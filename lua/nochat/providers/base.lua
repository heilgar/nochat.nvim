local Provider = {}
Provider.__index = Provider

function Provider:new(opts)
    opts = opts or {}
    local instance = setmetatable({}, self)
    instance.name = opts.name or "base"
    instance.models = opts.models or {}
    instance.default_model = opts.default_model or nil
    instance.request_in_progress = false
    instance.stream_controller = nil
    instance.api_key = opts.api_key or nil
    return instance
end

function Provider:setup(config)
    -- To be implemented by subclasses
    error("BaseProvider:setup must be implemented by subclasses")
end

function Provider:is_available()
    -- Override if needed
    return self.api_key ~= nil and self.api_key ~= ""
end

function Provider:get_models()
    return self.models
end

function Provider:get_default_model()
    if #self.models > 0 then
        return self.default_model or self.models[1]
    end
    return nil
end

function Provider:is_valid_model(model)
    if not model then return false end

    for _, m in ipairs(self.models) do
        if m == model then
            return true
        end
    end
    return false
end

function Provider:get_response(conversation, model, callback)
    -- Must be implemented by subclasses
    error("BaseProvider:get_response must be implemented by subclasses")
end

function Provider:abort_stream()
    if self.request_in_progress and self.stream_controller then
        self.stream_controller.abort()
        self.stream_controller = nil
        self.request_in_progress = false
    end
end

function Provider:format_conversation(conversation)
    -- Default implementation returns conversation unchanged
    return conversation
end

function Provider:get_error_message()
    return "Provider " .. self.name .. " is not properly configured."
end

function Provider:set_models(cfg)
    if cfg.models then
        self.models = cfg.models
    end

    if cfg.model and self:is_valid_model(cfg.model) then
        self.default_model = cfg.model
    elseif #self.models > 0 then
        self.default_model = self.models[1]
    end
end

return Provider

