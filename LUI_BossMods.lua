require "Window"
require "Apollo"
require "Unit"
require "Sound"
require "Vector3"

local LUI_BossMods = {}
local TemplateDraw = {}
local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage

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
local HEIGHT_PER_RACEID = {
    [GameLib.CodeEnumRace.Human] = 1.2,
    [GameLib.CodeEnumRace.Granok] = 1.6,
    [GameLib.CodeEnumRace.Aurin] = 1.1,
    [GameLib.CodeEnumRace.Draken] = 1.4,
    [GameLib.CodeEnumRace.Mechari] = 1.75,
    [GameLib.CodeEnumRace.Chua] = 1.0,
    [GameLib.CodeEnumRace.Mordesh] = 1.85,
}

function LUI_BossMods:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.bDebug = false
    self.bIsRunning = false
    self.language = "enUS"
    self.runtime = {}
    self.modules = {}
    self.config = {
        modules = {},
        interval = 100,
        aura = {
            sprite = "attention",
            color = "ff7fff00",
            offsets = {
                left = -120,
                top = -230,
                right = 120,
                bottom = 10
            },
        },
        icon = {
            sprite = "attention",
            color = "ff7fff00",
            size = 60,
        },
        line = {
            color = "ffff0000",
            thickness = 10,
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
        castbar = {
            mooColor = "ff9400d3",
            barColor = "ffb22222",
            textColor = "ffebebeb",
            offsets = {
                left = -300,
                top = -360,
                right = 300,
                bottom = -300
            },
        },
        timer = {
            barHeight = 32,
            barColor = "9600ffff",
            textColor = "ffebebeb",
            offsets = {
                left = -660,
                top = -230,
                right = -360,
                bottom = 40
            },
        },
        units = {
            enable = true,
            healthHeight = 32,
            shieldHeight = 10,
            shieldWidth = 40,
            healthColor = "96adff2f",
            shieldColor = "9600ffff",
            absorbColor = "96ffd700",
            textColor = "ffebebeb",
            offsets = {
                left = 310,
                top = -230,
                right = 580,
                bottom = 40
            },
        },
        alerts = {
            color = "ffff00ff",
            font = "CRB_FloaterLarge",
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
    Apollo.RegisterAddon(self, true, "LUI BossMods",nil)
end

function LUI_BossMods:OnDependencyError(strDependency, strError)
    return true
end

function LUI_BossMods:OnLoad()
    Apollo.RegisterEventHandler("UnitCreated", "OnPreloadUnitCreated", self)

    self.xmlDoc = XmlDoc.CreateFromFile("LUI_BossMods.xml")
    self.xmlDoc:RegisterCallback("OnDocLoaded", self)

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
    if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then
        return
    end

    Apollo.LoadSprites("Sprites.xml")
    Apollo.RegisterSlashCommand("bossmod", "OnSlashCommand", self)
    Apollo.RegisterSlashCommand("bossmods", "OnSlashCommand", self)

    self:GetLanguage()

    self:LoadWindows()
    self:LoadModules()
    self:LoadSettings()

    -- Check Volume Settings
    self:CheckVolume()

    if self.tPreloadUnits ~= nil then
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

    if not self.unitPlayer then
        self.unitPlayer = GetPlayerUnit()
    end

    if self.unitPlayer then
        self:OnChangeZone()
        self:OnEnteredCombat(self.unitPlayer,self.unitPlayer:IsInCombat())
    end
end

function LUI_BossMods:Print(message)
    if self.system then
        ChatSystemLib.PostOnChannel(self.system,message,"")
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
    self.settings:Init(self)
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
    if not tModule or not self.zone then
        return false
    end

    if not tModule.tTrigger or not tModule.tTrigger.tZones then
        return false
    end

    for _,tZone in ipairs(tModule.tTrigger.tZones) do
        if tZone.continentId == self.zone.continentId and tZone.parentZoneId == self.zone.parentZoneId and tZone.mapId == self.zone.mapId then
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

    for sName,tModule in pairs(self.modules) do
        if self:CheckZone(tModule) then
            if self.bIsRunning == false then
                if self:CheckTrigger(tModule) then
                    self.tCurrentEncounter = tModule

                    if self.tCurrentEncounter and self.tCurrentEncounter:IsEnabled() and not self.tCurrentEncounter:IsRunning() then
                        self:StartFight()
                    end

                    return
                end
            else
                return
            end
        end
    end

    if self.bIsRunning == true then
        self:ResetFight()
    end

    if self.tCurrentEncounter then
        self.tCurrentEncounter:OnDisable()
        self.tCurrentEncounter = nil
    end
end

function LUI_BossMods:CheckTrigger(tModule)
    if not tModule then
        return false
    end

    if not tModule.tTrigger or not self.tSavedUnits then
        return true
    end

    if not tModule.tTrigger.tNames or not tModule.tTrigger.tNames[self.language] then
        return true
    end

    if tModule.tTrigger.sType == "ANY" then
        for _,sName in ipairs(tModule.tTrigger.tNames[self.language]) do
            if self.tSavedUnits[sName] then
                for nId, unit in pairs(self.tSavedUnits[sName]) do
                    if unit:IsInCombat() == true then
                        return true
                    end
                end
            end
        end
        return false
    elseif tModule.tTrigger.sType == "ALL" then
        for _,sName in ipairs(tModule.tTrigger.tNames[self.language]) do
            if not self.tSavedUnits[sName] then
                return false
            else
                for nId, unit in pairs(self.tSavedUnits[sName]) do
                    if unit:IsInCombat() == false then
                        return false
                    end
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
    if self.tDraws then
        for key,draw in pairs(self.tDraws) do
            if draw.sType then
                if draw.sType == "Icon" then
                    self:UpdateIcon(key,draw)
                elseif draw.sType == "Pixie" then
                    self:UpdatePixie(key,draw)
                elseif draw.sType == "Polygon" then
                    self:UpdatePolygon(key,draw)
                elseif draw.sType == "Line" then
                    self:UpdateLine(key,draw)
                elseif draw.sType == "LineBetween" then
                    self:UpdateLineBetween(key,draw)
                end
            end
        end
    end
end

function LUI_BossMods:OnUpdate()
    if not self.bIsRunning == true or not self.tCurrentEncounter then
        return
    end

    self.tick = GetTickCount()

    if not self.lastCheck then
        self.lastCheck = self.tick
    end

    if (self.tick - self.lastCheck) > self.config.interval then
        if self.runtime.units then
            for _,tUnit in pairs(self.runtime.units) do
                if not tUnit.runtime then
                    tUnit.runtime = {}
                end

                -- Update Unit Frame
                self:UpdateUnit(tUnit)

                -- Check Casts
                if tUnit.bOnCast then
                    self:CheckCast(tUnit)
                end
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

        self.lastCheck = self.tick
    end
end

function LUI_BossMods:StartFight()
    if not self.tCurrentEncounter then
        return
    end

    self.bIsRunning = true
    self.tCurrentEncounter:OnEnable()
    self:ProcessSavedUnits()

    Apollo.RemoveEventHandler("VarChange_FrameCount",self)
    Apollo.RegisterEventHandler("VarChange_FrameCount", "OnUpdate", self)

    Apollo.RemoveEventHandler("ChatMessage",self)
    Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self)

    Apollo.RemoveEventHandler("NextFrame",self)
    Apollo.RegisterEventHandler("NextFrame", "OnFrame", self)

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

    Apollo.RemoveEventHandler("NextFrame",self)
    Apollo.RemoveEventHandler("VarChange_FrameCount",self)
    Apollo.RemoveEventHandler("ChatMessage",self)
    Apollo.RemoveEventHandler("BuffAdded",self)
    Apollo.RemoveEventHandler("BuffUpdated",self)
    Apollo.RemoveEventHandler("BuffRemoved",self)

    if self.tCurrentEncounter then
        self.tCurrentEncounter:OnDisable()
        self.tCurrentEncounter = nil
    end

    self.runtime = {}
    self.wndOverlay:DestroyAllPixies()

    if self.tDraws then
        for key,draw in pairs(self.tDraws) do
            if draw.sType then
                if draw.sType == "Icon" then
                    self:RemoveIcon(key,draw)
                elseif draw.sType == "Pixie" then
                    self:RemovePixie(key,draw)
                elseif draw.sType == "Polygon" then
                    self:RemovePolygon(key,draw)
                elseif draw.sType == "Line" then
                    self:RemoveLine(key,draw)
                elseif draw.sType == "LineBetween" then
                    self:RemoveLineBetween(key,draw)
                end
            end
        end
    end

    self.tDraws = nil

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
end

function LUI_BossMods:CheckForWipe()
    if self.bIsRunning == false then
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

        if self.bDebug == true then
            Apollo.RegisterEventHandler("NextFrame", "OnFrame", self)
            Apollo.RegisterEventHandler("VarChange_FrameCount", "OnUpdate", self)
        end
    end
end

function LUI_BossMods:OnUnitCreated(unit)
    if self.bIsRunning == true  then
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
    if self.bIsRunning == true then
        if self.tCurrentEncounter and self.tCurrentEncounter.OnUnitDestroyed then
            self.tCurrentEncounter:OnUnitDestroyed(unit:GetId(),unit,unit:GetName())
        end
    else
        if self.tSavedUnits ~= nil and self.tSavedUnits[unit:GetName()] ~= nil and self.tSavedUnits[unit:GetName()][unit:GetId()] ~= nil then
            self.tSavedUnits[unit:GetName()][unit:GetId()] = nil
        end
    end
end

function LUI_BossMods:OnEnteredCombat(unit, bInCombat)
    if unit:IsThePlayer() then
        if bInCombat == true then
            if self.bIsRunning == false then
                self:SearchForEncounter()
            end

            if self.tCurrentEncounter and self.tCurrentEncounter.OnUnitCreated then
                self.tCurrentEncounter:OnUnitCreated(unit:GetId(),unit,unit:GetName(),bInCombat)
            end
        else
            if self.bIsRunning == true then
                self.wipeTimer:Start()
            end
        end
    else
        if not unit:IsInYourGroup() then
            if self.bIsRunning == true then
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

                if bInCombat == true then
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

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # TRACKED UNITS
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:AddUnit(nId,sName,tUnit,bShowUnit,bOnCast,bOnBuff,bOnDebuff,sMark,sColor,nPriority)
    if not nId or not sName or not tUnit then
        return
    end

    if not self.runtime.units then
        self.runtime.units = {}
    end

    if not self.runtime.units[nId] then
        self.runtime.units[nId] = {
            nId = nId,
            sName = sName,
            tUnit = tUnit,
            sMark = sMark or nil,
            sColor = sColor or nil,
            nPriority = nPriority or 0,
            bShowUnit = bShowUnit or false,
            bOnCast = bOnCast or false,
            bOnBuff = bOnBuff or false,
            bOnDebuff = bOnDebuff or false
        }

        if (bOnBuff ~= nil and bOnBuff == true) then
            self:CheckBuffs(nId)
        end

        if (bShowUnit ~= nil and bShowUnit == true) and self.config.units.enable == true then
            if tUnit:IsValid() then
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
    wnd:FindChild("ShieldBar"):SetAnchorPoints((0.95-(self.config.units.shieldWidth/100)),1,0.95,1)
    wnd:FindChild("ShieldBar"):SetAnchorOffsets(0,(((self.config.units.shieldHeight/2)+15)*-1),0,(((self.config.units.shieldHeight/2)+5)*-1))

    wnd:FindChild("Name"):SetText(tData.sName)
    wnd:FindChild("Name"):SetTextColor(self.config.units.textColor)
    wnd:FindChild("Mark"):SetText(tData.sMark)
    wnd:FindChild("Mark"):Show(tData.sMark ~= nil,true)
    wnd:FindChild("HealthText"):SetTextColor(self.config.units.textColor)
    wnd:FindChild("HealthBar"):SetBGColor(tData.sColor or self.config.units.healthColor)

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
            nPriority = unit.nPriority or 0
        }
    end

    table.sort(tSorted, function(a, b)
        return a.nPriority < b.nPriority
    end)

    for i=1,#tSorted do
        local tUnit = self.runtime.units[tSorted[i].nId]
        local tOffsets = {0,(height * (i-1)),0,(height * i)}

        if tUnit.nPosition then
            if tUnit.nPosition ~= i then
                tUnit.wnd:TransitionMove(WindowLocation.new({fPoints = {0,0,1,0}, nOffsets = tOffsets}), .25)
            end
        else
            tUnit.wnd:SetAnchorOffsets(unpack(tOffsets))
        end

        tUnit.nPosition = i
    end
end

function LUI_BossMods:UpdateUnit(tData)
    if not tData or not type(tData) == "table" then
        return
    end

    -- Health
    local nHealth = tData.tUnit:GetHealth() or 0
    local nHealthMax = tData.tUnit:GetMaxHealth() or 0
    local nHealthPercent = (nHealth * 100) / nHealthMax
    local nHealthProgress = nHealthPercent / 100

    if nHealthProgress ~= (tData.runtime.health or 0) then
        if tData.wnd then
            tData.wnd:FindChild("HealthText"):SetText(nHealthPercent > 0 and string.format("%.1f%%", nHealthPercent) or "DEAD")
            tData.wnd:FindChild("HealthBar"):TransitionMove(WindowLocation.new({fPoints = {0, 0, nHealthProgress, 1}}), .075)
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

    if nAbsorb > 0 then
        if not tData.wnd:FindChild("ShieldBar"):IsShown() then
            tData.wnd:FindChild("ShieldBar"):Show(true,true)
        end

        if not tData.runtime.bShowAbsorb then
            tData.runtime.bShowAbsorb = true
            tData.wnd:FindChild("ShieldBar"):FindChild("Progress"):SetBGColor(self.config.units.absorbColor)
        end

        if nAbsorbProgress ~= (tData.runtime.shield or 0) then
            tData.wnd:FindChild("ShieldBar"):FindChild("Progress"):TransitionMove(WindowLocation.new({fPoints = {0, 0, nAbsorbProgress, 1}}), .075)
            tData.runtime.shield = nAbsorbProgress
        end
    else
        if tData.runtime.bShowAbsorb ~= nil then
            tData.runtime.bShowAbsorb = nil
            tData.wnd:FindChild("ShieldBar"):FindChild("Progress"):SetBGColor(self.config.units.shieldColor)
        end

        -- Shield
        local nShield = tData.tUnit:GetShieldCapacity() or 0
        local nShieldMax = tData.tUnit:GetShieldCapacityMax() or 0
        local nShieldPercent = (nShield * 100) / nShieldMax
        local nShieldProgress = nShieldPercent / 100

        if nShield > 0 then
            if not tData.wnd:FindChild("ShieldBar"):IsShown() then
                tData.wnd:FindChild("ShieldBar"):Show(true,true)
            end

            if nShieldProgress ~= (tData.runtime.shield or 0) then
                tData.wnd:FindChild("ShieldBar"):FindChild("Progress"):TransitionMove(WindowLocation.new({fPoints = {0, 0, nShieldProgress, 1}}), .075)
                tData.runtime.shield = nShieldProgress
            end
        else
            if tData.wnd:FindChild("ShieldBar"):IsShown() then
                tData.wnd:FindChild("ShieldBar"):Show(false,true)
            end
        end
    end
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # BUFFS & DEBUFFS
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:CheckBuffs(nId)
    if not nId then
        return
    end

    if not self.tCurrentEncounter then
        return
    end

    if not self.runtime.units then
        return
    end

    if self.runtime.units[nId] ~= nil and self.runtime.units[nId].bOnBuff then
        local tBuffs = self.runtime.units[nId].tUnit:GetBuffs()

        -- Process Buffs
        if tBuffs ~= nil and tBuffs.arBeneficial ~= nil then
            for i=1, #tBuffs.arBeneficial do
                self:OnBuffAdded(self.runtime.units[nId].tUnit,tBuffs.arBeneficial[i])
            end
        end

        -- Process Debuffs
        if tBuffs ~= nil and tBuffs.arHarmful ~= nil then
            for i=1, #tBuffs.arHarmful do
                self:OnBuffAdded(self.runtime.units[nId].tUnit,tBuffs.arHarmful[i])
            end
        end
    end
end

function LUI_BossMods:OnBuffAdded(unit,spell)
    if not unit or not spell then
        return
    end

    if not self.tCurrentEncounter then
        return
    end

    if not self.runtime.units then
        return
    end

    local nId = unit:GetId()

    if self.runtime.units[nId] ~= nil  then
        local buff = spell.splEffect:IsBeneficial() or false

        if (buff == true and self.runtime.units[nId].bOnBuff) or (buff == false and self.runtime.units[unit:GetId()].bOnDebuff) then
            local tData = {
                nId = spell.splEffect:GetId(),
                sName = spell.splEffect:GetName(),
                nDuration = spell.fTimeRemaining,
                nTick = GetTickCount(),
                nCount = spell.nCount,
                nUnitId = unit:GetId(),
                sUnitName = unit:GetName(),
                tUnit = unit,
                tSpell = spell,
            }

            if self.tCurrentEncounter and self.tCurrentEncounter.OnBuffAdded then
                self.tCurrentEncounter:OnBuffAdded(tData.nUnitId, tData.nId, tData.sName, tData, tData.sUnitName, spell.nCount, spell.fTimeRemaining)
            end
        end
    elseif (unit:IsInYourGroup() or unit:IsThePlayer()) and spell.splEffect:IsBeneficial() == false then
        local tData = {
            nId = spell.splEffect:GetId(),
            sName = spell.splEffect:GetName(),
            nDuration = spell.fTimeRemaining,
            nTick = GetTickCount(),
            nCount = spell.nCount,
            nUnitId = unit:GetId(),
            sUnitName = unit:GetName(),
            tUnit = unit,
            tSpell = spell,
        }

        if self.tCurrentEncounter and self.tCurrentEncounter.OnBuffAdded then
            self.tCurrentEncounter:OnBuffAdded(tData.nUnitId, tData.nId, tData.sName, tData, tData.sUnitName, spell.nCount, spell.fTimeRemaining)
        end
    end
end

function LUI_BossMods:OnBuffUpdated(unit,spell)
    if not unit or not spell then
        return
    end

    if not self.tCurrentEncounter then
        return
    end

    if not self.runtime.units then
        return
    end

    if self.runtime.units[unit:GetId()] ~= nil and self.runtime.units[unit:GetId()].bOnBuff then
        local tData = {
            nId = spell.splEffect:GetId(),
            sName = spell.splEffect:GetName(),
            nDuration = spell.fTimeRemaining,
            nTick = GetTickCount(),
            nCount = spell.nCount,
            nUnitId = unit:GetId(),
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
    if not unit or not spell then
        return
    end

    if not self.tCurrentEncounter then
        return
    end

    if not self.runtime.units then
        return
    end

    if self.runtime.units[unit:GetId()] ~= nil and self.runtime.units[unit:GetId()].bOnBuff then
        local tData = {
            nId = spell.splEffect:GetId(),
            sName = spell.splEffect:GetName(),
            nUnitId = unit:GetId(),
            sUnitName = unit:GetName(),
            tUnit = unit,
            tSpell = spell,
        }

        if self.tCurrentEncounter and self.tCurrentEncounter.OnBuffRemoved then
            self.tCurrentEncounter:OnBuffRemoved(tData.nUnitId, tData.nId, tData.sName, tData, tData.sUnitName)
        end
    end
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # TIMERS
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:AddTimer(sName,sText,nDuration,sColor,fHandler,tData)
    if not sName or not nDuration then
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
    self.runtime.timer[sName].sColor = sColor or self.config.timer.barColor
    self.runtime.timer[sName].fHandler = fHandler or nil
    self.runtime.timer[sName].tData = tData or nil

    self.runtime.timer[sName].wnd:FindChild("Name"):SetText(sText or sName)
    self.runtime.timer[sName].wnd:FindChild("Duration"):SetTextColor(self.config.timer.textColor)
    self.runtime.timer[sName].wnd:FindChild("Duration"):SetText(Apollo.FormatNumber(nDuration,1,true))
    self.runtime.timer[sName].wnd:FindChild("Progress"):SetBGColor(sColor or self.config.timer.barColor)
    self.runtime.timer[sName].wnd:FindChild("Progress"):SetAnchorPoints(0,0,1,1)
    self.runtime.timer[sName].wnd:Show(false,true)
end

function LUI_BossMods:UpdateTimer(tTimer)
    if not tTimer then
        return
    end

    if not tTimer.nTick or not tTimer.nDuration then
        return
    end

    local nTick = GetTickCount()
    local nElapsed = (nTick - tTimer.nTick) / 1000
    local nRemaining = tTimer.nDuration - nElapsed

    if nElapsed >= tTimer.nDuration then
        self:RemoveTimer(tTimer.sName,true)
    else
        self.runtime.timer[tTimer.sName].nRemaining = nRemaining
        self.runtime.timer[tTimer.sName].wnd:FindChild("Duration"):SetText(Apollo.FormatNumber(nRemaining,1,true))
    end
end

function LUI_BossMods:RemoveTimer(sName,bCallback)
    if not sName then
        return
    end

    if not self.runtime.timer or not self.runtime.timer[sName] then
        return
    end

    if bCallback ~= nil and bCallback == true then
        if self.runtime.timer[sName].fHandler and self.tCurrentEncounter then
            self.runtime.timer[sName].fHandler(self.tCurrentEncounter, self.runtime.timer[sName].tData)
        end
    end

    self.runtime.timer[sName].wnd:Destroy()
    self.runtime.timer[sName] = nil
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

    for i=1,#tSorted do
        local tTimer = self.runtime.timer[tSorted[i].sName]
        local tOffsets = {0,(height * (i+1)) * -1,0,(height * i) * -1}

        if not tTimer.wnd:IsShown() then
            tTimer.wnd:SetAnchorOffsets(unpack(tOffsets))
            tTimer.wnd:FindChild("Progress"):TransitionMove(WindowLocation.new({fPoints = {0, 0, 0, 1}}), tSorted[i].nRemaining)

            if #tSorted > 1 then
                tTimer.wnd:Show(true,false,.5)
            else
                tTimer.wnd:Show(true,true)
            end
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
    if not tData or not tData.tUnit then
        return
    end

    if not self.tCurrentEncounter then
        return
    end

    local bCasting
    local sName
    local nElapsed
    local nDuration
    local nTick = GetTickCount()

    nDuration = tData.tUnit:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability)

    if nDuration ~= nil and nDuration > 0 then
        bCasting = true
        nElapsed = 0
        nDuration = nDuration * 1000
        sName = "MOO"
    end

    if not bCasting then
        bCasting = tData.tUnit:IsCasting()

        if bCasting == true then
            sName = tData.tUnit:GetCastName() or ""
            nDuration = tData.tUnit:GetCastDuration()
            nElapsed = tData.tUnit:GetCastElapsed()
            bCasting = tData.tUnit:IsCasting()
        end
    end

    if bCasting == true then
        sName = string.gsub(sName, NO_BREAK_SPACE, " ")

        if not tData.tCast then
            -- New cast
                tData.tCast = {
                bCasting = true,
                sName = sName,
                nDuration = nDuration,
                nElapsed = nElapsed,
                nTick = nTick,
                nUnitId = tData.nId,
                sUnitName = tData.sName,
                tUnit = tData.tUnit,
            }

            if self.tCurrentEncounter and self.tCurrentEncounter.OnCastStart then
                self.tCurrentEncounter:OnCastStart(tData.nId, sName, tData.tCast, tData.sName, (nDuration-nElapsed))
            end
        elseif tData.tCast then
            if sName ~= tData.tCast.sName or nElapsed < tData.tCast.nElapsed then
                -- New cast just after a previous one.
                if self.tCurrentEncounter and self.tCurrentEncounter.OnCastEnd then
                    self.tCurrentEncounter:OnCastEnd(tData.nId, tData.tCast.sName, tData.tCast, tData.sName)
                end

                tData.tCast = {
                    bCasting = true,
                    sName = sName,
                    nDuration = nDuration,
                    nElapsed = nElapsed,
                    nTick = nTick,
                    nUnitId = tData.nId,
                    sUnitName = tData.sName,
                    tUnit = tData.tUnit,
                }

                if self.tCurrentEncounter and self.tCurrentEncounter.OnCastStart then
                    self.tCurrentEncounter:OnCastStart(tData.nId, sName, tData.tCast, tData.sName, (nDuration-nElapsed))
                end
            else
                if nTick >= (tData.tCast.nTick + tData.tCast.nDuration) then
                    -- End of cast
                    if self.tCurrentEncounter and self.tCurrentEncounter.OnCastEnd then
                        self.tCurrentEncounter:OnCastEnd(tData.nId, sName, tData.tCast, tData.sName)
                    end

                    tData.tCast = nil

                    if self.runtime.cast then
                        if self.runtime.cast.sName == sName and self.runtime.cast.nUnitId == tData.nId then
                            self.runtime.cast = nil
                            self.wndCastbar:Show(false,true)
                        end
                    end
                end
            end
        end
    else
        if tData.tCast ~= nil then
            if self.tCurrentEncounter and self.tCurrentEncounter.OnCastEnd then
                self.tCurrentEncounter:OnCastEnd(tData.nId, tData.tCast.sName, tData.tCast, tData.sName)
            end

            if self.runtime.cast then
                if self.runtime.cast.sName == tData.tCast.sName and self.runtime.cast.nUnitId == tData.nId then
                    self.runtime.cast = nil
                    self.wndCastbar:Show(false,true)
                end
            end

            tData.tCast = nil
        end
    end
end

function LUI_BossMods:ShowCast(tCast,sName,sColor)
    if not tCast then
        return
    end

    if not self.wndCastbar then
        self:LoadWindows()
    end

    if not self.wndCastbar:IsShown() then
        self.wndCastbar:Show(true,true)
    end

    self.runtime.cast = tCast

    local nRemaining = (tCast.nDuration - tCast.nElapsed) / 1000
    local nElapsed = (tCast.nElapsed * 100) / tCast.nDuration
    local nProgress = nElapsed / 100
    local fPoint = 1

    if tCast.sName == "MOO" then
        fPoint = 0
        nProgress = 1 - nProgress
        self.wndCastbar:FindChild("Progress"):SetBGColor(self.config.castbar.mooColor)
    else
        self.wndCastbar:FindChild("Progress"):SetBGColor(sColor or self.config.castbar.barColor)
    end

    local sCastName = sName

    if not sCastName then
        sCastName = (tCast.sName == "MOO") and (tCast.sUnitName or "") or (tCast.sName or "")
    end

    self.wndCastbar:FindChild("Name"):SetTextColor(self.config.castbar.textColor)
    self.wndCastbar:FindChild("Name"):SetText(sCastName)
    self.wndCastbar:FindChild("Duration"):SetTextColor(self.config.castbar.textColor)
    self.wndCastbar:FindChild("Duration"):SetText(Apollo.FormatNumber(nRemaining,1,true))
    self.wndCastbar:FindChild("Progress"):SetAnchorPoints(0, 0, nProgress, 1)
    self.wndCastbar:FindChild("Progress"):TransitionMove(WindowLocation.new({fPoints = {0, 0, fPoint, 1}}), nRemaining)
end

function LUI_BossMods:UpdateCast()
    if not self.runtime.cast then
        if self.wndCastbar:IsShown() then
            self.wndCastbar:Show(false,true)
        end

        return
    end

    local tCast = self.runtime.cast
    local nTick = GetTickCount()
    local nTotal = (tCast.nDuration - tCast.nElapsed)
    local nElapsed = (nTick - tCast.nTick)
    local nRemaining = (nTotal - nElapsed) / 1000

    if nElapsed > nTotal then
        self:HideCast()
    else
        self.wndCastbar:FindChild("Duration"):SetText(Apollo.FormatNumber(nRemaining,1,true))
    end
end

function LUI_BossMods:HideCast()
    self.runtime.cast = nil

    if self.wndCastbar:IsShown() then
        self.wndCastbar:Show(false,true)
    end
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # AURAS
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:ShowAura(sName,sSprite,sColor,nDuration,bShowDuration,fHandler,tData)
    if not sName then
        return
    end

    if not self.wndAura then
        self:LoadWindows()
    end

    if nDuration then
        self.wndAura:FindChild("Overlay"):SetFullSprite(sSprite or self.config.aura.sprite)
        self.wndAura:FindChild("Overlay"):SetBarColor("a0000000")
        self.wndAura:FindChild("Overlay"):SetBGColor("a0000000")
        self.wndAura:FindChild("Overlay"):SetMax(100)
        self.wndAura:FindChild("Overlay"):SetProgress(0.001)
        self.wndAura:FindChild("Overlay"):SetProgress(99.999,(100/nDuration))
        self.wndAura:FindChild("Overlay"):Show(true,true)

        self.wndAura:FindChild("Duration"):SetText()
        self.wndAura:FindChild("Duration"):Show(bShowDuration or false,true)

        self.runtime.aura = {
            sName = sName,
            nTick = GetTickCount(),
            nDuration = nDuration,
            bShowDuration = bShowDuration or false,
            fHandler = fHandler or nil,
            tData = tData or nil
        }
    else
        self.runtime.aura = {
            sName = sName
        }

        if self.wndAura:FindChild("Overlay"):IsShown() then
            self.wndAura:FindChild("Overlay"):Show(false,true)
        end

        if self.wndAura:FindChild("Duration"):IsShown() then
            self.wndAura:FindChild("Duration"):Show(false,true)
        end
    end

    self.wndAura:FindChild("Icon"):SetSprite(sSprite or self.config.aura.sprite)
    self.wndAura:FindChild("Icon"):SetBGColor(sColor or self.config.aura.color)

    if not self.wndAura:FindChild("Icon"):IsShown() then
        self.wndAura:FindChild("Icon"):Show(true,true)
    end

    if not self.wndAura:IsShown() then
        self.wndAura:Show(true,true)
    end
end

function LUI_BossMods:HideAura(sName,bCallback)
    if not sName then
        return
    end

    if not self.runtime.aura then
        return
    end

    if self.runtime.aura.sName == sName then
        if bCallback ~= nil and bCallback == true then
            if self.runtime.aura.fHandler and self.tCurrentEncounter then
                self.runtime.aura.fHandler(self.tCurrentEncounter, self.runtime.aura.tData)
            end
        end

        self.runtime.aura = nil
        self.wndAura:Show(false,true)
    end
end

function LUI_BossMods:UpdateAura()
    if not self.runtime.aura then
        return
    end

    if not self.runtime.aura.nTick then
        return
    end

    local tAura = self.runtime.aura
    local nTick = GetTickCount()
    local nTotal = tAura.nDuration
    local nElapsed = (nTick - tAura.nTick) / 1000
    local nRemaining = (nTotal - nElapsed)

    if nElapsed > nTotal then
        if tAura.fHandler and self.tCurrentEncounter then
            tAura.fHandler(self.tCurrentEncounter, tAura.tData)
        end

        self.runtime.aura = nil
        self.wndAura:Show(false,true)
    else
        if tAura.bShowDuration then
            self.wndAura:FindChild("Duration"):SetText(Apollo.FormatNumber(nRemaining,1,true))
        end
    end
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # ALERTS
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:ShowAlert(sName, sText, nDuration, sColor, sFont)
    if not sName or not sText then
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
    self.runtime.alerts[sName].nDuration = nDuration or 5
    self.runtime.alerts[sName].wnd:SetText(sText or "")
    self.runtime.alerts[sName].wnd:SetFont(sFont or self.config.alerts.font)
    self.runtime.alerts[sName].wnd:SetTextColor(sColor or self.config.alerts.color)

    self.wndAlerts:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop)

    if not self.runtime.alerts[sName].wnd:IsShown() then
        self.runtime.alerts[sName].wnd:Show(true,false,.25)
    end

    if not self.wndAlerts:IsShown() then
        self.wndAlerts:Show(true,true)
    end
