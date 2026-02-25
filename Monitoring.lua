local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local WEBHOOK_FILE = "pawfy-webhook.json"
local DATA_PATH = "pawfy-multi.json"
local MSG_ID_PATH = "pawfy-msgid.txt"

local request = (fluxus and fluxus.request) or (syn and syn.request) or http_request or request or (http and http.request)
local LocalPlayer = Players.LocalPlayer
local StartTime = os.time()
local webhook = ""

if setfpscap then setfpscap(5) end
settings().Rendering.QualityLevel = 1
task.spawn(function()
    RunService.RenderStepped:Connect(function()
        workspace.CurrentCamera.CFrame = CFrame.new(0, 1000, 0) * CFrame.Angles(math.rad(-90), 0, 0)
    end)
end)

local function loadWebhook()
    if isfile(WEBHOOK_FILE) then
        local s, cfg = pcall(HttpService.JSONDecode, HttpService, readfile(WEBHOOK_FILE))
        if s and cfg.webhook then return cfg.webhook end
    end
    return ""
end

webhook = loadWebhook()

if webhook == "" then
    local sg = Instance.new("ScreenGui", game.CoreGui)
    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.fromScale(0.5, 0.4); frame.Position = UDim2.fromScale(0.5, 0.5); frame.AnchorPoint = Vector2.new(0.5, 0.5); frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

    local input = Instance.new("TextBox", frame)
    input.Size = UDim2.fromScale(0.8, 0.2); input.Position = UDim2.fromScale(0.1, 0.35); input.PlaceholderText = "Paste Webhook Discord Disini"

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.fromScale(0.4, 0.2); btn.Position = UDim2.fromScale(0.3, 0.7); btn.Text = "SAVE & START"; btn.BackgroundColor3 = Color3.fromRGB(0, 150, 0); btn.TextColor3 = Color3.new(1, 1, 1)

    btn.MouseButton1Click:Connect(function()
        if input.Text:find("discord") then
            webhook = input.Text:gsub(" ", "")
            writefile(WEBHOOK_FILE, HttpService:JSONEncode({webhook = webhook}))
            sg:Destroy()
        end
    end)
    repeat task.wait(1) until webhook ~= ""
end

local function UpdateData()
    local allData = {}
    pcall(function() if isfile(DATA_PATH) then allData = HttpService:JSONDecode(readfile(DATA_PATH)) end end)

    local uptime_s = os.time() - StartTime
    
    local pingValue = "N/A"
    pcall(function()
        local rawPing = LocalPlayer:GetNetworkPing()
        pingValue = (rawPing and rawPing > 0) and math.floor(rawPing * 1000) or math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    end)

    local fps = 0
    pcall(function()
        fps = math.floor(1 / RunService.RenderStepped:Wait())
    end)

    allData[LocalPlayer.Name] = {
        uptime = string.format("%02d:%02d", uptime_s//3600, (uptime_s%3600)//60),
        ram = math.floor(Stats:GetTotalMemoryUsageMb()) .. "MB",
        ping = tostring(pingValue) .. "ms",
        cpu = fps .. " FPS", 
        lastSeen = os.time()
    }

    for name, info in pairs(allData) do
        if os.time() - info.lastSeen > 150 then allData[name] = nil end
    end

    writefile(DATA_PATH, HttpService:JSONEncode(allData))
    return allData
end

local function SendDiscord(allData)
    local names = {}
    for n in pairs(allData) do table.insert(names, n) end
    table.sort(names)

    if names[1] ~= LocalPlayer.Name then return end

    local list = ""
    for _, n in ipairs(names) do
        local d = allData[n]
        list = list .. string.format("🟢 `%s` | %s | %s | %s | %s\n", n:sub(1,10), d.uptime, d.ram, d.ping, d.cpu)
    end

    local payload = HttpService:JSONEncode({
        embeds = {{
            title = "🛡️ PAWFY MULTI-MONITOR (CPU)",
            description = "**User** | **Up** | **RAM** | **Ping** | **CPU**\n" .. list,
            color = 65407,
            footer = { text = "Monitoring Bot | Pawfy Sys" },
            timestamp = DateTime.now():ToIsoDate()
        }}
    })

    local msgId = isfile(MSG_ID_PATH) and readfile(MSG_ID_PATH) or nil
    local url = msgId and (webhook .. "/messages/" .. msgId) or (webhook .. "?wait=true")

    pcall(function()
        local res = request({
            Url = url,
            Method = msgId and "PATCH" or "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = payload
        })
        if not msgId and res then
            local data = HttpService:JSONDecode(res.Body)
            if data.id then writefile(MSG_ID_PATH, data.id) end
        end
    end)
end

--// 6. MAIN LOOP
task.spawn(function()
    while true do
        local currentData = UpdateData()
        SendDiscord(currentData)
        
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        
        task.wait(35 + math.random(5, 10))
    end
end)

print("✅ Pawfy Monitor Active!")
