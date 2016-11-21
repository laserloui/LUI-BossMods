require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "VolatilityLattice"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss"] = "Avatus",
        ["unit.devourer"] = "Data Devourer",
        -- Datachron
        ["datachron.laser"] = "Avatus sets his focus on (.*)!",
        ["datachron.delete_all"] = "Avatus prepares to delete all data!",
        ["datachron.secure_sector"] = "The Secure Sector Enhancement Ports have been activated!",
        ["datachron.locomotion"] = "The Vertical Locomotion Enhancement Ports have been activated!",
        -- Alerts
        ["alert.laser"] = "LASER ON %s!",
        ["alert.laser_player"] = "LASER ON YOU!",
        -- Messages
        ["message.laser"] = "Next Laser",
        ["message.pillar"] = "Next Pillars",
        ["message.devourer"] = "Next Devourers",
        -- Labels
        ["label.laser"] = "Laser",
        ["label.pillar"] = "Pillar",
    },
    ["deDE"] = {},
    ["frFR"] = {
        -- Units
        ["unit.boss"] = "Avatus",
        ["unit.devourer"] = "Dévoreur de données",
        -- Datachron
        ["datachron.laser"] = "Avatus porte son attention sur (.*) !",
        ["datachron.delete_all"] = "Avatus se prépare à effacer toutes les données !",
        ["datachron.secure_sector"] = "Les ports d'amélioration de secteur sécurisé ont été activés !",
        ["datachron.locomotion"] = "Les ports d'amélioration de locomotion verticale ont été activés !",
        -- Alerts
        ["alert.laser"] = "LASER SUR %s !",
        ["alert.laser_player"] = "LASER SUR TOI !",
        -- Messages
        ["message.laser"] = "Prochain Laser",
        ["message.pillar"] = "Prochain Pilier",
        ["message.devourer"] = "Prochain Dévoreur",
        -- Labels
        ["label.laser"] = "Laser",
        ["label.pillar"] = "Pilier",
    },
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Volatility Lattice"
    self.tTrigger = {
        sType = "ANY",
        tNames = {"unit.boss"},
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 116,
            },
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        timers = {
            devourer = {
                enable = true,
                position = 1,
                color = "c8ffa500",
                label = "unit.devourer",
            },
            pillar = {
                enable = true,
                position = 2,
                label = "label.pillar",
            },
            laser = {
                enable = true,
                position = 3,
                label = "label.laser",
            },
        },
        alerts = {
            laser = {
                enable = true,
                label = "label.laser",
            },
        },
        sounds = {
            laser = {
                enable = true,
                file = "alert",
                label = "label.laser",
            },
        },
        auras = {
            laser = {
                enable = true,
                sprite = "LUIBM_run",
                color = "ffff0000",
                label = "label.laser",
            },
        },
        icons = {
            laser = {
                enable = true,
                sprite = "LUIBM_crosshair",
                size = 80,
                color = "ffff0000",
                label = "label.laser",
            },
        },
        lines = {
            devourer = {
                enable = true,
                priority = 1,
                thickness = 6,
                max = 60,
                color = "ff00ffff",
                label = "unit.devourer",
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

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run == true then
        return
    end

    if sName == self.L["unit.devourer"] then
        self.core:DrawLineBetween(nId, tUnit, nil, self.config.lines.devourer)

        local nTick = Apollo.GetTickCount()
        if (self.nLastDevourer + 13000) < nTick then
            self.nLastDevourer = nTick
            self.core:AddTimer("Timer_Devourer", self.L["message.devourer"], 15, self.config.timers.devourer)
        end
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.devourer"] then
        self.core:RemoveLineBetween(nId)
    end
end

function Mod:OnDatachron(sMessage, sSender, sHandler)
    if sMessage:match(self.L["datachron.delete_all"]) then
        self.core:AddTimer("Timer_Pillar", self.L["message.pillar"], 50, self.config.timers.pillar)
    elseif sMessage:match(self.L["datachron.secure_sector"]) then
        self.core:AddTimer("Timer_Devourer", self.L["message.devourer"], 53, self.config.timers.devourer)
        self.core:AddTimer("Timer_Pillar", self.L["message.pillar"], 58, self.config.timers.pillar)
        self.core:AddTimer("Timer_Laser", self.L["message.laser"], 44, self.config.timers.laser)
    elseif sMessage:match(self.L["datachron.locomotion"]) then
        self.core:AddTimer("Timer_Devourer", self.L["message.devourer"], 68, self.config.timers.devourer)
        self.core:AddTimer("Timer_Pillar", self.L["message.pillar"], 75, self.config.timers.pillar)
        self.core:AddTimer("Timer_Laser", self.L["message.laser"], 58, self.config.timers.laser)
    else
        local strPlayerFocused = sMessage:match(self.L["datachron.laser"])

        if strPlayerFocused then
            local tFocusedUnit = GameLib.GetPlayerUnitByName(strPlayerFocused)

            if tFocusedUnit then
                if tFocusedUnit:IsThePlayer() then
                    self.core:PlaySound(self.config.sounds.laser)
                    self.core:ShowAura("Aura_Laser", self.config.auras.laser, 15, self.L["alert.laser_player"])
                    self.core:ShowAlert("Alert_Laser", self.L["alert.laser_player"], self.config.alerts.laser)
                else
                    self.core:DrawIcon("Icon_Laser", tFocusedUnit, self.config.icons.laser, true, nil, 15)
                    self.core:ShowAlert("Alert_Laser", self.L["alert.laser"]:format(tFocusedUnit:GetName()), self.config.alerts.laser)
                end
            end
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
    self.nLastDevourer = 0
    self.core:AddTimer("Timer_Devourer", self.L["message.devourer"], 10, self.config.timers.devourer)
    self.core:AddTimer("Timer_Pillar", self.L["message.pillar"], 45, self.config.timers.pillar)
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
