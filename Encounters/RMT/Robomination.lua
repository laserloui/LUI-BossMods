require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Robomination"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss"] = "Robomination",
        ["unit.cannon_arm"] = "Cannon Arm",
        ["unit.flailing_arm"] = "Flailing Arm",
        ["unit.scanning_eye"] = "Scanning Eye",
        -- Casts
        ["cast.noxious_belch"] = "Noxious Belch",
        ["cast.incineration_laser"] = "Incineration Laser",
        ["cast.cannon_fire"] = "Cannon Fire",
        -- Alerts
        ["alert.interrupt"] = "Interrupt!",
        ["alert.lasers"] = "Lasers incoming!",
        ["alert.midphase"] = "Midphase soon!",
        ["alert.crush"] = "CRUSH ON %s!",
        ["alert.crush_player"] = "CRUSH ON YOU!",
        ["alert.incineration"] = "INCINERATION ON %s!",
        ["alert.incineration_player"] = "INCINERATION ON YOU!",
        -- Messages
        ["message.next_arms"] = "Next arms",
        ["message.next_crush"] = "Next crush",
        ["message.next_belch"] = "Next belch",
        ["message.next_incineration"] = "Next incineration",
        -- Datachron messages
        ["datachron.midphase_start"] = "The Robomination sinks",
        ["datachron.midphase_end"] = "The Robomination erupts back into the fight!",
        ["datachron.incineration"] = "The Robomination tries to incinerate (.*)",
        -- Labels
        ["label.arms"] = "Arms",
        ["label.crush"] = "Crush",
        ["label.crush_player"] = "Crush on player",
    },
    ["deDE"] = {},
    ["frFR"] = {
        -- Units
        ["unit.boss"] = "Robominator",
        ["unit.cannon_arm"] = "Bras Cannon",
        ["unit.flailing_arm"] = "Bras Fléau",
        ["unit.scanning_eye"] = "Oeil Scanneur",
        -- Casts
        ["cast.noxious_belch"] = "Rot Nocif",
        ["cast.incineration_laser"] = "Incinération Laser",
        ["cast.cannon_fire"] = "Tir de Canon",
        -- Alerts
        ["alert.interrupt"] = "Interromps !",
        ["alert.lasers"] = "Lasers en approche !",
        ["alert.midphase"] = "Midphase bientôt !",
        ["alert.crush"] = "ÉCRASER SUR %s !",
        ["alert.crush_player"] = "ÉCRASER SUR TOI !",
        ["alert.incineration"] = "INCINÉRATION SUR %s !",
        ["alert.incineration_player"] = "INCINÉRATION SUR TOI !",
        -- Messages
        ["message.next_arms"] = "Bras suivants",
        ["message.next_crush"] = "Écraser suivant",
        ["message.next_belch"] = "Lasers suivants",
        ["message.next_incineration"] = "Incineration suivante",
        -- Datachron messages
        ["datachron.midphase_start"] = "Robomination s'enfonce",
        ["datachron.midphase_end"] = "Robomination revient dans la bataille !",
        ["datachron.incineration"] = "Robomination tente d'incinérer (.*)",
        -- Labels
        ["label.arms"] = "Bras",
        ["label.crush"] = "Écraser",
        ["label.crush_player"] = "Écraser sur le joueur",
    },
}

