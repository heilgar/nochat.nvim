local Provider = require('nochat.providers.base')
local streaming = require('nochat.utils.streaming')

local OpenAIProvider = {}
OpenAIProvider.__index = OpenAIProvider
setmetatable(OpenAIProvider, { __index = Provider })

function OpenAIProvider:new()
    local instance = Provider.new(self, { name = "openai" })
    setmetatable(instance, self)
    self.__index = self

    setmetatable(instance, OpenAIProvider)

    return instance
end

function OpenAIProvider:setup(cfg)
    self.api_key = cfg.api_key or os.getenv('OPENAI_API_KEY')
    self:set_models(cfg)
end

function OpenAIProvider:get_response(conversation, model, callback)
    -- Validate model
    if not self:is_valid_model(model) then
        model = self:get_default_model()
        if not model then
            callback("No valid model available for OpenAI", true)
            return
        end
    end

    if not self:is_available() then
        callback("API key not set for OpenAI", true)
        return
    end

    if self.request_in_progress then
        callback("A request is already in progress", true)
        return
    end

    self.request_in_progress = true

    -- Create a unique response for the OpenAI provider
    local full_response = "Hi there! I'm an OpenAI model: " .. model ..
        ".\n\nI like to provide helpful code examples like this:\n```javascript\nconsole.log('Hello from OpenAI!');\n```"

    -- Use character-by-character streaming (OpenAI style)
    self.stream_controller = streaming.simulate_char_streaming(full_response, function(response, is_done)
        if is_done then
            self.request_in_progress = false
        end
        callback(response, is_done)
    end, 5, 50) -- 5 chars per chunk, 50ms delay
end

function OpenAIProvider:format_conversation(conversation)
    -- Format conversation for OpenAI's API
    local formatted = {}
    for _, message in ipairs(conversation) do
        table.insert(formatted, {
            role = message.role,
            content = message.content
        })
    end
    return formatted
end

function OpenAIProvider:get_error_message()
    return "API key not set for " .. self.name .. ". Please set it in your configuration."
end

local provider = OpenAIProvider:new()
return provider

