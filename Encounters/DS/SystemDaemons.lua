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
        -- Labels
        ["label.disconnect_north"] = "Disconnect North",
        ["label.disconnect_south"] = "Disconnect South",
        ["label.purge"] = "Purge",
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
        units = {
            north = {
                enable = true,
                label = "unit.boss_north",
            },
            south = {
                enable = true,
                label = "unit.boss_south",
            },
        },
        casts = {
            disconnect = {
                enable = true,
                color = "ff9932cc",
                label = "cast.disconnect"
            },
            powersurge = {
                enable = true,
                color = "ffff4500",
                label = "cast.power_surge",
            },
        },
        alerts = {
            disconnect = {
                enable = true,
                color = "ff9932cc",
                label = "cast.disconnect"
            },
            powersurge = {
                enable = true,
                color = "ffff4500",
                label = "cast.power_surge",
            },
            purge = {
                enable = true,
                label = "label.purge",
            },
        },
        sounds = {
            disconnect = {
                enable = true,
                file = "info",
                label = "cast.disconnect"
            },
            powersurge = {
                enable = true,
                file = "alert",
                label = "cast.power_surge",
            },
            purge = {
                enable = false,
                file = "beware",
                label = "label.purge",
            },
        },
        lines = {
            purge = {
                enable = true,
                color = "ffff4500",
                thickness = 7,
                label = "label.purge",
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

    if sName == self.L["unit.boss_north"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.north.enable,true,false,false,"N",self.config.units.north.color, self.config.units.north.priority)
    elseif sName == self.L["unit.boss_south"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.north.enable,true,false,false,"S",self.config.units.south.color, self.config.units.south.priority)
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sCastName == self.L["cast.disconnect"] then
        if self.config.casts.disconnect.enable == true then
            if sName == self.L["unit.boss_north"] then
                self.core:ShowCast(tCast,self.L["label.disconnect_north"],self.config.casts.disconnect.color)
            elseif sName == self.L["unit.boss_south"] then
                self.core:ShowCast(tCast,self.L["label.disconnect_south"],self.config.casts.disconnect.color)
            end
        end

        if self.config.alerts.disconnect.enable == true then
            if sName == self.L["unit.boss_north"] then
                self.core:ShowAlert("disconnect_"..tostring(nId), self.L["alert.disconnect_north"],self.config.alerts.disconnect.duration,self.config.alerts.disconnect.color)
            elseif sName == self.L["unit.boss_south"] then
                self.core:ShowAlert("disconnect_"..tostring(nId), self.L["alert.disconnect_south"],self.config.alerts.disconnect.duration,self.config.alerts.disconnect.color)
            end
        end

        if self.config.sounds.disconnect.enable == true then
            self.core:PlaySound(self.config.sounds.disconnect.file)
        end
    elseif sCastName == self.L["cast.power_surge"] then
        if self.core:GetDistance(tCast.tUnit) < 25 then
            if self.config.casts.powersurge.enable == true then
                self.core:ShowCast(tCast,sCastName,self.config.casts.powersurge.color)
            end

            if self.config.sounds.powersurge.enable == true then
                self.core:PlaySound(self.config.sounds.powersurge.file)
            end

            if self.config.alerts.powersurge.enable == true then
                self.core:ShowAlert("power_surge_"..tostring(nId), self.L["alert.interrupt"],self.config.alerts.powersurge.duration,self.config.alerts.powersurge.color)
            end
        end
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF__PURGE == nSpellId then
        if tData.tUnit:IsThePlayer() then
            if self.config.sounds.purge.enable == true then
                self.core:PlaySound(self.config.sounds.purge.file)
            end

            if self.config.alerts.purge.enable == true then
                self.core:ShowAlert("purge_"..tostring(nId), self.L["alert.purge_player"],self.config.alerts.purge.duration,self.config.alerts.purge.color)
            end
        end

        if self.config.lines.purge.enable == true then
            self.core:DrawPolygon("purge_"..tostring(nId), tData.tUnit, 6, 0, self.config.lines.purge.thickness, self.config.lines.purge.color, 20, nDuration)
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if DEBUFF__PURGE == nSpellId then
        self.core:RemovePolygon("purge_"..tostring(nId))
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
