require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "ExperimentX89"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss"] = "Experiment X-89",
        -- Casts
        ["cast.shockwave"] = "Shattering Shockwave",
        ["cast.spew"] = "Repugnant Spew",
        ["cast.knockback"] = "Resounding Shout",
        -- Alerts
        ["alert.small_bomb"] = "Small Bomb on %s!",
        ["alert.small_bomb_player"] = "SMALL BOMB ON YOU! - RUN AWAY!",
        ["alert.big_bomb"] = "Big Bomb on %s!",
        ["alert.big_bomb_player"] = "BIG BOMB ON YOU! - JUMP OFF!",
        ["alert.knockback"] = "KNOCKBACK!",
        ["alert.spew"] = "SPEW!",
        -- Labels
        ["label.small_bomb"] = "Small Bomb",
        ["label.big_bomb"] = "Big Bomb",
        ["label.shockwave"] = "Shockwave",
        ["label.knockback"] = "Knockback",
        ["label.spew"] = "Spew",
    },
    ["deDE"] = {
        -- Units
        ["unit.boss"] = "Experiment X-89",
        -- Casts
        ["cast.shockwave"] = "Zerschmetternde Schockwelle",
        ["cast.spew"] = "Widerliches Erbrochenes",
        ["cast.knockback"] = "Widerhallender Schrei",
        -- Alerts
        ["alert.small_bomb"] = "Kleine Bombe auf %s!",
        ["alert.small_bomb_player"] = "KLEINE BOMBE AUF DIR! - LAUF WEG!",
        ["alert.big_bomb"] = "Große Bombe auf %s!",
        ["alert.big_bomb_player"] = "GROßE BOMBE AUF DIR! - SPRING HINUNTER!",
        ["alert.knockback"] = "KNOCKBACK!",
        ["alert.spew"] = "SPEW!",
        -- Labels
        ["label.small_bomb"] = "Kleine Bombe",
        ["label.big_bomb"] = "Große Bombe",
        ["label.shockwave"] = "Schockwelle",
        ["label.knockback"] = "Knockback",
        ["label.spew"] = "Spew",
    },
    ["frFR"] = {
        -- Units
        ["unit.boss"] = "Expérience X-89",
        -- Casts
        ["cast.shockwave"] = "Onde de choc dévastatrice",
        ["cast.spew"] = "Crachat répugnant",
        ["cast.knockback"] = "Hurlement retentissant",
        -- Alerts
        ["alert.small_bomb"] = "Petite bombe sur %s !",
        ["alert.small_bomb_player"] = "Petite bombe sur toi ! - Eloigne toi !",
        ["alert.big_bomb"] = "Grosse bombe sur %s !",
        ["alert.big_bomb_player"] = "Grosse Bombe sur toi ! - Saute dans le vide !",
        ["alert.knockback"] = "Repoussement !",
        ["alert.spew"] = "CRACHAT !",
        -- Labels
        ["label.small_bomb"] = "Petite bombe",
        ["label.big_bomb"] = "Grosse bombe",
        ["label.shockwave"] = "Onde de choc",
        ["label.knockback"] = "Repoussement",
        ["label.spew"] = "Crachat",
    },
}

