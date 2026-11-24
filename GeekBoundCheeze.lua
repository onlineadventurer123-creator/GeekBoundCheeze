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

-- Auto Ticket Farm
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FARM_INTERVAL = 3 -- seconds between claims, uncalibrated
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

-- Auto Sell
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

-- Teleport
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

-- My Home / Global Leaderboard
local MANUAL_HOME_NAME = nil -- e.g. "Home3"; set this to skip the House attribute
local TARGET_NAME = "GlobalLeaderboard" -- model name from you
local TARGET_HEIGHT_OFFSET = 3 -- studs above the model pivot, my choice; uncalibrated

local function getHomesFolder()
    local map = workspace:FindFirstChild("Map")
    return map and map:FindFirstChild("Homes")
end

-- Home number comes from the player attribute "House" (seen in your HomeMarker script)
local function findMyHome()
    local homes = getHomesFolder()
    if not homes then
        return nil, "Workspace.Map.Homes not found"
    end
    if MANUAL_HOME_NAME then
        return homes:FindFirstChild(MANUAL_HOME_NAME), "manual"
    end
    local houseNumber = Players.LocalPlayer:GetAttribute("House")
    if type(houseNumber) ~= "number" then
        return nil, "player attribute House is not set (yet)"
    end
    local home = homes:FindFirstChild("Home" .. houseNumber)
    if not home then
        return nil, "no Home" .. houseNumber .. " folder under Workspace.Map.Homes"
    end
    return home, "player attribute House=" .. houseNumber
end

local function targetPosition(target)
    if target:IsA("Model") then
        return target:GetPivot().Position
    end
    return target.Position
end

local function findLeaderboard()
    local home, how = findMyHome()
    if home then
        local inHome = home:FindFirstChild(TARGET_NAME, true)
        if inHome then
            return inHome, "inside " .. home.Name
        end
    end
    local homes = getHomesFolder()
    if homes then
        local besideHomes = homes:FindFirstChild(TARGET_NAME) -- direct child only
        if besideHomes then
            return besideHomes, "direct child of Homes"
        end
    end
    local map = workspace:FindFirstChild("Map")
    local inMap = map and map:FindFirstChild(TARGET_NAME) -- direct child only
    if inMap then
        return inMap, "direct child of Map"
    end
    return nil, TARGET_NAME .. " not found (home lookup said: " .. tostring(how) .. ")"
end

TeleportTab:CreateButton({
    Name = "Teleport: Global Leaderboard",
    Callback = function()
        local target, how = findLeaderboard()
        if not target then
            warn("[Leaderboard] " .. tostring(how))
            return
        end
        if not (target:IsA("Model") or target:IsA("BasePart")) then
            warn("[Leaderboard] " .. target:GetFullName() .. " is a " .. target.ClassName .. ", not a Model or part")
            return
        end
        print("[Leaderboard] " .. target:GetFullName() .. " via " .. how)
        teleportTo(targetPosition(target) + Vector3.new(0, TARGET_HEIGHT_OFFSET, 0))
    end
})

TeleportTab:CreateButton({
    Name = "Dump My Home",
    Callback = function()
        local home, how = findMyHome()
        if not home then
            warn("[Dump] " .. tostring(how))
            return
        end
        print("[Dump] " .. home:GetFullName() .. " via " .. how)
        for k, v in pairs(home:GetAttributes()) do
            print("  attr " .. k .. " = " .. tostring(v))
        end
        for _, d in ipairs(home:GetDescendants()) do
            print("  " .. d.ClassName .. " " .. d:GetFullName())
        end
    end
})

-- Dump All Homes
local DUMP_LINE_CAP = 150 -- lines printed per home, my choice

