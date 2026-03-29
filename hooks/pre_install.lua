function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    local os_type = RUNTIME.osType
    local arch_type = RUNTIME.archType

    local arch = arch_type
    if arch_type == "x86_64" then
        arch = "amd64"
    elseif arch_type == "aarch64" then
        arch = "arm64"
    end

    local filename = "kcs-" .. os_type .. "-" .. arch
    local url = "https://github.com/sauyon/kcs/releases/download/v" .. version .. "/" .. filename

    return {
        version = version,
        url = url,
        -- single binary, no archive
    }
end
