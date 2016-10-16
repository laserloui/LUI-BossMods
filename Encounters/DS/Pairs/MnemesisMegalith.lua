require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "MnemesisMegalith"

local Locales = {
    ["enUS"] = {
        -- Unit names
        ["unit.boss_logic"] = "Mnemesis",
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
    self.displayName = "Mnemesis & Megalith"
    self.groupName = "Elemental Pairs"
    self.tTrigger = {
        sType = "ALL",
        tNames = {"unit.boss_logic", "unit.boss_earth"},
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 117,
            },
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        units = {
            boss_logic = {
                enable = true,
                label = "unit.boss_logic",
                color = "afadff2f",
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

    if sName == self.L["unit.boss_logic"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_logic)
    elseif sName == self.L["unit.boss_earth"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_earth)
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
