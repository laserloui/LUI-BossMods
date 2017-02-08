require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Kuralak"

local Locales = {
    ["enUS"] = {
        ["unit.boss"] = "Kuralak the Defiler",
		-- Datachron messages.
		["datachron.return"] = "Kuralak the Defiler returns to the Archive Core",
		["datachron.outbreak"] = "Kuralak the Defiler causes a violent outbreak of corruption",
		["datachron.corruption"] = "The corruption begins to fester",
		["datachron.anesthetized"] = "has been anesthetized",
		-- Cast.
		["cast.vanish"] = "Vanish into Darkness",
		["cast.corruption"] = "Chromosome Corruption",
		-- Bar and messages.
		["message.next_outbreak"] = "Next outbreak",
		["message.next_eggs"] = "Next eggs",
		["message.next_tankswitch"] = "Next switch tank",
		["message.next_vanish"] = "Next vanish",
		["message.phase2"] = "PHASE 2 !",
		["message.vanish"] = "VANISH",
		["message.outbreak"] = "OUTBREAK",
		["message.eggs"] = "EGGS",
		["message.switchtank"] = "SWITCH TANK",
		-- Labels
		["label.vanish"] = "Vanish",
		["label.outbreak"] = "Outbreak",
		["label.eggs"] = "Eggs",
		["label.tankswitch"] = "Tank switch",
		["label.phase2"] = "Phase 2",
    },
    ["deDE"] = {
		-- Unit names.
		["unit.boss"] = "Kuralak die Schänderin",
		-- Datachron messages.
		["datachron.return"] = "Kuralak die Schänderin kehrt zum Archivkern zurück",
		["datachron.outbreak"] = "Kuralak die Schänderin verursacht einen heftigen Ausbruch der Korrumpierung",
		["datachron.corruption"] = "Die Korrumpierung beginnt zu eitern",
		["datachron.anesthetized"] = "wurde narkotisiert",
		-- Cast.
		["cast.vanish"] = "In der Dunkelheit verschwinden",
		["cast.corruption"] = "Chromosomen-Korrumpierung", --from GameLib.GetSpell(DEBUFFID_CHROMOSOME_CORRUPTION):GetName() --not sure, if actually correct
		-- Bar and messages.
		["message.next_outbreak"] = "Nächster Ausbruch",
		["message.next_eggs"] = "Nächste Eier",
		["message.next_tankswitch"] = "Nächster Tankwechsel",
		["message.next_vanish"] = "Nächstes Verschwinden",
		["message.phase2"] = "PHASE 2 !",
		["message.vanish"] = "VERSCHWINDEN",
		["message.outbreak"] = "AUSBRUCH",
		["message.eggs"] = "EIER",
		["message.switchtank"] = "AGGRO ZIEHEN !!!",
		-- Labels
		["label.vanish"] = "Verschwinden",
		["label.outbreak"] = "Ausbruch",
		["label.eggs"] = "Eier",
		["label.tankswitch"] = "Tankwechsel",
		["label.phase2"] = "Phase 2",
	},
    ["frFR"] = {
		-- Unit names.
		["unit.boss"] = "Kuralak la Profanatrice",
		-- Datachron messages.
		["datachron.return"] = "Kuralak la Profanatrice retourne au Noyau d'accès aux archives pour reprendre des forces",
		["datachron.outbreak"] = "Kuralak la Profanatrice provoque une violente éruption de Corruption",
		["datachron.corruption"] = "La Corruption commence à se répandre",
		["datachron.anesthetized"] = "est sous anesthésie",
		-- Cast.
		["cast.vanish"] = "Disparaître dans les ténèbres",
		["cast.corruption"] = "Corruption chromosomique",
		-- Bar and messages.
		["message.next_outbreak"] = "Prochaine invasion",
		["message.next_eggs"] = "Prochain oeufs",
		["message.next_tankswitch"] = "Prochain changement de tank",
		["message.next_vanish"] = "Prochaine disparition",
		["message.phase2"] = "PHASE 2 !",
		["message.vanish"] = "DISPARITION",
		["message.outbreak"] = "INVASION",
		["message.eggs"] = "OEUFS",
		["message.switchtank"] = "CHANGEMENT TANK",
		-- Labels
		["label.vanish"] = "Disparition",
		["label.outbreak"] = "Invasion",
		["label.eggs"] = "Oeufs",
		["label.tankswitch"] = "Changement tank",
		["label.phase2"] = "Phase 2",
	},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Genetic Archives"
    self.displayName = "Kuralak"
    self.tTrigger = {
        sType = "ANY",
        tNames = {"unit.boss"},
        tZones = {
            [1] = {
                continentId = 67,
                parentZoneId = 147,
                mapId = 148,
            },
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
		units = {
            boss = {
                enable = true,
                label = "unit.boss",
                position = 1,
            },
		},
		alerts = {
            vanish = {
                enable = true,
                position = 1,
                label = "label.vanish",
            },
			phase2 = {
                enable = true,
                position = 2,
                label = "label.phase2",
			},
			outbreak = {
                enable = true,
                position = 3,
                label = "label.outbreak",
            },
			eggs = {
                enable = true,
                position = 4,
                label = "label.eggs",
            },
			tankswitch = {
                enable = true,
                position = 5,
                label = "label.tankswitch",
            },
		},
		sounds = {
            vanish = {
                enable = true,
                position = 1,
                file = "alert",
                label = "label.vanish",
			},
			phase2 = {
                enable = true,
                position = 2,
                file = "long",
                label = "label.phase2",
			},
			outbreak = {
                enable = true,
                position = 3,
                file = "run-away",
                label = "label.outbreak",
			},
			eggs = {
                enable = true,
                position = 4,
                file = "alert",
                label = "label.eggs",
			},
			tankswitch = {
                enable = true,
                position = 5,
                file = "alarm",
                label = "label.tankswitch",
			},
		},
		timers = {
            vanish = {
                enable = true,
                position = 1,
                color = "ad1dfbfb",
                label = "label.vanish",
            },
			outbreak = {
                enable = true,
                position = 2,
                color = "afff4500",
                label = "label.outbreak",
            },
			eggs = {
                enable = true,
                position = 3,
                color = "afb0ff2f",
                label = "label.eggs",
            },
			tankswitch = {
                enable = true,
                position = 3,
                color = "afff00ff",
                label = "label.tankswitch",
            },
		},
		icons = {
			eggs = {
				enable = true,
				sprite = "target",
				size = 60,
				color = "ffb0ff2f",
				label = "label.eggs",
			},
		},
    }
    return o
end

-- Chromosome corruption is when a player is twice powerfull, and have a dot.
local DEBUFFID_CHROMOSOME_CORRUPTION = 56652
local bIsPhase2


function Mod:Init(parent)
    Apollo.LinkAddon(parent, self)

    self.core = parent
    self.L = parent:GetLocale(Encounter,Locales)
end

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run then return end
	if sName == self.L["unit.boss"] and bInCombat then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss)
	end
end

function Mod:OnDatachron(sMessage, sSender, sHandler)
    if sMessage:find(self.L["datachron.return"]) then
		self.core:ShowAlert("alert.vanish", self.L["message.vanish"], self.config.alerts.vanish)
        self.core:PlaySound(self.config.sounds.vanish)
        self.core:AddTimer("timer.vanish", self.L["message.next_vanish"], 47, self.config.timers.vanish)
    elseif sMessage:find(self.L["datachron.outbreak"]) then
		self.core:ShowAlert("alert.outbreak", self.L["message.outbreak"], self.config.alerts.outbreak)
        self.core:PlaySound(self.config.sounds.outbreak)
        self.core:AddTimer("timer.outbreak", self.L["message.next_outbreak"], 45, self.config.timers.outbreak)
    elseif sMessage:find(self.L["datachron.corruption"]) then
		self.core:ShowAlert("alert.eggs", self.L["message.eggs"], self.config.alerts.eggs)
        self.core:PlaySound(self.config.sounds.eggs)
        self.core:AddTimer("timer.eggs", self.L["message.next_eggs"], 66, self.config.timers.eggs)
    elseif sMessage:find(self.L["datachron.anesthetized"]) then
        if GroupLib.GetGroupMember(1).bTank then --assuming we are in a group!
			self.core:ShowAlert("alert.tankswitch", self.L["message.tankswitch"], self.config.alerts.tankswitch)
			self.core:PlaySound(self.config.sounds.tankswitch)
        end
        self.core:AddTimer("timer.tankswitch", self.L["message.next_tankswitch"], 88, self.config.timers.tankswitch)
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
	if sName == self.L["unit.boss"] and sCastName == self.L["cast.corruption"] and not bIsPhase2 then
		bIsPhase2 = true
		self.core:RemoveTimer("timer.vanish")
		self.core:ShowAlert("alert.phase2", self.L["message.phase2"], self.config.alerts.phase2)
		self.core:PlaySound(self.config.sounds.phase2)
		self.core:AddTimer("timer.outbreak", self.L["message.next_outbreak"], 15, self.config.timers.outbreak)
		self.core:AddTimer("timer.eggs", self.L["message.next_eggs"], 73, self.config.timers.eggs)
		self.core:AddTimer("timer.tankswitch", self.L["message.next_tankswitch"], 37, self.config.timers.tankswitch)
	end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFFID_CHROMOSOME_CORRUPTION == nSpellId then
        self.core:DrawIcon(nId, tData.tUnit, self.config.icons.eggs)
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if nSpellId == DEBUFFID_CHROMOSOME_CORRUPTION then
        self.core:RemoveIcon(nId)
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
    bIsPhase2 = false
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
