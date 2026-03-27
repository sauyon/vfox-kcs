local cmd = require("cmd")

function PLUGIN:PostInstall(ctx)
    local install_path = ctx.rootPath
    local os_type = RUNTIME.osType
    local arch_type = RUNTIME.archType

    local arch = arch_type
    if arch_type == "x86_64" then
        arch = "amd64"
    elseif arch_type == "aarch64" then
        arch = "arm64"
    end

    local bin_name = "kcs-" .. os_type .. "-" .. arch
    local bin_dir = install_path .. "/bin"

    cmd.exec("mkdir -p " .. bin_dir)
    cmd.exec("mv " .. install_path .. "/" .. bin_name .. " " .. bin_dir .. "/kcs")
    cmd.exec("chmod +x " .. bin_dir .. "/kcs")
end
