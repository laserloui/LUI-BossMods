require "Window"
require "Apollo"

local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local GeminiColor = Apollo.GetPackage("GeminiColor").tPackage

local Settings = {}

function Settings:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.bIsGlobal = false
    self.soundFiles = {"None","alarm","alert","info","long","interrupt","run-away","beware","burn","destruction","inferno"}
    return o
end

function Settings:Init(parent)
    Apollo.LinkAddon(parent, self)

    self.core = parent
    self.config = parent.config

    local strPrefix = Apollo.GetAssetFolder()
    local tToc = XmlDoc.CreateFromFile("toc.xml"):ToTable()
    for k,v in ipairs(tToc) do
        local strPath = string.match(v.Name, "(.*)[\\/]Settings")
        if strPath ~= nil and strPath ~= "" then
            strPrefix = strPrefix .. "\\" .. strPath .. "\\"
            break
        end
    end

    self.xmlDoc = XmlDoc.CreateFromFile(strPrefix .. "Settings.xml")
    self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function Settings:OnDocLoaded()
    if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then
        return
    end

    self:OnLoad()

    if self.core.modules then
        for sName,tModule in pairs(self.core.modules) do
            tModule.OnTextChange = self.OnTextChange
            tModule.OnDropdownToggle = self.OnDropdownToggle
            tModule.OnDropdownChoose = self.OnDropdownChoose
            tModule.OnSliderChange = self.OnSliderChange
            tModule.OnCheckbox = self.OnCheckbox
            tModule.OnBtnChooseColor = self.OnBtnChooseColor
            tModule.OnColorPicker = self.OnColorPicker
            tModule.ToggleSettings = self.ToggleSettings
        end
    end
end

function Settings:OnLoad()
    self.wndSettings = Apollo.LoadForm(self.xmlDoc, "Settings", nil, self)
    self.wndSettings:Show(false,true)

    local nMaxWidth,nMaxHeight = Apollo.GetScreenSize()
    local nCurrWidth = math.abs(self.config.settings.offsets.left) + math.abs(self.config.settings.offsets.right) + 50
    local nCurrHeight = math.abs(self.config.settings.offsets.top) + math.abs(self.config.settings.offsets.bottom) + 50

    if (nCurrWidth > nMaxWidth) or (nCurrHeight > nMaxHeight) then
        self.wndSettings:SetAnchorOffsets(-600,-420,600,420)
    else
        self.wndSettings:SetAnchorOffsets(
            self.config.settings.offsets.left,
            self.config.settings.offsets.top,
            self.config.settings.offsets.right,
            self.config.settings.offsets.bottom
        )
    end

    -- Hide Donation Form
    self.wndSettings:FindChild("DonateForm"):Show(false,true)
    self.wndSettings:FindChild("DonateSeperator"):Show(false,true)
    self.wndSettings:FindChild("DonateBtn"):Show((GameLib.GetRealmName() == "Jabbit"),true)
    self.wndSettings:FindChild("DonateForm"):FindChild("DonateSendBtn"):Enable(false)

    -- Navigation
    self.current = nil

    local wndMeasure = Apollo.LoadForm(self.xmlDoc, "Navigation:Instance", nil, self)
    self.nInstanceButtonHeight = wndMeasure:GetHeight()
    wndMeasure:Destroy()

    wndMeasure = Apollo.LoadForm(self.xmlDoc, "Navigation:Encounter", nil, self)
    self.nEncounterButtonHeight = wndMeasure:GetHeight()
    wndMeasure:Destroy()

    self:BuildTree()
    self:BuildGlobalSettings()
end

