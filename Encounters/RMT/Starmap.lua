require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Starmap"

local Locales = {
    ["enUS"] = {
        ["unit.world_ender"] = "World Ender",
        ["unit.asteroid"] = "Rogue Asteroid",
        ["unit.debris"] = "Cosmic Debris",
        -- Messages
        ["message.next_world_ender"] = "Next World Ender",
        -- Alerts
        ["alert.solar_wind"] = "Reset your stacks!",
        -- Labels
        ["label.solar_wind"] = "Solar Wind Stacks",
    },
    ["deDE"] = {
        ["unit.boss"] = "Starmap",
    },
    ["frFR"] = {
        ["unit.boss"] = "Starmap",
    },
}

local DEBUFF_SOLAR_WIND = 87536

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"
    self.displayName = "Starmap"
    self.tTrigger = {
        tZones = {
            [1] = {
                continentId = 104,
                parentZoneId = 548,
                mapId = 556,
            },
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        units = {
            world_ender = {
                enable = true,
                label = "unit.world_ender",
            }
        },
        timers = {
            world_ender = {
                enable = true,
                label = "message.next_world_ender",
            },
        },
        alerts = {
            solar_wind = {
                enable = true,
                label = "label.solar_wind",
            },
        },
        auras = {
            solar_wind = {
                enable = true,
                sprite = "LUIBM_heat",
                color = "ffffa500",
                label = "label.solar_wind",
            },
        },
        lines = {
            world_ender = {
                enable = true,
                thickness = 16,
                color = "ff00ffff",
                label = "unit.world_ender",
            },
            asteroid = {
                enable = true,
                thickness = 8,
                color = "ffff0000",
                label = "unit.asteroid",
            },
            debris = {
                enable = true,
                thickness = 8,
                color = "ffff0000",
                label = "unit.debris",
            },
        },
        sounds = {
            solar_wind = {
                enable = true,
                file = "beware",
                label = "label.solar_wind",
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

    if sName == self.L["unit.world_ender"] then
        self.core:DrawLine(nId, tUnit, self.config.lines.world_ender, 30)
        self.core:AddUnit(nId,sName,tUnit,self.config.units.world_ender)
        self.core:AddTimer("Timer_WorldEnder", self.L["message.next_world_ender"], 66, self.config.timers.world_ender)
    elseif sName == self.L["unit.asteroid"] then
        self.core:DrawLine(nId, tUnit, self.config.lines.asteroid, 15)
    elseif sName == self.L["unit.debris"] then
        self.core:DrawPolygon(nId, tUnit, self.config.lines.debris, 3, 0, 6)
    end
end

function Mod:OnBuffUpdated(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF_SOLAR_WIND == nSpellId then
        if tData.tUnit:IsThePlayer() then
            if nStack >= 6 then
                self.core:ShowAura("STACKS", self.config.auras.solar_wind, nDuration, self.L["alert.solar_wind"])

                if not self.warned then
                    self.core:PlaySound(self.config.sounds.solar_wind)
                    self.core:ShowAlert("STACKS", self.L["alert.solar_wind"], self.config.alerts.solar_wind)
                    self.warned = true
                end
            end
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if DEBUFF_SOLAR_WIND == nSpellId then
        if tData.tUnit:IsThePlayer() then
            self.core:HideAura("STACKS")
            self.warned = nil
        end
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
    self.core:AddTimer("Timer_WorldEnder", self.L["message.next_world_ender"], 60, self.config.timers.world_ender)
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
