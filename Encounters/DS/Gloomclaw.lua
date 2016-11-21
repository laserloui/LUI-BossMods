require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Gloomclaw"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss"] = "Gloomclaw",
        ["unit.essence"] = "Essence of Logic",
        ["unit.add1"] = "Strain Parasite",
        ["unit.add2"] = "Gloomclaw Skurge",
        ["unit.add3"] = "Corrupted Fraz",
        -- Casts
        ["cast.rupture"] = "Rupture",
        ["cast.burrow"] = "Burrow",
        -- Alerts
        ["alert.interrupt_rupture"] = "Interrupt Rupture!",
        -- Labels
        ["label.moo"] = "Moment of Opportunity",
        ["label.essence_left"] = "Left Essence",
        ["label.essence_right"] = "Right Essence",
        ["label.next_rupture"] = "Next Rupture",
        ["label.next_adds"] = "Next Wave",
    },
    ["deDE"] = {
        -- Units
        ["unit.boss"] = "Düsterklaue",
        ["unit.essence"] = "Logikessenz",
        ["unit.add1"] = "Transmutierten-Parasit",
        ["unit.add2"] = "Düsterklauen-Geißel",
        ["unit.add3"] = "Korrumpierter Fraz",
        -- Casts
        ["cast.rupture"] = "Aufreißen",
        ["cast.burrow"] = "Bau",
        -- Alerts
        ["alert.interrupt_rupture"] = "Boss Unterbrechen!",
        -- Labels
        ["label.moo"] = "Moment of Opportunity",
        ["label.essence_left"] = "Linke Essenz",
        ["label.essence_right"] = "Rechte Essenz",
        ["label.next_rupture"] = "Nächstes Aufreißen",
        ["label.next_adds"] = "Nächste Welle",
    },
    ["frFR"] = {
        -- Units
        ["unit.boss"] = "Serrenox",
        ["unit.essence"] = "Essence de logique",
        ["unit.add1"] = "Parasite de la Souillure",
        ["unit.add2"] = "Skurge serrenox",
        ["unit.add3"] = "Friz corrompu",
        -- Casts
        ["cast.rupture"] = "Rupture",
        ["cast.burrow"] = "Terrier",
        -- Alerts
        ["alert.interrupt_rupture"] = "Interrompre Rupture !",
        -- Labels
        ["label.moo"] = "Moment d'opportunité",
        ["label.essence_left"] = "Essence de gauche",
        ["label.essence_right"] = "Essence de droite",
        ["label.next_rupture"] = "Prochaine rupture",
        ["label.next_adds"] = "Prochaine vague",
    },
}

-- Constants
local nCenterX = 4310       -- The X coordinate of the Rooms Center
local nRoomSouth = -16612   -- The Z coordinate we use as the southmost point of the room.
local nRoomStep = 84        -- The distance between two seperators (seperating two sections)
local tFirstRuptureTimers = {[0]=30, [1]=32, [2]=28, [3]=26, [5]=30}    -- The timers for first rupture of each section. No value for section 4.
local tAddSpawnTimers = { [0]=25, [1]=26, [2]=33, [3]=25}               -- Static times for add-timers for each section. 4 not needed, 5 handled seperatly.
local tAddSpawnTotal = {[0]=4,[1]=4, [2]=3, [3]=4}                      -- The amount of add-spawns of each section. 4 not needed, 5 handled seperatly.

-- Variables
local tEssences = {}        -- [0-5]["L"/"R"] = tUnit e.g. tEssences[2].L is the left Essence in the 2nd Row
local nSection = nil        -- The section the boss is currently in (0-5 or nil)
local nTimeLastWave = 0     -- The timestamp the last wave was detected.
local nWaveCount = 0        -- The amount of waves spawned in this section.

