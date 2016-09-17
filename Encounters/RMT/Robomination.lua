require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Robomination"

local Locales = {
    ["enUS"] = {
        -- Unit names
        ["Robomination"] = "Robomination",
        ["Cannon Arm"] = "Cannon Arm",
        ["Flailing Arm"] = "Flailing Arm",
        ["Scanning Eye"] = "Scanning Eye",
        -- Casts
        ["Noxious Belch"] = "Noxious Belch",
        ["Incineration Laser"] = "Incineration Laser",
        ["Cannon Fire"] = "Cannon Fire",
        -- Bar and messages
        ["Interrupt!"] = "Interrupt!",
        ["Next arms"] = "Next arms",
        ["Go to center!"] = "Go to center!",
        ["Lasers incoming!"] = "Lasers incoming!",
        ["CRUSH ON YOU!"] = "CRUSH ON YOU!",
        ["CRUSH ON %s!"] = "CRUSH ON %s!",
        ["INCINERATION LASER ON YOU!"] = "INCINERATION LASER ON YOU!",
        ["INCINERATION LASER!"] = "INCINERATION LASER!",
        -- Datachron messages
        ["The Robomination sinks down into the trash"] = "The Robomination sinks down into the trash",
        ["The Robomination erupts back into the fight!"] = "The Robomination erupts back into the fight!",
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
    if sName == self.L["Robomination"] then
        self.robomination = tUnit
        self.core:AddUnit(nId,sName,tUnit,true,nil,true)
    elseif sName == self.L["Cannon Arm"] then
        if self.config.LinesCannonArms.enable == true then
            self.core:DrawLineBetween(nId, tUnit, nil, self.config.LinesCannonArms.nWidth, self.config.LinesCannonArms.color)
        end
    elseif sName == self.L["Flailing Arm"] then
        if self.config.LinesFlailingArms.enable == true then
            self.core:DrawLineBetween(nId, tUnit, nil, self.config.LinesFlailingArms.nWidth, self.config.LinesFlailingArms.color)
        end
    elseif sName == self.L["Scanning Eye"] then
        if self.config.LinesScanningEye.enable == true then
            self.core:DrawLineBetween(nId, tUnit, nil, self.config.LinesScanningEye.nWidth, self.config.LinesScanningEye.color)
        end
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["Scanning Eye"] then
        self.core:RemoveLineBetween(nId)
    elseif sName == self.L["Cannon Arm"] then
        self.core:RemoveLineBetween(nId)
    elseif sName == self.L["Flailing Arm"] then
        self.core:RemoveLineBetween(nId)
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if self.L["Robomination"] == sName then
        if self.L["Noxious Belch"] == sCastName then
            if self.config.bLaserWarning == true then
               self.core:ShowAlert("Lasers_Alert", self.L["Lasers incoming!"])
            end
        end
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF__THE_SKY_IS_FALLING == nSpellId then
        if tData.tUnit:IsThePlayer() then
            self.core:ShowAura("Crush_Aura", "LUI_BossMods:meteor", "ffff4500", nDuration)
            self.core:ShowAlert("Crush_Alert", self.L["CRUSH ON YOU!"])
            self.core:PlaySound("run-away")
        else
            if self.core:GetDistance(tData.tUnit) < 15 then
                self.core:PlaySound("info")
            end

            self.core:ShowAlert("Crush_Alert", self.L["CRUSH ON %s!"]:format(sUnitName))
            self.core:DrawIcon("Crush_Icon", tData.tUnit, "LUI_BossMods:meteor", 60, 25, "ffff4500", nDuration, false)
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if DEBUFF__THE_SKY_IS_FALLING == nSpellId then
        self.core:HideAura("Crush_Aura")
        self.core:RemoveIcon("Crush_Icon")
    end
end

function Mod:OnDatachron(sMessage, sSender, sHandler)
    if sMessage == self.L["The Robomination sinks down into the trash"] then
        self.core:ShowAlert("Midphase_Alert", self.L["Go to center!"])
    else
        local strPlayerLaserFocused = sMessage:match("The Robomination tries to incinerate (.*)")
        if strPlayerLaserFocused then
            local tFocusedUnit = GameLib.GetPlayerUnitByName(strPlayerLaserFocused)

            if tFocusedUnit:IsThePlayer() then
                self.core:ShowAlert("Incineration_Alert", self.L["INCINERATION LASER ON YOU!"])
            else
                self.core:ShowAlert("Incineration_Alert", self.L["INCINERATION LASER!"])
            end

            self.core:DrawIcon("Incineration_Icon", tFocusedUnit, "LUI_BossMods:angry", 60, 25, "ffadff2f", 10)

            if self.robomination then
                 self.core:DrawLineBetween("Incineration_Line", tFocusedUnit, self.robomination, 14, "ffadff2f", 10)
            end
        end
    end
end

function Mod:IsEnabled()
    return self.run
end

function Mod:OnEnable()
    self.run = true
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
