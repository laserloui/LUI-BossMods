require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "MnemesisVisceralus"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss_logic"] = "Mnemesis",
        ["unit.boss_life"] = "Visceralus",
        ["unit.life_orb"] = "Life Force",
        ["unit.essence_life"] = "Essence of Life",
        ["unit.essence_logic"] = "Essence of Logic",
        ["unit.tetris"] = "Alphanumeric Hash",
        ["unit.thorns"] = "Wild Brambles",
        -- Casts
        ["cast.defrag"] = "Defragment",
        -- Alerts
        ["alert.defrag"] = "DEFRAGMENT - SPREAD!",
        ["alert.snake"] = "SNAKE ON %s!",
        ["alert.snake_player"] = "SNAKE ON YOU!",
        -- Datachron
        ["datachron.enrage"] = "Time to die, sapients!",
        -- Labels
        ["label.next_thorns"] = "Next Thorns",
        ["label.next_defrag"] = "Next Defragment",
        ["label.life_force_shackle"] = "No-Healing Debuff",
        ["label.thorns"] = "Thorns Debuff",
        ["label.avatus"] = "Avatus incoming",
        ["label.enrage"] = "Enrage",
        ["label.snake"] = "Snake",
        ["label.snake_player"] = "Snake on player",
    },
    ["deDE"] = {
        -- Units
        ["unit.boss_logic"] = "Mnemesis",
        ["unit.boss_life"] = "Viszeralus",
        ["unit.life_orb"] = "Lebenskraft",
        ["unit.essence_life"] = "Lebensessenz",
        ["unit.essence_logic"] = "Logikessenz",
        ["unit.tetris"] = "Alphanumerische Raute",
        ["unit.thorns"] = "Wild Brambles", -- Missing
        -- Casts
        ["cast.defrag"] = "Defragmentieren",
        -- Alerts
        ["alert.defrag"] = "DEFRAGMENTIEREN - VERTEILEN!",
        ["alert.snake"] = "SCHLANGE AUF %s!",
        ["alert.snake_player"] = "SCHLANGE AUF DIR!",
        -- Datachron
        ["datachron.enrage"] = "Zeit, zu sterben, Vernunftbegabte!",
        -- Labels
        ["label.next_thorns"] = "Nächste Dornen",
        ["label.next_defrag"] = "Nächste Defragmentierung",
        ["label.life_force_shackle"] = "Keine-Heilung Debuff",
        ["label.thorns"] = "Dornen Debuff",
        ["label.avatus"] = "Avatus incoming",
        ["label.enrage"] = "Enrage",
        ["label.snake"] = "Schlange",
        ["label.snake_player"] = "Schlange auf Spieler",
    },
    ["frFR"] = {
        -- Units
        ["unit.boss_logic"] = "Mnémésis",
        ["unit.boss_life"] = "Visceralus",
        ["unit.life_orb"] = "Force vitale",
        ["unit.essence_life"] = "Essence de vie",
        ["unit.essence_logic"] = "Essence de logique",
        ["unit.tetris"] = "Alphanumeric Hash",
        ["unit.thorns"] = "Ronces sauvages",
        -- Casts
        ["cast.defrag"] = "Défragmentation",
        -- Alerts
        ["alert.defrag"] = "DÉFRAGMENTATION - SÉPARER-VOUS !",
        ["alert.snake"] = "SERPENT SUR %s !",
        ["alert.snake_player"] = "SERPENT SUR VOUS !",
        -- Datachron
        ["datachron.enrage"] = "Maintenant c'est l'heure de mourir, misérables !",
        -- Labels
        ["label.next_thorns"] = "Epines suivantes",
        ["label.next_defrag"] = "Défragmentation suivante",
        ["label.life_force_shackle"] = "Debuff: Aucun-Soin",
        ["label.thorns"] = "Debuff: Epines",
        ["label.avatus"] = "Avatus est arrivé",
        ["label.enrage"] = "Enrager",
        ["label.snake"] = "Serpent",
        ["label.snake_player"] = "Serpent sur le joueur",
    },
}

