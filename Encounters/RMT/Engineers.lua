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
        ["unit.circle_telegraph"] = "Hostile Invisible Unit for Fields (1.2 hit radius)",
        -- Debuffs
        ["debuff.atomic_attraction"] = "Atomic Attraction",
        ["debuff.electroshock_vulnerability"] = "Electroshock Vulnerability",
        ["debuff.discharged_plasma"] = "Discharged Plasma", -- Not 100% sure about name
        -- Casts
        ["cast.electroshock"] = "Electroshock",
        ["cast.liquidate"] = "Liquidate",
        -- Alerts
        ["alert.liquidate"] = "Liquidate!",
        ["alert.electroshock"] = "Electroshock!",
        -- datachron
        ["datachron.electroshock"] = "(.*) suffers from Electroshock",
        -- labels
        ["label.pillar"] = "20% Health Warning",
        ["label.circle_telegraph"] = "Circle Telegraphs",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

local DEBUFF__ELECTROSHOCK_VULNERABILITY = 83798
local DEBUFF_ATOMIC_ATTRACTION = 84052
local BUFF_INSULATION = 83987

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
        units = {
            gun = {
                enable = true,
                priority = 1,
                label = "unit.boss_gun",
                color = "afafafaf",
            },
            sword = {
                enable = true,
                priority = 2,
                label = "unit.boss_sword",
                color = "afafafaf",
            },
            spark = {
                enable = true,
                priority = 3,
                label = "unit.spark_plug",
                color = "afb0ff2f",
            },
            fusion = {
                enable = true,
                priority = 4,
                label = "unit.fusion_core",
                color = "afb0ff2f",
            },
            cooling = {
                enable = true,
                priority = 5,
                label = "unit.cooling_turbine",
                color = "ade91dfb",
            },
            lubricant = {
                enable = true,
                priority = 6,
                label = "unit.lubricant_nozzle",
                color = "ade91dfb",
            },
        },
        timers = {
            electroshock = {
                enable = true,
                color = "ade91dfb",
                label = "cast.electroshock",
            },
            liquidate = {
                enable = true,
                color = "afb0ff2f",
                label = "cast.liquidate",
            },
            vulnerability = {
                enable = true,
                color = "aaee94fd",
                label = "debuff.electroshock_vulnerability",
            },
            atomic_attraction = {
                enable = true,
                color = "afff4500",
                label = "debuff.atomic_attraction",
            },
        },
        alerts = {
            pillar = {
                enable = true,
                duration = 5,
                label = "label.pillar",
            },
            atomic_attraction = {
                enable = true,
                color = "ffff4500",
                duration = 5,
                label = "debuff.atomic_attraction",
            },
            electroshock = {
                enable = false,
                duration = 5,
                label = "cast.electroshock",
            },
            liquidate = {
                enable = false,
                duration = 5,
                label = "cast.liquidate",
            },
        },
        sounds = {
            pillar = {
                enable = true,
                file = "alert",
                label = "label.pillar",
            },
            atomic_attraction = {
                enable = true,
                file = "alert",
                label = "debuff.atomic_attraction",
            },
            electroshock = {
                enable = false,
                label = "cast.electroshock",
            },
            liquidate = {
                enable = false,
                label = "cast.liquidate",
            },
        },
        icons = {
            electroshock = {
                enable = true,
                sprite = "target2",
                size = 60,
                color = "ff40e0d0",
                label = "cast.electroshock",
            },
            atomic_attraction = {
                enable = true,
                sprite = "bomb",
                size = 60,
                color = "ffff4500",
                label = "debuff.atomic_attraction",
            },
        },
        lines = {
            gun = {
                enable = true,
                thickness = 10,
                color = "ffff0000",
                label = "unit.boss_gun",
            },
            sword = {
                enable = true,
                thickness = 7,
                color = "ffff0000",
                label = "unit.boss_sword",
            },
            circle_telegraph = {
                enable = true,
                thickness = 7,
                color = "ffff4500",
                label = "label.circle_telegraph",
            },
        },
    }
    return o
