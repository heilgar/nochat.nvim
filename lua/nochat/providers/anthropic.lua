local Provider = require('nochat.providers.base')
local streaming = require('nochat.utils.streaming')

local AnthropicProvider = {}
AnthropicProvider.__index = AnthropicProvider
setmetatable(AnthropicProvider, { __index = Provider })

function AnthropicProvider:new()
    local instance = Provider.new(self, { name = "anthropic" })
    setmetatable(instance, self)
    self.__index = self

    return instance
end

function AnthropicProvider:setup(cfg)
    self.api_key = cfg.api_key or os.getenv('ANTHROPIC_API_KEY')
    self:set_models(cfg)
end

function AnthropicProvider:get_response(conversation, model, callback)
    -- Validate model
    if not self:is_valid_model(model) then
        model = self:get_default_model()
        if not model then
            callback("No valid model available for Anthropic", true)
            return
        end
    end

    if not self:is_available() then
        callback("API key not set for Anthropic Claude", true)
        return
    end

    if self.request_in_progress then
        callback("A request is already in progress", true)
        return
    end

    self.request_in_progress = true

    -- Create a unique response for the Claude provider
    local full_response = "This is a response from Claude (Anthropic) using model: " .. model ..
        ". I'm known for my thoughtful, nuanced responses and strong reasoning capabilities."

    -- Use word-by-word streaming (Claude style)
    self.stream_controller = streaming.simulate_word_streaming(full_response, function(response, is_done)
        if is_done then
            self.request_in_progress = false
        end
        callback(response, is_done)
    end, 100) -- 100ms delay between words
end

function AnthropicProvider:format_conversation(conversation)
    -- Format conversation for Claude's API
    local formatted = {}
    for _, message in ipairs(conversation) do
        table.insert(formatted, {
            role = message.role,
            content = message.content
        })
    end
    return formatted
end

function AnthropicProvider:get_error_message()
    return "API key not set for " .. self.name .. ". Please set it in your configuration."
end

local provider = AnthropicProvider:new()
return provider

