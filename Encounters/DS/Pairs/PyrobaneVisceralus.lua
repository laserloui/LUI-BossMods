require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "PyrobaneVisceralus"

local Locales = {
    ["enUS"] = {
        -- Unit names
        ["unit.boss_fire"] = "Pyrobane",
        ["unit.boss_life"] = "Visceralus",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Pyrobane & Visceralus"
    self.groupName = "Elemental Pairs"
    self.tTrigger = {
        sType = "ALL",
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 119,
            },
        },
        tNames = {
            ["enUS"] = {"Pyrobane","Visceralus"},
            ["deDE"] = {"Pyrobane","Visceralus"},
            ["frFR"] = {"Pyrobane","Visceralus"},
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
            boss_life = {
                enable = true,
                label = "unit.boss_life",
                color = "af228b22",
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
    elseif sName == self.L["unit.boss_life"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_life.enable,false,false,false,nil,self.config.units.boss_life.color)
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
