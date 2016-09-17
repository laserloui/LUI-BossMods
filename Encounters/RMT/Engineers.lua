require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Engineers"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss_gun"] = "Head Engineer Orvulgh",
        ["unit.boss_sword"] = "Chief Engineer Wilbargh",
        ["unit.fusion_core"] = "Fusion Core",
        ["unit.lubricant_nozzle"] = "Lubricant Nozzle",
        ["unit.spark_plug"] = "Spark Plug",
        ["unit.cooling_turbine"] = "Cooling Turbine",
        -- Debuffs
        ["debuff.atomic_attraction"] = "Atomic Attraction",
        ["debuff.electroshock_vulnerability"] = "Electroshock Vulnerability",
 		["debuff.discharged_plasma"] = "Discharged Plasma", -- Not 100% sure about name
        -- Casts
        ["cast.electroshock"] = "Electroshock",
        ["cast.liquidate"] = "Liquidate",
        -- Alerts
        ["alert.liquidate"] = "Liquidate soon!",
        ["alert.electroshock"] = "Electroshock soon!",
        ["alert.cleave"] = "STOP CLEAVING!",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"
    self.displayName = "Engineers"
    self.tTrigger = {
        sType = "ANY",
        tZones = {
            [1] = {
                continentId = 104,
                parentZoneId = 548,
                mapId = 552,
            },
        },
        tNames = {
            ["enUS"] = {"Head Engineer Orvulgh","Chief Engineer Wilbargh"},
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        PillarHealth = {
            enable = true,
            sound = true,
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

    if sName == self.L["unit.boss_gun"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,false,nil,true)
        self.core:DrawLine(nId, tUnit, "Red", 10, 17)
    elseif sName == self.L["unit.boss_sword"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,false,nil,true)
        self.core:DrawLine("CleaveA", tUnit, "Red", 7, 15, -50, 0, Vector3.New(2,0,-1.5))
        self.core:DrawLine("CleaveB", tUnit, "Red", 7, 15, 50, 0, Vector3.New(-2,0,-1.5))
    elseif sName == self.L["unit.fusion_core"] or sName == self.L["unit.lubricant_nozzle"] or sName == self.L["unit.spark_plug"] or sName == self.L["unit.cooling_turbine"] then
        self.core:AddUnit(nId,sName,tUnit,true)
    end
end

function Mod:OnHealthChanged(nId, nPercent, sName, tUnit)
    if self.config.PillarHealth.enable == true then
        if sName == self.L["unit.fusion_core"] or sName == self.L["unit.lubricant_nozzle"] or sName == self.L["unit.spark_plug"] or sName == self.L["unit.cooling_turbine"] then
            if nPercent < 20 then
                if self.core:GetDistance(tUnit) < 30 then
                    if not self.warned or self.warned ~= sName then
                        if self.config.PillarHealth.sound == true then
                            self.core:PlaySound("alert")
                        end
                        self.core:ShowAlert("cleave", self.L["alert.cleave"])
                        self.warned = sName
                    end
                end
            end
        end
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss_gun"] and sCastName == self.L["cast.electroshock"] then
        self.core:AddTimer(sCastName, sCastName, 20, "afb0ff2f", Mod.OnElectroshock, tCast.tUnit)
    elseif sName == self.L["unit.boss_sword"] and sCastName == self.L["cast.liquidate"] then
        self.core:AddTimer(sCastName, sCastName, 20, "aff900ff", Mod.OnLiquidate, tCast.tUnit)
    end
end

function Mod:OnLiquidate(tUnit)
    if tUnit and self.core:GetDistance(tUnit) < 30 then
        self.core:ShowAlert("liquidate", self.L["alert.liquidate"])
    end
end

function Mod:OnElectroshock(tUnit)
    if tUnit and self.core:GetDistance(tUnit) < 30 then
        self.core:ShowAlert("electroshock", self.L["alert.electroshock"])
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
