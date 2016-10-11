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
        -- Casts
        ["cast.electroshock"] = "Electroshock",
        ["cast.liquidate"] = "Liquidate",
        ["cast.rocket_jump"] = "Rocket Jump",
        -- Alerts
        ["alert.liquidate"] = "Liquidate!",
        ["alert.electroshock"] = "Electroshock!",
        ["alert.atomic_attraction"] = "Atomic Attraction on ",
        ["alert.vulnerability"] = " swap to SWORD!",
        ["alert.vulnerability_player"] = "SWAP TO SWORD!",
        ["alert.sword_jump"] = "Sword is leaving ",
        ["alert.gun_jump"] = "Gun is leaving ",
        ["alert.gun_return"] = "RETURN TO GUN!",
        ["alert.pillar"] = " at 20%!",
        -- datachron
        ["datachron.electroshock"] = "(.*) suffers from Electroshock",
        -- labels
        ["label.pillar"] = "20% Health Warning",
        ["label.pillar_health"] = "Pillar Health",
        ["label.circle_telegraph"] = "Circle Telegraphs",
        ["label.sword_jump"] = "Sword Rocket Jump",
        ["label.gun_jump"] = "Gun Rocket Jump",
        ["label.gun_return"] = "Return to Gun Reminder",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

local DEBUFF_ELECTROSHOCK_VULNERABILITY = 83798
local DEBUFF_ATOMIC_ATTRACTION = 84053
local BUFF_INSULATION = 83987
local PLATFORM_BOUNDING_BOXES = {
    ["unit.cooling_turbine"] = { x_min = 249.19, x_max = 374.71, z_min = -893.52, z_max = -768.06 },
    ["unit.spark_plug"] = { x_min = 374.71, x_max = 500.23, z_min = -893.52, z_max = -768.06 },
    ["unit.lubricant_nozzle"] = { x_min = 374.71, x_max = 500.23, z_min = -1018.96, z_max = -893.52 },
    ["unit.fusion_core"] = { x_min = 249.19, x_max = 374.71, z_min = -1018.96, z_max = -893.52 }
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"
    self.displayName = "Engineers"
    self.tTrigger = {
        sType = "ALL",
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
                position = 1,
                label = "unit.boss_gun",
                color = "afafafaf",
            },
            sword = {
                enable = true,
                position = 2,
                label = "unit.boss_sword",
                color = "afafafaf",
            },
            spark = {
                enable = true,
                position = 3,
                label = "unit.spark_plug",
                color = "afb0ff2f",
            },
            fusion = {
                enable = true,
                position = 4,
                label = "unit.fusion_core",
                color = "afb0ff2f",
            },
            cooling = {
                enable = true,
                position = 5,
                label = "unit.cooling_turbine",
                color = "afb0ff2f",
            },
            lubricant = {
                enable = true,
                position = 6,
                label = "unit.lubricant_nozzle",
                color = "afb0ff2f",
            },
        },
        timers = {
            electroshock = {
                enable = true,
                position = 1,
                color = "ade91dfb",
                label = "cast.electroshock",
            },
            liquidate = {
                enable = true,
                position = 2,
                color = "afb0ff2f",
                label = "cast.liquidate",
            },
            atomic_attraction = {
                enable = true,
                position = 3,
                color = "afff4500",
                label = "debuff.atomic_attraction",
            },
            vulnerability = {
                enable = false,
                position = 4,
                color = "aaee94fd",
                label = "debuff.electroshock_vulnerability",
            },
        },
        casts = {
            sword_jump = {
                enable = false,
                color = "ffff00ff",
                label = "label.sword_jump",
            },
            gun_jump = {
                enable = false,
                color = "ffff00ff",
                label = "label.gun_jump",
            },
        },
        alerts = {
            electroshock = {
                enable = false,
                position = 1,
                label = "cast.electroshock",
            },
            liquidate = {
                enable = false,
                position = 2,
                label = "cast.liquidate",
            },
            atomic_attraction = {
                enable = true,
                position = 3,
                color = "ffff4500",
                label = "debuff.atomic_attraction",
            },
            pillar = {
                enable = true,
                position = 4,
                label = "label.pillar",
            },
            sword_jump = {
                enable = true,
                position = 5,
                label = "label.sword_jump",
            },
            gun_jump = {
                enable = true,
                position = 6,
                label = "label.gun_jump",
            },
            vulnerability = {
                enable = true,
                position = 7,
                label = "debuff.electroshock_vulnerability",
            },
            gun_return = {
                enable = true,
                position = 8,
                label = "label.gun_return",
            },
        },
        sounds = {
            electroshock = {
                enable = false,
                position = 1,
                label = "cast.electroshock",
            },
            liquidate = {
                enable = false,
                position = 2,
                label = "cast.liquidate",
            },
            atomic_attraction = {
                enable = true,
                position = 3,
                file = "run-away",
                label = "debuff.atomic_attraction",
            },
            pillar = {
                enable = true,
                position = 4,
                file = "alert",
                label = "label.pillar",
            },
            sword_jump = {
                enable = true,
                position = 5,
                file = "info",
                label = "label.sword_jump",
            },
            gun_jump = {
                enable = true,
                position = 6,
                file = "info",
                label = "label.gun_jump",
            },
        },
        icons = {
            vulnerability = {
                enable = true,
                sprite = "target2",
                size = 60,
                color = "ff40e0d0",
                label = "debuff.electroshock_vulnerability",
            },
            atomic_attraction = {
                enable = true,
                sprite = "bomb",
                size = 60,
                color = "ffff4500",
                label = "debuff.atomic_attraction",
            },
            pillar = {
                enable = true,
                size = 300,
                sprite = false,
                label = "label.pillar_health",
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
    local strPlayer = sMessage:match(self.L["datachron.electroshock"])

    if strPlayer then
        self.core:AddTimer("ElectroshockTimer_"..strPlayer, strPlayer, 60, self.config.timers.vulnerability)
    end
end

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run then
        return
    end

    if sName == self.L["unit.boss_gun"] and bInCombat then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.gun)
        self.core:DrawLine(nId, tUnit, self.config.lines.gun, 30)
    elseif sName == self.L["unit.boss_sword"] and bInCombat then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.sword)
        self.core:DrawLine("CleaveA", tUnit, self.config.lines.sword, 15, -50, 0, Vector3.New(2,0,-1.5))
        self.core:DrawLine("CleaveB", tUnit, self.config.lines.sword, 15, 50, 0, Vector3.New(-2,0,-1.5))
    elseif sName == self.L["unit.fusion_core"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.fusion)
        self.core:DrawIcon(nId, tUnit, self.config.icons.pillar, -275)
    elseif sName == self.L["unit.lubricant_nozzle"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.lubricant)
        self.core:DrawIcon(nId, tUnit, self.config.icons.pillar, -275)
    elseif sName == self.L["unit.spark_plug"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.spark)
        self.core:DrawIcon(nId, tUnit, self.config.icons.pillar, -275)
    elseif sName == self.L["unit.cooling_turbine"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.cooling)
        self.core:DrawIcon(nId, tUnit, self.config.icons.pillar, -275)
    elseif sName == self.L["unit.circle_telegraph"] then
        self.core:DrawPolygon(nId, tUnit, self.config.lines.circle_telegraph, 6.3, 0, 20)
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.circle_telegraph"] then
        self.core:RemovePolygon(nId)
    end
