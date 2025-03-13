local Provider = require('nochat.providers.base')
local streaming = require('nochat.utils.streaming')

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
end

function OllamaProvider:is_available()
    return self.host ~= nil and self.host ~= ""
end

function OllamaProvider:get_response(conversation, model, callback)
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

    self.request_in_progress = true

    -- Create a unique response for the Ollama provider
    local full_response = "Hello from a local Ollama model: " .. model ..
        ".\n\nI'm running locally on your machine, which provides privacy benefits:\n- No data sent to external servers\n- Works offline\n- Lower latency"

    -- Use chunk-based streaming (Ollama style)
    self.stream_controller = streaming.simulate_chunk_streaming(full_response, function(response, is_done)
        if is_done then
            self.request_in_progress = false
        end
        callback(response, is_done)
    end, 3, 15, 120) -- Random chunk sizes, slower timing
end

function OllamaProvider:format_conversation(conversation)
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
    return "Cannot connect to Ollama server. Make sure it's running."
end

local provider = OllamaProvider:new()
return provider

