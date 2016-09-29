require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "PyrobaneHydroflux"

local Locales = {
    ["enUS"] = {
        -- Unit names
        ["unit.boss_fire"] = "Pyrobane",
        ["unit.boss_water"] = "Hydroflux",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Pyrobane & Hydroflux"
    self.groupName = "Elemental Pairs"
    self.tTrigger = {
        sType = "ALL",
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 118,
            },
        },
        tNames = {
            ["enUS"] = {"Pyrobane", "Hydroflux"},
			["deDE"] = {"Pyroman", "Hydroflux"},
			["frFR"] = {"Pyromagnus", "Hydroflux"},
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        units = {
            boss_fire = {
                enable = true,
                label = "unit.boss_fire",
                color = "afff2f2f",
            },
            boss_water = {
                enable = true,
                label = "unit.boss_water",
                color = "af1e90ff",
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

    if sName == self.L["unit.boss_fire"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_fire.enable,false,false,false,nil,self.config.units.boss_fire.color)
    elseif sName == self.L["unit.boss_water"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_water.enable,false,false,false,nil,self.config.units.boss_water.color)
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
