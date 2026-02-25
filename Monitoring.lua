
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")
local NetworkClient = game:GetService("NetworkClient")

local LocalPlayer = Players.LocalPlayer
local request = http_request or (http and http.request) or (syn and syn.request) or request

--// CONFIGURATION
local WEBHOOK_FILE = "pawfy-webhook.json" 
local DATA_PATH = "pawfy-multi-instance.json" 
local MESSAGE_ID_FILE = "pawfy-message-id.txt" 
local BASE_INTERVAL = 40 

local webhook
local startTime = os.time()


local function OptimizeGame()

    if setfpscap then setfpscap(5) end
    

    settings().Rendering.QualityLevel = 1
    RunService:Set3dRenderingEnabled(false) 
    

    task.spawn(function()
        local cam = workspace.CurrentCamera
        RunService.RenderStepped:Connect(function()
            cam.CFrame = CFrame.new(0, 500, 0) * CFrame.Angles(math.rad(-90), 0, 0)
        end)
    end)
    

    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("Decal") or v:IsA("Texture") then
            v:Destroy()
        end
    end
end

--// 2. FUNGSI LOAD/SAVE WEBHOOK
local function loadWebhook()
    if isfile(WEBHOOK_FILE) then
        local s, content = pcall(readfile, WEBHOOK_FILE)
        if s then
            local ok, cfg = pcall(HttpService.JSONDecode, HttpService, content)
            if ok and cfg.webhook then return cfg.webhook end
        end
    end
    return nil
end

webhook = loadWebhook()


if not webhook or webhook == "" then
    local sg = Instance.new("ScreenGui", game.CoreGui)
    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.fromScale(0.4, 0.3); frame.Position = UDim2.fromScale(0.5, 0.5); frame.AnchorPoint = Vector2.new(0.5, 0.5); frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Instance.new("UICorner", frame)

    local box = Instance.new("TextBox", frame)
    box.Size = UDim2.fromScale(0.8, 0.25); box.Position = UDim2.fromScale(0.1, 0.3); box.PlaceholderText = "Input Webhook Disini"
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.fromScale(0.4, 0.2); btn.Position = UDim2.fromScale(0.3, 0.65); btn.Text = "SAVE"; btn.BackgroundColor3 = Color3.fromRGB(0, 120, 0); btn.TextColor3 = Color3.new(1,1,1)

    btn.MouseButton1Click:Connect(function()
        if box.Text:find("discord") then
            webhook = box.Text:gsub("%s+", "")
            writefile(WEBHOOK_FILE, HttpService:JSONEncode({webhook = webhook}))
            sg:Destroy()
        end
    end)
    repeat task.wait(1) until webhook and webhook ~= ""
end


local function updateLocalData(is_offline)
    local allData = {}
    pcall(function()
        if isfile(DATA_PATH) then allData = HttpService:JSONDecode(readfile(DATA_PATH)) end
    end)

    if is_offline then
        allData[LocalPlayer.Name] = nil 
    else

        local fps = math.floor(1/RunService.RenderStepped:Wait())
        
        local ping = "N/A"
        pcall(function()
            local p = LocalPlayer:GetNetworkPing()
            ping = (p > 0) and math.floor(p * 1000) .. "ms" or math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) .. "ms"
        end)
        
        local uptime_s = os.time() - startTime
        allData[LocalPlayer.Name] = {
            status = "🟢",
            uptime = string.format("%02d:%02d", uptime_s//3600, (uptime_s%3600)//60),
            perf = fps .. " FPS",
            mem = math.floor(Stats:GetTotalMemoryUsageMb()) .. "MB",
            ping = ping,
            lastUpdate = os.time()
        }
    end
    
    for name, data in pairs(allData) do
        if os.time() - data.lastUpdate > 150 then allData[name] = nil end
    end

    pcall(writefile, DATA_PATH, HttpService:JSONEncode(allData))
    return allData
end

local function sendGlobalEmbed(allData)
    local sortedNames = {}
    local totalRam = 0
    for name, data in pairs(allData) do 
        table.insert(sortedNames, name) 
        totalRam = totalRam + tonumber(data.mem:match("%d+"))
    end
    table.sort(sortedNames)
    
    if sortedNames[1] ~= LocalPlayer.Name then return end

    local list = "👤 **User** | ⏳ **Up** | 🖥️ **FPS** | 🧠 **RAM** | 📡 **Ping**\n"
    list = list .. "--------------------------------------------------\n"
    for _, name in ipairs(sortedNames) do
        local d = allData[name]
        list = list .. string.format("%s `%s` | %s | %s | %s | %s\n", 
            d.status, name:sub(1,10), d.uptime, d.perf, d.mem, d.ping)
    end
    list = list .. "--------------------------------------------------\n"
    list = list .. string.format("📊 **Total RAM:** **%.2f GB**", totalRam/1024)

    local payload = HttpService:JSONEncode({
        username = "Pawfy Stealth Monitor",
        embeds = {{
            title = "🛡️ PAWFY ALL-IN-ONE MONITOR",
            color = 0x00FF7F,
            description = list,
            footer = { text = "Optimizer Active • Safe Mode" },
            timestamp = DateTime.now():ToIsoDate()
        }}
    })

    local msgId = isfile(MESSAGE_ID_FILE) and readfile(MESSAGE_ID_FILE) or nil
    local url = msgId and (webhook .. "/messages/" .. msgId) or (webhook .. "?wait=true")
    
    pcall(function()
        local res = request({
            Url = url,
            Method = msgId and "PATCH" or "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = payload
        })
        if not msgId and res then
            local d = HttpService:JSONDecode(res.Body)
            if d.id then writefile(MESSAGE_ID_FILE, d.id) end
        end
    end)
end

OptimizeGame()

task.spawn(function()
    while true do
        local data = updateLocalData(false)
        sendGlobalEmbed(data)
        
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
            end
        end)
        
        task.wait(BASE_INTERVAL + math.random(5, 15))
    end
end)

game:BindToClose(function() updateLocalData(true) end)
print("✅ Pawfy All-in-One Stealth Loaded!")
