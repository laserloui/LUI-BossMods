require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Mordechai"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss"] = "Mordechai Redmoon",
        ["unit.kinetic_orb"] = "Kinetic Orb",
        ["unit.airlock_anchor"] = "Airlock Anchor",
        -- Debuffs
        ["debuff.kinetic_link"] = "Kinetic Link",
        ["debuff.kinetic_fixation"] = "Kinetic Fixation",
        ["debuff.shocking_attraction"] = "Shocking Attraction",
        -- Datachron
        ["datachron.airlock_opened"] = "The airlock has been opened!",
        ["datachron.airlock_closed"] = "The airlock has been closed!",
        -- Casts
        ["cast.shatter_shock"] = "Shatter Shock",
        ["cast.vicious_barrage"] = "Vicious Barrage",
        -- Alerts
        ["alert.orb_spawned"] = "Orb spawned!",
        ["alert.kinetic_link"] = "HIT THE ORB!",
        ["alert.kinetic_fixation"] = "ORB ON YOU!",
        ["alert.shocking_attraction_left"] = "MOVE TO THE LEFT!",
        ["alert.shocking_attraction_right"] = "MOVE TO THE RIGHT!",
        -- Messages
        ["message.barrage_next"] = "Next Barrage",
        ["message.shuriken_next"] = "Next Shuriken",
        ["message.orb_next"] = "Next Orb",
        ["message.orb_active"] = "Orb start moving",
        -- Labels
        ["label.orb_next"] = "Kinetic Orb (Next)",
        ["label.orb_active"] = "Kinetic Orb (Active)",
        ["label.shocking_attraction_left"] = "Shocking Attraction (Left)",
        ["label.shocking_attraction_right"] = "Shocking Attraction (Right)",
        ["label.shuriken"] = "Shuriken",
        ["label.airlock"] = "Airlock",
        ["label.stack_point"] = "Barrage Stack Point",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

