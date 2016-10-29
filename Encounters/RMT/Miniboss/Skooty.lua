require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Skooty"

local Locales = {
    ["enUS"] = {
        ["unit.boss"] = "Assistant Technician Skooty",
        ["unit.bomb"] = "Jumpstart Charge",
        ["label.bomb"] = "Bombs",
    },
    ["deDE"] = {},
    ["frFR"] = {
        ["unit.boss"] = "Assistant Technicien Skooty",
        ["unit.bomb"] = "Jumpstart Charge", -- MISSING
        ["label.bomb"] = "Bombes",
    },
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"
    self.displayName = "Skooty"
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
