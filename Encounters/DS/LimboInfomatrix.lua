require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "LimboInfomatrix"

local Locales = {
    ["enUS"] = {
        ["unit.antlion"] = "Infomatrix Antlion",
    },
    ["deDE"] = {},
    ["frFR"] = {
        ["unit.antlion"] = "Fourmilion de l'Infomatrice",
    },
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Limbo Infomatrix"
    self.tTrigger = {
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 114,
            },
        }
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        icons = {
            antlion = {
                enable = true,
                sprite = "LUIBM_crosshair",
                size = 60,
                color = "ff00ffff",
                label = "unit.antlion",
            },
        },
        lines = {
            antlion = {
                enable = true,
                thickness = 6,
                max = 220,
                color = "ff00ffff",
                label = "unit.antlion",
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

    if sName == self.L["unit.antlion"] then
        self.core:DrawLineBetween("Line"..tostring(nId), tUnit, nil, self.config.lines.antlion)
        self.core:DrawIcon("Icon"..tostring(nId), tUnit, self.config.icons.antlion, true)
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.antlion"] then
        self.core:RemoveLineBetween("Line"..tostring(nId))
        self.core:RemoveIcon("Icon"..tostring(nId))
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
