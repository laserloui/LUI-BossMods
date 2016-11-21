require "Window"
require "Apollo"

local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local GeminiColor = Apollo.GetPackage("GeminiColor").tPackage

local Settings = {}
local Locales = {
    ["enUS"] = {
        -- Headers
        ["header.general"] = "General",
        ["header.units"] = "Units",
        ["header.timers"] = "Timers",
        ["header.casts"] = "Casts",
        ["header.alerts"] = "Alerts",
        ["header.sounds"] = "Sounds",
        ["header.icons"] = "Icons",
        ["header.auras"] = "Auras",
        ["header.texts"] = "Texts",
        ["header.lines"] = "Lines",
        ["header.castbar"] = "Castbar",
        ["header.sprites"] = "Sprites",
        ["header.fonts"] = "Fonts",
        ["header.focus"] = "Focus Target",
        ["header.telegraph"] = "Telegraphs",
        -- Labels
        ["label.enable_module"] = "Enable Boss Module",
        ["label.enable"] = "Enable",
        ["label.interval"] = "Update Interval",
        ["label.thickness"] = "Thickness",
        ["label.color"] = "Color",
        ["label.size"] = "Size",
        ["label.line"] = "Line",
        ["label.icon"] = "Icon",
        -- Units
        ["global.show_text"] = "Show Absorb/Shield Text",
        ["global.health_color"] = "Health Color",
        ["global.shield_color"] = "Shield Color",
        ["global.absorb_color"] = "Absorb Color",
        ["global.cast_color"] = "Cast Color",
        ["global.moo_color"] = "MOO Color",
        ["global.text_color"] = "Text Color",
        ["global.bar_color"] = "Bar Color",
        ["global.bar_height"] = "Bar Height",
        ["global.health_height"] = "Health Height",
        ["global.shield_height"] = "Shield Height",
        ["global.font_size"] = "Font size",
        -- Voice
        ["voice.pack"] = "Countdown Voice",
        ["voice.length"] = "Countdown Length",
        ["voice.male"] = "Male",
        ["voice.female"] = "Female",
        ["voice.short"] = "Short",
        ["voice.short_skip"] = "Short (skip zero)",
        ["voice.long"] = "Long",
        ["voice.long_skip"] = "Long (skip zero)",
        -- Volume
        ["volume.force"] = "Adjust Volume",
        ["volume.master"] = "Master Volume",
        ["volume.music"] = "Music Volume",
        ["volume.ui"] = "UI Sounds Volume",
        ["volume.sfx"] = "Sound FX Volume",
        ["volume.ambient"] = "Ambient Volume",
        ["volume.voice"] = "Voice Volume",
        -- Buttons
        ["button.choose"] = "Choose",
        ["button.browse"] = "Browse",
        ["button.unlock"] = "Unlock Frames",
        ["button.reset"] = "Restore Defaults",
        ["button.reset_module"] = "Reset Module",
        -- Tooltips
        ["tooltip.sounds"] = "Enable/Disable all sounds.",
        ["tooltip.sounds_force"] = "Automatically unmute and adjust volume when playing sound.",
        ["tooltip.countdown_alert"] = "Show Countdown Messages?",
        ["tooltip.countdown_sound"] = "Play Countdown Sound?",
        -- Donation
        ["donate.button"] = "Make a donation",
        ["donate.headline"] = "Making this Addon was a lot of work!",
        ["donate.text"] = "Please consider supporting the continued development and maintenance of LUI BossMods with an ingame gold donation. Thank you very much in advance! <3",
        ["donate.submit"] = "Donate",
    },
    ["deDE"] = {
        -- Headers
        ["header.general"] = "Allgemein",
        ["header.units"] = "Units",
        ["header.timers"] = "Timers",
        ["header.casts"] = "Casts",
        ["header.alerts"] = "Warnungen",
        ["header.sounds"] = "Töne",
        ["header.icons"] = "Icons",
        ["header.auras"] = "Auren",
        ["header.texts"] = "Texte",
        ["header.lines"] = "Linien",
        ["header.castbar"] = "Castbar",
        ["header.sprites"] = "Texturen",
        ["header.fonts"] = "Schriftarten",
        ["header.focus"] = "Focus Target",
        ["header.telegraph"] = "Telegraphs",
        -- Labels
        ["label.enable_module"] = "Boss Modul einschalten",
        ["label.enable"] = "Einschalten",
        ["label.interval"] = "Aktualisierungs-Intervall",
        ["label.thickness"] = "Dicke",
        ["label.color"] = "Farbe",
        ["label.size"] = "Größe",
        ["label.line"] = "Linie",
        ["label.icon"] = "Icon",
        -- Units
        ["global.show_text"] = "Zeige Absorb/Schild Text",
        ["global.health_color"] = "Lebensenergie Farbe",
        ["global.shield_color"] = "Schild Farbe",
        ["global.absorb_color"] = "Absorb Farbe",
        ["global.cast_color"] = "Cast Farbe",
        ["global.moo_color"] = "MOO Farbe",
        ["global.text_color"] = "Text Farbe",
        ["global.bar_color"] = "Bar Farbe",
        ["global.bar_height"] = "Bar Höhe",
        ["global.health_height"] = "Lebensenergie Höhe",
        ["global.shield_height"] = "Schild Höhe",
        ["global.font_size"] = "Schriftgröße",
        -- Voice
        ["voice.pack"] = "Countdown Stimme",
        ["voice.length"] = "Countdown Länge",
        ["voice.male"] = "Männlich",
        ["voice.female"] = "Weiblich",
        ["voice.short"] = "Kurz",
        ["voice.short_skip"] = "Kurz (ohne null)",
        ["voice.long"] = "Lang",
        ["voice.long_skip"] = "Lang (ohne null)",
        -- Volume
        ["volume.force"] = "Laustärke anpassen",
        ["volume.master"] = "Gesamtlautstärke",
        ["volume.music"] = "Musiklautstärke",
        ["volume.ui"] = "UI-Soundlautstärke",
        ["volume.sfx"] = "Soundeffektlautstärke",
        ["volume.ambient"] = "Hintergrundlautstärke",
        ["volume.voice"] = "Sprachlautstärke",
        -- Buttons
        ["button.choose"] = "Auswählen",
        ["button.browse"] = "Durchsuchen",
        ["button.unlock"] = "Fenster entsperren",
        ["button.reset"] = "Einstellungen zurücksetzen",
        ["button.reset_module"] = "Modul zurücksetzen",
        -- Tooltips
        ["tooltip.sounds"] = "Alle Töne Ein/Aus",
        ["tooltip.sounds_force"] = "Unmute und automatische Anpassung der Lautstärke wenn Töne abgespielt werden.",
        ["tooltip.countdown_alert"] = "Zeige Countdown Nachrichten?",
        ["tooltip.countdown_sound"] = "Spiele Countdown Töne?",
        -- Donation
        ["donate.button"] = "Mache eine Spende",
        ["donate.headline"] = "Die Entwicklung dieses Addons war eine Menge Arbeit!", "Making this Addon was a lot of work!",
        ["donate.text"] = "Unterstütze die weiterführende Entwicklung und Instandhaltung von LUI BossMods mit einer ingame Gold Spende. Danke vielmals im voraus! <3",
        ["donate.submit"] = "Spenden",
    },
    ["frFR"] = {
        -- Headers
        ["header.general"] = "Général",
        ["header.units"] = "Unités",
        ["header.timers"] = "Timers",
        ["header.casts"] = "Sorts",
        ["header.alerts"] = "Alertes",
        ["header.sounds"] = "Sons",
        ["header.icons"] = "Icones",
        ["header.auras"] = "Auras",
        ["header.texts"] = "Textes",
        ["header.lines"] = "Lignes",
        ["header.castbar"] = "Barre de sorts",
        ["header.sprites"] = "Visuels",
        ["header.fonts"] = "Police",
        ["header.focus"] = "Focus Target",
        ["header.telegraph"] = "Telegraphs",
        -- Labels
        ["label.enable_module"] = "Activer le module du boss",
        ["label.enable"] = "Activer",
        ["label.interval"] = "Interval de mise a jour",
        ["label.thickness"] = "Epaisseur",
        ["label.color"] = "Couelur",
        ["label.size"] = "Taille",
        ["label.line"] = "Ligne",
        ["label.icon"] = "Icone",
        -- Units
        ["global.show_text"] = "Montrer les absorptions/boucliers",
        ["global.health_color"] = "Couleur de la santé",
        ["global.shield_color"] = "Couleur du bouclier",
        ["global.absorb_color"] = "Couleur de l’absorption",
        ["global.cast_color"] = "Couleur du lancement",
        ["global.moo_color"] = "Couleur de la phase d’opportunité",
        ["global.text_color"] = "Couleur du Texte",
        ["global.bar_color"] = "Couleur de la barre",
        ["global.bar_height"] = "Hauteur de la barre",
        ["global.health_height"] = "Hauteur de la santé",
        ["global.shield_height"] = "Hauteur du bouclier",
        ["global.font_size"] = "Taille de police",
        -- Voice
        ["voice.pack"] = "Voice du compte a rebours",
        ["voice.length"] = "Longueur du compte a rebours",
        ["voice.male"] = "Homme",
        ["voice.female"] = "Femme",
        ["voice.short"] = "Court",
        ["voice.short_skip"] = "Ne pas dire zéro",
        ["voice.long"] = "Long",
        ["voice.long_skip"] = "Ne pas dire zéro",
        -- Volume
        ["volume.force"] = "Ajuster le volume",
        ["volume.master"] = "Volume principal",
        ["volume.music"] = "Volume de la musique",
        ["volume.ui"] = "Volume du son IU",
        ["volume.sfx"] = "Volume des effets sonores",
        ["volume.ambient"] = "Volume ambiant",
        ["volume.voice"] = "Volume des voix",
        -- Buttons
        ["button.choose"] = "Choisir",
        ["button.browse"] = "Barcourir",
        ["button.unlock"] = "Débloquer les cadres",
        ["button.reset"] = "Restaurer les paramètres par défauts",
        ["button.reset_module"] = "Reinitialiser le module",
        -- Tooltips
        ["tooltip.sounds"] = "Activer/Désactiver tous les sons",
        ["tooltip.sounds_force"] = "Coupe et ajuste le volume automatiquement lorsque le son est joué.",
        ["tooltip.countdown_alert"] = "Montrer le message du compte à rebours.",
        ["tooltip.countdown_sound"] = "Faire jouer le son du compte à rebours.",
        -- Donation
        ["donate.button"] = "faire un don",
        ["donate.headline"] = "Travailler sur cet addon a demandé beaucoup de travail!",
        ["donate.text"] = "Merci de m’aider à poursuivre le développement et les mises à jour de Lui Bossmod par le biais d’une donation avec l’argent du jeu. Je vous remercie d’avance. <3",
        ["donate.submit"] = "donner",
    },
}

