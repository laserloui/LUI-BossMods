require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "SystemDaemons"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss_north"] = "Binary System Daemon",
        ["unit.boss_south"] = "Null System Daemon",
        -- Casts
        ["cast.disconnect"] = "Disconnect",
        ["cast.power_surge"] = "Power Surge",
        -- Alerts
        ["alert.disconnect_north"] = "Disconnect North!",
        ["alert.disconnect_south"] = "Disconnect South!",
        ["alert.purge_player"] = "Purge on you!",
        ["alert.interrupt"] = "Interrupt!",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

local DEBUFF__PURGE = 79399

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "System Daemons"
    self.tTrigger = {
        sType = "ANY",
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 105,
            },
        },
        tNames = {
            ["enUS"] = {"Binary System Daemon","Null System Daemon"},
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        purge = {
            enable = false,
            thickness = 7,
            alert = "Large",
            sound = "alert",
            color = "ffff4500",
        },
        disconnect = {
            enable = true,
            cast = true,
            alert = "Large",
            sound = "alarm",
            color = "ff9932cc",
        },
        powersurge = {
            enable = true,
            cast = true,
            alert = "Large",
            sound = "alert",
            color = "ffff4500",
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

    if sName == self.L["unit.boss_north"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,true,true,false,false,"N",self.config.northColor)
    elseif sName == self.L["unit.boss_south"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,true,true,false,false,"S",self.config.southColor)
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sCastName == self.L["cast.disconnect"] then
        if self.config.disconnect.enable == true then
            if sName == self.L["unit.boss_north"] then
                if self.config.disconnect.sound ~= "None" then
                    self.core:PlaySound(self.config.disconnect.sound)
                end

                if self.config.disconnect.cast == true then
                    self.core:ShowCast(tCast,(sCastName.." North"),self.config.disconnect.color)
                end

                if self.config.disconnect.alert ~= "None" then
                    self.core:ShowAlert(sName.."_disconnect", self.L["alert.disconnect_north"])
                end
            elseif sName == self.L["unit.boss_south"] then
                if self.config.disconnect.sound ~= "None" then
                    self.core:PlaySound(self.config.disconnect.sound)
                end

                if self.config.disconnect.cast == true then
                    self.core:ShowCast(tCast,(sCastName.." South"),self.config.disconnect.color)
                end

                if self.config.disconnect.alert ~= "None" then
                    self.core:ShowAlert(sName.."_disconnect", self.L["alert.disconnect_south"])
                end
            end
        end
    elseif sCastName == self.L["cast.power_surge"] then
        if self.config.powersurge.enable == true then
            if self.core:GetDistance(tCast.tUnit) < 25 then
                if self.config.powersurge.cast == true then
                    self.core:ShowCast(tCast,sCastName,self.config.powersurge.color)
                end

                if self.config.powersurge.sound ~= "None" then
                    self.core:PlaySound(self.config.powersurge.sound)
                end

                if self.config.powersurge.alert ~= "None" then
                    self.core:ShowAlert(sName.."_power_surge", self.L["alert.interrupt"])
                end
            end
        end
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF__PURGE == nSpellId then
        if self.config.purge.enable == true then
            if tData.tUnit:IsThePlayer() then
                if self.config.purge.sound ~= "None" then
                    self.core:PlaySound(self.config.purge.sound)
                end

                if self.config.purge.alert ~= "None" then
                    self.core:ShowAlert(tostring(nId).."_purge", self.L["alert.purge_player"])
                end
            end

            self.core:DrawPolygon(tostring(nId).."_purge", tData.tUnit, 6, 0, self.config.purge.thickness, self.config.purge.color, 20, nDuration)
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if DEBUFF__PURGE == nSpellId then
        if self.config.purge.enable == true then
            self.core:RemovePolygon(tostring(nId).."_purge")
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
