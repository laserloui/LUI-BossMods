require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Test"

local Locales = {
    ["enUS"] = {
        ["unit.bossA"] = "Grimhowl Devourer",
        ["unit.bossB"] = "Grimhowl Limbripper",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Test"
    self.displayName = "Test"
    self.tTrigger = {
        tZones = {
            [1] = {
                continentId = 8,    -- Olyssia
                parentZoneId = 0,
                mapId = 0,
            },
            [2] = {
                continentId = 33,   -- Isigrol
                parentZoneId = 0,
                mapId = 0,
            },
            [3] = {
                continentId = 6,    -- Alizar
                parentZoneId = 0,
                mapId = 0,
            },
            [4] = {
                continentId = 92,   -- Arcterra
                parentZoneId = 0,
                mapId = 0,
            },
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        casts = {
            castA = {
                enable = true,
                color = "ffb22222",
                label = "cast.a"
            },
        },
        alerts = {
            alertA = {
                enable = true,
                color = "ffff4500",
                duration = 5,
                label = "alert.a"
            },
        },
    }
    return o
end

function Mod:Init(parent)
    Apollo.LinkAddon(parent, self)

    self.core = parent
    self.L = parent:GetLocale(Encounter,Locales)

    -- self.wndDebug = Apollo.LoadForm(self.core.xmlDoc, "Debug", nil, self)
    -- self.wndDebug:Show(true,true)

    -- math.randomseed(os.time())
    -- local id = math.random(6)
end

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run == true then
        return
    end

    if (sName == self.L["unit.bossA"] or sName == self.L["unit.bossB"]) and bInCombat == true then
        self.core:AddUnit(nId, sName, tUnit, true, true, true, true)
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName, nDuration)
    if (sName == self.L["unit.bossA"] or sName == self.L["unit.bossB"]) then
        self.core:ShowCast(tCast, sCastName)
        self.core:ShowAlert(sCastName, sCastName, nDuration)
    end
end

function Mod:OnCastEnd(nId, sCastName, tCast, sName)

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