function Settings:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.bIsGlobal = false
    self.tSounds = {
        "alarm",
        "alert",
        "info",
        "long",
        "interrupt",
        "run-away",
        "beware",
        "burn",
        "destruction",
        "inferno"
    }
    self.tSprites = {
        "LUIBM_air",
        "LUIBM_air2",
        "LUIBM_tornado",
        "LUIBM_tornado2",
        "LUIBM_waterdrop",
        "LUIBM_waterdrop2",
        "LUIBM_waterdrop3",
        "LUIBM_wave",
        "LUIBM_twirl",
        "LUIBM_lightning",
        "LUIBM_lightning2",
        "LUIBM_run",
        "LUIBM_detonation",
        "LUIBM_eye",
        "LUIBM_eye2",
        "LUIBM_eye3",
        "LUIBM_crosshair",
        "LUIBM_poo",
        "LUIBM_atom",
        "LUIBM_stop",
        "LUIBM_stop2",
        "LUIBM_sword",
        "LUIBM_sword2",
        "LUIBM_sword3",
        "LUIBM_sword4",
        "LUIBM_axe",
        "LUIBM_axe2",
        "LUIBM_poison",
        "LUIBM_poison2",
        "LUIBM_boots",
        "LUIBM_boots2",
        "LUIBM_diamonds",
        "LUIBM_radioactive",
        "LUIBM_biohazard",
        "LUIBM_bomb",
        "LUIBM_heat",
        "LUIBM_fire",
        "LUIBM_fire2",
        "LUIBM_ifrit",
        "LUIBM_meteor",
        "LUIBM_meteor2",
        "LUIBM_meteor3",
        "LUIBM_meteor4",
        "LUIBM_virus",
        "LUIBM_skull",
        "LUIBM_skull2",
        "LUIBM_skull3",
        "LUIBM_skull4",
        "LUIBM_star",
        "LUIBM_shuriken",
        "LUIBM_granate",
        "LUIBM_pirate",
        "LUIBM_zombiehand",
        "LUIBM_ghost",
        "LUIBM_ghost2",
        "LUIBM_monster",
        "LUIBM_fish",
        "LUIBM_crown",
        "LUIBM_crown2",
        "LUIBM_biceps",
        "LUIBM_claw",
        "LUIBM_shield",
        "LUIBM_helm",
        "LUIBM_aim",
        "LUIBM_tree",
        "LUIBM_team",
        "LUIBM_hand",
        "LUIBM_duality",
        "LUIBM_tentacle",
        "LUIBM_position",
        "LUIBM_minotaur",
        "LUIBM_spider",
        "LUIBM_mushroom",
        "LUIBM_quicksand",
        "LUIBM_serpent",
        "LUIBM_supersonic",
        "LUIBM_voodoo",
    }
    return o
end

function Settings:Init(parent)
    Apollo.LinkAddon(parent, self)

    self.core = parent
    self.config = parent.config
    self.L = parent:GetLocale("Settings",Locales)

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
            tModule.OnResetModuleBtn = self.OnResetModuleBtn
        end
    end
end