end

function Mod:OnHealthChanged(nId, nPercent, sName, tUnit)
    if sName == self.L["unit.fusion_core"] or sName == self.L["unit.lubricant_nozzle"] or sName == self.L["unit.spark_plug"] or sName == self.L["unit.cooling_turbine"] then
        if self.config.icons.pillar.enable then
            local tIcon = self.core:GetDraw(nId)

            if tIcon and tIcon.wnd then
                tIcon.wnd:SetText(string.format("%.0f%%", nPercent))
                tIcon.wnd:SetFont("Subtitle")

                if nPercent > 20 then
                    tIcon.wnd:SetTextColor("ffadff2f")
                else
                    if nPercent > 15 then
                        tIcon.wnd:SetTextColor("ffff8c00")
                    else
                        tIcon.wnd:SetTextColor("ffff0000")
                    end
                end
            end
        end

        if self.config.alerts.pillar.enable or self.config.sounds.pillar.enable then
            if nPercent < 20 then
                local sCurrentPlatform = self:GetPlatform(self.unitPlayer)

                if sCurrentPlatform and sName == self.L[sCurrentPlatform] then
                    if not self.warned or self.warned ~= sName then
                        self.core:PlaySound(self.config.sounds.pillar)
                        self.core:ShowAlert("Pillar", sName..self.L["alert.pillar"], self.config.alerts.pillar)
                        self.warned = sName
                    end
                end
            end
        end
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if nSpellId == DEBUFF_ELECTROSHOCK_VULNERABILITY then
        self.core:DrawIcon("Electroshock_"..tostring(nId), tData.tUnit, self.config.icons.vulnerability, nil, nDuration)

        if tData.tUnit:IsThePlayer() then
            self.core:ShowAlert("Vulnerability_"..tostring(nId), self.L["alert.vulnerability_player"], self.config.alerts.vulnerability)
        else
            self.core:ShowAlert("Vulnerability_"..tostring(nId), sUnitName..self.L["alert.vulnerability"], self.config.alerts.vulnerability)
        end
    elseif nSpellId == DEBUFF_ATOMIC_ATTRACTION then
        self.core:DrawIcon("atomic_attraction_"..tostring(nId), tData.tUnit, self.config.icons.atomic_attraction, nil, nDuration)
        self.core:ShowAlert("atomic_attraction_"..tostring(nId), self.L["alert.atomic_attraction"]..sUnitName, self.config.alerts.atomic_attraction)
        self.core:AddTimer("atomic_attraction", self.L["debuff.atomic_attraction"], 23, self.config.timers.atomic_attraction)

        if tData.tUnit:IsThePlayer() then
            self.core:PlaySound(self.config.sounds.atomic_attraction)
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if nSpellId == DEBUFF_ELECTROSHOCK_VULNERABILITY then
        self.core:RemoveIcon("Electroshock_"..tostring(nId))

        if tData.tUnit:IsThePlayer() then
            self.core:ShowAlert("GunReturn_"..tostring(nId), self.L["alert.gun_return"], self.config.alerts.gun_return)
        end
    elseif nSpellId == DEBUFF_ATOMIC_ATTRACTION then
        self.core:RemoveIcon("atomic_attraction_"..tostring(nId))
    elseif nSpellId == BUFF_INSULATION and sUnitName == self.L["unit.fusion_core"] then
        self.core:AddTimer("atomic_attraction", self.L["debuff.atomic_attraction"], 23, self.config.timers.atomic_attraction)
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss_sword"] and sCastName == self.L["cast.rocket_jump"] then
        self.core:ShowCast(tCast, sCastName, self.config.casts.sword_jump)
        self.core:PlaySound(self.config.sounds.sword_jump)

        if self.config.alerts.sword_jump.enable then
            local sCurrentPlatform = self:GetPlatform(tCast.tUnit)
            if sCurrentPlatform then
                self.core:ShowAlert("sword_jump", self.L["alert.sword_jump"] .. self.L[sCurrentPlatform], self.config.alerts.sword_jump)
            end
        end
    elseif sName == self.L["unit.boss_gun"] and sCastName == self.L["cast.rocket_jump"] then
        self.core:ShowCast(tCast, sCastName, self.config.casts.gun_jump)
        self.core:PlaySound(self.config.sounds.gun_jump)

        if self.config.alerts.gun_jump.enable then
            local sCurrentPlatform = self:GetPlatform(tCast.tUnit)
            if sCurrentPlatform then
                self.core:ShowAlert("gun_jump", self.L["alert.gun_jump"] .. self.L[sCurrentPlatform], self.config.alerts.gun_jump)
            end
        end
    elseif sName == self.L["unit.boss_gun"] and sCastName == self.L["cast.electroshock"] then
        local sPlatformPlayer = self:GetPlatform(self.unitPlayer)
        local sPlatformGun = self:GetPlatform(tCast.tUnit)

        if sPlatformPlayer == sPlatformGun then
            self.core:ShowAlert("electroshock", self.L["alert.electroshock"], self.config.alerts.electroshock)
            self.core:PlaySound(self.config.sounds.electroshock)
        end
    elseif sName == self.L["unit.boss_sword"] and sCastName == self.L["cast.liquidate"] then
        local sPlatformPlayer = self:GetPlatform(self.unitPlayer)
        local sPlatformSword = self:GetPlatform(tCast.tUnit)

        if sPlatformPlayer == sPlatformSword then
            self.core:ShowAlert("liquidate", self.L["alert.liquidate"], self.config.alerts.liquidate)
            self.core:PlaySound(self.config.sounds.liquidate)
        end
    end