function Settings:BuildTree()
    local wndLeftScroll = self.wndSettings:FindChild("LeftScroll")
    wndLeftScroll:DestroyChildren()

    local instances = {}

    for sName,mod in pairs(self.core.modules) do
        if mod and mod.xmlDoc and mod.LoadSettings then
            if not instances[mod.instance] then
                instances[mod.instance] = {}
            end

            instances[mod.instance][mod.displayName] = sName
        end
    end

    for strInstance,tBosses in pairs(instances) do
        local wndInstanceGroup = Apollo.LoadForm(self.xmlDoc, "Navigation:Instance", wndLeftScroll, self)
        local wndInstanceContents = wndInstanceGroup:FindChild("GroupContents")
        local wndMinibosses = nil

        for strEncounter,strModule in pairs(tBosses) do
            if self.core.modules[strModule].bIsMiniboss then
                if not wndMinibosses then
                    local wndEncounterGroup = Apollo.LoadForm(self.xmlDoc, "Navigation:Encounter", wndInstanceContents, self)
                    wndEncounterGroup:SetData("Minibosses")

                    local wndEncounterGroupBtn = wndEncounterGroup:FindChild("EncounterBtn")
                    self:StyleButton(wndEncounterGroupBtn,"encounter")

                    wndEncounterGroupBtn:SetData({instance = strInstance, encounter = "Minibosses", btn = wndEncounterGroupBtn})
                    wndEncounterGroupBtn:SetText("Minibosses")
                    wndEncounterGroupBtn:ChangeArt("BK3:btnMetal_ExpandMenu_MedClean")

                    wndMinibosses = wndEncounterGroupBtn
                end

                local data = wndMinibosses:GetData()

                if not data.modules then
                    data.modules = {}
                end

                table.insert(data.modules,strModule)
                wndMinibosses:SetData(data)
            else
                local wndEncounterGroup = Apollo.LoadForm(self.xmlDoc, "Navigation:Encounter", wndInstanceContents, self)
                wndEncounterGroup:SetData(strModule)

                local wndEncounterGroupBtn = wndEncounterGroup:FindChild("EncounterBtn")
                self:StyleButton(wndEncounterGroupBtn,"encounter")

                wndEncounterGroupBtn:SetData({instance = strInstance, encounter = strModule, btn = wndEncounterGroupBtn})
                wndEncounterGroupBtn:SetText(strEncounter)
                wndEncounterGroupBtn:ChangeArt("BK3:btnMetal_ExpandMenu_MedClean")
            end
        end

        local wndInstanceGroupBtn = wndInstanceGroup:FindChild("InstanceBtn")
        wndInstanceGroupBtn:SetText(strInstance)
        wndInstanceGroupBtn:SetData(strInstance)

        self:StyleButton(wndInstanceGroupBtn,"instance")
        wndInstanceContents:ArrangeChildrenVert(0)
    end

    self:ResizeTree()
end

function Settings:ResizeTree()
    local wndLeftScroll = self.wndSettings:FindChild("LeftScroll")
    local nVScrollPos = wndLeftScroll:GetVScrollPos()

    for mainKey,wndMainGroup in pairs(wndLeftScroll:GetChildren()) do
        local wndMainContents = wndMainGroup:FindChild("GroupContents")
        local wndMainButton = wndMainGroup:FindChild("InstanceBtn")
        local nTopHeight = 0

        if wndMainButton:IsChecked() then
            for key, wndTopGroup in pairs(wndMainContents:GetChildren()) do
                nTopHeight = nTopHeight + 2 + self.nEncounterButtonHeight
            end

            if nTopHeight > 0 then
                nTopHeight = nTopHeight + 5
            end
        end

        local nLeft, nTop, nRight = wndMainGroup:GetAnchorOffsets()
        wndMainGroup:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nTopHeight + self.nInstanceButtonHeight)
        wndMainContents:ArrangeChildrenVert(0)
        wndMainContents:Show(wndMainButton:IsChecked(),true)
    end

    wndLeftScroll:ArrangeChildrenVert(0)
    wndLeftScroll:SetVScrollPos(nVScrollPos)
end

function Settings:StyleButton(button,sType)
    if not button or not sType then
        return
    end

    if sType == "instance" then
        button:SetNormalTextColor("UI_BtnTextGoldListNormal")
        button:SetPressedTextColor("UI_BtnTextGoldListPressed")
        button:SetFlybyTextColor("UI_BtnTextGoldListFlyby")
        button:SetPressedFlybyTextColor("UI_BtnTextGoldListPressedFlyby")
        button:SetBGColor("ffffffff")
        button:GetParent():SetBGColor("ffd7d7d7")
    elseif sType == "encounter" then
        button:SetNormalTextColor("UI_BtnTextGoldListNormal")
        button:SetPressedTextColor("UI_BtnTextGoldListPressed")
        button:SetFlybyTextColor("UI_BtnTextGoldListFlyby")
        button:SetPressedFlybyTextColor("UI_BtnTextGoldListPressedFlyby")
        button:SetBGColor("ffffffff")
    end
