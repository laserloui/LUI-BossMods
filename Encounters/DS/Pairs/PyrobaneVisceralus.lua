require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "PyrobaneVisceralus"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss_fire"] = "Pyrobane",
        ["unit.boss_life"] = "Visceralus",
        ["unit.flame_wave"] = "Flame Wave",
        ["unit.life_orb"] = "Life Force",
        ["unit.life_essence"] = "Essence of Life",
        -- Messages
        ["message.next_midphase"] = "Next Midphase",
        -- Labels
        ["label.life_force_shackle"] = "No-Healing Debuff",
        ["label.midphase"] = "Midphase",
    },
    ["deDE"] = {
        -- Units
        ["unit.boss_fire"] = "Pyroman",
        ["unit.boss_life"] = "Viszeralus",
        ["unit.flame_wave"] = "Flammenwelle",
        ["unit.life_orb"] = "Lebenskraft",
        ["unit.life_essence"] = "Lebensessenz",
        -- Messages
        ["message.next_midphase"] = "Nächste Mitte Phase",
        -- Labels
        ["label.life_force_shackle"] = "Keine-Heilung Debuff",
        ["label.midphase"] = "Mitte Phase",
    },
    ["frFR"] = {
        -- Units
        ["unit.boss_fire"] = "Pyromagnus",
        ["unit.boss_life"] = "Visceralus",
        ["unit.flame_wave"] = "Vague de feu",
        ["unit.life_orb"] = "Force vitale",
        ["unit.life_essence"] = "Essence de vie",
        -- Messages
        ["message.next_midphase"] = "Prochaine Phase du Milieu",
        -- Labels
        ["label.life_force_shackle"] = "Debuff: Aucun-Soin",
        ["label.midphase"] = "Phase du Milieu",
    },
}

local DEBUFF_LIFE_FORCE_SHACKLE = 74366

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Pyrobane & Visceralus"
    self.groupName = "Elemental Pairs"
    self.tTrigger = {
        sType = "ALL",
        tNames = {"unit.boss_fire", "unit.boss_life"},
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
            boss_fire = {
                enable = true,
                position = 1,
                label = "unit.boss_fire",
            },
            boss_life = {
                enable = true,
                position = 2,
                label = "unit.boss_life",
            },
        },
        timers = {
            midphase = {
                enable = true,
                label = "label.midphase",
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
            flame_wave = {
                enable = true,
                thickness = 10,
                color = "ffff0000",
                label = "unit.flame_wave",
            },
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

    if sName == self.L["unit.boss_fire"] and bInCombat == true then
        local nHealth = tUnit:GetHealth()
        if nHealth and nHealth > 0 then
            self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_fire)
        end
    elseif sName == self.L["unit.boss_life"] and bInCombat == true then
        self.visceralus = tUnit
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_life)
    elseif sName == self.L["unit.flame_wave"] then
        self.core:DrawLine(nId, tUnit, self.config.lines.flame_wave, 25)
    elseif sName == self.L["unit.life_orb"] then
        if self.visceralus then
            self.core:DrawLineBetween(nId, tUnit, self.visceralus, self.config.lines.life_orb)
        end
    elseif sName == self.L["unit.life_essence"] then
        self.nLifeEssenceCount = self.nLifeEssenceCount + 1
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.flame_wave"] then
        self.core:RemoveLine(nId)
    elseif sName == self.L["unit.life_orb"] then
        self.core:RemoveLineBetween(nId)
    elseif sName == self.L["unit.life_essence"] then
        self.nLifeEssenceCount = self.nLifeEssenceCount - 1
        if self.nLifeEssenceCount == 0 then
            self.core:AddTimer("MIDPHASE", self.L["message.next_midphase"], 90, self.config.timers.midphase)
        end
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
    self.nLifeEssenceCount = 0
    self.core:AddTimer("MIDPHASE", self.L["message.next_midphase"], 90, self.config.timers.midphase)
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
