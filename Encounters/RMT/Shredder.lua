require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Shredder"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss"] = "Swabbie Ski'Li",
        ["unit.noxious_nabber"] = "Noxious Nabber",
        ["unit.regor_the_rancid"] = "Regor the Rancid", -- Miniboss during Midphase
        ["unit.sawblade"] = "Sawblade",
        ["unit.circle_telegraph"] = "Hostile Invisible Unit for Fields (1.2 hit radius)",
        -- Casts
        ["cast.necrotic_lash"] = "Necrotic Lash", -- Cast by Noxious Nabber (grab and disorient), interruptable
        ["cast.deathwail"] = "Deathwail", -- Miniboss knockdown, interruptable
        ["cast.gravedigger"] = "Gravedigger", -- Miniboss cast
        -- Alerts
        ["alert.interrupt"] = "Interrupt!",
        -- Datachron
        ["datachron.shredder_start"] = "WARNING: THE SHREDDER IS STARTING!",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

local DEBUFF__OOZING_BILE = 84321
local DECK_Y_LOC = 598
local ENTRANCELINE_A = Vector3.New(-1, DECK_Y_LOC, -830)
local ENTRANCELINE_B = Vector3.New(-40, DECK_Y_LOC, -830)
local CENTERLINE_A = Vector3.New(-1, DECK_Y_LOC, -882)
local CENTERLINE_B = Vector3.New(-41, DECK_Y_LOC, -882)
local EXITLINE_A = Vector3.New(-1, DECK_Y_LOC, -980)
local EXITLINE_B = Vector3.New(-41, DECK_Y_LOC, -980)

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"
    self.displayName = "Shredder"
    self.tTrigger = {
        sType = "ANY",
        tZones = {
            [1] = {
                continentId = 104,
                parentZoneId = 548,
                mapId = 549,
            },
        },
        tNames = {
            ["enUS"] = {"Swabbie Ski'Li"},
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        bDrawRoomLines = true,
        bDrawSawLines = true,
        bDrawCircleTelegraphs = true,
        bOozingBileWarning = true,
        interrupt = {
            enable = true,
            sound = true,
            cast = true,
        }
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
        self.core:AddUnit(nId,sName,tUnit,true)

        if self.config.bDrawRoomLines == true then
            self.core:DrawLineBetween("ExitLine", EXITLINE_A, EXITLINE_B, 5, "xkcdBrightPurple")
            self.core:DrawLineBetween("CenterLine", CENTERLINE_A, CENTERLINE_B, 5, "xkcdBrightPurple")
            self.core:DrawLineBetween("EntranceLine", ENTRANCELINE_A, ENTRANCELINE_B, 5, "xkcdBrightPurple")
        end
    elseif sName == self.L["unit.noxious_nabber"] then
        self.core:AddUnit(nId,sName,tUnit,false,nil,true)
    elseif sName == self.L["unit.regor_the_rancid"] then
        self.core:AddUnit(nId,sName,tUnit,false,nil,true)
    elseif sName == self.L["unit.sawblade"] then
        if self.config.bDrawSawLines == true then
            self.core:DrawLine(nId, tUnit, "xkcdBrightPurple", 15, 60, 0, 0)
        end
    elseif sName == self.L["unit.circle_telegraph"] then
        if self.config.bDrawCircleTelegraphs == true then
            self.core:DrawPolygon(nId, tUnit, 6.7, 0, 7, "xkcdBloodOrange", 20)
        end
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.sawblade"] then
        self.core:RemoveLine(nId)
    elseif sName == self.L["unit.circle_telegraph"] then
        self.core:RemovePolygon(nId)
    end
end

function Mod:OnBuffUpdated(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if self.config.bOozingBileWarning == true then
        if DEBUFF__OOZING_BILE == nSpellId then
            if tData.tUnit:IsThePlayer() then
                if nStack >= 8 then
                    self.core:ShowAura("OOZE","LUI_BossMods:stop2","ffff0000",nDuration)
                end
            end
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if self.config.bOozingBileWarning == true then
        if DEBUFF__OOZING_BILE == nSpellId then
            if tData.tUnit:IsThePlayer() then
                self.core:HideAura("OOZE")
            end
        end
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if self.config.interrupt.enable == true then
        if self.L["unit.noxious_nabber"] == sName then
            if self.L["cast.necrotic_lash"] == sCastName then
                if self.core:GetDistance(tCast.tUnit) < 30 then
                    if self.config.interrupt.alert == true then
                        self.core:ShowAlert(nId, self.L["alert.interrupt"])
                    end

                    if self.config.interrupt.sound == true then
                        self.core:PlaySound("alert")
                    end

                    if self.config.interrupt.cast == true then
                        self.core:ShowCast(tCast)
                    end
                end
            end
        elseif self.L["unit.regor_the_rancid"] == sName then
            if self.L["cast.deathwail"] == sCastName or self.L["cast.gravedigger"] == sCastName then
                if self.config.interrupt.alert == true then
                    self.core:ShowAlert(nId, self.L["alert.interrupt"])
                end

                if self.config.interrupt.sound == true then
                    self.core:PlaySound("alert")
                end

                if self.config.interrupt.cast == true then
                    self.core:ShowCast(tCast)
                end
            end
        end
    end
end

function Mod:LoadSettings(wndParent)
    if not wndParent then
        return
    end

    return Apollo.LoadForm(self.xmlDoc, "Settings", wndParent, self)
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