function Settings:OnLoad()
    self.wndSettings = Apollo.LoadForm(self.xmlDoc, "Settings", nil, self)
    self.wndSettings:SetSizingMinimum(1100,800)
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

    -- Localize Settings Form
    self.wndSettings:FindChild("DonateBtn"):SetTooltip(self.L["donate.button"])
    self.wndSettings:FindChild("DonateForm"):FindChild("TextLine1"):SetText(self.L["donate.headline"])
    self.wndSettings:FindChild("DonateForm"):FindChild("TextLine2"):SetText(self.L["donate.text"])
    self.wndSettings:FindChild("DonateSendBtn"):FindChild("BtnText"):SetText(self.L["donate.submit"])

    self.media = Apollo.GetAddon("LUI_Media")

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

            if bEncounterHasChildren then
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

    if config.enable ~= nil then
        local wndGeneral = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
        wndGeneral:FindChild("Label"):SetText(self.L["header.general"])
        wndGeneral:FindChild("Settings"):SetStyle("Picture",true)

        local nHeight = 80
        local wnd = Apollo.LoadForm(self.xmlDoc, "Items:GeneralSetting", wndGeneral:FindChild("Settings"), self)
        nHeight = nHeight + wnd:GetHeight()

        -- Enable Checkbox
        wnd:FindChild("EnableCheckbox"):SetData("enable")
        wnd:FindChild("EnableCheckbox"):SetCheck(config.enable or false)
        wnd:FindChild("EnableCheckbox"):SetText(self.L["label.enable_module"])

        -- Reset Button
        wnd:FindChild("ResetBtn"):SetText(self.L["button.reset_module"])
        wnd:FindChild("ResetBtn"):SetAnchorOffsets((Apollo.GetTextWidth("CRB_Button", self.L["button.reset_module"]) + 90)*-1,-5,0,5)

        wndGeneral:FindChild("Settings"):ArrangeChildrenVert()
        wndGeneral:SetAnchorOffsets(0,0,0,nHeight)
    end

    -- #########################################################################################################################################
    -- # TELEGRAPH COLOR
    -- #########################################################################################################################################

    local wndTelegraph = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
    wndTelegraph:FindChild("Label"):SetText(self.L["header.telegraph"])

    Apollo.LoadForm(self.xmlDoc, "Items:TelegraphSetting", wndTelegraph:FindChild("Settings"), self)
    wndTelegraph:SetAnchorOffsets(0,0,0,(wndTelegraph:FindChild("TelegraphSetting"):GetHeight()+65))

    -- Color
    wndTelegraph:FindChild("ColorSetting"):SetData({"telegraph","color"})
    wndTelegraph:FindChild("ColorSetting"):FindChild("ColorBtn"):SetData("RGB")
    wndTelegraph:FindChild("ColorSetting"):FindChild("ColorText"):SetText(config.telegraph and config.telegraph.color or self.config.telegraph.color)
    wndTelegraph:FindChild("ColorSetting"):FindChild("BG"):SetBGColor(config.telegraph and config.telegraph.color or self.config.telegraph.color)

    -- Fill Opacity
    wndTelegraph:FindChild("FillSetting"):FindChild("Slider"):SetData({"telegraph","fill"})
    wndTelegraph:FindChild("FillSetting"):FindChild("Slider"):SetValue(config.telegraph and config.telegraph.fill or self.config.telegraph.fill)
    wndTelegraph:FindChild("FillSetting"):FindChild("SliderText"):SetData({"telegraph","fill"})
    wndTelegraph:FindChild("FillSetting"):FindChild("SliderText"):SetText(config.telegraph and config.telegraph.fill or self.config.telegraph.fill)

    -- Outline Opacity
    wndTelegraph:FindChild("OutlineSetting"):FindChild("Slider"):SetData({"telegraph","outline"})
    wndTelegraph:FindChild("OutlineSetting"):FindChild("Slider"):SetValue(config.telegraph and config.telegraph.outline or self.config.telegraph.outline)
    wndTelegraph:FindChild("OutlineSetting"):FindChild("SliderText"):SetData({"telegraph","outline"})
    wndTelegraph:FindChild("OutlineSetting"):FindChild("SliderText"):SetText(config.telegraph and config.telegraph.outline or self.config.telegraph.outline)

    -- Enable Checkbox
    wndTelegraph:FindChild("EnableCheckbox"):SetData({"telegraph","enable"})
    wndTelegraph:FindChild("EnableCheckbox"):SetCheck(config.telegraph and config.telegraph.enable or false)
    self:ToggleSettings(wndTelegraph:FindChild("TelegraphSetting"),config.telegraph and config.telegraph.enable or false)

    -- #########################################################################################################################################
    -- # SOUNDS
    -- #########################################################################################################################################

    if config.sounds ~= nil then
        local wndSounds = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
        wndSounds:FindChild("Label"):SetText(self.L["header.sounds"])
        wndSounds:FindChild("Settings"):SetStyle("Picture",true)

        local tSortedSounds = {}
        local nHeight = 92

        for nId,sound in pairs(config.sounds) do
            tSortedSounds[#tSortedSounds+1] = {
                nId = nId,
                position = sound.position or 99
            }
        end

        table.sort(tSortedSounds, function(a, b)
            return a.position < b.position
        end)

        for i=1,#tSortedSounds do
            local wnd = Apollo.LoadForm(self.xmlDoc, "Items:SoundSetting", wndSounds:FindChild("Settings"), self)
            local sound = config.sounds[tSortedSounds[i].nId]
            local nId = tSortedSounds[i].nId

            -- Sound File
            self:BuildSoundDropdown(wnd,{"sounds",nId,"file"},sound.file)

            -- Enable Checkbox
            wnd:FindChild("EnableCheckbox"):SetData({"sounds",nId,"enable"})
            wnd:FindChild("EnableCheckbox"):SetCheck(sound.enable or false)
            wnd:FindChild("EnableCheckbox"):SetText(L[sound.label] or sound.label)
            wnd:SetTooltip(sound.tooltip and (L[sound.tooltip] or sound.tooltip) or "")

            self:ToggleSettings(wnd,sound.enable or false)

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
    -- # UNITS
    -- #########################################################################################################################################

    if config.units ~= nil then
        local wndUnits = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
        wndUnits:FindChild("Label"):SetText(self.L["header.units"])
        wndUnits:FindChild("Settings"):SetStyle("Picture",true)

        local tSortedUnits = {}
        local nHeight = 84

        for nId,unit in pairs(config.units) do
            tSortedUnits[#tSortedUnits+1] = {
                nId = nId,
                position = unit.position or 99
            }
        end

        table.sort(tSortedUnits, function(a, b)
            return a.position < b.position
        end)

        for i=1,#tSortedUnits do
            local wnd = Apollo.LoadForm(self.xmlDoc, "Items:UnitSetting", wndUnits:FindChild("Settings"), self)
            local tUnit = config.units[tSortedUnits[i].nId]
            local nId = tSortedUnits[i].nId

            -- Color
            wnd:FindChild("ColorSetting"):SetData({"units",nId,"color"})
            wnd:FindChild("ColorSetting"):FindChild("ColorText"):SetText(tUnit.color or self.config.units.healthColor)
            wnd:FindChild("ColorSetting"):FindChild("BG"):SetBGColor(tUnit.color or self.config.units.healthColor)
            wnd:FindChild("ColorSetting"):Show(tUnit.color ~= false,true)
            wnd:FindChild("ColorLocked"):Show(tUnit.color == false,true)

            -- Enable Checkbox
            wnd:FindChild("EnableCheckbox"):SetData({"units",nId,"enable"})
            wnd:FindChild("EnableCheckbox"):SetCheck(tUnit.enable or false)
            wnd:FindChild("EnableCheckbox"):SetText(L[tUnit.label] or tUnit.label)
            wnd:SetTooltip(tUnit.tooltip and (L[tUnit.tooltip] or tUnit.tooltip) or "")

            self:ToggleSettings(wnd,tUnit.enable or false)

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
        wndTimers:FindChild("Label"):SetText(self.L["header.timers"])
        wndTimers:FindChild("Settings"):SetStyle("Picture",true)

        local tSortedTimers = {}
        local nHeight = 84

        for nId,timer in pairs(config.timers) do
            tSortedTimers[#tSortedTimers+1] = {
                nId = nId,
                position = timer.position or 99
            }
        end

        table.sort(tSortedTimers, function(a, b)
            return a.position < b.position
        end)

        for i=1,#tSortedTimers do
            local wnd = Apollo.LoadForm(self.xmlDoc, "Items:TimerSetting", wndTimers:FindChild("Settings"), self)
            local timer = config.timers[tSortedTimers[i].nId]
            local nId = tSortedTimers[i].nId

            -- Color
            wnd:FindChild("ColorSetting"):SetData({"timers",nId,"color"})
            wnd:FindChild("ColorSetting"):FindChild("ColorText"):SetText(timer.color or self.config.timer.barColor)
            wnd:FindChild("ColorSetting"):FindChild("BG"):SetBGColor(timer.color or self.config.timer.barColor)
            wnd:FindChild("ColorSetting"):Show(timer.color ~= false,true)
            wnd:FindChild("ColorLocked"):Show(timer.color == false,true)

            -- Alert Checkbox
            wnd:FindChild("AlertCheckbox"):SetData({"timers",nId,"alert"})
            wnd:FindChild("AlertCheckbox"):SetCheck(timer.alert or false)
            wnd:FindChild("AlertCheckbox"):SetTooltip(self.L["tooltip.countdown_alert"])

            -- Sound Checkbox
            wnd:FindChild("SoundCheckbox"):SetData({"timers",nId,"sound"})
            wnd:FindChild("SoundCheckbox"):SetCheck(timer.sound or false)
            wnd:FindChild("SoundCheckbox"):SetTooltip(self.L["tooltip.countdown_sound"])

            -- Enable Checkbox
            wnd:FindChild("EnableCheckbox"):SetData({"timers",nId,"enable"})
            wnd:FindChild("EnableCheckbox"):SetCheck(timer.enable or false)
            wnd:FindChild("EnableCheckbox"):SetText(L[timer.label] or timer.label)
            wnd:SetTooltip(timer.tooltip and (L[timer.tooltip] or timer.tooltip) or "")

            self:ToggleSettings(wnd,timer.enable or false)

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
    -- # CASTS
    -- #########################################################################################################################################

    if config.casts ~= nil then
        local wndCasts = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
        wndCasts:FindChild("Label"):SetText(self.L["header.casts"])
        wndCasts:FindChild("Settings"):SetStyle("Picture",true)

        local tSortedCasts = {}
        local nHeight = 84

        for nId,cast in pairs(config.casts) do
            tSortedCasts[#tSortedCasts+1] = {
                nId = nId,
                position = cast.position or 99
            }
        end

        table.sort(tSortedCasts, function(a, b)
            return a.position < b.position
        end)

        for i=1,#tSortedCasts do
            local wnd = Apollo.LoadForm(self.xmlDoc, "Items:CastSetting", wndCasts:FindChild("Settings"), self)
            local cast = config.casts[tSortedCasts[i].nId]
            local nId = tSortedCasts[i].nId

            -- Color
            wnd:FindChild("ColorSetting"):SetData({"casts",nId,"color"})
            wnd:FindChild("ColorSetting"):FindChild("ColorText"):SetText(cast.color or (cast.moo and self.config.castbar.mooColor or self.config.castbar.barColor))
            wnd:FindChild("ColorSetting"):FindChild("BG"):SetBGColor(cast.color or (cast.moo and self.config.castbar.mooColor or self.config.castbar.barColor))
            wnd:FindChild("ColorSetting"):Show(cast.color ~= false,true)
            wnd:FindChild("ColorLocked"):Show(cast.color == false,true)

            -- Enable Checkbox
            wnd:FindChild("EnableCheckbox"):SetData({"casts",nId,"enable"})
            wnd:FindChild("EnableCheckbox"):SetCheck(cast.enable or false)
            wnd:FindChild("EnableCheckbox"):SetText(L[cast.label] or cast.label)
            wnd:SetTooltip(cast.tooltip and (L[cast.tooltip] or cast.tooltip) or "")

            self:ToggleSettings(wnd,cast.enable or false)

            nHeight = nHeight + wnd:GetHeight()
        end

        local wndItem = wndCasts:FindChild("Settings"):GetChildren()

        if #wndItem > 0 then
            wndItem[1]:SetAnchorOffsets(5,0,-5,63)
            wndItem[1]:FindChild("Wrapper"):SetAnchorOffsets(0,7,0,0)
            wndItem[#wndItem]:FindChild("Divider"):Show(false,true)
        end

        wndCasts:FindChild("Settings"):ArrangeChildrenVert()
        wndCasts:SetAnchorOffsets(0,0,0,nHeight)
    end

    -- #########################################################################################################################################
    -- # ALERTS
    -- #########################################################################################################################################

    if config.alerts ~= nil then
        local wndAlerts = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
        wndAlerts:FindChild("Label"):SetText(self.L["header.alerts"])
        wndAlerts:FindChild("Settings"):SetStyle("Picture",true)

        local tSortedAlerts = {}
        local nHeight = 84

        for nId,alert in pairs(config.alerts) do
            tSortedAlerts[#tSortedAlerts+1] = {
                nId = nId,
                position = alert.position or 99
            }
        end

        table.sort(tSortedAlerts, function(a, b)
            return a.position < b.position
        end)

        for i=1,#tSortedAlerts do
            local wnd = Apollo.LoadForm(self.xmlDoc, "Items:AlertSetting", wndAlerts:FindChild("Settings"), self)
            local alert = config.alerts[tSortedAlerts[i].nId]
            local nId = tSortedAlerts[i].nId

            -- Color
            wnd:FindChild("ColorSetting"):SetData({"alerts",nId,"color"})
            wnd:FindChild("ColorSetting"):FindChild("ColorText"):SetText(alert.color or self.config.alerts.color)
            wnd:FindChild("ColorSetting"):FindChild("BG"):SetBGColor(alert.color or self.config.alerts.color)
            wnd:FindChild("ColorSetting"):Show(alert.color ~= false,true)
            wnd:FindChild("ColorLocked"):Show(alert.color == false,true)

            -- Enable Checkbox
            wnd:FindChild("EnableCheckbox"):SetData({"alerts",nId,"enable"})
            wnd:FindChild("EnableCheckbox"):SetCheck(alert.enable or false)
            wnd:FindChild("EnableCheckbox"):SetText(L[alert.label] or alert.label)
            wnd:SetTooltip(alert.tooltip and (L[alert.tooltip] or alert.tooltip) or "")

            self:ToggleSettings(wnd,alert.enable or false)

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
    -- # AURAS
    -- #########################################################################################################################################

    if config.auras ~= nil then
        local wndAuras = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
        wndAuras:FindChild("Label"):SetText(self.L["header.auras"])
        wndAuras:FindChild("Settings"):SetStyle("Picture",true)

        local tSortedAuras = {}
        local nHeight = 84

        for nId,aura in pairs(config.auras) do
            tSortedAuras[#tSortedAuras+1] = {
                nId = nId,
                position = aura.position or 99
            }
        end

        table.sort(tSortedAuras, function(a, b)
            return a.position < b.position
        end)

        for i=1,#tSortedAuras do
            local wnd = Apollo.LoadForm(self.xmlDoc, "Items:AuraSetting", wndAuras:FindChild("Settings"), self)
            local aura = config.auras[tSortedAuras[i].nId]
            local nId = tSortedAuras[i].nId

            -- Sprite
            wnd:FindChild("SpriteSetting"):FindChild("SpriteText"):SetText(aura.sprite or self.config.aura.sprite)
            wnd:FindChild("SpriteSetting"):FindChild("SpriteText"):SetData({"auras",nId,"sprite"})
            wnd:FindChild("SpriteSetting"):FindChild("BrowseBtn"):SetAnchorOffsets((Apollo.GetTextWidth("CRB_Button", self.L["button.browse"]) + 90)*-1,-3,0,2)
            wnd:FindChild("SpriteSetting"):FindChild("BrowseBtn"):SetData({{"auras",nId,"sprite"},wnd:FindChild("SpriteText")})
            wnd:FindChild("SpriteSetting"):FindChild("BrowseBtn"):SetText(self.L["button.browse"])

            -- Color
            wnd:FindChild("ColorSetting"):SetData({"auras",nId,"color"})
            wnd:FindChild("ColorSetting"):FindChild("ColorBtn"):SetData("RGB")
            wnd:FindChild("ColorSetting"):FindChild("BG"):SetBGColor(aura.color or self.config.aura.color)
            wnd:FindChild("ColorSetting"):Show(aura.color ~= false,true)
            wnd:FindChild("ColorLocked"):Show(aura.color == false,true)

            -- Enable Checkbox
            wnd:FindChild("EnableCheckbox"):SetText(L[aura.label] or aura.label)
            wnd:FindChild("EnableCheckbox"):SetData({"auras",nId,"enable"})
            wnd:FindChild("EnableCheckbox"):SetCheck(aura.enable or false)
            wnd:SetTooltip(aura.tooltip and (L[aura.tooltip] or aura.tooltip) or "")

            self:ToggleSettings(wnd,aura.enable or false)
            nHeight = nHeight + wnd:GetHeight()
        end

        local wndItem = wndAuras:FindChild("Settings"):GetChildren()

        if #wndItem > 0 then
            wndItem[1]:SetAnchorOffsets(5,0,-5,63)
            wndItem[1]:FindChild("Wrapper"):SetAnchorOffsets(0,7,0,0)
            wndItem[#wndItem]:FindChild("Divider"):Show(false,true)
        end

        wndAuras:FindChild("Settings"):ArrangeChildrenVert()
        wndAuras:SetAnchorOffsets(0,0,0,nHeight)
    end

    -- #########################################################################################################################################
    -- # TEXTS
    -- #########################################################################################################################################

    if config.texts ~= nil then
        local wndTexts = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
        wndTexts:FindChild("Label"):SetText(self.L["header.texts"])
        wndTexts:FindChild("Settings"):SetStyle("Picture",true)

        local tSortedTexts = {}
        local nHeight = 84

        for nId,text in pairs(config.texts) do
            tSortedTexts[#tSortedTexts+1] = {
                nId = nId,
                position = text.position or 99
            }
        end

        table.sort(tSortedTexts, function(a, b)
            return a.position < b.position
        end)

        for i=1,#tSortedTexts do
            local wnd = Apollo.LoadForm(self.xmlDoc, "Items:TextSetting", wndTexts:FindChild("Settings"), self)
            local text = config.texts[tSortedTexts[i].nId]
            local nId = tSortedTexts[i].nId

            -- Font
            wnd:FindChild("FontSetting"):FindChild("FontText"):SetText(text.font or self.config.text.font)
            wnd:FindChild("FontSetting"):FindChild("BrowseBtn"):SetText(self.L["button.browse"])
            wnd:FindChild("FontSetting"):FindChild("BrowseBtn"):SetAnchorOffsets((Apollo.GetTextWidth("CRB_Button", self.L["button.browse"]) + 90)*-1,-3,0,2)
            wnd:FindChild("FontSetting"):FindChild("BrowseBtn"):SetData({{"texts",nId,"font"}, wnd:FindChild("FontText")})

            -- Color
            wnd:FindChild("ColorSetting"):SetData({"texts",nId,"color"})
            wnd:FindChild("ColorSetting"):FindChild("BG"):SetBGColor(text.color or self.config.text.color)
            wnd:FindChild("ColorSetting"):Show(text.color ~= false,true)
            wnd:FindChild("ColorLocked"):Show(text.color == false,true)

            -- Enable Checkbox
            wnd:FindChild("EnableCheckbox"):SetText(L[text.label] or text.label)
            wnd:FindChild("EnableCheckbox"):SetData({"texts",nId,"enable"})
            wnd:FindChild("EnableCheckbox"):SetCheck(text.enable or false)
            wnd:SetTooltip(text.tooltip and (L[text.tooltip] or text.tooltip) or "")

            self:ToggleSettings(wnd,text.enable or false)
            nHeight = nHeight + wnd:GetHeight()
        end

        local wndItem = wndTexts:FindChild("Settings"):GetChildren()

        if #wndItem > 0 then
            wndItem[1]:SetAnchorOffsets(5,0,-5,63)
            wndItem[1]:FindChild("Wrapper"):SetAnchorOffsets(0,7,0,0)
            wndItem[#wndItem]:FindChild("Divider"):Show(false,true)
        end

        wndTexts:FindChild("Settings"):ArrangeChildrenVert()
        wndTexts:SetAnchorOffsets(0,0,0,nHeight)
    end

    -- #########################################################################################################################################
    -- # ICONS
    -- #########################################################################################################################################

    if config.icons ~= nil then
        local wndIcons = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
        wndIcons:FindChild("Label"):SetText(self.L["header.icons"])
        wndIcons:FindChild("Settings"):SetStyle("Picture",true)

        local tSortedIcons = {}
        local nHeight = 84

        for nId,icon in pairs(config.icons) do
            tSortedIcons[#tSortedIcons+1] = {
                nId = nId,
                position = icon.position or 99
            }
        end

        table.sort(tSortedIcons, function(a, b)
            return a.position < b.position
        end)

        for i=1,#tSortedIcons do
            local wnd = Apollo.LoadForm(self.xmlDoc, "Items:IconSetting", wndIcons:FindChild("Settings"), self)
            local icon = config.icons[tSortedIcons[i].nId]
            local nId = tSortedIcons[i].nId

            -- Sprite
            wnd:FindChild("SpriteSetting"):FindChild("SpriteText"):SetText(icon.sprite or "")
            wnd:FindChild("SpriteSetting"):FindChild("SpriteText"):SetData({"icons",nId,"sprite"})
            wnd:FindChild("SpriteSetting"):FindChild("BrowseBtn"):SetAnchorOffsets((Apollo.GetTextWidth("CRB_Button", self.L["button.browse"]) + 90)*-1,-3,0,2)
            wnd:FindChild("SpriteSetting"):FindChild("BrowseBtn"):SetData({{"icons",nId,"sprite"},wnd:FindChild("SpriteText")})
            wnd:FindChild("SpriteSetting"):FindChild("BrowseBtn"):SetText(self.L["button.browse"])

            -- Color
            wnd:FindChild("ColorSetting"):SetData({"icons",nId,"color"})
            wnd:FindChild("ColorSetting"):FindChild("BG"):SetBGColor(icon.color or self.config.icon.color)
            wnd:FindChild("ColorSetting"):Show(icon.color ~= false,true)
            wnd:FindChild("ColorLocked"):Show(icon.color == false,true)

            -- Size
            wnd:FindChild("SizeText"):SetData({"icons",nId,"size"})
            wnd:FindChild("SizeText"):SetText(icon.size or self.config.icon.size)
            wnd:FindChild("SizeText"):SetTooltip(self.L["label.size"])
            wnd:FindChild("SizeText"):SetMaxTextLength(3)

            -- Enable Checkbox
            wnd:FindChild("EnableCheckbox"):SetText(L[icon.label] or icon.label)
            wnd:FindChild("EnableCheckbox"):SetData({"icons",nId,"enable"})
            wnd:FindChild("EnableCheckbox"):SetCheck(icon.enable or false)
            wnd:SetTooltip(icon.tooltip and (L[icon.tooltip] or icon.tooltip) or "")

            self:ToggleSettings(wnd,icon.enable or false)
            nHeight = nHeight + wnd:GetHeight()
        end

        local wndItem = wndIcons:FindChild("Settings"):GetChildren()

        if #wndItem > 0 then
            wndItem[1]:SetAnchorOffsets(5,0,-5,63)
            wndItem[1]:FindChild("Wrapper"):SetAnchorOffsets(0,7,0,0)
            wndItem[#wndItem]:FindChild("Divider"):Show(false,true)
        end

        wndIcons:FindChild("Settings"):ArrangeChildrenVert()
        wndIcons:SetAnchorOffsets(0,0,0,nHeight)
    end

    -- #########################################################################################################################################
    -- # LINES
    -- #########################################################################################################################################

    if config.lines ~= nil then
        local wndLines = Apollo.LoadForm(self.xmlDoc, "Container", self.wndRight, self)
        wndLines:FindChild("Label"):SetText(self.L["header.lines"])
        wndLines:FindChild("Settings"):SetStyle("Picture",true)

        local tSortedLines = {}
        local nHeight = 84

        for nId,line in pairs(config.lines) do
            tSortedLines[#tSortedLines+1] = {
                nId = nId,
                position = line.position or 99
            }
        end

        table.sort(tSortedLines, function(a, b)
            return a.position < b.position
        end)

        for i=1,#tSortedLines do
            local wnd = Apollo.LoadForm(self.xmlDoc, "Items:LineSetting", wndLines:FindChild("Settings"), self)
            local line = config.lines[tSortedLines[i].nId]
            local nId = tSortedLines[i].nId

            -- Thickness
            wnd:FindChild("ThicknessSetting"):FindChild("Slider"):SetData({"lines",nId,"thickness"})
            wnd:FindChild("ThicknessSetting"):FindChild("Slider"):SetValue(line.thickness or self.config.line.thickness)
            wnd:FindChild("ThicknessSetting"):FindChild("SliderText"):SetData({"lines",nId,"thickness"})
            wnd:FindChild("ThicknessSetting"):FindChild("SliderText"):SetText(line.thickness or self.config.line.thickness)
            wnd:FindChild("ThicknessSetting"):FindChild("SliderText"):SetTooltip(self.L["label.thickness"])

            -- Color
            wnd:FindChild("ColorSetting"):SetData({"lines",nId,"color"})
            wnd:FindChild("ColorSetting"):FindChild("BG"):SetBGColor(line.color or self.config.line.color)
            wnd:FindChild("ColorSetting"):Show(line.color ~= false,true)
            wnd:FindChild("ColorLocked"):Show(line.color == false,true)

            -- Enable Checkbox
            wnd:FindChild("EnableCheckbox"):SetText(L[line.label] or line.label)
            wnd:FindChild("EnableCheckbox"):SetData({"lines",nId,"enable"})
            wnd:FindChild("EnableCheckbox"):SetCheck(line.enable or false)
            wnd:SetTooltip(line.tooltip and (L[line.tooltip] or line.tooltip) or "")

            self:ToggleSettings(wnd,line.enable or false)
            nHeight = nHeight + wnd:GetHeight()
        end

        local wndItem = wndLines:FindChild("Settings"):GetChildren()

        if #wndItem > 0 then
            wndItem[1]:SetAnchorOffsets(5,0,-5,63)
            wndItem[1]:FindChild("Wrapper"):SetAnchorOffsets(0,7,0,0)
            wndItem[#wndItem]:FindChild("Divider"):Show(false,true)
        end

        wndLines:FindChild("Settings"):ArrangeChildrenVert()
        wndLines:SetAnchorOffsets(0,0,0,nHeight)
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

    self.wndSettings:FindChild("Global"):FindChild("UnlockBtn"):SetText(self.L["button.unlock"])
    self.wndSettings:FindChild("Global"):FindChild("ResetBtn"):SetText(self.L["button.reset"])

    self.wndSettings:FindChild("Global"):FindChild("Unlock"):SetAnchorOffsets(10,10,Apollo.GetTextWidth("CRB_Button", self.L["button.unlock"]) + 90,60)
    self.wndSettings:FindChild("Global"):FindChild("Reset"):SetAnchorOffsets(0,10,Apollo.GetTextWidth("CRB_Button", self.L["button.reset"]) + 90,60)

    -- #########################################################################################################################################
    -- # GENERAL
    -- #########################################################################################################################################

    local wndGeneral = self.wndSettings:FindChild("Global"):FindChild("General")
    wndGeneral:FindChild("Frame"):FindChild("Label"):SetText(self.L["header.general"])

    -- Update Interval
    wndGeneral:FindChild("IntervalSetting"):FindChild("Label"):SetText(self.L["label.interval"])
    wndGeneral:FindChild("IntervalSetting"):FindChild("Slider"):SetData("interval")
    wndGeneral:FindChild("IntervalSetting"):FindChild("SliderText"):SetData("interval")
    wndGeneral:FindChild("IntervalSetting"):FindChild("Slider"):SetValue(self.config.interval or 0)
    wndGeneral:FindChild("IntervalSetting"):FindChild("SliderText"):SetText(self.config.interval or 0)

    -- #########################################################################################################################################
    -- # SOUNDS
    -- #########################################################################################################################################

    local wndSounds = self.wndSettings:FindChild("Global"):FindChild("Sounds")
    wndSounds:FindChild("Frame"):FindChild("Label"):SetText(self.L["header.sounds"])

    self:ToggleSettings(wndSounds:FindChild("Container"),(self.config.sound.enable and self.config.sound.force) or false)
    self:ToggleSettings(wndSounds:FindChild("ForceCheckbox"),self.config.sound.enable or false)

    -- Enable Checkbox
    wndSounds:FindChild("EnableCheckbox"):SetText(self.L["label.enable"])
    wndSounds:FindChild("EnableCheckbox"):SetData({"sound","enable"})
    wndSounds:FindChild("EnableCheckbox"):SetCheck(self.config.sound.enable or false)
    wndSounds:FindChild("EnableCheckbox"):SetTooltip(self.L["tooltip.sounds"])
    wndSounds:FindChild("EnableCheckbox"):SetAnchorOffsets(10,0,Apollo.GetTextWidth("CRB_ButtonHeader", self.L["label.enable"]) + 90,0)

    -- Adjust Volume Checkbox
    wndSounds:FindChild("ForceCheckbox"):SetText(self.L["volume.force"])
    wndSounds:FindChild("ForceCheckbox"):SetData({"sound","force"})
    wndSounds:FindChild("ForceCheckbox"):SetCheck(self.config.sound.force or false)
    wndSounds:FindChild("ForceCheckbox"):SetTooltip(self.L["tooltip.sounds_force"])

    -- Volume Master
    wndSounds:FindChild("VolumeMasterSetting"):FindChild("Label"):SetText(self.L["volume.master"])
    wndSounds:FindChild("VolumeMasterSetting"):FindChild("Slider"):SetData({"sound","volumeMaster"})
    wndSounds:FindChild("VolumeMasterSetting"):FindChild("SliderText"):SetData({"sound","volumeMaster"})
    wndSounds:FindChild("VolumeMasterSetting"):FindChild("Slider"):SetValue(self.config.sound.volumeMaster or 0)
    wndSounds:FindChild("VolumeMasterSetting"):FindChild("SliderText"):SetText(self.config.sound.volumeMaster or 0)

    -- Volume Music
    wndSounds:FindChild("VolumeMusicSetting"):FindChild("Label"):SetText(self.L["volume.music"])
    wndSounds:FindChild("VolumeMusicSetting"):FindChild("Slider"):SetData({"sound","volumeMusic"})
    wndSounds:FindChild("VolumeMusicSetting"):FindChild("SliderText"):SetData({"sound","volumeMusic"})
    wndSounds:FindChild("VolumeMusicSetting"):FindChild("Slider"):SetValue(self.config.sound.volumeMusic or 0)
    wndSounds:FindChild("VolumeMusicSetting"):FindChild("SliderText"):SetText(self.config.sound.volumeMusic or 0)

    -- Volume UI
    wndSounds:FindChild("VolumeUISetting"):FindChild("Label"):SetText(self.L["volume.ui"])
    wndSounds:FindChild("VolumeUISetting"):FindChild("Slider"):SetData({"sound","volumeUI"})
    wndSounds:FindChild("VolumeUISetting"):FindChild("SliderText"):SetData({"sound","volumeUI"})
    wndSounds:FindChild("VolumeUISetting"):FindChild("Slider"):SetValue(self.config.sound.volumeUI or 0)
    wndSounds:FindChild("VolumeUISetting"):FindChild("SliderText"):SetText(self.config.sound.volumeUI or 0)

    -- Volume SFX
    wndSounds:FindChild("VolumeSFXSetting"):FindChild("Label"):SetText(self.L["volume.sfx"])
    wndSounds:FindChild("VolumeSFXSetting"):FindChild("Slider"):SetData({"sound","volumeSFX"})
    wndSounds:FindChild("VolumeSFXSetting"):FindChild("SliderText"):SetData({"sound","volumeSFX"})
    wndSounds:FindChild("VolumeSFXSetting"):FindChild("Slider"):SetValue(self.config.sound.volumeSFX or 0)
    wndSounds:FindChild("VolumeSFXSetting"):FindChild("SliderText"):SetText(self.config.sound.volumeSFX or 0)

    -- Volume Ambient
    wndSounds:FindChild("VolumeAmbientSetting"):FindChild("Label"):SetText(self.L["volume.ambient"])
    wndSounds:FindChild("VolumeAmbientSetting"):FindChild("Slider"):SetData({"sound","volumeAmbient"})
    wndSounds:FindChild("VolumeAmbientSetting"):FindChild("SliderText"):SetData({"sound","volumeAmbient"})
    wndSounds:FindChild("VolumeAmbientSetting"):FindChild("Slider"):SetValue(self.config.sound.volumeAmbient or 0)
    wndSounds:FindChild("VolumeAmbientSetting"):FindChild("SliderText"):SetText(self.config.sound.volumeAmbient or 0)

    -- Volume Voice
    wndSounds:FindChild("VolumeVoiceSetting"):FindChild("Label"):SetText(self.L["volume.voice"])
    wndSounds:FindChild("VolumeVoiceSetting"):FindChild("Slider"):SetData({"sound","volumeVoice"})
    wndSounds:FindChild("VolumeVoiceSetting"):FindChild("SliderText"):SetData({"sound","volumeVoice"})
    wndSounds:FindChild("VolumeVoiceSetting"):FindChild("Slider"):SetValue(self.config.sound.volumeVoice or 0)
    wndSounds:FindChild("VolumeVoiceSetting"):FindChild("SliderText"):SetText(self.config.sound.volumeVoice or 0)

    -- #########################################################################################################################################
    -- # UNITS
    -- #########################################################################################################################################

    local wndUnit = self.wndSettings:FindChild("Global"):FindChild("Units")
    wndUnit:FindChild("Frame"):FindChild("Label"):SetText(self.L["header.units"])

    self:ToggleSettings(wndUnit:FindChild("Container"),self.config.units.enable or false)

    -- Enable Checkbox
    wndUnit:FindChild("EnableCheckbox"):SetText(self.L["label.enable"])
    wndUnit:FindChild("EnableCheckbox"):SetData({"units","enable"})
    wndUnit:FindChild("EnableCheckbox"):SetCheck(self.config.units.enable or false)
    wndUnit:FindChild("EnableCheckbox"):SetAnchorOffsets(10,0,Apollo.GetTextWidth("CRB_ButtonHeader", self.L["label.enable"]) + 90,0)

    -- Show Text Checkbox
    wndUnit:FindChild("TextCheckbox"):SetText(self.L["global.show_text"])
    wndUnit:FindChild("TextCheckbox"):SetData({"units","showText"})
    wndUnit:FindChild("TextCheckbox"):SetCheck(self.config.units.showText or false)

    -- Health Color
    wndUnit:FindChild("HealthColorSetting"):FindChild("Label"):SetText(self.L["global.health_color"])
    wndUnit:FindChild("HealthColorSetting"):FindChild("Color"):SetData({"units","healthColor"})
    wndUnit:FindChild("HealthColorSetting"):FindChild("ColorText"):SetText(self.config.units.healthColor or "")
    wndUnit:FindChild("HealthColorSetting"):FindChild("BG"):SetBGColor(self.config.units.healthColor)

    -- Shield Color
    wndUnit:FindChild("ShieldColorSetting"):FindChild("Label"):SetText(self.L["global.shield_color"])
    wndUnit:FindChild("ShieldColorSetting"):FindChild("Color"):SetData({"units","shieldColor"})
    wndUnit:FindChild("ShieldColorSetting"):FindChild("ColorText"):SetText(self.config.units.shieldColor or "")
    wndUnit:FindChild("ShieldColorSetting"):FindChild("BG"):SetBGColor(self.config.units.shieldColor)

    -- Absorb Color
    wndUnit:FindChild("AbsorbColorSetting"):FindChild("Label"):SetText(self.L["global.absorb_color"])
    wndUnit:FindChild("AbsorbColorSetting"):FindChild("Color"):SetData({"units","absorbColor"})
    wndUnit:FindChild("AbsorbColorSetting"):FindChild("ColorText"):SetText(self.config.units.absorbColor or "")
    wndUnit:FindChild("AbsorbColorSetting"):FindChild("BG"):SetBGColor(self.config.units.absorbColor)

    -- Cast Color
    wndUnit:FindChild("CastColorSetting"):FindChild("Label"):SetText(self.L["global.cast_color"])
    wndUnit:FindChild("CastColorSetting"):FindChild("Color"):SetData({"units","castColor"})
    wndUnit:FindChild("CastColorSetting"):FindChild("ColorText"):SetText(self.config.units.castColor or "")
    wndUnit:FindChild("CastColorSetting"):FindChild("BG"):SetBGColor(self.config.units.castColor)

    -- MOO Color
    wndUnit:FindChild("MooColorSetting"):FindChild("Label"):SetText(self.L["global.moo_color"])
    wndUnit:FindChild("MooColorSetting"):FindChild("Color"):SetData({"units","mooColor"})
    wndUnit:FindChild("MooColorSetting"):FindChild("ColorText"):SetText(self.config.units.mooColor or "")
    wndUnit:FindChild("MooColorSetting"):FindChild("BG"):SetBGColor(self.config.units.mooColor)

    -- Text Color
    wndUnit:FindChild("TextColorSetting"):FindChild("Label"):SetText(self.L["global.text_color"])
    wndUnit:FindChild("TextColorSetting"):FindChild("Color"):SetData({"units","textColor"})
    wndUnit:FindChild("TextColorSetting"):FindChild("ColorText"):SetText(self.config.units.textColor or "")
    wndUnit:FindChild("TextColorSetting"):FindChild("BG"):SetBGColor(self.config.units.textColor)

    -- Health Height
    wndUnit:FindChild("HealthHeightSetting"):FindChild("Label"):SetText(self.L["global.health_height"])
    wndUnit:FindChild("HealthHeightSetting"):FindChild("Slider"):SetData({"units","healthHeight"})
    wndUnit:FindChild("HealthHeightSetting"):FindChild("SliderText"):SetData({"units","healthHeight"})
    wndUnit:FindChild("HealthHeightSetting"):FindChild("Slider"):SetValue(self.config.units.healthHeight or 0)
    wndUnit:FindChild("HealthHeightSetting"):FindChild("SliderText"):SetText(self.config.units.healthHeight or 0)

    -- Shield Height
    wndUnit:FindChild("ShieldHeightSetting"):FindChild("Label"):SetText(self.L["global.shield_height"])
    wndUnit:FindChild("ShieldHeightSetting"):FindChild("Slider"):SetData({"units","shieldHeight"})
    wndUnit:FindChild("ShieldHeightSetting"):FindChild("SliderText"):SetData({"units","shieldHeight"})
    wndUnit:FindChild("ShieldHeightSetting"):FindChild("Slider"):SetValue(self.config.units.shieldHeight or 0)
    wndUnit:FindChild("ShieldHeightSetting"):FindChild("SliderText"):SetText(self.config.units.shieldHeight or 0)

    -- #########################################################################################################################################
    -- # FONTS
    -- #########################################################################################################################################

    local wndFonts = self.wndSettings:FindChild("Global"):FindChild("Fonts")
    wndFonts:FindChild("Frame"):FindChild("Label"):SetText(self.L["header.fonts"])

    -- Alert Font
    wndFonts:FindChild("AlertSetting"):FindChild("Label"):SetText(self.L["header.alerts"])
    wndFonts:FindChild("AlertSetting"):FindChild("FontText"):SetText(self.config.alerts.font or "")
    wndFonts:FindChild("AlertSetting"):FindChild("BrowseBtn"):SetText(self.L["button.browse"])
    wndFonts:FindChild("AlertSetting"):FindChild("BrowseBtn"):SetData({{"alerts","font"}, wndFonts:FindChild("AlertSetting"):FindChild("FontText")})
    wndFonts:FindChild("AlertSetting"):FindChild("BrowseBtn"):SetAnchorOffsets((Apollo.GetTextWidth("CRB_Button", self.L["button.browse"]) + 90)*-1,-3,0,2)

    -- Text Color
    wndFonts:FindChild("AlertSetting"):FindChild("ColorSetting"):SetData({"alerts","color"})
    wndFonts:FindChild("AlertSetting"):FindChild("ColorSetting"):FindChild("BG"):SetBGColor(self.config.alerts.color)

    -- Font
    wndFonts:FindChild("AuraSetting"):FindChild("Label"):SetText(self.L["header.auras"])
    wndFonts:FindChild("AuraSetting"):FindChild("FontText"):SetText(self.config.aura.font or "")
    wndFonts:FindChild("AuraSetting"):FindChild("BrowseBtn"):SetText(self.L["button.browse"])
    wndFonts:FindChild("AuraSetting"):FindChild("BrowseBtn"):SetData({{"aura","font"}, wndFonts:FindChild("AuraSetting"):FindChild("FontText")})
    wndFonts:FindChild("AuraSetting"):FindChild("BrowseBtn"):SetAnchorOffsets((Apollo.GetTextWidth("CRB_Button", self.L["button.browse"]) + 90)*-1,-3,0,2)

    -- Color
    wndFonts:FindChild("AuraSetting"):FindChild("ColorSetting"):SetData({"aura","color"})
    wndFonts:FindChild("AuraSetting"):FindChild("ColorSetting"):FindChild("BG"):SetBGColor(self.config.aura.color)
    wndFonts:FindChild("AuraSetting"):FindChild("ColorBtn"):SetData("RGB")

    -- #########################################################################################################################################
    -- # CASTBAR
    -- #########################################################################################################################################

    local wndCastbar = self.wndSettings:FindChild("Global"):FindChild("Castbar")
    wndCastbar:FindChild("Frame"):FindChild("Label"):SetText(self.L["header.castbar"])

    -- Bar Color
    wndCastbar:FindChild("BarColorSetting"):FindChild("Label"):SetText(self.L["global.bar_color"])
    wndCastbar:FindChild("BarColorSetting"):FindChild("Color"):SetData({"castbar","barColor"})
    wndCastbar:FindChild("BarColorSetting"):FindChild("ColorText"):SetText(self.config.castbar.barColor or "")
    wndCastbar:FindChild("BarColorSetting"):FindChild("BG"):SetBGColor(self.config.castbar.barColor)

    -- MoO Color
    wndCastbar:FindChild("MooColorSetting"):FindChild("Label"):SetText(self.L["global.moo_color"])
    wndCastbar:FindChild("MooColorSetting"):FindChild("Color"):SetData({"castbar","mooColor"})
    wndCastbar:FindChild("MooColorSetting"):FindChild("ColorText"):SetText(self.config.castbar.mooColor or "")
    wndCastbar:FindChild("MooColorSetting"):FindChild("BG"):SetBGColor(self.config.castbar.mooColor)

    -- Text Color
    wndCastbar:FindChild("TextColorSetting"):FindChild("Label"):SetText(self.L["global.text_color"])
    wndCastbar:FindChild("TextColorSetting"):FindChild("Color"):SetData({"castbar","textColor"})
    wndCastbar:FindChild("TextColorSetting"):FindChild("ColorText"):SetText(self.config.castbar.textColor or "")
    wndCastbar:FindChild("TextColorSetting"):FindChild("BG"):SetBGColor(self.config.castbar.textColor)

    -- #########################################################################################################################################
    -- # TIMER
    -- #########################################################################################################################################

    local wndTimer = self.wndSettings:FindChild("Global"):FindChild("Timer")
    wndTimer:FindChild("Frame"):FindChild("Label"):SetText(self.L["header.timers"])

    -- Countdown Voice
    wndTimer:FindChild("SoundPackSetting"):FindChild("Label"):SetText(self.L["voice.pack"])
    wndTimer:FindChild("SoundPackSetting"):FindChild("Dropdown"):AttachWindow(wndTimer:FindChild("SoundPackSetting"):FindChild("ChoiceContainer"))
    wndTimer:FindChild("SoundPackSetting"):FindChild("ChoiceContainer"):Show(false)
    wndTimer:FindChild("SoundPackSetting"):FindChild("Dropdown"):SetText(self.L["button.choose"])
    wndTimer:FindChild("SoundPackSetting"):FindChild("Dropdown"):SetData({"timer","soundPack"})

    wndTimer:FindChild("SoundPackSetting"):FindChild("ChoiceContainer"):FindChild("male"):SetText(self.L["voice.male"])
    wndTimer:FindChild("SoundPackSetting"):FindChild("ChoiceContainer"):FindChild("female"):SetText(self.L["voice.female"])

    for _,button in pairs(wndTimer:FindChild("SoundPackSetting"):FindChild("ChoiceContainer"):GetChildren()) do
        if button:GetName() == self.config.timer.soundPack then
            button:SetCheck(true)
            wndTimer:FindChild("SoundPackSetting"):FindChild("Dropdown"):SetText(button:GetText())
        else
            button:SetCheck(false)
        end
    end

    -- Countdown Length
    wndTimer:FindChild("SoundLengthSetting"):FindChild("Label"):SetText(self.L["voice.length"])
    wndTimer:FindChild("SoundLengthSetting"):FindChild("Dropdown"):AttachWindow(wndTimer:FindChild("SoundLengthSetting"):FindChild("ChoiceContainer"))
    wndTimer:FindChild("SoundLengthSetting"):FindChild("ChoiceContainer"):Show(false)
    wndTimer:FindChild("SoundLengthSetting"):FindChild("Dropdown"):SetText(self.L["button.choose"])
    wndTimer:FindChild("SoundLengthSetting"):FindChild("Dropdown"):SetData({"timer","countdown"})

    wndTimer:FindChild("SoundLengthSetting"):FindChild("ChoiceContainer"):FindChild("short1"):SetText(self.L["voice.short"])
    wndTimer:FindChild("SoundLengthSetting"):FindChild("ChoiceContainer"):FindChild("short2"):SetText(self.L["voice.short_skip"])
    wndTimer:FindChild("SoundLengthSetting"):FindChild("ChoiceContainer"):FindChild("long1"):SetText(self.L["voice.long"])
    wndTimer:FindChild("SoundLengthSetting"):FindChild("ChoiceContainer"):FindChild("long2"):SetText(self.L["voice.long_skip"])

    for _,button in pairs(wndTimer:FindChild("SoundLengthSetting"):FindChild("ChoiceContainer"):GetChildren()) do
        if button:GetName() == self.config.timer.countdown then
            button:SetCheck(true)
            wndTimer:FindChild("SoundLengthSetting"):FindChild("Dropdown"):SetText(button:GetText())
        else
            button:SetCheck(false)
        end
    end

    -- Bar Color
    wndTimer:FindChild("BarColorSetting"):FindChild("Label"):SetText(self.L["global.bar_color"])
    wndTimer:FindChild("BarColorSetting"):FindChild("Color"):SetData({"timer","barColor"})
    wndTimer:FindChild("BarColorSetting"):FindChild("ColorText"):SetText(self.config.timer.barColor or "")
    wndTimer:FindChild("BarColorSetting"):FindChild("BG"):SetBGColor(self.config.timer.barColor)

    -- Text Color
    wndTimer:FindChild("TextColorSetting"):FindChild("Label"):SetText(self.L["global.text_color"])
    wndTimer:FindChild("TextColorSetting"):FindChild("Color"):SetData({"timer","textColor"})
    wndTimer:FindChild("TextColorSetting"):FindChild("ColorText"):SetText(self.config.timer.textColor or "")
    wndTimer:FindChild("TextColorSetting"):FindChild("BG"):SetBGColor(self.config.timer.textColor)

    -- Bar Height
    wndTimer:FindChild("BarHeightSetting"):FindChild("Label"):SetText(self.L["global.bar_height"])
    wndTimer:FindChild("BarHeightSetting"):FindChild("Slider"):SetData({"timer","barHeight"})
    wndTimer:FindChild("BarHeightSetting"):FindChild("SliderText"):SetData({"timer","barHeight"})
    wndTimer:FindChild("BarHeightSetting"):FindChild("Slider"):SetValue(self.config.timer.barHeight or 0)
    wndTimer:FindChild("BarHeightSetting"):FindChild("SliderText"):SetText(self.config.timer.barHeight or 0)

    -- #########################################################################################################################################
    -- # FOCUS TARGET
    -- #########################################################################################################################################

    local wndFocus = self.wndSettings:FindChild("Global"):FindChild("Focus")
    local wndFocusIcon = wndFocus:FindChild("IconSetting")
    local wndFocusLine = wndFocus:FindChild("LineSetting")

    wndFocus:FindChild("Frame"):FindChild("Label"):SetText(self.L["header.focus"])

    -- Enable Icon Checkbox
    wndFocusIcon:FindChild("EnableCheckbox"):SetText(self.L["label.icon"])
    wndFocusIcon:FindChild("EnableCheckbox"):SetData({"focus","icon","enable"})
    wndFocusIcon:FindChild("EnableCheckbox"):SetCheck(self.config.focus.icon.enable or false)

    -- Icon Sprite
    wndFocusIcon:FindChild("SpriteSetting"):FindChild("SpriteText"):SetText(self.config.focus.icon.sprite or "LUIBM_star")
    wndFocusIcon:FindChild("SpriteSetting"):FindChild("SpriteText"):SetData({"focus","icon","sprite"})
    wndFocusIcon:FindChild("SpriteSetting"):FindChild("BrowseBtn"):SetAnchorOffsets((Apollo.GetTextWidth("CRB_Button", self.L["button.browse"]) + 90)*-1,-3,0,2)
    wndFocusIcon:FindChild("SpriteSetting"):FindChild("BrowseBtn"):SetData({{"focus","icon","sprite"},wndFocusIcon:FindChild("SpriteText")})
    wndFocusIcon:FindChild("SpriteSetting"):FindChild("BrowseBtn"):SetText(self.L["button.browse"])

    -- Icon Color
    wndFocusIcon:FindChild("ColorSetting"):SetData({"focus","icon","color"})
    wndFocusIcon:FindChild("ColorSetting"):FindChild("BG"):SetBGColor(self.config.focus.icon.color or "ffb0ff2f")

    -- Icon Size
    wndFocusIcon:FindChild("SizeText"):SetTooltip(self.L["label.size"])
    wndFocusIcon:FindChild("SizeText"):SetData({"focus","icon","size"})
    wndFocusIcon:FindChild("SizeText"):SetText(self.config.focus.icon.size or 80)
    wndFocusIcon:FindChild("SizeText"):SetMaxTextLength(3)

    -- Enable Line Checkbox
    wndFocusLine:FindChild("EnableCheckbox"):SetText(self.L["label.line"])
    wndFocusLine:FindChild("EnableCheckbox"):SetData({"focus","line","enable"})
    wndFocusLine:FindChild("EnableCheckbox"):SetCheck(self.config.focus.line.enable or false)

    -- Line Thickness
    wndFocusLine:FindChild("ThicknessSetting"):FindChild("Slider"):SetData({"focus","line","thickness"})
    wndFocusLine:FindChild("ThicknessSetting"):FindChild("Slider"):SetValue(self.config.focus.line.thickness or 6)
    wndFocusLine:FindChild("ThicknessSetting"):FindChild("SliderText"):SetData({"focus","line","thickness"})
    wndFocusLine:FindChild("ThicknessSetting"):FindChild("SliderText"):SetText(self.config.focus.line.thickness or 6)
    wndFocusLine:FindChild("ThicknessSetting"):FindChild("SliderText"):SetTooltip(self.L["label.thickness"])

    -- Line Color
    wndFocusLine:FindChild("ColorSetting"):SetData({"focus","line","color"})
    wndFocusLine:FindChild("ColorSetting"):FindChild("BG"):SetBGColor(self.config.focus.line.color or "ffb0ff2f")

    self:ToggleSettings(wndFocusIcon, self.config.focus.icon.enable or false)
    self:ToggleSettings(wndFocusLine, self.config.focus.line.enable or false)
end

function Settings:BuildSoundDropdown(wnd,setting,value)
    if not wnd or not setting then
        return
    end

    local currentTrigger = 0
    local triggerCount = #self.tSounds

    wnd:FindChild("ChoiceContainer"):DestroyChildren()

    for idx,fileName in ipairs(self.tSounds) do
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

    if not value or value == "" then
        self.core:Print("Please enter a value.")
        return
    end

    if wndControl:GetName() == "SizeText" or wndControl:GetName() == "SliderText" then
        if tonumber(value) == nil then
            self.core:Print("Please enter a number.")
            return
        end
    end

    if wndControl:GetName() == "SliderText" then
        local slider = wndControl:GetParent():FindChild("Slider")
        local max = slider:GetMax()
        local min = slider:GetMin()

        if value ~= math.floor(value) then
            value = self.core:Round(value,2)
        end

        if value < min then
            value = min
        end

        if value > max then
            value = max
        end

        wndControl:SetText(value)
        slider:SetValue(value)
    end

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
    local alpha = (wndControl:GetData() ~= "RGB") or false

    setting = self:GetVar(setting)

    GeminiColor:ShowColorPicker(self, {
        callback = "OnColorPicker",
        strInitialColor = setting,
        bCustomColor = true,
        bAlpha = alpha,
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

    if wndControl:GetParent():FindChild("ColorText") then
        wndControl:GetParent():FindChild("ColorText"):SetText(sColor)
    end

    self:SetVar(setting,sColor)
end

function Settings:ToggleSettings(wnd,state,bIsChild)
    local enable = (state ~= nil and state == true) and true or false
    local opacity = enable and 1 or 0.5

    if bIsChild and wnd:GetData() == "ignore" then
        return
    end

    if bIsChild and
        wnd:GetName() ~= "Frame" and
        wnd:GetName() ~= "Config" and
        wnd:GetName() ~= "Container" and
        wnd:GetName() ~= "Wrapper" and
        wnd:GetName() ~= "EnableCheckbox"
    then
        wnd:Enable(state)

        if enable == false and wnd:IsStyleOn("BlockOutIfDisabled") then
            wnd:SetStyle("BlockOutIfDisabled",false)
            wnd:SetOpacity(opacity)
        end

        if enable and wnd:GetOpacity() == 0.5 then
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

    if amount > 0 then
        self.wndSettings:FindChild("DonateForm"):FindChild("DonateSendBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.SendMail, "Loui NaN", "Jabbit", "LUI BossMods Donation", tostring(GameLib.GetPlayerUnit():GetName()) .. " donated something for you!", nil, MailSystemLib.MailDeliverySpeed_Instant, 0, self.wndSettings:FindChild("DonateForm"):FindChild("CashWindow"):GetCurrency())
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

function Settings:OnToggleSprites(wndHandler, wndControl)
    if self.wndSprites then
        if self.wndSprites:IsShown() then
            self.wndSprites:Close()
        else
            local wndText = wndControl:GetParent():FindChild("SpriteText")

            for _,wndSprite in pairs(self.wndSprites:FindChild("Container"):FindChild("List"):GetChildren()) do
                if wndText and wndSprite:FindChild("SelectBtn"):GetData() == wndText:GetText() then
                    wndSprite:FindChild("SelectBtn"):SetCheck(true)
                else
                    wndSprite:FindChild("SelectBtn"):SetCheck(false)
                end
            end

            self.wndSprites:SetData(wndControl:GetData())
            self.wndSprites:Invoke()
        end
    else
        self.wndSprites = Apollo.LoadForm(self.xmlDoc, "BrowseForm", nil, self)
        self.wndSprites:SetData(wndControl:GetData())
        self.wndSprites:FindChild("TitleText"):SetText(self.L["header.sprites"])
        self.wndSprites:FindChild("ChooseBtn"):SetText(self.L["button.choose"])

        local wndSpriteList = self.wndSprites:FindChild("Container"):FindChild("List")
        local wndText = wndControl:GetParent():FindChild("SpriteText")

        for idx = 1, #self.tSprites do
            local wndSprite = Apollo.LoadForm(self.xmlDoc, "Items:SpriteItem", wndSpriteList, self)
            wndSprite:FindChild("Sprite"):SetSprite(self.tSprites[idx])
            wndSprite:FindChild("Sprite"):SetBGColor("ffffffff")
            wndSprite:FindChild("SelectBtn"):SetData(self.tSprites[idx])

            if wndText and wndSprite:FindChild("SelectBtn"):GetData() == wndText:GetText() then
                wndSprite:FindChild("SelectBtn"):SetCheck(true)
            else
                wndSprite:FindChild("SelectBtn"):SetCheck(false)
            end
        end

        -- LUI Media
        if self.media then
            local icons = self.media:Load("icons")

            if icons then
                for idx = 1, #icons do
                    local wndIcon = Apollo.LoadForm(self.xmlDoc, "Items:SpriteItem", wndSpriteList, self)
                    wndIcon:FindChild("Sprite"):SetSprite("LUI_Media:"..tostring(icons[idx]))
                    wndIcon:FindChild("SelectBtn"):SetData("LUI_Media:"..tostring(icons[idx]))

                    if wndText and wndIcon:FindChild("SelectBtn"):GetData() == wndText:GetText() then
                        wndIcon:FindChild("SelectBtn"):SetCheck(true)
                    else
                        wndIcon:FindChild("SelectBtn"):SetCheck(false)
                    end
                end
            end
        end

        wndSpriteList:ArrangeChildrenTiles()
    end
end

function Settings:OnSelectSprite(wndHandler, wndControl, eMouseButton)
    if eMouseButton == GameLib.CodeEnumInputMouse.Right then
         return false
    end

    if not self.wndSprites then
        return
    end

    self.wndSprites:FindChild("ChooseBtn"):SetData(wndControl:GetData())
end

function Settings:OnSaveSprite(wndHandler, wndControl)
    if not self.wndSprites then
        return
    end

    local strIcon = wndControl:GetData()
    local setting = self.wndSprites:GetData()[1]
    local wndText = self.wndSprites:GetData()[2]

    if not strIcon or not setting or not wndText then
        return
    end

    if wndText then
        wndText:SetText(strIcon)
    end

    if setting[1] == "icons" then
        self:SetVar({setting[1],setting[2],"overlay"}, self:GetVar({setting[1],setting[2],"overlay"}) ~= nil)
    end

    self:SetVar(setting,strIcon)
    self.wndSprites:Close()
end

function Settings:OnToggleFonts(wndHandler, wndControl)
    if self.wndFonts then
        if self.wndFonts:IsShown() then
            self.wndFonts:Close()
        else
            local wndText = wndControl:GetParent():FindChild("FontText")

            for _,wndFont in pairs(self.wndFonts:FindChild("Container"):FindChild("List"):GetChildren()) do
                if wndText and wndFont:FindChild("SelectBtn"):GetData().sFont == wndText:GetText() then
                    wndFont:FindChild("SelectBtn"):SetCheck(true)
                else
                    wndFont:FindChild("SelectBtn"):SetCheck(false)
                end
            end

            self.wndFonts:SetData(wndControl:GetData())
            self.wndFonts:Invoke()
        end
    else
        self.wndFonts = Apollo.LoadForm(self.xmlDoc, "BrowseForm", nil, self)
        self.wndFonts:FindChild("TitleText"):SetText(self.L["header.fonts"])
        self.wndFonts:FindChild("ChooseBtn"):SetText(self.L["button.choose"])

        self.wndFonts:FindChild("ChooseBtn"):RemoveEventHandler("ButtonSignal")
        self.wndFonts:FindChild("CloseButton"):RemoveEventHandler("ButtonSignal")
        self.wndFonts:FindChild("ChooseBtn"):AddEventHandler("ButtonSignal", "OnSaveFont", self)
        self.wndFonts:FindChild("CloseButton"):AddEventHandler("ButtonSignal", "OnToggleFonts", self)
        self.wndFonts:SetData(wndControl:GetData())

        local wndFontList = self.wndFonts:FindChild("Container"):FindChild("List")
        local wndText = wndControl:GetParent():FindChild("FontText")
        local tFonts = {}

        for _, font in ipairs(Apollo.GetGameFonts()) do
            if not string.match(font.name,"Alien") and not tFonts[font.name] then
                local wndFont = Apollo.LoadForm(self.xmlDoc, "Items:FontItem", wndFontList, self)
                local nFontSize = font.size * 2
                tFonts[font.name] = true

                wndFont:SetAnchorOffsets(0,0,0,(nFontSize > 50 and nFontSize or 50))
                wndFont:FindChild("SelectBtn"):SetText("This is a dummy message!")
                wndFont:FindChild("SelectBtn"):SetFont(font.name)
                wndFont:FindChild("SelectBtn"):SetData({sFont = font.name, nSize = font.size})

                if wndText and font.name == wndText:GetText() then
                    wndFont:FindChild("SelectBtn"):SetCheck(true)
                else
                    wndFont:FindChild("SelectBtn"):SetCheck(false)
                end
            end
        end

        wndFontList:ArrangeChildrenVert()
    end
end

function Settings:OnSelectFont(wndHandler, wndControl, eMouseButton)
    if eMouseButton == GameLib.CodeEnumInputMouse.Right then
         return false
    end

    if not self.wndFonts then
        return
    end

    self.wndFonts:FindChild("ChooseBtn"):SetData(wndControl:GetData())
end

function Settings:OnSaveFont(wndHandler, wndControl)
    if not self.wndFonts then
        return
    end

    local tData = wndControl:GetData()
    local setting = self.core:Copy(self.wndFonts:GetData()[1])
    local wndText = self.wndFonts:GetData()[2]

    if not tData or not setting or not wndText then
        return
    end

    if wndText then
        wndText:SetText(tData.sFont)
    end

    self:SetVar(setting,tData.sFont)

    setting[#setting] = "fontsize"
    self:SetVar(setting,tData.nSize)

    self.wndFonts:Close()
end

function Settings:OnResetModuleBtn(wndHandler, wndControl)
    if wndHandler ~= wndControl then
        return
    end

    if not self.current or not self.current.encounter then
        return
    end

    local module = self.core.modules[self.current.encounter]

    if not module then
        return
    end

    module.config = nil
    RequestReloadUI()
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

    if self.core.bIsRunning then
        self.core:Print("You are infight.")
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

function Settings:OnRefresh(sId)
    if sId:match("timer") then
        self.core:AddTimer(sId, "60 Second Timer", 60, {enable=true}, Settings.OnRefresh, sId)
    elseif sId == "aura" then
        self.core:ShowAura("aura", {enable=true,sprite="LUIBM_run"}, 15, "Run away little girl!", Settings.OnRefresh, "aura")
    elseif sId == "cast" then
        self.core:ShowCast({sName = "cast", nDuration = 20, nElapsed = 0, nTick = Apollo.GetTickCount()}, "Castbar", {enable=true}, Settings.OnRefresh, "cast")
    end
end

function Settings:OnLock(state)
    if not self.core then
        return
    end

    self.core.bIsLocked = not state

    if state then
        Apollo.RegisterEventHandler("FrameCount", "OnUpdate", self.core)

        self.core:AddTimer("timer_1", "60 Second Timer", 60, {enable=true}, Settings.OnRefresh, "timer_1")
        self.core:AddTimer("timer_2", "45 Second Timer", 45, {enable=true}, Settings.OnRefresh, "timer_2")
        self.core:AddTimer("timer_3", "30 Second Timer", 30, {enable=true}, Settings.OnRefresh, "timer_3")
        self.core:AddTimer("timer_4", "15 Second Timer", 15, {enable=true}, Settings.OnRefresh, "timer_4")

        self.core:AddUnit("unit_1", "Unit A", self.core.unitPlayer, {enable=true, position=1})
        self.core:AddUnit("unit_2", "Unit B", self.core.unitPlayer, {enable=true, position=2})
        self.core:AddUnit("unit_3", "Unit C", self.core.unitPlayer, {enable=true, position=3})

        self.core:ShowAura("aura", {enable=true,sprite="LUIBM_run"}, 15, "Run away little girl!", Settings.OnRefresh, "aura")
        self.core:ShowAlert("alert", "This is a dummy message!", {enable=true, duration=600})
        self.core:ShowCast({sName = "cast", nDuration = 20, nElapsed = 0, nTick = Apollo.GetTickCount()}, "Castbar", {enable=true}, Settings.OnRefresh, "cast")
    else
        Apollo.RemoveEventHandler("FrameCount",self.core)

        self.core:RemoveTimer("timer_1")
        self.core:RemoveTimer("timer_2")
        self.core:RemoveTimer("timer_3")
        self.core:RemoveTimer("timer_4")

        self.core:RemoveUnit("unit_1")
        self.core:RemoveUnit("unit_2")
        self.core:RemoveUnit("unit_3")

        self.core:HideAura("aura")
        self.core:HideAlert("alert")
        self.core:HideCast()
    end

    if self.core.wndTimers then
        self.core.wndTimers:SetStyle("Moveable", state)
        self.core.wndTimers:SetStyle("Sizable", state)
        self.core.wndTimers:SetStyle("IgnoreMouse", not state)
        self.core.wndTimers:Show(state,true)
    end

    if self.core.wndUnits then
        self.core.wndUnits:SetStyle("Moveable", state)
        self.core.wndUnits:SetStyle("Sizable", state)
        self.core.wndUnits:SetStyle("IgnoreMouse", not state)
        self.core.wndUnits:Show(state,true)
    end

    if self.core.wndCastbar then
        self.core.wndCastbar:SetStyle("Moveable", state)
        self.core.wndCastbar:SetStyle("Sizable", state)
        self.core.wndCastbar:SetStyle("IgnoreMouse", not state)
        self.core.wndCastbar:Show(state,true)
    end

    if self.core.wndAura then
        self.core.wndAura:SetStyle("Moveable", state)
        self.core.wndAura:SetStyle("Sizable", state)
        self.core.wndAura:SetStyle("IgnoreMouse", not state)
        self.core.wndAura:Show(state,true)
    end

    if self.core.wndAlerts then
        self.core.wndAlerts:SetStyle("Moveable", state)
        self.core.wndAlerts:SetStyle("IgnoreMouse", not state)
        self.core.wndAlerts:Show(state,true)
    end

    if state then
        if not self.wndLock then
            self.wndLock = Apollo.LoadForm(self.xmlDoc, "Lock", nil, self)
            self.wndLock:Show(true,true)
        end
    else
        if self.wndLock then
            self.wndLock:Destroy()
            self.wndLock = nil
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
                if not self.config[setting[1]] then
                    self.config[setting[1]] = {}
                end

                if not self.config[setting[1]][setting[2]] then
                    self.config[setting[1]][setting[2]] = {}
                end

                self.config[setting[1]][setting[2]][setting[3]] = value
            elseif #setting == 2 then
                if not self.config[setting[1]] then
                    self.config[setting[1]] = {}
                end

                self.config[setting[1]][setting[2]] = value
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
                if not config[setting[1]] then
                    config[setting[1]] = {}
                end

                if not config[setting[1]][setting[2]] then
                    config[setting[1]][setting[2]] = {}
                end

                config[setting[1]][setting[2]][setting[3]] = value
            elseif #setting == 2 then
                if not config[setting[1]] then
                    config[setting[1]] = {}
                end

                config[setting[1]][setting[2]] = value
            end
        end
    end
end

LUI_BossMods.settings = Settings:new()
