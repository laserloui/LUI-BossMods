require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "PhageCouncil"

local Locales = {
    ["enUS"] = {
        ["unit.golgox"] = "Golgox the Lifecrusher",
        ["unit.terax"] = "Terax Blightweaver",
        ["unit.ersoth"] = "Ersoth Curseform",
        ["unit.noxmind"] = "Noxmind the Insidious",
        ["unit.vratorg"] = "Fleshmonger Vratorg",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Genetic Archives"
    self.displayName = "Phageborn Convergence"
    self.tTrigger = {
        sType = "ANY",
        tNames = {"unit.golgox", "unit.terax", "unit.ersoth", "unit.noxmind", "unit.vratorg"},
        tZones = {
            [1] = {
                continentId = 67,
                parentZoneId = 147,
                mapId = 149,
            },
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
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