end

function LUI_BossMods:UpdateAlert(tAlert)
    if not tAlert then
        return
    end

    if not tAlert.nTick or not tAlert.nDuration then
        return
    end

    local nTick = GetTickCount()
    local nTotal = tAlert.nDuration
    local nElapsed = (nTick - tAlert.nTick) / 1000

    if nElapsed > nTotal then
        self.runtime.alerts[tAlert.sName].wnd:Destroy()
        self.runtime.alerts[tAlert.sName] = nil
    end
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # SOUNDS
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:PlaySound(sound)
    if not sound or sound == "" then
        return
    end

    self:SetVolume()

    if type(sound) == "string" then
        Sound.PlayFile("Sounds\\"..sound..".wav")
    else
        Sound.Play(sound)
    end

    if self.config.sound.force == true then
        if self.VolumeTimer == nil then
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

    if mute then
        Apollo.SetConsoleVariable("sound.mute", false)
        Apollo.SetConsoleVariable("sound.volumeMaster", 0.5)
        Apollo.SetConsoleVariable("sound.volumeUI", 0.01)
        Apollo.SetConsoleVariable("sound.volumeMusic", 0)
        Apollo.SetConsoleVariable("sound.volumeSfx", 0)
        Apollo.SetConsoleVariable("sound.volumeAmbient", 0)
        Apollo.SetConsoleVariable("sound.volumeVoice", 0)
    end

    if not self.tVolume then
        self.tVolume = {}
    end

    self.tVolume.Master = Apollo.GetConsoleVariable("sound.volumeMaster")
    self.tVolume.Music = Apollo.GetConsoleVariable("sound.volumeMusic")
    self.tVolume.Voice = Apollo.GetConsoleVariable("sound.volumeUI")
    self.tVolume.Sfx = Apollo.GetConsoleVariable("sound.volumeSfx")
    self.tVolume.Ambient = Apollo.GetConsoleVariable("sound.volumeAmbient")
    self.tVolume.Voice = Apollo.GetConsoleVariable("sound.volumeVoice")
