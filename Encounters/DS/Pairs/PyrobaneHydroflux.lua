require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "PyrobaneHydroflux"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss_fire"] = "Pyrobane",
        ["unit.boss_water"] = "Hydroflux",
        ["unit.flame_wave"] = "Flame Wave",
        ["unit.ice_tomb"] = "Ice Tomb",
        -- Alerts
        ["alert.bombs"] = "Bombs!",
        ["alert.ice_tomb"] = "Ice Tombs!",
        ["alert.stacks"] = "WATCH YOUR DEBUFF STACKS!",
        -- Labels
        ["label.bombs"] = "Bombs",
        ["label.bombs_player"] = "Bomb on player",
        ["label.fire_bomb"] = "Fire Bomb",
        ["label.water_bomb"] = "Water Bomb",
        ["label.stacks"] = "Debuff Stacks Warning",
        ["label.avatus"] = "Avatus incoming",
        ["label.enrage"] = "Enrage",
        -- Datachron
        ["datachron.enrage"] = "Time to die, sapients!",
        -- Texts
        ["text.next_bombs"] = "Next bombs",
        ["text.next_ice_tomb"] = "Next ice tomb",
        ["text.stacks"] = "/p I hit %d stacks and just failed the challenge!",
    },
    ["deDE"] = {
        -- Units
        ["unit.boss_fire"] = "Pyroman",
        ["unit.boss_water"] = "Hydroflux",
        ["unit.flame_wave"] = "Flammenwelle",
        ["unit.ice_tomb"] = "Eisgrab",
        -- Alerts
        ["alert.bombs"] = "Bomben!",
        ["alert.ice_tomb"] = "Eisgräber!",
        -- Labels
        ["label.bombs"] = "Bomben",
        ["label.bombs_player"] = "Bombe auf Spieler",
        ["label.fire_bomb"] = "Feuer Bombe",
        ["label.water_bomb"] = "Wasser Bombe",
        ["label.avatus"] = "Avatus incoming",
        ["label.enrage"] = "Enrage",
        -- Datachron
        ["datachron.enrage"] = "Zeit, zu sterben, Vernunftbegabte!",
        -- Texts
        ["text.next_bombs"] = "Nächste Bomben",
        ["text.next_ice_tomb"] = "Nächstes Eisgrab",
        ["text.stacks"] = "/gr Ich hab %d stacks und somit die Challenge vermasselt!",
    },
    ["frFR"] = {
        -- Units
        ["unit.boss_fire"] = "Pyromagnus",
        ["unit.boss_water"] = "Hydroflux",
        ["unit.flame_wave"] = "Vague de feu",
        ["unit.ice_tomb"] = "Tombeau de glace",
        -- Alerts
        ["alert.bombs"] = "Bombes !",
        ["alert.ice_tomb"] = "Tombeau de glace !",
        -- Labels
        ["label.bombs"] = "Bombes",
        ["label.bombs_player"] = "Bombe sur le joueur",
        ["label.fire_bomb"] = "Bombe de feu",
        ["label.water_bomb"] = "Bombe d'eau",
        ["label.avatus"] = "Avatus est arrivé",
        ["label.enrage"] = "Enrager",
        -- Datachron
        ["datachron.enrage"] = "Maintenant c'est l'heure de mourir, misérables !",
        -- Texts
        ["text.next_bombs"] = "Bombes suivantes",
        ["text.next_ice_tomb"] = "Tombeau de glace suivant",
        ["text.stacks"] = "/éq J'ai atteint %d stacks et j'ai perdu le défi !",
    },
}