local DEBUFF_KINETIC_LINK = 86797
local DEBUFF_KINETIC_FIXATION = 85566
local DEBUFF_SHOCKING_ATTRACTION = 86861
local STACK_POINT_MID = Vector3.New(108.63, 353.87, 175.49)
local AIRLOCK_ANCHOR_LEFT = Vector3.New(123.85, 353.874, 179.71)
local AIRLOCK_ANCHOR_RIGHT = Vector3.New(93.85, 353.874, 179.71)
local CLEAVE_OFFSETS = {
    ["FRONT_LEFT"] = Vector3.New(3.25, 0, 0),
    ["FRONT_RIGHT"] = Vector3.New(-3.25, 0, 0),
    ["BACK_LEFT"] = Vector3.New(-3.25, 0, 0),
    ["BACK_RIGHT"] = Vector3.New(3.25, 0, 0),
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"
    self.displayName = "Mordechai"
    self.tTrigger = {
        sType = "ANY",
        tZones = {
            [1] = {
                continentId = 104,
                parentZoneId = 0,
                mapId = 548,
            },
        },
        tNames = {"unit.boss"},
    }
    self.run = false
    self.bViciousBarrage = false
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
            orb = {
                enable = true,
                label = "unit.kinetic_orb",
                color = "afb0ff2f",
                position = 2,
            },
        },
        timers = {
            orb = {
                enable = true,
                position = 1,
                color = "afb0ff2f",
                label = "label.orb_next",
            },
            orb_active = {
                enable = true,
                position = 2,
                color = "afff4500",
                label = "label.orb_active",
            },
            shuriken = {
                enable = true,
                position = 3,
                sound = true,
                color = "afb0ff2f",
                label = "label.shuriken",
            },
            airlock = {
                enable = true,
                position = 4,
                color = "afb0ff2f",
                label = "label.airlock",
            },
            barrage = {
                enable = true,
                position = 5,
                color = "afff4500",
                label = "cast.vicious_barrage",
            },
        },
        alerts = {
            orb = {
                enable = true,
                duration = 3,
                position = 1,
                label = "unit.kinetic_orb",
            },
            kinetic_link = {
                enable = true,
                duration = 3,
                position = 2,
                label = "debuff.kinetic_link",
            },
            kinetic_fixation = {
                enable = true,
                duration = 3,
                position = 3,
                label = "debuff.kinetic_fixation",
            },
            shocking_attraction_left = {
                enable = false,
                duration = 3,
                position = 4,
                label = "label.shocking_attraction_left",
            },
            shocking_attraction_right = {
                enable = true,
                duration = 3,
                position = 5,
                label = "label.shocking_attraction_right",
            },
        },
        sounds = {
            orb = {
                enable = true,
                position = 1,
                file = "alert",
                label = "unit.kinetic_orb",
            },
            kinetic_link = {
                enable = true,
                position = 2,
                file = "burn",
                label = "debuff.kinetic_link",
            },
            kinetic_fixation = {
                enable = true,
                position = 3,
                file = "run-away",
                label = "debuff.kinetic_fixation",
            },
            shocking_attraction = {
                enable = true,
                position = 4,
                file = "beware",
                label = "debuff.shocking_attraction",
            },
        },
        lines = {
            boss = {
                enable = true,
                position = 1,
                thickness = 6,
                color = "ffffffff",
                label = "unit.boss",
            },
            kinetic_fixation = {
                enable = true,
                position = 2,
                thickness = 6,
                color = "ffb0ff2f",
                label = "debuff.kinetic_fixation",
            },
        },
        icons = {
            kinetic_link = {
                enable = true,
                sprite = "target2",
                size = 60,
                color = "ffff00ff",
                label = "debuff.kinetic_link",
            },
            shocking_attraction = {
                enable = true,
                sprite = "target2",
                size = 60,
                color = "ffb0ff2f",
                label = "debuff.shocking_attraction",
            },
        },
        texts = {
            airlock_anchor = {
                enable = true,
                font = "CRB_FloaterMedium",
                color = "ff00ff00",
                label = "unit.airlock_anchor",
            },
            stack_point = {
                enable = true,
                font = "CRB_FloaterMedium",
                color = "ffff00ff",
                label = "label.stack_point",
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
    if not self.run then
        return
    end

    if sName == self.L["unit.boss"] and bInCombat then
        self.tUnitBoss = tUnit
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss)
        self:AddMarkerLines()
    elseif sName == self.L["unit.kinetic_orb"] and bInCombat then
        self.tUnitOrb = tUnit
        self.core:AddUnit(nId,sName,tUnit,self.config.units.orb)
        self.core:AddTimer("NEXT_ORB", self.L["message.orb_next"], 26, self.config.timers.orb)
        self.core:AddTimer("ORB_ACTIVE", self.L["message.orb_active"], 4.5, self.config.timers.orb_active)
        self.core:ShowAlert("ORB"..tostring(nId), self.L["alert.orb_spawned"], self.config.alerts.orb)
        self.core:PlaySound(self.config.sounds.orb)
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.kinetic_orb"] then
        self.core:RemoveLineBetween("ORB")
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if nSpellId == DEBUFF_KINETIC_LINK then
        if tData.tUnit:IsThePlayer() then
            self.core:ShowAlert("KL"..tostring(nId), self.L["alert.kinetic_link"], self.config.alerts.kinetic_link)
            self.core:PlaySound(self.config.sounds.kinetic_link)
        end

        self.core:DrawIcon("KL"..tostring(nId), tData.tUnit, self.config.icons.kinetic_link, nil, nDuration)
    elseif nSpellId == DEBUFF_KINETIC_FIXATION then
        if tData.tUnit:IsThePlayer() then
            self.core:ShowAlert("KF"..tostring(nId), self.L["alert.kinetic_fixation"], self.config.alerts.kinetic_fixation)
            self.core:PlaySound(self.config.sounds.kinetic_fixation)
        end

        if self.tUnitOrb then
            self.core:DrawLineBetween("ORB", tData.tUnit, self.tUnitOrb, self.config.lines.kinetic_fixation)
        end
    elseif nSpellId == DEBUFF_SHOCKING_ATTRACTION then
        if tData.tUnit:IsThePlayer() then
            self.core:ShowAlert("SA"..tostring(nId), self.L["alert.shocking_attraction_right"], self.config.alerts.shocking_attraction_right)
            self.core:ShowAlert("SA"..tostring(nId), self.L["alert.shocking_attraction_left"], self.config.alerts.shocking_attraction_left)
            self.core:PlaySound(self.config.sounds.shocking_attraction)
        end

        self.core:DrawIcon("SA"..tostring(nId), tData.tUnit, self.config.icons.shocking_attraction, nil, nDuration)
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if nSpellId == DEBUFF_KINETIC_LINK then
        self.core:RemoveIcon("KL" .. nId)
    elseif nSpellId == DEBUFF_SHOCKING_ATTRACTION then
        self.core:RemoveIcon("SA" .. nId)
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName, nDuration)
    if sName == self.L["Mordechai Redmoon"] then
        if sCastName == self.L["cast.shatter_shock"] then
            self.core:AddTimer("NEXT_SHURIKEN", self.L["message.shuriken_next"], 22, self.config.timers.shuriken)
        elseif sCastName == self.L["cast.vicious_barrage"] then
            self.core:AddTimer("NEXT_BARRAGE", self.L["message.barrage_next"], 33, self.config.timers.barrage)
        end
    end
