print("[Pulsar] loader start")
local URL = "https://raw.githubusercontent.com/Overthinker-1/PulsarTSB/main/main.lua"
local ok, src = pcall(function() return game:HttpGet(URL) end)
if not ok then print("[Pulsar] HttpGet FAILED:", src) return end
print("[Pulsar] downloaded", type(src)=="string" and #src or 0, "bytes")
local ok2, fn = pcall(function() return loadstring(src) end)
if not ok2 or type(fn)~="function" then print("[Pulsar] loadstring FAILED:", fn) return end
local ok3, err = pcall(fn)
print(ok3 and "[Pulsar] executed OK" or ("[Pulsar] runtime FAILED: "..tostring(err)))