end

function LUI_BossMods:RestoreVolume()
    if self.config.sound.force == true then
        Apollo.SetConsoleVariable("sound.volumeMaster", self.tVolume.Master)
        Apollo.SetConsoleVariable("sound.volumeMusic", self.tVolume.Music)
        Apollo.SetConsoleVariable("sound.volumeUI", self.tVolume.Voice)
        Apollo.SetConsoleVariable("sound.volumeSfx", self.tVolume.Sfx)
        Apollo.SetConsoleVariable("sound.volumeAmbient", self.tVolume.Ambient)
        Apollo.SetConsoleVariable("sound.volumeVoice", self.tVolume.Voice)
    end
end

function LUI_BossMods:SetVolume()
    if self.config.sound.force == true then
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
-- # PIXIES (Where the magic happens!) - Thanks to author(s) of RaidCore
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

function LUI_BossMods:DrawIcon(Key, Origin, sSprite, nSpriteSize, nSpriteHeight, sColor, nDuration, bShowOverlay, fHandler, tData)
    if not Key or not Origin then
        return
    end

    if not type(Origin) == "userdata" then
        return
    end

    if not Origin:IsValid() then
        return
    end

    if not self.wndOverlay then
        self:LoadWindows()
    end

    if not self.tDraws then
        self.tDraws = {}
    end

    if self.tDraws[Key] ~= nil then
        if self.tDraws[Key].wnd then
            self.tDraws[Key].wnd:Show(false,true)
            self.tDraws[Key].wnd:Destroy()
        end

        self.tDraws[Key] = nil
    end

    local nSize = (nSpriteSize/2) or self.config.icon.size
    local wnd = Apollo.LoadForm(self.xmlDoc, "Icon", nil, self)
    local nHeight = nSpriteHeight or 40

    wnd:SetAnchorOffsets((nSize*-1),((nSize*-1)-nHeight),nSize,(nSize-nHeight))
    wnd:SetSprite(sSprite or self.config.icon.sprite)
    wnd:SetBGColor(sColor or self.config.icon.color)
    wnd:SetUnit(Origin)

    if nDuration ~= nil and nDuration > 0 then
        if bShowOverlay then
            wnd:FindChild("Overlay"):SetFullSprite(sSprite or self.config.icon.sprite)
            wnd:FindChild("Overlay"):SetBarColor("a0000000")
            wnd:FindChild("Overlay"):SetBGColor("a0000000")
            wnd:FindChild("Overlay"):SetMax(100)
            wnd:FindChild("Overlay"):SetProgress(0.001)
            wnd:FindChild("Overlay"):SetProgress(99.999,(100/nDuration))
            wnd:FindChild("Overlay"):Show(true,true)
        end

        self.tDraws[Key] = {
            nTick = GetTickCount(),
            nDuration = nDuration,
            sType = "Icon",
            fHandler = fHandler,
            tData = tData,
            wnd = wnd
        }
    else
        self.tDraws[Key] = {
            wnd = wnd,
            fHandler = fHandler,
            tData = tData
        }
    end