local function describeInteresting(d)
    if d:IsA("ValueBase") then
        return d.ClassName .. " " .. d:GetFullName() .. " = " .. tostring(d.Value)
    end
    if d:IsA("TextLabel") or d:IsA("TextButton") then
        return d.ClassName .. " " .. d:GetFullName() .. " text=" .. d.Text
    end
    local parts = {}
    for k, v in pairs(d:GetAttributes()) do
        parts[#parts + 1] = k .. "=" .. tostring(v)
    end
    if #parts > 0 then
        return d.ClassName .. " " .. d:GetFullName() .. " attrs: " .. table.concat(parts, ", ")
    end
    return nil
end

TeleportTab:CreateButton({
    Name = "Dump All Homes",
    Callback = function()
        local homes = getHomesFolder()
        if not homes then
            warn("[DumpAll] Workspace.Map.Homes not found")
            return
        end
        for _, home in ipairs(homes:GetChildren()) do
            print("[DumpAll] ===== " .. home:GetFullName() .. " =====")
            local printed = 0
            local function emit(line)
                if printed < DUMP_LINE_CAP then
                    print("  " .. line)
                    printed += 1
                end
            end
            local own = describeInteresting(home)
            if own then emit(own) end
            for _, d in ipairs(home:GetDescendants()) do
                local line = describeInteresting(d)
                if line then emit(line) end
                if d.Name == TARGET_NAME then
                    emit("TARGET " .. d.ClassName .. " " .. d:GetFullName())
                end
            end
            if printed >= DUMP_LINE_CAP then
                print("  (capped at " .. DUMP_LINE_CAP .. " lines)")
            end
        end
    end
})

-- Auto Curfew
local CURFEW_TELEPORT_MINUTE = 21 * 60 + 31 -- 9:31 PM, minutes after midnight; your time, read as PM
local CLOCK_POLL = 0.25 -- seconds between clock checks, my choice
local MAX_CLOCK_JUMP = 10 -- game minutes; a bigger jump (stall, sleep) is ignored, my choice
local curfewToken = 0

-- Constants copied from the game's clock module you pasted
local CLOCK_DAY_START = 420
local CLOCK_SCHOOL_START = 555
local CLOCK_SCHOOL_END = 945
local CLOCK_SLOW = 2.5
local CLOCK_MORNING = CLOCK_SCHOOL_START - CLOCK_DAY_START
local CLOCK_SCHOOL = (CLOCK_SCHOOL_END - CLOCK_SCHOOL_START) * CLOCK_SLOW
local CLOCK_EVENING = CLOCK_DAY_START + 1440 - CLOCK_SCHOOL_END
local CLOCK_DAY_SECONDS = CLOCK_MORNING + CLOCK_SCHOOL + CLOCK_EVENING

-- Returns game minutes after midnight, or nil if ClockStart is not a number
local function gameMinutes()
    local start = workspace:GetAttribute("ClockStart")
    if type(start) ~= "number" then
        return nil
    end
    local seconds = math.max(workspace:GetServerTimeNow() - start, 0) % CLOCK_DAY_SECONDS
    local minutes
    if seconds < CLOCK_MORNING then
        minutes = CLOCK_DAY_START + seconds
    else
        local school = seconds - CLOCK_MORNING
        if school < CLOCK_SCHOOL then
            minutes = CLOCK_SCHOOL_START + school / CLOCK_SLOW
        else
            minutes = CLOCK_SCHOOL_END + (school - CLOCK_SCHOOL)
        end
    end
    return minutes % 1440
end

local function teleportToLeaderboard()
    local target, how = findLeaderboard()
    if not target then
        warn("[AutoCurfew] " .. tostring(how))
        return
    end
    if not (target:IsA("Model") or target:IsA("BasePart")) then
        warn("[AutoCurfew] " .. target:GetFullName() .. " is a " .. target.ClassName .. ", not a Model or part")
        return
    end
    print("[AutoCurfew] " .. target:GetFullName() .. " via " .. how)
    teleportTo(targetPosition(target) + Vector3.new(0, TARGET_HEIGHT_OFFSET, 0))
end

local AutomaticTab = Window:CreateTab({
    Name = "Automatic",
    Icon = "autorenew",
    ImageSource = "Material",
    ShowTitle = true
})

AutomaticTab:CreateToggle({
    Name = "Auto Curfew",
    Description = "Teleports to Global Leaderboard at 9:31 PM game time",
    CurrentValue = false,
    Flag = "AutoCurfew",
    Callback = function(Value)
        curfewToken += 1
        if not Value then
            return
        end

        local myToken = curfewToken
        task.spawn(function()
            local warnedNoClock = false
            local previous = gameMinutes()
            while curfewToken == myToken do
                task.wait(CLOCK_POLL)
                local current = gameMinutes()
                if current == nil then
                    if not warnedNoClock then
                        warn("[AutoCurfew] workspace attribute ClockStart is not a number, waiting")
                        warnedNoClock = true
                    end
                elseif previous ~= nil
                    and previous < CURFEW_TELEPORT_MINUTE
                    and current >= CURFEW_TELEPORT_MINUTE
                    and current - previous < MAX_CLOCK_JUMP then
                    local ok, err = pcall(teleportToLeaderboard)
                    if not ok then
                        warn("[AutoCurfew] " .. tostring(err))
                    end
                end
                previous = current
            end
        end)
    end
})

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
