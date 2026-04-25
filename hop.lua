local TeleportService = game:GetService("TeleportService")
local Players         = game:GetService("Players")
local HttpService     = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local placeId     = game.PlaceId
local myJobId     = game.JobId

local VISITED_KEY     = "visited_servers"
local TARGET_COLOR    = Color3.fromRGB(253, 255, 137)
local COLOR_TOLERANCE = 5
local WAIT_AFTER_LOAD = 5

local SCRIPT_URL = "https://raw.githubusercontent.com/VounderS/RobloxScript/refs/heads/main/hop.lua" 

local queueteleport = (typeof(queue_on_teleport) == "function" and queue_on_teleport)
    or (syn and typeof(syn.queue_on_teleport) == "function" and syn.queue_on_teleport)
    or (fluxus and typeof(fluxus.queue_on_teleport) == "function" and fluxus.queue_on_teleport)

if queueteleport then
    queueteleport(string.format([[
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer              
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        if not character:FindFirstChild("HumanoidRootPart") then
            character:WaitForChild("HumanoidRootPart", 15)
        end
        task.wait(3)
        print("auto exe")
        loadstring(game:HttpGet("%s", true))()
    ]], SCRIPT_URL))
else
    print("Queue not work with executor, use auto exe")
end

-- VISITED
local function getVisited()
    local ok, data = pcall(function() return shared[VISITED_KEY] or {} end)
    return ok and data or {}
end

local function addVisited(jobId)
    local visited = getVisited()
    visited[jobId] = true
    shared[VISITED_KEY] = visited
end

-- SERVER LIST
local function getServers(cursor)
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
    if cursor and cursor ~= "" then
        url = url .. "&cursor=" .. cursor
    end
    local response = game:HttpGet(url)
    return HttpService:JSONDecode(response)
end

-- COLOR CHECK
local function colorMatch(c1, c2, tolerance)
    return math.abs(c1.R * 255 - c2.R * 255) <= tolerance
       and math.abs(c1.G * 255 - c2.G * 255) <= tolerance
       and math.abs(c1.B * 255 - c2.B * 255) <= tolerance
end

-- GUI HELPER
local function getPlayerGui()
    return LocalPlayer:FindFirstChild("PlayerGui")
end

-- STEP 1: KLIK SLOT 1
local function clickLoadButton()
    local gui = getPlayerGui()
    if not gui then return false end

    local mainMenu = gui:FindFirstChild("MainMenuV2")
    if not mainMenu then return false end

    local slots = mainMenu:FindFirstChild("Slots")
    if not slots then return false end

    local scrollContainer = slots:FindFirstChild("ScrollContainer")
    if not scrollContainer then return false end

    local slotList = scrollContainer:FindFirstChild("SlotList")
    if not slotList then return false end

    local slotCard = slotList:FindFirstChild("SlotCard")
    if not slotCard then return false end

    local container = slotCard:FindFirstChild("Container")
    if not container then return false end

    local header = container:FindFirstChild("Header")
    if not header then return false end

    local loadButton = header:FindFirstChild("LoadButton")
    if not loadButton then return false end

    local btnContainer = loadButton:FindFirstChild("Container")
    if not btnContainer then return false end

    local button = btnContainer:FindFirstChild("Button")
    if not button then return false end

    print("[Auto] Klik Slot 1 LoadButton")
    button.MouseButton1Click:Fire()
    return true
end

-- STEP 2: KLIK CLAIM PROPERTY
local function clickClaimButton()
    local gui = getPlayerGui()
    if not gui then return false end

    local propSelection = gui:FindFirstChild("PropertySelection")
    if not propSelection then return false end

    local propMenu = propSelection:FindFirstChild("PropertyMenu")
    if not propMenu then return false end

    local action = propMenu:FindFirstChild("Action")
    if not action then return false end

    local claimButton = action:FindFirstChild("ClaimButton")
    if not claimButton then return false end

    local container = claimButton:FindFirstChild("Container")
    if not container then return false end

    local button = container:FindFirstChild("Button")
    if not button then return false end

    print("[Auto] Klik ClaimButton")
    button.MouseButton1Click:Fire()
    return true
