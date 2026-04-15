local function new_session_id()
    local f = io.open("/dev/urandom", "rb")
    if f then
        local bytes = f:read(4)
        f:close()
        local n = 0
        for i = 1, #bytes do
            n = n * 256 + bytes:byte(i)
        end
        return tostring(n % 90000 + 10000)
    end
    math.randomseed(os.time())
    return tostring(math.random(10000, 99999))
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
    local kcs_dir = xdg_runtime_dir() .. "/kcs/sessions/"
    local kube_dir = os.getenv("HOME") .. "/.kube"
    local kcs_config = kube_dir .. "/kcs-config"

    -- Ensure the sessions directory and kcs-config symlink exist.
    os.execute("mkdir -p " .. kcs_dir)
    os.execute("test -e " .. kcs_config .. " -o -L " .. kcs_config ..
        " || ln -s " .. kube_dir .. "/config " .. kcs_config)

    -- If KCS_SESSION is already set, honour it; otherwise generate a new one.
    local session_id = os.getenv("KCS_SESSION")
    if not session_id or session_id == "" then
        session_id = new_session_id()
    end

    local existing_kubeconfig = os.getenv("KUBECONFIG") or ""

    -- Strip any existing kcs session path so we don't accumulate duplicates.
    -- If KUBECONFIG already contains a kcs path, fall back to ~/.kube/kcs-config
    -- rather than re-appending the session path on top of itself.
    -- NOTE: do NOT return {} here — that tells mise to unset the vars it
    -- previously exported, causing KCS_SESSION to oscillate on every hook.
    local fallback
    if existing_kubeconfig:find(kcs_dir, 1, true) or existing_kubeconfig:find("kcs-config", 1, true) then
        fallback = kcs_config
    elseif existing_kubeconfig ~= "" then
        fallback = existing_kubeconfig
    else
        fallback = kcs_config
    end

    local session_file = kcs_dir .. session_id
    local kubeconfig = session_file .. ":" .. fallback

    local options = ctx.options or {}
    local env = {
        { key = "KUBECONFIG",  value = kubeconfig },
        { key = "KCS_SESSION", value = session_id },
    }
    if options.default_session then
        table.insert(env, { key = "KCS_DEFAULT_SESSION", value = "1" })
    end

    return {
        cacheable = true,
        watch_files = { session_file },
        env = env,
    }
end