local DEBUFF_THE_SKY_IS_FALLING = 75126 -- Crush target

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"
    self.displayName = "Robomination"
    self.tTrigger = {
        sType = "ANY",
        tNames = {"unit.boss"},
        tZones = {
            [1] = {
                continentId = 104,
                parentZoneId = 548,
                mapId = 551,
            },
            [2] = {
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
                color = "afb0ff2f",
                position = 1,
            },
            flailing_arm = {
                enable = true,
                label = "unit.flailing_arm",
                position = 2,
            },
            cannon_arm = {
                enable = true,
                label = "unit.cannon_arm",
                position = 3,
            },
        },
        timers = {
            arms = {
                enable = true,
                position = 1,
                color = "c800ffff",
                label = "label.arms",
            },
            crush = {
                enable = true,
                position = 2,
                color = "c8ffd700",
                label = "label.crush",
            },
            noxious_belch = {
                enable = true,
                position = 3,
                color = "c87cfc00",
                label = "cast.noxious_belch",
            },
            incineration = {
                enable = true,
                position = 4,
                color = "c8ff0000",
                label = "cast.incineration_laser",
            },
        },
        auras = {
            crush_player = {
                enable = true,
                sprite = "LUIBM_run",
                color = "ffff0000",
                label = "label.crush_player",
            },
            incineration = {
                enable = true,
                sprite = "LUIBM_ifrit",
                color = "ffff0000",
                label = "cast.incineration_laser",
            },
        },
        casts = {
            noxious_belch = {
                enable = true,
                label = "cast.noxious_belch",
            },
            cannon_fire = {
                enable = false,
                label = "cast.cannon_fire",
            },
        },
        alerts = {
            crush = {
                enable = true,
                position = 1,
                label = "label.crush",
            },
            crush_player = {
                enable = true,
                position = 2,
                label = "label.crush_player",
            },
            lasers = {
                enable = true,
                position = 3,
                label = "alert.lasers",
            },
            incineration = {
                enable = true,
                position = 4,
                label = "cast.incineration_laser",
            },
            midphase = {
                enable = true,
                position = 5,
                label = "alert.midphase",
            },
        },
        sounds = {
            crush = {
                enable = true,
                position = 1,
                file = "info",
                label = "label.crush",
            },
            crush_player = {
                enable = true,
                position = 2,
                file = "run-away",
                label = "label.crush_player",
            },
            incineration = {
                enable = true,
                position = 3,
                file = "run-away",
                label = "cast.incineration_laser",
            },
            cannon_fire = {
                enable = false,
                position = 4,
                file = "info",
                label = "cast.cannon_fire",
            },
        },
        icons = {
            crush = {
                enable = true,
                sprite = "LUIBM_meteor",
                size = 80,
                color = "ffff0000",
                label = "label.crush",
            },
            incineration = {
                enable = true,
                sprite = "LUIBM_fire",
                size = 80,
                color = "ffff0000",
                label = "cast.incineration_laser",
            },
        },
        lines = {
            cannon_arm = {
                enable = true,
                position = 1,
                thickness = 8,
                color = "afff0000",
                label = "unit.cannon_arm",
            },
            flailing_arm = {
                enable = true,
                position = 2,
                thickness = 8,
                color = "af0084ff",
                label = "unit.flailing_arm",
            },
            scanning_eye = {
                enable = true,
                position = 3,
                thickness = 8,
                color = "af7fff00",
                label = "unit.scanning_eye",
            },
            incineration = {
                enable = true,
                position = 4,
                thickness = 12,
                color = "ffff0000",
                label = "cast.incineration_laser",
            },
        }
    }
    return o
end

function Mod:Init(parent)
    Apollo.LinkAddon(parent, self)

    self.core = parent
    self.L = parent:GetLocale(Encounter,Locales)
end

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if sName == self.L["unit.boss"] and bInCombat then
        self.boss = tUnit
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss)
    elseif sName == self.L["unit.cannon_arm"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.cannon_arm)
        self.core:DrawLineBetween(nId, tUnit, nil, self.config.lines.cannon_arm)

        if not self.bIsMidPhase then
            self.core:AddTimer("Timer_Arms", self.L["message.next_arms"], 45, self.config.timers.arms)
        end
    elseif sName == self.L["unit.flailing_arm"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.flailing_arm)
        self.core:DrawLineBetween(nId, tUnit, nil, self.config.lines.flailing_arm)
    elseif sName == self.L["unit.scanning_eye"] then
        self.core:DrawLineBetween(nId, tUnit, nil, self.config.lines.scanning_eye)
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.scanning_eye"] then
        self.core:RemoveLineBetween(nId)
    elseif sName == self.L["unit.cannon_arm"] then
        self.core:RemoveLineBetween(nId)
    elseif sName == self.L["unit.flailing_arm"] then
        self.core:RemoveLineBetween(nId)
    end
end

