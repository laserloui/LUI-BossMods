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
        ["alert.center"] = "Go to center!",
        ["alert.lasers"] = "Lasers incoming!",
        ["alert.crush"] = "CRUSH ON %s!",
        ["alert.crush_player"] = "CRUSH ON YOU!",
        ["alert.incineration"] = "INCINERATION LASER!",
        ["alert.incineration_player"] = "INCINERATION LASER ON YOU!",
        -- Messages
        ["message.next_arms"] = "Next arms",
        ["message.next_crush"] = "Next crush",
        ["message.midphase"] = "Midphase soon!",
        -- Datachron messages
        ["datachron.midphase_start"] = "The Robomination sinks down into the trash",
        ["datachron.midphase_end"] = "The Robomination erupts back into the fight!",
        ["datachron.incineration"] = "The Robomination tries to incinerate (.*)",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

local DEBUFF__THE_SKY_IS_FALLING = 75126 --Crush target

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
        bLaserWarning = true,
        LinesCannonArms = {
            enable = true,
            width = 8,
            color = "red",
        },
        LinesFlailingArms = {
            enable = false,
            width = 8,
            color = "blue",
        },
        LinesScanningEye = {
            enable = true,
            width = 8,
            color = "green",
        },
    }
    return o
end

function Mod:Init(parent)
    Apollo.LinkAddon(parent, self)

    self.core = parent
    self.L = parent:GetLocale(Encounter,Locales)

    local strPrefix = Apollo.GetAssetFolder()
    local tToc = XmlDoc.CreateFromFile("toc.xml"):ToTable()
    for k,v in ipairs(tToc) do
        local strPath = string.match(v.Name, "(.*)[\\/]"..Encounter)
        if strPath ~= nil and strPath ~= "" then
            strPrefix = strPrefix .. "\\" .. strPath .. "\\"
            break
        end
    end

    self.xmlDoc = XmlDoc.CreateFromFile(strPrefix .. Encounter..".xml")
    self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function Mod:OnDocLoaded()
    if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then
        return
    end
end

function Mod:LoadSettings(wndParent)
    if not wndParent then
        return
    end

    return Apollo.LoadForm(self.xmlDoc, "Settings", wndParent, self)
end

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if sName == self.L["unit.boss"] then
        self.boss = tUnit
        self.core:AddUnit(nId,sName,tUnit,true,nil,true)
        self.core:AddTimer("Timer_Arms", self.L["message.next_arms"], 45, "orange")
 		self.core:AddTimer("Timer_Crush", self.L["message.next_crush"], 8, "red")
    elseif sName == self.L["unit.cannon_arm"] then
        self.core:AddTimer("Timer_Arms", self.L["message.next_arms"], 45, "orange")

        if self.config.LinesCannonArms.enable == true then
            self.core:DrawLineBetween(nId, tUnit, nil, self.config.LinesCannonArms.nWidth, self.config.LinesCannonArms.color)
        end
    elseif sName == self.L["unit.flailing_arm"] then
        if self.config.LinesFlailingArms.enable == true then
            self.core:DrawLineBetween(nId, tUnit, nil, self.config.LinesFlailingArms.nWidth, self.config.LinesFlailingArms.color)
        end
    elseif sName == self.L["unit.scanning_eye"] then
        if self.config.LinesScanningEye.enable == true then
            self.core:DrawLineBetween(nId, tUnit, nil, self.config.LinesScanningEye.nWidth, self.config.LinesScanningEye.color)
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
    if sName == self.L["unit.boss"] then
        if nHealthPercent <= 77 and self.nMidphaseWarnings == 0 then
            self.core:ShowAlert("Midphase", self.L["message.midphase"])
            self.nMidphaseWarnings = 1
        elseif nHealthPercent <= 52 and self.nMidphaseWarnings == 1 then
            self.core:ShowAlert("Midphase", self.L["message.midphase"])
            self.nMidphaseWarnings = 2
        end
    end
 end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if self.L["unit.boss"] == sName then
        if self.L["cast.noxious_belch"] == sCastName then
            if self.config.bLaserWarning == true then
               self.core:ShowAlert(sCastName, self.L["alert.lasers"])
            end
        end
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF__THE_SKY_IS_FALLING == nSpellId then
        self.core:AddTimer("Timer_Crush", self.L["message.next_crush"], 8, "red")

        if tData.tUnit:IsThePlayer() then
            self.core:ShowAura("Aura_Crush", "LUI_BossMods:meteor", "ffff4500", nDuration)
            self.core:ShowAlert("Alert_Crush", self.L["alert.crush_player"])
            self.core:PlaySound("run-away")
        else
            if self.core:GetDistance(tData.tUnit) < 15 then
                self.core:PlaySound("info")
            end

            self.core:ShowAlert("Alert_Crush", self.L["alert.crush"]:format(sUnitName))
            self.core:DrawIcon("Icon_Crush", tData.tUnit, "LUI_BossMods:meteor", 60, 25, "ffff4500", nDuration, false)
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if DEBUFF__THE_SKY_IS_FALLING == nSpellId then
        self.core:HideAura("Aura_Crush")
        self.core:RemoveIcon("Icon_Crush")
    end
end

function Mod:OnDatachron(sMessage, sSender, sHandler)
    if sMessage == self.L["datachron.midphase_start"] then
        self.core:ShowAlert("Midphase_Start", self.L["alert.center"])
        self.core:RemoveTimer("Timer_Arms")
 		self.core:RemoveTimer("Timer_Crush")
    elseif sMessage == self.L["datachron.midphase_end"] then
        self.core:AddTimer("Timer_Arms", self.L["message.next_arms"], 45, "orange")
 		self.core:AddTimer("Timer_Crush", self.L["message.next_crush"], 8, "red")
    else
        local strPlayerLaserFocused = sMessage:match(self.L["datachron.incineration"])
        if strPlayerLaserFocused then
            local tFocusedUnit = GameLib.GetPlayerUnitByName(strPlayerLaserFocused)

            if tFocusedUnit:IsThePlayer() then
                self.core:ShowAlert("Incineration", self.L["alert.incineration_player"])
            else
                self.core:ShowAlert("Incineration", self.L["alert.incineration"])
            end

            self.core:DrawIcon("Icon_Incineration", tFocusedUnit, "LUI_BossMods:angry", 60, 25, "ffadff2f", 10)

            if self.boss then
                 self.core:DrawLineBetween("Line_Incineration", tFocusedUnit, self.boss, 14, "ffadff2f", 10)
            end
        end
    end
end

function Mod:IsEnabled()
    return self.run
end

function Mod:OnEnable()
    self.run = true
    self.nMidphaseWarnings = 0
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
