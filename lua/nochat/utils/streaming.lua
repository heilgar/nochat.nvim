local M = {}

-- Simulate word-by-word streaming (like Anthropic Claude)
M.simulate_word_streaming = function(full_response, callback, delay_ms)
    local delay = delay_ms or 100
    local words = {}
    for word in full_response:gmatch("%S+") do
        table.insert(words, word)
    end

    local current_response = ""
    local word_index = 1
    local abort_requested = false

    -- Simulate "typing" by adding words with delays
    local timer = vim.loop.new_timer()
    timer:start(delay, delay, vim.schedule_wrap(function()
        if abort_requested or word_index > #words then
            timer:stop()
            timer:close()
            callback(current_response, true) -- true indicates it's done
            return
        end

        -- Add the next word with a space
        if current_response ~= "" then
            current_response = current_response .. " "
        end
        current_response = current_response .. words[word_index]
        word_index = word_index + 1

        -- Update with current progress
        callback(current_response, false)
    end))

    -- Return control functions for the timer
    return {
        abort = function()
            abort_requested = true
            timer:stop()
            timer:close()
        end,
        timer = timer
    }
end

-- Simulate character-by-character streaming (like OpenAI)
M.simulate_char_streaming = function(full_response, callback, chars_per_chunk, delay_ms)
    local chars_chunk = chars_per_chunk or 5
    local delay = delay_ms or 50

    local current_response = ""
    local char_index = 1
    local abort_requested = false

    -- Simulate token-by-token streaming
    local timer = vim.loop.new_timer()
    timer:start(delay, delay, vim.schedule_wrap(function()
        if abort_requested or char_index > #full_response then
            timer:stop()
            timer:close()
            callback(current_response, true) -- true indicates it's done
            return
        end

        -- Add the next chunk of characters
        local end_index = math.min(char_index + chars_chunk - 1, #full_response)
        local chunk = string.sub(full_response, char_index, end_index)
        current_response = current_response .. chunk
        char_index = end_index + 1

        -- Update with current progress
        callback(current_response, false)
    end))

    -- Return control functions for the timer
    return {
        abort = function()
            abort_requested = true
            timer:stop()
            timer:close()
        end,
        timer = timer
    }
end

-- Simulate variable chunk streaming (like Ollama)
M.simulate_chunk_streaming = function(full_response, callback, min_chunk, max_chunk, delay_ms)
    local min_size = min_chunk or 3
    local max_size = max_chunk or 15
    local delay = delay_ms or 120

    local chunks = {}

    -- Split the response into random-sized chunks
    local start = 1
    while start <= #full_response do
        local chunk_size = math.random(min_size, max_size)
        local end_pos = math.min(start + chunk_size - 1, #full_response)
        table.insert(chunks, string.sub(full_response, start, end_pos))
        start = end_pos + 1
    end

    local current_response = ""
    local chunk_index = 1
    local abort_requested = false

    -- Simulate streaming with variable-sized chunks
    local timer = vim.loop.new_timer()
    timer:start(delay, delay, vim.schedule_wrap(function()
        if abort_requested or chunk_index > #chunks then
            timer:stop()
            timer:close()
            callback(current_response, true) -- true indicates it's done
            return
        end

        -- Add the next chunk
        current_response = current_response .. chunks[chunk_index]
        chunk_index = chunk_index + 1

        -- Update with current progress
        callback(current_response, false)
    end))

    -- Return control functions for the timer
    return {
        abort = function()
            abort_requested = true
            timer:stop()
            timer:close()
        end,
        timer = timer
    }
end

return M

