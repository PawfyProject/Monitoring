print("🚀 PAWFY STARTING...")

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--// EXECUTOR CHECK
local request = http_request or (http and http.request) or (syn and syn.request) or request
local hasFileFunctions = (writefile and readfile and isfile)

print("✅ Services loaded")

local WEBHOOK_FILE = "pawfy-webhook.json" 
local DATA_PATH = "pawfy-multi-instance.json" 
local MESSAGE_ID_FILE = "pawfy-message-id.txt" 
local BASE_INTERVAL = 40 
local startTime = os.time()
local webhook = nil

local function loadWebhook()
    if not hasFileFunctions then return nil end
    if not isfile(WEBHOOK_FILE) then return nil end
    
    local s, content = pcall(readfile, WEBHOOK_FILE)
    if not s then return nil end
    
    local ok, cfg = pcall(HttpService.JSONDecode, HttpService, content)
    if ok and cfg.webhook then 
        print("✅ Webhook loaded from file")
        return cfg.webhook 
    end
    return nil
end

webhook = loadWebhook()

if not webhook or webhook == "" then
    print("📝 Creating input GUI...")
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "PawfySetup"
    
    local guiSuccess = pcall(function()
        sg.Parent = CoreGui
    end)
    
    if not guiSuccess then
        sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromScale(0.5, 0.35)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Parent = sg
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromScale(1, 0.15)
    title.Position = UDim2.fromScale(0, 0.08)
    title.BackgroundTransparency = 1
    title.Text = "PAWFY ALL-IN-ONE MONITOR"
    title.TextColor3 = Color3.fromRGB(0, 255, 100)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.Parent = frame
    
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.fromScale(1, 0.1)
    status.Position = UDim2.fromScale(0, 0.25)
    status.BackgroundTransparency = 1
    status.Text = "Enter your Discord webhook URL"
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.Font = Enum.Font.Gotham
    status.TextSize = 14
    status.Parent = frame
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.fromScale(0.85, 0.18)
    box.Position = UDim2.fromScale(0.075, 0.38)
    box.PlaceholderText = "https://discord.com/api/webhooks/..."
    box.Text = ""
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    box.TextColor3 = Color3.new(1, 1, 1)
    box.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    box.ClearTextOnFocus = false
    box.Parent = frame
    
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 8)
    boxCorner.Parent = box
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(0.4, 0.15)
    btn.Position = UDim2.fromScale(0.3, 0.6)
    btn.Text = "SAVE & START"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    local info = Instance.new("TextLabel")
    info.Size = UDim2.fromScale(0.9, 0.15)
    info.Position = UDim2.fromScale(0.05, 0.78)
    info.BackgroundTransparency = 1
    info.Text = "Multi-instance monitor with embed\nLeave blank to skip"
    info.TextColor3 = Color3.fromRGB(180, 180, 180)
    info.Font = Enum.Font.Gotham
    info.TextSize = 11
    info.TextWrapped = true
    info.Parent = frame
    
    print("✅ GUI created, waiting for input...")
    
    local clicked = false
    btn.MouseButton1Click:Connect(function()
        if clicked then return end
        clicked = true
        
        local text = box.Text:gsub("%s+", "")
        
        if text == "" then
            status.Text = "Skipping webhook..."
            status.TextColor3 = Color3.fromRGB(255, 200, 0)
            webhook = "SKIPPED"
            task.wait(1)
            sg:Destroy()
            return
        end
        
        if text:find("discord.com/api/webhooks/") then
            webhook = text
            status.Text = "Saving..."
            status.TextColor3 = Color3.fromRGB(0, 255, 0)
            
            if hasFileFunctions then
                pcall(function()
                    writefile(WEBHOOK_FILE, HttpService:JSONEncode({webhook = webhook}))
                end)
            end
            
            task.wait(0.5)
            sg:Destroy()
        else
            status.Text = "Invalid URL! Must contain discord.com/api/webhooks/"
            status.TextColor3 = Color3.fromRGB(255, 100, 100)
            box.Text = ""
            clicked = false
        end
    end)
    
    while not webhook do
        task.wait(0.1)
    end
    
    print("✅ Webhook set")
else
    print("✅ Using saved webhook")
end

print("Starting optimization...")

if setfpscap then 
    setfpscap(3) 
end

settings().Rendering.QualityLevel = 1
RunService:Set3dRenderingEnabled(false)

task.spawn(function()
    local cam = Workspace.CurrentCamera
    while true do
        pcall(function()
            cam.CameraType = Enum.CameraType.Scriptable
            cam.CFrame = CFrame.new(0, 10000, 0) * CFrame.Angles(math.rad(-90), 0, 0)
        end)
        task.wait()
    end
end)

Lighting.GlobalShadows = false
Lighting.Brightness = 0
Lighting.Ambient = Color3.new(0,0,0)
Lighting.OutdoorAmbient = Color3.new(0,0,0)
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0
Lighting.FogEnd = 0

for _, v in pairs(Lighting:GetChildren()) do
    if v:IsA("PostEffect") or v:IsA("Sky") or v:IsA("Atmosphere") then
        pcall(function() v:Destroy() end)
    end
end

local function optimizeObject(obj)
    if obj:IsA("BasePart") then
        obj.Material = Enum.Material.Plastic
        obj.Reflectance = 0
        obj.CastShadow = false
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        pcall(function() obj:Destroy() end)
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
        obj.Enabled = false
    end
end

for _, obj in pairs(game:GetDescendants()) do
    optimizeObject(obj)
end

Workspace.DescendantAdded:Connect(function(obj)
    task.wait()
    optimizeObject(obj)
end)