end

function LUI_BossMods:UpdateIcon(Key,tDraw)
    if tDraw.nDuration ~= nil and tDraw.nDuration > 0 then
        local nTick = GetTickCount()
        local nTotal = tDraw.nDuration
        local nElapsed = (nTick - tDraw.nTick) / 1000

        if nElapsed > nTotal then
            self:RemoveIcon(Key,true)
            return
        end
    end
end

function LUI_BossMods:RemoveIcon(Key,bCallback)
    if not self.tDraws then
        return
    end

    local tDraw = self.tDraws[Key]

    if tDraw then
        if tDraw.wnd then
            tDraw.wnd:Show(false,true)
            tDraw.wnd:Destroy()
        end

        if bCallback ~= nil and bCallback == true then
            if tDraw.fHandler and self.tCurrentEncounter then
                tDraw.fHandler(self.tCurrentEncounter, tDraw.tData)
            end
        end

        self.tDraws[Key] = nil
    end
end

function LUI_BossMods:DrawPixie(Key, Origin, sSprite, nSpriteSize, nRotation, nDistance, nHeight, sColor, nDuration, fHandler, tData)
    if not Key or not Origin then
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

    -- Register a new object to manage.
    local tDraw = self.tDraws[Key] or self:NewDraw()
    tDraw.sType = "Pixie"
    tDraw.sSprite = sSprite or tDraw.sSprite
    tDraw.nDuration = nDuration or 0
    tDraw.nTick = GetTickCount()
    tDraw.nRotation = nRotation or 0
    tDraw.nDistance = nDistance or 0
    tDraw.nHeight = nHeight or 0
    tDraw.nSpriteSize = nSpriteSize or 30
    tDraw.sColor = sColor or "white"
    tDraw.fHandler = fHandler or nil
    tDraw.tData = tData or nil

    local nRad = math.rad(tDraw.nRotation or 0)
    local nCos = math.cos(nRad)
    local nSin = math.sin(nRad)

    tDraw.RotationMatrix = {
        x = NewVector3({ nCos, 0, -nSin }),
        y = NewVector3({ 0, 1, 0 }),
        z = NewVector3({ nSin, 0, nCos }),
    }

    if OriginType == "number" then
        local tUnit = GetUnitById(Origin)
        local nRaceId = tUnit and tUnit:GetRaceId()

        tDraw.tOriginUnit = tUnit

        if nRaceId and HEIGHT_PER_RACEID[nRaceId] then
            tDraw.nHeight = HEIGHT_PER_RACEID[nRaceId]
        end
    elseif OriginType == "table" or Vector3.Is(Origin) then
        local tOriginVector = NewVector3(Origin)
        local tFacingVector = NewVector3(DEFAULT_NORTH_FACING)
        local tRefVector = tFacingVector * tDraw.nDistance

        tDraw.tVector = tOriginVector + self:Rotation(tRefVector, tDraw.RotationMatrix)
        tDraw.tVector.y = tDraw.tVector.y + tDraw.nHeight
    elseif OriginType == "userdata" then
        tDraw.tOriginUnit = Origin
    end

    self.tDraws[Key] = tDraw
