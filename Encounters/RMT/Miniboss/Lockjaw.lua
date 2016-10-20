require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Lockjaw"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss"] = "Chief Warden Lockjaw",
        ["unit.circle_telegraph"] = "Hostile Invisible Unit for Fields (0 hit radius)",
        -- Casts
        ["cast.blaze_shackles"] = "Blaze Shackles",
        -- Labels
        ["label.circle_telegraph"] = "Circle Telegraphs",
    },
    ["deDE"] = {},
    ["frFR"] = {
        -- Units
        ["unit.boss"] = "Chef Directeur Tétanos",
        ["unit.circle_telegraph"] = "Unité de Champs Hostile Invisible (rayon d'action : 0)",
        -- Casts
        ["cast.blaze_shackles"] = "Entrave de Feu",
        -- Labels
        ["label.circle_telegraph"] = "Télégraphes Circulaire",
    },
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"
    self.displayName = "Lockjaw"
    self.groupName = "Minibosses"
    self.tTrigger = {
        sType = "ANY",
        tNames = {"unit.boss"},
        tZones = {
            [1] = {
                continentId = 104,
                parentZoneId = 548,
                mapId = 550,
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
            circle_telegraph = {
                enable = true,
                thickness = 7,
                color = "ffff1493",
                label = "label.circle_telegraph",
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
    if not self.run then
        return
    end

    if sName == self.L["unit.boss"] and bInCombat then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss)
    elseif sName == self.L["unit.circle_telegraph"] then
        self.core:DrawPolygon(nId, tUnit, self.config.lines.circle_telegraph, 6.5, 0, 20)
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.circle_telegraph"] then
        self.core:RemovePolygon(nId)
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
