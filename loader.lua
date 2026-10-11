--[[
  Pulsar Hub Loader — The Strongest Battlegrounds
  Prints clear errors if HttpGet / loadstring fails
]]

local URL = "https://raw.githubusercontent.com/Overthinker-1/PulsarTSB/main/main.lua"

local okGet, src = pcall(function()
    return game:HttpGet(URL)
end)

if not okGet then
    warn("[Pulsar] HttpGet failed: " .. tostring(src))
    warn("[Pulsar] Your executor may block GitHub. Try another executor or paste main.lua directly.")
    return
end

if type(src) ~= "string" or #src < 50 then
    warn("[Pulsar] Empty response from GitHub. Is the repo public?")
    return
end

local okLoad, fn = pcall(function()
    return loadstring(src)
end)

if not okLoad or type(fn) ~= "function" then
    warn("[Pulsar] loadstring failed: " .. tostring(fn))
    warn("[Pulsar] Script may have a syntax error — update main.lua on GitHub.")
    return
end

local okRun, err = pcall(fn)
if not okRun then
    warn("[Pulsar] Runtime error: " .. tostring(err))
end