end

function Settings:OnInstanceBtn(wndHandler, wndControl)
    if wndHandler ~= wndControl then
        return
    end

    if self.current and self.current.instance == wndControl:GetData() then
        self.current.btn:SetCheck(false)
        self.current = nil
        self:ResizeTree()

        self.wndSettings:FindChild("RightScroll"):FindChild("Container"):DestroyChildren()
        self.wndSettings:FindChild("RightScroll"):FindChild("Container"):RecalculateContentExtents()
        return
    end

    self:ResizeTree()
end

function Settings:OnEncounterBtn(wndHandler, wndControl)
    if wndHandler ~= wndControl then
        return
    end

    if self.current and self.current.encounter == wndControl:GetData()["encounter"] then
        wndHandler:SetCheck(true)
        return
    end

    if self.current and self.current.btn then
        self.current.btn:SetCheck(false)
    end

    wndHandler:SetCheck(true)
    self.current = wndControl:GetData()
    self:BuildRightPanel()
end

function Settings:BuildRightPanel()
    if not self.current or not self.current.encounter then
        return
    end

    local wndRightScroll = self.wndSettings:FindChild("RightScroll"):FindChild("Container")
    wndRightScroll:DestroyChildren()

    if self.wndRight then
        self.wndRight:Destroy()
    end

    if self.current.encounter == "Minibosses" then
        self.wndRight = Apollo.LoadForm(self.xmlDoc, "RightScroll", wndRightScroll, self)

        if self.current.modules then
            for _,strModule in pairs(self.current.modules) do
                self.core.modules[strModule]:LoadSettings(self.wndRight)
            end
        end

        self.wndRight:ArrangeChildrenVert()
    else
        self.wndRight = self.core.modules[self.current.encounter]:LoadSettings(wndRightScroll)
    end

    if self.wndRight then
        self.wndRight:RecalculateContentExtents()
        wndRightScroll:RecalculateContentExtents()
    end
end

