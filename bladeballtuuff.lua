--[[
  blade ball — tweaked a bunch, not a "clean rewrite"
  if something breaks ping me with the line # lol
]]
local sqrt = math.sqrt
local min, max = math.min, math.max
local TAB = "Secret.cc"

local function xyz(v)
    if not v then return end
    return v.X, v.Y, v.Z
end

local function len3(v)
    local x, y, z = xyz(v)
    if not x then return 0 end
    return sqrt(x * x + y * y + z * z)
end

local function dist(a, b)
    local ax, ay, az = xyz(a)
    local bx, by, bz = xyz(b)
    if not ax or not bx then return math.huge end
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return sqrt(dx * dx + dy * dy + dz * dz)
end

local function norm(v)
    local x, y, z = xyz(v)
    if not x then return Vector3.new(0, 0, 0) end
    local m = sqrt(x * x + y * y + z * z)
    if m < 0.001 then return Vector3.new(0, 0, 0) end
    local inv = 1 / m
    return Vector3.new(x * inv, y * inv, z * inv)
end

local function clamp(v, lo, hi)
    return min(max(v, lo), hi)
end

local function rnd(lo, hi)
    if utility and utility.RandomFloat then
        return utility.RandomFloat(lo, hi)
    end
    return lo + (hi - lo) * math.random()
end

local function rndi(lo, hi)
    return math.floor(rnd(lo, hi + 0.999))
end

local function attr(inst, name)
    if not inst or not inst.GetAttributes then return nil end
    local attrs = inst:GetAttributes()
    if type(attrs) ~= "table" then return nil end
    for i = 1, #attrs do
        local row = attrs[i]
        if row and row.Name == name then
            return row.Value
        end
    end
    return nil
end

local function tick()
    return utility.GetTickCount()
end

local clashOn = false
local clashTicks = {}
local function patchUiTab(name)
    local f = ui[name]
    if type(f) ~= "function" then return end
    ui[name] = function(tabRef, ...)
        return f(tabRef, ...)
    end
end

do
    local uiWrapList = {
        "getValue", "setValue", "setVisibility",
        "newTab", "newContainer", "newCheckbox", "newButton", "newDropdown",
        "newSliderFloat", "newSliderInt", "newColorpicker",
    }
    for i = 1, #uiWrapList do
        patchUiTab(uiWrapList[i])
    end
end

