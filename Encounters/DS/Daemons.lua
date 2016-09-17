require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Daemons"

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

function Mod:LoadSettings(wndParent)
    if not wndParent then
        return
    end

    local wnd = Apollo.LoadForm(self.xmlDoc, "Settings", wndParent, self)

    -- Enable Checkbox
    wnd:FindChild("GeneralGroup"):FindChild("EnableCheckbox"):SetData("enable")
    wnd:FindChild("GeneralGroup"):FindChild("EnableCheckbox"):SetCheck(self.config.enable or false)

    -- North Color
    wnd:FindChild("GeneralGroup"):FindChild("NorthColorSetting"):FindChild("Color"):SetData("northColor")
    wnd:FindChild("GeneralGroup"):FindChild("NorthColorSetting"):FindChild("ColorText"):SetText(self.config.northColor or self.core.config.units.healthColor)
    wnd:FindChild("GeneralGroup"):FindChild("NorthColorSetting"):FindChild("BG"):SetBGColor(self.config.northColor or self.core.config.units.healthColor)

    -- South Color
    wnd:FindChild("GeneralGroup"):FindChild("SouthColorSetting"):FindChild("Color"):SetData("southColor")
    wnd:FindChild("GeneralGroup"):FindChild("SouthColorSetting"):FindChild("ColorText"):SetText(self.config.southColor or self.core.config.units.healthColor)
    wnd:FindChild("GeneralGroup"):FindChild("SouthColorSetting"):FindChild("BG"):SetBGColor(self.config.southColor or self.core.config.units.healthColor)

    ---------------------

    -- Disconnect Checkbox
    wnd:FindChild("DisconnectGroup"):FindChild("EnableCheckbox"):SetData({"disconnect","enable"})
    wnd:FindChild("DisconnectGroup"):FindChild("EnableCheckbox"):SetCheck(self.config.disconnect.enable or false)
    self.core.settings:ToggleSettings(wnd:FindChild("DisconnectGroup"),self.config.disconnect.enable or false)

    -- Disconnect Cast
    wnd:FindChild("DisconnectGroup"):FindChild("CastCheckbox"):SetData({"disconnect","cast"})
    wnd:FindChild("DisconnectGroup"):FindChild("CastCheckbox"):SetCheck(self.config.disconnect.cast or false)

    -- Disconnect Alert
    wnd:FindChild("DisconnectGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):AttachWindow(wnd:FindChild("DisconnectGroup"):FindChild("AlertSetting"):FindChild("ChoiceContainer"))
    wnd:FindChild("DisconnectGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):FindChild("ChoiceContainer"):Show(false)
    wnd:FindChild("DisconnectGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):SetText("Choose")
    wnd:FindChild("DisconnectGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):SetData({"disconnect","alert"})

    for _,button in pairs(wnd:FindChild("DisconnectGroup"):FindChild("AlertSetting"):FindChild("ChoiceContainer"):GetChildren()) do
        if button:GetName() == self.config.disconnect.alert then
            wnd:FindChild("DisconnectGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):SetText(button:GetText())
            button:SetCheck(true)
        else
            button:SetCheck(false)
        end
    end

    -- Disconnect Sound
    self.core.settings:BuildSoundDropdown(wnd:FindChild("DisconnectGroup"):FindChild("SoundSetting"),{"disconnect","sound"},self.config.disconnect.sound)

    -- Disconnect Color
    wnd:FindChild("DisconnectGroup"):FindChild("ColorSetting"):FindChild("Color"):SetData({"disconnect","color"})
    wnd:FindChild("DisconnectGroup"):FindChild("ColorSetting"):FindChild("ColorText"):SetText(self.config.disconnect.color or "")
    wnd:FindChild("DisconnectGroup"):FindChild("ColorSetting"):FindChild("BG"):SetBGColor(self.config.disconnect.color)

    ---------------------

    -- Power Surge Checkbox
    wnd:FindChild("SurgeGroup"):FindChild("EnableCheckbox"):SetData({"powersurge","enable"})
    wnd:FindChild("SurgeGroup"):FindChild("EnableCheckbox"):SetCheck(self.config.powersurge.enable or false)
    self.core.settings:ToggleSettings(wnd:FindChild("SurgeGroup"),self.config.powersurge.enable or false)

    -- Power Surge Cast
    wnd:FindChild("SurgeGroup"):FindChild("CastCheckbox"):SetData({"powersurge","cast"})
    wnd:FindChild("SurgeGroup"):FindChild("CastCheckbox"):SetCheck(self.config.powersurge.cast or false)

    -- Power Surge Alert
    wnd:FindChild("SurgeGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):AttachWindow(wnd:FindChild("SurgeGroup"):FindChild("AlertSetting"):FindChild("ChoiceContainer"))
    wnd:FindChild("SurgeGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):FindChild("ChoiceContainer"):Show(false)
    wnd:FindChild("SurgeGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):SetText("Choose")
    wnd:FindChild("SurgeGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):SetData({"powersurge","alert"})

    for _,button in pairs(wnd:FindChild("SurgeGroup"):FindChild("AlertSetting"):FindChild("ChoiceContainer"):GetChildren()) do
        if button:GetName() == self.config.powersurge.alert then
            wnd:FindChild("SurgeGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):SetText(button:GetText())
            button:SetCheck(true)
        else
            button:SetCheck(false)
        end
    end

    -- Power Surge Sound
    self.core.settings:BuildSoundDropdown(wnd:FindChild("SurgeGroup"):FindChild("SoundSetting"),{"powersurge","sound"},self.config.powersurge.sound)

    -- Power Surge Color
    wnd:FindChild("SurgeGroup"):FindChild("ColorSetting"):FindChild("Color"):SetData({"powersurge","color"})
    wnd:FindChild("SurgeGroup"):FindChild("ColorSetting"):FindChild("ColorText"):SetText(self.config.powersurge.color or "")
    wnd:FindChild("SurgeGroup"):FindChild("ColorSetting"):FindChild("BG"):SetBGColor(self.config.powersurge.color)

    ---------------------

    -- Purge Checkbox
    wnd:FindChild("PurgeGroup"):FindChild("EnableCheckbox"):SetData({"purge","enable"})
    wnd:FindChild("PurgeGroup"):FindChild("EnableCheckbox"):SetCheck(self.config.purge.enable or false)
    self.core.settings:ToggleSettings(wnd:FindChild("PurgeGroup"),self.config.purge.enable or false)

    -- Purge Alert
    wnd:FindChild("PurgeGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):AttachWindow(wnd:FindChild("PurgeGroup"):FindChild("AlertSetting"):FindChild("ChoiceContainer"))
    wnd:FindChild("PurgeGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):FindChild("ChoiceContainer"):Show(false)
    wnd:FindChild("PurgeGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):SetText("Choose")
    wnd:FindChild("PurgeGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):SetData({"purge","alert"})

    for _,button in pairs(wnd:FindChild("PurgeGroup"):FindChild("AlertSetting"):FindChild("ChoiceContainer"):GetChildren()) do
        if button:GetName() == self.config.purge.alert then
            wnd:FindChild("PurgeGroup"):FindChild("AlertSetting"):FindChild("Dropdown"):SetText(button:GetText())
            button:SetCheck(true)
        else
            button:SetCheck(false)
        end
    end

    -- Purge Sound
    self.core.settings:BuildSoundDropdown(wnd:FindChild("PurgeGroup"):FindChild("SoundSetting"),{"purge","sound"},self.config.purge.sound)

    -- Purge Color
    wnd:FindChild("PurgeGroup"):FindChild("ColorSetting"):FindChild("Color"):SetData({"purge","color"})
    wnd:FindChild("PurgeGroup"):FindChild("ColorSetting"):FindChild("ColorText"):SetText(self.config.purge.color or "")
    wnd:FindChild("PurgeGroup"):FindChild("ColorSetting"):FindChild("BG"):SetBGColor(self.config.purge.color)

    -- Purge Thickness
    wnd:FindChild("PurgeGroup"):FindChild("ThicknessSetting"):FindChild("Slider"):SetData({"purge","thickness"})
    wnd:FindChild("PurgeGroup"):FindChild("ThicknessSetting"):FindChild("Slider"):SetValue(self.config.purge.thickness or 0)
    wnd:FindChild("PurgeGroup"):FindChild("ThicknessSetting"):FindChild("SliderText"):SetText(self.config.purge.thickness or 0)

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
