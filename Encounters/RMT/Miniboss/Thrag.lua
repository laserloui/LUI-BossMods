require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Thrag"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss"] = "Chief Enginer Scrubber Thrag",
        ["unit.bomb"] = "Jumpstart Charge",
        -- Casts
        ["cast.gigavolt"] = "Gigavolt",
        -- Alerts
        ["alert.gigavolt"] = "GIGAVOLT - SPREAD!",
        -- Labels
        ["label.bomb"] = "Bombs",
    },
    ["deDE"] = {},
    ["frFR"] = {
        -- Units
        ["unit.boss"] = "Chef Ingénieur Lave-Pont Thrag",
        ["unit.bomb"] = "Jumpstart Charge",
        -- Casts
        ["cast.gigavolt"] = "Gigavolt", -- Translation needed!
        -- Alerts
        ["alert.gigavolt"] = "GIGAVOLT - SÉPARER-VOUS !",
        -- Labels
        ["label.bomb"] = "Bombes",
    },
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"
    self.displayName = "Thrag"
    self.groupName = "Minibosses"
    self.tTrigger = {
        sType = "ANY",
        tNames = {"unit.boss"},
        tZones = {
            [1] = {
                continentId = 104,
                parentZoneId = 548,
                mapId = 552,
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
        lines = {
            bomb = {
                enable = true,
                thickness = 4,
                color = "afff0000",
                label = "label.bomb",
            },
        },
        casts = {
            gigavolt = {
                enable = true,
                label = "cast.gigavolt",
            },
        },
        alerts = {
            gigavolt = {
                enable = true,
                label = "cast.gigavolt",
            },
        },
        sounds = {
            gigavolt = {
                enable = true,
                file = "beware",
                label = "cast.gigavolt",
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
    elseif sName == self.L["unit.bomb"] then
        self.core:DrawLineBetween(nId, tUnit, nil, self.config.lines.bomb)
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.bomb"] then
        self.core:RemoveLineBetween(nId)
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss"] and sCastName == self.L["cast.gigavolt"] then
        self.core:ShowAlert("gigavolt", self.L["alert.gigavolt"], self.config.alerts.gigavolt)
        self.core:PlaySound(self.config.sounds.gigavolt)
        self.core:ShowCast(tCast,sCastName,self.config.casts.gigavolt)
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