local DEBUFF_SMALL_BOMB = 47316
local DEBUFF_BIG_BOMB = 47285

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Genetic Archives"
    self.displayName = "Experiment X-89"
    self.tTrigger = {
        sType = "ANY",
        tNames = {"unit.boss"},
        tZones = {
            [1] = {
                continentId = 67,
                parentZoneId = 147,
                mapId = 148,
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
        casts = {
            knockback = {
                enable = true,
                position = 1,
                label = "label.knockback",
            },
            shockwave = {
                enable = true,
                position = 2,
                label = "label.shockwave",
            },
            spew = {
                enable = true,
                position = 3,
                label = "label.spew",
            },
        },
        alerts = {
            small_bomb = {
                enable = true,
                position = 1,
                label = "label.small_bomb",
            },
            big_bomb = {
                enable = true,
                position = 2,
                label = "label.big_bomb",
            },
            knockback = {
                enable = true,
                position = 3,
                label = "label.knockback",
            },
            spew = {
                enable = true,
                position = 4,
                label = "label.spew",
            },
        },
        sounds = {
            small_bomb = {
                enable = true,
                file = "run-away",
                position = 1,
                label = "label.small_bomb",
            },
            big_bomb = {
                enable = true,
                file = "alert",
                position = 2,
                label = "label.big_bomb",
            },
        },
        auras = {
            small_bomb = {
                enable = true,
                position = 1,
                sprite = "LUIBM_bomb",
                color = "ff00ff00",
                label = "label.small_bomb",
            },
            big_bomb = {
                enable = true,
                position = 2,
                sprite = "LUIBM_bomb",
                color = "ffff0000",
                label = "label.big_bomb",
            },
        },
        icons = {
            small_bomb = {
                enable = true,
                sprite = "run",
                size = 80,
                color = "ffffd700",
                label = "label.small_bomb",
            },
            big_bomb = {
                enable = true,
                sprite = "bomb",
                size = 80,
                color = "ffff0000",
                label = "label.big_bomb",
            },
        },
        lines = {
            boss = {
                enable = true,
                thickness = 10,
                color = "ffff0000",
                label = "unit.boss",
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

    if sName == self.L["unit.boss"] and bInCombat then
        self.core:AddUnit(nId, sName, tUnit, self.config.units.boss)
        self.core:DrawLine(nId, tUnit, self.config.lines.boss, 30)
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF_SMALL_BOMB == nSpellId then
        if tData.tUnit:IsThePlayer() then
            self.core:ShowAura("Aura_SmallBomb", self.config.auras.small_bomb, nDuration, "SMALL Bomb on you!")
            self.core:ShowAlert("Alert_SmallBomb", self.L["alert.small_bomb_player"], self.config.alerts.small_bomb)
            self.core:PlaySound(self.config.sounds.small_bomb)
        else
            self.core:DrawIcon("Icon_SmallBomb", tData.tUnit, self.config.icons.small_bomb, nil, nDuration)
            self.core:ShowAlert("Alert_SmallBomb", self.L["alert.small_bomb"]:format(sUnitName), self.config.alerts.small_bomb)
        end
    elseif DEBUFF_BIG_BOMB == nSpellId then
        if tData.tUnit:IsThePlayer() then
            self.core:ShowAura("Aura_BigBomb", self.config.auras.big_bomb, nDuration, "BIG Bomb on you!")
            self.core:ShowAlert("Alert_BigBomb", self.L["alert.big_bomb_player"], self.config.alerts.big_bomb)
            self.core:PlaySound(self.config.sounds.big_bomb)
        else
            self.core:DrawIcon("Icon_BigBomb", tData.tUnit, self.config.icons.big_bomb, nil, nDuration)
            self.core:ShowAlert("Alert_BigBomb", self.L["alert.big_bomb"]:format(sUnitName), self.config.alerts.big_bomb)
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if DEBUFF_SMALL_BOMB == nSpellId then
        self.core:HideAura("Aura_SmallBomb")
        self.core:RemoveIcon("Icon_SmallBomb")
    elseif DEBUFF_BIG_BOMB == nSpellId then
        self.core:HideAura("Aura_BigBomb")
        self.core:RemoveIcon("Icon_BigBomb")
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss"] then
        if sCastName == self.L["cast.shockwave"] then
            self.core:ShowCast(tCast, sCastName, self.config.casts.shockwave)

        elseif sCastName == self.L["cast.spew"] then
            self.core:ShowCast(tCast, sCastName, self.config.casts.spew)
            self.core:ShowAlert("SPEW", self.L["alert.spew"], self.config.alerts.spew)

        elseif sCastName == self.L["cast.knockback"] then
            self.core:ShowCast(tCast, sCastName, self.config.casts.knockback)
            self.core:ShowAlert("KNOCKBACK", self.L["alert.knockback"], self.config.alerts.knockback)
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
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