end

function Mod:OnDatachron(sMessage, sSender, sHandler)
    if sMessage:find(self.L["datachron.airlock_closed"]) then
        self:AddMarkerLines()
        self.core:AddTimer("NEXT_SHURIKEN", self.L["message.shuriken_next"], 10, self.config.timers.shuriken)
        self.core:AddTimer("NEXT_ORB", self.L["message.orb_next"], 15, self.config.timers.orb)

        if self.bViciousBarrage then
            self.core:AddTimer("NEXT_BARRAGE", self.L["message.barrage_next"], 19, self.config.timers.barrage)
        end

        self.bViciousBarrage = true
    elseif sMessage:find(self.L["datachron.airlock_opened"]) then
        self:RemoveMarkerLines()
        self.core:RemoveTimer("NEXT_ORB")
        self.core:RemoveTimer("NEXT_SHURIKEN")
        self.core:RemoveTimer("NEXT_BARRAGE")
        self.core:AddTimer("AIRLOCK", self.L["label.airlock"], 25, self.config.timers.airlock)
    end
end

function Mod:AddMarkerLines()
    if self.tUnitBoss then
        self.core:DrawLine("Cleave_1", self.tUnitBoss, self.config.lines.boss, 60, -23.5, 0, CLEAVE_OFFSETS["FRONT_LEFT"])
        self.core:DrawLine("Cleave_2", self.tUnitBoss, self.config.lines.boss, 60, 23.5, 0, CLEAVE_OFFSETS["FRONT_RIGHT"])
        self.core:DrawLine("Cleave_3", self.tUnitBoss, self.config.lines.boss, -60, -23.5, 0, CLEAVE_OFFSETS["BACK_LEFT"])
        self.core:DrawLine("Cleave_4", self.tUnitBoss, self.config.lines.boss, -60, 23.5, 0, CLEAVE_OFFSETS["BACK_RIGHT"])
    end

    self.core:DrawText("AnchorLeft", AIRLOCK_ANCHOR_LEFT, self.config.texts.airlock_anchor, "LEFT")
    self.core:DrawText("AnchorRight", AIRLOCK_ANCHOR_RIGHT, self.config.texts.airlock_anchor, "RIGHT")
    self.core:DrawText("StackPoint", STACK_POINT_MID, self.config.texts.stack_point, "STACK")
end

function Mod:RemoveMarkerLines()
    self.core:RemoveLine("Cleave_1")
    self.core:RemoveLine("Cleave_2")
    self.core:RemoveLine("Cleave_3")
    self.core:RemoveLine("Cleave_4")

    self.core:RemoveText("AnchorLeft")
    self.core:RemoveText("AnchorRight")
    self.core:RemoveText("StackPoint")
end

function Mod:IsRunning()
    return self.run
end

function Mod:IsEnabled()
    return self.config.enable
end

function Mod:OnEnable()
    self.run = true
    self.tUnitBoss = nil
    self.tUnitOrb = nil
    self.bViciousBarrage = false

    self.core:AddTimer("NEXT_ORB", self.L["message.orb_next"], 22, self.config.timers.orb)
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