end

function LUI_BossMods:UpdatePixie(Key,tDraw)
    local tVector = nil

    if tDraw.nDuration ~= nil and tDraw.nDuration > 0 then
        local nTick = GetTickCount()
        local nTotal = tDraw.nDuration
        local nElapsed = (nTick - tDraw.nTick) / 1000

        if nElapsed > nTotal then
            self:RemovePixie(Key,true)
            return
        end
    end

    if tDraw.tOriginUnit then
        if tDraw.tOriginUnit:IsValid() then
            local tOriginVector = NewVector3(tDraw.tOriginUnit:GetPosition())
            local tFacingVector = NewVector3(tDraw.tOriginUnit:GetFacing())
            local tRefVector = tFacingVector * tDraw.nDistance

            tVector = tOriginVector + self:Rotation(tRefVector, tDraw.RotationMatrix)
            tVector.y = tVector.y + tDraw.nHeight
        end
    else
        tVector = tDraw.tVector
    end

    if tVector then
        -- Convert the 3D coordonate of game in 2D coordonnate of screen
        local tScreenLoc = WorldLocToScreenPoint(tVector)

        if tScreenLoc.z > 0 then
            local tVectorPlayer = NewVector3(self.unitPlayer:GetPosition())
            local nDistance2Player = (tVectorPlayer - tVector):Length()
            local nScale = math.min(40 / nDistance2Player, 1)

            nScale = math.max(nScale, 0.5) * tDraw.nSpriteSize

            local tPixieAttributs = {
                bLine = false,
                strSprite = tDraw.sSprite,
                cr = tDraw.sColor,
                loc = {
                    fPoints = FPOINT_NULL,
                    nOffsets = {
                        tScreenLoc.x - nScale,
                        tScreenLoc.y - nScale,
                        tScreenLoc.x + nScale,
                        tScreenLoc.y + nScale,
                    },
                },
            }

            if tDraw.nPixieId then
                self.wndOverlay:UpdatePixie(tDraw.nPixieId, tPixieAttributs)
            else
                tDraw.nPixieId = self.wndOverlay:AddPixie(tPixieAttributs)
            end
        else
            -- The Line is out of sight.
            if tDraw.nPixieId then
                self.wndOverlay:DestroyPixie(tDraw.nPixieId)
                tDraw.nPixieId = nil
            end
        end
    end
