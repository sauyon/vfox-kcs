local function get_shell_pid()
    -- Linux: read PPid from /proc/self/status (mise runs embedded in-process,
    -- so self is the mise process and its parent is the shell)
    local f = io.open("/proc/self/status", "r")
    if f then
        for line in f:lines() do
            local ppid = line:match("^PPid:%s+(%d+)")
            if ppid then
                f:close()
                return ppid
            end
        end
        f:close()
    end

    -- macOS fallback: get mise PID via $PPID of a subshell, then get its parent
    local mise_pid = cmd.exec({ "sh", "-c", "echo $PPID" }):match("%d+")
    if mise_pid then
        local shell_pid = cmd.exec({ "ps", "-o", "ppid=", "-p", mise_pid }):match("%d+")
        if shell_pid then
            return shell_pid
        end
    end

    return nil
end

local function xdg_runtime_dir()
    local d = os.getenv("XDG_RUNTIME_DIR")
    if d and d ~= "" then
        return d
    end
    local home = os.getenv("HOME")
    return home .. "/.local/run"
end

function PLUGIN:MiseEnv(ctx)
    local shell_pid = get_shell_pid()
    if not shell_pid then
        return {}
    end

    local kcs_dir = xdg_runtime_dir() .. "/kcs/sessions/"
    local existing_kubeconfig = os.getenv("KUBECONFIG") or ""
    if existing_kubeconfig:find(kcs_dir, 1, true) then
        return {}
    end

    local session_file = kcs_dir .. shell_pid
    local fallback = existing_kubeconfig ~= ""
        and existing_kubeconfig
        or (os.getenv("HOME") .. "/.kube/config")
    local kubeconfig = session_file .. ":" .. fallback

    return {
        cacheable = true,
        watch_files = { session_file },
        env = (function()
            local e = { { key = "KUBECONFIG", value = kubeconfig } }
            if not os.getenv("KCS_SESSION") then
                table.insert(e, { key = "KCS_SESSION", value = shell_pid })
            end
            return e
        end)()
    }
end