local function clashSpam(windowSeconds, threshold)
    local t0 = tick() / 1000
    clashTicks[#clashTicks + 1] = t0
    local cut = t0 - windowSeconds
    for i = #clashTicks, 1, -1 do
        if clashTicks[i] < cut then
            table.remove(clashTicks, i)
        end
    end
    return #clashTicks >= threshold
end

local function buildUi()
    ui.newTab(TAB, TAB)

    ui.newContainer(TAB, "parry", "Auto Parry", { autosize = true, next = true })
    ui.newCheckbox(TAB, "parry", "Enabled")
    ui.newSliderFloat(TAB, "parry", "Base Mult", 0.10, 2.00, 0.85)
    ui.newSliderFloat(TAB, "parry", "Accel Boost", 0.00, 1.00, 0.25)
    ui.newSliderFloat(TAB, "parry", "Execute Ratio", 0.10, 1.00, 0.65)
    ui.newSliderFloat(TAB, "parry", "TTI Cap", 0.20, 2.00, 1.10)
    ui.newSliderInt(TAB, "parry", "Close Range Distance", 5, 100, 40)
    ui.newSliderFloat(TAB, "parry", "Close Range TTI", 0.05, 0.80, 0.250)

    ui.newContainer(TAB, "clash", "Clash Mode", { autosize = true, next = true })
    ui.newCheckbox(TAB, "clash", "Enabled")
    ui.newSliderFloat(TAB, "clash", "Clash Window", 0.10, 1.00, 0.35)
    ui.newSliderInt(TAB, "clash", "Clash Threshold", 1, 6, 2)
    ui.newSliderInt(TAB, "clash", "Clash Activate Distance", 5, 60, 25)
    ui.newSliderInt(TAB, "clash", "Clash Deactivate Distance", 10, 80, 35)

    ui.newContainer(TAB, "misc", "Misc", { autosize = true, next = true })
    ui.newCheckbox(TAB, "misc", "Hit Circle")
    ui.newColorpicker(TAB, "misc", "Hit Circle Color", { r = 255, g = 255, b = 255, a = 200 }, true)
    ui.newSliderFloat(TAB, "misc", "Hit Circle Size", 30, 260, 120)
    ui.newSliderInt(TAB, "misc", "Hit Circle Duration", 200, 2500, 900)
    ui.newCheckbox(TAB, "misc", "Rage on ball")
    ui.newSliderFloat(TAB, "misc", "Rage Height", 1.0, 25.0, 1.0)
    ui.newSliderFloat(TAB, "misc", "Rage Speed", 0.0, 100.0, 13.0)
    ui.newSliderFloat(TAB, "misc", "Rage Distance", 0.0, 60.0, 30.0)
    ui.newCheckbox(TAB, "misc", "tp to ball")
    ui.newSliderFloat(TAB, "misc", "tp to ball distance", 2.0, 80.0, 10.0)
    ui.newSliderFloat(TAB, "misc", "tp to ball interval", 0.2, 5.0, 1.0)
    ui.newCheckbox(TAB, "misc", "China hat")
    ui.newColorpicker(TAB, "misc", "China hat Color", { r = 255, g = 90, b = 90, a = 255 }, true)
    ui.newCheckbox(TAB, "misc", "China hat self esp")
    ui.newSliderFloat(TAB, "misc", "China hat max distance", 50.0, 2000.0, 500.0)
    ui.newCheckbox(TAB, "misc", "Auto play")
    ui.newButton(TAB, "misc", " auto parry and clash mode needs to be turned on", function()
        print("[Auto play] auto parry and clash mode needs to be turned on")
    end)

    ui.newContainer(TAB, "vis", "Visuals", { autosize = true })
    ui.newCheckbox(TAB, "vis", "Distance")
    ui.newColorpicker(TAB, "vis", "Distance Color", { r = 255, g = 255, b = 255, a = 255 }, true)
    ui.newCheckbox(TAB, "vis", "Hit Info")
    ui.newColorpicker(TAB, "vis", "Hit Info Accent", { r = 0, g = 255, b = 255, a = 255 }, true)
    ui.newCheckbox(TAB, "vis", "Snaplines")
    ui.newColorpicker(TAB, "vis", "Snapline Color", { r = 255, g = 255, b = 255, a = 255 }, true)
    ui.newCheckbox(TAB, "vis", "Traces")
    ui.newColorpicker(TAB, "vis", "Traces Color", { r = 200, g = 140, b = 255, a = 210 }, true)
    ui.newCheckbox(TAB, "vis", "Range Circle")
    ui.newColorpicker(TAB, "vis", "Range Circle Color", { r = 255, g = 255, b = 255, a = 255 }, true)
    ui.newCheckbox(TAB, "vis", "Time Ball")
    ui.newColorpicker(TAB, "vis", "Time Ball Color", { r = 255, g = 255, b = 120, a = 255 }, true)
    ui.newDropdown(TAB, "vis", "Time Ball Unit", { "Milliseconds", "Seconds", "Auto" }, 1)
    ui.newCheckbox(TAB, "vis", "Trails")
    ui.newColorpicker(TAB, "vis", "Trail Color", { r = 255, g = 255, b = 255, a = 255 }, true)
    ui.newCheckbox(TAB, "vis", "Self Trail")
    ui.newSliderInt(TAB, "vis", "Trail Length", 10, 400, 120)
    ui.newSliderInt(TAB, "vis", "Trail Fade", 0, 100, 40)
    ui.newSliderFloat(TAB, "vis", "Trail Max Thickness", 0.2, 8.0, 3.2)
    ui.newSliderFloat(TAB, "vis", "Trail Min Thickness", 0.1, 6.0, 1.2)
    ui.newSliderInt(TAB, "vis", "Trail Opacity", 20, 255, 255)
    ui.newSliderInt(TAB, "vis", "Trail Step", 1, 4, 1)
    ui.newCheckbox(TAB, "vis", "Trail End Dot")
    ui.newCheckbox(TAB, "vis", "Watermark")
    ui.newCheckbox(TAB, "vis", "Combat Notify")
    ui.newCheckbox(TAB, "vis", "Headdot")
    ui.newColorpicker(TAB, "vis", "Headdot Color", { r = 255, g = 60, b = 60, a = 255 }, true)
    ui.newCheckbox(TAB, "vis", "Team check", true)
    ui.newCheckbox(TAB, "vis", "Status ESP")
    ui.newColorpicker(TAB, "vis", "Status ESP Color", { r = 255, g = 255, b = 255, a = 255 }, true)
    ui.newCheckbox(TAB, "vis", "Particles")
    ui.newDropdown(TAB, "vis", "Particle Style", { "Burst", "Spiral", "Spark" }, 1)
    ui.newColorpicker(TAB, "vis", "Particle Color", { r = 255, g = 255, b = 255, a = 220 }, true)

    local defaults = {
        { TAB, "parry", "Enabled", false },
        { TAB, "clash", "Enabled", false },
        { TAB, "vis", "Distance", false },
        { TAB, "vis", "Hit Info", false },
        { TAB, "vis", "Snaplines", false },
        { TAB, "vis", "Traces", false },
        { TAB, "vis", "Traces Color", { r = 200, g = 140, b = 255, a = 210 } },
        { TAB, "vis", "Range Circle", false },
        { TAB, "vis", "Time Ball", false },
        { TAB, "vis", "Time Ball Unit", 1 },
        { TAB, "vis", "Trails", false },
        { TAB, "vis", "Self Trail", false },
        { TAB, "vis", "Trail Opacity", 255 },
        { TAB, "vis", "Trail Step", 1 },
        { TAB, "vis", "Trail End Dot", false },
        { TAB, "vis", "Watermark", false },
        { TAB, "vis", "Combat Notify", false },
        { TAB, "vis", "Headdot", false },
        { TAB, "vis", "Headdot Color", { r = 255, g = 60, b = 60, a = 255 } },
        { TAB, "vis", "Team check", false },
        { TAB, "misc", "Hit Circle", false },
        { TAB, "vis", "Status ESP", false },
        { TAB, "vis", "Particles", false },
        { TAB, "misc", "Rage on ball", false },
        { TAB, "misc", "Rage Height", 1.0 },
        { TAB, "misc", "Rage Speed", 13.0 },
        { TAB, "misc", "Rage Distance", 30.0 },
        { TAB, "misc", "tp to ball", false },
        { TAB, "misc", "tp to ball distance", 10.0 },
        { TAB, "misc", "tp to ball interval", 1.0 },
        { TAB, "misc", "China hat", false },
        { TAB, "misc", "China hat Color", { r = 255, g = 90, b = 90, a = 255 } },
        { TAB, "misc", "China hat self esp", false },
        { TAB, "misc", "China hat max distance", 500.0 },
        { TAB, "misc", "Auto play", false }
    }

    for _, item in ipairs(defaults) do
        ui.setValue(item[1], item[2], item[3], item[4])
    end
end

buildUi()

local fb = {
    BaseMult = 0.85,
    AccelBoost = 0.25,
    ExecuteRatio = 0.65,
    TTICap = 1.10,
    
    ClashWindow = 0.35,
    ClashThreshold = 2,
    ClashActivateDist = 25,
    ClashDeactivateDist = 35,
    
    CloseRangeDist = 40,
    CloseRangeTTI = 0.250
}

local bb = {
    player = nil,
    playerName = "",
    root = nil,
    pos = nil,
    
    ball = nil,
    ballPos = nil,
    ballVel = nil,
    ballSpeed = 0,
    
    distance = math.huge,
    distanceToHitbox = math.huge,
    tti = 0,
    isReal = false,
    isTargetingMe = false,
    
    alive = true,
    wasAlive = true,
    
    parryDist = 15,
    commitDist = 20,
    parried = false,
    
    committed = false,
    wasTargeting = false,
    
    distanceClosingSmooth = 0,
    currentMult = 0.85,
    
    reason = "Ready"
}

local theme = {
    gn = Color3.fromRGB(50, 255, 150),
    yl = Color3.fromRGB(255, 220, 50),
    rd = Color3.fromRGB(255, 70, 70),
    cy = Color3.fromRGB(0, 255, 255),
    wh = Color3.fromRGB(255, 255, 255),
    gy = Color3.fromRGB(150, 150, 150),
    dk = Color3.fromRGB(25, 25, 30),
    or_ = Color3.fromRGB(255, 150, 50),
    bl = Color3.fromRGB(100, 150, 255),
    mg = Color3.fromRGB(255, 50, 200),
    pr = Color3.fromRGB(180, 100, 255),
}

local spdHist = {}
local dstHist = {}
local dSpeedDt = 0
local accelK = 0

local singWho = nil
local lastTouch = {
    Name = "Unknown",
    HitDistance = 0,
    LastSeen = 0
}
local wmBox = {
    X = 220,
    Y = 14,
    W = 120,
    H = 34,
    Dragging = false,
    DragOffsetX = 0,
    DragOffsetY = 0
}
local plyTrails = {}
local trailSampleT = 0
local toasts = {}
local combatHud = {
    WasAlive = true,
    LastKills = 0,
    LastDeaths = 0,
    Initialized = false
}
local dragWho = { Active = nil }
local hitPanel = { X = 20, Y = 110, W = 360, H = 76, Dragging = false, DragOffsetX = 0, DragOffsetY = 0 }
local killFeedBox = { X = nil, Y = 20, W = 250, H = 34, Dragging = false, DragOffsetX = 0, DragOffsetY = 0 }
local ripples = {}
local ballFromTag = ""
local whoTouchedBall = {}
local flecks = {}
local macro = {
    Keys = {
        w = false,
        a = false,
        s = false,
        d = false
    },
    StrafeDir = 1,
    NextStrafeSwapTick = 0,
    BurstForwardUntil = 0,
    BurstBackUntil = 0,
    IdleUntil = 0,
    Mode = "idle",
    ModeUntil = 0,
    NextDecisionTick = 0,
    LastThreat = false,
    ThreatReactUntil = 0,
    BaitFlipUntil = 0,
    BaitForward = true,
    LateralLockUntil = 0,
    MicroPauseUntil = 0
}
local tpPulse = {
    NextPulseTick = 0,
    Active = false,
    StartTick = 0,
    DurationMs = 260,
    StartPos = nil,
    TargetPos = nil
}

local function rgbaFromUi(tab, container, name, fallback)
    local value = ui.getValue(tab, container, name)
    if type(value) ~= "table" then return fallback end
    local r = value.r or value.R or 255
    local g = value.g or value.G or 255
    local b = value.b or value.B or 255
    return Color3.fromRGB(r, g, b)
end

local function syncLastTouch()
    if not bb.ball then return end
    local from = attr(bb.ball, "from")
    if type(from) ~= "string" or from == "" or from == lastTouch.Name then return end
    lastTouch.Name = from
    lastTouch.HitDistance = bb.distance or 0
    lastTouch.LastSeen = tick()
end

local function grabSliders()
    return {
        BaseMult = ui.getValue(TAB, "parry", "Base Mult") or fb.BaseMult,
        AccelBoost = ui.getValue(TAB, "parry", "Accel Boost") or fb.AccelBoost,
        ExecuteRatio = ui.getValue(TAB, "parry", "Execute Ratio") or fb.ExecuteRatio,
        TTICap = ui.getValue(TAB, "parry", "TTI Cap") or fb.TTICap,
        CloseRangeDist = ui.getValue(TAB, "parry", "Close Range Distance") or fb.CloseRangeDist,
        CloseRangeTTI = ui.getValue(TAB, "parry", "Close Range TTI") or fb.CloseRangeTTI,
        ClashWindow = ui.getValue(TAB, "clash", "Clash Window") or fb.ClashWindow,
        ClashThreshold = ui.getValue(TAB, "clash", "Clash Threshold") or fb.ClashThreshold,
        ClashActivateDist = ui.getValue(TAB, "clash", "Clash Activate Distance") or fb.ClashActivateDist,
        ClashDeactivateDist = ui.getValue(TAB, "clash", "Clash Deactivate Distance") or fb.ClashDeactivateDist
    }
end

local function cursorPos()
    local a, b = utility.GetMousePos()
    if type(a) == "table" then
        local x = a.X or a.x or a[1]
        local y = a.Y or a.y or a[2]
        x = tonumber(x)
        y = tonumber(y)
        if x and y then return x, y end
        return nil, nil
    end
    if type(a) == "number" and type(b) == "number" then
        return a, b
    end
    return nil, nil
end

local function lmbHeld()
    return mouse.is_pressed("leftmouse")
end

local function lmbClicked()
    return mouse.is_clicked("leftmouse")
end

local function dragRect(id, rect)
    local menuOpen = utility.GetMenuState()
    if not menuOpen then
        rect.Dragging = false
        if dragWho.Active == id then dragWho.Active = nil end
        return
    end

    local mx, my = cursorPos()
    if not mx or not my then return end
    local w = rect.W or 0
    local h = rect.H or 0

    if dragWho.Active == nil and lmbClicked() then
        if mx >= rect.X and mx <= rect.X + w and my >= rect.Y and my <= rect.Y + h then
            dragWho.Active = id
            rect.Dragging = true
            rect.DragOffsetX = mx - rect.X
            rect.DragOffsetY = my - rect.Y
        end
    end

    if dragWho.Active == id and rect.Dragging then
        if lmbHeld() then
            local ww, wh = cheat.getWindowSize()
            rect.X = clamp(mx - rect.DragOffsetX, 0, math.max(0, ww - w))
            rect.Y = clamp(my - rect.DragOffsetY, 0, math.max(0, wh - h))
        else
            rect.Dragging = false
            dragWho.Active = nil
        end
    end
end

local function collapseMenu()
    local t = TAB
    local on

    on = ui.getValue(t, "parry", "Enabled")
    ui.setVisibility(t, "parry", "Base Mult", on)
    ui.setVisibility(t, "parry", "Accel Boost", on)
    ui.setVisibility(t, "parry", "Execute Ratio", on)
    ui.setVisibility(t, "parry", "TTI Cap", on)
    ui.setVisibility(t, "parry", "Close Range Distance", on)
    ui.setVisibility(t, "parry", "Close Range TTI", on)

    on = ui.getValue(t, "clash", "Enabled")
    ui.setVisibility(t, "clash", "Clash Window", on)
    ui.setVisibility(t, "clash", "Clash Threshold", on)
    ui.setVisibility(t, "clash", "Clash Activate Distance", on)
    ui.setVisibility(t, "clash", "Clash Deactivate Distance", on)

    on = ui.getValue(t, "vis", "Traces")
    ui.setVisibility(t, "vis", "Traces Color", on)

    on = ui.getValue(t, "vis", "Trails")
    ui.setVisibility(t, "vis", "Trail Color", on)
    ui.setVisibility(t, "vis", "Self Trail", on)
    ui.setVisibility(t, "vis", "Trail Length", on)
    ui.setVisibility(t, "vis", "Trail Fade", on)
    ui.setVisibility(t, "vis", "Trail Max Thickness", on)
    ui.setVisibility(t, "vis", "Trail Min Thickness", on)
    ui.setVisibility(t, "vis", "Trail Opacity", on)
    ui.setVisibility(t, "vis", "Trail Step", on)
    ui.setVisibility(t, "vis", "Trail End Dot", on)

    on = ui.getValue(t, "misc", "Hit Circle")
    ui.setVisibility(t, "misc", "Hit Circle Color", on)
    ui.setVisibility(t, "misc", "Hit Circle Size", on)
    ui.setVisibility(t, "misc", "Hit Circle Duration", on)

    on = ui.getValue(t, "vis", "Status ESP")
    ui.setVisibility(t, "vis", "Status ESP Color", on)

    on = ui.getValue(t, "vis", "Time Ball")
    ui.setVisibility(t, "vis", "Time Ball Color", on)
    ui.setVisibility(t, "vis", "Time Ball Unit", on)

    on = ui.getValue(t, "vis", "Particles")
    ui.setVisibility(t, "vis", "Particle Style", on)
    ui.setVisibility(t, "vis", "Particle Color", on)

    on = ui.getValue(t, "misc", "Rage on ball")
    ui.setVisibility(t, "misc", "Rage Height", on)
    ui.setVisibility(t, "misc", "Rage Speed", on)
    ui.setVisibility(t, "misc", "Rage Distance", on)

    on = ui.getValue(t, "misc", "tp to ball")
    ui.setVisibility(t, "misc", "tp to ball distance", on)
    ui.setVisibility(t, "misc", "tp to ball interval", on)

    on = ui.getValue(t, "misc", "China hat")
    ui.setVisibility(t, "misc", "China hat Color", on)
    ui.setVisibility(t, "misc", "China hat self esp", on)
    ui.setVisibility(t, "misc", "China hat max distance", on)

    on = ui.getValue(t, "misc", "Auto play")
    ui.setVisibility(t, "misc", " auto parry and clash mode needs to be turned on", on)
end

local function toastPush(text, kind)
    toasts[#toasts + 1] = {
        Text = text,
        Kind = kind or "info",
        StartTick = tick(),
        DurationMs = 2600
    }
    while #toasts > 6 do
        table.remove(toasts, 1)
    end
end

local function easeOut3(t)
    t = clamp(t, 0, 1)
    local p = 1 - t
    return 1 - (p * p * p)
end

local function spewFx(worldPos)
    if not ui.getValue(TAB, "vis", "Particles") then return end
    if not worldPos then return end

    local style = ui.getValue(TAB, "vis", "Particle Style") or 1
    local count = 16
    if style == 2 then count = 20 end
    if style == 3 then count = 12 end

    local now = tick()
    for i = 1, count do
        local angle = rnd(0, math.pi * 2)
        local speed = rnd(0.6, 2.8)
        local spin = rnd(-4.0, 4.0)
        local life = rnd(420, 900)
        local vx = math.cos(angle) * speed
        local vy = rnd(0.2, 1.8)
        local vz = math.sin(angle) * speed

        if style == 2 then
            vx = vx * 0.5
            vz = vz * 0.5
            spin = rnd(5.0, 10.0)
            life = rnd(650, 1200)
        elseif style == 3 then
            vx = vx * 1.8
            vz = vz * 1.8
            vy = rnd(0.1, 0.8)
            life = rnd(300, 650)
        end

        table.insert(flecks, {
            X = worldPos.X, Y = worldPos.Y, Z = worldPos.Z,
            VX = vx, VY = vy, VZ = vz,
            Spin = spin,
            Style = style,
            Born = now,
            Life = life
        })
    end
    while #flecks > 240 do
        table.remove(flecks, 1)
    end
end

local function addRipple(worldPos)
    if not ui.getValue(TAB, "misc", "Hit Circle") then return end
    if not worldPos then return end
    table.insert(ripples, {
        Pos = worldPos,
        Start = tick()
    })
    while #ripples > 8 do
        table.remove(ripples, 1)
    end
end

local function ragePull()
    if not ui.getValue(TAB, "misc", "Rage on ball") then return end
    if not bb.root or not bb.ballPos or not bb.pos then return end

    local height = ui.getValue(TAB, "misc", "Rage Height") or 1.0
    local speed = ui.getValue(TAB, "misc", "Rage Speed") or 13.0
    local speedBoost = speed * 4.0
    local desiredRange = ui.getValue(TAB, "misc", "Rage Distance") or 30.0
    local nearestEnemyDist = math.huge
    local enemyPlayers = entity.GetPlayers(true) or {}
    for _, p in ipairs(enemyPlayers) do
        if p and p.IsAlive and p.Name ~= bb.playerName and p.Position then
            local d = dist(bb.pos, p.Position)
            if d < nearestEnemyDist then
                nearestEnemyDist = d
            end
        end
    end
    if nearestEnemyDist > 40.0 then
        desiredRange = 18.0
    end

    local fromBallToMe = Vector3.new(bb.pos.X - bb.ballPos.X, 0, bb.pos.Z - bb.ballPos.Z)
    local flatDistance = len3(fromBallToMe)
    local dir
    if flatDistance < 0.001 then
        dir = Vector3.new(1, 0, 0)
    else
        dir = norm(fromBallToMe)
    end

    local target = Vector3.new(
        bb.ballPos.X + dir.X * desiredRange,
        bb.ballPos.Y + height,
        bb.ballPos.Z + dir.Z * desiredRange
    )
    local delta = Vector3.new(target.X - bb.pos.X, target.Y - bb.pos.Y, target.Z - bb.pos.Z)

    local vx = clamp(delta.X * speedBoost, -1200, 1200)
    local vy = clamp(delta.Y * speedBoost, -1200, 1200)
    local vz = clamp(delta.Z * speedBoost, -1200, 1200)
    bb.root.Velocity = Vector3.new(vx, vy, vz)
end

local function tpArm(now)
    if not bb.root or not bb.ballPos or not bb.pos then return end

    local desiredDistance = ui.getValue(TAB, "misc", "tp to ball distance") or 10.0
    desiredDistance = tonumber(desiredDistance) or 10.0
    desiredDistance = clamp(desiredDistance, 2.0, 80.0)
    local toPlayer = Vector3.new(
        bb.pos.X - bb.ballPos.X,
        0,
        bb.pos.Z - bb.ballPos.Z
    )
    local flatDist = len3(toPlayer)
    local dir
    if flatDist < 0.001 then
        dir = Vector3.new(1, 0, 0)
    else
        dir = norm(toPlayer)
    end

    local target = Vector3.new(
        bb.ballPos.X + dir.X * desiredDistance,
        bb.pos.Y,
        bb.ballPos.Z + dir.Z * desiredDistance
    )

    tpPulse.StartPos = bb.pos
    tpPulse.TargetPos = target
    tpPulse.StartTick = now
    tpPulse.Active = true
end

local function tpTick()
    if not ui.getValue(TAB, "misc", "tp to ball") then
        tpPulse.Active = false
        tpPulse.NextPulseTick = 0
        return
    end
    if not bb.root or not bb.ballPos or not bb.alive then
        tpPulse.Active = false
        return
    end

    local now = tick()
    local intervalSec = ui.getValue(TAB, "misc", "tp to ball interval") or 1.0
    intervalSec = tonumber(intervalSec) or 1.0
    intervalSec = clamp(intervalSec, 0.2, 5.0)
    local intervalMs = intervalSec * 1000.0

    if now >= (tpPulse.NextPulseTick or 0) then
        tpPulse.NextPulseTick = now + intervalMs
        tpArm(now)
    end

    if not tpPulse.Active then
        return
    end
    if not tpPulse.StartPos or not tpPulse.TargetPos then
        tpPulse.Active = false
        return
    end

    local elapsed = now - tpPulse.StartTick
    local duration = math.max(1, tpPulse.DurationMs or 260)
    local t = clamp(elapsed / duration, 0, 1)
    local ease = 1 - ((1 - t) * (1 - t) * (1 - t))

    local from = tpPulse.StartPos
    local to = tpPulse.TargetPos
    local x = from.X + (to.X - from.X) * ease
    local y = from.Y + (to.Y - from.Y) * ease
    local z = from.Z + (to.Z - from.Z) * ease

    bb.root.Position = Vector3.new(x, y, z)
    bb.pos = bb.root.Position

    if t >= 1 then
        tpPulse.Active = false
    end
end

local function rootPartFor(playerName)
    if not playerName or playerName == "" then return nil end
    local playersContainer = game.Players
    if not playersContainer then return nil end
    local plr = playersContainer:FindFirstChild(playerName)
    if not plr then return nil end

    local char = plr.Character
    if not char then return nil end
    if not char:IsDescendantOf(game.Workspace) then return nil end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    if (hum.Health or 0) <= 0 then return nil end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    return root
end

local function inLobbyRadius(entityPlayer, liveRoot)
    if not entityPlayer or not liveRoot then return false end
    if not bb.ballPos then return false end

    local distToBall = dist(liveRoot.Position, bb.ballPos)
    if distToBall > 180 then
        return false
    end

    local bbox = entityPlayer.BoundingBox
    if not bbox then
        return false
    end
    if (bbox.w or 0) <= 0 or (bbox.h or 0) <= 0 then
        return false
    end

    return true
end

local function macroKey(key, down)
    local prev = macro.Keys[key]
    if prev == down then return end
    macro.Keys[key] = down
    if down then
        keyboard.press(key)
    else
        keyboard.release(key)
    end
end

local function macroKeysUp()
    macroKey("w", false)
    macroKey("a", false)
    macroKey("s", false)
    macroKey("d", false)
end

local function macroReset()
    macroKeysUp()
    macro.Mode = "idle"
    macro.ModeUntil = 0
    macro.NextDecisionTick = 0
    macro.LastThreat = false
    macro.ThreatReactUntil = 0
    macro.BaitFlipUntil = 0
    macro.BaitForward = true
    macro.LateralLockUntil = 0
    macro.MicroPauseUntil = 0
    macro.BurstForwardUntil = 0
    macro.BurstBackUntil = 0
    macro.IdleUntil = 0
end

local function nearestBad()
    if not bb.pos then return math.huge end
    local best = math.huge
    for _, p in ipairs(entity.GetPlayers(true) or {}) do
        if p and p.IsAlive and p.Name ~= bb.playerName and p.Position then
            local d = dist(bb.pos, p.Position)
            if d < best then best = d end
        end
    end
    return best
end

local function rollWalk(now, dist, incoming, ballSpeed, enemyDist)
    local underPressure = incoming and dist <= 65
    local closeThreat = incoming and dist <= 24
    local mediumThreat = incoming and dist <= 42

    if closeThreat then
        if rnd(0, 1) < 0.62 then
            return "hard_dodge", now + rndi(120, 240)
        end
        return "panic_kite", now + rndi(140, 280)
    end

    if mediumThreat then
        if rnd(0, 1) < 0.35 then
            return "retreat", now + rndi(120, 260)
        end
        return "kite", now + rndi(160, 320)
    end

    if underPressure then
        if rnd(0, 1) < 0.50 then
            return "circle", now + rndi(180, 360)
        end
        return "approach", now + rndi(120, 280)
    end

    if enemyDist < 28 then
        if rnd(0, 1) < 0.45 then
            return "bait", now + rndi(200, 420)
        end
        return "circle", now + rndi(180, 380)
    end

    if ballSpeed <= 30 and rnd(0, 1) < 0.52 then
        return "approach", now + rndi(220, 520)
    end

    if rnd(0, 1) < 0.28 then
        return "idle_drift", now + rndi(90, 180)
    end

    return "approach", now + rndi(180, 420)
end

local function macroRun()
    if not ui.getValue(TAB, "misc", "Auto play") then
        macroReset()
        return
    end

    local parryEnabled = ui.getValue(TAB, "parry", "Enabled")
    local clashEnabled = ui.getValue(TAB, "clash", "Enabled")
    if not parryEnabled or not clashEnabled then
        macroReset()
        return
    end

    if not bb.alive then
        macroReset()
        return
    end

    local now = tick()
    local dist = bb.distanceToHitbox or 999
    local pressure = bb.isTargetingMe and dist <= 65
    local veryClose = bb.isTargetingMe and dist <= 24
    local ballSpeed = bb.ballSpeed or 0
    local nearestEnemyDist = nearestBad()

    if now >= (macro.NextStrafeSwapTick or 0) then
        local swapChance = pressure and 0.68 or 0.38
        if rnd(0, 1) <= swapChance then
            macro.StrafeDir = -macro.StrafeDir
        end
        macro.NextStrafeSwapTick = now + rndi(130, pressure and 260 or 460)
    end

    if now >= (macro.BurstForwardUntil or 0) and now >= (macro.BurstBackUntil or 0) then
        if pressure and rnd(0, 1) < 0.23 then
            macro.BurstForwardUntil = now + rndi(85, 210)
        elseif (not pressure) and rnd(0, 1) < 0.16 then
            macro.BurstBackUntil = now + rndi(75, 180)
        end
    end

    if now >= (macro.IdleUntil or 0) and rnd(0, 1) < 0.04 then
        macro.IdleUntil = now + rndi(40, 110)
    end

    if bb.isTargetingMe and not macro.LastThreat then
        macro.LastThreat = true
        macro.ThreatReactUntil = now + rndi(55, 145)
    elseif not bb.isTargetingMe then
        macro.LastThreat = false
        macro.ThreatReactUntil = 0
    end

    if now >= (macro.NextDecisionTick or 0) or now >= (macro.ModeUntil or 0) then
        local mode, untilTick = rollWalk(now, dist, bb.isTargetingMe, ballSpeed, nearestEnemyDist)
        macro.Mode = mode
        macro.ModeUntil = untilTick
        macro.NextDecisionTick = now + rndi(70, 165)
    end

    local moveForward = false
    local moveBack = false
    local strafeLeft = false
    local strafeRight = false
    local canReactToThreat = (not bb.isTargetingMe) or (now >= (macro.ThreatReactUntil or 0))

    if macro.Mode == "approach" then
        moveForward = true
        if dist < 16 and bb.isTargetingMe then
            moveForward = false
            moveBack = true
        end
    elseif macro.Mode == "retreat" then
        moveBack = true
        if dist > 52 and rnd(0, 1) < 0.38 then
            moveBack = false
        end
    elseif macro.Mode == "circle" then
        if dist > 35 or not bb.isTargetingMe then
            moveForward = rnd(0, 1) < 0.62
        elseif dist < 14 then
            moveBack = true
        end
    elseif macro.Mode == "hard_dodge" then
        moveBack = true
    elseif macro.Mode == "panic_kite" then
        moveBack = true
        if dist > 38 and rnd(0, 1) < 0.32 then
            moveForward = true
            moveBack = false
        end
    elseif macro.Mode == "bait" then
        if now >= (macro.BaitFlipUntil or 0) then
            macro.BaitForward = not macro.BaitForward
            macro.BaitFlipUntil = now + rndi(100, 220)
        end
        moveForward = macro.BaitForward
        moveBack = not macro.BaitForward
    elseif macro.Mode == "idle_drift" then
        if rnd(0, 1) < 0.42 then
            moveForward = true
        elseif rnd(0, 1) < 0.36 then
            moveBack = true
        end
    else
        moveForward = rnd(0, 1) < 0.50
    end

    if now < (macro.BurstForwardUntil or 0) then
        moveForward = true
        moveBack = false
    end
    if now < (macro.BurstBackUntil or 0) then
        moveBack = true
        moveForward = false
    end

    if now < (macro.IdleUntil or 0) then
        moveForward = false
        moveBack = false
    end

    if macro.StrafeDir < 0 then
        strafeLeft = true
    else
        strafeRight = true
    end

    if macro.Mode == "hard_dodge" then
        if now >= (macro.LateralLockUntil or 0) then
            macro.StrafeDir = -macro.StrafeDir
            macro.LateralLockUntil = now + rndi(70, 160)
        end
        strafeLeft = macro.StrafeDir < 0
        strafeRight = not strafeLeft
    elseif macro.Mode == "panic_kite" or macro.Mode == "kite" then
        strafeLeft = macro.StrafeDir < 0
        strafeRight = not strafeLeft
    elseif macro.Mode == "bait" then
        if rnd(0, 1) < 0.25 then
            strafeLeft = false
            strafeRight = false
        end
    end

    if veryClose then
        strafeLeft = rnd(0, 1) < 0.5
        strafeRight = not strafeLeft
    elseif rnd(0, 1) < 0.08 then
        strafeLeft = false
        strafeRight = false
    end

    if not canReactToThreat and bb.isTargetingMe then
        moveForward = false
        moveBack = false
    end

    if now >= (macro.MicroPauseUntil or 0) and rnd(0, 1) < 0.022 then
        macro.MicroPauseUntil = now + rndi(35, 85)
    end
    if now < (macro.MicroPauseUntil or 0) then
        moveForward = false
        moveBack = false
        if rnd(0, 1) < 0.50 then
            strafeLeft = false
            strafeRight = false
        end
    end

    if nearestEnemyDist < 14 and not bb.isTargetingMe then
        if rnd(0, 1) < 0.55 then
            moveBack = true
            moveForward = false
        end
    end

    if moveForward and moveBack then
        if rnd(0, 1) < 0.5 then
            moveBack = false
        else
            moveForward = false
        end
    end
    if strafeLeft and strafeRight then
        if rnd(0, 1) < 0.5 then
            strafeRight = false
        else
            strafeLeft = false
        end
    end

    macroKey("w", moveForward)
    macroKey("s", moveBack)
    macroKey("a", strafeLeft and not strafeRight)
    macroKey("d", strafeRight and not strafeLeft)
end

local function boardInt(statNames)
    local lp = game.LocalPlayer
    if not lp then return 0 end
    local ls = lp:FindFirstChild("leaderstats")
    if not ls then return 0 end
    for _, name in ipairs(statNames) do
        local stat = ls:FindFirstChild(name)
        if stat then
            local v = stat.Value
            if type(v) == "number" then
                return math.floor(v)
            end
        end
    end
    return 0
end

local function pulseKillfeed(char)
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local aliveNow = (humanoid and (humanoid.Health or 0) > 0) or false

    local kills = boardInt({ "Kills", "KOs", "Eliminations", "Frags" })
    local deaths = boardInt({ "Deaths", "Wipeouts", "KOd", "Defeats" })

    if not combatHud.Initialized then
        combatHud.Initialized = true
        combatHud.WasAlive = aliveNow
        combatHud.LastKills = kills
        combatHud.LastDeaths = deaths
        return
    end

    if kills > combatHud.LastKills then
        local delta = kills - combatHud.LastKills
        toastPush(delta > 1 and string.format("You eliminated x%d", delta) or "You eliminated enemy", "kill")
    end

    if deaths > combatHud.LastDeaths then
        local delta = deaths - combatHud.LastDeaths
        toastPush(delta > 1 and string.format("You died x%d", delta) or "You got eliminated", "death")
    end

    if combatHud.WasAlive and not aliveNow then
        toastPush("You got eliminated", "death")
    end

    combatHud.WasAlive = aliveNow
    combatHud.LastKills = kills
    combatHud.LastDeaths = deaths
end

local function trailsTick()
    if not ui.getValue(TAB, "vis", "Trails") then
        plyTrails = {}
        return
    end

    local now = tick()
    if (now - trailSampleT) < 8 then return end
    trailSampleT = now

    local maxLen = ui.getValue(TAB, "vis", "Trail Length") or 120
    local includeSelf = ui.getValue(TAB, "vis", "Self Trail")
    local seen = {}

    local playersContainer = game.Players
    if playersContainer then
        for _, plr in ipairs(playersContainer:GetChildren()) do
            local name = plr.Name
            local isSelf = (name == bb.playerName)
            if includeSelf or not isSelf then
                local char = plr.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if root and (not hum or hum.Health > 0) then
                    local pos = root.Position
                    local key = tostring(name)
                    seen[key] = true
                    if not plyTrails[key] then plyTrails[key] = {} end
                    local trail = plyTrails[key]

                    local shouldInsert = true
                    local last = trail[#trail]
                    if last then
                        shouldInsert = dist(last.Pos, pos) > 0.03
                    end

                    if shouldInsert then
                        table.insert(trail, { Pos = pos, Tick = now })
                    end

                    while #trail > maxLen do
                        table.remove(trail, 1)
                    end
                end
            end
        end
    end

    for name, trail in pairs(plyTrails) do
        if not seen[name] then
            plyTrails[name] = nil
        else
            for i = #trail, 1, -1 do
                if now - trail[i].Tick > 1500 then
                    table.remove(trail, i)
                end
            end
        end
    end
end

local function ellipsize(text, font, maxWidth)
    if not text then return "" end
    local width = draw.GetTextSize(text, font)
    if width <= maxWidth then return text end

    local suffix = "..."
    local out = text
    while #out > 1 do
        out = string.sub(out, 1, #out - 1)
        local candidate = out .. suffix
        local w = draw.GetTextSize(candidate, font)
        if w <= maxWidth then
            return candidate
        end
    end
    return suffix
end

local function pushSpdSample()
    table.insert(spdHist, { tick = tick(), speed = bb.ballSpeed })
    while #spdHist > 10 do table.remove(spdHist, 1) end
end

local function bumpAccel()
    local count = #spdHist
    if count < 3 then
        dSpeedDt = 0
        accelK = 0
        return
    end

    local oldestIdx = count - 5
    if oldestIdx < 1 then oldestIdx = 1 end
    local oldest = spdHist[oldestIdx]
    local newest = spdHist[count]

    local dtSeconds = (newest.tick - oldest.tick) * 0.001
    if dtSeconds < 0.01 then
        dSpeedDt = 0
        accelK = 0
        return
    end

    local deltaSpeed = newest.speed - oldest.speed
    dSpeedDt = deltaSpeed / dtSeconds

    local accel = dSpeedDt
    if accel <= 200 then
        accelK = 0
    elseif accel >= 500 then
        accelK = 1
    else
        accelK = (accel - 200) / 300
    end

    local baseSpeed = oldest.speed
    if baseSpeed > 0 then
        local relativeAccel = deltaSpeed / baseSpeed
        if relativeAccel > 0.30 then
            accelK = math.max(accelK, 0.8)
        elseif relativeAccel > 0.15 then
            accelK = math.max(accelK, 0.5)
        end
    end
end

local function pushDstSample()
    local now = tick()
    dstHist[#dstHist + 1] = { tick = now, distance = bb.distance }
    while #dstHist > 10 do
        table.remove(dstHist, 1)
    end
end

local function closingVel()
    local count = #dstHist
    if count < 4 then
        bb.distanceClosingSmooth = 0
        return
    end

    local sample = dstHist[count - 3]
    local older = sample and sample.distance or bb.distance
    bb.distanceClosingSmooth = (older - bb.distance) * 0.25
end

local function parryLimits(speed, settings)
    local dynamicMult = settings.BaseMult + settings.AccelBoost * accelK
    local thresholdByMult = speed * dynamicMult
    local thresholdByTti = speed * settings.TTICap
    local commitThreshold = math.max(15, math.min(thresholdByMult, thresholdByTti))
    local executeThreshold = commitThreshold * settings.ExecuteRatio

    bb.currentMult = dynamicMult

    return commitThreshold, executeThreshold
end

local function realBallPart()
    local ws = game.Workspace
    if not ws then return nil end
    local folder = ws:FindFirstChild("Balls")
    if not folder then return nil end
    for _, child in ipairs(folder:GetChildren()) do
        if child.ClassName == "Part" then
            if attr(child, "realBall") == true then return child end
        end
    end
    return nil
end

local function readBallVel(ball)
    if not ball then return Vector3.new(0,0,0), 0 end
    local zoomies = ball:FindFirstChild("zoomies")
    if zoomies then
        local vel = zoomies.VectorVelocity
        if vel then return vel, len3(vel) end
    end
    local vel = ball.Velocity
    if vel then return vel, len3(vel) end
    return Vector3.new(0,0,0), 0
end

local function readBallAim(ball)
    if not ball then return "", false end
    local target = attr(ball, "target")
    if type(target) == "string" then
        return target, (target == bb.playerName)
    end
    return "", false
end

local function myHp()
    if not bb.player then return 0 end
    local char = bb.player.Character
    if not char then return 0 end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return 0 end
    return humanoid.Health or 0
end

local function bangFx()
    local p = bb.ballPos
    if not p then return end
    addRipple(p)
    spewFx(p)
end

local function mainTick()
    local enabled = ui.getValue(TAB, "parry", "Enabled")
    local clashEnabled = ui.getValue(TAB, "clash", "Enabled")
    local settings = grabSliders()
    collapseMenu()
    
    bb.player = game.LocalPlayer
    if not bb.player then return end
    bb.playerName = bb.player.Name or ""
    
    local char = bb.player.Character
    pulseKillfeed(char)
    bb.root = char and char:FindFirstChild("HumanoidRootPart")
    trailsTick()
    if not bb.root then return end
    bb.pos = bb.root.Position
    
    bb.wasAlive = bb.alive
    bb.alive = myHp() > 0
    
    if bb.wasAlive and not bb.alive then
        clashOn = false
        bb.parried = false
        bb.committed = false
    end
    
    bb.ball = realBallPart()
    
    if not bb.ball then
        clashOn = false
        bb.parried = false
        bb.committed = false
        bb.isTargetingMe = false
        bb.wasTargeting = false
        return
    end
    
    bb.wasTargeting = bb.isTargetingMe
    bb.isReal = false
    
    bb.ballPos = bb.ball.Position
    bb.ballVel, bb.ballSpeed = readBallVel(bb.ball)
    bb.isReal = attr(bb.ball, "realBall") == true
    _, bb.isTargetingMe = readBallAim(bb.ball)
    syncLastTouch()
    tpTick()
    ragePull()
    macroRun()

    local from = attr(bb.ball, "from")
    if type(from) == "string" then
        if from ~= "" and from ~= ballFromTag then
            whoTouchedBall[from] = tick()
            if from == bb.playerName then
                spewFx(bb.ballPos)
            end
        end
        if from == bb.playerName and from ~= ballFromTag then
            bangFx()
        end
        ballFromTag = from
    end
    
    bb.distance = dist(bb.pos, bb.ballPos)
    bb.distanceToHitbox = math.max(0, bb.distance - 15)
    
    local effectiveSpeed = math.max(bb.ballSpeed, 1)
    bb.tti = bb.distanceToHitbox / effectiveSpeed

    if not enabled then
        bb.reason = "OFF"
        return
    end
    
    local closestSingularity = attr(bb.ball, "ClosestSingularity")
    local singularityFrom = attr(bb.ball, "from")
    local wasInSingularity = (singWho ~= nil)
    singWho = closestSingularity
    local justReleasedFromSingularity = wasInSingularity and (singWho == nil)
    
    if singWho == bb.playerName then
        bb.reason = "HOLDING"
        return
    end
    
    if singWho ~= nil then
        bb.reason = string.format("SINGULARITY: %s", singWho)
        return
    end
    
    if justReleasedFromSingularity and singularityFrom ~= nil 
        and singularityFrom ~= bb.playerName and bb.isTargetingMe then
        mouse.Click("leftmouse", 0)
        bangFx()
        bb.parried = true
        bb.reason = string.format("SING: %s", singularityFrom)
        
        if clashEnabled and bb.distance <= settings.ClashActivateDist then
            if clashSpam(settings.ClashWindow, settings.ClashThreshold) then
                clashOn = true
            end
        end
        return
    end
    
    if bb.isTargetingMe then
        pushDstSample()
        closingVel()
        pushSpdSample()
        bumpAccel()
        bb.commitDist, bb.parryDist = parryLimits(bb.ballSpeed, settings)
    end
    
    if bb.isTargetingMe and not bb.wasTargeting then
        bb.parried = false
        bb.committed = false
        dstHist = {}
        spdHist = {}
        dSpeedDt = 0
        accelK = 0
        
        if bb.distanceToHitbox <= 20 then
            mouse.Click("leftmouse", 0)
            bangFx()
            bb.parried = true
            bb.reason = "INSTANT"
            
            if clashEnabled and bb.distance <= settings.ClashActivateDist then
                if clashSpam(settings.ClashWindow, settings.ClashThreshold) then
                    clashOn = true
                end
            end
            return
        end
    end
    
    if not bb.isTargetingMe and bb.wasTargeting then
        bb.parried = false
    end
    
    if not bb.isTargetingMe then
        bb.parried = false
        bb.committed = false
        if clashOn then clashOn = false end
    end
    
    if clashOn and bb.distance > settings.ClashDeactivateDist then
        clashOn = false
    end
    
    if bb.isTargetingMe and not bb.wasTargeting 
        and bb.distance <= settings.ClashActivateDist and clashEnabled then
        if clashSpam(settings.ClashWindow, settings.ClashThreshold) then
            clashOn = true
        end
    end
    
    if clashOn and clashEnabled then
        mouse.Click("leftmouse", 0)
        mouse.Click("leftmouse", 0)
        bb.reason = "CLASH"
        if not bb.parried and bb.isTargetingMe then
            bb.parried = true
        end
        return
    end
    
    if bb.isTargetingMe and bb.isReal and bb.distance <= settings.CloseRangeDist then
        local closeSpeed = math.max(bb.ballSpeed, 40)
        local closeThreshold = closeSpeed * settings.CloseRangeTTI
        
        if bb.distanceToHitbox <= closeThreshold and not bb.parried then
            mouse.Click("leftmouse", 0)
            bangFx()
            bb.parried = true
            bb.reason = string.format("CLOSE d<=%.0f", closeThreshold)
            
            if clashEnabled and bb.distance <= settings.ClashActivateDist then
                if clashSpam(settings.ClashWindow, settings.ClashThreshold) then
                    clashOn = true
                end
            end
            return
        else
            bb.reason = string.format("CLOSE %.0f>%.0f", bb.distanceToHitbox, closeSpeed * settings.CloseRangeTTI)
        end
        return
    end
    
    if not bb.committed then
        if bb.ball and bb.isReal and bb.isTargetingMe 
            and bb.ballSpeed >= 20 and bb.distanceToHitbox <= bb.commitDist then
            bb.committed = true
        end
    end
    
    if bb.committed and not bb.parried then
        if bb.distanceClosingSmooth >= 0.3 and bb.distanceToHitbox <= bb.parryDist then
            mouse.Click("leftmouse", 0)
            bangFx()
            bb.parried = true
            bb.reason = string.format("PARRY %.0fms", bb.tti * 1000)
            
            if clashEnabled and bb.distance <= settings.ClashActivateDist then
                if clashSpam(settings.ClashWindow, settings.ClashThreshold) then
                    clashOn = true
                end
            end
            return
        end
    end
    
    if not bb.ball then
        bb.reason = "No ball"
    elseif not bb.isReal then
        bb.reason = "Fake"
    elseif not bb.isTargetingMe then
        bb.reason = "Not target"
    elseif bb.parried then
        bb.reason = "Parried"
    elseif bb.ballSpeed < 20 then
        bb.reason = "Turning"
    elseif bb.committed then
        bb.reason = string.format("COMMIT %.0f>%.0f", bb.distanceToHitbox, bb.parryDist)
    else
        bb.reason = string.format("%.0f>%.0f", bb.distanceToHitbox, bb.commitDist)
    end
end

local function paintDist()
    if not ui.getValue(TAB, "vis", "Distance") then return end
    if not bb.ball or not bb.ballPos then return end
    
    local sx, sy, onScreen = utility.WorldToScreen(bb.ballPos)
    if not onScreen then return end
    local distanceColor = rgbaFromUi(TAB, "vis", "Distance Color", theme.wh)
    local metersText = string.format("%.1fm", bb.distance)
    local textW, textH = draw.GetTextSize(metersText, "Verdana")
    local tx = sx - (textW / 2)
    local ty = sy - 40 - textH
    draw.TextOutlined(metersText, tx, ty, distanceColor, "Verdana", 255)
end

local function paintLine()
    if not ui.getValue(TAB, "vis", "Snaplines") then return end
    if not bb.ball or not bb.ballPos then return end
    local sx, sy, onScreen = utility.WorldToScreen(bb.ballPos)
    if not onScreen then return end
    local mx, my = cursorPos()
    if not mx or not my then return end

    local snapColor = rgbaFromUi(TAB, "vis", "Snapline Color", theme.wh)
    draw.Line(mx, my, sx, sy, snapColor, 2.0, 255)
end

local function paintTraces()
    if not ui.getValue(TAB, "vis", "Traces") then return end
    local mx, my = cursorPos()
    if not mx or not my then return end

    local lineCol = rgbaFromUi(TAB, "vis", "Traces Color", theme.pr)
    local teamOnlyEnemies = ui.getValue(TAB, "vis", "Team check")
    local plrs = entity.GetPlayers(false) or {}

    for _, p in ipairs(plrs) do
        if p and p.IsAlive and p.Name ~= bb.playerName then
            if not (teamOnlyEnemies and not p.IsEnemy) then
                local wp = p.GetBonePosition and p:GetBonePosition("Head")
                if not wp and p.GetBonePosition then
                    wp = p:GetBonePosition("HumanoidRootPart")
                end
                if not wp and p.Position then
                    wp = p.Position
                end
                if wp then
                    local sx, sy, vis = utility.WorldToScreen(wp)
                    if vis then
                        draw.Line(mx, my, sx, sy, lineCol, 1.6, 210)
                    end
                end
            end
        end
    end
end

local function paintLastHit()
    if not ui.getValue(TAB, "vis", "Hit Info") then return end

    hitPanel.W, hitPanel.H = 360, 76
    dragRect("targetgui", hitPanel)
    local x, y = hitPanel.X, hitPanel.Y
    local w, h = hitPanel.W, hitPanel.H
    local accent = rgbaFromUi(TAB, "vis", "Hit Info Accent", theme.cy)
    local name = lastTouch.Name or "Unknown"

    draw.RectFilled(x, y, w, h, Color3.fromRGB(16, 18, 24), 10, 230)
    draw.Rect(x, y, w, h, Color3.fromRGB(accent.R * 255, accent.G * 255, accent.B * 255), 1.2, 10, 120)

    local tx = x + 14
    local maxTextWidth = w - 28
    local title = ellipsize(string.format("%s hit the ball", name), "Verdana", maxTextWidth)
    local hitText = ellipsize(string.format("Hit distance: %.1fm", lastTouch.HitDistance or 0), "Verdana", maxTextWidth)
    draw.TextOutlined(title, tx, y + 14, theme.wh, "Verdana", 255)
    draw.TextOutlined(hitText, tx, y + 36, accent, "Verdana", 235)
end

local function paintRing()
    if not ui.getValue(TAB, "vis", "Range Circle") then return end
    if not bb.pos then return end
    local radius = math.max(0, (bb.parryDist or 15) + 15)
    if radius <= 0 then return end

    local points = {}
    local steps = 48
    for i = 1, steps do
        local t = ((i - 1) / steps) * math.pi * 2
        local worldPoint = Vector3.new(
            bb.pos.X + math.cos(t) * radius,
            bb.pos.Y,
            bb.pos.Z + math.sin(t) * radius
        )
        local sx, sy, onScreen = utility.WorldToScreen(worldPoint)
        if onScreen then
            table.insert(points, { sx, sy })
        end
    end

    if #points >= 8 then
        local circleColor = rgbaFromUi(TAB, "vis", "Range Circle Color", theme.wh)
        draw.Polyline(points, circleColor, true, 2.0, 220)
    end
end

local function paintClock()
    if not ui.getValue(TAB, "vis", "Time Ball") then return end
    if not bb.ball or not bb.ballPos then return end
    local sx, sy, onScreen = utility.WorldToScreen(bb.ballPos)
    if not onScreen then return end

    local ms = math.max(0, bb.tti * 1000)
    local unitValue = ui.getValue(TAB, "vis", "Time Ball Unit")
    local unitMode = 1
    if type(unitValue) == "number" then
        unitMode = unitValue
    elseif type(unitValue) == "string" then
        local s = string.lower(unitValue)
        if s:find("second", 1, true) then
            unitMode = 2
        elseif s:find("auto", 1, true) then
            unitMode = 3
        else
            unitMode = 1
        end
    end
    local text
    if unitMode == 2 then
        text = string.format("Time: %.2fs", ms / 1000)
    elseif unitMode == 3 then
        if ms >= 1000 then
            text = string.format("Time: %.2fs", ms / 1000)
        else
            text = string.format("Time: %.0fms", ms)
        end
    else
        text = string.format("Time: %.0fms", ms)
    end
    local color = rgbaFromUi(TAB, "vis", "Time Ball Color", theme.yl)
    local textW, textH = draw.GetTextSize(text, "Verdana")
    draw.TextOutlined(text, sx - textW / 2, sy - 60 - textH, color, "Verdana", 255)
end

local function paintTag()
    if not ui.getValue(TAB, "vis", "Watermark") then return end

    dragRect("watermark", wmBox)
    local x, y, w, h = wmBox.X, wmBox.Y, wmBox.W, wmBox.H

    draw.RectFilled(x, y, w, h, Color3.fromRGB(10, 10, 12), 10, 235)
    draw.RectFilled(x + 2, y + 2, w - 4, h - 4, Color3.fromRGB(22, 24, 30), 8, 220)

    local t = tick() / 1000.0
    local hue1 = (t * 0.16) % 1.0
    local hue2 = (hue1 + 0.33) % 1.0
    local secretColor = Color3.fromHSV(hue1, 0.85, 1.0)
    local ccColor = Color3.fromHSV(hue2, 0.85, 1.0)

    draw.TextOutlined("Secret", x + 10, y + 8, Color3.fromRGB(255, 255, 255), "Verdana", 255)
    draw.TextOutlined(".cc", x + 52, y + 8, Color3.fromRGB(0, 0, 0), "Verdana", 255)
    draw.TextOutlined("Secret", x + 10, y + 8, secretColor, "Verdana", 220)
    draw.TextOutlined(".cc", x + 52, y + 8, ccColor, "Verdana", 220)

end

local function paintTrails()
    if not ui.getValue(TAB, "vis", "Trails") then return end
    local trailColor = rgbaFromUi(TAB, "vis", "Trail Color", theme.wh)
    local fadePercent = ui.getValue(TAB, "vis", "Trail Fade") or 40
    local maxThickness = ui.getValue(TAB, "vis", "Trail Max Thickness") or 3.2
    local minThickness = ui.getValue(TAB, "vis", "Trail Min Thickness") or 1.2
    local opacity = ui.getValue(TAB, "vis", "Trail Opacity") or 255
    local step = ui.getValue(TAB, "vis", "Trail Step") or 1
    local endDot = ui.getValue(TAB, "vis", "Trail End Dot")
    step = math.max(1, math.floor(step))
    opacity = clamp(opacity, 20, 255)
    if minThickness > maxThickness then
        minThickness, maxThickness = maxThickness, minThickness
    end

    for _, trail in pairs(plyTrails) do
        local count = #trail
        if count >= 2 then
            local fadeCutoff = math.max(1, math.floor(count * (fadePercent * 0.01)))
            for i = 1, count - step, step do
                local a = trail[i].Pos
                local b = trail[i + step].Pos
                local ax, ay, av = utility.WorldToScreen(a)
                local bx, by, bv = utility.WorldToScreen(b)
                if av and bv then
                    local progress = (i - 1) / math.max(1, (count - 2))
                    local fadeProgress = (i <= fadeCutoff) and (i / fadeCutoff) or 1
                    local alpha = ((55 + (200 * progress)) * fadeProgress) * (opacity / 255)
                    local thickness = minThickness + ((maxThickness - minThickness) * progress)
                    draw.Line(ax, ay, bx, by, trailColor, thickness, alpha)
                end
            end

            if endDot then
                local last = trail[count]
                if last and last.Pos then
                    local lx, ly, lv = utility.WorldToScreen(last.Pos)
                    if lv then
                        local dotAlpha = math.max(45, opacity)
                        local dotRadius = math.max(1.5, maxThickness + 0.8)
                        draw.CircleFilled(lx, ly, dotRadius, trailColor, 14, dotAlpha)
                    end
                end
            end
        end
    end
end

local function paintDots()
    if not ui.getValue(TAB, "vis", "Headdot") then return end

    local teamCheck = ui.getValue(TAB, "vis", "Team check")
    local headdotColor = rgbaFromUi(TAB, "vis", "Headdot Color", Color3.fromRGB(255, 60, 60))
    local players = entity.GetPlayers(false) or {}

    for _, p in ipairs(players) do
        if p and p.Name ~= bb.playerName and p.IsAlive then
            if not (teamCheck and not p.IsEnemy) then
                local headPos = p.GetBonePosition and p:GetBonePosition("Head")
                if not headPos and p.GetBonePosition then
                    headPos = p:GetBonePosition("HumanoidRootPart")
                end
                if headPos then
                    local sx, sy, onScreen = utility.WorldToScreen(headPos)
                    if onScreen then
                        local color = p.IsEnemy and headdotColor or Color3.fromRGB(90, 140, 255)
                        draw.CircleFilled(sx, sy, 3.5, color, 12, 255)
                        draw.Circle(sx, sy, 5.0, Color3.fromRGB(0, 0, 0), 1.0, 12, 120)
                    end
                end
            end
        end
    end
end

local function espLine(p)
    local moveText = ""

    local moveMag = 0
    if p.MoveDirection then
        moveMag = len3(p.MoveDirection)
    elseif p.Velocity then
        moveMag = len3(p.Velocity)
    end

    if moveMag == 0 then
        moveText = "idle"
    elseif moveMag > 0 then
        moveText = "walking"
    end

    local stateId = p.StateId
    if stateId == nil and game.Players then
        local plr = game.Players:FindFirstChild(p.Name)
        local hum = plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            stateId = hum.StateId
            if stateId == nil and hum.GetState then
                stateId = hum:GetState()
            end
        end
    end

    local nState = tonumber(stateId)
    if nState == 0 or nState == 1 then
        moveText = "ragdolled"
    elseif nState == 3 or nState == 5 or nState == 6 then
        moveText = "in air"
    elseif nState == 4 then
        moveText = "swimming"
    elseif nState == 12 then
        moveText = "climbing"
    elseif nState == 13 then
        moveText = "sitting"
    elseif nState == 14 then
        moveText = "platform standing"
    elseif type(stateId) == "string" then
        local s = string.lower(stateId)
        if s:find("rag") then moveText = "ragdolled"
        elseif s:find("freefall") or s:find("jump") or s:find("fall") then moveText = "in air"
        elseif s:find("swim") then moveText = "swimming"
        elseif s:find("climb") then moveText = "climbing"
        elseif s:find("sit") then moveText = "sitting"
        elseif s:find("platform") then moveText = "platform standing"
        end
    end

    local now = tick()
    local hitAt = whoTouchedBall[p.Name]
    if hitAt and (now - hitAt) <= 1200 then
        moveText = "ball touch (recent)"
    end

    if moveText == "" then
        moveText = "unknown"
    end
    return moveText
end

local function paintEsp()
    if not ui.getValue(TAB, "vis", "Status ESP") then return end
    local players = entity.GetPlayers(false) or {}
    local color = rgbaFromUi(TAB, "vis", "Status ESP Color", theme.wh)

    for _, p in ipairs(players) do
        if p and p.Name ~= bb.playerName and p.BoundingBox then
            local bbox = p.BoundingBox
            local moveText = espLine(p)
            local x = bbox.x + bbox.w + 5
            local y = bbox.y
            draw.TextOutlined(moveText, x, y, color, "Verdana", 235)
        end
    end
end

local function paintFeed()
    if not ui.getValue(TAB, "vis", "Combat Notify") then return end
    local sw, _ = cheat.getWindowSize()
    local boxW, boxH = 250, 34
    if killFeedBox.X == nil then
        killFeedBox.X = sw - boxW - 18
    end
    killFeedBox.W, killFeedBox.H = boxW, boxH
    dragRect("combatnotify", killFeedBox)
    local baseY = killFeedBox.Y or 20

    if #toasts == 0 then
        return
    end

    local now = tick()
    local gap = 8

    for i = #toasts, 1, -1 do
        local n = toasts[i]
        local age = now - n.StartTick
        if age > n.DurationMs then
            table.remove(toasts, i)
        end
    end

    local row = 0
    for i = 1, #toasts do
        local n = toasts[i]
        local age = now - n.StartTick
        local t = age / n.DurationMs
        t = clamp(t, 0, 1)

        local slideIn = clamp(age / 260, 0, 1)
        local fadeOut = clamp((n.DurationMs - age) / 360, 0, 1)
        local alphaMul = math.min(slideIn, fadeOut)
        local offsetX = (1 - slideIn) * 40

        local x = (killFeedBox.X or (sw - boxW - 18)) + offsetX
        local y = baseY + row * (boxH + gap)
        row = row + 1

        local accent = theme.cy
        if n.Kind == "kill" then accent = Color3.fromRGB(80, 255, 120) end
        if n.Kind == "death" then accent = Color3.fromRGB(255, 90, 110) end

        draw.RectFilled(x, y, boxW, boxH, Color3.fromRGB(18, 20, 26), 8, 220 * alphaMul)
        draw.RectFilled(x + 2, y + 2, 3, boxH - 4, accent, 2, 255 * alphaMul)
        draw.TextOutlined(n.Text, x + 12, y + 10, theme.wh, "Verdana", 255 * alphaMul)
    end
end

local function paintRipple()
    if not ui.getValue(TAB, "misc", "Hit Circle") then
        ripples = {}
        return
    end

    local now = tick()
    local colorPick = ui.getValue(TAB, "misc", "Hit Circle Color") or { r = 255, g = 255, b = 255, a = 200 }
    local baseColor = Color3.fromRGB(colorPick.r or 255, colorPick.g or 255, colorPick.b or 255)
    local baseAlpha = colorPick.a or 200
    local maxRadius = ui.getValue(TAB, "misc", "Hit Circle Size") or 120
    local duration = ui.getValue(TAB, "misc", "Hit Circle Duration") or 900

    for i = #ripples, 1, -1 do
        local c = ripples[i]
        local age = now - c.Start
        if age >= duration then
            table.remove(ripples, i)
        else
            local t = age / duration
            local k = easeOut3(t)
            local radius = 10 + (maxRadius - 10) * k
            local alpha = baseAlpha * (1 - t)

            local sx, sy, onScreen = utility.WorldToScreen(c.Pos)
            if onScreen then
                draw.Circle(sx, sy, radius, baseColor, 2.2, 48, alpha)
                draw.Circle(sx, sy, radius * 0.72, baseColor, 1.6, 48, alpha * 0.65)
            end
        end
    end
end

local function paintSparks()
    if not ui.getValue(TAB, "vis", "Particles") then
        flecks = {}
        return
    end

    local now = tick()
    local pick = ui.getValue(TAB, "vis", "Particle Color") or { r = 255, g = 255, b = 255, a = 220 }
    local color = Color3.fromRGB(pick.r or 255, pick.g or 255, pick.b or 255)
    local alphaBase = pick.a or 220

    for i = #flecks, 1, -1 do
        local p = flecks[i]
        local age = now - p.Born
        if age >= p.Life then
            table.remove(flecks, i)
        else
            local t = age / p.Life
            local fade = 1 - t

            local sx = p.X + (p.VX * t * 18)
            local sy = p.Y + (p.VY * t * 18) - (t * t * 2.2)
            local sz = p.Z + (p.VZ * t * 18)

            if p.Style == 2 then
                local ang = t * p.Spin
                local r = 0.8 + t * 3.0
                sx = sx + math.cos(ang) * r
                sz = sz + math.sin(ang) * r
            end

            local world = Vector3.new(sx, sy, sz)
            local x, y, onScreen = utility.WorldToScreen(world)
            if onScreen then
                local a = alphaBase * fade
                if p.Style == 3 then
                    draw.Line(x, y, x + p.VX * 8, y - p.VY * 5, color, 1.4, a)
                else
                    local radius = (p.Style == 2) and (3.6 - t * 1.2) or (2.6 - t * 0.8)
                    draw.CircleFilled(x, y, math.max(1.0, radius), color, 10, a)
                end
            end
        end
    end
end

local function coneHat(headPos, hatColor, refPos, maxDist)
    if not headPos or not refPos then return end
    if dist(refPos, headPos) > maxDist then return end

    local segs, hatH, hatR = 48, 1.0, 1.5
    local apexBump, baseLift = 0.15, 0.2
    local fillA, baseMult, softPx, lineA = 107, 0.6, 2.0, 100

    local twoPi = math.pi * 2
    local apexWorld = Vector3.new(headPos.X, headPos.Y + hatH + apexBump, headPos.Z)
    local baseY = headPos.Y + baseLift

    local apexX, apexY, apexOn = utility.WorldToScreen(apexWorld)
    if apexX == nil or apexY == nil then
        apexOn = false
    end

    local baseScreen = {}
    local anyOnScreen = apexOn == true
    local allProjected = true

    for i = 1, segs do
        local angle = (twoPi * (i - 1)) / segs
        local wx = headPos.X + hatR * math.cos(angle)
        local wz = headPos.Z + hatR * math.sin(angle)
        local worldPt = Vector3.new(wx, baseY, wz)
        local sx, sy, onScreen = utility.WorldToScreen(worldPt)
        if not sx or not sy then
            allProjected = false
            break
        end
        baseScreen[i] = { sx, sy }
        if onScreen then
            anyOnScreen = true
        end
    end

    if not (allProjected and anyOnScreen and apexX and apexY) then
        return
    end

    for i = 1, segs do
        local nextIdx = (i % segs) + 1
        local bi = baseScreen[i]
        local bn = baseScreen[nextIdx]
        local angle = (twoPi * (i - 1)) / segs
        local ox = apexX + math.cos(angle) * softPx
        local oy = apexY + math.sin(angle) * softPx
        draw.TriangleFilled(ox, oy, bi[1], bi[2], bn[1], bn[2], hatColor, fillA)
    end

    local baseAlpha = math.floor(fillA * baseMult)
    local hull = {}
    for i = 1, segs do
        hull[#hull + 1] = { baseScreen[i][1], baseScreen[i][2] }
    end
    draw.ConvexPolyFilled(hull, hatColor, baseAlpha)

    local outlineColor = Color3.new(0, 0, 0)
    for i = 1, segs do
        local nextIdx = (i % segs) + 1
        local bi = baseScreen[i]
        local bn = baseScreen[nextIdx]
        draw.Line(bi[1], bi[2], bn[1], bn[2], outlineColor, 1.2, lineA)
    end
end

local function headHere()
    local lp = game.LocalPlayer
    if not lp or not lp.Character then return nil end
    local hum = lp.Character:FindFirstChildOfClass("Humanoid")
    if hum and (hum.Health or 0) <= 0 then return nil end
    local head = lp.Character:FindFirstChild("Head")
    if not head then return nil end
    return head.Position
end

local function paintHats()
    if not ui.getValue(TAB, "misc", "China hat") then return end
    if not bb.pos then return end

    local maxDist = ui.getValue(TAB, "misc", "China hat max distance") or 500.0
    maxDist = clamp(tonumber(maxDist) or 500.0, 50.0, 2000.0)

    local hatColor = rgbaFromUi(TAB, "misc", "China hat Color", Color3.fromRGB(255, 90, 90))

    local players = entity.GetPlayers(false) or {}

    for _, p in ipairs(players) do
        if p and p.Name ~= bb.playerName and p.IsAlive then
            local headPos = p.GetBonePosition and p:GetBonePosition("Head")
            if headPos then
                coneHat(headPos, hatColor, bb.pos, maxDist)
            end
        end
    end

    if ui.getValue(TAB, "misc", "China hat self esp") then
        local selfHead = headHere()
        if selfHead then
            coneHat(selfHead, hatColor, bb.pos, maxDist)
        end
    end
end

local function mainDraw()
    paintDist()
    paintLine()
    paintTraces()
    paintRing()
    paintClock()
    paintTrails()
    paintDots()
    paintHats()
    paintEsp()
    paintLastHit()
    paintTag()
    paintFeed()
    paintRipple()
    paintSparks()
end

cheat.register("onUpdate", mainTick)
cheat.register("onPaint", mainDraw)

print("[bb] dm me  if u get any errors.")