end

function Mod:Init(parent)
    Apollo.LinkAddon(parent, self)

    self.core = parent
    self.L = parent:GetLocale(Encounter,Locales)
end

function Mod:OnDatachron(sMessage, sSender, sHandler)
    if self.config.timers.vulnerability.enable == true then
        local strPlayer = sMessage:match(self.L["datachron.electroshock"])
        if strPlayer then
            self.core:AddTimer("ElectroshockTimer_"..strPlayer, strPlayer, 60, self.config.timers.vulnerability.color)
        end
    end
end

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run == true then
        return
    end

    if sName == self.L["unit.boss_gun"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.gun.enable,true,false,false,nil,self.config.units.gun.color, self.config.units.gun.priority)

        if self.config.lines.gun.enable == true then
            self.core:DrawLine(nId, tUnit, self.config.lines.gun.color, self.config.lines.gun.thickness, 20)
        end

        if self.config.timers.electroshock.enable == true then
            self.core:AddTimer("cast.electroshock", self.L["cast.electroshock"], 10, self.config.timers.electroshock.color, Mod.OnElectroshock, tUnit)
        end
    elseif sName == self.L["unit.boss_sword"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.sword.enable,true,false,false,nil,self.config.units.sword.color, self.config.units.sword.priority)

        if self.config.lines.sword.enable == true then
            self.core:DrawLine("CleaveA", tUnit, self.config.lines.sword.color, self.config.lines.sword.thickness, 15, -50, 0, Vector3.New(2,0,-1.5))
            self.core:DrawLine("CleaveB", tUnit, self.config.lines.sword.color, self.config.lines.sword.thickness, 15, 50, 0, Vector3.New(-2,0,-1.5))
        end

        if self.config.timers.liquidate.enable == true then
            self.core:AddTimer("cast.liquidate", self.L["cast.liquidate"], 10, self.config.timers.liquidate.color, Mod.OnLiquidate, tUnit)
        end
    elseif sName == self.L["unit.fusion_core"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.fusion.enable,false,true,false,nil,self.config.units.fusion.color, self.config.units.fusion.priority)
    elseif sName == self.L["unit.lubricant_nozzle"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.lubricant.enable,false,false,false,nil,self.config.units.lubricant.color, self.config.units.lubricant.priority)
    elseif sName == self.L["unit.spark_plug"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.spark.enable,false,false,false,nil,self.config.units.spark.color, self.config.units.spark.priority)
    elseif sName == self.L["unit.cooling_turbine"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.cooling.enable,false,false,false,nil,self.config.units.cooling.color, self.config.units.cooling.priority)
    elseif sName == self.L["unit.circle_telegraph"] then
        if self.config.lines.circle_telegraph.enable == true then
            self.core:DrawPolygon(nId, tUnit, 6.3, 0, self.config.lines.circle_telegraph.thickness, self.config.lines.circle_telegraph.color, 20)
        end
    end
end