end

function LUI_BossMods:RemovePixie(Key,bCallback)
    if not self.tDraws then
        return
    end
    local tDraw = self.tDraws[Key]
    if tDraw then
        if tDraw.nPixieId then
            self.wndOverlay:DestroyPixie(tDraw.nPixieId)
            tDraw.nPixieId = nil
        end

        if bCallback ~= nil and bCallback == true then
            if tDraw.fHandler and self.tCurrentEncounter then
                tDraw.fHandler(self.tCurrentEncounter, tDraw.tData)
            end
        end

        self.tDraws[Key] = nil
    end
end

function LUI_BossMods:DrawPolygon(Key, Origin, nRadius, nRotation, nWidth, sColor, nSide, nDuration, fHandler, tData)
    if not Key or not Origin then
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
    tDraw.nWidth = nWidth or 4
    tDraw.nDuration = nDuration or 0
    tDraw.nTick = GetTickCount()
    tDraw.nRotation = nRotation or 0
    tDraw.sColor = sColor or tDraw.sColor
    tDraw.nSide = nSide or 5
    tDraw.nPixieIds = tDraw.nPixieIds or {}
    tDraw.tVectors = tDraw.tVectors or {}
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
            tDraw.tVectors[i] = tOriginVector + self:Rotation(tRefVector, CornerRotate)
        end
    elseif OriginType == "userdata" then
        tDraw.tOriginUnit = Origin
    end

    self.tDraws[Key] = tDraw
