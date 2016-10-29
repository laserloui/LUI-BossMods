require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "SystemDaemons"

local Locales = {
    ["enUS"] = {
        -- Bosses
        ["unit.boss_north"] = "Binary System Daemon",
        ["unit.boss_south"] = "Null System Daemon",
        -- Probes
        ["unit.prope_1"] = "Conduction Unit Mk. I",
        ["unit.prope_2"] = "Conduction Unit Mk. II",
        ["unit.prope_3"] = "Conduction Unit Mk. III",
        -- Adds
        ["unit.brute_force_algorithm"] = "Brute Force Algorithm",
        ["unit.encryption_program"] = "Encryption Program",
        ["unit.radiation_dispersion_unit"] = "Radiation Dispersion Unit",
        ["unit.defragmentation_unit"] = "Defragmentation Unit",
        ["unit.extermination_sequence"] = "Extermination Sequence",
        ["unit.data_compiler"] = "Data Compiler",
        ["unit.viral_diffusion_inhibitor"] = "Viral Diffusion Inhibitor",
        -- Casts
        ["cast.disconnect"] = "Disconnect",
        ["cast.power_surge"] = "Power Surge",
        -- Alerts
        ["alert.disconnect_north"] = "Disconnect North!",
        ["alert.disconnect_south"] = "Disconnect South!",
        ["alert.purge_player"] = "Purge on you!",
        ["alert.interrupt"] = "Interrupt!",
        -- Datachron
        ["datachron.disconnect"] = "INVALID SIGNAL. DISCONNECTING",
        ["datachron.enhancement"] = "COMMENCING ENHANCEMENT SEQUENCE",
        -- Messages
        ["message.next_wave_mobs"] = "Next wave: Mobs",
        ["message.next_wave_boss"] = "Next wave: Miniboss",
        ["message.next_disconnect"] = "Next disconnect",
        ["message.next_probe"] = "Next probe #%u",
        -- Labels
        ["label.disconnect_north"] = "Disconnect North",
        ["label.disconnect_south"] = "Disconnect South",
        ["label.purge"] = "Purge",
        ["label.disconnect"] = "Disconnect",
        ["label.waves"] = "Add Waves",
        ["label.probes"] = "Probes",
    },
    ["deDE"] = {
        -- Bosses
        ["unit.boss_north"] = "Binärsystem-Dämon",
        ["unit.boss_south"] = "Nullsystem-Dämon",
        -- Probes
        ["unit.prope_1"] = "Leistungseinheit V1",
        ["unit.prope_2"] = "Leistungseinheit V2",
        ["unit.prope_3"] = "Leistungseinheit V3",
        -- Adds
        ["unit.brute_force_algorithm"] = "Brachialgewalt-Algorithmus",
        ["unit.encryption_program"] = "Verschlüsselungsprogramm",
        ["unit.radiation_dispersion_unit"] = "Strahlungsverteilungseinheit", --copied from Raidcore
        ["unit.defragmentation_unit"] = "Defragmentierungseinheit", --copied from Raidcore
        ["unit.extermination_sequence"] = "Vernichtungssequenz",
        ["unit.data_compiler"] = "Datenkompilierer",
        ["unit.viral_diffusion_inhibitor"] = "Virushemmstoff", --copied from Raidcore
        -- Casts
        ["cast.disconnect"] = "Trennung",
        ["cast.power_surge"] = "Energieschweller",
        -- Alerts
        ["alert.disconnect_north"] = "Disconnect Norden!",
        ["alert.disconnect_south"] = "Disconnect Süden!",
        ["alert.purge_player"] = "Purge auf dir!",
        ["alert.interrupt"] = "Interrupt!",
        -- Datachron
        ["datachron.disconnect"] = "UNGÜLTIGES SIGNAL. VERBINDUNG ZU", --%s WIRD ABGEBROCHEN.
        ["datachron.enhancement"] = "BEGINNE VERBESSERUNGSSEQUENZ",
        -- Messages
        ["message.next_wave_mobs"] = "Nächste Welle: Mobs",
        ["message.next_wave_boss"] = "Nächste Welle: Miniboss",
        ["message.next_disconnect"] = "Nächstes Disconnect",
        ["message.next_probe"] = "Nächste Sonde #%u",
        -- Labels
        ["label.disconnect_north"] = "Disconnect Norden",
        ["label.disconnect_south"] = "Disconnect Süden",
        ["label.purge"] = "Purge",
        ["label.disconnect"] = "Disconnect",
        ["label.waves"] = "Add Wellen",
        ["label.probes"] = "Sonden",
    },
    ["frFR"] = {
        -- Bosses
        ["unit.boss_north"] = "Daemon 2.0",
        ["unit.boss_south"] = "Daemon 1.0",
        -- Probes
        ["unit.prope_1"] = "Unité de conductivité v1",
        ["unit.prope_2"] = "Unité de conductivité v2",
        ["unit.prope_3"] = "Unité de conductivité v3",
        -- Adds
        ["unit.brute_force_algorithm"] = "Algorithme de force brute",
        ["unit.encryption_program"] = "Programme de cryptage",
        ["unit.radiation_dispersion_unit"] = "Unité de dispersion de radiations",
        ["unit.defragmentation_unit"] = "Unité de défragmentation",
        ["unit.extermination_sequence"] = "Séquence d'extermination",
        ["unit.data_compiler"] = "Compilateur de données",
        ["unit.viral_diffusion_inhibitor"] = "Inhibiteur de diffusion virale",
        -- Casts
        ["cast.disconnect"] = "Déconnexion",
        ["cast.power_surge"] = "Afflux d'énergie",
        -- Alerts
        ["alert.disconnect_north"] = "Déconnexion Nord !",
        ["alert.disconnect_south"] = "Déconnexion Sud !",
        ["alert.purge_player"] = "Purge sur toi !",
        ["alert.interrupt"] = "Interrompre !",
        -- Datachron
        ["datachron.disconnect"] = "SIGNAL INCORRECT. DECONNECTION",
        ["datachron.enhancement"] = "ACTIVATION DE LA SÉQUENCE D'AMÉLIORATION",
        -- Messages
        ["message.next_wave_mobs"] = "Vague suivante : Mobs",
        ["message.next_wave_boss"] = "Vague suivante : Miniboss",
        ["message.next_disconnect"] = "Prochaine déconnexion",
        ["message.next_probe"] = "Prochaine sonde #%u",
        -- Labels
        ["label.disconnect_north"] = "Déconnexion Nord",
        ["label.disconnect_south"] = "Déconnexion Sud",
        ["label.purge"] = "Purge",
        ["label.disconnect"] = "Déconnexion",
        ["label.waves"] = "Vague pop",
        ["label.probes"] = "Sondes",
    },
}