end

function Mod:OnCastEnd(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss_gun"] and sCastName == self.L["cast.electroshock"] then
        self.core:AddTimer("cast.electroshock", sCastName, 18.5, self.config.timers.electroshock)
        self.electroshock = Apollo.GetTickCount()
    elseif sName == self.L["unit.boss_sword"] and sCastName == self.L["cast.liquidate"] then
        self.core:AddTimer("cast.liquidate", sCastName, 21.5, self.config.timers.liquidate)
        self.liquidate = Apollo.GetTickCount()
    end
end

function Mod:GetPlatform(tUnit)
    local loc = tUnit:GetPosition()
    if not loc then return nil end
    for k,v in pairs(PLATFORM_BOUNDING_BOXES) do
        if v.x_min <= loc.x and loc.x <= v.x_max and v.z_min <= loc.z and loc.z <= v.z_max then
            return k
        end
    end
    return nil
end

function Mod:IsRunning()
    return self.run
end

function Mod:IsEnabled()
    return self.config.enable
end

function Mod:OnEnable()
    self.run = true
    self.unitPlayer = GameLib.GetPlayerUnit()

    self.core:AddTimer("cast.electroshock", self.L["cast.electroshock"], 11, self.config.timers.electroshock)
    self.core:AddTimer("cast.liquidate", self.L["cast.liquidate"], 12, self.config.timers.liquidate)

    self.liquidate = Apollo.GetTickCount()
    self.electroshock = Apollo.GetTickCount()
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