end

function LUI_BossMods:UpdatePolygon(Key,tDraw)
    local tVectors = nil

    if tDraw.nDuration ~= nil and tDraw.nDuration > 0 then
        local nTick = GetTickCount()
        local nTotal = tDraw.nDuration
        local nElapsed = (nTick - tDraw.nTick) / 1000

        if nElapsed > nTotal then
            self:RemovePolygon(Key,true)
            return
        end
    end

    if tDraw.tOriginUnit then
        if tDraw.tOriginUnit:IsValid() then
            local tOriginVector = NewVector3(tDraw.tOriginUnit:GetPosition())
            local tFacingVector = NewVector3(tDraw.tOriginUnit:GetFacing())
            local tRefVector = tFacingVector * tDraw.nRadius
            tVectors = {}

            for i = 1, tDraw.nSide do
                local nRad = math.rad(360 * i / tDraw.nSide + tDraw.nRotation)
                local nCos = math.cos(nRad)
                local nSin = math.sin(nRad)
                local CornerRotate = {
                    x = NewVector3({ nCos, 0, -nSin }),
                    y = NewVector3({ 0, 1, 0 }),
                    z = NewVector3({ nSin, 0, nCos }),
                }
                tVectors[i] = tOriginVector + self:Rotation(tRefVector, CornerRotate)
            end
        end
    else
        tVectors = tDraw.tVectors
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

function LUI_BossMods:RemovePolygon(Key,bCallback)
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

        if bCallback ~= nil and bCallback == true then
            if tDraw.fHandler and self.tCurrentEncounter then
                tDraw.fHandler(self.tCurrentEncounter, tDraw.tData)
            end
        end

        self.tDraws[Key] = nil
    end
end

