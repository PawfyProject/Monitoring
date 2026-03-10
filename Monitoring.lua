print("🚀 PAWFY STARTING...")

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local request = http_request or (http and http.request) or (syn and syn.request) or request
local hasFileFunctions = (writefile and readfile and isfile)

print("✅ Services loaded")

--================================================
-- GLOBAL WEBHOOK (NO INPUT REQUIRED)
--================================================

local webhook = "https://discord.com/api/webhooks/1471107667190612121/vCxaTbWvTNftpvv3o-YmOBH4oJ9KfB36U2wwznOwNtZ2UjRYFNftIWtw-E6AQ36Vz50J"

local DATA_PATH = "pawfy-multi-instance.json"
local MESSAGE_ID_FILE = "pawfy-message-id.txt"

local BASE_INTERVAL = 40
local startTime = os.time()

print("✅ Global webhook active")

--================================================
-- PERFORMANCE OPTIMIZATION
--================================================

if setfpscap then
    setfpscap(3)
end

settings().Rendering.QualityLevel = 1
RunService:Set3dRenderingEnabled(false)

Lighting.GlobalShadows = false
Lighting.Brightness = 0
Lighting.Ambient = Color3.new(0,0,0)
Lighting.OutdoorAmbient = Color3.new(0,0,0)
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0
Lighting.FogEnd = 0

for _,v in pairs(Lighting:GetChildren()) do
    if v:IsA("PostEffect") or v:IsA("Sky") or v:IsA("Atmosphere") then
        pcall(function()
            v:Destroy()
        end)
    end
end

local function optimizeObject(obj)

    if obj:IsA("BasePart") then
        obj.Material = Enum.Material.Plastic
        obj.CastShadow = false
        obj.Reflectance = 0

    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        pcall(function()
            obj:Destroy()
        end)

    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
        obj.Enabled = false
    end
end

for _,obj in pairs(game:GetDescendants()) do
    optimizeObject(obj)
end

Workspace.DescendantAdded:Connect(function(obj)
    task.wait()
    optimizeObject(obj)
end)

task.spawn(function()
    while true do
        task.wait(30)
        for _,obj in pairs(Workspace:GetDescendants()) do
            optimizeObject(obj)
        end
    end
end)

local terrain = Workspace:FindFirstChildOfClass("Terrain")

if terrain then
    terrain.WaterWaveSize = 0
    terrain.WaterWaveSpeed = 0
    terrain.WaterReflectance = 0
    terrain.WaterTransparency = 1
end

print("Optimization complete")

--================================================
-- FPS TRACKER
--================================================

local frames = 0
local currentFPS = 0

RunService.RenderStepped:Connect(function()
    frames += 1
end)

task.spawn(function()

    while true do
        task.wait(1)
        currentFPS = frames
        frames = 0
    end

end)

--================================================
-- MULTI INSTANCE DATA SYSTEM
--================================================

local function updateLocalData()

    local allData = {}

    if hasFileFunctions and isfile(DATA_PATH) then
        pcall(function()
            allData = HttpService:JSONDecode(readfile(DATA_PATH))
        end)
    end

    local pingValue = 0

    pcall(function()
        pingValue = math.floor(
            Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        )
    end)

    local uptimeSeconds = os.time() - startTime
    local hours = math.floor(uptimeSeconds / 3600)
    local minutes = math.floor((uptimeSeconds % 3600) / 60)

    local uptimeStr = string.format("%02d:%02d", hours, minutes)

    allData[LocalPlayer.Name] = {

        status = "🟢",
        uptime = uptimeStr,
        fps = currentFPS,
        mem = math.floor(Stats:GetTotalMemoryUsageMb()),
        ping = pingValue,
        lastUpdate = os.time()

    }

    for name,data in pairs(allData) do
        if os.time() - data.lastUpdate > 150 then
            allData[name] = nil
        end
    end

    if hasFileFunctions then
        pcall(function()
            writefile(DATA_PATH, HttpService:JSONEncode(allData))
        end)
    end

    return allData
end

--================================================
-- DISCORD EMBED
--================================================

local function sendEmbed(allData)

    local sortedNames = {}
    local totalRam = 0

    for name,data in pairs(allData) do
        table.insert(sortedNames,name)
        totalRam += data.mem
    end

    table.sort(sortedNames)

    if sortedNames[1] ~= LocalPlayer.Name then
        return
    end

    local lines = {}

    table.insert(lines,"👤 **User** | ⏳ **Up** | 🖥️ **FPS** | 🧠 **RAM** | 📡 **Ping**")
    table.insert(lines,"--------------------------------------------------")

    for _,name in ipairs(sortedNames) do

        local d = allData[name]

        local line = string.format(
            "%s `%s` | %s | %s | %sMB | %sms",
            d.status,
            string.sub(name,1,10),
            d.uptime,
            d.fps,
            d.mem,
            d.ping
        )

        table.insert(lines,line)
    end

    table.insert(lines,"--------------------------------------------------")
    table.insert(lines,string.format("📊 **Total RAM:** **%.2f GB**", totalRam/1024))

    local payload = HttpService:JSONEncode({

        username = "Pawfy Stealth Monitor",

        embeds = {{

            title = "🛡️ PAWFY ALL-IN-ONE MONITOR",
            color = 65280,
            description = table.concat(lines,"\n"),

            footer = {
                text = "Optimizer Active • Safe Mode"
            },

            timestamp = DateTime.now():ToIsoDate()

        }}
    })

    local msgId = nil

    if hasFileFunctions and isfile(MESSAGE_ID_FILE) then
        msgId = readfile(MESSAGE_ID_FILE)
    end

    local url = msgId and (webhook.."/messages/"..msgId) or (webhook.."?wait=true")
    local method = msgId and "PATCH" or "POST"

    local success,result = pcall(function()

        return request({
            Url = url,
            Method = method,
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = payload
        })

    end)

    if success and result and result.Body then

        local ok,response = pcall(function()
            return HttpService:JSONDecode(result.Body)
        end)

        if ok and response.id and not msgId and hasFileFunctions then
            pcall(function()
                writefile(MESSAGE_ID_FILE,response.id)
            end)
        end
    end
end

--================================================
-- MAIN LOOP
--================================================

task.spawn(function()

    task.wait(3)

    while true do

        local data = updateLocalData()
        sendEmbed(data)

        task.wait(BASE_INTERVAL + math.random(5,15))

        pcall(function()

            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
            end

        end)

    end

end)

print("✅ PAWFY ALL-IN-ONE MONITOR LOADED (GLOBAL WEBHOOK MODE)")
