require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Gloomclaw"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss"] = "Gloomclaw",
        -- Casts
        ["cast.rupture"] = "Rupture",
        -- Alerts
        ["alert.interrupt_rupture"] = "Interrupt Rupture!",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Gloomclaw"
    self.tTrigger = {
        sType = "ANY",
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 115,
            },
        },
        tNames = {
            ["enUS"] = {"Gloomclaw"},
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        units = {
            boss = {
                enable = true,
                label = "unit.boss",
            }
        },
        casts = {
            rupture = {
                enable = true,
                color = "ffff4500",
                label = "cast.rupture",
            },
        },
        alerts = {
            rupture = {
                enable = true,
                label = "cast.rupture",
            },
        },
        sounds = {
            rupture = {
                enable = true,
                file = "alert",
                label = "cast.rupture",
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

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run == true then
        return
    end

    if sName == self.L["unit.boss"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss)
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss"] and sCastName == self.L["cast.rupture"] then
        self.core:PlaySound(self.config.sounds.rupture)
        self.core:ShowCast(tCast,sCastName,self.config.casts.rupture)
        self.core:ShowAlert(sCastName, self.L["alert.interrupt_rupture"], self.config.alerts.rupture)
    end
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