end

-- STEP 3: TUNGGU WORLD LOAD
local function waitForWorld()
    print("[Auto Hop] Menunggu World load...")

    local world = workspace:FindFirstChild("World")
    while not world do
        task.wait(1)
        world = workspace:FindFirstChild("World")
    end

    local shrine = world:FindFirstChild("HeavenlyShrine")
    while not shrine do
        task.wait(1)
        shrine = world:FindFirstChild("HeavenlyShrine")
    end

    local lightParts = shrine:FindFirstChild("LightParts")
    while not lightParts do
        task.wait(1)
        lightParts = shrine:FindFirstChild("LightParts")
    end

    while #lightParts:GetChildren() < 8 do
        task.wait(1)
    end

    print("[Auto Hop] World loaded! Tunggu", WAIT_AFTER_LOAD, "detik...")
    task.wait(WAIT_AFTER_LOAD)

    return lightParts
end

-- STEP 4: CEK HEAVENLY SHRINE
local function checkHeavenlyShrine(lightParts)
    local found  = 0
    local yellow = 0

    for _, part in ipairs(lightParts:GetChildren()) do
        if part:IsA("BasePart") then
            found += 1
            if colorMatch(part.Color, TARGET_COLOR, COLOR_TOLERANCE) then
                yellow += 1
            end
        end
    end

    print(string.format("[HeavenlyShrine] %d/%d parts yellow", yellow, found))
    return found >= 8 and yellow >= 8
end

-- STEP 5: SERVER HOP
local function serverHop()
    addVisited(myJobId)

    local visited = getVisited()
    local cursor  = ""
    local found   = nil

    repeat
        local ok, data = pcall(getServers, cursor)
        if not ok or not data then break end

        for _, server in ipairs(data.data or {}) do
            if server.id == myJobId then continue end
            if visited[server.id] then continue end
            if server.playing >= server.maxPlayers then continue end
            if server.playing > 0 then
                found = server.id
                break
            end
        end

        cursor = data.nextPageCursor or ""
    until found or cursor == "" or cursor == nil

    if found then
        addVisited(found)
        print("[Auto Hop] Server hop ke:", found)
        TeleportService:TeleportToPlaceInstance(placeId, found, LocalPlayer)
    else
        print("[Auto Hop] Tidak ada server cocok, join server baru")
        TeleportService:Teleport(placeId, LocalPlayer)
    end
end

-- MAIN
task.spawn(function()
    -- STEP 1: tunggu MainMenuV2 lalu klik slot
    print("[Auto Hop] Menunggu MainMenuV2...")
    local gui = getPlayerGui()
    while not (gui and gui:FindFirstChild("MainMenuV2")) do
        task.wait(0.5)
        gui = getPlayerGui()
    end
    task.wait(1)

    for i = 1, 30 do
        if clickLoadButton() then break end
        task.wait(0.5)
    end

    -- STEP 2: tunggu PropertySelection lalu klik claim
    print("[Auto Hop] Menunggu PropertySelection...")
    local gui2 = getPlayerGui()
    while not (gui2 and gui2:FindFirstChild("PropertySelection")) do
        task.wait(0.5)
        gui2 = getPlayerGui()
    end
    task.wait(1)

    for i = 1, 30 do
        if clickClaimButton() then break end
        task.wait(0.5)
    end

    print("[Auto Hop] Slot dan property dipilih!")

    -- STEP 3: tunggu world dan lightparts
    local lightParts = waitForWorld()

    -- STEP 4: cek shrine
    local shrineActive = checkHeavenlyShrine(lightParts)

    -- STEP 5: keputusan
    if shrineActive then
        print("[Auto Hop] HeavenlyShrine AKTIF! Server ini valid, berhenti.")
    else
        print("[Auto Hop] HeavenlyShrine tidak aktif, server hop...")
        serverHop()
    end
end)
