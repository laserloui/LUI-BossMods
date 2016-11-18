require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "AileronMegalith"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss_air"] = "Aileron",
        ["unit.boss_earth"] = "Megalith",
        ["unit.tornado"] = "Air Column",
        -- Alerts
        ["alert.tornado"] = "Tornado incoming!",
        ["alert.supercell"] = "Supercell - LAND ON MEGALITH!",
        ["alert.superquake"] = "Superquake - JUMP!",
        -- Casts
        ["cast.supercell"] = "Supercell",
        ["cast.fierce_swipe"] = "Fierce Swipe",
        -- Datachron
        ["datachron.superquake"] = "The ground shudders beneath Megalith!",
        -- Labels
        ["label.moo"] = "Moment of Opportunity",
        ["label.superquake"] = "Superquake",
        ["label.next_supercell"] = "Next supercell",
        ["label.next_tornado"] = "Next tornado",
        ["label.next_fierce_swipe"] = "Next fierce swipe",
    },
    ["deDE"] = {
        -- Units
        ["unit.boss_air"] = "Aileron",
        ["unit.boss_earth"] = "Megalith",
        ["unit.tornado"] = "Luftsäule",
        -- Alerts
        ["alert.tornado"] = "Tornado incoming!",
        ["alert.supercell"] = "Superzelle - LANDE AUF MEGALITH!",
        ["alert.superquake"] = "Superquake - SPRING!",
        -- Casts
        ["cast.supercell"] = "Superzelle",
        ["cast.fierce_swipe"] = "Heftiger Hieb",
        -- Datachron
        ["datachron.superquake"] = "The ground shudders beneath Megalith!",
        -- Labels
        ["label.moo"] = "Moment of Opportunity",
        ["label.superquake"] = "Superquake",
        ["label.next_supercell"] = "Nächste Superzelle",
        ["label.next_tornado"] = "Nächster Tornado",
        ["label.next_fierce_swipe"] = "Nächster Heftiger Hieb",
    },
    ["frFR"] = {
        -- Units
        ["unit.boss_air"] = "Ventemort",
        ["unit.boss_earth"] = "Mégalithe",
        ["unit.tornado"] = "Colonne d'air",
        -- Alerts
        ["alert.tornado"] = "La tornade est entrante !",
        ["alert.supercell"] = "Super-cellule - ATTERISSAGE SUR MÉGALITHE !",
        ["alert.superquake"] = "Superquake - SAUTE!",
        -- Casts
        ["cast.supercell"] = "Super-cellule",
        ["cast.fierce_swipe"] = "Baffe féroce",
        -- Datachron
        ["datachron.superquake"] = "Le sol tremble sous les pieds de Mégalithe !",
        -- Labels
        ["label.moo"] = "Moment d'opportunité",
        ["label.superquake"] = "Superquake",
        ["label.next_supercell"] = "Prochaine super-cellule",
        ["label.next_tornado"] = "Prochaine baffe féroce",
        ["label.next_fierce_swipe"] = "Prochaine tornade",
    },
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Aileron & Megalith"
    self.groupName = "Elemental Pairs"
    self.tTrigger = {
        sType = "ALL",
        tNames = {"unit.boss_air", "unit.boss_earth"},
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
            boss_air = {
                enable = true,
                label = "unit.boss_air",
            },
            boss_earth = {
                enable = true,
                label = "unit.boss_earth",
            },
        },
        timers = {
            supercell = {
                enable = true,
                position = 1,
                label = "label.next_supercell",
            },
            tornado = {
                enable = true,
                position = 2,
                label = "label.next_tornado",
            },
            fierce_swipe = {
                enable = true,
                position = 3,
                label = "label.next_fierce_swipe",
            },
        },
        alerts = {
            superquake = {
                enable = true,
                label = "label.superquake",
            },
            tornado = {
                enable = true,
                label = "unit.tornado",
            },
            supercell = {
                enable = true,
                label = "unit.supercell",
            },
        },
        casts = {
            superquake = {
                enable = true,
                label = "label.superquake",
            },
            moo = {
                enable = true,
                moo = true,
                label = "label.moo",
            },
        },
        sounds = {
            superquake = {
                enable = true,
                file = "alert",
                label = "label.superquake",
            },
            tornado = {
                enable = true,
                file = "info",
                label = "unit.tornado",
            },
        },
        lines = {
            tornado = {
                enable = true,
                thickness = 10,
                color = "ffff0000",
                label = "unit.tornado",
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

    if sName == self.L["unit.boss_air"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_air)
    elseif sName == self.L["unit.boss_earth"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_earth)
    elseif sName == self.L["unit.tornado"] then
        self.core:DrawLine(nId, tUnit, self.config.lines.tornado, 30)

        local nCurrentTime = GameLib.GetGameTime()
        if nCurrentTime > (self.nLastTornado + 10) then
            self.nLastTornado = nCurrentTime
            self.core:AddTimer("NEXT_TORNADO", self.L["label.next_tornado"], 17, self.config.timers.tornado)
            self.core:ShowAlert("Tornado", self.L["alert.tornado"], self.config.alerts.tornado)
            self.core:PlaySound(self.config.sounds.tornado)
        end
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.tornado"] then
        self.core:RemoveLine(nId)
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss_earth"] then
        if sCastName == self.L["cast.fierce_swipe"] then
            self.core:AddTimer("NEXT_FIERCE_SWIPE", self.L["label.next_fierce_swipe"], 16.5, self.config.timers.fierce_swipe)
        elseif sCastName == "MOO" then
            self.core:ShowCast(tCast,sCastName,self.config.casts.moo)
        end
    elseif sName == self.L["unit.boss_air"] then
        if sCastName == self.L["cast.supercell"] then
            local nCurrentTime = GameLib.GetGameTime()
            if nCurrentTime > (self.nLastSupercell + 30) then
                self.nLastSupercell = nCurrentTime
                self.core:AddTimer("NEXT_SUPERCELL", self.L["label.next_supercell"], 80, self.config.timers.supercell)
                self.core:ShowAlert("Supercell", self.L["alert.supercell"], self.config.alerts.supercell)
            end
        end
    end
end

function Mod:OnDatachron(sMessage, sSender, sHandler)
    if sMessage:match(self.L["datachron.superquake"]) then
        self.core:ShowCast({
            sName = "Superquake",
            nDuration = 2,
            nElapsed = 0,
            nTick = Apollo.GetTickCount()
        }, self.L["label.superquake"], self.config.casts.superquake)
        self.core:ShowAlert(self.L["label.superquake"], self.L["alert.jump"], self.config.alerts.superquake)
        self.core:PlaySound(self.config.sounds.superquake)
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
    self.nLastTornado = GameLib.GetGameTime()
    self.nLastSupercell = GameLib.GetGameTime()

    self.core:AddTimer("NEXT_SUPERCELL", self.L["label.next_supercell"], 65, self.config.timers.supercell)
    self.core:AddTimer("NEXT_TORNADO", self.L["label.next_tornado"], 16, self.config.timers.tornado)
    self.core:AddTimer("NEXT_FIERCE_SWIPE", self.L["label.next_fierce_swipe"], 16, self.config.timers.fierce_swipe)
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