function Settings:BuildGlobalSettings()

    -- #########################################################################################################################################
    -- # GENERAL
    -- #########################################################################################################################################

    local wndGeneral = self.wndSettings:FindChild("Global"):FindChild("General")

    -- Update Interval
    wndGeneral:FindChild("IntervalSetting"):FindChild("Slider"):SetData("interval")
    wndGeneral:FindChild("IntervalSetting"):FindChild("Slider"):SetValue(self.config.interval or 0)
    wndGeneral:FindChild("IntervalSetting"):FindChild("SliderText"):SetText(self.config.interval or 0)

    -- #########################################################################################################################################
    -- # SOUNDS
    -- #########################################################################################################################################

    local wndSounds = self.wndSettings:FindChild("Global"):FindChild("Sounds")
    self:ToggleSettings(wndSounds:FindChild("Container"),(self.config.sound.enable and self.config.sound.force) or false)
    self:ToggleSettings(wndSounds:FindChild("ForceCheckbox"),self.config.sound.enable or false)

    -- Enable Checkbox
    wndSounds:FindChild("EnableCheckbox"):SetData({"sound","enable"})
    wndSounds:FindChild("EnableCheckbox"):SetCheck(self.config.sound.enable or false)

    -- Adjust Volume Checkbox
    wndSounds:FindChild("ForceCheckbox"):SetData({"sound","force"})
    wndSounds:FindChild("ForceCheckbox"):SetCheck(self.config.sound.force or false)

    -- Volume Master
    wndSounds:FindChild("VolumeMasterSetting"):FindChild("Slider"):SetData({"sound","volumeMaster"})
    wndSounds:FindChild("VolumeMasterSetting"):FindChild("Slider"):SetValue(self.config.sound.volumeMaster or 0)
    wndSounds:FindChild("VolumeMasterSetting"):FindChild("SliderText"):SetText(self.config.sound.volumeMaster or 0)

    -- Volume Music
    wndSounds:FindChild("VolumeMusicSetting"):FindChild("Slider"):SetData({"sound","volumeMusic"})
    wndSounds:FindChild("VolumeMusicSetting"):FindChild("Slider"):SetValue(self.config.sound.volumeMusic or 0)
    wndSounds:FindChild("VolumeMusicSetting"):FindChild("SliderText"):SetText(self.config.sound.volumeMusic or 0)

    -- Volume UI
    wndSounds:FindChild("VolumeUISetting"):FindChild("Slider"):SetData({"sound","volumeUI"})
    wndSounds:FindChild("VolumeUISetting"):FindChild("Slider"):SetValue(self.config.sound.volumeUI or 0)
    wndSounds:FindChild("VolumeUISetting"):FindChild("SliderText"):SetText(self.config.sound.volumeUI or 0)

    -- Volume SFX
    wndSounds:FindChild("VolumeSFXSetting"):FindChild("Slider"):SetData({"sound","volumeSFX"})
    wndSounds:FindChild("VolumeSFXSetting"):FindChild("Slider"):SetValue(self.config.sound.volumeSFX or 0)
    wndSounds:FindChild("VolumeSFXSetting"):FindChild("SliderText"):SetText(self.config.sound.volumeSFX or 0)

    -- Volume Ambient
    wndSounds:FindChild("VolumeAmbientSetting"):FindChild("Slider"):SetData({"sound","volumeAmbient"})
    wndSounds:FindChild("VolumeAmbientSetting"):FindChild("Slider"):SetValue(self.config.sound.volumeAmbient or 0)
    wndSounds:FindChild("VolumeAmbientSetting"):FindChild("SliderText"):SetText(self.config.sound.volumeAmbient or 0)

    -- Volume Voice
    wndSounds:FindChild("VolumeVoiceSetting"):FindChild("Slider"):SetData({"sound","volumeVoice"})
    wndSounds:FindChild("VolumeVoiceSetting"):FindChild("Slider"):SetValue(self.config.sound.volumeVoice or 0)
    wndSounds:FindChild("VolumeVoiceSetting"):FindChild("SliderText"):SetText(self.config.sound.volumeVoice or 0)

    -- #########################################################################################################################################
    -- # UNITS
    -- #########################################################################################################################################

    local wndUnit = self.wndSettings:FindChild("Global"):FindChild("Units")
    self:ToggleSettings(wndUnit:FindChild("Container"),self.config.units.enable or false)

    -- Enable Checkbox
    wndUnit:FindChild("EnableCheckbox"):SetData({"units","enable"})
    wndUnit:FindChild("EnableCheckbox"):SetCheck(self.config.units.enable or false)

    -- Health Color
    wndUnit:FindChild("HealthColorSetting"):FindChild("Color"):SetData({"units","healthColor"})
    wndUnit:FindChild("HealthColorSetting"):FindChild("ColorText"):SetText(self.config.units.healthColor or "")
    wndUnit:FindChild("HealthColorSetting"):FindChild("BG"):SetBGColor(self.config.units.healthColor)

    -- Shield Color
    wndUnit:FindChild("ShieldColorSetting"):FindChild("Color"):SetData({"units","shieldColor"})
    wndUnit:FindChild("ShieldColorSetting"):FindChild("ColorText"):SetText(self.config.units.shieldColor or "")
    wndUnit:FindChild("ShieldColorSetting"):FindChild("BG"):SetBGColor(self.config.units.shieldColor)

    -- Absorb Color
    wndUnit:FindChild("AbsorbColorSetting"):FindChild("Color"):SetData({"units","absorbColor"})
    wndUnit:FindChild("AbsorbColorSetting"):FindChild("ColorText"):SetText(self.config.units.absorbColor or "")
    wndUnit:FindChild("AbsorbColorSetting"):FindChild("BG"):SetBGColor(self.config.units.absorbColor)

    -- Text Color
    wndUnit:FindChild("TextColorSetting"):FindChild("Color"):SetData({"units","textColor"})
    wndUnit:FindChild("TextColorSetting"):FindChild("ColorText"):SetText(self.config.units.textColor or "")
    wndUnit:FindChild("TextColorSetting"):FindChild("BG"):SetBGColor(self.config.units.textColor)

    -- Health Height
    wndUnit:FindChild("HealthHeightSetting"):FindChild("Slider"):SetData({"units","healthHeight"})
    wndUnit:FindChild("HealthHeightSetting"):FindChild("Slider"):SetValue(self.config.units.healthHeight or 0)
    wndUnit:FindChild("HealthHeightSetting"):FindChild("SliderText"):SetText(self.config.units.healthHeight or 0)

    -- Shield Height
    wndUnit:FindChild("ShieldHeightSetting"):FindChild("Slider"):SetData({"units","shieldHeight"})
    wndUnit:FindChild("ShieldHeightSetting"):FindChild("Slider"):SetValue(self.config.units.shieldHeight or 0)
    wndUnit:FindChild("ShieldHeightSetting"):FindChild("SliderText"):SetText(self.config.units.shieldHeight or 0)

    -- Shield Height
    wndUnit:FindChild("ShieldWidthSetting"):FindChild("Slider"):SetData({"units","shieldWidth"})
    wndUnit:FindChild("ShieldWidthSetting"):FindChild("Slider"):SetValue(self.config.units.shieldWidth or 0)
    wndUnit:FindChild("ShieldWidthSetting"):FindChild("SliderText"):SetText(self.config.units.shieldWidth or 0)

    -- #########################################################################################################################################
    -- # CASTBAR
    -- #########################################################################################################################################

    local wndCastbar = self.wndSettings:FindChild("Global"):FindChild("Castbar")

    -- Bar Color
    wndCastbar:FindChild("BarColorSetting"):FindChild("Color"):SetData({"castbar","barColor"})
    wndCastbar:FindChild("BarColorSetting"):FindChild("ColorText"):SetText(self.config.castbar.barColor or "")
    wndCastbar:FindChild("BarColorSetting"):FindChild("BG"):SetBGColor(self.config.castbar.barColor)

    -- MoO Color
    wndCastbar:FindChild("MooColorSetting"):FindChild("Color"):SetData({"castbar","mooColor"})
    wndCastbar:FindChild("MooColorSetting"):FindChild("ColorText"):SetText(self.config.castbar.mooColor or "")
    wndCastbar:FindChild("MooColorSetting"):FindChild("BG"):SetBGColor(self.config.castbar.mooColor)

    -- Text Color
    wndCastbar:FindChild("TextColorSetting"):FindChild("Color"):SetData({"castbar","textColor"})
    wndCastbar:FindChild("TextColorSetting"):FindChild("ColorText"):SetText(self.config.castbar.textColor or "")
    wndCastbar:FindChild("TextColorSetting"):FindChild("BG"):SetBGColor(self.config.castbar.textColor)

    -- #########################################################################################################################################
    -- # CASTBAR
    -- #########################################################################################################################################

    local wndTimer = self.wndSettings:FindChild("Global"):FindChild("Timer")

    -- Bar Color
    wndTimer:FindChild("BarColorSetting"):FindChild("Color"):SetData({"timer","barColor"})
    wndTimer:FindChild("BarColorSetting"):FindChild("ColorText"):SetText(self.config.timer.barColor or "")
    wndTimer:FindChild("BarColorSetting"):FindChild("BG"):SetBGColor(self.config.timer.barColor)

    -- Text Color
    wndTimer:FindChild("TextColorSetting"):FindChild("Color"):SetData({"timer","textColor"})
    wndTimer:FindChild("TextColorSetting"):FindChild("ColorText"):SetText(self.config.timer.textColor or "")
    wndTimer:FindChild("TextColorSetting"):FindChild("BG"):SetBGColor(self.config.timer.textColor)

    -- Bar Height
    wndTimer:FindChild("BarHeightSetting"):FindChild("Slider"):SetData({"timer","barHeight"})
    wndTimer:FindChild("BarHeightSetting"):FindChild("Slider"):SetValue(self.config.timer.barHeight or 0)
    wndTimer:FindChild("BarHeightSetting"):FindChild("SliderText"):SetText(self.config.timer.barHeight or 0)

