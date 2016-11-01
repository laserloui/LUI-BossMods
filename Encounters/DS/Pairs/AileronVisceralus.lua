require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "AileronVisceralus"

local Locales = {
    ["enUS"] = {
        -- Unit names
        ["unit.boss_air"] = "Aileron",
        ["unit.boss_life"] = "Visceralus",
        ["unit.life_orb"] = "Life Force",
        -- Labels
        ["label.life_force_shackle"] = "No-Healing Debuff",
    },
    ["deDE"] = {
        -- Units
        ["unit.boss_air"] = "Aileron",
        ["unit.boss_life"] = "Viszeralus",
        ["unit.life_orb"] = "Lebenskraft",
        -- Labels
        ["label.life_force_shackle"] = "Keine-Heilung Debuff",
    },
    ["frFR"] = {
        -- Units
        ["unit.boss_air"] = "Ventemort",
        ["unit.boss_life"] = "Visceralus",
        ["unit.life_orb"] = "Force vitale",
        -- Labels
        ["label.life_force_shackle"] = "Aucun-Soin Debuff",
    },
}

local DEBUFF_LIFE_FORCE_SHACKLE = 74366

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Aileron & Visceralus"
    self.groupName = "Elemental Pairs"
    self.tTrigger = {
        sType = "ALL",
        tNames = {"unit.boss_air", "unit.boss_life"},
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 119,
            },
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
            },
            boss_life = {
                enable = true,
                label = "unit.boss_life",
            },
        },
        icons = {
            life_force_shackle = {
                enable = true,
                sprite = "LUIBM_voodoo",
                size = 80,
                color = "ffadff2f",
                label = "label.life_force_shackle",
            },
        },
        lines = {
            life_orb = {
                enable = true,
                thickness = 6,
                color = "ffadff2f",
                label = "unit.life_orb",
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
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_air)
    elseif sName == self.L["unit.boss_life"] and bInCombat == true then
        self.visceralus = tUnit
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_life)
    elseif sName == self.L["unit.life_orb"] then
        if self.visceralus then
            self.core:DrawLineBetween(nId, tUnit, self.visceralus, self.config.lines.life_orb)
        end
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.life_orb"] then
        self.core:RemoveLineBetween(nId)
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF_LIFE_FORCE_SHACKLE == nSpellId then
        self.core:DrawIcon("NoHeal_"..tostring(nId), tData.tUnit, self.config.icons.life_force_shackle, true)
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if DEBUFF_LIFE_FORCE_SHACKLE == nSpellId then
        self.core:RemoveIcon("NoHeal_"..tostring(nId))
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
