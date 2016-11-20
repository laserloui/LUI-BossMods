require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Octog"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss"] = "Star-Eater the Voracious",
    	["unit.astral_shard"] = "Astral Shard",
        ["unit.squirgling"] = "Squirgling",
        ["unit.chaos_orb"] = "Chaos Orb",
        ["unit.noxious_ink_pool"] = "Noxious Ink Pool",
        -- Casts
        ["cast.hookshot"] = "Hookshot",
        ["cast.summon_squirglings"] = "Summon Squirglings",
        ["cast.flamethrower"] = "Flamethrower",
        ["cast.supernova"] = "Supernova",
        -- Labels
        ["label.next_hookshot"] = "Next Hookshot",
        ["label.next_flamethrower"] = "Next Flamethrower",
        ["label.next_orbs"] = "Next Orbs",
    },
    ["deDE"] = {
        ["unit.boss"] = "Star-Eater the Voracious",
    },
    ["frFR"] = {
        ["unit.boss"] = "Star-Eater the Voracious",
    },
}

local DEBUFF_NOXIOUS_INK = 85533 -- DoT for standing in circles
local DEBUFF_SQUINGLING_SMASHER = 86804 -- +5% DPS/heals, -10% incoming heals; per stack
local DEBUFF_CHAOS_TETHER = 85583 -- kills you if you leave orb area
local DEBUFF_CHAOS_ORB = 85582 -- 10% more damage taken per stack
local DEBUFF_REND = 85443 -- main tank stacking debuff, 2.5% less mitigation per stack
local DEBUFF_SPACE_FIRE = 87159 -- 12k dot from flame, lasts 45 seconds
local BUFF_CHAOS_ORB = 86876 -- Countdown to something, probably the orb wipe
local BUFF_CHAOS_AMPLIFIER = 86876 -- Bosun Buff that increases orb count?
local BUFF_FLAMETHROWER = 87059 -- Flamethrower countdown buff -- DOESN'T EXIST ANYMORE, used to be 15s countdown to flame cast
local BUFF_ASTRAL_SHIELD = 85643 -- Shard phase shield, 20 stacks
local BUFF_ASTRAL_SHARD = 85611 --Buff shards get right before they die, probably meaningless

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"
    self.displayName = "Octog"
    self.tTrigger = {
        sType = "ANY",
        tNames = {"unit.boss"},
        tZones = {
            [1] = {
                continentId = 104,
                parentZoneId = 0,
                mapId = 548,
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
                position = 1,
            },
        },
        timers = {
            hookshot = {
                enable = true,
                position = 1,
                label = "label.next_hookshot",
            },
            flamethrower = {
                enable = true,
                position = 2,
                label = "label.next_flamethrower",
            },
            orbs = {
                enable = true,
                position = 3,
                label = "label.next_orbs",
            },
            supernova = {
                enable = true,
                position = 4,
                label = "cast.supernova",
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
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if BUFF_CHAOS_AMPLIFIER == nSpellId then
        self.core:AddTimer("ORBS", self.L["label.next_orbs"], 80, self.config.timers.orbs)
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if self.L["unit.boss"] == sName then
        if self.L["cast.hookshot"] == sCastName then
            self.core:AddTimer("HOOKSHOT", self.L["label.next_hookshot"], 30, self.config.timers.hookshot)
        elseif self.L["cast.supernova"] == sCastName then
            self.core:RemoveTimer("HOOKSHOT")
            self.core:RemoveTimer("FLAMETHROWER")
            self.core:RemoveTimer("ORBS")
            self.core:AddTimer("SUPERNOVA", self.L["cast.supernova"], 25, self.config.timers.supernova)
        elseif self.L["cast.flamethrower"] == sCastName then
            self.core:AddTimer("FLAMETHROWER", self.L["label.next_flamethrower"], 45, self.config.timers.flamethrower)
        end
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

    self.core:AddTimer("HOOKSHOT", self.L["label.next_hookshot"], 45, self.config.timers.hookshot)
    self.core:AddTimer("FLAMETHROWER", self.L["label.next_flamethrower"], 35, self.config.timers.flamethrower)
    self.core:AddTimer("ORBS", self.L["label.next_orbs"], 48, self.config.timers.orbs)
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