local DEBUFF_LIFE_FORCE_SHACKLE = 74366
local DEBUFF_SNAKE_SNACK = 74570
local DEBUFF_THORNS = 75031

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Mnemesis & Visceralus"
    self.groupName = "Elemental Pairs"
    self.tTrigger = {
        sType = "ALL",
        tNames = {"unit.boss_logic", "unit.boss_life"},
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
            boss_logic = {
                enable = true,
                label = "unit.boss_logic",
            },
            boss_life = {
                enable = true,
                label = "unit.boss_life",
            },
        },
        timers = {
            defrag = {
                enable = true,
                position = 1,
                color = "c800bfff",
                label = "label.next_defrag",
            },
            thorns = {
                enable = true,
                position = 2,
                color = "c8ffa500",
                label = "label.next_thorns",
            },
            enrage = {
                enable = true,
                position = 3,
                label = "label.enrage",
            },
        },
        auras = {
            snake_player = {
                enable = true,
                sprite = "LUIBM_virus",
                color = "ffadff2f",
                label = "label.snake_player",
            },
        },
        alerts = {
            defrag = {
                enable = true,
                position = 1,
                label = "cast.defrag",
            },
            snake = {
                enable = true,
                position = 2,
                label = "label.snake",
            },
            snake_player = {
                enable = true,
                position = 3,
                label = "label.snake_player",
            },
        },
        sounds = {
            defrag = {
                enable = true,
                file = "info",
                label = "cast.defrag",
            },
            snake_player = {
                enable = true,
                file = "run-away",
                label = "label.snake_player",
            },
        },
        icons = {
            snake_player = {
                enable = true,
                sprite = "LUIBM_virus",
                size = 80,
                color = "ffadff2f",
                label = "label.snake_player",
            },
            life_force_shackle = {
                enable = true,
                sprite = "LUIBM_voodoo",
                size = 80,
                color = "ffadff2f",
                label = "label.life_force_shackle",
            },
            thorns = {
                enable = false,
                sprite = "LUIBM_hand",
                size = 80,
                color = "ffff0000",
                label = "label.thorns",
            },
        },
        lines = {
            defrag = {
                enable = true,
                position = 1,
                thickness = 6,
                color = "ffff0000",
                label = "cast.defrag",
            },
            life_orb = {
                enable = true,
                position = 2,
                thickness = 6,
                color = "ffadff2f",
                label = "unit.life_orb",
            },
            tetris = {
                enable = true,
                position = 3,
                thickness = 8,
                color = "ffadff2f",
                label = "unit.tetris",
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
    elseif sName == self.L["unit.boss_life"] and bInCombat == true then
        self.visceralus = tUnit
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_life)
    elseif sName == self.L["unit.essence_logic"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.essence_logic)
    elseif sName == self.L["unit.essence_life"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.essence_life)
        self.core:RemoveTimer("DEFRAG")
        self.core:RemoveTimer("THORNS")
    elseif sName == self.L["unit.life_orb"] then
        if self.visceralus then
            self.core:DrawLineBetween(nId, tUnit, self.visceralus, self.config.lines.life_orb)
        end
    elseif sName == self.L["unit.tetris"] then
        self.core:DrawLine(nId, tUnit, self.config.lines.tetris, 30)
    elseif sName == self.L["unit.thorns"] then
        local nCurrentTime = GameLib.GetGameTime()
        if nCurrentTime - self.nLastThornsTime > 15 then
            self.nLastThornsTime = nCurrentTime
            self.core:AddTimer("THORNS", self.L["label.next_thorns"], 30, self.config.timers.thorns)
        end
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.life_orb"] then
        self.core:RemoveLineBetween(nId)
    elseif sName == self.L["unit.tetris"] then
        self.core:RemoveLine(nId)
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF_LIFE_FORCE_SHACKLE == nSpellId then
        self.core:DrawIcon("NoHeal_"..tostring(nId), tData.tUnit, self.config.icons.life_force_shackle, true)
    elseif DEBUFF_SNAKE_SNACK == nSpellId then
        if tData.tUnit:IsThePlayer() then
            self.core:ShowAura("Aura_Snake", self.config.auras.snake_player, nDuration, self.L["alert.snake_player"])
            self.core:ShowAlert("Alert_Snake", self.L["alert.snake_player"], self.config.alerts.snake_player)
            self.core:PlaySound(self.config.sounds.snake_player)
        else
            self.core:ShowAlert("Alert_Snake", self.L["alert.snake"]:format(sUnitName), self.config.alerts.snake)
        end

        self.core:DrawIcon("Snake_"..tostring(nId), tData.tUnit, self.config.icons.snake, true, nil, nDuration)
    elseif DEBUFF_THORNS == nSpellId then
        self.core:DrawIcon("Thorns_"..tostring(nId), tData.tUnit, self.config.icons.thorns, true)
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if DEBUFF_LIFE_FORCE_SHACKLE == nSpellId then
        self.core:RemoveIcon("NoHeal_"..tostring(nId))
    elseif DEBUFF_SNAKE_SNACK == nSpellId then
        self.core:RemoveIcon("Snake_"..tostring(nId))
    elseif DEBUFF_THORNS == nSpellId then
        self.core:RemoveIcon("Thorns_"..tostring(nId))
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss_logic"] and sCastName == self.L["cast.defrag"] then
        self.core:PlaySound(self.config.sounds.defrag)
        self.core:ShowAlert("Alert_Defrag", self.L["alert.defrag"], self.config.alerts.defrag)
        self.core:AddTimer("DEFRAG", self.L["label.next_defrag"], 50, self.config.timers.defrag)
        self.core:DrawPolygon("DEFRAG", GameLib.GetPlayerUnit(), self.config.lines.defrag, 13, 0, 4, 10)
    end
end

function Mod:OnDatachron(sMessage, sSender, sHandler)
    if sMessage:match(self.L["datachron.enrage"]) then
        self.core:RemoveTimer("AVATUS")
        self.core:AddTimer("ENRAGE", self.L["label.enrage"], 34, self.config.timers.enrage)
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
    self.nLastThornsTime = 0

    self.core:AddTimer("DEFRAG", self.L["label.next_defrag"], 21, self.config.timers.defrag)
    self.core:AddTimer("THORNS", self.L["label.next_thorns"], 24, self.config.timers.defrag)
    self.core:AddTimer("AVATUS", self.L["label.avatus"], 480, self.config.timers.enrage)
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
