--[[
======================================
TranscludeData
--------------------------------------
@Author Jono99
@Version 0
See https://github.com/Jono997/TranscludeData for documentation and releases
======================================
]]--

local p = {}
local data = nil

local function loadData()
	data = require('Module:TranscludeData/data')['data']
end

--- Breaks a data path down into a series of keys and returns it
--- @param path string|table The data path to process
--- @return table keys The individual keys comprising the path, in the order they appear
local function processPath(path)
    if type(path) == 'string' then
        local retval = {}
        for segment in path:gmatch('([^.]+)') do
            local i = #retval + 1
            if segment:match('^%d+$') then
                retval[i] = tonumber(segment)
            else
                retval[i] = segment
            end
        end
        return retval
    end
    return path
end

--- Gets and returns the data at the data path provided
--- @param path string|table The data path to get data from
--- @return any data The data at the data path provided
--- @return table parent The table that contains data as a value
--- @return string|number parent_key The key to data in parent
local function getData(path)
    local retval = data
    local path = processPath(path)
    local i = 1
    while i < #path do
        retval = retval[path[i]]
        i = i + 1
    end

    return retval[path[i]], retval, path[i]
end

--- Gets and returns if data exists at the data path provided
--- @param path string|table The data path to check
--- @return boolean exists true if there is any data at the path provided. false if not.
local function existsData(path)
	local path = processPath(path)
	local current = data
	local i = 1
	while i < #path do
		if current[path[i]] == nil then
			return false
		end
		current = current[path[i]]
		i = i + 1
	end
	return true
end

--- Formats a string as a lua error and returns it
--- @param err_text string The text to format
--- @return string The text formatted as an error
local function error(err_text)
    return '<strong class="error"><span class="scribunto-error">' .. err_text .. '</span></strong>'
end

--- Creates utility functions for views to use
--- @param view string The view the functions are being created for
--- @return table utils The utility functions for the view
local function makeUtils(view)
    local u = {}

    --- Formats a string as a lua error and returns it
    --- @param err_text string The text to formatted
    --- @return string The text formatted as an error
    function u.error(err_text)
        return error(err_text)
    end

    --- Returns data at the data path provided
    --- @param path string|table The data path to get data from
    --- @return any data The data at the data path provided, processed by override(s) present
    function u.get(path)
        return getData(path)
    end
    
    --- Returns if there is data at the data path provided
    --- @param path string|table The data path to check
    --- @return any exists true if data is at the data path provided
    function u.exists(path)
    	return existsData(path)
    end

	--- Parses a credits string into the artist credits contained within and the surrounding strings
	--- @param credits string The credits string to parse
	--- @param only_artists boolean If true, only the artist credits will be returned, not the raw strings in between. false by default
	--- @return table credits An array of the artist credits themselves and, if only_artists is false, the surrounding strings that make up the rest of the credits string.
    function u.parseCredits(credits, only_artists)
        local credit_pattern = '<%b<>>'
        local start = 1
        local retval = {}
        while true do
            local ms, me = mw.ustring.find(credits, credit_pattern, start)
            if ms == nil then
            	if not only_artists then
                	table.insert(retval, mw.ustring.sub(credits, start))
                end
                break
            end

			if not only_artists then
            	table.insert(retval, mw.ustring.sub(credits, start, ms - 1))
            end
            local match = mw.ustring.sub(credits, ms + 2, me - 2)
            local alias_point = mw.ustring.find(match, '|')
            if alias_point == nil then
                table.insert(retval, {
                    artist = match,
                    alias = match
                })
            else
                table.insert(retval, {
                artist = mw.ustring.sub(match, 1, alias_point - 1),
                alias =  mw.ustring.sub(match, alias_point + 1)
                })
            end
            start = me + 1
        end
        return retval
    end
    
    --- Convert a processed credits string into wikitext
    --- @param credits table A processed Credits string (return value of parseCredits)
    --- @param link_page string If not nil, artist credits will be stringified as links to this page with the artist name as the header to jump to (eg. '[[Artists#N16FS|Tetrajectory]]')
    --- @return string credits The credits processed into wikitext
    function u.stringifyCredits(credits, link_page)
    	local retval = ''
    	for _, c in ipairs(credits) do
    		if type(c) == 'string' then
    			retval = retval .. c
    		else
    			if link_page then
    				retval = retval .. '[[' .. link_page .. '#' .. c.artist .. '|' .. c.alias .. ']]'
    			else
    				retval = retval .. c.alias
    			end
    		end
    	end
    	return retval
    end	

    return u
end

function p.View(frame)
	loadData()
    local args = frame.args

    -- Checking for a valid view
    if args[1] == nil then
        return error('TranscludeData error: No view id given')
    end
    local views = require('Module:TranscludeData/views')
    if views[args[1]] == nil then
        return error('TranscludeData error: No view with id \'' .. args[1] .. '\' exists')
    end

    -- Checking for valid view parameters
    local view = views[args[1]]
    local view_args = {}
    local param_errors = {}

    for _, param in ipairs(view.params) do
        local p_name = param[1]

        -- Increment index of param if it's a number so it aligns with where it'll be in args
        if type(p_name) == 'number' then
            p_name = p_name + 1
        end

        local p_required = param[3]
        if p_required == nil then
            p_required = true
        end
        if args[p_name] == nil then
            if p_required then
                param_errors[#param_errors + 1] = 'Required argument \'' .. tostring(param[0]) .. '\' not defined'
            end
        elseif type(args[p_name]) ~= param[2] and param[2] ~= 'any' then
            param_errors[#param_errors + 1] = 'Argument \'' ..
            tostring(param[0]) ..
            '\' invalid type (Expected: ' .. param[2] .. ', Provided: ' .. type(args[p_name]) .. ')'
        else
            view_args[param[1]] = args[p_name]
        end
    end

    if #param_errors > 0 then
        local pe_str = param_errors[1]
        local i = 2
        while i <= #param_errors do
            pe_str = pe_str .. '<br />' .. param_errors[i]
            i = i + 1
        end
        return error(pe_str)
    end

    -- Executing the view
    local retval = view.func(makeUtils(args[1]), frame, frame:getParent(), view_args)
    if retval == nil then
        return error('View did not return a value')
    end
    return retval
end

function p.Get(frame)
	loadData()
    local args = frame.args
    
    if existsData(args[1]) then
    	local retval = getData(args[1])
    	return retval
    end
    
    return error('No data at path \'' .. args[1] .. '\'')
end

return p