end

function Settings:BuildSoundDropdown(wnd,setting,value)
    if not wnd or not setting then
        return
    end

    local currentTrigger = 0
    local triggerCount = #self.soundFiles

    wnd:FindChild("ChoiceContainer"):DestroyChildren()

    for idx,fileName in ipairs(self.soundFiles) do
        currentTrigger = currentTrigger + 1
        local item = "Items:Dropdown:MidItem"
        local offset = 30 * (currentTrigger -1)

        if triggerCount > 1 then
            if currentTrigger == 1 then
                item = "Items:Dropdown:TopItem"
            elseif currentTrigger == triggerCount then
                item = "Items:Dropdown:BottomItem"
            end
        else
            item = "Items:Dropdown:SingleItem"
        end

        local wndItem = Apollo.LoadForm(self.xmlDoc, item, wnd:FindChild("ChoiceContainer"), self)
        wndItem:SetText(fileName)
        wndItem:SetCheck(fileName == value)
        wndItem:SetAnchorOffsets(42,49 + offset,-44,81 + offset)
        wndItem:AddEventHandler("ButtonCheck", "OnSoundChoose", self)
    end

    wnd:FindChild("Dropdown"):AttachWindow(wnd:FindChild("ChoiceContainer"))
    wnd:FindChild("Dropdown"):SetText(value or "Choose")
    wnd:FindChild("Dropdown"):SetData(setting)
    wnd:FindChild("ChoiceContainer"):SetAnchorOffsets(-19,-25,350,77 + (triggerCount * 30))
    wnd:FindChild("ChoiceContainer"):Show(false)