function LUI_BossMods:DrawLine(Key, Origin, sColor, nWidth, nLength, nRotation, nOffset, tVectorOffset, nDuration, nNumberOfDot, fHandler, tData)
    if not Key or not Origin then
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
    tDraw.nWidth = nWidth or self.config.line.thickness
    tDraw.sColor = sColor or self.config.line.color
    tDraw.nNumberOfDot = nNumberOfDot or 1
    tDraw.nPixieIdDot = tDraw.nPixieIdDot or {}
    tDraw.tVectorOffset = tVectorOffset or nil
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

        if tDraw.tVectorOffset then
            if type(tDraw.tVectorOffset) == "table" then
                tDraw.tVectorOffset = NewVector3(tDraw.tVectorOffset)
            end

            local nRad2 = -math.atan2(tFacingVector.x, tFacingVector.z)
            local nCos2 = math.cos(nRad2)
            local nSin2 = math.sin(nRad2)
            local RotationMatrix2 = {
                x = NewVector3({ nCos2, 0, -nSin2 }),
                y = NewVector3({ 0, 1, 0 }),
                z = NewVector3({ nSin2, 0, nCos2 }),
            }

            local tVectorC = self:Rotation(tDraw.tVectorOffset, RotationMatrix2)

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
            self:RemoveLine(Key,true)
            return
        end
    end

    local tVectorTo, tVectorFrom = nil, nil
    if tDraw.tOriginUnit then
        if tDraw.tOriginUnit:IsValid() then
            local tOriginVector = NewVector3(tDraw.tOriginUnit:GetPosition())
            local tFacingVector = NewVector3(tDraw.tOriginUnit:GetFacing())

            local tVectorA = tFacingVector * (tDraw.nOffset)
            local tVectorB = tFacingVector * (tDraw.nLength + tDraw.nOffset)

            tVectorA = self:Rotation(tVectorA, tDraw.RotationMatrix)
            tVectorB = self:Rotation(tVectorB, tDraw.RotationMatrix)

            tVectorFrom = tOriginVector + tVectorA
            tVectorTo = tOriginVector + tVectorB

            if tDraw.tVectorOffset then
                local nRad = -math.atan2(tFacingVector.x, tFacingVector.z)
                local nCos = math.cos(nRad)
                local nSin = math.sin(nRad)
                local RotationMatrix = {
                    x = NewVector3({ nCos, 0, -nSin }),
                    y = NewVector3({ 0, 1, 0 }),
                    z = NewVector3({ nSin, 0, nCos }),
                }

                local tVectorC = self:Rotation(tDraw.tVectorOffset, RotationMatrix)

                tVectorFrom = tVectorFrom + tVectorC
                tVectorTo = tVectorTo + tVectorC
            end
        end
    else
        tVectorTo = tDraw.tVectorTo
        tVectorFrom = tDraw.tVectorFrom
    end

    self:UpdateDraw(tDraw,tVectorFrom,tVectorTo)
end

function LUI_BossMods:RemoveLine(Key,bCallback)
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

        if bCallback ~= nil and bCallback == true then
            if tDraw.fHandler and self.tCurrentEncounter then
                tDraw.fHandler(self.tCurrentEncounter, tDraw.tData)
            end
        end

        self.tDraws[Key] = nil
    end
end

function LUI_BossMods:DrawLineBetween(Key, FromOrigin, OriginTo, nWidth, sColor, nDuration, nNumberOfDot, fHandler, tData)
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
    tDraw.nWidth = nWidth or self.config.line.thickness
    tDraw.sColor = sColor or self.config.line.color
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
        ToOrigin = (self.unitPlayer ~= nil) and self.unitPlayer or GetPlayerUnit()
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
            self:RemoveLineBetween(Key,true)
            return
        end
    end

    local tVectorFrom, tVectorTo = nil, nil

    if tDraw.tUnitFrom then
        if tDraw.tUnitFrom:IsValid() then
            tVectorFrom = NewVector3(tDraw.tUnitFrom:GetPosition())
        end
    else
        tVectorFrom = tDraw.tVectorFrom
    end

    if tDraw.tUnitTo then
        if tDraw.tUnitTo:IsValid() then
            tVectorTo = NewVector3(tDraw.tUnitTo:GetPosition())
        end
    else
        tVectorTo = tDraw.tVectorTo
    end

    self:UpdateDraw(tDraw,tVectorFrom,tVectorTo)
end

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

function LUI_BossMods:RemoveLineBetween(Key,bCallback)
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

        if bCallback ~= nil and bCallback == true then
            if tDraw.fHandler and self.tCurrentEncounter then
                tDraw.fHandler(self.tCurrentEncounter, tDraw.tData)
            end
        end

        self.tDraws[Key] = nil
    end
end

-- #########################################################################################################################################
-- #########################################################################################################################################
-- #
-- # TEMPLATES
-- #
-- #########################################################################################################################################
-- #########################################################################################################################################

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
        ToOrigin = (self.unitPlayer ~= nil) and self.unitPlayer or GetPlayerUnit()
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
        self.wndTimers:SetData("timer")
        self.wndTimers:Show(false,true)

        self.wndTimers:SetAnchorOffsets(
            self.config.timer.offsets.left,
            self.config.timer.offsets.top,
            self.config.timer.offsets.right,
            self.config.timer.offsets.bottom
        )
    end

    if not self.wndUnits and self.config.units.enable == true then
        self.wndUnits = Apollo.LoadForm(self.xmlDoc, "Container", nil, self)
        self.wndUnits:SetSizingMinimum(200, 200)
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

function LUI_BossMods:OnSlashCommand()
	self.settings:OnToggleMenu()
end

function LUI_BossMods:OnInterfaceMenuListHasLoaded()
    Event_FireGenericEvent("InterfaceMenuList_NewAddOn","LUI BossMods", {"LUIBossMods_ToggleMenu", "", "LUI_BossMods:logo" })
end

function LUI_BossMods:OnSave(eType)
    if eType ~= GameLib.CodeEnumAddonSaveLevel.General then
        return
    end

    if self.config.modules ~= nil then
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

    if tSavedData ~= nil and tSavedData ~= "" then
        self.config = self:InsertDefaults(tSavedData,self.config)

        for sName,tModule in pairs(self.modules) do
            if self.config.modules[sName] then
                tModule.config = self:InsertDefaults(self.config.modules[sName], tModule.config)
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

function LUI_BossMods:GetLanguage()
    local strCancel = Apollo.GetString(1)

    if strCancel == "Abbrechen" then
        self.language = "deDE"
    elseif strCancel == "Annuler" then
        self.language = "frFR"
    else
        self.language = "enUS"
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
