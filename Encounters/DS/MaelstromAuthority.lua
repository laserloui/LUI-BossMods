require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "MaelstromAuthority"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss"] = "Maelstrom Authority",
        ["unit.station"] = "Weather Station",
        -- Messages
        ["message.station"] = "Next stations",
        -- Alerts
        ["alert.station"] = "Weather Stations spawned!",
        -- Casts
        ["cast.weather_cycle"] = "Activate Weather Cycle",
        ["cast.shatter"] = "Shatter",
    },
    ["deDE"] = {
        -- Units
        ["unit.boss"] = "Mahlstromgewalt",
        ["unit.station"] = "Wetterstation",
        -- Messages
        ["message.station"] = "Nächste Wetterstation",
        -- Alerts
        ["alert.station"] = "Wetterstationen gespawned!",
        -- Casts
        ["cast.weather_cycle"] = "Wetterzyklus aktivieren",
        ["cast.shatter"] = "Zerschmettern",
    },
    ["frFR"] = {
        -- Units
        ["unit.boss"] = "Contrôleur du Maelstrom",
        ["unit.station"] = "Station météorologique",
        -- Messages
        ["message.station"] = "Prochaines stations",
        -- Alerts
        ["alert.station"] = "Spawn des Stations !",
        -- Casts
        ["cast.weather_cycle"] = "Activer cycle climatique",
        ["cast.shatter"] = "Fracasser",
    },
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Maelstrom Authority"
    self.tTrigger = {
        sType = "ANY",
        tNames = {"unit.boss"},
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 120,
            },
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
        timers = {
            station = {
                enable = true,
                label = "unit.station",
            },
        },
        alerts = {
            station = {
                enable = true,
                label = "unit.station",
            },
        },
        sounds = {
            station = {
                enable = true,
                file = "alert",
                label = "unit.station",
            },
        },
        lines = {
            station = {
                enable = true,
                priority = 1,
                thickness = 6,
                color = "ff00ffff",
                label = "unit.station",
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
    elseif sName == self.L["unit.station"] and bInCombat == true then
        self.core:PlaySound(self.config.sounds.station)
        self.core:DrawLineBetween(nId, tUnit, nil, self.config.lines.station)
        self.core:ShowAlert("Alert_Station", self.L["alert.station"], self.config.alerts.station)
        self.core:AddTimer("Timer_Station", self.L["message.station"], 25, self.config.timers.station)
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.station"] then
        self.core:RemoveLineBetween(nId)
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sName == self.L["Maelstrom Authority"] then
        if sCastName == self.L["cast.weather_cycle"] then
            self.core:AddTimer("Timer_Station", self.L["message.station"], 13, self.config.timers.station)
        elseif sCastName == self.L["cast.shatter"] then
            self.core:RemoveTimer("Timer_Station")
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
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
