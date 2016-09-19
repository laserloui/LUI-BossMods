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
    self.soundFiles = {"alarm","alert","info","long","interrupt","run-away","beware","burn","destruction","inferno"}
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

    wndMeasure = Apollo.LoadForm(self.xmlDoc, "Navigation:Miniboss", nil, self)
    self.nMinibossButtonHeight = wndMeasure:GetHeight()
    wndMeasure:Destroy()

    self:BuildTree()
    self:BuildGlobalSettings()
end

function Settings:BuildTree()
    local wndLeftScroll = self.wndSettings:FindChild("LeftScroll")
    wndLeftScroll:DestroyChildren()

    local instances = {}

    for sName,mod in pairs(self.core.modules) do
        if mod then
            if not instances[mod.instance] then
                instances[mod.instance] = {}
            end

            if mod.groupName then
                if not instances[mod.instance][mod.groupName] then
                    instances[mod.instance][mod.groupName] = {}
                end

                instances[mod.instance][mod.groupName][mod.displayName] = sName
            else
                instances[mod.instance][mod.displayName] = sName
            end
        end
    end

    for strInstance,tBosses in self.core:Sort(instances) do
        local wndInstance = Apollo.LoadForm(self.xmlDoc, "Navigation:Instance", wndLeftScroll, self)
        local wndInstanceContents = wndInstance:FindChild("GroupContents")

        for strEncounter,strModule in self.core:Sort(tBosses) do
            local wndEncounter = Apollo.LoadForm(self.xmlDoc, "Navigation:Encounter", wndInstanceContents, self)
            local wndEncounterContents = wndEncounter:FindChild("GroupContents")
            wndEncounter:SetData(strModule)

            if type(strModule) == "table" then
                for strMiniboss, strMiniModule in self.core:Sort(strModule) do
    				local wndMiniboss = Apollo.LoadForm(self.xmlDoc, "Navigation:Miniboss", wndEncounterContents, self)
    				wndMiniboss:SetData(strMiniModule)

                    local wndMinibossBtn = wndMiniboss:FindChild("MinibossBtn")
                    wndMinibossBtn:SetData({instance = strInstance, encounter = strMiniModule, btn = wndMinibossBtn})
                    wndMinibossBtn:SetText(strMiniboss)
                end
            end

            local bEncounterHasChildren = #wndEncounterContents:GetChildren() > 0
            wndEncounterContents:ArrangeChildrenVert(0)

            local wndEncounterBtn = wndEncounter:FindChild("EncounterBtn")
            wndEncounterBtn:SetText(strEncounter)

            if bEncounterHasChildren == true then
                wndEncounterBtn:RemoveEventHandler("ButtonCheck")
                wndEncounterBtn:RemoveEventHandler("ButtonUncheck")
                wndEncounterBtn:AddEventHandler("ButtonCheck", "OnInstanceBtn", self)
                wndEncounterBtn:AddEventHandler("ButtonUncheck", "OnInstanceBtn", self)
                wndEncounterBtn:ChangeArt("BK3:btnMetal_ExpandMenu_Med")
                wndEncounterBtn:SetData(strEncounter)
            else
                wndEncounterBtn:ChangeArt("BK3:btnMetal_ExpandMenu_MedClean")
                wndEncounterBtn:SetData({instance = strInstance, encounter = strModule, btn = wndEncounterBtn})
            end
        end

        local wndInstanceBtn = wndInstance:FindChild("InstanceBtn")
        wndInstanceBtn:SetData(strInstance)
        wndInstanceBtn:SetText(strInstance)

        wndInstanceContents:ArrangeChildrenVert(0)
    end

    self:ResizeTree()
end

