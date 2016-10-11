require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "PyrobaneHydroflux"

local Locales = {
    ["enUS"] = {
        -- Unit names
        ["unit.boss_fire"] = "Pyrobane",
        ["unit.boss_water"] = "Hydroflux",
        ["unit.ice_tomb"] = "Ice Tomb",
        ["unit.flame_wave"] = "Flame Wave",
        -- Texts
        ["text.next_bombs"] = "Next bombs",
        ["text.next_ice_tomb"] = "Next ice tomb",
        -- Labels
        ["label.bombs"] = "Bombs",
        ["label.ice_tomb"] = "Ice Tomb",
        ["label.flame_waves"] = "Flame Waves",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

local nLastBombTime = 0
local nLastIceTombTime = 0
local DEBUFF_FROSTBOMB = 75058
local DEBUFF_FIREBOMB = 75059
local DEBUFF_ICE_TOMB = 74326

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Pyrobane & Hydroflux"
    self.groupName = "Elemental Pairs"
    self.tTrigger = {
        sType = "ANY",
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 118,
            },
        },
        tNames = {
            ["enUS"] = {"Pyrobane","Hydroflux"},
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        units = {
            boss_fire = {
                enable = true,
                label = "unit.boss_fire",
                color = "afff2f2f",
            },
            boss_water = {
                enable = true,
                label = "unit.boss_water",
                color = "af1e90ff",
            },
        },
        alerts = {
            bombs = {
                enable = true,
                duration = 3,
                label = "label.bombs",
            },
            ice_tomb = {
                enable = true,
                duration = 3,
                label = "label.ice_tomb",
            },
        },
        sounds = {
            bombs = {
                enable = true,
                file = "info",
                label = "label.bombs",
            },
            ice_tomb = {
                enable = true,
                file = "alert",
                label = "label.ice_tomb",
            },
        },
        timers = {
            bombs = {
                enable = true,
                color = "ade91dfb",
                text = "text.next_bombs",
                label = "label.bombs",
            },
            ice_tomb = {
                enable = true,
                color = "ade91dfb",
                text = "text.next_ice_tomb",
                label = "label.ice_tomb",
            },
        },
        lines = {
            flame_wave = {
                enable = true,
                thickness = 10,
                color = "ffff0000",
                label = "label.flame_waves",
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
        self.core:DrawLine(nId, tUnit, self.config.lines.flame_wave, 20)
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.flame_wave"] then
        self.core:RemoveLine(nId)
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if nSpellId == DEBUFF_FIREBOMB or nSpellId == DEBUFF_FROSTBOMB then
        local nCurrentTime = GameLib.GetGameTime()
        if nCurrentTime - nLastBombTime > 10 then
            nLastBombTime = nCurrentTime
            self:AddTimer("bombs",30)
        end
    elseif nSpellId == DEBUFF_ICE_TOMB then
        local nCurrentTime = GameLib.GetGameTime()
        if nCurrentTime - nLastIceTombTime > 5 then
            nLastIceTombTime = nCurrentTime
            self:AddTimer("ice_tomb",15)
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
    nLastIceTombTime = 0
    nLastBombTime = 0

    if self.config.timers.bombs.enable == true then
        self.core:AddTimer("BOMBS", self.L["message.bombs"], 30, self.config.timers.bombs.color)
    end

    if self.config.timers.ice_tomb.enable == true then
        self.core:AddTimer("ICE_TOMB", self.L["message.ice_tomb"], 26, self.config.timers.ice_tomb.color)
    end
end

function Mod:OnDisable()
    self.run = false
end

-------- ### HELPER METHODS ### ------

function Mod:AddUnit(key, unit, uniqueID, bShowUnit, bOnCast, bOnBuff, bOnDebuff, sMark, sText)
    if self.config.units and self.config.units[key] and self.config.units[key].enable then
        local txt = sText or (self.L[self.config.units[key].label] or self.config.units[key].label)
        self.core:AddUnit(uniqueID or key, txt, unit, bShowUnit, bOnCast, bOnBuff, bOnDebuff, sMark, self.config.units[key].color, self.config.units[key].priority)
    end
end

function Mod:AddTimer(key, time, uniqueID, text, fHandler, tData)
    if self.config.timers and self.config.timers[key] and self.config.timers[key].enable then
        local txt = text or (self.L[self.config.timers[key].label] or self.config.timers[key].label)
        self.core:AddTimer(uniqueID or key, txt, time, self.config.timers[key].color, fHandler, tData)
    end
end

function Mod:ShowCast(key, cast, text)
    if self.config.casts and self.config.casts[key] and self.config.casts[key].enable then
        local txt = text or (self.L[self.config.casts[key].label] or self.config.casts[key].label)
        self.core:ShowCast(cast, txt, self.config.casts[key].color)
    end
end

function Mod:ShowAlert(key, time, uniqueID, text)
    if self.config.alerts and self.config.alerts[key] and self.config.alerts[key].enable then
        local txt = text or (self.L[self.config.alerts[key].label] or self.config.alerts[key].label)
        self.core:ShowAlert(uniqueID or key, txt, time, self.config.alerts[key].color)
    end
end

function Mod:ShowAura(key, uniqueID, nDuration, bShowDuration, fHandler, tData)
    if self.config.auras and self.config.auras[key] and self.config.auras[key].enable then
        self.core:ShowAura(uniqueID or key, self.config.auras[key].sprite, self.config.auras[key].color, nDuration, bShowDuration, fHandler, tData)
    end
end

function Mod:PlaySound(key)
    if self.config.sounds and self.config.sounds[key] and self.config.sounds[key].enable then
        self.core:PlaySound(self.config.sounds[key].file)
    end
end

function Mod:DrawIcon(key, unit, uniqueID, nDuration, nHeight, bShowOverlay, fHandler, tData)
    if self.config.icons and self.config.icons[key] and self.config.icons[key].enable then
        self.core:DrawIcon(uniqueID or key, unit, self.config.icons[key].sprite, self.config.icons[key].size, nHeight, self.config.icons[key].color, nDuration, bShowOverlay, fHandler, tData)
    end
end

function Mod:DrawPixie(key, origin, uniqueID, nDuration, nRotation, nDistance, nHeight, fHandler, tData)
    if self.config.icons and self.config.icons[key] and self.config.icons[key].enable then
        self.core:DrawPixie(uniqueID or key, origin, self.config.icons[key].sprite, self.config.icons[key].size, nRotation, nDistance, nHeight, self.config.icons[key].color, nDuration, fHandler, tData)
    end
end

function Mod:DrawPolygon(key, origin, uniqueID, nRadius, nDuration, nRotation, nSide, fHandler, tData)
    if self.config.lines and self.config.lines[key] and self.config.lines[key].enable then
        self.core:DrawPolygon(uniqueID or key, origin, nRadius, nRotation, self.config.lines[key].thickness, self.config.lines[key].color, nSide, nDuration, fHandler, tData)
    end
end

function Mod:DrawLine(key, origin, uniqueID, nLength, nDuration, nRotation, nOffset, tVectorOffset, nNumberOfDot, fHandler, tData)
    if self.config.lines and self.config.lines[key] and self.config.lines[key].enable then
        self.core:DrawLine(uniqueID or key, origin, self.config.lines[key].color, self.config.lines[key].thickness, nLength, nRotation, nOffset, tVectorOffset, nDuration, nNumberOfDot, fHandler, tData)
    end
end

function Mod:DrawLineBetween(key, from, to, uniqueID, nDuration, nNumberOfDot, fHandler, tData)
    if self.config.lines and self.config.lines[key] and self.config.lines[key].enable then
        self.core:DrawLineBetween(uniqueID or key, from, to, self.config.lines[key].color, self.config.lines[key].thickness, nDuration, nNumberOfDot, fHandler, tData)
    end
end

function Mod:RemoveUnit(nId)
    self.core:RemoveUnit(nId)
end

function Mod:RemoveTimer(key, callback)
    self.core:RemoveTimer(key, callback)
end

function Mod:HideAura(key, callback)
    self.core:HideAura(key, callback)
end

function Mod:RemoveIcon(key, callback)
    self.core:RemoveIcon(key, callback)
end

function Mod:RemovePixie(key, callback)
    self.core:RemovePixie(key, callback)
end

function Mod:RemovePolygon(key, callback)
    self.core:RemovePolygon(key, callback)
end

function Mod:RemoveLine(key, callback)
    self.core:RemoveLine(key, callback)
end

function Mod:RemoveLineBetween(key, callback)
    self.core:RemoveLineBetween(key, callback)
end

function Mod:GetDraw(key)
    return self.core:GetDraw(key)
end

function Mod:GetDistance(from, to)
    return self.core:GetDistance(from, to)
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
