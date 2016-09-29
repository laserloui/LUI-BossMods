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
        ["message.next_belch"] = "Next lasers",
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
    ["frFR"] = {},
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
        tNames = {
            ["enUS"] = {"Robomination"},
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
                priority = 1,
            },
            flailing_arm = {
                enable = true,
                label = "unit.flailing_arm",
                color = "ade91dfb",
                priority = 2,
            },
            cannon_arm = {
                enable = true,
                label = "unit.cannon_arm",
                color = "ade91dfb",
                priority = 3,
            },
        },
        timers = {
            arms = {
                enable = true,
                color = "afb0ff2f",
                label = "label.arms",
            },
            crush = {
                enable = true,
                color = "afe91dfb",
                label = "label.crush",
            },
            noxious_belch = {
                enable = true,
                color = "ad1dfbfb",
                label = "cast.noxious_belch",
            },
            incineration = {
                enable = true,
                color = "afff4500",
                label = "cast.incineration_laser",
            },
        },
        auras = {
            crush_player = {
                enable = true,
                sprite = "run",
                color = "ffff00ff",
                label = "label.crush_player",
            },
        },
        casts = {
            noxious_belch = {
                enable = true,
                color = "afb0ff2f",
                label = "cast.noxious_belch",
            },
            cannon_fire = {
                enable = false,
                color = "ade91dfb",
                label = "cast.cannon_fire",
            },
        },
        alerts = {
            midphase = {
                enable = true,
                label = "alert.midphase",
            },
            lasers = {
                enable = true,
                label = "alert.lasers",
            },
            crush_player = {
                enable = true,
                label = "label.crush_player",
            },
            crush = {
                enable = true,
                label = "label.crush",
            },
            incineration = {
                enable = true,
                label = "cast.incineration_laser",
            },
        },
        sounds = {
            cannon_fire = {
                enable = false,
                file = "info",
                label = "cast.cannon_fire",
            },
            crush_player = {
                enable = true,
                file = "run-away",
                label = "label.crush_player",
            },
            crush = {
                enable = true,
                file = "info",
                label = "label.crush",
            },
            incineration = {
                enable = true,
                file = "run-away",
                label = "cast.incineration_laser",
            },
        },
        icons = {
            crush = {
                enable = true,
                sprite = "meteor",
                size = 80,
                color = "ffff4500",
                label = "label.crush",
            },
            incineration = {
                enable = true,
                sprite = "target",
                size = 80,
                color = "ffff4500",
                label = "cast.incineration_laser",
            },
        },
        lines = {
            cannon_arm = {
                enable = true,
                thickness = 8,
                color = "afff4500",
                label = "unit.cannon_arm",
            },
            flailing_arm = {
                enable = true,
                thickness = 8,
                color = "af0084ff",
                label = "unit.flailing_arm",
            },
            scanning_eye = {
                enable = true,
                thickness = 8,
                color = "af7fff00",
                label = "unit.scanning_eye",
            },
            incineration = {
                enable = true,
                thickness = 12,
                color = "ffff4500",
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
    if sName == self.L["unit.boss"] and bInCombat == true then
        self.boss = tUnit
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss.enable,true,false,false,nil,self.config.units.boss.color, self.config.units.boss.priority)
    elseif sName == self.L["unit.cannon_arm"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.cannon_arm.enable,true,false,false,nil,self.config.units.cannon_arm.color, self.config.units.cannon_arm.priority)

        if not self.bIsMidPhase and self.config.timers.arms.enable == true then
            self.core:AddTimer("Timer_Arms", self.L["message.next_arms"], 45, self.config.timers.arms.color)
        end

        if self.config.lines.cannon_arm.enable == true then
            self.core:DrawLineBetween(nId, tUnit, nil, self.config.lines.cannon_arm.color, self.config.lines.cannon_arm.thickness)
        end
    elseif sName == self.L["unit.flailing_arm"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.flailing_arm.enable,true,false,false,nil,self.config.units.flailing_arm.color, self.config.units.flailing_arm.priority)

        if self.config.lines.flailing_arm.enable == true then
            self.core:DrawLineBetween(nId, tUnit, nil, self.config.lines.flailing_arm.color, self.config.lines.flailing_arm.thickness)
        end
    elseif sName == self.L["unit.scanning_eye"] then
        if self.config.lines.scanning_eye.enable == true then
            self.core:DrawLineBetween(nId, tUnit, nil, self.config.lines.scanning_eye.color, self.config.lines.scanning_eye.thickness)
        end
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
    if self.config.alerts.midphase.enable == true then
        if sName == self.L["unit.boss"] then
            if nHealthPercent <= 77 and self.nMidphaseWarnings == 0 then
                self.core:ShowAlert("Midphase",self.L["alert.midphase"],self.config.alerts.midphase.duration, self.config.alerts.midphase.color)
                self.nMidphaseWarnings = 1
            elseif nHealthPercent <= 52 and self.nMidphaseWarnings == 1 then
                self.core:ShowAlert("Midphase",self.L["alert.midphase"],self.config.alerts.midphase.duration, self.config.alerts.midphase.color)
                self.nMidphaseWarnings = 2
            end
        end
    end
 end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if self.L["unit.boss"] == sName and self.L["cast.noxious_belch"] == sCastName then
        if self.config.casts.noxious_belch.enable == true then
            self.core:ShowCast(tCast,sCastName,self.config.casts.noxious_belch.color)
        end

        if self.config.timers.noxious_belch.enable == true then
            self.core:AddTimer("Timer_Belch", self.L["message.next_belch"], 31, self.config.timers.noxious_belch.color)
        end

        if self.config.alerts.lasers.enable == true then
            self.core:ShowAlert(sCastName,self.L["alert.lasers"],self.config.alerts.lasers.duration, self.config.alerts.lasers.color)
        end
    elseif self.L["unit.cannon_arm"] == sName and self.L["cast.cannon_fire"] == sCastName then
        if self.config.casts.cannon_fire.enable == true then
            self.core:ShowCast(tCast,sCastName,self.config.casts.cannon_fire.color)
        end

        if self.config.sounds.cannon_fire.enable == true then
            self.core:PlaySound(self.config.sounds.cannon_fire.file)
        end
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF_THE_SKY_IS_FALLING == nSpellId then
        if self.config.timers.crush.enable == true then
            self.core:AddTimer("Timer_Crush", self.L["message.next_crush"], 17, self.config.timers.crush.color)
        end

        if tData.tUnit:IsThePlayer() then
            if self.config.auras.crush_player.enable == true then
                self.core:ShowAura("Aura_Crush",self.config.auras.crush_player.sprite,self.config.auras.crush_player.color,nDuration)
            end

            if self.config.alerts.crush_player.enable == true then
                self.core:ShowAlert("Alert_Crush", self.L["alert.crush_player"],self.config.alerts.crush_player.duration, self.config.alerts.crush_player.color)
            end

            if self.config.sounds.crush_player.enable == true then
                self.core:PlaySound(self.config.sounds.crush_player.file)
            end
        else
            if self.config.sounds.crush.enable == true then
                self.core:PlaySound(self.config.sounds.crush.file)
            end

            if self.config.alerts.crush.enable == true then
                self.core:ShowAlert("Alert_Crush", self.L["alert.crush"]:format(sUnitName),self.config.alerts.crush.duration, self.config.alerts.crush.color)
            end

            if self.config.icons.crush.enable == true then
                self.core:DrawIcon("Icon_Crush", tData.tUnit, self.config.icons.crush.sprite, self.config.icons.crush.size, nil, self.config.icons.crush.color, nDuration)
            end
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if DEBUFF_THE_SKY_IS_FALLING == nSpellId then
        self.core:HideAura("Aura_Crush")
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

        if self.config.timers.arms.enable == true then
            self.core:AddTimer("Timer_Arms", self.L["message.next_arms"], 45, self.config.timers.arms.color)
        end

        if self.config.timers.crush.enable == true then
            self.core:AddTimer("Timer_Crush", self.L["message.next_crush"], 8, self.config.timers.crush.color)
        end

        if self.config.timers.noxious_belch.enable == true then
            self.core:AddTimer("Timer_Belch", self.L["message.next_belch"], 14, self.config.timers.noxious_belch.color)
        end

        if self.config.timers.incineration.enable == true then
            self.core:AddTimer("Timer_Incineration", self.L["message.next_incineration"], 20, self.config.timers.incineration.color)
        end
    else
        local strPlayerLaserFocused = sMessage:match(self.L["datachron.incineration"])
        if strPlayerLaserFocused then
            local tFocusedUnit = GameLib.GetPlayerUnitByName(strPlayerLaserFocused)

            if tFocusedUnit:IsThePlayer() then
                if self.config.alerts.incineration.enable == true then
                    self.core:ShowAlert("Incineration", self.L["alert.incineration_player"],self.config.alerts.incineration.duration, self.config.alerts.incineration.color)
                end

                if self.config.sounds.incineration.enable == true then
                    self.core:PlaySound(self.config.sounds.incineration.file)
                end
            else
                if self.config.alerts.incineration.enable == true then
                    self.core:ShowAlert("Incineration", self.L["alert.incineration"]:format(tFocusedUnit:GetName()),self.config.alerts.incineration.duration, self.config.alerts.incineration.color)
                end
            end

            if self.config.timers.incineration.enable == true then
                self.core:AddTimer("Timer_Incineration", self.L["message.next_incineration"], 40, self.config.timers.incineration.color)
            end

            if self.config.icons.incineration.enable == true then
                self.core:DrawIcon("Icon_Incineration", tFocusedUnit, self.config.icons.incineration.sprite, self.config.icons.incineration.size, nil, self.config.icons.incineration.color, 10)
            end

            if self.boss and self.config.lines.incineration.enable == true then
                self.core:DrawLineBetween("Line_Incineration", tFocusedUnit, self.boss, self.config.lines.incineration.color, self.config.lines.incineration.thickness, 10)
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

    if self.config.timers.arms.enable == true then
        self.core:AddTimer("Timer_Arms", self.L["message.next_arms"], 45, self.config.timers.arms.color)
    end

    if self.config.timers.crush.enable == true then
        self.core:AddTimer("Timer_Crush", self.L["message.next_crush"], 8, self.config.timers.crush.color)
    end

    if self.config.timers.noxious_belch.enable == true then
        self.core:AddTimer("Timer_Belch", self.L["message.next_belch"], 16, self.config.timers.noxious_belch.color)
    end
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
