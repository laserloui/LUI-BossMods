require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "MnemesisHydroflux"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss_logic"] = "Mnemesis",
        ["unit.boss_water"] = "Hydroflux",
        ["unit.tetris"] = "Alphanumeric Hash",
        ["unit.orb"] = "Hydro Disrupter - DNT",
        -- Casts
        ["cast.circuit_breaker"] = "Circuit Breaker",
        ["cast.imprison"] = "Imprison",
        ["cast.defrag"] = "Defragment",
        -- Alerts
        ["alert.midphase"] = "MIDPHASE!",
        ["alert.defrag"] = "DEFRAGMENT - SPREAD!",
        ["alert.imprison"] = "%s GOT IMPRISONED!",
        ["alert.imprison_player"] = "YOU GOT IMPRISONED! - MOVE!",
        -- Datachron
        ["datachron.enrage"] = "Time to die, sapients!",
        -- Labels
        ["label.orb"] = "Orb",
        ["label.midphase"] = "Midphase",
        ["label.next_midphase"] = "Next midphase",
        ["label.next_defrag"] = "Next defragment",
        ["label.next_imprison"] = "Next imprison",
        ["label.avatus"] = "Avatus incoming",
        ["label.enrage"] = "Enrage",
        ["label.imprison"] = "Imprison",
        ["label.imprison_player"] = "Imprison on player",
    },
    ["deDE"] = {
        -- Units
        ["unit.boss_logic"] = "Mnemesis",
        ["unit.boss_water"] = "Hydroflux",
        ["unit.tetris"] = "Alphanumerische Raute",
        ["unit.orb"] = "Hydro-disrupteur - DNT",
        -- Casts
        ["cast.circuit_breaker"] = "Schaltkreiszerstörer",
        ["cast.imprison"] = "Einsperren",
        ["cast.defrag"] = "Defragmentieren",
        -- Alerts
        ["alert.midphase"] = "MITTE PHASE!",
        ["alert.defrag"] = "DEFRAGMENTIEREN - VERTEILEN!",
        ["alert.imprison"] = "%s WURDE EINGESPERRT!",
        ["alert.imprison_player"] = "DU WURDEST EINGESPERRT - LAUF!",
        -- Datachron
        ["datachron.enrage"] = "Zeit, zu sterben, Vernunftbegabte!",
        -- Labels
        ["label.orb"] = "Orb",
        ["label.midphase"] = "Mitte Phase",
        ["label.next_midphase"] = "Nächste Mitte-Phase",
        ["label.next_defrag"] = "Nächste Defragmentierung",
        ["label.next_imprison"] = "Nächstes Einsperren",
        ["label.avatus"] = "Avatus incoming",
        ["label.enrage"] = "Enrage",
        ["label.imprison"] = "Einsperren",
        ["label.imprison_player"] = "Einsperren auf Spieler",
    },
    ["frFR"] = {
        -- Units
        ["unit.boss_logic"] = "Mnémésis",
        ["unit.boss_water"] = "Hydroflux",
        ["unit.tetris"] = "Alphanumeric Hash",
        ["unit.orb"] = "Hydro-disrupteur - DNT",
        -- Casts
        ["cast.circuit_breaker"] = "Coupe-circuit",
        ["cast.imprison"] = "Emprisonner",
        ["cast.defrag"] = "Défragmentation",
        -- Alerts
        ["alert.midphase"] = "PHASE MILIEU !",
        ["alert.defrag"] = "DÉFRAGMENTATION - SÉPARER-VOUS !",
        ["alert.imprison"] = "%s A OBTENU EMPRISONNER !",
        ["alert.imprison_player"] = "TU AS EMPRISONNER !",
        -- Datachron
        ["datachron.enrage"] = "Maintenant c'est l'heure de mourir, misérables !",
        -- Labels
        ["label.orb"] = "Orbe",
        ["label.midphase"] = "Phase milieu",
        ["label.next_midphase"] = "Prochaine phase milieu",
        ["label.next_defrag"] = "Défragmentation suivante",
        ["label.next_imprison"] = "Prochain emprisonner",
        ["label.avatus"] = "Avatus est arrivé",
        ["label.enrage"] = "Enrager",
        ["label.imprison"] = "Emprisonner",
        ["label.imprison_player"] = "Emprisonner sur le joueur",
    },
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Mnemesis & Hydroflux"
    self.groupName = "Elemental Pairs"
    self.tTrigger = {
        sType = "ALL",
        tNames = {"unit.boss_logic", "unit.boss_water"},
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 118,
            },
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        units = {
            boss_logic = {
                enable = true,
                label = "unit.boss_logic",
            },
            boss_water = {
                enable = true,
                label = "unit.boss_water",
            },
        },
        timers = {
            defrag = {
                enable = true,
                position = 1,
                color = "c800bfff",
                label = "label.next_defrag",
            },
            imprison = {
                enable = true,
                position = 2,
                color = "c87cfc00",
                label = "label.next_imprison",
            },
            midphase = {
                enable = true,
                position = 3,
                label = "label.next_midphase",
            },
            enrage = {
                enable = true,
                position = 4,
                label = "label.enrage",
            },
        },
        alerts = {
            defrag = {
                enable = true,
                position = 1,
                label = "cast.defrag",
            },
            imprison = {
                enable = true,
                position = 2,
                label = "label.imprison",
            },
            midphase = {
                enable = true,
                position = 3,
                label = "label.midphase",
            },
        },
        sounds = {
            defrag = {
                enable = true,
                file = "info",
                label = "cast.defrag",
            },
            imprison = {
                enable = true,
                file = "run-away",
                label = "label.imprison_player",
            },
        },
        auras = {
            imprison = {
                enable = true,
                sprite = "LUIBM_run",
                color = "ffadff2f",
                label = "label.imprison_player",
            },
        },
        icons = {
            imprison = {
                enable = true,
                sprite = "LUIBM_crosshair",
                size = 80,
                color = "ffadff2f",
                label = "label.imprison",
            },
        },
        lines = {
            defrag = {
                enable = true,
                position = 1,
                thickness = 6,
                color = "ffff0000",
                label = "cast.defrag",
            },
            tetris = {
                enable = true,
                position = 2,
                thickness = 8,
                color = "ffadff2f",
                label = "unit.tetris",
            },
            orb = {
                enable = true,
                thickness = 4,
                color = "af00ffff",
                label = "label.orb",
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

    if sName == self.L["unit.boss_logic"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_logic)
    elseif sName == self.L["unit.boss_water"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_water)
    elseif sName == self.L["unit.tetris"] then
        self.core:DrawLine(nId, tUnit, self.config.lines.tetris, 30)
    elseif sName == self.L["unit.orb"] then
        if not self.bMidphase then
            self.core:DrawLineBetween(nId, tUnit, nil, self.config.lines.orb)
        end
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.tetris"] then
        self.core:RemoveLine(nId)
    elseif sName == self.L["unit.orb"] then
        self.core:RemoveLineBetween(nId)
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss_logic"] then
        if sCastName == self.L["cast.defrag"] then
            self.core:PlaySound(self.config.sounds.defrag)
            self.core:ShowAlert("Alert_Defrag", self.L["alert.defrag"], self.config.alerts.defrag)
            self.core:AddTimer("DEFRAG", self.L["label.next_defrag"], 36, self.config.timers.defrag)
            self.core:DrawPolygon("DEFRAG", GameLib.GetPlayerUnit(), self.config.lines.defrag, 13, 0, 4, 10)
        elseif sCastName == self.L["cast.imprison"] then
            self.core:RemoveTimer("IMPRISON")

            local tTarget = tCast.tUnit:GetTarget()
            if tTarget:IsThePlayer() then
                self.core:PlaySound(self.config.sounds.imprison)
                self.core:ShowAura("Aura_Imprison", self.config.auras.imprison, tCast.nDuration, self.L["alert.imprison_player"])
                self.core:ShowAlert("Alert_Imprison", self.L["alert.imprison_player"], self.config.alerts.imprison)
            else
                self.core:ShowAlert("Alert_Imprison", self.L["alert.imprison"]:format(tTarget:GetName()), self.config.alerts.imprison)
            end

            self.core:DrawIcon("Icon_Imprison", tTarget, self.config.icons.imprison, true, nil, tCast.nDuration)
        elseif sCastName == self.L["cast.circuit_breaker"] then
            self.bMidphase = true
            self.core:RemoveTimer("DEFRAG")
            self.core:RemoveTimer("IMPRISON")
            self.core:AddTimer("MIDPHASE", self.L["cast.circuit_breaker"], 25, self.config.timers.midphase)
            self.core:ShowAlert("Alert_Midphase", self.L["alert.midphase"], self.config.alerts.midphase)
        end
    end
end

function Mod:OnCastEnd(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss_logic"] then
        if sCastName == self.L["cast.imprison"] then
            self.core:RemoveIcon("Icon_Imprison")
            self.core:HideAura("Aura_Imprison")
        elseif sCastName == self.L["cast.circuit_breaker"] then
            self.bMidphase = false
            self.core:AddTimer("MIDPHASE", self.L["label.next_midphase"], 85, self.config.timers.midphase)
            self.core:AddTimer("IMPRISON", self.L["label.next_imprison"], 25, self.config.timers.imprison)
        end
    end
end

function Mod:OnDatachron(sMessage, sSender, sHandler)
    if sMessage:match(self.L["datachron.enrage"]) then
        self.core:RemoveTimer("AVATUS")
        self.core:AddTimer("ENRAGE", self.L["label.enrage"], 34, self.config.timers.enrage)
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
    self.bMidphase = false

    self.core:AddTimer("DEFRAG", self.L["label.next_defrag"], 16, self.config.timers.defrag)
    self.core:AddTimer("IMPRISON", self.L["label.next_imprison"], 33, self.config.timers.imprison)
    self.core:AddTimer("MIDPHASE", self.L["label.next_defrag"], 75, self.config.timers.midphase)
    self.core:AddTimer("AVATUS", self.L["label.avatus"], 420, self.config.timers.enrage)
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
