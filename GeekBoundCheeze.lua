local Luna = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua",
    true
))()

local Window = Luna:CreateWindow({
    Name = "GeekBound",
    Subtitle = "",
    LogoID = "82795327169782",

    LoadingEnabled = true,
    LoadingTitle = "Luna",
    LoadingSubtitle = "Loading...",

    ConfigSettings = {
        RootFolder = nil,
        ConfigFolder = "Big Hub"
    },

    KeySystem = false
})

Window:CreateHomeTab({
    SupportedExecutors = {},
    DiscordInvite = "",
    Icon = 1
})

local MainTab = Window:CreateTab({
    Name = "Main",
    Icon = "view_in_ar",
    ImageSource = "Material",
    ShowTitle = true
})

-- Tickets
MainTab:CreateButton({
    Name = "Get 300 Tickets",
    Callback = function()
        local Event = game:GetService("ReplicatedStorage").MoneyRemotes.Tickets

        Event:InvokeServer(
            "won",
            300
        )
    end
})



local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FARM_INTERVAL = 1 -- seconds between claims, uncalibrated
local farmToken = 0

MainTab:CreateToggle({
    Name = "Auto Ticket Farm",
    Description = "Claims 300 tickets every interval",
    CurrentValue = false,
    Flag = "AutoTicketFarm",
    Callback = function(Value)
        farmToken += 1
        if not Value then
            return
        end

        local myToken = farmToken
        task.spawn(function()
            while farmToken == myToken do
                local ok, err = pcall(function()
                    local remotes = ReplicatedStorage:FindFirstChild("MoneyRemotes")
                    local tickets = remotes and remotes:FindFirstChild("Tickets")
                    if not tickets then
                        error("MoneyRemotes.Tickets not found")
                    end
                    tickets:InvokeServer("won", 300)
                end)
                if not ok then
                    warn("[AutoTicketFarm] " .. tostring(err))
                end
                task.wait(FARM_INTERVAL)
            end
        end)
    end
})


local SELL_INTERVAL = 1 -- seconds between sells, uncalibrated
local SELL_AMOUNT = 300 -- from your Cobalt capture
local sellToken = 0

MainTab:CreateToggle({
    Name = "Auto Sell",
    Description = "Cashes out tickets every interval",
    CurrentValue = false,
    Flag = "AutoSell",
    Callback = function(Value)
        sellToken += 1
        if not Value then
            return
        end

        local myToken = sellToken
        task.spawn(function()
            while sellToken == myToken do
                local ok, err = pcall(function()
                    local remotes = ReplicatedStorage:FindFirstChild("MoneyRemotes")
                    local tickets = remotes and remotes:FindFirstChild("Tickets")
                    if not tickets then
                        error("MoneyRemotes.Tickets not found")
                    end
                    tickets:InvokeServer("cash", SELL_AMOUNT)
                end)
                if not ok then
                    warn("[AutoSell] " .. tostring(err))
                end
                task.wait(SELL_INTERVAL)
            end
        end)
    end
})




local Players = game:GetService("Players")

local TELEPORT_HEIGHT_OFFSET = 0 -- studs added to Y, my choice; raise it if you clip into the floor

-- Coordinates from you, as (X, Y, Z)
local TeleportSpots = {
    { Name = "Bathroom",         Position = Vector3.new(396, 3, -38) },
    { Name = "Kawaii Deal Man",  Position = Vector3.new(539, -38, 13) },
    { Name = "Arcade",           Position = Vector3.new(1033, 3, -33) },
}

local function teleportTo(position)
    local character = Players.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        warn("[Teleport] no HumanoidRootPart, character not loaded")
        return false
    end
    character:PivotTo(CFrame.new(position + Vector3.new(0, TELEPORT_HEIGHT_OFFSET, 0)))
    root.AssemblyLinearVelocity = Vector3.zero
    return true
end

local TeleportTab = Window:CreateTab({
    Name = "Teleport",
    Icon = "near_me",
    ImageSource = "Material",
    ShowTitle = true
})

for _, spot in ipairs(TeleportSpots) do
    TeleportTab:CreateButton({
        Name = "Teleport: " .. spot.Name,
        Callback = function()
            teleportTo(spot.Position)
        end
    })
end

local ThemeTab = Window:CreateTab({
    Name = "Theme",
    Icon = "palette",
    ImageSource = "Material",
    ShowTitle = true
})

ThemeTab:BuildThemeSection()

local SettingsTab = Window:CreateTab({
    Name = "Settings",
    Icon = "settings",
    ImageSource = "Material",
    ShowTitle = true
})

SettingsTab:BuildConfigSection()