local DEBUFF__PURGE = 79399

local bIsPhaseTwo = false
local nProbeCount = 0
local nWaveCount = 0
local nLastWave = 0

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "System Daemons"
    self.tTrigger = {
        sType = "ALL",
        tNames = {"unit.boss_north", "unit.boss_south"},
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 105,
            },
            [2] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 107,
            },
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        units = {
            north = {
                enable = true,
                label = "unit.boss_north",
            },
            south = {
                enable = true,
                label = "unit.boss_south",
            },
        },
        timers = {
            disconnect = {
                enable = true,
                label = "label.disconnect",
            },
            adds = {
                enable = true,
                label = "label.waves"
            },
            probes = {
                enable = true,
                label = "label.probes"
            },
        },
        casts = {
            disconnect = {
                enable = true,
                label = "cast.disconnect"
            },
            powersurge = {
                enable = true,
                label = "cast.power_surge",
            },
        },
        alerts = {
            disconnect = {
                enable = true,
                label = "cast.disconnect"
            },
            powersurge = {
                enable = true,
                label = "cast.power_surge",
            },
            purge = {
                enable = true,
                label = "label.purge",
            },
        },
        sounds = {
            disconnect = {
                enable = true,
                file = "info",
                label = "cast.disconnect"
            },
            powersurge = {
                enable = true,
                file = "alert",
                label = "cast.power_surge",
            },
            purge = {
                enable = false,
                file = "beware",
                label = "label.purge",
            },
        },
        lines = {
            purge = {
                enable = true,
                color = "ffff0000",
                thickness = 7,
                label = "label.purge",
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
    if not self.run then
        return
    end

    if sName == self.L["unit.boss_north"] and bInCombat then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.north,"N")
        self.core:AddTimer("DISCONNECT", self.L["message.next_disconnect"], 41, self.config.timers.disconnect)
        self.core:AddTimer("ADDS", self.L["message.next_wave_mobs"], 15, self.config.timers.adds)
    elseif sName == self.L["unit.boss_south"] and bInCombat then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.south,"S")
    elseif sName == self.L["unit.brute_force_algorithm"]
        or sName == self.L["unit.encryption_program"]
        or sName == self.L["unit.radiation_dispersion_unit"]
        or sName == self.L["unit.defragmentation_unit"]
        or sName == self.L["unit.extermination_sequence"]
        or sName == self.L["unit.data_compiler"]
        or sName == self.L["unit.viral_diffusion_inhibitor"] then
            if bIsPhaseTwo then
                return
            end

            local time = GameLib.GetGameTime()

            if (time - nLastWave) > 48 then
                nLastWave = time
                nWaveCount = nWaveCount + 1
                nProbeCount = 0

                if nWaveCount == 1 then
                    self.core:AddTimer("ADDS", self.L["message.next_wave_mobs"], 50, self.config.timers.adds)
                elseif nWaveCount % 2 == 0 then
                    self.core:AddTimer("ADDS", self.L["message.next_wave_boss"], 50, self.config.timers.adds)
                else
                    self.core:AddTimer("ADDS", self.L["message.next_wave_mobs"], 50, self.config.timers.adds)
                end

                self.core:AddTimer("PROBES", self.L["message.next_probe"]:format(1), 10, self.config.timers.probes)
            end
    elseif sName == self.L["unit.prope_1"] then
        if nProbeCount == 0 then nProbeCount = 1 end
        self.core:AddTimer("PROBES", self.L["message.next_probe"]:format(2), 10, self.config.timers.probes)
    elseif sName == self.L["unit.prope_2"] then
        if nProbeCount == 1 then nProbeCount = 2 end
        self.core:AddTimer("PROBES", self.L["message.next_probe"]:format(3), 10, self.config.timers.probes)
    elseif sName == self.L["unit.prope_3"] then
        if nProbeCount == 2 then nProbeCount = 3 end
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sCastName == self.L["cast.disconnect"] then
        if sName == self.L["unit.boss_north"] then
            self.core:ShowCast(tCast, self.L["label.disconnect_north"], self.config.casts.disconnect)
            self.core:ShowAlert("DISCONNECT", self.L["alert.disconnect_north"] ,self.config.alerts.disconnect)
        elseif sName == self.L["unit.boss_south"] then
            self.core:ShowCast(tCast, self.L["label.disconnect_south"], self.config.casts.disconnect)
            self.core:ShowAlert("DISCONNECT", self.L["alert.disconnect_south"], self.config.alerts.disconnect)
        end

        self.core:PlaySound(self.config.sounds.disconnect)
    elseif sCastName == self.L["cast.power_surge"] then
        if self.core:GetDistance(tCast.tUnit) < 25 then
            self.core:ShowCast(tCast, sCastName, self.config.casts.powersurge)
            self.core:PlaySound(self.config.sounds.powersurge)
            self.core:ShowAlert("power_surge_"..tostring(nId), self.L["alert.interrupt"], self.config.alerts.powersurge)
        end
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF__PURGE == nSpellId then
        if tData.tUnit:IsThePlayer() then
            self.core:PlaySound(self.config.sounds.purge)
            self.core:ShowAlert("purge_"..tostring(nId), self.L["alert.purge_player"], self.config.alerts.purge)
        end

        self.core:DrawPolygon("purge_"..tostring(nId), tData.tUnit, self.config.lines.purge, 6, 0, 20, nDuration)
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if DEBUFF__PURGE == nSpellId then
        self.core:RemovePolygon("purge_"..tostring(nId))
    end
