local Provider = require('nochat.providers.base')
local utils = require('nochat.utils')

local OllamaProvider = {}
OllamaProvider.__index = OllamaProvider
setmetatable(OllamaProvider, { __index = Provider })

function OllamaProvider:new()
    local instance = Provider.new(self, {
        name = 'ollama',
        host = 'http://localhost:11434'
    })
    setmetatable(instance, self)
    self.__index = self

    return instance
end

function OllamaProvider:setup(cfg)
    self.host = cfg.host or self.host
    self:set_models(cfg)

    if #self.models == 0 then
        self:get_models_from_api(function(models, err)
            if err then
                vim.notify("Failed to fetch Ollama models: " .. err, vim.log.levels.WARN)
                return
            end

            if #models > 0 then
                self.models = models
                self.default_model = models[1]
                vim.notify("Loaded " .. #models .. " models from Ollama server", vim.log.levels.INFO)
            end
        end)
    end
end

function OllamaProvider:is_available()
    if self.host == nil or self.host == "" then
        return false
    end

    -- For better UX, we cache the availability check for a short time
    if self.available_cache and self.available_cache_time and
        os.time() - self.available_cache_time < 10 then -- Cache for 10 seconds
        return self.available_cache
    end

    if not utils.is_http_available() then
        return false
    end

    local success = false

    -- Try a simple synchronous check
    local response = utils.get(self.host .. "/api/version")
    if response and response.status == 200 then
        success = true
    end

    -- Update cache
    self.available_cache = success
    self.available_cache_time = os.time()

    return success
end

-- Format conversation as a simple text prompt
function OllamaProvider:format_prompt(conversation)
    local prompt = ""

    for _, message in ipairs(conversation) do
        if message.role == "system" then
            prompt = prompt .. "System: " .. message.content .. "\n\n"
        elseif message.role == "user" then
            prompt = prompt .. "User: " .. message.content .. "\n\n"
        elseif message.role == "assistant" then
            prompt = prompt .. "Assistant: " .. message.content .. "\n\n"
        end
    end

    -- Add final prompt instruction
    prompt = prompt .. "Assistant: "

    return prompt
end

function OllamaProvider:format_conversation(conversation)
    -- Keep this for compatibility, but we actually use format_prompt instead
    local formatted = {}
    for _, message in ipairs(conversation) do
        table.insert(formatted, {
            role = message.role,
            content = message.content
        })
    end
    return formatted
end

function OllamaProvider:get_error_message()
    return "Cannot connect to Ollama server at " .. self.host .. ". Make sure it's running."
end

-- Hook to fetch models from the Ollama API
function OllamaProvider:get_models_from_api(callback)
    if not self:is_available() then
        callback({}, "Ollama server not available")
        return
    end

    local url = self.host .. "/api/tags"

    -- Use the jobstart API for reliability
    local command = "curl -s " .. url
    local output = ""

    local job_id = vim.fn.jobstart(command, {
        on_stdout = function(_, data, _)
            if data and #data > 0 then
                for _, line in ipairs(data) do
                    if line and line ~= "" then
                        output = output .. line
                    end
                end
            end
        end,
        on_exit = function(_, code, _)
            if code ~= 0 or output == "" then
                vim.schedule(function()
                    callback({}, "Failed to fetch models from Ollama server")
                end)
                return
            end

            local success, parsed = pcall(vim.fn.json_decode, output)
            if not success or not parsed or not parsed.models then
                vim.schedule(function()
                    callback({}, "Failed to parse models response from Ollama")
                end)
                return
            end

            local models = {}
            for _, model in ipairs(parsed.models) do
                table.insert(models, model.name)
            end

            vim.schedule(function()
                vim.notify("Loaded " .. #models .. " models from Ollama server", vim.log.levels.INFO)
                callback(models)
            end)
        end
    })

    if job_id <= 0 then
        vim.schedule(function()
            callback({}, "Failed to start request to Ollama")
        end)
    end
end

function OllamaProvider:get_response(conversation, model, callback)
    -- Validate model
    if not self:is_valid_model(model) then
        model = self:get_default_model()
        if not model then
            callback("No valid model available for Ollama", true)
            return
        end
    end

    if not self:is_available() then
        callback("Ollama server not available", true)
        return
    end

    if self.request_in_progress then
        callback("A request is already in progress", true)
        return
    end

    -- Format conversation as a simple prompt
    local prompt = self:format_prompt(conversation)

    -- Prepare request payload
    local payload = {
        model = model,
        prompt = prompt,
        stream = true -- Enable streaming
    }

    local payload_json = vim.fn.json_encode(payload)

    self.request_in_progress = true
    self.abort_requested = false
    local current_response = ""

    -- Use curl with --no-buffer for proper streaming
    local command = "curl -s --no-buffer -X POST " ..
        "-H 'Content-Type: application/json' " ..
        "-d '" .. payload_json:gsub("'", "'\\''") .. "' " ..
        self.host .. "/api/generate"

    local job_id = vim.fn.jobstart(command, {
        on_stdout = function(_, data, _)
            if self.abort_requested then
                return
            end

            if data and #data > 0 then
                for _, line in ipairs(data) do
                    if line and line ~= "" then
                        -- Each line should be a complete JSON object from Ollama
                        local success, parsed = pcall(vim.fn.json_decode, line)
                        if success and parsed then
                            if parsed.response then
                                current_response = current_response .. parsed.response
                                vim.schedule(function()
                                    callback(current_response, false)
                                end)
                            end

                            if parsed.done then
                                vim.schedule(function()
                                    self.request_in_progress = false
                                    callback(current_response, true)
                                end)
                            end
                        end
                    end
                end
            end
        end,
        on_stderr = function(_, data, _)
            if data and #data > 0 then
                local error_msg = table.concat(data, "\n")
                if error_msg ~= "" then
                    vim.schedule(function()
                        self.request_in_progress = false
                        callback("Error: " .. error_msg, true)
                    end)
                end
            end
        end,
        on_exit = function(_, code, _)
            if not self.abort_requested then
                vim.schedule(function()
                    self.request_in_progress = false
                    -- Only report exit as an error if we didn't get any response
                    if code ~= 0 and current_response == "" then
                        callback("Error communicating with Ollama server (code " .. code .. ")", true)
                    elseif current_response ~= "" then
                        -- Final callback with the complete response
                        callback(current_response, true)
                    end
                end)
            end
        end
    })

    if job_id <= 0 then
        self.request_in_progress = false
        callback("Failed to start request to Ollama", true)
    end

    self.current_job_id = job_id
end

function OllamaProvider:abort_stream()
    if self.request_in_progress and self.current_job_id and self.current_job_id > 0 then
        self.abort_requested = true
        vim.fn.jobstop(self.current_job_id)
        self.current_job_id = nil
        self.request_in_progress = false
    end
end

local provider = OllamaProvider:new()
return provider

