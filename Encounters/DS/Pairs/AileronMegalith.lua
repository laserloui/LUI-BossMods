require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "AileronMegalith"

local Locales = {
    ["enUS"] = {
        -- Unit names
        ["unit.boss_air"] = "Aileron",
        ["unit.boss_earth"] = "Megalith",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Aileron & Megalith"
    self.groupName = "Elemental Pairs"
    self.tTrigger = {
        sType = "ALL",
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 117,
            },
        },
        tNames = {
            ["enUS"] = {"Aileron","Megalith"},
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        units = {
            boss_air = {
                enable = true,
                label = "unit.boss_air",
                color = "af00ffff",
            },
            boss_earth = {
                enable = true,
                label = "unit.boss_earth",
                color = "afff932f",
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

    if sName == self.L["unit.boss_air"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_air.enable,false,false,false,nil,self.config.units.boss_air.color)
    elseif sName == self.L["unit.boss_earth"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_earth.enable,false,false,false,nil,self.config.units.boss_earth.color)
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