end

function Mod:OnDatachron(sMessage, sSender, sHandler)
    if sMessage:find(self.L["datachron.disconnect"]) then
        if bIsPhaseTwo then
            bIsPhaseTwo = false
        end

        self.core:AddTimer("DISCONNECT", self.L["label.disconnect"], 60, self.config.timers.disconnect)
    elseif sMessage:find(self.L["datachron.enhancement"]) then
        bIsPhaseTwo = true

        self.core:AddTimer("DISCONNECT", self.L["label.disconnect"], 85, self.config.timers.disconnect)

        if nProbeCount == 3 then
            if nWaveCount % 2 == 0 then
                self.core:AddTimer("ADDS", self.L["message.next_wave_boss"], 95, self.config.timers.adds)
            else
                self.core:AddTimer("ADDS", self.L["message.next_wave_mobs"], 95, self.config.timers.adds)
            end
        else
            if nWaveCount % 2 == 0 then
                self.core:AddTimer("ADDS", self.L["message.next_wave_boss"], 115 + (2 - nProbeCount) * 10, self.config.timers.adds)
            else
                self.core:AddTimer("ADDS", self.L["message.next_wave_mobs"], 115 + (2 - nProbeCount) * 10, self.config.timers.adds)
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

    bIsPhaseTwo = false
    nProbeCount = 0
    nWaveCount = 0
    nLastWave = 0
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