end

function Settings:OnTextChange(wndHandler, wndControl)
    local setting = wndControl:GetData()
    local value = wndHandler:GetText()

    if type(setting) == "string" then
        self.config[setting] = value
    elseif type(setting) == "table" then
        self.config[setting[1]][setting[2]] = value
    end
end

function Settings:OnDropdownToggle(wndHandler, wndControl)
    if wndHandler ~= wndControl then
        return
    end

    wndControl:FindChild("ChoiceContainer"):Show(wndControl:IsChecked())
end

function Settings:OnSoundChoose(wndHandler, wndControl)
    local dropdown = wndControl:GetParent():GetParent()
    local setting = dropdown:GetData()
    local value = wndControl:GetText()

    dropdown:SetText(wndControl:GetText())
    wndControl:GetParent():Close()

    if self.current.encounter and self.core.modules[self.current.encounter] then
        if type(setting) == "string" then
            self.core.modules[self.current.encounter].config[setting] = value
        elseif type(setting) == "table" then
            if self.core.modules[self.current.encounter].config[setting[1]] ~= nil then
                self.core.modules[self.current.encounter].config[setting[1]][setting[2]] = value
            end
        end
    end

    if value and value ~= "None" then
        self.core:PlaySound(value)
    end
end

function Settings:OnDropdownChoose(wndHandler, wndControl)
    local dropdown = wndControl:GetParent():GetParent()
    local setting = dropdown:GetData()
    local value = wndControl:GetName()

    dropdown:SetText(wndControl:GetText())
    wndControl:GetParent():Close()

    if type(setting) == "string" then
        self.config[setting] = value
    elseif type(setting) == "table" then
        self.config[setting[1]][setting[2]] = value
    end
end

function Settings:OnSliderChange(wndHandler, wndControl)
    local setting = wndControl:GetData()
    local value = wndHandler:GetValue()

    if value ~= math.floor(value) then
        value = self.core:Round(value,2)
    end

    wndControl:GetParent():FindChild("SliderText"):SetText(value)

    if type(setting) == "string" then
        self.config[setting] = value
    elseif type(setting) == "table" then
        self.config[setting[1]][setting[2]] = value
    end
end

function Settings:OnCheckbox(wndHandler, wndControl)
    local setting = wndControl:GetData()
    local value = wndHandler:IsChecked()

    if type(setting) == "string" then
        self.config[setting] = value
    elseif type(setting) == "table" then
        self.config[setting[1]][setting[2]] = value

        if setting[1] == "sound" and setting[2] == "force" then
            self:ToggleSettings(wndControl:GetParent():GetParent():FindChild("Container"),(self.config.sound.enable and self.config.sound.force) or false)
        elseif setting[1] == "sound" and setting[2] == "enable" then
            self:ToggleSettings(wndControl:GetParent():FindChild("ForceCheckbox"),value)
        elseif setting[1] == "units" and setting[2] == "enable" then
            self:ToggleSettings(wndControl:GetParent():GetParent():FindChild("Container"),value)
        else
            if wndControl:GetName() == "EnableCheckbox" then
                self:ToggleSettings(wndControl:GetParent():GetParent(),value)
            end
        end
    end
end