function Settings:ResizeTree()
    local wndLeftScroll = self.wndSettings:FindChild("LeftScroll")
    local nVScrollPos = wndLeftScroll:GetVScrollPos()

    for _,wndInstance in pairs(wndLeftScroll:GetChildren()) do
        local wndInstanceContents = wndInstance:FindChild("GroupContents")
        local wndInstanceBtn = wndInstance:FindChild("InstanceBtn")
        local nInstanceHeight = 0

        if wndInstanceBtn:IsChecked() then
            for _,wndEncounter in pairs(wndInstanceContents:GetChildren()) do
                local wndEncounterContents = wndEncounter:FindChild("GroupContents")
				local wndEncounterBtn = wndEncounter:FindChild("EncounterBtn")
                local bEncounterHasChildren = #wndEncounterContents:GetChildren() > 0
				local nEncounterHeight = 2

                if bEncounterHasChildren and wndEncounterBtn:IsChecked() then
                    for _,wndMiniboss in pairs(wndEncounterContents:GetChildren()) do
                        nEncounterHeight = nEncounterHeight + self.nMinibossButtonHeight
                    end
                end

                local nLeft, nTop, nRight = wndEncounter:GetAnchorOffsets()
				wndEncounter:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nEncounterHeight + self.nEncounterButtonHeight)
				wndEncounterContents:ArrangeChildrenVert(0)
                wndEncounterContents:Show(wndEncounterBtn:IsChecked() and bEncounterHasChildren,true)

                nInstanceHeight = nInstanceHeight + nEncounterHeight + self.nEncounterButtonHeight
            end

            if nInstanceHeight > 0 then
				nInstanceHeight = nInstanceHeight + 14
			end

			wndInstance:FindChild("Divider"):Show(nInstanceHeight > 0,true)
        end

        local nLeft, nTop, nRight = wndInstance:GetAnchorOffsets()
        wndInstance:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nInstanceHeight + self.nInstanceButtonHeight)
        wndInstanceContents:ArrangeChildrenVert(0)
        wndInstanceContents:Show(wndInstanceBtn:IsChecked(),true)
    end

    wndLeftScroll:ArrangeChildrenVert(0)
    wndLeftScroll:SetVScrollPos(nVScrollPos)
end