--[[
L/R        true|false
        5    |    5
        ----+----        z = -16612 -5*84
        4    |    4
        ----+----        z = -16612 -4*84
        3    |    3
        ----+----        z = -16612 -3*84
        2    |    2
        ----+----        z = -16612 -2*84
        1    |    1    <- the fight starts with these.
        ----+----        z = -16612 -84
        0    |    0    <- entry
        ----+----        z = -16612
]]

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Gloomclaw"
    self.tTrigger = {
        sType = "ANY",
        tNames = {"unit.boss"},
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 115,
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
                position = 1,
            },
            essence_left = {
                enable = true,
                label = "label.essence_left",
                position = 2,
            },
            essence_right = {
                enable = true,
                label = "label.essence_right",
                position = 3,
            }
        },
        timers = {
            rupture = {
                enable = true,
                position = 1,
                color = "c8ffa500",
                label = "label.next_rupture",
                sound = true,
            },
            adds = {
                enable = true,
                position = 2,
                label = "label.next_adds",
            }
        },
        casts = {
            rupture = {
                enable = true,
                label = "cast.rupture",
            },
            moo = {
                enable = true,
                moo = true,
                label = "label.moo",
            },
        },
        alerts = {
            rupture = {
                enable = true,
                label = "cast.rupture",
            },
        },
        sounds = {
            rupture = {
                enable = true,
                file = "alert",
                label = "cast.rupture",
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

function Mod:GetSection(tPos)
    -- returns the section of the position (0-5) and bIsLeftSide
    return math.floor((nRoomSouth-tPos.z)/nRoomStep), tPos.x<nCenterX
end

function Mod:RegisterEssence(tUnit)
    local section, side = self:GetSection(tUnit:GetPosition())
    tEssences[section] = tEssences[section] or {}
    tEssences[section][side and "L" or "R"] = tUnit

    if nSection == section then
        if side then -- left
            self.core:RemoveUnit("ESSENCE_LEFT")
            self.core:AddUnit("ESSENCE_LEFT", self.L["label.essence_left"], tUnit, self.config.units.essence_left)
        else -- right
            self.core:RemoveUnit("ESSENCE_RIGHT")
            self.core:AddUnit("ESSENCE_RIGHT", self.L["label.essence_right"], tUnit, self.config.units.essence_right)
        end
    end
end

function Mod:UpdateGloomclawPos(tUnit) -- Gloomclaw
    nSection = self:GetSection(tUnit:GetPosition())
    if tEssences[nSection] then
        if tEssences[nSection].L then
            self.core:RemoveUnit("ESSENCE_LEFT")
            self.core:AddUnit("ESSENCE_LEFT", self.L["label.essence_left"], tEssences[nSection].L, self.config.units.essence_left)
        end
        if tEssences[nSection].R then
            self.core:RemoveUnit("ESSENCE_RIGHT")
            self.core:AddUnit("ESSENCE_RIGHT", self.L["label.essence_right"], tEssences[nSection].R, self.config.units.essence_right)
        end
    end
    return nSection
end

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run == true then
        return
    end

    if sName == self.L["unit.add1"] or sName == self.L["unit.add2"] or sName == self.L["unit.add3"] then
        local now = GameLib.GetGameTime()
        if now - nTimeLastWave > 10 then
            nTimeLastWave = now
            nWaveCount = nWaveCount + 1
            if nSection < 5 then
                if nWaveCount < tAddSpawnTotal[nSection] then
                    self.core:AddTimer("ADDS", self.L["label.next_adds"], tAddSpawnTimers[nSection], self.config.timers.adds)
                end
            else
                if nWaveCount == 1 then
                    self.core:AddTimer("ADDS", self.L["label.next_adds"], 20.5, self.config.timers.adds)
                elseif nWaveCount == 2 then
                    self.core:AddTimer("ADDS", self.L["label.next_adds"], 30, self.config.timers.adds)
                elseif nWaveCount == 3 then
                    self.core:AddTimer("ADDS", self.L["label.next_adds"], 15, self.config.timers.adds)
                end
            end
        end
    elseif sName == self.L["unit.boss"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss)
        self:UpdateGloomclawPos(tUnit)
    elseif sName == self.L["unit.essence"] then
        self:RegisterEssence(tUnit)
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss"] and sCastName == self.L["cast.rupture"] then
        self.core:PlaySound(self.config.sounds.rupture)
        self.core:ShowCast(tCast,sCastName,self.config.casts.rupture)
        self.core:ShowAlert(sCastName, self.L["alert.interrupt_rupture"], self.config.alerts.rupture)
        self.core:AddTimer("RUPTURE", self.L["label.next_rupture"], 43, self.config.timers.rupture)
    elseif sName == self.L["unit.boss"] and sCastName == "MOO" then
        self.core:ShowCast(tCast,sCastName,self.config.casts.moo)
        self.core:RemoveTimer("RUPTURE")
        self.core:RemoveTimer("ADDS")
    end
end


function Mod:OnCastEnd(nId, sCastName, tCast, sName)
    if sCastName == self.L["cast.burrow"] then -- Gloomclaw changed position
        local section = self:UpdateGloomclawPos(tCast.tUnit)
        if section ~= 4 then -- We need no timer for 4th phase
            self.core:AddTimer("RUPTURE", self.L["label.next_rupture"], tFirstRuptureTimers[section], self.config.timers.rupture)
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

    tEssences = {}
    nSection = nil
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