function Mod:OnHealthChanged(nId, nHealthPercent, sName, tUnit)
    if sName == self.L["unit.boss"] then
        if nHealthPercent <= 77 and self.nMidphaseWarnings == 0 then
            self.core:ShowAlert("Alert_Midphase", self.L["alert.midphase"], self.config.alerts.midphase)
            self.nMidphaseWarnings = 1
        elseif nHealthPercent <= 52 and self.nMidphaseWarnings == 1 then
            self.core:ShowAlert("Alert_Midphase", self.L["alert.midphase"], self.config.alerts.midphase)
            self.nMidphaseWarnings = 2
        end
    end
 end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if self.L["unit.boss"] == sName and self.L["cast.noxious_belch"] == sCastName then
        self.core:ShowCast(tCast, sCastName, self.config.casts.noxious_belch)
        self.core:AddTimer("Timer_Belch", self.L["message.next_belch"], 31, self.config.timers.noxious_belch)
        self.core:ShowAlert(sCastName, self.L["alert.lasers"], self.config.alerts.lasers)
    elseif self.L["unit.cannon_arm"] == sName and self.L["cast.cannon_fire"] == sCastName then
        self.core:ShowCast(tCast, sCastName, self.config.casts.cannon_fire)
        self.core:PlaySound(self.config.sounds.cannon_fire)
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF_THE_SKY_IS_FALLING == nSpellId then
        self.core:AddTimer("Timer_Crush", self.L["message.next_crush"], 17, self.config.timers.crush)

        if tData.tUnit:IsThePlayer() then
            self.core:ShowAura("Aura_Crush", self.config.auras.crush_player, nDuration, self.L["alert.crush_player"])
            self.core:ShowAlert("Alert_Crush", self.L["alert.crush_player"], self.config.alerts.crush_player)
            self.core:PlaySound(self.config.sounds.crush_player)
        else
            self.core:ShowAlert("Alert_Crush", self.L["alert.crush"]:format(sUnitName), self.config.alerts.crush)
            self.core:PlaySound(self.config.sounds.crush)
        end

        self.core:DrawIcon("Icon_Crush", tData.tUnit, self.config.icons.crush, true, nil, nDuration)
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if DEBUFF_THE_SKY_IS_FALLING == nSpellId then
        if tData.tUnit:IsThePlayer() then
            self.core:HideAura("Aura_Crush")
        end

        self.core:RemoveIcon("Icon_Crush")
    end
end

function Mod:OnDatachron(sMessage, sSender, sHandler)
    if sMessage:match(self.L["datachron.midphase_start"]) then
        self.core:RemoveTimer("Timer_Belch")
        self.core:RemoveTimer("Timer_Arms")
        self.core:RemoveTimer("Timer_Crush")
        self.core:RemoveTimer("Timer_Incineration")
        self.core:RemoveIcon("Icon_Crush")
        self.core:HideAura("Aura_Crush")
        self.bIsMidPhase = true
    elseif sMessage:match(self.L["datachron.midphase_end"]) then
        self.bIsMidPhase = nil
        self.core:AddTimer("Timer_Arms", self.L["message.next_arms"], 45, self.config.timers.arms)
        self.core:AddTimer("Timer_Crush", self.L["message.next_crush"], 8, self.config.timers.crush)
        self.core:AddTimer("Timer_Belch", self.L["message.next_belch"], 14, self.config.timers.noxious_belch)
        self.core:AddTimer("Timer_Incineration", self.L["message.next_incineration"], 20, self.config.timers.incineration)
    else
        local strPlayerLaserFocused = sMessage:match(self.L["datachron.incineration"])

        if strPlayerLaserFocused then
            local tFocusedUnit = GameLib.GetPlayerUnitByName(strPlayerLaserFocused)

            if tFocusedUnit then
                if tFocusedUnit:IsThePlayer() then
                    self.core:PlaySound(self.config.sounds.incineration)
                    self.core:ShowAura("Aura_Incineration", self.config.auras.incineration, 12, self.L["alert.incineration_player"])
                    self.core:ShowAlert("Alert_Incineration", self.L["alert.incineration_player"], self.config.alerts.incineration)
                else
                    self.core:ShowAlert("Alert_Incineration", self.L["alert.incineration"]:format(tFocusedUnit:GetName()), self.config.alerts.incineration)
                end

                self.core:DrawIcon("Icon_Incineration", tFocusedUnit, self.config.icons.incineration, true, nil, 12)
                self.core:AddTimer("Timer_Incineration", self.L["message.next_incineration"], 40, self.config.timers.incineration)
                self.core:DrawLineBetween("Line_Incineration", tFocusedUnit, self.boss, self.config.lines.incineration, 12)
            end
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
    self.boss = nil
    self.bIsMidPhase = nil
    self.nMidphaseWarnings = 0

    self.core:AddTimer("Timer_Arms", self.L["message.next_arms"], 45, self.config.timers.arms)
    self.core:AddTimer("Timer_Crush", self.L["message.next_crush"], 8, self.config.timers.crush)
    self.core:AddTimer("Timer_Belch", self.L["message.next_belch"], 16, self.config.timers.noxious_belch)
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
