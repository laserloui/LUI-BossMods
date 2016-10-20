require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Augmentors"

local Locales = {
    ["enUS"] = {
        ["Prime Evolutionary Operant"] = "Prime Evolutionary Operant",
        ["Prime Phage Distributor"] = "Prime Phage Distributor",
        ["Organic Incinerator"] = "Organic Incinerator",
    },
    ["deDE"] = {},
    ["frFR"] = {
        ["Prime Evolutionary Operant"] = "Opérateur de la Primo Évolution",
        ["Prime Phage Distributor"] = "Distributeur de Primo Phage",
        ["Organic Incinerator"] = "Incinérateur organique",
    },
}

local sin, cos, rad = math.sin, math.cos, math.rad

-- local DEBUFF_RADIATION_BATH = 71188
-- local DEBUFF_STRAIN_INCUBATION = 49303

local Aug = {
    [1] = Vector3.New(1268.16, -800.51, 830.32),
    [2] = Vector3.New(1227.63, -800.51, 900.47),
    [3] = Vector3.New(1308.60, -800.51, 900.56)
}

-- Thanks to KuronaSilversky <3
local Coords = {
    [1] = {
        [1] = {
            ["x"] = 1302.87,
            ["z"] = 837.23,
        },
        [2] = {
            ["x"] = 1303.22,
            ["z"] = 823.23,
        },
        [3] = {
            ["x"] = 1291.21,
            ["z"] = 803.33
        },
        [4] = {
            ["x"] = 1280.26,
            ["z"] = 796.33
        },
        [5] = {
            ["x"] = 1256.22,
            ["z"] = 796.51,
        },
        [6] = {
            ["x"] = 1244.71,
            ["z"] = 802.90,
        },
        [7] = {
            ["x"] = 1232.53,
            ["z"] = 823.87,
        },
        [8] = {
            ["x"] = 1232.62,
            ["z"] = 836.80,
        },
        [9] = {
            ["x"] = 1278.79,
            ["z"] = 823.45,
        },
        [10] = {
            ["x"] = 1268.00,
            ["z"] = 817.31,
        },
        [11] = {
            ["x"] = 1256.95,
            ["z"] = 823.64,
        },
    },
    [2] = {
        [1] = {
            ["x"] = 1215.35,
            ["z"] = 866.08,
        },
        [2] = {
            ["x"] = 1204.24,
            ["z"] = 872.99,
        },
        [3] = {
            ["x"] = 1191.91,
            ["z"] = 893.94
        },
        [4] = {
            ["x"] = 1191.86,
            ["z"] = 906.97
        },
        [5] = {
            ["x"] = 1204.29,
            ["z"] = 927.76,
        },
        [6] = {
            ["x"] = 1215.66,
            ["z"] = 934.04,
        },
        [7] = {
            ["x"] = 1239.53,
            ["z"] = 933.933,
        },
        [8] = {
            ["x"] = 1250.87,
            ["z"] = 927.76,
        },
        [9] = {
            ["x"] = 1216.43,
            ["z"] = 894.04,
        },
        [10] = {
            ["x"] = 1216.33,
            ["z"] = 906.61,
        },
        [11] = {
            ["x"] = 1227.33,
            ["z"] = 912.87,
        },
    },
    [3] = {
        [1] = {
            ["x"] = 1285.45,
            ["z"] = 927.58
        },
        [2] = {
            ["x"] = 1296.25,
            ["z"] = 934.77
        },
        [3] = {
            ["x"] = 1320.93,
            ["z"] = 935.26,
        },
        [4] = {
            ["x"] = 1332.09,
            ["z"] = 928.45,
        },
        [5] = {
            ["x"] = 1344.32,
            ["z"] = 907.19,
        },
        [6] = {
            ["x"] = 1344.04,
            ["z"] = 891.89,
        },
        [7] = {
            ["x"] = 1331.96,
            ["z"] = 873.30,
        },
        [8] = {
            ["x"] = 1321.60,
            ["z"] = 866.36,
        },
        [9] = {
            ["x"] = 1308.58,
            ["z"] = 913.53,
        },
        [10] = {
            ["x"] = 1319.61,
            ["z"] = 907.28,
        },
        [11] = {
            ["x"] = 1319.62,
            ["z"] = 894.53,
        },
    }
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Initialization Core Y-83"
    self.displayName = "Augmentors"
    self.tTrigger = {
        sType = "ANY",
        tZones = {
            [1] = {
                continentId = 8,
                parentZoneId = 0,
                mapId = 78,
            },
        },
        tNames = {
            ["enUS"] = {"Prime Evolutionary Operant","Prime Phage Distributor","Organic Incinerator"},
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = false,
        interval = 10,
        digitize = {
            enable = true,
            thickness = 2,
            height = 2,
        },
        incinerator = {
            enable = true,
            offset = 25,
            height = 15,
            thickness = 10,
            length = 80,
            spacing = 5,
            color = "ffff0000",
        },
        undermine = {
            enable = true,
            overlay = true,
            sprite = "Icon_SkillMind_UI_espr_cnfs",
            color = "ffff0000",
            size = 160,
            posX = 0,
            posY = 0,
            sound = {
                enable = true,
                unmute = true,
                file = "Sounds\alert.wav",
            },
            unit = {
                enable = true,
                size = 80,
                position = 0,
                sprite = "Icon_SkillMind_UI_espr_cnfs",
                color = "ffff0000",
            },
            telegraph = {
                enable = false,
                size = 100,
                sprite = "circle",
                color = "ffff0000",
            },
        },
        bath = {
            enable = true,
            overlay = true,
            sprite = "Icon_SkillMind_UI_espr_cnfs",
            color = "ffff0000",
            size = 160,
            posX = 0,
            posY = 0,
            sound = {
                enable = true,
                unmute = true,
                file = "Sounds\alert.wav",
            },
            unit = {
                enable = true,
                size = 80,
                position = 0,
                sprite = "Icon_SkillMind_UI_espr_cnfs",
                color = "ffff0000",
            },
            telegraph = {
                enable = false,
                size = 100,
                sprite = "circle",
                color = "ffff0000",
            },
        },
    }
    return o
end

function Mod:Init(parent)
    Apollo.LinkAddon(parent, self)

    self.core = parent
    self.L = parent:GetLocale(Encounter,Locales)
end

function Mod:OnNextFrame()
    if not self.run == true then
        return
    end

    if not self.unitPlayer then
        self.unitPlayer = GameLib.GetPlayerUnit()
        return
    end

    self.tick = Apollo.GetTickCount()

    if not self.lastCheck then
        self.lastCheck = self.tick
    end

    if (self.tick - self.lastCheck) > self.config.interval then
        self.wndOverlay:DestroyAllPixies()

        if not self.unitPlayer:IsInCombat() then
              Apollo.RemoveEventHandler("NextFrame",self)
            self.uIncinerator = nil
            return
        end

        if self.uIncinerator and self.config.incinerator.enable == true then
            self:DrawPixieLine()
        end

        if self.config.digitize.enable == true then
            self:DrawZoneLines()
        end
    end
end

function Mod:OnEnteredCombat(unit, bInCombat)
    if not self.run == true then
        return
    end
    --[[
    if unit:GetName() == self.L["Organic Incinerator"] then
        self.uIncinerator = unit
        Apollo.RemoveEventHandler("NextFrame",self)
        Apollo.RegisterEventHandler("NextFrame", "OnNextFrame", self)
    elseif unit:GetName() == self.L["Prime Phage Distributor"] then
        Apollo.RemoveEventHandler("NextFrame",self)
        Apollo.RegisterEventHandler("NextFrame", "OnNextFrame", self)
    end
    ]]
end

function Mod:OnUnitCreated(unit)
    if not self.run == true then
        return
    end
    --[[
    if unit:GetName() == self.L["Organic Incinerator"] then
        self.uIncinerator = unit
    end
    ]]
end

function Mod:DrawPixieLine()
    if not self.uIncinerator then
        return
    end

    local tface = self.uIncinerator:GetFacing()

    if tface == nil then
        return
    end

    local tpos = self.uIncinerator:GetPosition()
    local tangle = math.atan2(tface.x, tface.z)
    local tposV = Vector3.New(tpos.x,tpos.y+(self.config.height / 10),tpos.z)
    local dist = self.config.length
    local vect = tangle + rad(self.config.offset)

    local End = Vector3.New(tposV.x+dist*sin(vect), tposV.y, tposV.z+dist*cos(vect))
    local Offset = Vector3.InterpolateLinear(End, tposV, (1 - (self.config.spacing / 100)))

    self:DrawLine(End,Offset,self.config.color)
end

function Mod:DrawLine(startV, endV, col, sizeMod)
    local startPoint = GameLib.WorldLocToScreenPoint(startV)
    local endPoint = GameLib.WorldLocToScreenPoint(endV)

    self.wndOverlay:AddPixie({
        bLine = true,
        fWidth = sizeMod or self.config.thickness,
        cr = col,
        loc = {
            fPoints = { 0, 0, 0, 0 },
            nOffsets = { startPoint.x, startPoint.y, endPoint.x, endPoint.y }
        }
    })
end

function Mod:DrawZoneLines()
    local ppos = self.unitPlayer:GetPosition()
    local pvec = Vector3.New(ppos.x,ppos.y,ppos.z)
    local dist = 999
    local aug = 1
    local yPos = -800.60
    local tOffsets

    for i =1,3 do
        local len = ((Aug[i] - pvec):Length())
        if len < dist then
            aug = i
            dist = len
        end
    end

    self:DrawLine(Vector3.New(Coords[aug][1].x,yPos,Coords[aug][1].z), Vector3.New(Coords[aug][8].x,yPos,Coords[aug][8].z), "ffff0000", 2)

    local pos2 = Vector3.New(Coords[aug][2].x,yPos,Coords[aug][2].z)
    local pos7 = Vector3.New(Coords[aug][7].x,yPos,Coords[aug][7].z)
    -- local pos4 = Vector3.New(Coords[aug][4].x,yPos,Coords[aug][4].z)

    tOffsets = Coords[aug][9]
    self:DrawLine(Vector3.New(pos2.x,yPos,pos2.z), Vector3.New(tOffsets.x,yPos,tOffsets.z), "ff0000ff", 2)
    self:DrawLine(Vector3.New(Coords[aug][3].x,yPos,Coords[aug][3].z), Vector3.New(tOffsets.x,yPos,tOffsets.z), "ff0000ff", 2)

    tOffsets = Coords[aug][11]
    self:DrawLine(Vector3.New(pos7.x,yPos,pos7.z), Vector3.New(tOffsets.x,yPos,tOffsets.z), "ff00ff00", 2)
    self:DrawLine(Vector3.New(Coords[aug][6].x,yPos,Coords[aug][6].z), Vector3.New(tOffsets.x,yPos,tOffsets.z), "ff00ff00", 2)

    tOffsets = Coords[aug][10]
    self:DrawLine(Vector3.New(Coords[aug][4].x,yPos,Coords[aug][4].z), Vector3.New(tOffsets.x,yPos,tOffsets.z), "ffff8000", 2)

    tOffsets = Coords[aug][10]
    self:DrawLine(Vector3.New(Coords[aug][5].x,yPos,Coords[aug][5].z), Vector3.New(tOffsets.x,yPos,tOffsets.z), "ffff8000", 2)
end

function Mod:IsRunning()
    return self.run
end

function Mod:IsEnabled()
    return self.config.enable
end

function Mod:OnEnable()
    self.run = true
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