function Settings:OnBtnChooseColor(wndHandler, wndControl)
    local setting = wndControl:GetParent():GetData()

    if type(setting) == "string" then
        setting = self.config[setting]
    elseif type(setting) == "table" then
        setting = self.config[setting[1]][setting[2]]
    end

    GeminiColor:ShowColorPicker(self, {
        callback = "OnColorPicker",
        strInitialColor = setting,
        bCustomColor = true,
        bAlpha = true
    }, wndControl)
end

function Settings:OnColorPicker(wndHandler, wndControl)
    if not wndHandler then
        return
    end

    local setting = wndControl:GetParent():GetData()
    local sColor

    if type(wndHandler) == "string" then
        sColor = wndHandler
    elseif type(wndHandler) == "userdata" then
        sColor = wndHandler:GetText()
    end

    if string.len(sColor) ~= 8 then
        return
    end

    wndControl:GetParent():FindChild("BG"):SetBGColor(sColor)
    wndControl:GetParent():FindChild("ColorText"):SetText(sColor)

    if type(setting) == "string" then
        self.config[setting] = sColor
    elseif type(setting) == "table" then
        self.config[setting[1]][setting[2]] = sColor
    end
end

function Settings:ToggleSettings(wnd,state,bIsChild)
    local enable = (state ~= nil and state == true) and true or false
    local opacity = enable == true and 1 or 0.5

    if bIsChild and
        wnd:GetName() ~= "Frame" and
        wnd:GetName() ~= "Config" and
        wnd:GetName() ~= "Container" and
        wnd:GetName() ~= "EnableCheckbox"
    then
        wnd:Enable(state)

        if enable == false and wnd:IsStyleOn("BlockOutIfDisabled") then
            wnd:SetStyle("BlockOutIfDisabled",false)
            wnd:SetOpacity(opacity)
        end

        if enable == true and wnd:GetOpacity() == 0.5 then
            wnd:SetStyle("BlockOutIfDisabled",true)
            wnd:SetOpacity(opacity)
        end
    end

    if #wnd:GetChildren() > 0 then
        for _,child in pairs(wnd:GetChildren()) do
            self:ToggleSettings(child,state,true)
        end
    end
end

function Settings:OnDonate(wndHandler, wndControl)
    self.wndSettings:FindChild("DonateSeperator"):Show(wndHandler:IsChecked(),true)
    self.wndSettings:FindChild("DonateForm"):Show(wndHandler:IsChecked(),true)
end