task.spawn(function()
    while true do
        task.wait(30)
        for _, obj in pairs(Workspace:GetDescendants()) do
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

local fpsGui = Instance.new("ScreenGui")
fpsGui.Name = "PawfyMonitor"
fpsGui.ResetOnSpawn = false

pcall(function()
    fpsGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end)

if not fpsGui.Parent then
    fpsGui.Parent = CoreGui
end

local fpsFrame = Instance.new("Frame")
fpsFrame.Size = UDim2.new(0, 150, 0, 32)
fpsFrame.Position = UDim2.new(1, -160, 0, 10)
fpsFrame.BackgroundColor3 = Color3.new(0,0,0)
fpsFrame.BackgroundTransparency = 0.2
fpsFrame.BorderSizePixel = 0
fpsFrame.Parent = fpsGui

local fpsCorner = Instance.new("UICorner")
fpsCorner.CornerRadius = UDim.new(0, 8)
fpsCorner.Parent = fpsFrame

local fpsText = Instance.new("TextLabel")
fpsText.Size = UDim2.new(1,0,1,0)
fpsText.BackgroundTransparency = 1
fpsText.Font = Enum.Font.GothamBold
fpsText.TextSize = 12
fpsText.TextColor3 = Color3.fromRGB(0,255,100)
fpsText.Text = "PAWFY ACTIVE"
fpsText.Parent = fpsFrame

local frames = 0
local lastTime = tick()
local currentFPS = 0

RunService.RenderStepped:Connect(function()
    frames = frames + 1
    if tick() - lastTime >= 1 then
        currentFPS = frames
        fpsText.Text = string.format("FPS: %d | PAWFY", frames)
        frames = 0
        lastTime = tick()
    end
end)

if request and webhook and webhook ~= "SKIPPED" then
    print("Starting embed webhook system...")
    
    local function updateLocalData(isOffline)
        local allData = {}
        
        if hasFileFunctions and isfile(DATA_PATH) then
            pcall(function()
                allData = HttpService:JSONDecode(readfile(DATA_PATH))
            end)
        end
        
        if isOffline then
            allData[LocalPlayer.Name] = nil
        else
            local pingValue = 0
            pcall(function()
                pingValue = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
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
        end
        
        for name, data in pairs(allData) do
            if os.time() - data.lastUpdate > 150 then
                allData[name] = nil
            end
        end
        
        if hasFileFunctions then
            pcall(writefile, DATA_PATH, HttpService:JSONEncode(allData))
        end
        
        return allData
    end
    
    local function sendEmbed(allData)

        local sortedNames = {}
        local totalRam = 0
        
        for name, data in pairs(allData) do
            table.insert(sortedNames, name)
            totalRam = totalRam + data.mem
        end
        
        table.sort(sortedNames)

        if sortedNames[1] ~= LocalPlayer.Name then
            return
        end

        local lines = {}
        table.insert(lines, "👤 **User** | ⏳ **Up** | 🖥️ **FPS** | 🧠 **RAM** | 📡 **Ping**")
        table.insert(lines, "--------------------------------------------------")
        
        for _, name in ipairs(sortedNames) do
            local d = allData[name]
            local nameShort = string.sub(name, 1, 10)
            local fpsStr = tostring(d.fps)
            local memStr = tostring(d.mem) .. "MB"
            local pingStr = tostring(d.ping) .. "ms"
            
            local line = string.format("%s `%s` | %s | %s | %s | %s", 
                d.status, nameShort, d.uptime, fpsStr, memStr, pingStr)
            table.insert(lines, line)
        end
        
        table.insert(lines, "--------------------------------------------------")
        table.insert(lines, string.format("📊 **Total RAM:** **%.2f GB**", totalRam / 1024))
        
        local description = table.concat(lines, "\n")
        
        local payloadTable = {
            username = "Pawfy Stealth Monitor",
            embeds = {
                {
                    title = "🛡️ PAWFY ALL-IN-ONE MONITOR",
                    color = 65280, -- 0x00FF7F in decimal
                    description = description,
                    footer = {
                        text = "Optimizer Active • Safe Mode"
                    },
                    timestamp = DateTime.now():ToIsoDate()
                }
            }
        }
        
        local payload = HttpService:JSONEncode(payloadTable)
        
        local msgId = nil
        if hasFileFunctions and isfile(MESSAGE_ID_FILE) then
            msgId = readfile(MESSAGE_ID_FILE)
        end
        
        local url = msgId and (webhook .. "/messages/" .. msgId) or (webhook .. "?wait=true")
        local method = msgId and "PATCH" or "POST"
        
        -- Send request
        local success, result = pcall(function()
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
            local decodeSuccess, responseData = pcall(function()
                return HttpService:JSONDecode(result.Body)
            end)
            
            if decodeSuccess and responseData.id and not msgId and hasFileFunctions then
                pcall(writefile, MESSAGE_ID_FILE, responseData.id)
            end
        end
    end

    task.spawn(function()
        task.wait(2) -- Wait for FPS to stabilize
        local data = updateLocalData(false)
        sendEmbed(data)
    end)
    
    task.spawn(function()
        while true do
            task.wait(BASE_INTERVAL + math.random(5, 15))
            
            local data = updateLocalData(false)
            sendEmbed(data)

            pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
                end
            end)
        end
    end)
    
    print("Embed webhook system active")
else
    print("Webhook system skipped")
end

game:BindToClose(function()
    if hasFileFunctions then
        local allData = {}
        pcall(function()
            if isfile(DATA_PATH) then
                allData = HttpService:JSONDecode(readfile(DATA_PATH))
            end
        end)
        allData[LocalPlayer.Name] = nil
        pcall(writefile, DATA_PATH, HttpService:JSONEncode(allData))
    end
end)

print("✅ PAWFY ALL-IN-ONE MONITOR LOADED")
