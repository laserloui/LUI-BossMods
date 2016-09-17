require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Gloomclaw"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss"] = "Gloomclaw",
        -- Casts
        ["cast.rupture"] = "Rupture",
        -- Alerts
        ["alert.interrupt_rupture"] = "Interrupt Rupture!",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Gloomclaw"
    self.tTrigger = {
        sType = "ANY",
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 115,
            },
        },
        tNames = {
            ["enUS"] = {"Gloomclaw"},
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        rupture = {
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

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run == true then
        return
    end

    if sName == self.L["unit.boss"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,true,true,false,false,nil,self.config.healthColor)
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if self.config.rupture.enable == true then
        if sName == self.L["unit.boss"] and sCastName == self.L["cast.rupture"] then
            if self.config.rupture.sound ~= "None" then
                self.core:PlaySound(self.config.rupture.sound)
            end

            if self.config.rupture.cast == true then
                self.core:ShowCast(tCast,sCastName,self.config.rupture.color)
            end

            if self.config.rupture.alert ~= "None" then
                self.core:ShowAlert(sCastName, self.L["alert.interrupt_rupture"])
            end
        end
    end
end

function Mod:LoadSettings(wndParent)
    if not wndParent then
        return
    end

    local wnd = Apollo.LoadForm(self.xmlDoc, "Settings", wndParent, self)

    -- Enable Checkbox
    wnd:FindChild("GeneralGroup"):FindChild("EnableCheckbox"):SetData("enable")
    wnd:FindChild("GeneralGroup"):FindChild("EnableCheckbox"):SetCheck(self.config.enable or false)

    -- Health Color
    wnd:FindChild("GeneralGroup"):FindChild("HealthColorSetting"):FindChild("Color"):SetData("healthColor")
    wnd:FindChild("GeneralGroup"):FindChild("HealthColorSetting"):FindChild("ColorText"):SetText(self.config.healthColor or self.core.config.units.healthColor)
    wnd:FindChild("GeneralGroup"):FindChild("HealthColorSetting"):FindChild("BG"):SetBGColor(self.config.healthColor or self.core.config.units.healthColor)

    ---------------------

    -- Rupture Checkbox
    wnd:FindChild("RuptureGroup"):FindChild("EnableCheckbox"):SetData({"rupture","enable"})
    wnd:FindChild("RuptureGroup"):FindChild("EnableCheckbox"):SetCheck(self.config.rupture.enable or false)
    self.core.settings:ToggleSettings(wnd:FindChild("RuptureGroup"),self.config.rupture.enable or false)

    -- Rupture Cast
    wnd:FindChild("RuptureGroup"):FindChild("CastCheckbox"):SetData({"rupture","cast"})
    wnd:FindChild("RuptureGroup"):FindChild("CastCheckbox"):SetCheck(self.config.rupture.cast or false)

    -- Rupture Alert
    wnd:FindChild("RuptureGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):AttachWindow(wnd:FindChild("RuptureGroup"):FindChild("AlertSetting"):FindChild("ChoiceContainer"))
    wnd:FindChild("RuptureGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):FindChild("ChoiceContainer"):Show(false)
    wnd:FindChild("RuptureGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):SetText("Choose")
    wnd:FindChild("RuptureGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):SetData({"rupture","alert"})

    for _,button in pairs(wnd:FindChild("RuptureGroup"):FindChild("AlertSetting"):FindChild("ChoiceContainer"):GetChildren()) do
        if button:GetName() == self.config.rupture.alert then
            wnd:FindChild("RuptureGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):SetText(button:GetText())
            button:SetCheck(true)
        else
            button:SetCheck(false)
        end
    end

    -- Rupture Sound
    self.core.settings:BuildSoundDropdown(wnd:FindChild("RuptureGroup"):FindChild("SoundSetting"),{"rupture","sound"},self.config.rupture.sound)

    -- Rupture Color
    wnd:FindChild("RuptureGroup"):FindChild("ColorSetting"):FindChild("Color"):SetData({"rupture","color"})
    wnd:FindChild("RuptureGroup"):FindChild("ColorSetting"):FindChild("ColorText"):SetText(self.config.rupture.color or "")
    wnd:FindChild("RuptureGroup"):FindChild("ColorSetting"):FindChild("BG"):SetBGColor(self.config.rupture.color)

    return wnd
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
