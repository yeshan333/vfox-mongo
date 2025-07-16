local http = require("http")

local mongo_utils = {}

function mongo_utils.get_mongo_release_verions()
    local fetch_url = "https://fastly.jsdelivr.net/gh/yeshan333/vfox-mongo@main/assets/" .. RUNTIME.osType .. "_versions.txt"
    local resp, err = http.get({
        url = fetch_url
    })
    
    local unique_versions = {}
    local version_map = {}
    
    -- Extract semantic versions from platform-specific strings
    for full_version in string.gmatch(resp.body, '([^\n]+)') do
        -- Extract semantic version (e.g., "8.1.2", "8.1.2-rc1", "8.0.6")
        local semantic_version = full_version:match('(%d+%.%d+%.%d+[%w%-]*)$')
        if semantic_version and not version_map[semantic_version] then
            version_map[semantic_version] = true
            table.insert(unique_versions, semantic_version)
        end
    end
    
    -- Sort versions in descending order (newest first)
    table.sort(unique_versions, function(a, b)
        -- Simple version comparison - split by dots and compare parts
        local function split_version(v)
            local parts = {}
            for part in string.gmatch(v, '([^.%-]+)') do
                table.insert(parts, part)
            end
            return parts
        end
        
        local a_parts = split_version(a)
        local b_parts = split_version(b)
        
        for i = 1, math.max(#a_parts, #b_parts) do
            local a_part = tonumber(a_parts[i]) or a_parts[i] or 0
            local b_part = tonumber(b_parts[i]) or b_parts[i] or 0
            
            if a_part ~= b_part then
                if type(a_part) == "number" and type(b_part) == "number" then
                    return a_part > b_part
                else
                    return tostring(a_part) > tostring(b_part)
                end
            end
        end
        
        return false
    end)
    
    local result = {}
    for _, version in ipairs(unique_versions) do
        table.insert(result, {
            version = version
        })
    end
    
    return result
end

return mongo_utils