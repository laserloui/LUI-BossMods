require "Window"
require "Apollo"
require "ICCommLib"
require "ICComm"
require "Unit"
require "Sound"
require "Vector3"

local LUI_BossMods = {}
local TemplateDraw = {}
local GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local JSON = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage

local ipairs, pairs = ipairs, pairs
local table = table
local math = math
local string = string

local GetPlayerUnit = GameLib.GetPlayerUnit
local GetUnitById = GameLib.GetUnitById
local GetCurrentZoneMap = GameLib.GetCurrentZoneMap
local WorldLocToScreenPoint = GameLib.WorldLocToScreenPoint
local GetPlayerDeathState = GameLib.GetPlayerDeathState
local GetTickCount = Apollo.GetTickCount
local Vector3 = Vector3
local NewVector3 = Vector3.New

local NO_BREAK_SPACE = string.char(194, 160)
local FPOINT_NULL = { 0, 0, 0, 0 }
local DEFAULT_NORTH_FACING = { x = 0, y = 0, z = -1.0 }
local TEMPLATE_DRAW_META = { __index = TemplateDraw }
local CHANNEL_HANDLERS = {
    [ChatSystemLib.ChatChannel_Say] = nil,
    [ChatSystemLib.ChatChannel_Party] = nil,
    [ChatSystemLib.ChatChannel_NPCSay] = "OnNPCSay",
    [ChatSystemLib.ChatChannel_NPCYell] = "OnNPCYell",
    [ChatSystemLib.ChatChannel_NPCWhisper] = "OnNPCWhisper",
    [ChatSystemLib.ChatChannel_Datachron] = "OnDatachron",
}

function LUI_BossMods:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.bIsLocked = true
    self.bIsRunning = false
    self.runtime = {}
    self.modules = {}
    self.config = {
        modules = {},
        interval = 100,
        aura = {
            color = "ff00ffff",
            font = "CRB_Header18",
            fontsize = 20,
            offsets = {
                left = -90,
                top = -180,
                right = 90,
                bottom = 0
            },
        },
        icon = {
            color = "ff7fff00",
            size = 160,
        },
        text = {
            color = "ffdbdbdb",
            font = "Subtitle",
            fontsize = 40,
        },
        line = {
            color = "ffff0000",
            thickness = 10,
        },
        focus = {
            line = {
                enable = true,
                thickness = 6,
                color = "ffb0ff2f",
            },
            icon = {
                enable = true,
                sprite = "LUIBM_star",
                color = "ffb0ff2f",
                size = 80,
            },
        },
        sound = {
            enable = true,
            force = false,
            volumeMaster = 0.5,
            volumeMusic = 0,
            volumeUI = 0.5,
            volumeSFX = 0,
            volumeAmbient = 0,
            volumeVoice = 0,
        },
        telegraph = {
            enable = false,
            color = "9affffff",
            fill = 1,
            outline = 1,
        },
        castbar = {
            mooColor = "c89400d3",
            barColor = "c800ffff",
            textColor = "ffebebeb",
            offsets = {
                left = -275,
                top = -350,
                right = 275,
                bottom = -300
            },
        },
        timer = {
            barHeight = 32,
            barColor = "c800ffff",
            textColor = "ffebebeb",
            soundPack = "male",
            countdown = "long1",
            offsets = {
                left = -650,
                top = -300,
                right = -360,
                bottom = 0
            },
        },
        units = {
            enable = true,
            showText = false,
            healthHeight = 32,
            shieldHeight = 10,
            castColor = "c8778899",
            mooColor = "ff9400d3",
            healthColor = "c8adff2f",
            shieldColor = "c800ffff",
            absorbColor = "c8ffd700",
            textColor = "ffebebeb",
            offsets = {
                left = 390,
                top = -150,
                right = 660,
                bottom = 150
            },
        },
        alerts = {
            color = "ff00ffff",
            font = "CRB_Header20",
            fontsize = 20,
            duration = 3,
            offsets = {
                left = -300,
                top = -260,
                right = 300,
                bottom = -200
            },
        },
        settings = {
            offsets = {
                left = -600,
                top = -420,
                right = 600,
                bottom = 420
            },
        },
    }
    return o
end

function LUI_BossMods:Init()
    Apollo.RegisterAddon(self, true, "LUI BossMods", {"LUI_Media"})
end

function LUI_BossMods:OnDependencyError(strDependency, strError)
    return true
end

function LUI_BossMods:OnLoad()
    Apollo.RegisterEventHandler("UnitCreated", "OnPreloadUnitCreated", self)

    self.xmlDoc = XmlDoc.CreateFromFile("LUI_BossMods.xml")
    self.xmlDoc:RegisterCallback("OnDocLoaded", self)

    Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
    Apollo.RegisterEventHandler("PlayerEnteredWorld", "OnCharacterCreated", self)
    Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
    Apollo.RegisterEventHandler("ChangeWorld", "OnChangeZone", self)
    Apollo.RegisterEventHandler("SubZoneChanged", "OnChangeZone", self)
    Apollo.RegisterTimerHandler("CheckZoneTimer", "OnChangeZone", self)
    Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnteredCombat", self)
    Apollo.RegisterEventHandler("LUIBossMods_ToggleMenu", "OnConfigure", self)

    self.wipeTimer = ApolloTimer.Create(0.5, true, "CheckForWipe", self)
    self.wipeTimer:Stop()
end

function LUI_BossMods:OnDocLoaded()
    if not self.xmlDoc or not self.xmlDoc:IsLoaded() then
        return
    end

    Apollo.LoadSprites("Sprites.xml")
    Apollo.RegisterSlashCommand("bm", "OnSlashCommand", self)
    Apollo.RegisterSlashCommand("luibm", "OnSlashCommand", self)
    Apollo.RegisterSlashCommand("bossmod", "OnSlashCommand", self)

    self:LoadWindows()
    self:LoadModules()
    self:LoadSettings()

    self.SaveTelegraphTimer = ApolloTimer.Create(3, false, "SaveTelegraphColor", self)
    self.CheckVolumeTimer = ApolloTimer.Create(3, false, "CheckVolume", self)
    self.CheckConnectionTimer = ApolloTimer.Create(1, false, "Connect", self)

    if self.tPreloadUnits then
        self:CreateUnitsFromPreload()
    end

    -- Find System Chat Channel
    for idx, channelCurrent in ipairs(ChatSystemLib.GetChannels()) do
        if channelCurrent:GetName() == "System" then
            self.system = channelCurrent:GetUniqueId()
        elseif channelCurrent:GetName() == "Systeme" then
            self.system = channelCurrent:GetUniqueId()
        end
    end

    self:OnCharacterCreated()
end

function LUI_BossMods:OnCharacterCreated()
    if self.unitPlayer and self.unitPlayer:IsValid() then
        if self.unitPlayerTimer then
            self.unitPlayerTimer:Stop()
            self.unitPlayerTimer = nil
        end

        self:OnChangeZone()
        self:OnEnteredCombat(self.unitPlayer,self.unitPlayer:IsInCombat())
    else
        self.unitPlayer = GetPlayerUnit()

        if not self.unitPlayerTimer then
            self.unitPlayerTimer = ApolloTimer.Create(0.1, false, "OnCharacterCreated", self)
        end

        self.unitPlayerTimer:Start()
    end
end

function LUI_BossMods:Print(message)
    if self.system then
        ChatSystemLib.PostOnChannel(self.system,message,"LUI_BossMods")
    else
        Print(message)
    end
end

function LUI_BossMods:LoadModules()
    if self.modules then
        for sName,tModule in pairs(self.modules) do
            tModule:Init(self)
        end
    end
end

function LUI_BossMods:LoadSettings()
    if self.settings then
        self.settings:Init(self)
    else
        self:Print("Settings unable to load.")
    end
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # ZONES
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:OnChangeZone()
    local zone = GetCurrentZoneMap()

    if zone then
        self.zone = {
            strName = zone.strName,
            continentId = zone.continentId,
            parentZoneId = zone.parentZoneId,
            mapId = zone.id,
        }

        self:SearchForEncounter()
    else
        Apollo.CreateTimer("CheckZoneTimer", 1, false)
    end
end

function LUI_BossMods:CheckZone(tModule)
    if not self.zone or not tModule or not tModule.tTrigger or not tModule.tTrigger.tZones then
        return false
    end

    for _,tZone in ipairs(tModule.tTrigger.tZones) do
        if tZone.continentId == self.zone.continentId and (tZone.parentZoneId == self.zone.parentZoneId or tZone.parentZoneId == 0) and (tZone.mapId == self.zone.mapId or tZone.mapId == 0) then
            return true
        end
    end

    return false
end

function LUI_BossMods:SearchForEncounter()
    if not self.zone then
        self:OnChangeZone()
        return
    end

    if not self.unitPlayer or not self.unitPlayer:IsValid() then
        self.unitPlayer = GetPlayerUnit()
    end

    if self.bIsRunning and self.tCurrentEncounter then
        if self:CheckZone(self.tCurrentEncounter) then
            return
        else
            self:ResetFight()
        end
    end

    if self.unitPlayer:IsInCombat() then
        for sName,tModule in pairs(self.modules) do
            if tModule and tModule:IsEnabled() and not tModule:IsRunning() then
                if self:CheckZone(tModule) then
                    if self:CheckTrigger(tModule) then
                        self.tCurrentEncounter = tModule
                        self:StartFight()
                        return
                    end
                end
            end
        end
    end
end

function LUI_BossMods:CheckTrigger(tModule)
    if not tModule or not tModule.tTrigger then
        return false
    end

    if not tModule.tTrigger.sType or not tModule.tTrigger.tNames or not type(tModule.tTrigger.tNames) == "table" or not #tModule.tTrigger.tNames then
        return true
    end

    if not self.tSavedUnits or not tModule.L then
        return false
    end

    if tModule.tTrigger.sType == "ANY" then
        for _,sName in ipairs(tModule.tTrigger.tNames) do
            local unitName = tModule.L[sName] or sName

            if self.tSavedUnits[unitName] then
                for nId, unit in pairs(self.tSavedUnits[unitName]) do
                    if unit:IsInCombat() then
                        return true
                    end
                end
            end
        end

        return false
    elseif tModule.tTrigger.sType == "ALL" then
        for _,sName in ipairs(tModule.tTrigger.tNames) do
            local unitName = tModule.L[sName] or sName

            if not self.tSavedUnits[unitName] then
                return false
            else
                local combat = false

                for nId, unit in pairs(self.tSavedUnits[unitName]) do
                    if unit:IsInCombat() then
                        combat = true
                        break
                    end
                end

                if not combat then
                    return false
                end
            end
        end

        return true
    end

    return false
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # FIGHT
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:OnFrame()
    if (not self.bIsRunning or not self.tCurrentEncounter) and not self.bHasFocus then
        return
    end

    local tick = GetTickCount()

    if not self.nLastFrameCheck then
        self.nLastFrameCheck = tick
    elseif (tick - self.nLastFrameCheck) > 20 then
        if self.tDraws then
            for key,draw in pairs(self.tDraws) do
                if draw.sType == "Icon" then
                    self:UpdateIcon(key,draw)
                elseif draw.sType == "Text" then
                    self:UpdateText(key,draw)
                elseif draw.sType == "Polygon" then
                    self:UpdatePolygon(key,draw)
                elseif draw.sType == "Line" then
                    self:UpdateLine(key,draw)
                elseif draw.sType == "LineBetween" then
                    self:UpdateLineBetween(key,draw)
                end
            end
        end

        self.nLastFrameCheck = tick
    end
end

function LUI_BossMods:OnUpdate()
    if (not self.bIsRunning or not self.tCurrentEncounter) and self.bIsLocked and not self.bHasFocus then
        return
    end

    local tick = GetTickCount()

    if not self.nLastCheck then
        self.nLastCheck = tick
    elseif (tick - self.nLastCheck) > self.config.interval then
        if self.runtime.units then
            for _,tUnit in pairs(self.runtime.units) do
                if not tUnit.runtime then
                    tUnit.runtime = {}
                end

                -- Update Unit Frame
                self:UpdateUnit(tUnit)

                -- Check Casts
                self:CheckCast(tUnit)
            end
        end

        if self.runtime.cast then
            self:UpdateCast()
        end

        if self.runtime.aura then
            self:UpdateAura()
        end

        if self.runtime.timer then
            for _,timer in pairs(self.runtime.timer) do
                self:UpdateTimer(timer)
            end
            self:SortTimer()
        end

        if self.runtime.alerts then
            for _,alert in pairs(self.runtime.alerts) do
                self:UpdateAlert(alert)
            end
        end

        self.nLastCheck = tick
    end
end

function LUI_BossMods:StartFight()
    if not self.tCurrentEncounter then
        return
    end

    if not self.bIsLocked then
        self.settings:OnLock(false)
    end

    self:OnBreakEnd()
    self.bIsRunning = true
    self.tCurrentEncounter:OnEnable()
    self:ProcessSavedUnits()
    self:SetTelegraphColor(self.tCurrentEncounter.config.telegraph)

    Apollo.RemoveEventHandler("FrameCount",self)
    Apollo.RegisterEventHandler("FrameCount", "OnUpdate", self)

    Apollo.RemoveEventHandler("NextFrame",self)
    Apollo.RegisterEventHandler("NextFrame", "OnFrame", self)

    Apollo.RemoveEventHandler("ChatMessage",self)
    Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self)

    Apollo.RemoveEventHandler("BuffAdded",self)
    Apollo.RegisterEventHandler("BuffAdded", "OnBuffAdded", self)

    Apollo.RemoveEventHandler("BuffUpdated",self)
    Apollo.RegisterEventHandler("BuffUpdated", "OnBuffUpdated", self)

    Apollo.RemoveEventHandler("BuffRemoved",self)
    Apollo.RegisterEventHandler("BuffRemoved", "OnBuffRemoved", self)
end

