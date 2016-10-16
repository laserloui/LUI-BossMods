require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Logic_HyperAcceleratedSkeledroid"

local Locales = {
    ["enUS"] = {
        -- Unit names
        ["unit.boss"] = "Hyper-Accelerated Skeledroid",
        -- Labels
        ["label.cleave"] = "Boss Cleave",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Hyper-Accelerated Skeledroid"
    self.groupName = "Minibosses"
    self.tTrigger = {
        sType = "ANY",
        tNames = {"unit.boss"},
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 111,
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
            },
        },
        lines = {
            boss = {
                enable = true,
                color = "ffff0000",
                thickness = 6,
                label = "labe.cleave",
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
        self.core:DrawLine("CleaveA", tUnit, self.config.lines.boss, 20, -50, 0, Vector3.New(2.3,0,-2.65))
        self.core:DrawLine("CleaveB", tUnit, self.config.lines.boss, 20, 50, 0, Vector3.New(-2.3,0,-2.65))
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
