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
        ["alert.liquidate"] = "Liquidate!",
        ["alert.electroshock"] = "Electroshock!",
        -- datachron
        ["datachron.electroshock"] = "(.*) suffers from Electroshock",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

local DEBUFF__ELECTROSHOCK_VULNERABILITY = 83798
local DEBUFF_ATOMIC_ATTRACTION = 84052

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"
    self.displayName = "Engineers"
    self.bHasSettings = true
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
                name = "Head Engineer Orvulgh",
            },
            sword = {
                enable = true,
                priority = 2,
                name = "Chief Engineer Wilbargh",
            },
            spark = {
                enable = true,
                priority = 3,
                name = "Spark Plug",
                color = "afb0ff2f",
            },
            fusion = {
                enable = true,
                priority = 4,
                name = "Fusion Core",
                color = "afb0ff2f",
            },
            cooling = {
                enable = true,
                priority = 5,
                name = "Cooling Turbine",
                color = "ade91dfb",
            },
            lubricant = {
                enable = true,
                priority = 6,
                name = "Lubricant Nozzle",
                color = "ade91dfb",
            },
        },
        lines = {
            gun = {
                enable = true,
                thickness = 10,
                color = "ffff0000",
            },
            sword = {
                enable = true,
                thickness = 7,
                color = "ffff0000",
            },
        },
        timers = {
            electroshock = {
                enable = true,
                color = "ade91dfb",
            },
            liquidate = {
                enable = true,
                color = "afb0ff2f",
            },
            vulnerability = {
                enable = true,
                color = "aaee94fd",
            },
        },
        alerts = {
            pillar = {
                enable = true,
                duration = 5,
            },
            orb = {
                enable = true,
                color = "ffff4500",
                duration = 5,
            },
            electroshock = {
                enable = false,
                duration = 5,
            },
            liquidate = {
                enable = false,
                duration = 5,
            },
        },
        sounds = {
            pillar = {
                enable = true,
                file = "alert",
            },
            orb = {
                enable = true,
                file = "alert",
            },
            electroshock = {
                enable = false,
            },
            liquidate = {
                enable = false,
            },
        },
        icons = {
            electroshock = {
                enable = true,
                sprite = "target2",
                size = 60,
                color = "ff40e0d0",
            },
            orb = {
                enable = true,
                sprite = "bomb",
                size = 60,
                color = "ffff4500",
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
            self.core:DrawLine(nId, tUnit, self.config.lines.gun.color, self.config.lines.gun.thickness, 17)
        end

        if self.config.timers.electroshock.enable == true then
            self.core:AddTimer(self.L["cast.electroshock"], self.L["cast.electroshock"], 10, self.config.timers.electroshock.color, Mod.OnElectroshock, tUnit)
        end
    elseif sName == self.L["unit.boss_sword"] and bInCombat == true then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.sword.enable,true,false,false,nil,self.config.units.sword.color, self.config.units.sword.priority)

        if self.config.lines.sword.enable == true then
            self.core:DrawLine("CleaveA", tUnit, self.config.lines.sword.color, self.config.lines.sword.thickness, 15, -50, 0, Vector3.New(2,0,-1.5))
            self.core:DrawLine("CleaveB", tUnit, self.config.lines.sword.color, self.config.lines.sword.thickness, 15, 50, 0, Vector3.New(-2,0,-1.5))
        end

        if self.config.timers.liquidate.enable == true then
            self.core:AddTimer(self.L["cast.liquidate"], self.L["cast.liquidate"], 10, self.config.timers.liquidate.color, Mod.OnLiquidate, tUnit)
        end
    elseif sName == self.L["unit.fusion_core"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.fusion.enable,false,false,false,nil,self.config.units.fusion.color, self.config.units.fusion.priority)
    elseif sName == self.L["unit.lubricant_nozzle"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.lubricant.enable,false,false,false,nil,self.config.units.lubricant.color, self.config.units.lubricant.priority)
    elseif sName == self.L["unit.spark_plug"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.spark.enable,false,false,false,nil,self.config.units.spark.color, self.config.units.spark.priority)
    elseif sName == self.L["unit.cooling_turbine"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.cooling.enable,false,false,false,nil,self.config.units.cooling.color, self.config.units.cooling.priority)
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
        if self.config.icons.orb.enable == true then
            self.core:DrawIcon("Orb_"..tostring(nId), tData.tUnit, self.config.icons.orb.sprite, self.config.icons.orb.size, nil, self.config.icons.orb.color, nDuration)
        end

        if self.config.alerts.orb.enable == true then
            self.core:ShowAlert("Orb_"..tostring(nId), self.L["debuff.atomic_attraction"].." on "..sName, self.config.alerts.orb.duration, self.config.alerts.orb.color)
        end

        if self.config.sounds.orb.enable == true then
            if tData.tUnit:IsThePlayer() then
                self.core:PlaySound(self.config.sounds.orb.file)
            end
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if nSpellId == DEBUFF__ELECTROSHOCK_VULNERABILITY then
        self.core:RemoveIcon("Electroshock_"..tostring(nId))
    elseif nSpellId == DEBUFF_ATOMIC_ATTRACTION then
        self.core:RemoveIcon("Orb_"..tostring(nId))
    end
end

function Mod:OnCastEnd(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss_gun"] and sCastName == self.L["cast.electroshock"] then
        if self.config.timers.electroshock.enable == true then
            self.core:AddTimer(sCastName, sCastName, 20, self.config.timers.electroshock.color, Mod.OnElectroshock, tCast.tUnit)
        end
    elseif sName == self.L["unit.boss_sword"] and sCastName == self.L["cast.liquidate"] then
        if self.config.timers.liquidate.enable == true then
            self.core:AddTimer(sCastName, sCastName, 20, self.config.timers.liquidate.color, Mod.OnLiquidate, tCast.tUnit)
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