function LUI_BossMods:ResetFight()
    self.bIsRunning = false
    self.wipeTimer:Stop()

    Apollo.RemoveEventHandler("FrameCount",self)
    Apollo.RemoveEventHandler("ChatMessage",self)
    Apollo.RemoveEventHandler("BuffAdded",self)
    Apollo.RemoveEventHandler("BuffUpdated",self)
    Apollo.RemoveEventHandler("BuffRemoved",self)

    if not self.bHasFocus then
        Apollo.RemoveEventHandler("NextFrame",self)
    end

    if self.tCurrentEncounter then
        self:RestoreTelegraphColor(self.tCurrentEncounter.config.telegraph)
        self.tCurrentEncounter:OnDisable()
        self.tCurrentEncounter = nil
    end

    if self.tDraws then
        for key,draw in pairs(self.tDraws) do
            if draw.sType and key ~= "FOCUS_ICON" and key ~= "FOCUS_LINE" then
                if draw.sType == "Icon" then
                    self:RemoveIcon(key)
                elseif draw.sType == "Text" then
                    self:RemoveText(key)
                elseif draw.sType == "Polygon" then
                    self:RemovePolygon(key)
                elseif draw.sType == "Line" then
                    self:RemoveLine(key)
                elseif draw.sType == "LineBetween" then
                    self:RemoveLineBetween(key)
                end

                self.tDraws[key] = nil
            end
        end
    end

    if self.wndUnits:IsShown() then
        self.wndUnits:DestroyChildren()
        self.wndUnits:Show(false,true)
    end

    if self.wndTimers:IsShown() then
        self.wndTimers:DestroyChildren()
        self.wndTimers:Show(false,true)
    end

    if self.wndCastbar:IsShown() then
        self.wndCastbar:Show(false,true)
    end

    if self.wndAura:IsShown() then
        self.wndAura:Show(false,true)
    end

    if self.wndAlerts:IsShown() then
        self.wndAlerts:DestroyChildren()
        self.wndAlerts:Show(false,true)
    end

    if not self.bHasFocus then
        self.tDraws = nil
        self.wndOverlay:DestroyAllPixies()
    end

    self.runtime = {}
end