function Mod:OnHealthChanged(nId, nPercent, sName, tUnit)
    if self.config.alerts.pillar.enable == true or self.config.sounds.pillar == true then
        if sName == self.L["unit.fusion_core"] or sName == self.L["unit.lubricant_nozzle"] or sName == self.L["unit.spark_plug"] or sName == self.L["unit.cooling_turbine"] then
            if nPercent < 20 then
                if self.core:GetDistance(tUnit) < 30 then
                    if not self.warned or self.warned ~= sName then
                        if self.config.sounds.pillar.enable == true then
                            self.core:PlaySound(self.config.sounds.pillar.file)
                        end

                        if self.config.alerts.pillar.enable == true then
                            self.core:ShowAlert("Pillar", sName.." at 20%!",self.config.alerts.pillar.duration, self.config.alerts.pillar.color)
                        end

                        self.warned = sName
                    end
                end
            end
        end
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if nSpellId == DEBUFF__ELECTROSHOCK_VULNERABILITY then
        if self.config.icons.electroshock.enable == true then
            self.core:DrawIcon("Electroshock_"..tostring(nId), tData.tUnit, self.config.icons.electroshock.sprite, self.config.icons.electroshock.size, nil, self.config.icons.electroshock.color, nDuration)
        end
    elseif nSpellId == DEBUFF_ATOMIC_ATTRACTION then
        if self.config.icons.atomic_attraction.enable == true then
            self.core:DrawIcon("Orb_"..tostring(nId), tData.tUnit, self.config.icons.atomic_attraction.sprite, self.config.icons.atomic_attraction.size, nil, self.config.icons.atomic_attraction.color, nDuration)
        end

        if self.config.alerts.atomic_attraction.enable == true then
            self.core:ShowAlert("Orb_"..tostring(nId), self.L["debuff.atomic_attraction"].." on "..sName, self.config.alerts.atomic_attraction.duration, self.config.alerts.atomic_attraction.color)
        end

        if self.config.timers.atomic_attraction.enable == true then
            self.core:AddTimer("atomic_attraction", self.L["debuff.atomic_attraction"], 23, self.config.timers.atomic_attraction.color)
        end

        if self.config.sounds.atomic_attraction.enable == true then
            if tData.tUnit:IsThePlayer() then
                self.core:PlaySound(self.config.sounds.atomic_attraction.file)
            end
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if nSpellId == DEBUFF__ELECTROSHOCK_VULNERABILITY then
        self.core:RemoveIcon("Electroshock_"..tostring(nId))
    elseif nSpellId == DEBUFF_ATOMIC_ATTRACTION then
        self.core:RemoveIcon("Orb_"..tostring(nId))
    elseif nSpellId == BUFF_INSULATION and sUnitName == self.L["unit.fusion_core"] then
        if self.config.timers.atomic_attraction.enable == true then
            self.core:AddTimer("atomic_attraction", self.L["debuff.atomic_attraction"], 23, self.config.timers.atomic_attraction.color)
        end
    end
end

function Mod:OnCastEnd(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss_gun"] and sCastName == self.L["cast.electroshock"] then
        if self.config.timers.electroshock.enable == true then
            self.core:AddTimer("cast.electroshock", sCastName, 20, self.config.timers.electroshock.color, Mod.OnElectroshock, tCast.tUnit)
        end
    elseif sName == self.L["unit.boss_sword"] and sCastName == self.L["cast.liquidate"] then
        if self.config.timers.liquidate.enable == true then
            self.core:AddTimer("cast.liquidate", sCastName, 20, self.config.timers.liquidate.color, Mod.OnLiquidate, tCast.tUnit)
        end
    end
end

function Mod:OnLiquidate(tUnit)
    if not tUnit then
        return
    end

    local distance = self.core:GetDistance(tUnit)

    if distance < 30 then
        if self.config.alerts.liquidate.enable == true then
            self.core:ShowAlert("liquidate", self.L["alert.liquidate"], self.config.alerts.liquidate.duration, self.config.alerts.liquidate.color)
        end

        if self.config.sounds.liquidate.enable == true then
            self.core:PlaySound(self.config.sounds.liquidate.file)
        end
    end
end

function Mod:OnElectroshock(tUnit)
    if not tUnit then
        return
    end

    local distance = self.core:GetDistance(tUnit)

    if distance < 30 then
        if self.config.alerts.electroshock.enable == true then
            self.core:ShowAlert("electroshock", self.L["alert.electroshock"], self.config.alerts.electroshock.duration, self.config.alerts.electroshock.color)
        end

        if self.config.sounds.electroshock.enable == true then
            self.core:PlaySound(self.config.sounds.electroshock.file)
        end
    end
end

function Mod:IsRunning()
    return self.run
end

function Mod:IsEnabled()
    return self.config.enable
end

function Mod:OnEnable()
    self.run = true
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