local DEBUFF_FROST_BOMB = 75058
local DEBUFF_FIRE_BOMB = 75059
local DEBUFF_ICE_TOMB = 74326
local DEBUFF_DRENCHED = 52874
local DEBUFF_ENGULFED = 52876

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Pyrobane & Hydroflux"
    self.groupName = "Elemental Pairs"
    self.tTrigger = {
        sType = "ALL",
        tNames = {"unit.boss_fire", "unit.boss_water"},
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 118,
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
            boss_water = {
                enable = true,
                position = 2,
                label = "unit.boss_water",
            },
        },
        timers = {
            bombs = {
                enable = true,
                position = 1,
                color = "c8ff0000",
                label = "label.bombs",
            },
            ice_tomb = {
                enable = true,
                position = 2,
                color = "c800bfff",
                label = "unit.ice_tomb",
            },
            enrage = {
                enable = true,
                position = 3,
                label = "label.enrage",
            },
        },
        alerts = {
            bombs = {
                enable = true,
                position = 1,
                label = "label.bombs",
            },
            bombs_player = {
                enable = true,
                position = 2,
                label = "label.bombs_player",
            },
            ice_tomb = {
                enable = true,
                position = 3,
                label = "unit.ice_tomb",
            },
            stacks = {
                enable = true,
                position = 4,
                label = "label.stacks",
            },
        },
        sounds = {
            bombs = {
                enable = true,
                position = 1,
                file = "info",
                label = "label.bombs",
            },
            bombs_player = {
                enable = true,
                position = 2,
                file = "burn",
                label = "label.bombs_player",
            },
            ice_tomb = {
                enable = false,
                position = 3,
                file = "alert",
                label = "unit.ice_tomb",
            },
            stacks = {
                enable = true,
                position = 4,
                file = "alert",
                label = "label.stacks",
            },
        },
        auras = {
            fire_bomb = {
                enable = true,
                sprite = "LUIBM_meteor3",
                color = "ffff0000",
                label = "label.fire_bomb",
            },
            water_bomb = {
                enable = true,
                sprite = "LUIBM_waterdrop2",
                color = "ff00bfff",
                label = "label.water_bomb",
            },
        },
        icons = {
            fire_bomb = {
                enable = true,
                sprite = "LUIBM_circle_bg",
                color = "ffff0000",
                size = 50,
                label = "label.fire_bomb",
                overlay = {
                    sprite = "LUIBM_circle_full",
                    color = "ffff0000",
                    invert = true,
                },
            },
            water_bomb = {
                enable = true,
                sprite = "LUIBM_circle_bg",
                color = "ff00bfff",
                size = 50,
                label = "label.water_bomb",
                overlay = {
                    sprite = "LUIBM_circle_full",
                    color = "ff00bfff",
                    invert = true,
                },
            },
        },
        lines = {
            flame_wave = {
                enable = true,
                position = 1,
                thickness = 8,
                color = "ffff0000",
                label = "unit.flame_wave",
            },
            ice_tomb = {
                enable = true,
                position = 2,
                thickness = 6,
                color = "ff00bfff",
                label = "unit.ice_tomb",
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

    if sName == self.L["unit.boss_fire"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_fire)
    elseif sName == self.L["unit.boss_water"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_water)
    elseif sName == self.L["unit.flame_wave"] then
        self.core:DrawLine(nId, tUnit, self.config.lines.flame_wave, 25)
    elseif sName == self.L["unit.ice_tomb"] then
        if self.core:GetDistance(tUnit) < 45 then
            self.core:DrawLineBetween(nId, tUnit, nil, self.config.lines.ice_tomb)
        end
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.flame_wave"] then
        self.core:RemoveLine(nId)
    elseif sName == self.L["unit.ice_tomb"] then
        self.core:RemoveLineBetween(nId)
    end
end

function Mod:OnBombs()
    if not self.bPlayerHasBomb then
        self.core:PlaySound(self.config.sounds.bombs)
        self.core:ShowAlert("Alert_Bomb", self.L["alert.bombs"], self.config.alerts.bombs)
    end

    self.bPlayerHasBomb = nil
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if nSpellId == DEBUFF_FIRE_BOMB or nSpellId == DEBUFF_FROST_BOMB then
        local nCurrentTime = GameLib.GetGameTime()
        if nCurrentTime - self.nLastBombTime > 10 then
            self.nLastBombTime = nCurrentTime
            ApolloTimer.Create(1, false, "OnBombs", self)
            self.core:AddTimer("BOMBS", self.L["text.next_bombs"], 30, self.config.timers.bombs)
        end

        if tData.tUnit:IsThePlayer() then
            self.bPlayerHasBomb = true
            self.core:PlaySound(self.config.sounds.bombs_player)
            self.core:ShowAlert("Alert_Bomb", self.L["alert.bombs_player"], self.config.alerts.bombs_player)

            if nSpellId == DEBUFF_FIRE_BOMB then
                self.core:ShowAura("Aura_Bomb", self.config.auras.fire_bomb, nDuration, self.L["alert.bombs_player"])
            else
                self.core:ShowAura("Aura_Bomb", self.config.auras.water_bomb, nDuration, self.L["alert.bombs_player"])
            end
        end

        if nSpellId == DEBUFF_FIRE_BOMB then
            self.core:DrawIcon("Icon_Bomb"..tostring(nId), tData.tUnit, self.config.icons.fire_bomb, true, nil, nDuration)
        else
            self.core:DrawIcon("Icon_Bomb"..tostring(nId), tData.tUnit, self.config.icons.water_bomb, true, nil, nDuration)
        end
    elseif nSpellId == DEBUFF_ICE_TOMB then
        local nCurrentTime = GameLib.GetGameTime()
        if nCurrentTime - self.nLastIceTombTime > 5 then
            self.nLastIceTombTime = nCurrentTime
            self.core:PlaySound(self.config.sounds.ice_tomb)
            self.core:ShowAlert("Alert_Tomb", self.L["alert.ice_tomb"], self.config.alerts.ice_tomb)
            self.core:AddTimer("ICE_TOMB", self.L["text.next_ice_tomb"], 15, self.config.timers.ice_tomb)
        end
    end
end

function Mod:OnBuffUpdated(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF_DRENCHED == nSpellId or DEBUFF_ENGULFED == nSpellId then
        if tData.tUnit:IsThePlayer() then
            if nStack >= 10 and not self.warned then
                self.core:PlaySound(self.config.sounds.stacks)
                self.core:ShowAlert("Alert_Stacks", self.L["alert.stacks"], self.config.alerts.stacks)
                self.warned = true
            end

            if nStack > 13 then
                ChatSystemLib.Command(self.L["text.stacks"]:format(nStack))
            end
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if nSpellId == DEBUFF_FIRE_BOMB or nSpellId == DEBUFF_FROST_BOMB then
        if tData.tUnit:IsThePlayer() then
            self.core:HideAura("Aura_Bomb")
        end

        self.core:RemoveIcon("Icon_Bomb")
    elseif DEBUFF_DRENCHED == nSpellId or DEBUFF_ENGULFED == nSpellId then
        if tData.tUnit:IsThePlayer() then
            self.warned = nil
        end
    end
end

function Mod:OnDatachron(sMessage, sSender, sHandler)
    if sMessage:find(self.L["datachron.enrage"]) then
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
    self.warned = nil
    self.bPlayerHasBomb = nil
    self.nLastIceTombTime = 0
    self.nLastBombTime = 0

    self.core:AddTimer("BOMBS", self.L["text.next_bombs"], 30, self.config.timers.bombs)
    self.core:AddTimer("ICE_TOMB", self.L["text.next_ice_tomb"], 26, self.config.timers.ice_tomb)
    self.core:AddTimer("AVATUS", self.L["label.avatus"], 380, self.config.timers.enrage)
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