function LUI_BossMods:CheckForWipe()
    if not self.bIsRunning then
        self.wipeTimer:Stop()
    end

    local tPlayerDeathState = GetPlayerDeathState()

    if tPlayerDeathState and not tPlayerDeathState.bAcceptCasterRez then
        return
    end

    for i = 1, GroupLib.GetMemberCount() do
        local tUnit = GroupLib.GetUnitForGroupMember(i)
        if tUnit and tUnit:IsInCombat() then
            return
        end
    end

    self:ResetFight()
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # DATACHRON
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:OnChatMessage(tChannelCurrent, tMessage)
    if tChannelCurrent then
        local nChannelType = tChannelCurrent:GetType()
        local sHandler = CHANNEL_HANDLERS[nChannelType]
        if sHandler then
            local sMessage = ""
            local sSender = tMessage.strSender or ""
            sSender:gsub(NO_BREAK_SPACE, " ")

            for _,tSegment in ipairs(tMessage.arMessageSegments) do
                sMessage = sMessage .. tSegment.strText:gsub(NO_BREAK_SPACE, " ")
            end

            if self.tCurrentEncounter and self.tCurrentEncounter.OnDatachron then
                self.tCurrentEncounter:OnDatachron(sMessage, sSender, sHandler)
            end
        end
    end
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # UNITS
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:OnPreloadUnitCreated(unitNew)
    if not self.tPreloadUnits then
        self.tPreloadUnits = {}
    end

    self.tPreloadUnits[#self.tPreloadUnits + 1] = unitNew
end

function LUI_BossMods:CreateUnitsFromPreload()
    self.unitPlayer = GetPlayerUnit()

    self.timerPreloadUnitCreateDelay = ApolloTimer.Create(0.5, true, "OnPreloadUnitCreateTimer", self)
    self:OnPreloadUnitCreateTimer()
end

function LUI_BossMods:OnPreloadUnitCreateTimer()
    if self.unitPlayer then
        Apollo.RemoveEventHandler("UnitCreated", self)

        Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
        Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
        Apollo.RegisterEventHandler("AlternateTargetUnitChanged", "OnAlternateTargetUnitChanged", self)

        self:OnAlternateTargetUnitChanged(self.unitPlayer:GetAlternateTarget())

        if self.tPreloadUnits then
            local nCurrentTime = GetTickCount()

            while #self.tPreloadUnits > 0 do
                local unit = table.remove(self.tPreloadUnits, #self.tPreloadUnits)

                if unit:IsValid() then
                    self:OnUnitCreated(unit)
                end

                if GetTickCount() - nCurrentTime > 500 then
                    return
                end
            end
        end

        if self.timerPreloadUnitCreateDelay then
            self.timerPreloadUnitCreateDelay:Stop()
        end

        self.tPreloadUnits = nil
        self.timerPreloadUnitCreateDelay = nil
    end
end

function LUI_BossMods:OnUnitCreated(unit)
    if self.bIsRunning then
        if self.runtime.buffs and self.runtime.buffs[unit:GetId()] then
            self:CheckBuffs(unit)
        end

        if self.tCurrentEncounter and self.tCurrentEncounter.OnUnitCreated then
            self.tCurrentEncounter:OnUnitCreated(unit:GetId(),unit,unit:GetName(),unit:IsInCombat())
        end
    else
        if unit:IsThePlayer() then
            self:OnEnteredCombat(unit,unit:IsInCombat())
        else
            if not self.tSavedUnits then
                self.tSavedUnits = {}
            end

            if not self.tSavedUnits[unit:GetName()] then
                self.tSavedUnits[unit:GetName()] = {}
            end

            if not self.tSavedUnits[unit:GetName()][unit:GetId()] then
                self.tSavedUnits[unit:GetName()][unit:GetId()] = unit
            end
        end
    end
end

function LUI_BossMods:OnUnitDestroyed(unit)
    if self.bIsRunning then
        self:RemoveUnit(unit:GetId())

        if self.tCurrentEncounter and self.tCurrentEncounter.OnUnitDestroyed then
            self.tCurrentEncounter:OnUnitDestroyed(unit:GetId(),unit,unit:GetName())
        end
    end

    if self.runtime.buffs and self.runtime.buffs[unit:GetId()] then
        self.runtime.buffs[unit:GetId()] = nil
    end

    if self.tSavedUnits and self.tSavedUnits[unit:GetName()] and self.tSavedUnits[unit:GetName()][unit:GetId()] then
        self.tSavedUnits[unit:GetName()][unit:GetId()] = nil
    end
end

function LUI_BossMods:OnEnteredCombat(unit, bInCombat)
    if unit:IsThePlayer() then
        if bInCombat then
            if not self.bIsRunning then
                self:SearchForEncounter()
            end

            if self.tCurrentEncounter and self.tCurrentEncounter.OnUnitCreated then
                self.tCurrentEncounter:OnUnitCreated(unit:GetId(),unit,unit:GetName(),bInCombat)
            end
        else
            if self.bIsRunning then
                self.wipeTimer:Start()
            end
        end
    else
        if not unit:IsInYourGroup() then
            if self.bIsRunning then
                if self.tCurrentEncounter and self.tCurrentEncounter.OnUnitCreated then
                    self.tCurrentEncounter:OnUnitCreated(unit:GetId(),unit,unit:GetName(),bInCombat)
                end
            else
                if not self.tSavedUnits then
                    self.tSavedUnits = {}
                end

                if not self.tSavedUnits[unit:GetName()] then
                    self.tSavedUnits[unit:GetName()] = {}
                end

                if not self.tSavedUnits[unit:GetName()][unit:GetId()] then
                    self.tSavedUnits[unit:GetName()][unit:GetId()] = unit
                end

                if bInCombat then
                    self:SearchForEncounter()
                end
            end
        end
    end
end

function LUI_BossMods:ProcessSavedUnits()
    if not self.tSavedUnits then
        return
    end

    for _,tUnit in pairs(self.tSavedUnits) do
        for _,unit in pairs(tUnit) do
            self:OnUnitCreated(unit)
        end
    end
end

function LUI_BossMods:OnAlternateTargetUnitChanged(unit)
    if not self.config.focus or (not self.config.focus.line.enable and not self.config.focus.icon.enable) then
        return
    end

    if unit ~= nil and unit ~= self.unitPlayer and unit:GetHealth() ~= nil and unit:GetMaxHealth() > 0 then
        if self.config.focus.line.enable then
            self:DrawLineBetween("FOCUS_LINE", unit, nil, self.config.focus.line)
        end

        if self.config.focus.icon.enable then
            self:DrawIcon("FOCUS_ICON", unit, self.config.focus.icon, true)
        end

        if not self.bHasFocus then
            self.bHasFocus = true
            Apollo.RemoveEventHandler("NextFrame",self)
            Apollo.RegisterEventHandler("NextFrame", "OnFrame", self)
        end
    else
        if self.bHasFocus then
            self.bHasFocus = false
            self:RemoveLineBetween("FOCUS_LINE")
            self:RemoveIcon("FOCUS_ICON")

            if not self.bIsRunning then
                Apollo.RemoveEventHandler("NextFrame",self)
            end
        end
    end
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # TRACKED UNITS
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:AddUnit(nId,sName,tUnit,tConfig,sMark)
    if not nId or not sName or not tUnit or not tUnit:IsValid() then
        return
    end

    if not self.runtime.units then
        self.runtime.units = {}
    end

    if not self.runtime.units[nId] then
        self.runtime.units[nId] = {
            nId = nId,
            sName = sName,
            tUnit = tUnit
        }

        self:CheckBuffs(tUnit)

        if tConfig then
            self.runtime.units[nId].sMark = sMark or nil
            self.runtime.units[nId].sColor = tConfig.color or nil
            self.runtime.units[nId].nPosition = tConfig.position or 99
            self.runtime.units[nId].bShowUnit = tConfig.enable or false

            if tConfig.enable and self.config.units.enable then
                if not self.wndUnits then
                    self:LoadWindows()
                end

                if not self.wndUnits:IsShown() then
                    self.wndUnits:Show(true,true)
                end

                self.runtime.units[nId].wnd = self:StyleUnit(Apollo.LoadForm(self.xmlDoc, "Unit", self.wndUnits, self),self.runtime.units[nId])
                self:SortUnits()
            end
        end
    end
end

function LUI_BossMods:StyleUnit(wnd,tData)
    if not wnd or not tData then
        return nil
    end

    wnd:SetAnchorOffsets(0,0,0,(self.config.units.healthHeight + 15))

    local childHealthBar = wnd:FindChild("HealthBar")
    childHealthBar:FindChild("Progress"):SetBGColor(tData.sColor or self.config.units.healthColor)
    childHealthBar:FindChild("Text"):SetTextColor(self.config.units.textColor)

    local childShieldBar = wnd:FindChild("ShieldBar")
    childShieldBar:SetAnchorOffsets(4,(((self.config.units.shieldHeight/2)+15)*-1),0,((self.config.units.shieldHeight/2)-15))
    childShieldBar:FindChild("Progress"):SetBGColor(self.config.units.shieldColor)
    childShieldBar:FindChild("Text"):SetTextColor(self.config.units.textColor)
    childShieldBar:FindChild("Text"):Show(self.config.units.showText,true)

    local childName = wnd:FindChild("Name")
    childName:SetText(tData.sName)
    childName:SetTextColor(self.config.units.textColor)

    local childMark = wnd:FindChild("Mark")
    childMark:SetText(tData.sMark)
    childMark:Show(tData.sMark ~= nil,true)

    local childCastBar = wnd:FindChild("CastBar")
    childCastBar:SetAnchorOffsets(0,(((self.config.units.shieldHeight/2)+15)*-1),0,((self.config.units.shieldHeight/2)-15))
    childCastBar:FindChild("Progress"):SetBGColor(self.config.units.castColor)
    childCastBar:FindChild("Text"):SetTextColor(self.config.units.textColor)

    return wnd
end

function LUI_BossMods:SortUnits()
    if not self.runtime.units then
        return
    end

    local tSorted = {}
    local height = self.config.units.healthHeight + 15

    for nId,unit in pairs(self.runtime.units) do
        tSorted[#tSorted+1] = {
            nId = nId,
            nPosition = unit.nPosition or 99
        }
    end

    table.sort(tSorted, function(a, b)
        return a.nPosition < b.nPosition
    end)

    for i=1,#tSorted do
        local tUnit = self.runtime.units[tSorted[i].nId]

        if tUnit.wnd then
            local tOffsets = {0,(height * (i-1)),0,(height * i)}

            if tUnit.nCurrentPosition then
                if tUnit.nCurrentPosition ~= i then
                    tUnit.wnd:TransitionMove(WindowLocation.new({fPoints = {0,0,1,0}, nOffsets = tOffsets}), .25)
                end
            else
                tUnit.wnd:SetAnchorOffsets(unpack(tOffsets))
            end

            tUnit.nCurrentPosition = i
        end
    end
end

function LUI_BossMods:UpdateUnit(tData)
    if not tData or not type(tData) == "table" then
        return
    end

    -- Health
    local bIsDead = tData.tUnit:IsDead()
    local nHealth = tData.tUnit:GetHealth() or 0
    local nHealthMax = tData.tUnit:GetMaxHealth() or 0
    local nHealthPercent = (nHealth * 100) / nHealthMax
    local nHealthProgress = nHealthPercent / 100

    if bIsDead then
        nHealthPercent = 0
    end

    if nHealthProgress ~= (tData.runtime.health or 0) then
        if tData.wnd then
            tData.wnd:FindChild("HealthBar"):FindChild("Text"):SetText(nHealthPercent > 0 and string.format("%.1f%%", nHealthPercent) or "DEAD")
            tData.wnd:FindChild("HealthBar"):FindChild("Progress"):TransitionMove(WindowLocation.new({fPoints = {0, 0, nHealthProgress, 1}}), .075)
        end

        tData.runtime.health = nHealthProgress

        if self.tCurrentEncounter and self.tCurrentEncounter.OnHealthChanged then
            self.tCurrentEncounter:OnHealthChanged(tData.nId, nHealthPercent, tData.sName, tData.tUnit)
        end
    end

    if not tData.wnd then
        return
    end

    -- Absorb
    local nAbsorb = tData.tUnit:GetAbsorptionValue() or 0
    local nAbsorbMax = tData.tUnit:GetAbsorptionMax() or 0
    local nAbsorbPercent = (nAbsorb * 100) / nAbsorbMax
    local nAbsorbProgress = nAbsorbPercent / 100

    if bIsDead then
        nAbsorbProgress = 0
    end

    if nAbsorb > 0 then
        if not tData.wnd:FindChild("ShieldBar"):IsShown() then
            tData.wnd:FindChild("ShieldBar"):Show(true,true)
        end

        if not tData.runtime.bShowAbsorb then
            tData.runtime.bShowAbsorb = true
            tData.wnd:FindChild("ShieldBar"):FindChild("Progress"):SetBGColor(self.config.units.absorbColor)
        end

        if nAbsorbProgress ~= (tData.runtime.absorb or 0) then
            tData.wnd:FindChild("ShieldBar"):FindChild("Text"):SetText(self:HelperFormatBigNumber(nAbsorb))
            tData.wnd:FindChild("ShieldBar"):FindChild("Progress"):TransitionMove(WindowLocation.new({fPoints = {0, 0, nAbsorbProgress, 1}}), .075)
            tData.runtime.absorb = nAbsorbProgress
        end
    else
        if tData.runtime.bShowAbsorb ~= nil then
            tData.wnd:FindChild("ShieldBar"):FindChild("Progress"):SetBGColor(self.config.units.shieldColor)
            tData.runtime.bShowAbsorb = nil
            tData.runtime.absorb = nil
        end

        -- Shield
        local nShield = tData.tUnit:GetShieldCapacity() or 0
        local nShieldMax = tData.tUnit:GetShieldCapacityMax() or 0
        local nShieldPercent = (nShield * 100) / nShieldMax
        local nShieldProgress = nShieldPercent / 100

        if bIsDead then
            nShieldProgress = 0
        end

        if nShield > 0 then
            if not tData.wnd:FindChild("ShieldBar"):IsShown() then
                tData.wnd:FindChild("ShieldBar"):Show(true,true)
            end

            if nShieldProgress ~= (tData.runtime.shield or 0) then
                tData.wnd:FindChild("ShieldBar"):FindChild("Text"):SetText(self:HelperFormatBigNumber(nShield))
                tData.wnd:FindChild("ShieldBar"):FindChild("Progress"):TransitionMove(WindowLocation.new({fPoints = {0, 0, nShieldProgress, 1}}), .075)
                tData.runtime.shield = nShieldProgress
            end
        else
            if tData.wnd:FindChild("ShieldBar"):IsShown() then
                tData.wnd:FindChild("ShieldBar"):Show(false,true)
                tData.runtime.shield = nil
            end
        end
    end

    -- Cast
    if tData.tCast then
        if tData.runtime.shield or tData.runtime.absorb then
            if tData.runtime.isMax then
                tData.wnd:FindChild("CastBar"):SetAnchorPoints(0.05,1,0.65,1)
                tData.runtime.isMax = nil
            end
        else
            if not tData.runtime.isMax then
                tData.wnd:FindChild("CastBar"):SetAnchorPoints(0.05,1,0.95,1)
                tData.runtime.isMax = true
            end
        end

        if not tData.tCast.bIsRunning then
            local nRemaining = (tData.tCast.nDuration - tData.tCast.nElapsed)
            local nElapsed = (tData.tCast.nElapsed * 100) / tData.tCast.nDuration
            local nProgress = nElapsed / 100
            local fPoint = 1

            if tData.tCast.sName == "MOO" then
                fPoint = 0
                nProgress = 1 - nProgress
                tData.wnd:FindChild("CastBar"):FindChild("Progress"):SetBGColor(self.config.units.mooColor)
            else
                tData.wnd:FindChild("CastBar"):FindChild("Progress"):SetBGColor(self.config.units.castColor)
            end

            tData.wnd:FindChild("CastBar"):FindChild("Text"):SetText(tData.tCast.sName)
            tData.wnd:FindChild("CastBar"):FindChild("Progress"):SetAnchorPoints(0, 0, nProgress, 1)
            tData.wnd:FindChild("CastBar"):FindChild("Progress"):TransitionMove(WindowLocation.new({fPoints = {0, 0, fPoint, 1}}), nRemaining)
            tData.wnd:FindChild("CastBar"):Show(true,true)
            tData.tCast.bIsRunning = true
        end
    else
        if tData.wnd:FindChild("CastBar"):IsShown() then
            tData.wnd:FindChild("CastBar"):Show(false,true)
        end
    end
end

function LUI_BossMods:RemoveUnit(nId)
    if not nId then
        return
    end

    if self.runtime.buffs and self.runtime.buffs[nId] then
        self.runtime.buffs[nId] = nil
    end

    if not self.runtime.units or not self.runtime.units[nId] then
        return
    end

    if self.runtime.units[nId].wnd then
        self.runtime.units[nId].wnd:Destroy()
    end

    self.runtime.units[nId] = nil
    self:SortUnits()
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # BUFFS & DEBUFFS
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:CheckBuffs(tUnit)
    if not tUnit or not tUnit:IsValid() or not self.tCurrentEncounter then
        return
    end

    local nId = tUnit:GetId()
    local tBuffs = tUnit:GetBuffs()
    local bMember = tUnit:IsInYourGroup()
    local tCurrent = (self.runtime.buffs and self.runtime.buffs[nId]) and self:Copy(self.runtime.buffs[nId]) or nil

    -- Process Buffs
    if not bMember and tBuffs and tBuffs.arBeneficial then
        for i=1, #tBuffs.arBeneficial do
            if tCurrent then
                local nSpellId = tBuffs.arBeneficial[i].splEffect:GetId()

                if not tCurrent[nSpellId] then
                    self:OnBuffAdded(tUnit, tBuffs.arBeneficial[i])
                else
                    table.remove(tCurrent, nSpellId)
                end
            else
                self:OnBuffAdded(tUnit, tBuffs.arBeneficial[i])
            end
        end
    end

    -- Process Debuffs
    if tBuffs and tBuffs.arHarmful then
        for i=1, #tBuffs.arHarmful do
            if tCurrent then
                local nSpellId = tBuffs.arHarmful[i].splEffect:GetId()

                if not tCurrent[nSpellId] then
                    self:OnBuffAdded(tUnit, tBuffs.arHarmful[i])
                else
                    table.remove(tCurrent, nSpellId)
                end
            else
                self:OnBuffAdded(tUnit, tBuffs.arHarmful[i])
            end
        end
    end

    -- Process Removed Buffs
    if tCurrent and #tCurrent then
        for _,spell in ipairs(tCurrent) do
            self:OnBuffRemoved(tUnit, spell)
        end
    end
end

function LUI_BossMods:OnBuffAdded(unit,spell)
    if not unit or not spell or not self.tCurrentEncounter then
        return
    end

    local buff = spell.splEffect:IsBeneficial()
    local nUnitId = unit:GetId()
    local nSpellId = spell.splEffect:GetId()

    if not self.runtime.buffs then
        self.runtime.buffs = {}
    end

    if not self.runtime.buffs[nUnitId] then
        self.runtime.buffs[nUnitId] = {}
    end

    if self.runtime.buffs[nUnitId][nSpellId] then
        self:OnBuffUpdated(unit,spell)
        return
    end

    if self.runtime.units and self.runtime.units[nUnitId] then
        local tData = {
            nId = nSpellId,
            sName = spell.splEffect:GetName(),
            nDuration = spell.fTimeRemaining,
            nTick = GetTickCount(),
            nCount = spell.nCount,
            nUnitId = nUnitId,
            sUnitName = unit:GetName(),
            tUnit = unit,
            tSpell = spell,
        }

        if self.tCurrentEncounter and self.tCurrentEncounter.OnBuffAdded then
            self.tCurrentEncounter:OnBuffAdded(tData.nUnitId, tData.nId, tData.sName, tData, tData.sUnitName, spell.nCount, spell.fTimeRemaining)
        end

        self.runtime.buffs[nUnitId][nSpellId] = tData
    elseif (unit:IsInYourGroup() or unit:IsThePlayer()) and not buff then
        local tData = {
            nId = nSpellId,
            sName = spell.splEffect:GetName(),
            nDuration = spell.fTimeRemaining,
            nTick = GetTickCount(),
            nCount = spell.nCount,
            nUnitId = nUnitId,
            sUnitName = unit:GetName(),
            tUnit = unit,
            tSpell = spell,
        }

        if self.tCurrentEncounter and self.tCurrentEncounter.OnBuffAdded then
            self.tCurrentEncounter:OnBuffAdded(tData.nUnitId, tData.nId, tData.sName, tData, tData.sUnitName, spell.nCount, spell.fTimeRemaining)
        end

        self.runtime.buffs[nUnitId][nSpellId] = tData
    end
end

function LUI_BossMods:OnBuffUpdated(unit,spell)
    if not unit or not spell or not self.tCurrentEncounter then
        return
    end

    local buff = spell.splEffect:IsBeneficial()
    local nUnitId = unit:GetId()
    local nSpellId = spell.splEffect:GetId()

    if not self.runtime.buffs or not self.runtime.buffs[nUnitId] or not self.runtime.buffs[nUnitId][nSpellId] then
        self:OnBuffAdded(unit,spell)
        return
    end

    if self.runtime.units and self.runtime.units[nUnitId] then
        local tData = {
            nId = nSpellId,
            sName = spell.splEffect:GetName(),
            nDuration = spell.fTimeRemaining,
            nTick = GetTickCount(),
            nCount = spell.nCount,
            nUnitId = nUnitId,
            sUnitName = unit:GetName(),
            tUnit = unit,
            tSpell = spell,
        }

        if self.tCurrentEncounter and self.tCurrentEncounter.OnBuffUpdated then
            self.tCurrentEncounter:OnBuffUpdated(tData.nUnitId, tData.nId, tData.sName, tData, tData.sUnitName, spell.nCount, spell.fTimeRemaining)
        end
    elseif (unit:IsInYourGroup() or unit:IsThePlayer()) and not buff then
        local tData = {
            nId = nSpellId,
            sName = spell.splEffect:GetName(),
            nDuration = spell.fTimeRemaining,
            nTick = GetTickCount(),
            nCount = spell.nCount,
            nUnitId = nUnitId,
            sUnitName = unit:GetName(),
            tUnit = unit,
            tSpell = spell,
        }

        if self.tCurrentEncounter and self.tCurrentEncounter.OnBuffUpdated then
            self.tCurrentEncounter:OnBuffUpdated(tData.nUnitId, tData.nId, tData.sName, tData, tData.sUnitName, spell.nCount, spell.fTimeRemaining)
        end
    end
end

function LUI_BossMods:OnBuffRemoved(unit,spell)
    if not unit or not spell or not self.tCurrentEncounter then
        return
    end

    local buff = spell.splEffect:IsBeneficial()
    local nUnitId = unit:GetId()
    local nSpellId = spell.splEffect:GetId()

    if not self.runtime.buffs or not self.runtime.buffs[nUnitId] or not self.runtime.buffs[nUnitId][nSpellId] then
        return
    end

    if self.runtime.units and self.runtime.units[nUnitId] then
        local tData = {
            nId = nSpellId,
            sName = spell.splEffect:GetName(),
            nUnitId = nUnitId,
            sUnitName = unit:GetName(),
            tUnit = unit,
            tSpell = spell,
        }

        if self.tCurrentEncounter and self.tCurrentEncounter.OnBuffRemoved then
            self.tCurrentEncounter:OnBuffRemoved(tData.nUnitId, tData.nId, tData.sName, tData, tData.sUnitName)
        end

        self.runtime.buffs[nUnitId][nSpellId] = nil
    elseif (unit:IsInYourGroup() or unit:IsThePlayer()) and not buff then
        local tData = {
            nId = nSpellId,
            sName = spell.splEffect:GetName(),
            nUnitId = nUnitId,
            sUnitName = unit:GetName(),
            tUnit = unit,
            tSpell = spell,
        }

        if self.tCurrentEncounter and self.tCurrentEncounter.OnBuffRemoved then
            self.tCurrentEncounter:OnBuffRemoved(tData.nUnitId, tData.nId, tData.sName, tData, tData.sUnitName)
        end

        self.runtime.buffs[nUnitId][nSpellId] = nil
    end
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # TIMERS
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:AddTimer(sName, sText, nDuration, tConfig, fHandler, tData)
    if not sName or not nDuration or not tConfig or not tConfig.enable then
        return
    end

    if not self.wndTimers then
        self:LoadWindows()
    end

    if not self.runtime.timer then
        self.runtime.timer = {}
    end

    if not self.wndTimers:IsShown() then
        self.wndTimers:Show(true,true)
    end

    if not self.runtime.timer[sName] then
        self.runtime.timer[sName] = {
            sName = sName,
            wnd = Apollo.LoadForm(self.xmlDoc, "Timer", self.wndTimers, self)
        }
    end

    self.runtime.timer[sName].nTick = GetTickCount()
    self.runtime.timer[sName].sText = sText or sName
    self.runtime.timer[sName].nDuration = nDuration
    self.runtime.timer[sName].bSound = tConfig.sound or false
    self.runtime.timer[sName].bAlert = tConfig.alert or false
    self.runtime.timer[sName].sColor = tConfig.color or self.config.timer.barColor
    self.runtime.timer[sName].fHandler = fHandler or nil
    self.runtime.timer[sName].tData = tData or nil

    self.runtime.timer[sName].wnd:FindChild("Name"):SetText(sText or sName)
    self.runtime.timer[sName].wnd:FindChild("Duration"):SetTextColor(self.config.timer.textColor)
    self.runtime.timer[sName].wnd:FindChild("Duration"):SetText(Apollo.FormatNumber(nDuration,1,true))
    self.runtime.timer[sName].wnd:FindChild("Progress"):SetBGColor(tConfig.color or self.config.timer.barColor)
    self.runtime.timer[sName].wnd:FindChild("Progress"):SetAnchorPoints(0,0,1,1)
    self.runtime.timer[sName].wnd:Show(false,true)
end

function LUI_BossMods:UpdateTimer(tTimer)
    if not tTimer or not tTimer.nTick or not tTimer.nDuration then
        return
    end

    local nTick = GetTickCount()
    local nElapsed = (nTick - tTimer.nTick) / 1000
    local nRemaining = tTimer.nDuration - nElapsed
    local nPrevCountdown = tTimer.nCountDown or 6
    local nCountDown = -1

    if string.match(self.config.timer.countdown,"long") then
        if nRemaining < 5.4 and nPrevCountdown > 5 then
            nCountDown = 5
        elseif nRemaining < 4.4 and nPrevCountdown == 5 then
            nCountDown = 4
        end
    end

    if nRemaining < 3.4 and nPrevCountdown >= 4 then
        nCountDown = 3
    elseif nRemaining < 2.4 and nPrevCountdown == 3 then
        nCountDown = 2
    elseif nRemaining < 1.4 and nPrevCountdown == 2 then
        nCountDown = 1
    end

    if string.match(self.config.timer.countdown,"1") then
        if nRemaining < 0.4 and nPrevCountdown == 1 then
            nCountDown = 0
        end
    end

    if tTimer.bAlert and nCountDown >= 0 then
        self:ShowAlert("COUNTDOWN", nCountDown > 0 and nCountDown or "NOW!", {
            enable = true,
            duration = 1,
            color = self.config.alerts.color,
        })
        tTimer.nCountDown = nCountDown
    end

    if tTimer.bSound and nCountDown >= 0 then
        self:PlaySound(tostring(nCountDown),self.config.timer.soundPack)
        tTimer.nCountDown = nCountDown
    end

    if tTimer.nRemaining and (nRemaining > tTimer.nRemaining) then
        tTimer.nCountDown = nil
    end

    if tTimer.nRemaining and (nElapsed >= tTimer.nDuration) then
        self:RemoveTimer(tTimer.sName)
    else
        tTimer.nRemaining = nRemaining

        if nRemaining < 60 then
            tTimer.wnd:FindChild("Duration"):SetText(Apollo.FormatNumber(nRemaining,1,true))
        else
            tTimer.wnd:FindChild("Duration"):SetText(ConvertSecondsToTimer(nRemaining))
        end
    end
end

function LUI_BossMods:RemoveTimer(sName)
    if not sName or not self.runtime.timer or not self.runtime.timer[sName] then
        return
    end

    local tCallback = {
        fHandler = self.runtime.timer[sName].fHandler,
        tData = self.runtime.timer[sName].tData
    }

    self.runtime.timer[sName].wnd:Destroy()
    self.runtime.timer[sName] = nil

    self:Callback(tCallback.fHandler, tCallback.tData)
end

function LUI_BossMods:SortTimer()
    if not self.runtime.timer then
        return
    end

    local tSorted = {}
    local height = self.config.timer.barHeight + 6

    for _,timer in pairs(self.runtime.timer) do
        if timer.nRemaining then
            table.insert(tSorted, {
                sName = timer.sName,
                nRemaining = timer.nRemaining,
            })
        end
    end

    table.sort(tSorted, function(a, b)
        return a.nRemaining < b.nRemaining
    end)

    for i=0,#tSorted-1 do
        local tTimer = self.runtime.timer[tSorted[i+1].sName]
        local tOffsets = {0,(height * (i+1)) * -1,0,(height * i) * -1}

        if not tTimer.wnd:IsShown() then
            tTimer.wnd:SetAnchorOffsets(unpack(tOffsets))
            tTimer.wnd:FindChild("Progress"):TransitionMove(WindowLocation.new({fPoints = {0, 0, 0, 1}}), tTimer.nRemaining or tTimer.nDuration)
            tTimer.wnd:Show(true,true)
        else
            if tTimer.nPosition ~= nil and tTimer.nPosition ~= i then
                tTimer.wnd:TransitionMove(WindowLocation.new({fPoints = {0,1,1,1}, nOffsets = tOffsets}), .25)
            end
        end

        tTimer.nPosition = i
    end
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # CASTS
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:CheckCast(tData)
    if not tData or not tData.tUnit or not self.tCurrentEncounter then
        return
    end

    local sName
    local nElapsed
    local bCasting = false
    local nDuration = tData.tUnit:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability)

    if nDuration ~= nil and nDuration > 0 then
        bCasting = true
        nElapsed = 0
        sName = "MOO"
    end

    if not bCasting then
        bCasting = tData.tUnit:IsCasting()

        if bCasting then
            sName = tData.tUnit:GetCastName() or ""
            nElapsed = tData.tUnit:GetCastElapsed() / 1000
            nDuration = tData.tUnit:GetCastDuration() / 1000
            bCasting = tData.tUnit:IsCasting()
        end
    end

    if bCasting then
        local nTick = GetTickCount()
        sName = string.gsub(sName, NO_BREAK_SPACE, " ")

        if not tData.tCast and nDuration > nElapsed then
            -- New cast
            tData.tCast = {
                sName = sName,
                nDuration = nDuration,
                nElapsed = nElapsed,
                nTick = nTick,
                nUnitId = tData.nId,
                sUnitName = tData.sName,
                tUnit = tData.tUnit,
            }

            if self.tCurrentEncounter and self.tCurrentEncounter.OnCastStart then
                self.tCurrentEncounter:OnCastStart(tData.nId, sName, tData.tCast, tData.sName, nDuration)
            end

            return
        elseif tData.tCast then
            if sName ~= tData.tCast.sName or nElapsed < tData.tCast.nElapsed then
                -- New cast just after a previous one.
                if self.runtime.cast and self.runtime.cast.nUnitId == tData.nId then
                    self:HideCast()
                end

                if self.tCurrentEncounter and self.tCurrentEncounter.OnCastEnd then
                    self.tCurrentEncounter:OnCastEnd(tData.nId, tData.tCast.sName, tData.tCast, tData.sName)
                end

                tData.tCast = {
                    sName = sName,
                    nDuration = nDuration,
                    nElapsed = nElapsed,
                    nTick = nTick,
                    nUnitId = tData.nId,
                    sUnitName = tData.sName,
                    tUnit = tData.tUnit,
                }

                if self.tCurrentEncounter and self.tCurrentEncounter.OnCastStart then
                    self.tCurrentEncounter:OnCastStart(tData.nId, sName, tData.tCast, tData.sName, nDuration)
                end

                return
            else
                if nTick > (tData.tCast.nTick + (tData.tCast.nDuration * 1000)) then
                    -- End of cast
                    if self.runtime.cast and self.runtime.cast.nUnitId == tData.nId then
                        self:HideCast()
                    end

                    if self.tCurrentEncounter and self.tCurrentEncounter.OnCastEnd then
                        self.tCurrentEncounter:OnCastEnd(tData.nId, tData.tCast.sName, tData.tCast, tData.sName)
                    end

                    tData.tCast = nil
                    return
                else
                    -- Cast Running
                    tData.tCast.nElapsed = nElapsed
                    return
                end
            end
        end
    else
        if self.runtime.cast and self.runtime.cast.nUnitId == tData.nId then
            self:HideCast()
        end

        if tData.tCast then
            if self.tCurrentEncounter and self.tCurrentEncounter.OnCastEnd then
                self.tCurrentEncounter:OnCastEnd(tData.nId, tData.tCast.sName, tData.tCast, tData.sName)
            end

            tData.tCast = nil
        end

        return
    end
end

function LUI_BossMods:ShowCast(tCast,sName,tConfig,fHandler,tData)
    if not tCast or not tConfig or not tConfig.enable then
        return
    end

    tCast.fHandler = fHandler or nil
    tCast.tData = tData or nil

    if not self.wndCastbar then
        self:LoadWindows()
    end

    local nRemaining = (tCast.nDuration - tCast.nElapsed)
    local nElapsed = (tCast.nElapsed * 100) / tCast.nDuration
    local nProgress = nElapsed / 100
    local fPoint = 1

    if tCast.sName == "MOO" then
        fPoint = 0
        nProgress = 1 - nProgress
        self.wndCastbar:FindChild("Progress"):SetBGColor(tConfig.color or self.config.castbar.mooColor)
        self.wndCastbar:FindChild("Duration"):SetText()
    else
        self.wndCastbar:FindChild("Progress"):SetBGColor(tConfig.color or self.config.castbar.barColor)
        self.wndCastbar:FindChild("Duration"):SetTextColor(self.config.castbar.textColor)
        self.wndCastbar:FindChild("Duration"):SetText(Apollo.FormatNumber(nRemaining,1,true))
    end

    local sCastName = sName

    if not sCastName then
        sCastName = (tCast.sName == "MOO") and (tCast.sUnitName or "") or (tCast.sName or "")
    end

    self.wndCastbar:FindChild("Name"):SetTextColor(self.config.castbar.textColor)
    self.wndCastbar:FindChild("Name"):SetText(sCastName)
    self.wndCastbar:FindChild("Progress"):SetAnchorPoints(0, 0, nProgress, 1)
    self.wndCastbar:FindChild("Progress"):TransitionMove(WindowLocation.new({fPoints = {0, 0, fPoint, 1}}), nRemaining)

    if not self.wndCastbar:IsShown() then
        self.wndCastbar:Show(true,true)
    end

    self.runtime.cast = tCast
end

function LUI_BossMods:UpdateCast()
    if not self.runtime.cast then
        if self.wndCastbar:IsShown() then
            self.wndCastbar:Show(false,true)
        end

        return
    end

    local tCast = self.runtime.cast
    local nRemaining = (tCast.nDuration - tCast.nElapsed)

    if not self.bIsLocked then
        nRemaining = ((tCast.nTick + (tCast.nDuration * 1000)) - GetTickCount()) / 1000
    end

    if (tCast.nElapsed > tCast.nDuration) or nRemaining <= 0 then
        self:HideCast()
    else
        if tCast.sName ~= "MOO" then
            self.wndCastbar:FindChild("Duration"):SetText(Apollo.FormatNumber(nRemaining,1,true))
        end
    end
end

function LUI_BossMods:HideCast()
    local tCallback = {
        fHandler = self.runtime.cast.fHandler,
        tData = self.runtime.cast.tData
    }

    if self.wndCastbar:IsShown() then
        self.wndCastbar:Show(false,true)
    end

    self.runtime.cast = nil
    self:Callback(tCallback.fHandler, tCallback.tData)
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # AURAS
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:ShowAura(sName, tConfig, nDuration, sText, fHandler, tData)
    if not sName or not tConfig or not tConfig.enable then
        return
    end

    if not self.wndAura then
        self:LoadWindows()
    end

    local nWidth = (sText and sText ~= "") and (Apollo.GetTextWidth(self.config.aura.font or "CRB_Header18", sText) + 30) / 2 or 100
    local nHeight = (self.config.aura.fontsize or 20) + 30

    self.wndAura:FindChild("Icon"):SetSprite(tConfig.sprite or "")
    self.wndAura:FindChild("Icon"):SetBGColor(tConfig.color or self.config.aura.color)

    self.wndAura:FindChild("Text"):SetAnchorOffsets((nWidth*-1),0,nWidth,nHeight)
    self.wndAura:FindChild("Text"):SetText(sText or "")
    self.wndAura:FindChild("Text"):SetFont(self.config.aura.font or "CRB_Header18")
    self.wndAura:FindChild("Text"):SetTextColor(tConfig.color or self.config.aura.color)
    self.wndAura:FindChild("Text"):Show(sText or false,true)

    self.wndAura:FindChild("Overlay"):SetBGColor("a0000000")
    self.wndAura:FindChild("Overlay"):Show(true,true)

    self.wndAura:FindChild("Progress"):SetBGColor("96"..string.sub(tConfig.color or self.config.aura.color,3))
    self.wndAura:FindChild("Progress"):SetBarColor("96"..string.sub(tConfig.color or self.config.aura.color,3))
    self.wndAura:FindChild("Progress"):SetMax(100)

    if nDuration then
        self.wndAura:FindChild("Progress"):SetProgress(0.001)
        self.wndAura:FindChild("Progress"):SetProgress(99.999,(100/nDuration))
    else
        self.wndAura:FindChild("Progress"):SetProgress(99.999)
    end

    self.runtime.aura = {
        sName = sName,
        nTick = nDuration and GetTickCount() or nil,
        nDuration = nDuration or nil,
        fHandler = fHandler or nil,
        tData = tData or nil
    }

    if not self.wndAura:IsShown() then
        self.wndAura:Show(true,true)
    end
end

function LUI_BossMods:UpdateAura()
    if not self.runtime.aura or not self.runtime.aura.nTick then
        return
    end

    local tAura = self.runtime.aura
    local nTick = GetTickCount()
    local nTotal = tAura.nDuration
    local nElapsed = (nTick - tAura.nTick) / 1000

    if nElapsed > nTotal then
        self:HideAura(tAura.sName)
    end
end

function LUI_BossMods:HideAura(sName)
    if not sName or not self.runtime.aura then
        return
    end

    if self.runtime.aura.sName == sName then
        local tCallback = {
            fHandler = self.runtime.aura.fHandler,
            tData = self.runtime.aura.tData
        }

        self.runtime.aura = nil

        if self.wndAura:IsShown() then
            self.wndAura:Show(false,true)
        end

        self:Callback(tCallback.fHandler, tCallback.tData)
    end
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # ALERTS
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:ShowAlert(sName, sText, tConfig, fHandler, tData)
    if not sName or not sText or not tConfig or not tConfig.enable then
        return
    end

    if not self.wndAlerts then
        self:LoadWindows()
    end

    if not self.runtime.alerts then
        self.runtime.alerts = {}
    end

    if not self.runtime.alerts[sName] then
        self.runtime.alerts[sName] = {
            sName = sName,
            wnd = Apollo.LoadForm(self.xmlDoc, "Alert", self.wndAlerts, self)
        }
    end

    self.runtime.alerts[sName].nTick = GetTickCount()
    self.runtime.alerts[sName].nDuration = tConfig.duration or self.config.alerts.duration
    self.runtime.alerts[sName].fHandler = fHandler or nil
    self.runtime.alerts[sName].tData = tData or nil

    local nHeight = (self.config.alerts.fontsize or 20) * 2
    self.runtime.alerts[sName].wnd:SetText(sText or "")
    self.runtime.alerts[sName].wnd:SetFont(self.config.alerts.font)
    self.runtime.alerts[sName].wnd:SetTextColor(tConfig.color or self.config.alerts.color)
    self.runtime.alerts[sName].wnd:SetAnchorOffsets(0,0,0,nHeight)

    for id,alert in pairs(self.runtime.alerts) do
        if id ~= sName then
            local _,offsetTop = alert.wnd:GetAnchorOffsets()
            local tOffsets = {0, offsetTop + (nHeight * -1), 0, offsetTop}
            alert.wnd:SetAnchorOffsets(unpack(tOffsets))
        end
    end

    if not self.runtime.alerts[sName].wnd:IsShown() then
        self.runtime.alerts[sName].wnd:Show(true,false,0.5)
    end

    if not self.wndAlerts:IsShown() then
        self.wndAlerts:Show(true,true)
    end
end

function LUI_BossMods:UpdateAlert(tAlert)
    if not tAlert or not tAlert.nTick or not tAlert.nDuration then
        return
    end

    local nTick = GetTickCount()
    local nTotal = tAlert.nDuration
    local nElapsed = (nTick - tAlert.nTick) / 1000

    if nElapsed > nTotal then
        self:HideAlert(tAlert.sName)
    end
end

function LUI_BossMods:HideAlert(sName)
    if not sName or not self.runtime.alerts or not self.runtime.alerts[sName] then
        return
    end

    local tCallback = {
        fHandler = self.runtime.alerts[sName].fHandler,
        tData = self.runtime.alerts[sName].tData
    }

    self.runtime.alerts[sName].wnd:Destroy()
    self.runtime.alerts[sName] = nil
    self:Callback(tCallback.fHandler, tCallback.tData)
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # SOUNDS
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:PlaySound(sound,folder)
    if not sound then
        return
    end

    if type(sound) == "string" and sound ~= "" then
        self:SetVolume()

        if folder and folder ~= "" then
            Sound.PlayFile("Sounds\\"..folder.."\\"..sound..".wav")
        else
            Sound.PlayFile("Sounds\\"..sound..".wav")
        end
    elseif type(sound) == "table" and sound.enable then
        self:SetVolume()
        Sound.PlayFile("Sounds\\"..sound.file..".wav")
    else
        return
    end

    if self.config.sound.force then
        if not self.VolumeTimer then
            self.VolumeTimer = ApolloTimer.Create(3, false, "RestoreVolume", self)
            self.VolumeTimer:Start()
        else
            self.VolumeTimer:Stop()
            self.VolumeTimer:Start()
        end
    end
end

function LUI_BossMods:CheckVolume()
    local mute = Apollo.GetConsoleVariable("sound.mute")

    if not self.tVolume then
        self.tVolume = {}
    end

    if mute then
        Apollo.SetConsoleVariable("sound.mute", false)
        Apollo.SetConsoleVariable("sound.volumeMaster", 0.5)
        Apollo.SetConsoleVariable("sound.volumeUI", 0)
        Apollo.SetConsoleVariable("sound.volumeMusic", 0)
        Apollo.SetConsoleVariable("sound.volumeSfx", 0)
        Apollo.SetConsoleVariable("sound.volumeAmbient", 0)
        Apollo.SetConsoleVariable("sound.volumeVoice", 0)
    end

    self.tVolume.Master = Apollo.GetConsoleVariable("sound.volumeMaster")
    self.tVolume.Music = Apollo.GetConsoleVariable("sound.volumeMusic")
    self.tVolume.Interface = Apollo.GetConsoleVariable("sound.volumeUI")
    self.tVolume.Sfx = Apollo.GetConsoleVariable("sound.volumeSfx")
    self.tVolume.Ambient = Apollo.GetConsoleVariable("sound.volumeAmbient")
    self.tVolume.Voice = Apollo.GetConsoleVariable("sound.volumeVoice")

    if self.tVolume.Interface < 0.1 then
        self.tVolume.Interface = 0
        Apollo.SetConsoleVariable("sound.volumeMaster", 0)
        Apollo.SetConsoleVariable("sound.volumeUI", 1)
        ApolloTimer.Create(2, false, "RestoreVolumeUI", self)
    end
end

function LUI_BossMods:RestoreVolumeUI()
    Apollo.SetConsoleVariable("sound.volumeUI", 0)
    Apollo.SetConsoleVariable("sound.volumeMaster", self.tVolume.Master)
end

function LUI_BossMods:RestoreVolume()
    if self.config.sound.force then
        Apollo.SetConsoleVariable("sound.volumeMaster", self.tVolume.Master)
        Apollo.SetConsoleVariable("sound.volumeMusic", self.tVolume.Music)
        Apollo.SetConsoleVariable("sound.volumeUI", self.tVolume.Interface)
        Apollo.SetConsoleVariable("sound.volumeSfx", self.tVolume.Sfx)
        Apollo.SetConsoleVariable("sound.volumeAmbient", self.tVolume.Ambient)
        Apollo.SetConsoleVariable("sound.volumeVoice", self.tVolume.Voice)
    end
end

function LUI_BossMods:SetVolume()
    if self.config.sound.force then
        Apollo.SetConsoleVariable("sound.volumeMaster", self.config.sound.volumeMaster)
        Apollo.SetConsoleVariable("sound.volumeMusic", self.config.sound.volumeMusic)
        Apollo.SetConsoleVariable("sound.volumeUI", self.config.sound.volumeUI)
        Apollo.SetConsoleVariable("sound.volumeSfx", self.config.sound.volumeSFX)
        Apollo.SetConsoleVariable("sound.volumeAmbient", self.config.sound.volumeAmbient)
        Apollo.SetConsoleVariable("sound.volumeVoice", self.config.sound.volumeVoice)
    end
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # TELEGRAPH COLORS
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:SaveTelegraphColor()
    self.nTelegraphColorSet = Apollo.GetConsoleVariable("spell.telegraphColorSet")
	self.tTelegraphColor = {
		Apollo.GetConsoleVariable("spell.custom1EnemyNPCDetrimentalTelegraphColorR"),
		Apollo.GetConsoleVariable("spell.custom1EnemyNPCDetrimentalTelegraphColorG"),
		Apollo.GetConsoleVariable("spell.custom1EnemyNPCDetrimentalTelegraphColorB"),
		Apollo.GetConsoleVariable("spell.fillOpacityCustom1_34"),
		Apollo.GetConsoleVariable("spell.outlineOpacityCustom1_34"),
	}
end

function LUI_BossMods:SetTelegraphColor(tTelegraphColor)
    if not tTelegraphColor or not tTelegraphColor.enable then
        return
    end

    local r,g,b = GeminiColor:HexToRGBA(tTelegraphColor.color or self.config.telegraph.color)

    Apollo.SetConsoleVariable("spell.telegraphColorSet", 4)
	Apollo.SetConsoleVariable("spell.custom1EnemyNPCDetrimentalTelegraphColorR", r)
	Apollo.SetConsoleVariable("spell.custom1EnemyNPCDetrimentalTelegraphColorG", g)
	Apollo.SetConsoleVariable("spell.custom1EnemyNPCDetrimentalTelegraphColorB", b)
	Apollo.SetConsoleVariable("spell.fillOpacityCustom1_34", (tTelegraphColor.fill or self.config.telegraph.fill) * 255)
	Apollo.SetConsoleVariable("spell.outlineOpacityCustom1_34", (tTelegraphColor.outline or self.config.telegraph.outline) * 255)
    GameLib.RefreshCustomTelegraphColors()
end

function LUI_BossMods:RestoreTelegraphColor(tTelegraph)
    if not tTelegraph or not tTelegraph.enable then
        return
    end

    Apollo.SetConsoleVariable("spell.telegraphColorSet", self.nTelegraphColorSet)
	Apollo.SetConsoleVariable("spell.custom1EnemyNPCDetrimentalTelegraphColorR", self.tTelegraphColor[1])
	Apollo.SetConsoleVariable("spell.custom1EnemyNPCDetrimentalTelegraphColorG", self.tTelegraphColor[2])
	Apollo.SetConsoleVariable("spell.custom1EnemyNPCDetrimentalTelegraphColorB", self.tTelegraphColor[3])
	Apollo.SetConsoleVariable("spell.fillOpacityCustom1_34", self.tTelegraphColor[4])
	Apollo.SetConsoleVariable("spell.outlineOpacityCustom1_34", self.tTelegraphColor[5])
    GameLib.RefreshCustomTelegraphColors()
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # ONSCREEN DRAWINGS (Where the magic happens!) - Thanks to author(s) of RaidCore
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

-- #########################################################################################################################################
-- # TEXT
-- #########################################################################################################################################

function LUI_BossMods:DrawText(Key, Origin, tConfig, sText, bTop, nOffset, nDuration, fHandler, tData)
    if not Key or not Origin or not tConfig or not tConfig.enable then
        return
    end

    if not self.wndOverlay then
        self:LoadWindows()
    end

    if not self.tDraws then
        self.tDraws = {}
    end

    if self.tDraws[Key] then
        if self.tDraws[Key].wnd then
            self.tDraws[Key].wnd:Show(false,true)
            self.tDraws[Key].wnd:Destroy()
        end

        self.tDraws[Key] = nil
    end

    local OriginType = type(Origin)
    local wnd = Apollo.LoadForm(self.xmlDoc, "Icon", nil, self)
    local width = (sText and sText ~= "") and (Apollo.GetTextWidth(tConfig.font or self.config.text.font, sText) + 30) / 2 or 100

    wnd:SetAnchorOffsets((width*-1),(-50 + (nOffset or 0)),width,(50 + (nOffset or 0)))
    wnd:SetSprite("")
    wnd:SetFont(tConfig.font or self.config.text.font)
    wnd:SetText(sText or "")
    wnd:SetTextColor(tConfig.color or self.config.text.color)

    if OriginType == "number" then
        Origin = GetUnitById(Origin)
        wnd:SetUnit(Origin,bTop and 1 or 0)
    elseif OriginType == "table" or Vector3.Is(Origin) then
        wnd:SetWorldLocation(Origin)
    elseif OriginType == "userdata" and Origin:IsValid() then
        wnd:SetUnit(Origin,bTop and 1 or 0)
    end

    self.tDraws[Key] = {
        nTick = GetTickCount(),
        nDuration = nDuration,
        tOrigin = Origin,
        sType = "Text",
        bShowTimer = tConfig.timer or false,
        fHandler = fHandler,
        tData = tData,
        wnd = wnd
    }
end

function LUI_BossMods:UpdateText(Key,tDraw)
    if tDraw.wnd:IsOnScreen() then
        if not tDraw.wnd:IsShown() then
            tDraw.wnd:Show(true,true)
        end
    else
        if tDraw.wnd:IsShown() then
            tDraw.wnd:Show(false,true)
        end
    end

    if tDraw.nDuration ~= nil and tDraw.nDuration > 0 then
        local nTick = GetTickCount()
        local nTotal = tDraw.nDuration
        local nElapsed = (nTick - tDraw.nTick) / 1000
        local nRemaining = (nTotal - nElapsed)

        if nElapsed > nTotal then
            self:RemoveText(Key)
            return
        else
            if tDraw.bShowTimer then
                tDraw.wnd:SetText(Apollo.FormatNumber(nRemaining,1,true))
            end
        end
    end

    if tDraw.tOrigin and type(tDraw.tOrigin) == "userdata" and not Vector3.Is(tDraw.tOrigin) then
        if not tDraw.tOrigin:IsValid() or tDraw.tOrigin:IsDead() then
            self:RemoveText(Key)
            return
        end
    end
end

function LUI_BossMods:RemoveText(Key)
    if not self.tDraws then
        return
    end

    if self.tDraws[Key] then
        if self.tDraws[Key].wnd then
            self.tDraws[Key].wnd:Show(false,true)
            self.tDraws[Key].wnd:Destroy()
        end

        local tCallback = {
            fHandler = self.tDraws[Key].fHandler,
            tData = self.tDraws[Key].tData
        }

        self.tDraws[Key] = nil
        self:Callback(tCallback.fHandler, tCallback.tData)
    end
end

-- #########################################################################################################################################
-- # ICONS
-- #########################################################################################################################################

function LUI_BossMods:DrawIcon(Key, Origin, tConfig, bTop, nOffset, nDuration, fHandler, tData)
    if not Key or not Origin or not tConfig or not tConfig.enable then
        return
    end

    if not self.wndOverlay then
        self:LoadWindows()
    end

    if not self.tDraws then
        self.tDraws = {}
    end

    if self.tDraws[Key] then
        if self.tDraws[Key].wnd then
            self.tDraws[Key].wnd:Show(false,true)
            self.tDraws[Key].wnd:Destroy()
        end

        self.tDraws[Key] = nil
    end

    local OriginType = type(Origin)
    local nSize = (tConfig.size or self.config.icon.size) / 2
    local wnd = Apollo.LoadForm(self.xmlDoc, "Icon", nil, self)

    wnd:SetAnchorOffsets((nSize*-1),((nSize*-1)+(nOffset or 0)),nSize,(nSize+(nOffset or 0)))
    wnd:SetSprite(tConfig.sprite or "")
    wnd:SetBGColor(tConfig.color or self.config.icon.color)

    if OriginType == "number" then
        Origin = GetUnitById(Origin)
        wnd:SetUnit(Origin,bTop and 1 or 0)
    elseif OriginType == "table" or Vector3.Is(Origin) then
        wnd:SetWorldLocation(Origin)
    elseif OriginType == "userdata" and Origin:IsValid() then
        wnd:SetUnit(Origin,bTop and 1 or 0)
    end

    if nDuration and nDuration > 0 then
        if tConfig.overlay then
            if type(tConfig.overlay) == "table" then
                wnd:FindChild("Overlay"):SetFullSprite(tConfig.overlay.sprite or (tConfig.sprite or ""))
                wnd:FindChild("Overlay"):SetBarColor(tConfig.overlay.color or "a0000000")
                wnd:FindChild("Overlay"):SetBGColor(tConfig.overlay.color or "a0000000")
                wnd:FindChild("Overlay"):SetMax(100)
                wnd:FindChild("Overlay"):SetProgress((tConfig.overlay.invert ~= nil and tConfig.overlay.invert or false) and 99.999 or 0.001)
                wnd:FindChild("Overlay"):SetProgress((tConfig.overlay.invert ~= nil and tConfig.overlay.invert or false) and 0.001 or 99.999,(100/nDuration))
                wnd:FindChild("Overlay"):SetStyleEx("Clockwise", (tConfig.overlay.invert ~= nil and tConfig.overlay.invert or false))
                wnd:FindChild("Overlay"):SetStyleEx("RadialBar", (tConfig.overlay.radial ~= nil and tConfig.overlay.radial or true))
                wnd:FindChild("Overlay"):Show(true,true)
            else
                wnd:FindChild("Overlay"):SetFullSprite(tConfig.sprite or "")
                wnd:FindChild("Overlay"):SetBarColor("a0000000")
                wnd:FindChild("Overlay"):SetBGColor("a0000000")
                wnd:FindChild("Overlay"):SetMax(100)
                wnd:FindChild("Overlay"):SetProgress(0.001)
                wnd:FindChild("Overlay"):SetProgress(99.999,(100/nDuration))
                wnd:FindChild("Overlay"):SetStyleEx("Clockwise", false)
                wnd:FindChild("Overlay"):SetStyleEx("RadialBar", true)
                wnd:FindChild("Overlay"):Show(true,true)
            end

        end
    end

    self.tDraws[Key] = {
        nTick = GetTickCount(),
        nDuration = nDuration,
        tOrigin = Origin,
        sType = "Icon",
        fHandler = fHandler,
        tData = tData,
        wnd = wnd
    }
end

function LUI_BossMods:UpdateIcon(Key,tDraw)
    if tDraw.wnd:IsOnScreen() then
        if not tDraw.wnd:IsShown() then
            tDraw.wnd:Show(true,true)
        end
    else
        if tDraw.wnd:IsShown() then
            tDraw.wnd:Show(false,true)
        end
    end

    if tDraw.nDuration ~= nil and tDraw.nDuration > 0 then
        local nTick = GetTickCount()
        local nTotal = tDraw.nDuration
        local nElapsed = (nTick - tDraw.nTick) / 1000

        if nElapsed > nTotal then
            self:RemoveIcon(Key)
            return
        end
    end

    if tDraw.tOrigin and type(tDraw.tOrigin) == "userdata" and not Vector3.Is(tDraw.tOrigin) then
        if not tDraw.tOrigin:IsValid() or (tDraw.tOrigin:IsDead() and Key ~= "FOCUS_ICON") then
            self:RemoveIcon(Key)
            return
        end
    end
end

function LUI_BossMods:RemoveIcon(Key)
    if not self.tDraws then
        return
    end

    if self.tDraws[Key] then
        if self.tDraws[Key].wnd then
            self.tDraws[Key].wnd:Show(false,true)
            self.tDraws[Key].wnd:Destroy()
        end

        local tCallback = {
            fHandler = self.tDraws[Key].fHandler,
            tData = self.tDraws[Key].tData
        }

        self.tDraws[Key] = nil
        self:Callback(tCallback.fHandler, tCallback.tData)
    end
end

-- #########################################################################################################################################
-- # POLYGONS
-- #########################################################################################################################################

function LUI_BossMods:DrawPolygon(Key, Origin, tConfig, nRadius, nRotation, nSide, nDuration, tVectorOffsets, fHandler, tData)
    if not Key or not Origin or not tConfig or not tConfig.enable then
        return
    end

    local OriginType = type(Origin)

    if not (OriginType == "number" or OriginType == "table" or OriginType == "userdata") then
        return
    end

    if not self.wndOverlay then
        self:LoadWindows()
    end

    if not self.tDraws then
        self.tDraws = {}
    end

    if self.tDraws[Key] then
        self:RemovePolygon(Key)
    end

    -- Register a new object to manage.
    local tDraw = self.tDraws[Key] or self:NewDraw()
    tDraw.sType = "Polygon"
    tDraw.nRadius = nRadius or 10
    tDraw.nWidth = tConfig.thickness or self.config.line.thickness
    tDraw.nDuration = nDuration or 0
    tDraw.nTick = GetTickCount()
    tDraw.nRotation = nRotation or 0
    tDraw.sColor = tConfig.color or tDraw.sColor
    tDraw.nSide = nSide or 5
    tDraw.nPixieIds = tDraw.nPixieIds or {}
    tDraw.tVectors = tDraw.tVectors or {}
    tDraw.tVectorOffsets = tVectorOffsets or nil
    tDraw.fHandler = fHandler or nil
    tDraw.tData = tData or nil

    if OriginType == "number" then
        tDraw.tOriginUnit = GetUnitById(Origin)
    elseif OriginType == "table" or Vector3.Is(Origin) then
        local tOriginVector = NewVector3(Origin)
        local tFacingVector = NewVector3(DEFAULT_NORTH_FACING)
        local tRefVector = tFacingVector * tDraw.nRadius

        for i = 1, tDraw.nSide do
            local nRad = math.rad(360 * i / tDraw.nSide + tDraw.nRotation)
            local nCos = math.cos(nRad)
            local nSin = math.sin(nRad)
            local CornerRotate = {
                x = NewVector3({ nCos, 0, -nSin }),
                y = NewVector3({ 0, 1, 0 }),
                z = NewVector3({ nSin, 0, nCos }),
            }

            if tDraw.tVectorOffsets then
                if type(tDraw.tVectorOffsets) == "table" then
                    tDraw.tVectorOffsets = NewVector3(tDraw.tVectorOffsets)
                end

                local nRad2 = -math.atan2(tFacingVector.x, tFacingVector.z)
                local nCos2 = math.cos(nRad2)
                local nSin2 = math.sin(nRad2)
                local RotationMatrix = {
                    x = NewVector3({ nCos2, 0, -nSin2 }),
                    y = NewVector3({ 0, 1, 0 }),
                    z = NewVector3({ nSin2, 0, nCos2 }),
                }

                tDraw.tVectors[i] = tOriginVector + self:Rotation(tRefVector, CornerRotate) + self:Rotation(tDraw.tVectorOffsets, RotationMatrix)
            else
                tDraw.tVectors[i] = tOriginVector + self:Rotation(tRefVector, CornerRotate)
            end
        end
    elseif OriginType == "userdata" then
        tDraw.tOriginUnit = Origin
    end

    self.tDraws[Key] = tDraw
end

function LUI_BossMods:UpdatePolygon(Key,tDraw)
    local tVectors

    if tDraw.nDuration ~= nil and tDraw.nDuration > 0 then
        local nTick = GetTickCount()
        local nTotal = tDraw.nDuration
        local nElapsed = (nTick - tDraw.nTick) / 1000

        if nElapsed > nTotal then
            self:RemovePolygon(Key)
            return
        end
    end

    if tDraw.tOriginUnit then
        if not tDraw.tOriginUnit:IsValid() or tDraw.tOriginUnit:IsDead() then
            self:RemovePolygon(Key)
            return
        else
            local tOriginVector = NewVector3(tDraw.tOriginUnit:GetPosition())
            local tFacingVector = NewVector3(tDraw.tOriginUnit:GetFacing())

            if tOriginVector ~= tDraw.tOriginVector or tFacingVector ~= tDraw.tFacingVector then
                local tRefVector = tFacingVector * tDraw.nRadius

                for i = 1, tDraw.nSide do
                    local nRad = math.rad(360 * i / tDraw.nSide + tDraw.nRotation)
                    local nCos = math.cos(nRad)
                    local nSin = math.sin(nRad)
                    local CornerRotate = {
                        x = NewVector3({ nCos, 0, -nSin }),
                        y = NewVector3({ 0, 1, 0 }),
                        z = NewVector3({ nSin, 0, nCos }),
                    }

                    if tDraw.tVectorOffsets then
                        if type(tDraw.tVectorOffsets) == "table" then
                            tDraw.tVectorOffsets = NewVector3(tDraw.tVectorOffsets)
                        end

                        local nRad2 = -math.atan2(tFacingVector.x, tFacingVector.z)
                        local nCos2 = math.cos(nRad2)
                        local nSin2 = math.sin(nRad2)
                        local RotationMatrix = {
                            x = NewVector3({ nCos2, 0, -nSin2 }),
                            y = NewVector3({ 0, 1, 0 }),
                            z = NewVector3({ nSin2, 0, nCos2 }),
                        }

                        tDraw.tVectors[i] = tOriginVector + self:Rotation(tRefVector, CornerRotate) + self:Rotation(tDraw.tVectorOffsets, RotationMatrix)
                    else
                        tDraw.tVectors[i] = tOriginVector + self:Rotation(tRefVector, CornerRotate)
                    end
                end

                tDraw.tOriginVector = tOriginVector
                tDraw.tFacingVector = tFacingVector
                tVectors = tDraw.tVectors
            else
                tVectors = tDraw.tVectors
            end
        end
    else
        if tDraw.tVectors then
            tVectors = tDraw.tVectors
        else
            self:RemovePolygon(Key)
            return
        end
    end

    if tVectors then
        -- Convert all 3D coordonate of game in 2D coordonnate of screen
        local tScreenLoc = {}
        for i = 1, tDraw.nSide do
            tScreenLoc[i] = WorldLocToScreenPoint(tVectors[i])
        end

        for i = 1, tDraw.nSide do
            local j = i == tDraw.nSide and 1 or i + 1
            if tScreenLoc[i].z > 0 or tScreenLoc[j].z > 0 then
                local tPixieAttributs = {
                    bLine = true,
                    fWidth = tDraw.nWidth,
                    cr = tDraw.sColor,
                    loc = {
                        fPoints = FPOINT_NULL,
                        nOffsets = {
                            tScreenLoc[i].x,
                            tScreenLoc[i].y,
                            tScreenLoc[j].x,
                            tScreenLoc[j].y,
                        },
                    },
                }

                if tDraw.nPixieIds[i] then
                    self.wndOverlay:UpdatePixie(tDraw.nPixieIds[i], tPixieAttributs)
                else
                    tDraw.nPixieIds[i] = self.wndOverlay:AddPixie(tPixieAttributs)
                end
            else
                -- The Line is out of sight.
                if tDraw.nPixieIds[i] then
                    self.wndOverlay:DestroyPixie(tDraw.nPixieIds[i])
                    tDraw.nPixieIds[i] = nil
                end
            end
        end
    else
        -- Unit is not valid.
        for i = 1, tDraw.nSide do
            if tDraw.nPixieIds[i] then
                self.wndOverlay:DestroyPixie(tDraw.nPixieIds[i])
                tDraw.nPixieIds[i] = nil
            end
        end
    end
end

function LUI_BossMods:RemovePolygon(Key)
    if not self.tDraws then
        return
    end

    local tDraw = self.tDraws[Key]

    if tDraw then
        for i = 1, tDraw.nSide do
            if tDraw.nPixieIds[i] then
                self.wndOverlay:DestroyPixie(tDraw.nPixieIds[i])
                tDraw.nPixieIds[i] = nil
            end
        end

        local tCallback = {
            fHandler = tDraw.fHandler,
            tData = tDraw.tData
        }

        self.tDraws[Key] = nil
        self:Callback(tCallback.fHandler, tCallback.tData)
    end
end

-- #########################################################################################################################################
-- # LINES
-- #########################################################################################################################################

function LUI_BossMods:DrawLine(Key, Origin, tConfig, nLength, nRotation, nOffset, tVectorOffsets, nDuration, nNumberOfDot, fHandler, tData)
    if not Key or not Origin or not tConfig or not tConfig.enable then
        return
    end

    local OriginType = type(Origin)

    if not (OriginType == "number" or OriginType == "table" or OriginType == "userdata") then
        return
    end

    if not self.wndOverlay then
        self:LoadWindows()
    end

    if not self.tDraws then
        self.tDraws = {}
    end

    if self.tDraws[Key] then
        self:RemoveLine(Key)
    end

    local tDraw = self.tDraws[Key] or self:NewDraw()
    tDraw.nOffset = nOffset or 0
    tDraw.nLength = nLength or 10
    tDraw.sType = "Line"
    tDraw.nDuration = nDuration or 0
    tDraw.nWidth = tConfig.thickness or self.config.line.thickness
    tDraw.sColor = tConfig.color or self.config.line.color
    tDraw.nMaxLengthVisible = tConfig.max or nil
    tDraw.nMinLengthVisible = tConfig.min or nil
    tDraw.nNumberOfDot = nNumberOfDot or 1
    tDraw.nPixieIdDot = tDraw.nPixieIdDot or {}
    tDraw.tVectorOffsets = tVectorOffsets or nil
    tDraw.fHandler = fHandler or nil
    tDraw.tData = tData or nil

    local nRad = math.rad(nRotation or 0)
    local nCos = math.cos(nRad)
    local nSin = math.sin(nRad)

    tDraw.RotationMatrix = {
        x = NewVector3({ nCos, 0, -nSin }),
        y = NewVector3({ 0, 1, 0 }),
        z = NewVector3({ nSin, 0, nCos }),
    }

    if OriginType == "number" then
        tDraw.tOriginUnit = GetUnitById(Origin)
        tDraw.tVectorFrom = nil
        tDraw.tVectorTo = nil
    elseif OriginType == "table" or Vector3.Is(Origin) then
        local tOriginVector = NewVector3(Origin)
        local tFacingVector = NewVector3(DEFAULT_NORTH_FACING)
        local tVectorA = tFacingVector * (tDraw.nOffset)
        local tVectorB = tFacingVector * (tDraw.nLength + tDraw.nOffset)

        tVectorA = self:Rotation(tVectorA, tDraw.RotationMatrix)
        tVectorB = self:Rotation(tVectorB, tDraw.RotationMatrix)

        tDraw.tOriginUnit = nil
        tDraw.tVectorFrom = tOriginVector + tVectorA
        tDraw.tVectorTo = tOriginVector + tVectorB

        if tDraw.tVectorOffsets then
            if type(tDraw.tVectorOffsets) == "table" then
                tDraw.tVectorOffsets = NewVector3(tDraw.tVectorOffsets)
            end

            local nRad2 = -math.atan2(tFacingVector.x, tFacingVector.z)
            local nCos2 = math.cos(nRad2)
            local nSin2 = math.sin(nRad2)
            local RotationMatrix2 = {
                x = NewVector3({ nCos2, 0, -nSin2 }),
                y = NewVector3({ 0, 1, 0 }),
                z = NewVector3({ nSin2, 0, nCos2 }),
            }

            local tVectorC = self:Rotation(tDraw.tVectorOffsets, RotationMatrix2)

            tDraw.tVectorFrom = tDraw.tVectorFrom + tVectorC
            tDraw.tVectorTo = tDraw.tVectorTo + tVectorC
        end
    elseif OriginType == "userdata" then
        tDraw.tOriginUnit = Origin
        tDraw.tVectorFrom = nil
        tDraw.tVectorTo = nil
    end

    if not self.tDraws then
        self.tDraws = {}
    end

    self.tDraws[Key] = tDraw
end

function LUI_BossMods:UpdateLine(Key,tDraw)
    if tDraw.nDuration ~= nil and tDraw.nDuration > 0 then
        local nTick = GetTickCount()
        local nTotal = tDraw.nDuration
        local nElapsed = (nTick - tDraw.nTick) / 1000

        if nElapsed > nTotal then
            self:RemoveLine(Key)
            return
        end
    end

    local tVectorTo, tVectorFrom

    if tDraw.tOriginUnit then
        if not tDraw.tOriginUnit:IsValid() or tDraw.tOriginUnit:IsDead() then
            self:RemoveLine(Key)
            return
        else
            local tOriginVector = NewVector3(tDraw.tOriginUnit:GetPosition())
            local tFacingVector = NewVector3(tDraw.tOriginUnit:GetFacing())

            if tOriginVector ~= tDraw.tOriginVector or tFacingVector ~= tDraw.tFacingVector then
                local tVectorA = tFacingVector * (tDraw.nOffset)
                local tVectorB = tFacingVector * (tDraw.nLength + tDraw.nOffset)

                tVectorA = self:Rotation(tVectorA, tDraw.RotationMatrix)
                tVectorB = self:Rotation(tVectorB, tDraw.RotationMatrix)

                tDraw.tVectorFrom = tOriginVector + tVectorA
                tDraw.tVectorTo = tOriginVector + tVectorB

                if tDraw.tVectorOffsets then
                    local nRad = -math.atan2(tFacingVector.x, tFacingVector.z)
                    local nCos = math.cos(nRad)
                    local nSin = math.sin(nRad)
                    local RotationMatrix = {
                        x = NewVector3({ nCos, 0, -nSin }),
                        y = NewVector3({ 0, 1, 0 }),
                        z = NewVector3({ nSin, 0, nCos }),
                    }

                    local tVectorC = self:Rotation(tDraw.tVectorOffsets, RotationMatrix)

                    tDraw.tVectorFrom = tDraw.tVectorFrom + tVectorC
                    tDraw.tVectorTo = tDraw.tVectorTo + tVectorC
                end

                tDraw.tOriginVector = tOriginVector
                tDraw.tFacingVector = tFacingVector

                tVectorTo = tDraw.tVectorTo
                tVectorFrom = tDraw.tVectorFrom
            else
                tVectorTo = tDraw.tVectorTo
                tVectorFrom = tDraw.tVectorFrom
            end
        end
    else
        tVectorTo = tDraw.tVectorTo
        tVectorFrom = tDraw.tVectorFrom
    end

    self:UpdateDraw(tDraw,tVectorFrom,tVectorTo)
end

function LUI_BossMods:RemoveLine(Key)
    if not self.tDraws then
        return
    end

    local tDraw = self.tDraws[Key]

    if tDraw then
        if tDraw.nPixieIdFull then
            self.wndOverlay:DestroyPixie(tDraw.nPixieIdFull)
            tDraw.nPixieIdFull = nil
        end

        if next(tDraw.nPixieIdDot) then
            for _, nPixieIdDot in next, tDraw.nPixieIdDot do
                self.wndOverlay:DestroyPixie(nPixieIdDot)
            end
            tDraw.nPixieIdDot = {}
        end

        local tCallback = {
            fHandler = tDraw.fHandler,
            tData = tDraw.tData
        }

        self.tDraws[Key] = nil
        self:Callback(tCallback.fHandler, tCallback.tData)
    end
end

-- #########################################################################################################################################
-- # LINE BETWEEN
-- #########################################################################################################################################

function LUI_BossMods:DrawLineBetween(Key, FromOrigin, OriginTo, tConfig, nDuration, nNumberOfDot, fHandler, tData)
    if not Key or not FromOrigin or not tConfig or not tConfig.enable then
        return
    end

    if not self.wndOverlay then
        self:LoadWindows()
    end

    if not self.tDraws then
        self.tDraws = {}
    end

    if self.tDraws[Key] then
        self:RemoveLine(Key)
    end

    -- Register a new object to manage.
    local tDraw = self.tDraws[Key] or self:NewDraw()
    tDraw.sType = "LineBetween"
    tDraw.nDuration = nDuration or 0
    tDraw.nTick = GetTickCount()
    tDraw.nWidth = tConfig.thickness or self.config.line.thickness
    tDraw.sColor = tConfig.color or self.config.line.color
    tDraw.nMaxLengthVisible = tConfig.max or nil
    tDraw.nMinLengthVisible = tConfig.min or nil
    tDraw.nNumberOfDot = nNumberOfDot or 1
    tDraw.nPixieIdDot = tDraw.nPixieIdDot or {}
    tDraw.fHandler = fHandler or nil
    tDraw.tData = tData or nil

    if type(FromOrigin) == "number" then
        tDraw.tVectorFrom = nil
        tDraw.tUnitFrom = GetUnitById(FromOrigin)
    elseif type(FromOrigin) == "table" or Vector3.Is(FromOrigin) then
        tDraw.tVectorFrom = NewVector3(FromOrigin)
        tDraw.tUnitFrom = nil
    elseif type(FromOrigin) == "userdata" then
        tDraw.tVectorFrom = nil
        tDraw.tUnitFrom = FromOrigin
    end

    local ToOrigin = OriginTo

    if not ToOrigin then
        ToOrigin = self.unitPlayer or GetPlayerUnit()
    end

    if type(ToOrigin) == "number" then
        tDraw.tVectorTo = nil
        tDraw.tUnitTo = GetUnitById(ToOrigin)
    elseif type(ToOrigin) == "table" or Vector3.Is(ToOrigin) then
        tDraw.tVectorTo = NewVector3(ToOrigin)
        tDraw.tUnitTo = nil
    elseif type(ToOrigin) == "userdata" then
        tDraw.tVectorTo = nil
        tDraw.tUnitTo = ToOrigin
    end

    self.tDraws[Key] = tDraw
end

function LUI_BossMods:UpdateLineBetween(Key,tDraw)
    if tDraw.nDuration ~= nil and tDraw.nDuration > 0 then
        local nTick = GetTickCount()
        local nTotal = tDraw.nDuration
        local nElapsed = (nTick - tDraw.nTick) / 1000

        if nElapsed > nTotal then
            self:RemoveLineBetween(Key)
            return
        end
    end

    local tVectorFrom, tVectorTo

    if tDraw.tUnitFrom then
        if not tDraw.tUnitFrom:IsValid() or (tDraw.tUnitFrom:IsDead() and Key ~= "FOCUS_LINE") then
            self:RemoveLineBetween(Key)
            return
        else
            tVectorFrom = NewVector3(tDraw.tUnitFrom:GetPosition())
        end
    else
        tVectorFrom = tDraw.tVectorFrom
    end

    if tDraw.tUnitTo then
        if not tDraw.tUnitTo:IsValid() or tDraw.tUnitTo:IsDead() then
            self:RemoveLineBetween(Key)
            return
        else
            tVectorTo = NewVector3(tDraw.tUnitTo:GetPosition())
        end
    else
        tVectorTo = tDraw.tVectorTo
    end

    self:UpdateDraw(tDraw,tVectorFrom,tVectorTo)
end

function LUI_BossMods:RemoveLineBetween(Key)
    if not self.tDraws then
        return
    end

    local tDraw = self.tDraws[Key]

    if tDraw then
        if tDraw.nPixieIdFull then
            self.wndOverlay:DestroyPixie(tDraw.nPixieIdFull)
            tDraw.nPixieIdFull = nil
        end

        if next(tDraw.nPixieIdDot) then
            for _, nPixieIdDot in next, tDraw.nPixieIdDot do
                self.wndOverlay:DestroyPixie(nPixieIdDot)
            end
            tDraw.nPixieIdDot = {}
        end

        local tCallback = {
            fHandler = tDraw.fHandler,
            tData = tDraw.tData
        }

        self.tDraws[Key] = nil
        self:Callback(tCallback.fHandler, tCallback.tData)
    end
end

-- #########################################################################################################################################
-- # HELPER
-- #########################################################################################################################################

function LUI_BossMods:UpdateDraw(tDraw, tVectorFrom, tVectorTo)
    local tScreenLocTo, tScreenLocFrom = nil, nil

    if tVectorFrom and tVectorTo then
        local bShouldBeVisible = true

        if tDraw.nMaxLengthVisible or tDraw.nMinLengthVisible then
            local len = (tVectorTo - tVectorFrom):Length()
            if tDraw.nMaxLengthVisible and tDraw.nMaxLengthVisible < len then
                bShouldBeVisible = false
            elseif tDraw.nMinLengthVisible and tDraw.nMinLengthVisible > len then
                bShouldBeVisible = false
            end
        end

        if bShouldBeVisible then
            tScreenLocTo = WorldLocToScreenPoint(tVectorTo)
            tScreenLocFrom = WorldLocToScreenPoint(tVectorFrom)
        end
    end

    if tScreenLocFrom and tScreenLocTo and (tScreenLocFrom.z > 0 or tScreenLocTo.z > 0) then
        if tDraw.nNumberOfDot == 1 then
            local tPixieAttributs = {
                bLine = true,
                fWidth = tDraw.nWidth,
                cr = tDraw.sColor,
                loc = {
                    fPoints = FPOINT_NULL,
                    nOffsets = {
                        tScreenLocFrom.x,
                        tScreenLocFrom.y,
                        tScreenLocTo.x,
                        tScreenLocTo.y,
                    },
                },
            }

            if tDraw.nPixieIdFull then
                self.wndOverlay:UpdatePixie(tDraw.nPixieIdFull, tPixieAttributs)
            else
                tDraw.nPixieIdFull = self.wndOverlay:AddPixie(tPixieAttributs)
            end
        else
            local tVectorPlayer = NewVector3(self.unitPlayer:GetPosition())
            for i = 1, tDraw.nNumberOfDot do
                local nRatio = (i - 1) / (tDraw.nNumberOfDot - 1)
                local tVectorDot = Vector3.InterpolateLinear(tVectorFrom, tVectorTo, nRatio)
                local tScreenLocDot = WorldLocToScreenPoint(tVectorDot)

                if tScreenLocDot.z > 0 then
                    local nDistance2Player = (tVectorPlayer - tVectorDot):Length()
                    local nScale = math.min(40 / nDistance2Player, 1)
                    local tVector = tScreenLocTo - tScreenLocFrom

                    nScale = math.max(nScale, 0.5) * tDraw.nSpriteSize

                    local tPixieAttributs = {
                        bLine = false,
                        strSprite = tDraw.sSprite,
                        cr = tDraw.sColor,
                        fRotation = math.deg(math.atan2(tVector.y, tVector.x)) + 90,
                        loc = {
                            fPoints = FPOINT_NULL,
                            nOffsets = {
                                tScreenLocDot.x - nScale,
                                tScreenLocDot.y - nScale ,
                                tScreenLocDot.x + nScale,
                                tScreenLocDot.y + nScale,
                            },
                        },
                    }

                    if tDraw.nPixieIdDot[i] then
                        self.wndOverlay:UpdatePixie(tDraw.nPixieIdDot[i], tPixieAttributs)
                    else
                        tDraw.nPixieIdDot[i] = self.wndOverlay:AddPixie(tPixieAttributs)
                    end
                else
                    self.wndOverlay:DestroyPixie(tDraw.nPixieIdDot[i])
                    tDraw.nPixieIdDot[i] = nil
                end
            end
        end
    else
        if tDraw.nPixieIdFull then
            self.wndOverlay:DestroyPixie(tDraw.nPixieIdFull)
            tDraw.nPixieIdFull = nil
        end

        if tDraw.nPixieIdDot and next(tDraw.nPixieIdDot) then
            for _, nPixieIdDot in next, tDraw.nPixieIdDot do
                self.wndOverlay:DestroyPixie(nPixieIdDot)
            end
            tDraw.nPixieIdDot = {}
        end
    end
end

function LUI_BossMods:GetDraw(Key)
    if not self.tDraws then
        return
    end

    return self.tDraws[Key]
end

function LUI_BossMods:NewDraw()
    local new = {
        nSpriteSize = 4,
        sSprite = "BasicSprites:WhiteCircle",
        sColor = { a = 1.0, r = 1.0, g = 0.0, b = 0.0 },
    }
    return setmetatable(new, TEMPLATE_DRAW_META)
end

function TemplateDraw:SetColor(sColor)
    local mt = getmetatable(self)
    mt.__index.sColor = sColor or { a = 1.0, r = 1.0, g = 0.0, b = 0.0 }
end

function TemplateDraw:SetSprite(sSprite, nSize)
    local mt = getmetatable(self)
    mt.__index.sSprite = sSprite or mt.__index.sSprite or "BasicSprites:WhiteCircle"
    mt.__index.nSpriteSize = nSize or mt.__index.nSpriteSize or 4
end

function TemplateDraw:SetMaxLengthVisible(nMax)
    local mt = getmetatable(self)
    mt.__index.nMaxLengthVisible = nMax
end

function TemplateDraw:SetMinLengthVisible(nMin)
    local mt = getmetatable(self)
    mt.__index.nMinLengthVisible = nMin
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # OTHER STUFF
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:Callback(fHandler, tData)
    if fHandler and type(fHandler) == "function" then
        if not self.bIsLocked then
            fHandler(self.settings, tData)
        elseif self.tCurrentEncounter then
            fHandler(self.tCurrentEncounter, tData)
        else
            if tData == "break" then
                fHandler(self, tData)
            end
        end
    end
end

function LUI_BossMods:GetDistance(FromOrigin, OriginTo)
    if not FromOrigin then
        return 999
    end

    local ToOrigin = OriginTo
    local positionA,positionB
    local length = 999

    if type(FromOrigin) == "number" then
        FromOrigin = GetUnitById(FromOrigin)

        if FromOrigin then
            positionA = FromOrigin:GetPosition()
        else
            return 999
        end
    elseif type(FromOrigin) == "table" then
        positionA = FromOrigin
    elseif type(FromOrigin) == "userdata" then
        positionA = FromOrigin:GetPosition()
    else
        return 999
    end

    if not ToOrigin then
        ToOrigin = self.unitPlayer or GetPlayerUnit()
    end

    if type(ToOrigin) == "number" then
        ToOrigin = GetUnitById(ToOrigin)

        if ToOrigin then
            positionB = ToOrigin:GetPosition()
        else
            return 999
        end
    elseif type(ToOrigin) == "table" then
        positionB = ToOrigin
    elseif type(ToOrigin) == "userdata" then
        positionB = ToOrigin:GetPosition()
    end

    if positionA and positionB then
        local vectorA = NewVector3(positionA)
        local vectorB = NewVector3(positionB)
        length = (vectorB - vectorA):Length()
    end

    return length
end

function LUI_BossMods:LoadWindows()
    if not self.wndOverlay then
        self.wndOverlay = Apollo.LoadForm(self.xmlDoc, "Overlay", "InWorldHudStratum", self)
    end

    if not self.wndTimers then
        self.wndTimers = Apollo.LoadForm(self.xmlDoc, "Container", nil, self)
        self.wndTimers:SetSizingMinimum(200,300)
        self.wndTimers:SetSizingMaximum(400,300)
        self.wndTimers:SetData("timer")
        self.wndTimers:Show(false,true)

        self.wndTimers:SetAnchorOffsets(
            self.config.timer.offsets.left,
            self.config.timer.offsets.top,
            self.config.timer.offsets.right,
            self.config.timer.offsets.bottom
        )
    end

    if not self.wndUnits and self.config.units.enable then
        self.wndUnits = Apollo.LoadForm(self.xmlDoc, "Container", nil, self)
        self.wndUnits:SetSizingMinimum(200,300)
        self.wndUnits:SetSizingMaximum(400,300)
        self.wndUnits:SetData("units")
        self.wndUnits:Show(false,true)

        self.wndUnits:SetAnchorOffsets(
            self.config.units.offsets.left,
            self.config.units.offsets.top,
            self.config.units.offsets.right,
            self.config.units.offsets.bottom
        )
    end

    if not self.wndCastbar then
        self.wndCastbar = Apollo.LoadForm(self.xmlDoc, "Castbar", nil, self)
        self.wndCastbar:SetSizingMinimum(200,30)
        self.wndCastbar:SetSizingMaximum(1000,200)
        self.wndCastbar:SetData("castbar")
        self.wndCastbar:Show(false,true)

        self.wndCastbar:SetAnchorOffsets(
            self.config.castbar.offsets.left,
            self.config.castbar.offsets.top,
            self.config.castbar.offsets.right,
            self.config.castbar.offsets.bottom
        )
    end

    if not self.wndAura then
        self.wndAura = Apollo.LoadForm(self.xmlDoc, "Aura", nil, self)
        self.wndAura:SetSizingMinimum(125,125)
        self.wndAura:SetSizingMaximum(300,300)
        self.wndAura:SetData("aura")
        self.wndAura:Show(false,true)

        self.wndAura:SetAnchorOffsets(
            self.config.aura.offsets.left,
            self.config.aura.offsets.top,
            self.config.aura.offsets.right,
            self.config.aura.offsets.bottom
        )
    end

    if not self.wndAlerts then
        self.wndAlerts = Apollo.LoadForm(self.xmlDoc, "Container", nil, self)
        self.wndAlerts:SetData("alerts")
        self.wndAlerts:Show(false,true)

        self.wndAlerts:SetAnchorOffsets(
            self.config.alerts.offsets.left,
            self.config.alerts.offsets.top,
            self.config.alerts.offsets.right,
            self.config.alerts.offsets.bottom
        )
    end
end

function LUI_BossMods:OnWindowChanged(wndHandler, wndControl)
    if wndHandler ~= wndControl then
        return
    end

    local strData = wndControl:GetData()
    local nLeft, nTop, nRight, nBottom = wndControl:GetAnchorOffsets()

    if strData and self.config[strData] then
        self.config[strData].offsets = {
            left = nLeft,
            top = nTop,
            right = nRight,
            bottom = nBottom,
        }
    end
end

function LUI_BossMods:OnConfigure()
    self.settings:OnToggleMenu()
end

function LUI_BossMods:Connect()
    if not self.comm then
        self.comm = ICCommLib.JoinChannel("LUIBossMods", ICCommLib.CodeEnumICCommChannelType.Group)
    end

    if self.comm:IsReady() then
        self.comm:SetReceivedMessageFunction("OnICCommMessageReceived", self)
        self.comm:SetSendMessageResultFunction("OnICCommSendMessageResult", self)

        if self.nBreakDuration then
            self:OnBreakSet(self.nBreakDuration)
        end

        if self.CheckConnectionTimer then
            self.CheckConnectionTimer:Stop()
            self.CheckConnectionTimer = nil
        end
    else
        if not self.CheckConnectionTimer then
            self.CheckConnectionTimer = ApolloTimer.Create(1, false, "Connect", self)
        end

        self.CheckConnectionTimer:Start()
    end
end

function LUI_BossMods:OnSlashCommand(cmd, args)
    local tArgc = {}

    for sWord in string.gmatch(args, "[^%s]+") do
        table.insert(tArgc, sWord)
    end

    local strName, nDuration

    if #tArgc >= 1 then
        strName = tArgc[1] == "break" and tArgc[1] or nil
        nDuration = tonumber(tArgc[2]) ~= nil and tonumber(tArgc[2]) or nil
    end

    if strName and nDuration then
        self:OnBreakSet(nDuration)
    else
        self.settings:OnToggleMenu()
    end
end

function LUI_BossMods:OnICCommSendMessageResult(iccomm, eResult, idMessage)
    self.busy = false
end

function LUI_BossMods:OnICCommMessageReceived(channel, strMessage, idMessage)
    local tMessage = JSON.decode(strMessage)

    if type(tMessage) ~= "table" then
        return
    end

    if not tMessage.action then
        return
    end

    if tMessage.action == "break" then
        self:OnBreakStart(tMessage)
    end
end

function LUI_BossMods:OnBreakSet(nDuration)
    if not nDuration or not self:CheckPermission() then
        return
    end

    local tMessage = {
        action = "break",
        duration = nDuration
    }

    local strMsg = JSON.encode(tMessage)

    if self.comm and self.comm:IsReady() and not self.busy then
        self.busy = true
        self.nBreakDuration = nil

        self:OnBreakStart(tMessage)
        self.comm:SendMessage(tostring(strMsg))
    else
        if not self.CheckConnectionTimer then
            self.CheckConnectionTimer = ApolloTimer.Create(1, false, "Connect", self)
        end

        self.nBreakDuration = nDuration
        self.CheckConnectionTimer:Start()
    end
end

function LUI_BossMods:OnBreakStart(tMessage)
    if not tMessage or not tMessage.duration then
        return
    end

    self:AddTimer("break", "Break", tonumber(tMessage.duration), {enable=true}, LUI_BossMods.OnBreakFinished, "break")

    if not self.breakTimer then
        self.breakTimer = ApolloTimer.Create(0.1, true, "OnBreakTimer", self)
        self.breakTimer:Start()
    end
end

function LUI_BossMods:OnBreakTimer()
    if self.runtime.timer and self.runtime.timer["break"] then
        self:UpdateTimer(self.runtime.timer["break"])
        self:SortTimer()
    else
        if self.breakTimer then
            self.breakTimer:Stop()
            self.breakTimer = nil
        end
    end
end

function LUI_BossMods:OnBreakFinished()
    if self:CheckPermission() then
        GroupLib.ReadyCheck()
    end
end

function LUI_BossMods:OnBreakEnd()
    if self.runtime.timer and self.runtime.timer["break"] then
        self.runtime.timer["break"].wnd:Destroy()
        self.runtime.timer["break"] = nil
    end
end

function LUI_BossMods:CheckPermission()
    local sName = GetPlayerUnit():GetName()
    local inRaid = GroupLib.InRaid(sName)
    local isLeader = GroupLib.AmILeader()
    local isAssist = false
    local nMemberCount = GroupLib.GetMemberCount()

    for nMemberIdx = 1, nMemberCount do
        local tMember = GroupLib.GetGroupMember(nMemberIdx)

        if tMember.strCharacterName == sName then
            if tMember.bRaidAssistant then
                isAssist = true
            end
        end
    end

    if inRaid and (isLeader or isAssist) then
        return true
    else
        return false
    end
end

function LUI_BossMods:OnInterfaceMenuListHasLoaded()
    Event_FireGenericEvent("InterfaceMenuList_NewAddOn","LUI BossMods", {"LUIBossMods_ToggleMenu", "", "LUI_BossMods:LUIBM_logo" })
end

function LUI_BossMods:OnSave(eType)
    if eType ~= GameLib.CodeEnumAddonSaveLevel.General then
        return
    end

    if self.config.modules then
        for sName,tModule in pairs(self.modules) do
            self.config.modules[sName] = tModule.config
        end
    end

    return self.config
end

function LUI_BossMods:OnRestore(eLevel, tSavedData)
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then
        return
    end

    if tSavedData and tSavedData ~= "" then
        self.config = self:InsertDefaults(self:CheckSavedData(tSavedData,self.config),self.config)

        for sName,tModule in pairs(self.modules) do
            if tSavedData.modules and tSavedData.modules[sName] then
                tModule.config = self:InsertDefaults(self:CheckSavedData(tSavedData.modules[sName],tModule.config), tModule.config)
            end
        end
    end
end

function LUI_BossMods:OnRestoreDefaults()
    self.config = {}
    RequestReloadUI()
end

function LUI_BossMods:RegisterLocale(strBoss, sLanguage, tLocales)
    local sName = "LUI_BossMods_" .. strBoss
    local L = GeminiLocale:NewLocale(sName, sLanguage, sLanguage == "enUS", true)

    if L then
        for key, val in next, tLocales do
            L[key] = val
        end
    end
end

function LUI_BossMods:GetLocale(strBoss,tLocales)
    self:RegisterLocale(strBoss, "enUS", tLocales["enUS"])

    if tLocales["deDE"] and #tLocales["deDE"] then
        self:RegisterLocale(strBoss, "deDE", tLocales["deDE"])
    end

    if tLocales["frFR"] and #tLocales["frFR"] then
        self:RegisterLocale(strBoss, "frFR", tLocales["frFR"])
    end

    return GeminiLocale:GetLocale("LUI_BossMods_" .. strBoss)
end

function LUI_BossMods:CheckSavedData(tSavedData,tConfig)
    for k,v in pairs(tSavedData) do
        if k ~= "modules" and k ~= "telegraph" and type(v) == "table" then
            if tConfig[k] == nil then
                tSavedData[k] = nil
            else
                tSavedData[k] = self:CheckSavedData(tSavedData[k],tConfig[k])
            end
        end
    end

    return tSavedData
end

function LUI_BossMods:InsertDefaults(t,defaults)
    for k,v in pairs(defaults) do
        if t[k] == nil then
            if type(v) == 'table' then
                t[k] = self:Copy(v)
            else
                t[k] = v
            end
        else
            if type(v) == 'table' then
                t[k] = self:InsertDefaults(t[k],v)
            end
        end
    end

    return t
end

function LUI_BossMods:HelperFormatBigNumber(nArg)
    local strResult
    if nArg < 1000 then
        strResult = tostring(nArg)
    elseif nArg < 1000000 then
        if math.floor(nArg%1000/100) == 0 then
            strResult = String_GetWeaselString("$1ck", math.floor(nArg / 1000))
        else
            strResult = String_GetWeaselString("$1f1k", nArg / 1000)
        end
    elseif nArg < 1000000000 then
        if math.floor(nArg%1000000/100000) == 0 then
            strResult = String_GetWeaselString("$1cm", math.floor(nArg / 1000000))
        else
            strResult = String_GetWeaselString("$1f1m", nArg / 1000000)
        end
    elseif nArg < 1000000000000 then
        if math.floor(nArg%1000000/100000) == 0 then
            strResult = String_GetWeaselString("$1cb", math.floor(nArg / 1000000))
        else
            strResult = String_GetWeaselString("$1f1b", nArg / 1000000)
        end
    else
        strResult = tostring(nArg)
    end
    return strResult
end

function LUI_BossMods:Rotation(tVector, tMatrixTeta)
    local r = {}
    for axis1, R in next, tMatrixTeta do
        r[axis1] = tVector.x * R.x + tVector.y * R.y + tVector.z * R.z
    end
    return NewVector3(r)
end

function LUI_BossMods:Copy(t)
    local o = {}

    for k,v in pairs(t) do
        if type(v) == 'table' then
            o[k] = self:Copy(v)
        else
            o[k] = v
        end
    end

    return o
end

function LUI_BossMods:Sort(t, order)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end

    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function LUI_BossMods:Round(val, decimal)
    local exp = decimal and 10^decimal or 1
    return math.ceil(val * exp - 0.5) / exp
end

local LUI_BossModsInst = LUI_BossMods:new()
LUI_BossModsInst:Init()
