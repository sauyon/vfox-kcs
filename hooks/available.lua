local http = require("http")
local json = require("json")

function PLUGIN:Available(ctx)
    local headers = { ["Accept"] = "application/vnd.github+json" }
    local token = os.getenv("GITHUB_TOKEN")
    if token and token ~= "" then
        headers["Authorization"] = "Bearer " .. token
    end

    local resp = http.get({
        url = "https://api.github.com/repos/FogDong/kcs/releases",
        headers = headers,
    })
    if resp.status_code ~= 200 then
        error("GitHub API request failed: " .. resp.status_code)
    end

    local releases = json.decode(resp.body)
    local result = {}
    for _, release in ipairs(releases) do
        if not release.prerelease and not release.draft then
            local version = release.tag_name:gsub("^v", "")
            table.insert(result, { version = version })
        end
    end
    return result
end
