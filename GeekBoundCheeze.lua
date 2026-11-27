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

local FARM_INTERVAL = 5 -- seconds between claims, uncalibrated
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
local SELL_INTERVAL = 5 -- seconds between sells, uncalibrated
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


-- Noclip
-- Noclip (same logic as your original: direct children, set every frame)
local RunService = game:GetService("RunService")
local noclipConn = nil

local function stopNoclip()
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
end

MainTab:CreateToggle({
    Name = "Noclip",
    Description = "Walk through walls and objects",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(Value)
        stopNoclip()
        if not Value then
            return
        end
        noclipConn = RunService.Stepped:Connect(function()
            local character = Players.LocalPlayer.Character
            if not character then
                return
            end
            for _, v in pairs(character:GetChildren()) do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
        end)
    end
})


---------------------------------------------------- teleport section ---------------------------------------------------------------------------------


-- Teleport
local Players = game:GetService("Players")

local TELEPORT_HEIGHT_OFFSET = 0 -- studs added to Y, my choice; raise it if you clip into the floor

-- Coordinates from you, as (X, Y, Z)
local TeleportSpots = {
    { Name = "Bathroom",      Position = Vector3.new(396, 3, -38) },
    { Name = "Sewer Dealer",  Position = Vector3.new(539, -38, 13) },
    { Name = "Arcade",        Position = Vector3.new(1033, 3, -33) },
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

-------------------------------------------------------------- Automatic Section ---------------------------------------------------------------------------

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

-- Auto Cash Pickup
local CASH_INTERVAL = 1 -- seconds between sweeps, from you
local CASH_PROMPT_RANGE = 7 -- MaxActivationDistance in the CashDrops module you pasted
local CASH_STAND_OFFSET = Vector3.new(0, 3, 0) -- where I stand relative to the drop, my choice
local cashToken = 0

local function collectCash(drop)
    local prompt = drop:FindFirstChildOfClass("ProximityPrompt")
    if not prompt or not prompt.Enabled then
        return
    end
    if typeof(fireproximityprompt) == "function" then
        fireproximityprompt(prompt)
    else
        prompt:InputHoldBegin()
        task.wait(0.05)
        prompt:InputHoldEnd()
    end
end

local function sweepCash(myToken)
    local folder = workspace:FindFirstChild("CashDrops")
    local character = Players.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not folder or not root then
        return
    end

    local origin
    for _, drop in ipairs(folder:GetChildren()) do
        if cashToken ~= myToken then
            break
        end
        if drop:IsA("BasePart") and drop.Name == "Cash" and drop.Parent then
            if (root.Position - drop.Position).Magnitude > CASH_PROMPT_RANGE - 1 then
                origin = origin or character:GetPivot()
                character:PivotTo(CFrame.new(drop.Position + CASH_STAND_OFFSET))
                root.AssemblyLinearVelocity = Vector3.zero
                task.wait(0.1)
            end
            collectCash(drop)
        end
    end
    if origin then
        character:PivotTo(origin)
        root.AssemblyLinearVelocity = Vector3.zero
    end
end

AutomaticTab:CreateToggle({
    Name = "Auto Cash Pickup",
    Description = "Grabs every dropped cash pile each second",
    CurrentValue = false,
    Flag = "AutoCashPickup",
    Callback = function(Value)
        cashToken += 1
        if not Value then
            return
        end

        local myToken = cashToken
        task.spawn(function()
            while cashToken == myToken do
                local ok, err = pcall(sweepCash, myToken)
                if not ok then
                    warn("[AutoCash] " .. tostring(err))
                end
                task.wait(CASH_INTERVAL)
            end
        end)
    end
})

-- Force Cash Drops
local CASH_SPAWN_INTERVAL = 5 -- seconds between spawn attempts, my choice; uncalibrated
local CASH_MAX_LIVE = 3 -- same cap as the module's own 3-drop limit; raise to test, my choice
local cashSpawnToken = 0
local spawnNearFn = nil

-- Finds the module's spawnNear by name, then confirms it by its CashDrops folder upvalue
local function findSpawnNear()
    if typeof(getgc) ~= "function" or not (debug and debug.getupvalues) then
        return nil, "executor lacks getgc or debug.getupvalues"
    end
    for _, f in ipairs(getgc()) do
        if type(f) == "function" and debug.info(f, "n") == "spawnNear" then
            local okUp, ups = pcall(debug.getupvalues, f)
            if okUp then
                for _, up in pairs(ups) do
                    if typeof(up) == "Instance" and up.Name == "CashDrops" then
                        return f
                    end
                end
            end
        end
    end
    return nil, "spawnNear not found, the module may not have started yet"
end

local function liveCashCount()
    local folder = workspace:FindFirstChild("CashDrops")
    if not folder then
        return 0
    end
    local n = 0
    for _, c in ipairs(folder:GetChildren()) do
        if c.Name == "Cash" then
            n += 1
        end
    end
    return n
end

AutomaticTab:CreateToggle({
    Name = "Force Cash Drops",
    Description = "Spawns cash drops on demand instead of waiting 90-150 seconds",
    CurrentValue = false,
    Flag = "ForceCashDrops",
    Callback = function(Value)
        cashSpawnToken += 1
        if not Value then
            return
        end

        local myToken = cashSpawnToken
        task.spawn(function()
            local lastErr
            while cashSpawnToken == myToken do
                local ok, err = pcall(function()
                    if not spawnNearFn then
                        local f, why = findSpawnNear()
                        if not f then
                            error(why)
                        end
                        spawnNearFn = f
                    end
                    local character = Players.LocalPlayer.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    if root and liveCashCount() < CASH_MAX_LIVE then
                        spawnNearFn(root.Position)
                    end
                end)
                if not ok and tostring(err) ~= lastErr then
                    lastErr = tostring(err)
                    warn("[ForceCash] " .. lastErr)
                end
                task.wait(CASH_SPAWN_INTERVAL)
            end
        end)
    end
})

-- Daily Sales Cap (slider)
local DAILY_SALES_DEFAULT = 6 -- the module's own value, from your paste
local salesModule = nil

local function findSalesModule()
    if typeof(getgc) ~= "function" then
        return nil, "executor lacks getgc"
    end
    for _, t in ipairs(getgc(true)) do
        if type(t) == "table"
            and type(rawget(t, "DAILY_SALES")) == "number"
            and rawget(t, "MEET_SECONDS") ~= nil
            and type(rawget(t, "sell")) == "function" then
            return t
        end
    end
    return nil, "sales table not found, the module may not have loaded yet"
end

local function applyDailySales(value)
    value = math.floor(tonumber(value) or DAILY_SALES_DEFAULT)
    if not salesModule then
        if value == DAILY_SALES_DEFAULT then
            return -- nothing to change, skip the memory search
        end
        local found, why = findSalesModule()
        if not found then
            warn("[DailySales] " .. tostring(why))
            return
        end
        salesModule = found
    end
    rawset(salesModule, "DAILY_SALES", value)
    print("[DailySales] cap is now " .. tostring(rawget(salesModule, "DAILY_SALES")))
end

AutomaticTab:CreateSlider({
    Name = "Daily Sales Cap",
    Range = {1, 30},
    Increment = 1,
    CurrentValue = DAILY_SALES_DEFAULT,
    Flag = "DailySalesCap",
    Callback = function(Value)
        local ok, err = pcall(applyDailySales, Value)
        if not ok then
            warn("[DailySales] " .. tostring(err))
        end
    end
})

AutomaticTab:CreateButton({
    Name = "Set Daily Sales 30",
    Callback = function()
        local found, why = findSalesModule()
        if not found then
            warn("[DailySales] " .. tostring(why))
            return
        end
        salesModule = found
        rawset(found, "DAILY_SALES", 30)
        print("[DailySales] button set cap to " .. tostring(rawget(found, "DAILY_SALES")))
    end
})


-- Device Sale
local DEVICE_SALE_AMOUNT = 35000 -- from your capture
local DEVICE_SALE_KIND = "devicesale" -- from your capture
local DEVICE_SALE_INTERVAL = 5 -- seconds between sales, my choice; uncalibrated
local DEVICE_REFUSED_WAIT = 60 -- seconds to wait after a false reply, my choice; uncalibrated
local deviceSaleToken = 0

local function sellDevice()
    local remotes = ReplicatedStorage:FindFirstChild("MoneyRemotes")
    local change = remotes and remotes:FindFirstChild("Change")
    if not change then
        error("MoneyRemotes.Change not found")
    end
    return change:InvokeServer(DEVICE_SALE_AMOUNT, DEVICE_SALE_KIND)
end

MainTab:CreateButton({
    Name = "Sell Device",
    Callback = function()
        local ok, result = pcall(sellDevice)
        print("[DeviceSale]", ok, typeof(result), tostring(result))
    end
})

AutomaticTab:CreateToggle({
    Name = "Auto Device Sale",
    Description = "Sells every interval, backs off when the server refuses",
    CurrentValue = false,
    Flag = "AutoDeviceSale",
    Callback = function(Value)
        deviceSaleToken += 1
        if not Value then
            return
        end

        local myToken = deviceSaleToken
        task.spawn(function()
            local sold = 0
            while deviceSaleToken == myToken do
                local ok, result = pcall(sellDevice)
                local waitFor = DEVICE_SALE_INTERVAL
                if not ok then
                    warn("[AutoDeviceSale] " .. tostring(result))
                elseif result == false then
                    print("[AutoDeviceSale] refused after " .. sold .. " accepted calls, waiting " .. DEVICE_REFUSED_WAIT .. "s")
                    sold = 0
                    waitFor = DEVICE_REFUSED_WAIT
                else
                    sold += 1
                    if sold == 1 then
                        print("[AutoDeviceSale] first reply: " .. tostring(result))
                    end
                end
                local deadline = os.clock() + waitFor
                while deviceSaleToken == myToken and os.clock() < deadline do
                    task.wait(0.25)
                end
            end
        end)
    end
})

-- No Shift Cooldown
local SHIFT_CD_POLL = 0.5 -- seconds between resets, my choice
local shiftCdToken = 0
local dinerRecords = {}

-- Diner records from the shift module you pasted: cooldownUntil number, prompts table, model Instance
local function findDinerRecords()
    if typeof(getgc) ~= "function" then
        return nil, "executor lacks getgc"
    end
    local found = {}
    for _, t in ipairs(getgc(true)) do
        if type(t) == "table"
            and type(rawget(t, "cooldownUntil")) == "number"
            and type(rawget(t, "prompts")) == "table"
            and typeof(rawget(t, "model")) == "Instance" then
            found[#found + 1] = t
        end
    end
    if #found == 0 then
        return nil, "no diner records found, the shift module may not have started yet"
    end
    return found
end

AutomaticTab:CreateToggle({
    Name = "No Shift Cooldown",
    Description = "Resets every diner's client-side shift cooldown",
    CurrentValue = false,
    Flag = "NoShiftCooldown",
    Callback = function(Value)
        shiftCdToken += 1
        if not Value then
            return
        end

        local myToken = shiftCdToken
        task.spawn(function()
            local lastErr
            while shiftCdToken == myToken do
                local ok, err = pcall(function()
                    if #dinerRecords == 0 then
                        local found, why = findDinerRecords()
                        if not found then
                            error(why)
                        end
                        dinerRecords = found
                        print("[ShiftCD] found " .. #found .. " diner records")
                    end
                    for _, rec in ipairs(dinerRecords) do
                        rawset(rec, "cooldownUntil", 0)
                    end
                end)
                if not ok and tostring(err) ~= lastErr then
                    lastErr = tostring(err)
                    warn("[ShiftCD] " .. lastErr)
                end
                task.wait(SHIFT_CD_POLL)
            end
        end)
    end
})

-- Auto Shift (server cooldown ~22s, measured with the ShiftProbe)
local SHIFT_ARG = 100
local SHIFT_KIND = "shift"
local SHIFT_PAID_WAIT = 23   -- seconds after a payout, a little over the measured 22.4, my choice
local SHIFT_RETRY_WAIT = 2   -- seconds between tries after a refusal, my choice
local SHIFT_LONG_REFUSAL = 120 -- seconds of nonstop refusals before assuming a longer limit, my choice
local shiftToken = 0

AutomaticTab:CreateToggle({
    Name = "Auto Shift",
    Description = "Claims shift pay every ~23s, retries while the server cooldown runs",
    CurrentValue = false,
    Flag = "AutoShift",
    Callback = function(Value)
        shiftToken += 1
        if not Value then
            return
        end

        local myToken = shiftToken
        task.spawn(function()
            local paid = 0
            local refusedSince = nil
            while shiftToken == myToken do
                local ok, result = pcall(function()
                    local remotes = ReplicatedStorage:FindFirstChild("MoneyRemotes")
                    local change = remotes and remotes:FindFirstChild("Change")
                    if not change then
                        error("MoneyRemotes.Change not found")
                    end
                    return change:InvokeServer(SHIFT_ARG, SHIFT_KIND)
                end)

                local waitFor = SHIFT_RETRY_WAIT
                if not ok then
                    warn("[AutoShift] " .. tostring(result))
                elseif result == false then
                    refusedSince = refusedSince or os.clock()
                    if os.clock() - refusedSince > SHIFT_LONG_REFUSAL then
                        warn("[AutoShift] refused for over " .. SHIFT_LONG_REFUSAL .. "s, maybe a daily earning limit, backing off to 30s tries")
                        waitFor = 30
                    end
                else
                    paid += 1
                    refusedSince = nil
                    waitFor = SHIFT_PAID_WAIT
                    print("[AutoShift] paid call #" .. paid)
                end

                local deadline = os.clock() + waitFor
                while shiftToken == myToken and os.clock() < deadline do
                    task.wait(0.25)
                end
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