function Settings:OnDonationChanged(wndHandler, wndControl)
    local amount = self.wndSettings:FindChild("DonateForm"):FindChild("CashWindow"):GetAmount()
    local recipient = "Loui NaN"

    if GameLib.GetPlayerUnit():GetFaction() ~= 166 then
        recipient = "Loui x"
    end

    if amount > 0 then
        self.wndSettings:FindChild("DonateForm"):FindChild("DonateSendBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.SendMail, recipient, "Jabbit", "LUI BossMods Donation", tostring(GameLib.GetPlayerUnit():GetName()) .. " donated something for you!", nil, MailSystemLib.MailDeliverySpeed_Instant, 0, self.wndSettings:FindChild("DonateForm"):FindChild("CashWindow"):GetCurrency())
        self.wndSettings:FindChild("DonateForm"):FindChild("DonateSendBtn"):Enable(true)
    else
        self.wndSettings:FindChild("DonateForm"):FindChild("DonateSendBtn"):Enable(false)
    end
end

function Settings:OnDonationSent()
    self.wndSettings:FindChild("DonateBtn"):SetCheck(false)
    self.wndSettings:FindChild("DonateForm"):Show(false)
    self.wndSettings:FindChild("DonateSeperator"):Show(false)
    self.wndSettings:FindChild("DonateForm"):FindChild("CashWindow"):SetAmount(0)
    self.wndSettings:FindChild("DonateForm"):FindChild("DonateSendBtn"):Enable(false)
    self.core:Print("Thank you very much!!! <3")
end

function Settings:OnToggleMenu()
    if self.wndSettings then
        if self.wndSettings:IsShown() then
            self.wndSettings:Close()
        else
            self.wndSettings:Invoke()
        end
    else
        self:OnLoad()
    end
end

function Settings:OnResetBtn(wndHandler, wndControl)
    if wndHandler ~= wndControl then
        return
    end

    self.core:OnRestoreDefaults()
end

function Settings:OnUnlockBtn(wndHandler, wndControl)
    if wndHandler ~= wndControl then
        return
    end

    self:OnToggleMenu()
    self:OnLock(true)
end

function Settings:OnLockBtn(wndHandler, wndControl)
    if wndHandler ~= wndControl then
        return
    end

    self:OnLock(false)
end

function Settings:OnLock(state)
    if not self.core then
        return
    end

    if self.core.wndTimers then
        self.core.wndTimers:SetStyle("Moveable", state)
        self.core.wndTimers:SetStyle("Sizable", state)
        self.core.wndTimers:SetStyle("Picture", state)
        self.core.wndTimers:SetStyle("IgnoreMouse", not state)
        self.core.wndTimers:SetText(state == true and "TIMER" or "")

        if state == true or not self.core.bIsRunning == true then
            self.core.wndTimers:Show(state,true)
        end
    end

    if self.core.wndUnits then
        self.core.wndUnits:SetStyle("Moveable", state)
        self.core.wndUnits:SetStyle("Sizable", state)
        self.core.wndUnits:SetStyle("Picture", state)
        self.core.wndUnits:SetStyle("IgnoreMouse", not state)
        self.core.wndUnits:SetText(state == true and "UNITS" or "")

        if state == true or not self.core.bIsRunning == true then
            self.core.wndUnits:Show(state,true)
        end
    end

    if self.core.wndCastbar then
        self.core.wndCastbar:SetStyle("Moveable", state)
        self.core.wndCastbar:SetStyle("Sizable", state)
        self.core.wndCastbar:SetStyle("Picture", state)
        self.core.wndCastbar:SetStyle("IgnoreMouse", not state)
        self.core.wndCastbar:FindChild("Container"):Show(not state,true)
        self.core.wndCastbar:SetText(state == true and "CASTBAR" or "")

        if state == true or not self.core.bIsRunning == true then
            self.core.wndCastbar:Show(state,true)
        end
    end

    if self.core.wndAura then
        self.core.wndAura:SetStyle("Moveable", state)
        self.core.wndAura:SetStyle("Sizable", state)
        self.core.wndAura:SetStyle("Picture", state)
        self.core.wndAura:SetStyle("IgnoreMouse", not state)
        self.core.wndAura:FindChild("Icon"):Show(not state,true)
        self.core.wndAura:SetText(state == true and "AURA" or "")

        if state == true or not self.core.bIsRunning == true then
            self.core.wndAura:Show(state,true)
        end
    end

    if self.core.wndAlerts then
        self.core.wndAlerts:SetStyle("Moveable", state)
        self.core.wndAlerts:SetStyle("Sizable", state)
        self.core.wndAlerts:SetStyle("Picture", state)
        self.core.wndAlerts:SetStyle("IgnoreMouse", not state)
        self.core.wndAlerts:SetText(state == true and "ALERTS" or "")

        if state == true or not self.core.bIsRunning == true then
            self.core.wndAlerts:Show(state,true)
        end
    end

    if state == true then
        self.wndLock = Apollo.LoadForm(self.xmlDoc, "Lock", nil, self)
        self.wndLock:Show(true,true)
    else
        if self.wndLock then
            self.wndLock:Destroy()
        end
    end
end

function Settings:OnSettings(wndHandler, wndControl)
    local value = wndHandler:IsChecked()

    self.wndSettings:FindChild("Global"):Show(value,true)
    self.wndSettings:FindChild("Main"):Show(not value,true)

    self.wndSettings:FindChild("BGHolo_Full"):Show(value,true)
    self.wndSettings:FindChild("BGHolo_Left"):Show(not value,true)
    self.wndSettings:FindChild("BGHolo_Right"):Show(not value,true)

    self.bIsGlobal = value
end

function Settings:OnWindowChanged(wndHandler, wndControl)
    if wndHandler ~= wndControl then
        return
    end

    local nLeft, nTop, nRight, nBottom = wndControl:GetAnchorOffsets()

    if self.config.settings.offsets then
        self.config.settings.offsets = {
            left = nLeft,
            top = nTop,
            right = nRight,
            bottom = nBottom,
        }
    end
end

local SettingsInst = Settings:new()
LUI_BossMods.settings = SettingsInst
