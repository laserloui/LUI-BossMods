require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "MnemesisMegalith"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss_logic"] = "Mnemesis",
        ["unit.boss_earth"] = "Megalith",
        ["unit.pillar"] = "Crystalline Matrix",
        -- Casts
        ["cast.defrag"] = "Defragment",
        -- Alerts
        ["alert.mario"] = "JUMP INTO CUBES!",
        ["alert.superquake"] = "JUMP, JUMP, JUMP!!!",
        ["alert.defrag"] = "DEFRAGMENT - SPREAD!",
        ["alert.snake"] = "SNAKE ON %s!",
        ["alert.snake_player"] = "SNAKE ON YOU!",
        -- Datachron
        ["datachron.superquake"] = "The ground shudders beneath Megalith!",
        ["datachron.mario"] = "Logic creates powerful data caches",
        ["datachron.enrage"] = "Time to die, sapients!",
        -- Labels
        ["label.superquake"] = "Superquake",
        ["label.next_mario"] = "Next Mario Phase",
        ["label.next_defrag"] = "Next Defragment",
        ["label.avatus"] = "Avatus incoming",
        ["label.enrage"] = "Enrage",
        ["label.snake"] = "Snake",
        ["label.snake_player"] = "Snake on player",
    },
    ["deDE"] = {
        -- Units
        ["unit.boss_logic"] = "Mnemesis",
        ["unit.boss_earth"] = "Megalith",
        ["unit.pillar"] = "Kristallmatrix",
        -- Casts
        ["cast.defrag"] = "Defragmentieren",
        -- Alerts
        ["alert.mario"] = "SPRING IN WÜRFEL!",
        ["alert.superquake"] = "SPRING, SPRING, SPRING!!!",
        ["alert.defrag"] = "DEFRAGMENTIEREN - VERTEILEN!",
        ["alert.snake"] = "SCHLANGE AUF %s!",
        ["alert.snake_player"] = "SCHLANGE AUF DIR!",
        -- Datachron
        ["datachron.superquake"] = "Der Boden unter Megalith bebt!",
        ["datachron.mario"] = "Logik erschafft mächtige Datenspeicher!",
        ["datachron.enrage"] = "Zeit, zu sterben, Vernunftbegabte!",
        -- Labels
        ["label.superquake"] = "Superbeben",
        ["label.next_mario"] = "Nächste Mario Phase",
        ["label.next_defrag"] = "Nächste Defragmentierung",
        ["label.avatus"] = "Avatus incoming",
        ["label.enrage"] = "Enrage",
        ["label.snake"] = "Schlange",
        ["label.snake_player"] = "Schlange auf Spieler",
    },
    ["frFR"] = {
        -- Units
        ["unit.boss_logic"] = "Mnémésis",
        ["unit.boss_earth"] = "Mégalithe",
        ["unit.pillar"] = "Matrice cristalline",
        -- Casts
        ["cast.defrag"] = "Défragmentation",
        -- Alerts
        ["alert.mario"] = "SAUTE SUR DES CUBES !",
        ["alert.superquake"] = "SAUTE, SAUTE, SAUTE !!!",
        ["alert.defrag"] = "DÉFRAGMENTATION - SÉPARER-VOUS !",
        ["alert.snake"] = "SERPENT SUR %s !",
        ["alert.snake_player"] = "SERPENT SUR VOUS !",
        -- Datachron
        ["datachron.superquake"] = "Le sol tremble sous les pieds de Mégalithe !",
        ["datachron.mario"] = "La logique crée de puissantes caches de données !",
        ["datachron.enrage"] = "Maintenant c'est l'heure de mourir, misérables !",
        -- Labels
        ["label.superquake"] = "Super séisme",
        ["label.next_mario"] = "Prochaine phase de Mario",
        ["label.next_defrag"] = "Défragmentation suivante",
        ["label.avatus"] = "Avatus est arrivé",
        ["label.enrage"] = "Enrager",
        ["label.snake"] = "Serpent",
        ["label.snake_player"] = "Serpent sur le joueur",
    },
}

