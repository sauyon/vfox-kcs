local function new_session_id()
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

    -- If KCS_SESSION is already set, honour it; otherwise derive from shell PID.
    local session_id = os.getenv("KCS_SESSION")
    if not session_id or session_id == "" then
        session_id = new_session_id()
    end
    if not session_id then
        return {}
    end

    local existing_kubeconfig = os.getenv("KUBECONFIG") or ""

    -- Strip any existing kcs session path so we don't accumulate duplicates.
    -- If KUBECONFIG already contains a kcs path, fall back to ~/.kube/config
    -- rather than re-appending the session path on top of itself.
    -- NOTE: do NOT return {} here — that tells mise to unset the vars it
    -- previously exported, causing KCS_SESSION to oscillate on every hook.
    local fallback
    if existing_kubeconfig:find(kcs_dir, 1, true) then
        fallback = os.getenv("HOME") .. "/.kube/config"
    elseif existing_kubeconfig ~= "" then
        fallback = existing_kubeconfig
    else
        fallback = os.getenv("HOME") .. "/.kube/config"
    end

    local session_file = kcs_dir .. session_id
    local kubeconfig = session_file .. ":" .. fallback

    return {
        cacheable = true,
        watch_files = { session_file },
        env = {
            { key = "KUBECONFIG",  value = kubeconfig },
            { key = "KCS_SESSION", value = session_id  },
        },
    }
end