function Settings:OnInstanceBtn(wndHandler, wndControl)
    if wndHandler ~= wndControl then
        return
    end

    if self.current then
        self.current.btn:SetCheck(false)
        self.current = nil
        self.wndSettings:FindChild("RightScroll"):DestroyChildren()
        self.wndSettings:FindChild("RightScroll"):RecalculateContentExtents()
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

    if self.wndRight then
        self.wndRight:DestroyChildren()
    else
        self.wndRight = self.wndSettings:FindChild("RightScroll")
    end

    local module = self.core.modules[self.current.encounter]

    if not module then
        return
    end

    local config = module.config
    local L = module.L

    if not config then
        return
    end

    -- #########################################################################################################################################
    -- # GENERAL
    -- #########################################################################################################################################


    -- #########################################################################################################################################
    -- # UNITS
    -- #########################################################################################################################################

    if config.units ~= nil then
        local wndUnits = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
        wndUnits:FindChild("Label"):SetText("Units")
        wndUnits:FindChild("Settings"):SetStyle("Picture",true)

        local tSortedUnits = {}
        local nHeight = 84

        for nId,unit in pairs(config.units) do
            tSortedUnits[#tSortedUnits+1] = {
                nId = nId,
                priority = unit.priority or 0
            }
        end

        table.sort(tSortedUnits, function(a, b)
            return a.priority < b.priority
        end)

        for i=1,#tSortedUnits do
            local tUnit = config.units[tSortedUnits[i].nId]
            local wnd = Apollo.LoadForm(self.xmlDoc, "Items:UnitSetting", wndUnits:FindChild("Settings"), self)

            -- Enable Checkbox
            wnd:FindChild("Checkbox"):SetData({"units",tSortedUnits[i].nId,"enable"})
            wnd:FindChild("Checkbox"):SetCheck(tUnit.enable or false)
            wnd:FindChild("Checkbox"):SetText(L[tUnit.label] or tUnit.label)

            -- Color
            wnd:FindChild("Color"):SetData({"units",tSortedUnits[i].nId,"color"})
            wnd:FindChild("ColorText"):SetText(tUnit.color or self.config.units.healthColor)
            wnd:FindChild("BG"):SetBGColor(tUnit.color or self.config.units.healthColor)

            nHeight = nHeight + wnd:GetHeight()
        end

        local wndItem = wndUnits:FindChild("Settings"):GetChildren()

        if #wndItem > 0 then
            wndItem[1]:SetAnchorOffsets(5,0,-5,63)
            wndItem[1]:FindChild("Wrapper"):SetAnchorOffsets(0,7,0,0)
            wndItem[#wndItem]:FindChild("Divider"):Show(false,true)
        end

        wndUnits:FindChild("Settings"):ArrangeChildrenVert()
        wndUnits:SetAnchorOffsets(0,0,0,nHeight)
    end

    -- #########################################################################################################################################
    -- # TIMERS
    -- #########################################################################################################################################

    if config.timers ~= nil then
        local wndTimers = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
        wndTimers:FindChild("Label"):SetText("Timers")
        wndTimers:FindChild("Settings"):SetStyle("Picture",true)

        local nHeight = 84

        for id,timer in pairs(config.timers) do
            local wnd = Apollo.LoadForm(self.xmlDoc, "Items:TimerSetting", wndTimers:FindChild("Settings"), self)

            -- Enable Checkbox
            wnd:FindChild("Checkbox"):SetData({"timers",id,"enable"})
            wnd:FindChild("Checkbox"):SetCheck(timer.enable or false)
            wnd:FindChild("Checkbox"):SetText(L[timer.label] or timer.label)

            -- Color
            wnd:FindChild("Color"):SetData({"timers",id,"color"})
            wnd:FindChild("ColorText"):SetText(timer.color or self.config.timer.barColor)
            wnd:FindChild("BG"):SetBGColor(timer.color or self.config.timer.barColor)

            nHeight = nHeight + wnd:GetHeight()
        end

        local wndItem = wndTimers:FindChild("Settings"):GetChildren()

        if #wndItem > 0 then
            wndItem[1]:SetAnchorOffsets(5,0,-5,63)
            wndItem[1]:FindChild("Wrapper"):SetAnchorOffsets(0,7,0,0)
            wndItem[#wndItem]:FindChild("Divider"):Show(false,true)
        end

        wndTimers:FindChild("Settings"):ArrangeChildrenVert()
        wndTimers:SetAnchorOffsets(0,0,0,nHeight)
    end

    -- #########################################################################################################################################
    -- # ALERTS
    -- #########################################################################################################################################

    if config.alerts ~= nil then
        local wndAlerts = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
        wndAlerts:FindChild("Label"):SetText("Alerts")
        wndAlerts:FindChild("Settings"):SetStyle("Picture",true)

        local nHeight = 84

        for id,alert in pairs(config.alerts) do
            local wnd = Apollo.LoadForm(self.xmlDoc, "Items:AlertSetting", wndAlerts:FindChild("Settings"), self)

            -- Enable Checkbox
            wnd:FindChild("Checkbox"):SetData({"alerts",id,"enable"})
            wnd:FindChild("Checkbox"):SetCheck(alert.enable or false)
            wnd:FindChild("Checkbox"):SetText(L[alert.label] or alert.label)

            -- Color
            wnd:FindChild("Color"):SetData({"alerts",id,"color"})
            wnd:FindChild("ColorText"):SetText(alert.color or self.config.alerts.color)
            wnd:FindChild("BG"):SetBGColor(alert.color or self.config.alerts.color)

            nHeight = nHeight + wnd:GetHeight()
        end

        local wndItem = wndAlerts:FindChild("Settings"):GetChildren()

        if #wndItem > 0 then
            wndItem[1]:SetAnchorOffsets(5,0,-5,63)
            wndItem[1]:FindChild("Wrapper"):SetAnchorOffsets(0,7,0,0)
            wndItem[#wndItem]:FindChild("Divider"):Show(false,true)
        end

        wndAlerts:FindChild("Settings"):ArrangeChildrenVert()
        wndAlerts:SetAnchorOffsets(0,0,0,nHeight)
    end

    -- #########################################################################################################################################
    -- # SOUNDS
    -- #########################################################################################################################################

    if config.sounds ~= nil then
        local wndSounds = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
        wndSounds:FindChild("Label"):SetText("Sounds")
        wndSounds:FindChild("Settings"):SetStyle("Picture",true)

        local nHeight = 84

        for id,sound in pairs(config.sounds) do
            local wnd = Apollo.LoadForm(self.xmlDoc, "Items:SoundSetting", wndSounds:FindChild("Settings"), self)

            -- Enable Checkbox
            wnd:FindChild("Checkbox"):SetData({"sounds",id,"enable"})
            wnd:FindChild("Checkbox"):SetCheck(sound.enable or false)
            wnd:FindChild("Checkbox"):SetText(L[sound.label] or sound.label)

            -- Sound File
            self:BuildSoundDropdown(wnd,{"sounds",id,"file"},sound.file)

            nHeight = nHeight + wnd:GetHeight()
        end

        local wndItem = wndSounds:FindChild("Settings"):GetChildren()

        if #wndItem > 0 then
            wndItem[1]:SetAnchorOffsets(5,0,-5,63)
            wndItem[1]:FindChild("Wrapper"):SetAnchorOffsets(0,7,0,0)
            wndItem[#wndItem]:FindChild("Divider"):Show(false,true)
        end

        wndSounds:FindChild("Settings"):ArrangeChildrenVert()
        wndSounds:SetAnchorOffsets(0,0,0,nHeight)
    end

    -- #########################################################################################################################################
    -- # ICONS
    -- #########################################################################################################################################

    if config.icons ~= nil then
        local wndIcons = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
        wndIcons:FindChild("Label"):SetText("Icons")

        local nHeight = 75

        for id,icon in pairs(config.icons) do
            local wnd = Apollo.LoadForm(self.xmlDoc, "Items:IconSetting", wndIcons:FindChild("Settings"), self)

            -- Label
            wnd:FindChild("Label"):SetText(L[icon.label] or icon.label)

            -- Enable Checkbox
            wnd:FindChild("Checkbox"):SetData({"icons",id,"enable"})
            wnd:FindChild("Checkbox"):SetCheck(icon.enable or false)

            -- Sprite
            wnd:FindChild("SpriteText"):SetText(icon.sprite or self.config.icon.sprite)
        	wnd:FindChild("SpriteText"):SetData({"icons",id,"sprite"})

            wnd:FindChild("SpriteText"):SetStyle("BlockOutIfDisabled",false)
            wnd:FindChild("SpriteText"):SetOpacity(0.5)
            wnd:FindChild("SpriteText"):Enable(false)
            wnd:FindChild("BrowseBtn"):Enable(false)

            -- Color
            wnd:FindChild("Color"):SetData({"icons",id,"color"})
            wnd:FindChild("ColorText"):SetText(icon.color or self.config.icon.color)
            wnd:FindChild("Color"):FindChild("BG"):SetBGColor(icon.color or self.config.icon.color)

            -- Size
            wnd:FindChild("Slider"):SetData({"icons",id,"size"})
            wnd:FindChild("Slider"):SetValue(icon.size or self.config.icon.size)
            wnd:FindChild("SliderText"):SetText(icon.size or self.config.icon.size)

            nHeight = nHeight + wnd:GetHeight()
        end

        wndIcons:FindChild("Settings"):ArrangeChildrenVert()
        wndIcons:SetAnchorOffsets(0,0,0,(nHeight-10))
    end

    -- #########################################################################################################################################
    -- # LINES
    -- #########################################################################################################################################

    if config.lines ~= nil then
        local wndLines = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
        wndLines:FindChild("Label"):SetText("Lines")

        local nHeight = 75

        for id,line in pairs(config.lines) do
            local wnd = Apollo.LoadForm(self.xmlDoc, "Items:LineSetting", wndLines:FindChild("Settings"), self)

            -- Label
            wnd:FindChild("Label"):SetText(L[line.label] or line.label)

            -- Enable Checkbox
            wnd:FindChild("Checkbox"):SetData({"lines",id,"enable"})
            wnd:FindChild("Checkbox"):SetCheck(line.enable or false)

            -- Color
            wnd:FindChild("Color"):SetData({"lines",id,"color"})
            wnd:FindChild("ColorText"):SetText(line.color or self.config.line.color)
            wnd:FindChild("Color"):FindChild("BG"):SetBGColor(line.color or self.config.line.color)

            -- Thickness
            wnd:FindChild("Slider"):SetData({"lines",id,"thickness"})
            wnd:FindChild("Slider"):SetValue(line.thickness or self.config.line.thickness)
            wnd:FindChild("SliderText"):SetText(line.thickness or self.config.line.thickness)

            nHeight = nHeight + wnd:GetHeight()
        end

        wndLines:FindChild("Settings"):ArrangeChildrenVert()
        wndLines:SetAnchorOffsets(0,0,0,(nHeight-10))
    end

    local wndContainer = self.wndRight:GetChildren()

    if #wndContainer > 0 then
        wndContainer[#wndContainer]:FindChild("Frame"):SetAnchorOffsets(0,0,0,0)
        wndContainer[#wndContainer]:SetAnchorOffsets(0,0,0,(wndContainer[#wndContainer]:GetHeight() - 10))
    end

    self.wndRight:ArrangeChildrenVert()
    self.wndRight:RecalculateContentExtents()
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
    wnd:FindChild("Dropdown"):SetText(value or "")
    wnd:FindChild("Dropdown"):SetData(setting)
    wnd:FindChild("ChoiceContainer"):SetAnchorOffsets(-19,-25,350,77 + (triggerCount * 30))
    wnd:FindChild("ChoiceContainer"):Show(false)
end

function Settings:OnTextChange(wndHandler, wndControl)
    local setting = wndControl:GetData()
    local value = wndHandler:GetText()
    self:SetVar(setting,value)
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
    self:SetVar(setting,value)

    if value then
        self.core:PlaySound(value)
    end
end

function Settings:OnDropdownChoose(wndHandler, wndControl)
    local dropdown = wndControl:GetParent():GetParent()
    local setting = dropdown:GetData()
    local value = wndControl:GetName()

    dropdown:SetText(wndControl:GetText())
    wndControl:GetParent():Close()
    self:SetVar(setting,value)
end

function Settings:OnSliderChange(wndHandler, wndControl)
    local setting = wndControl:GetData()
    local value = wndHandler:GetValue()

    if value ~= math.floor(value) then
        value = self.core:Round(value,2)
    end

    wndControl:GetParent():FindChild("SliderText"):SetText(value)
    self:SetVar(setting,value)
end

function Settings:OnCheckbox(wndHandler, wndControl)
    local setting = wndControl:GetData()
    local value = wndHandler:IsChecked()

    self:SetVar(setting,value)

    if type(setting) == "table" then
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
    setting = self:GetVar(setting)

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

    self:SetVar(setting,sColor)
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
    self.wndSettings:FindChild("Navigation"):Show(not value,true)

    self.wndSettings:FindChild("BGHolo_Full"):Show(value,true)
    self.wndSettings:FindChild("BGHolo"):Show(not value,true)

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

function Settings:GetVar(setting)
    if not setting then
        return
    end

    if self.bIsGlobal then
        if type(setting) == "string" then
            return self.config[setting]
        elseif type(setting) == "table" then
            if #setting == 3 then
                if self.config[setting[1]] and self.config[setting[1]][setting[2]] then
                    return self.config[setting[1]][setting[2]][setting[3]]
                end
            else
                if self.config[setting[1]] then
                    return self.config[setting[1]][setting[2]]
                end
            end
        end
    else
        if not self.current or not self.current.encounter then
            return
        end

        local config = self.core.modules[self.current.encounter].config

        if not config then
            return
        end

        if type(setting) == "string" then
            return config[setting]
        elseif type(setting) == "table" then
            if #setting == 3 then
                if config[setting[1]] and config[setting[1]][setting[2]] then
                    return config[setting[1]][setting[2]][setting[3]]
                end
            else
                if config[setting[1]] then
                    return config[setting[1]][setting[2]]
                end
            end
        end
    end
end

function Settings:SetVar(setting,value)
    if not setting then
        return
    end

    if self.bIsGlobal then
        if type(setting) == "string" then
            self.config[setting] = value
        elseif type(setting) == "table" then
            if #setting == 3 then
                if self.config[setting[1]] and self.config[setting[1]][setting[2]] then
                    self.config[setting[1]][setting[2]][setting[3]] = value
                end
            else
                if self.config[setting[1]] then
                    self.config[setting[1]][setting[2]] = value
                end
            end
        end
    else
        if not self.current or not self.current.encounter then
            return
        end

        local config = self.core.modules[self.current.encounter].config

        if not config then
            return
        end

        if type(setting) == "string" then
            config[setting] = value
        elseif type(setting) == "table" then
            if #setting == 3 then
                if config[setting[1]] and config[setting[1]][setting[2]] then
                    config[setting[1]][setting[2]][setting[3]] = value
                end
            else
                if config[setting[1]] then
                    config[setting[1]][setting[2]] = value
                end
            end
        end
    end
end

local SettingsInst = Settings:new()
LUI_BossMods.settings = SettingsInst