local DEBUFF_SNAKE_SNACK = 74570

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
                position = 1,
                label = "unit.boss_logic",
            },
            boss_earth = {
                enable = true,
                position = 2,
                label = "unit.boss_earth",
            },
            pillar = {
                enable = true,
                position = 3,
                label = "unit.pillar",
            },
        },
        timers = {
            defrag = {
                enable = true,
                position = 1,
                color = "c800bfff",
                label = "label.next_defrag",
            },
            mario = {
                enable = true,
                position = 2,
                color = "c8ffa500",
                label = "label.next_mario",
            },
            enrage = {
                enable = true,
                position = 3,
                label = "label.enrage",
            },
        },
        alerts = {
            defrag = {
                enable = true,
                position = 1,
                label = "cast.defrag",
            },
            superquake = {
                enable = true,
                position = 2,
                label = "label.superquake",
            },
            snake = {
                enable = true,
                position = 3,
                label = "label.snake",
            },
            snake_player = {
                enable = true,
                position = 4,
                label = "label.snake_player",
            },
            mario = {
                enable = true,
                position = 5,
                label = "label.next_mario",
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
        casts = {
            superquake = {
                enable = true,
                label = "label.superquake",
            },
        },
        sounds = {
            defrag = {
                enable = true,
                position = 1,
                file = "info",
                label = "cast.defrag",
            },
            superquake = {
                enable = true,
                position = 2,
                file = "alert",
                label = "label.superquake",
            },
            snake_player = {
                enable = true,
                position = 3,
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
        },
        lines = {
            defrag = {
                enable = true,
                position = 1,
                thickness = 6,
                color = "ffff0000",
                label = "cast.defrag",
            },
            antlion = {
                enable = true,
                thickness = 6,
                color = "ffadff2f",
                label = "unit.pillar",
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

    if sName == self.L["unit.boss_logic"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_logic)
    elseif sName == self.L["unit.boss_earth"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_earth)
    elseif sName == self.L["unit.pillar"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.pillar)
        self.core:DrawLineBetween("Pillar"..tostring(nId), tUnit, nil, self.config.lines.pillar)
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF_SNAKE_SNACK == nSpellId then
        if tData.tUnit:IsThePlayer() then
            self.core:ShowAura("Aura_Snake", self.config.auras.snake_player, nDuration, self.L["alert.snake_player"])
            self.core:ShowAlert("Alert_Snake", self.L["alert.snake_player"], self.config.alerts.snake_player)
            self.core:PlaySound(self.config.sounds.snake_player)
        else
            self.core:ShowAlert("Alert_Snake", self.L["alert.snake"]:format(sUnitName), self.config.alerts.snake)
        end

        self.core:DrawIcon("Snake_"..tostring(nId), tData.tUnit, self.config.icons.snake, true, nil, nDuration)
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if DEBUFF_SNAKE_SNACK == nSpellId then
        self.core:RemoveIcon("Snake_"..tostring(nId))
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss_logic"] and sCastName == self.L["cast.defrag"] then
        self.core:PlaySound(self.config.sounds.defrag)
        self.core:ShowAlert("Alert_Defrag", self.L["alert.defrag"], self.config.alerts.defrag)
        self.core:AddTimer("DEFRAG", self.L["label.next_defrag"], 40, self.config.timers.defrag)
        self.core:DrawPolygon("DEFRAG", GameLib.GetPlayerUnit(), self.config.lines.defrag, 13, 0, 4, 10)
    end
end

function Mod:OnDatachron(sMessage, sSender, sHandler)
    if sMessage:find(self.L["datachron.superquake"]) then
        self.core:ShowCast({
            sName = "Superquake",
            nDuration = 2,
            nElapsed = 0,
            nTick = Apollo.GetTickCount()
        }, self.L["label.superquake"], self.config.casts.superquake)
        self.core:ShowAlert("Superquake", self.L["alert.jump"], self.config.alerts.superquake)
        self.core:PlaySound(self.config.sounds.superquake)
    elseif sMessage:find(self.L["datachron.mario"]) then
        self.core:AddTimer("MARIO", self.L["label.next_mario"], 60, self.config.timers.mario)
        self.core:ShowAlert("Mario", self.L["alert.mario"], self.config.alerts.mario)
    elseif sMessage:match(self.L["datachron.enrage"]) then
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

    self.core:AddTimer("DEFRAG", self.L["label.next_defrag"], 10, self.config.timers.defrag)
    self.core:AddTimer("MARIO", self.L["label.next_mario"], 60, self.config.timers.mario)
    self.core:AddTimer("AVATUS", self.L["label.avatus"], 310, self.config.timers.enrage)
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
