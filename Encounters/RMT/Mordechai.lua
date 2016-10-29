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
        ["alert.shocking_attraction"] = "SHURIKENS ON YOU!",
        ["alert.shocking_attraction_left"] = "MOVE TO THE LEFT!",
        ["alert.shocking_attraction_right"] = "MOVE TO THE RIGHT!",
        ["alert.midphase"] = "Midphase soon!",
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
    ["frFR"] = {
        -- Units
        ["unit.boss"] = "Mordechai Rougelune",
        ["unit.kinetic_orb"] = "Orbe Cinétique",
        ["unit.airlock_anchor"] = "Bride de sas",
        -- Debuffs
        ["debuff.kinetic_link"] = "Lien Cinétique",
        ["debuff.kinetic_fixation"] = "Fixation Cinétique",
        ["debuff.shocking_attraction"] = "Attraction Choquante",
        -- Datachron
        ["datachron.airlock_opened"] = "Le sas a été ouvert !",
        ["datachron.airlock_closed"] = "Le sas a été fermé !",
        -- Casts
        ["cast.shatter_shock"] = "Choc Fracassant",
        ["cast.vicious_barrage"] = "Barrage Vicieux",
        -- Alerts
        ["alert.orb_spawned"] = "Une orbe est apparue !",
        ["alert.kinetic_link"] = "TAPE L'ORBE !",
        ["alert.kinetic_fixation"] = "ORBE SUR TOI !",
        ["alert.shocking_attraction"] = "SHURIKEN SUR TOI !",
        ["alert.shocking_attraction_left"] = "BOUGE VERS LA GAUCHE !",
        ["alert.shocking_attraction_right"] = "BOUGE VERS LA DROITE !",
        ["alert.midphase"] = "Midphase bientôt !",
        -- Messages
        ["message.barrage_next"] = "Barrage Suivant",
        ["message.shuriken_next"] = "Shuriken Suivant",
        ["message.orb_next"] = "Orbe Suivante",
        ["message.orb_active"] = "L'orbe commence à bouger",
        -- Labels
        ["label.orb_next"] = "Orbe Cinétique (Suivante)",
        ["label.orb_active"] = "Orbe Cinétique (Active)",
        ["label.shocking_attraction_left"] = "Attraction Choquante (Gauche)",
        ["label.shocking_attraction_right"] = "Attraction Choquante (Droite)",
        ["label.shuriken"] = "Shuriken",
        ["label.airlock"] = "Aspiration",
        ["label.stack_point"] = "Point de ralliement du barrage",
    },
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
        tNames = {"unit.boss"},
        tZones = {
            [1] = {
                continentId = 104,
                parentZoneId = 0,
                mapId = 548,
            },
        },
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
                position = 1,
            },
            orb = {
                enable = true,
                label = "unit.kinetic_orb",
                position = 2,
            },
        },
        timers = {
            orb = {
                enable = true,
                position = 1,
                label = "label.orb_next",
            },
            orb_active = {
                enable = true,
                position = 2,
                color = "afff0000",
                label = "label.orb_active",
            },
            shuriken = {
                enable = true,
                position = 3,
                sound = true,
                label = "label.shuriken",
            },
            airlock = {
                enable = true,
                position = 4,
                label = "label.airlock",
            },
            barrage = {
                enable = true,
                position = 5,
                color = "afff0000",
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
            midphase = {
                enable = true,
                duration = 3,
                position = 6,
                label = "alert.midphase",
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
            midphase = {
                enable = true,
                position = 5,
                file = "beware",
                label = "alert.midphase",
            },
        },
        auras = {
            shocking_attraction = {
                enable = true,
                sprite = "LUIBM_shuriken",
                color = "ffb0ff2f",
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
            kinetic_link = {
                enable = true,
                position = 2,
                thickness = 6,
                color = "ffff0000",
                label = "debuff.kinetic_link",
            },
            kinetic_fixation = {
                enable = true,
                position = 3,
                thickness = 6,
                color = "ffb0ff2f",
                label = "debuff.kinetic_fixation",
            },
        },
        icons = {
            kinetic_link = {
                enable = true,
                position = 1,
                sprite = "LUIBM_crosshair",
                size = 80,
                color = "ffff0000",
                label = "debuff.kinetic_link",
            },
            shocking_attraction = {
                enable = true,
                position = 2,
                sprite = "LUIBM_crosshair",
                size = 80,
                color = "ffb0ff2f",
                label = "debuff.shocking_attraction",
            },
            airlock_anchor = {
                enable = true,
                position = 3,
                sprite = "BasicSprites:WhiteCircle",
                size = 40,
                color = "9600ff00",
                label = "unit.airlock_anchor",
            },
            stack_point = {
                enable = true,
                position = 4,
                sprite = "BasicSprites:WhiteCircle",
                size = 40,
                color = "96ff00ff",
                label = "label.stack_point",
            },
        },
        texts = {
            orb_active = {
                enable = true,
                color = "ffff0000",
                timer = true,
                label = "label.orb_active",
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
        self.core:AddTimer("ORB_ACTIVE", self.L["message.orb_active"], 5, self.config.timers.orb_active)
        self.core:DrawText("ORB_ACTIVE", tUnit, self.config.texts.orb_active, "", false, nil, 5)
        self.core:ShowAlert("ORB_SPAWNED", self.L["alert.orb_spawned"], self.config.alerts.orb)
        self.core:PlaySound(self.config.sounds.orb)
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.kinetic_orb"] then
        self.core:RemoveLineBetween("Line_Fixation")
        self.core:RemoveLineBetween("Line_Link")
        self.tUnitOrb = nil
    end
end

function Mod:OnHealthChanged(nId, nHealthPercent, sName, tUnit)
    if sName == self.L["unit.boss"] then
        if nHealthPercent <= 88 and self.nMidphaseWarnings == 0 then
            self.core:PlaySound(self.config.sounds.midphase)
            self.core:ShowAlert("Alert_Midphase", self.L["alert.midphase"], self.config.alerts.midphase)
            self.nMidphaseWarnings = 1
        elseif nHealthPercent <= 63 and self.nMidphaseWarnings == 1 then
            self.core:PlaySound(self.config.sounds.midphase)
            self.core:ShowAlert("Alert_Midphase", self.L["alert.midphase"], self.config.alerts.midphase)
            self.nMidphaseWarnings = 2
        elseif nHealthPercent <= 38 and self.nMidphaseWarnings == 2 then
            self.core:PlaySound(self.config.sounds.midphase)
            self.core:ShowAlert("Alert_Midphase", self.L["alert.midphase"], self.config.alerts.midphase)
            self.nMidphaseWarnings = 3
        elseif nHealthPercent <= 13 and self.nMidphaseWarnings == 3 then
            self.core:PlaySound(self.config.sounds.midphase)
            self.core:ShowAlert("Alert_Midphase", self.L["alert.midphase"], self.config.alerts.midphase)
            self.nMidphaseWarnings = 4
        end
    end
 end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if nSpellId == DEBUFF_KINETIC_LINK then
        if tData.tUnit:IsThePlayer() then
            self.core:PlaySound(self.config.sounds.kinetic_link)
            self.core:DrawLineBetween("Line_Link", self.tUnitOrb, tData.tUnit, self.config.lines.kinetic_link)
            self.core:ShowAlert("Alert_Link", self.L["alert.kinetic_link"], self.config.alerts.kinetic_link)
        end

        self.core:DrawIcon("Icon_Link"..tostring(nId), tData.tUnit, self.config.icons.kinetic_link, true, nil, nDuration)
    elseif nSpellId == DEBUFF_KINETIC_FIXATION then
        if tData.tUnit:IsThePlayer() then
            self.core:PlaySound(self.config.sounds.kinetic_fixation)
            self.core:ShowAlert("Alert_Fixation", self.L["alert.kinetic_fixation"], self.config.alerts.kinetic_fixation)
        end

        self.core:DrawLineBetween("Line_Fixation", self.tUnitOrb, tData.tUnit, self.config.lines.kinetic_fixation)
    elseif nSpellId == DEBUFF_SHOCKING_ATTRACTION then
        if tData.tUnit:IsThePlayer() then
            self.core:PlaySound(self.config.sounds.shocking_attraction)
            self.core:ShowAura("Aura_Shurikens", self.config.auras.shocking_attraction, nDuration, self.L["alert.shocking_attraction"])
            self.core:ShowAlert("Alert_Shurikens"..tostring(nId), self.L["alert.shocking_attraction_right"], self.config.alerts.shocking_attraction_right)
            self.core:ShowAlert("Alert_Shurikens"..tostring(nId), self.L["alert.shocking_attraction_left"], self.config.alerts.shocking_attraction_left)
        end

        self.core:DrawIcon("Icon_Shurikens"..tostring(nId), tData.tUnit, self.config.icons.shocking_attraction, true, nil, nDuration)
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if nSpellId == DEBUFF_KINETIC_LINK then
        self.core:RemoveIcon("Icon_Link"..tostring(nId))

        if tData.tUnit:IsThePlayer() then
            self.core:RemoveLineBetween("Line_Link")
        end
    elseif nSpellId == DEBUFF_KINETIC_FIXATION then
        self.core:RemoveLineBetween("Line_Fixation")
    elseif nSpellId == DEBUFF_SHOCKING_ATTRACTION then
        self.core:RemoveIcon("Icon_Shurikens"..tostring(nId))

        if tData.tUnit:IsThePlayer() then
            self.core:HideAura("Aura_Shurikens")
        end
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

    self.core:DrawIcon("AnchorLeft", AIRLOCK_ANCHOR_LEFT, self.config.icons.airlock_anchor)
    self.core:DrawIcon("AnchorRight", AIRLOCK_ANCHOR_RIGHT, self.config.icons.airlock_anchor)
    self.core:DrawIcon("StackPoint", STACK_POINT_MID, self.config.icons.stack_point)
end

function Mod:RemoveMarkerLines()
    self.core:RemoveLine("Cleave_1")
    self.core:RemoveLine("Cleave_2")
    self.core:RemoveLine("Cleave_3")
    self.core:RemoveLine("Cleave_4")

    self.core:RemoveIcon("AnchorLeft")
    self.core:RemoveIcon("AnchorRight")
    self.core:RemoveIcon("StackPoint")
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
    self.nMidphaseWarnings = 0

    self.core:AddTimer("NEXT_ORB", self.L["message.orb_next"], 22, self.config.timers.orb)
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
