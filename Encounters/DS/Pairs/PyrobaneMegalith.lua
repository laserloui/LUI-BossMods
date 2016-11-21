require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "PyrobaneMegalith"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss_fire"] = "Pyrobane",
        ["unit.boss_earth"] = "Megalith",
        ["unit.flame_wave"] = "Flame Wave",
        ["unit.obsidian"] = "Obsidian Outcropping",
        ["unit.lava_floor"] = "e395- [Datascape] Fire Elemental - Lava Floor (invis unit)",
        -- Alerts
        ["alert.superquake"] = "JUMP, JUMP, JUMP!!!",
        -- Datachron
        ["datachron.superquake"] = "The ground shudders beneath Megalith!",
        ["datachron.lava_floor"] = "The lava begins to rise through the floor!",
        ["datachron.enrage"] = "Time to die, sapients!",
        -- Labels
        ["label.superquake"] = "Superquake",
        ["label.lava_floor"] = "Lava Floor Phase",
        ["label.next_lava_floor"] = "Next Lava Floor",
        ["label.next_obsidian"] = "Next Obsidian",
        ["label.avatus"] = "Avatus incoming",
        ["label.enrage"] = "Enrage",
    },
    ["deDE"] = {
        -- Units
        ["unit.boss_fire"] = "Pyroman",
        ["unit.boss_earth"] = "Megalith",
        ["unit.flame_wave"] = "Flammenwelle",
        ["unit.obsidian"] = "Obsidian Outcropping",
        ["unit.lava_floor"] = "e395- [Datascape] Fire Elemental - Lava Floor (invis unit)",
        -- Alerts
        ["alert.superquake"] = "SPRING, SPRING, SPRING!!!",
        -- Datachron
        ["datachron.superquake"] = "Der Boden unter Megalith bebt!",
        ["datachron.lava_floor"] = "Die Lava beginnt durch den Boden nach oben aufzusteigen!",
        ["datachron.enrage"] = "Zeit, zu sterben, Vernunftbegabte!",
        -- Labels
        ["label.superquake"] = "Superbeben",
        ["label.lava_floor"] = "Lava Boden Phase",
        ["label.next_lava_floor"] = "Nächster Lava Boden",
        ["label.next_obsidian"] = "Nächster Obsidian",
        ["label.avatus"] = "Avatus incoming",
        ["label.enrage"] = "Enrage",
    },
    ["frFR"] = {
        -- Units
        ["unit.boss_fire"] = "Pyromagnus",
        ["unit.boss_earth"] = "Mégalithe",
        ["unit.flame_wave"] = "Vague de feu",
        ["unit.obsidian"] = "Affleurement d'obsidienne",
        ["unit.lava_floor"] = "e395- [Datascape] Fire Elemental - Lava Floor (invis unit)",
        -- Alerts
        ["alert.superquake"] = "SAUTE, SAUTE, SAUTE !!!",
        -- Datachron
        ["datachron.superquake"] = "Le sol tremble sous les pieds de Mégalithe !",
        ["datachron.lava_floor"] = "La lave apparaît par les fissures du sol !",
        ["datachron.enrage"] = "Maintenant c'est l'heure de mourir, misérables !",
        -- Labels
        ["label.superquake"] = "Super séisme",
        ["label.lava_floor"] = "Phase de lave",
        ["label.next_lava_floor"] = "Phase de lave suivante",
        ["label.next_obsidian"] = "Rocher suivante",
        ["label.avatus"] = "Avatus est arrivé",
        ["label.enrage"] = "Enrager",
    },
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Datascape"
    self.displayName = "Pyrobane & Megalith"
    self.groupName = "Elemental Pairs"
    self.tTrigger = {
        sType = "ALL",
        tNames = {"unit.boss_fire", "unit.boss_earth"},
        tZones = {
            [1] = {
                continentId = 52,
                parentZoneId = 98,
                mapId = 117,
            },
        },
    }
    self.run = false
    self.runtime = {}
    self.config = {
        enable = true,
        units = {
            boss_fire = {
                enable = true,
                position = 1,
                label = "unit.boss_fire",
            },
            boss_earth = {
                enable = true,
                position = 2,
                label = "unit.boss_earth",
            },
        },
        timers = {
            obsidian = {
                enable = true,
                position = 1,
                color = "c8ffa500",
                label = "label.next_obsidian",
            },
            lava_floor = {
                enable = true,
                position = 2,
                label = "label.next_lava_floor",
            },
            enrage = {
                enable = true,
                position = 3,
                label = "label.enrage",
            },
        },
        alerts = {
            superquake = {
                enable = true,
                label = "label.superquake",
            },
        },
        casts = {
            superquake = {
                enable = true,
                label = "label.superquake",
            },
        },
        sounds = {
            superquake = {
                enable = true,
                file = "alert",
                label = "label.superquake",
            },
        },
        lines = {
            flame_wave = {
                enable = true,
                thickness = 10,
                color = "ffff0000",
                label = "unit.flame_wave",
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

    if sName == self.L["unit.boss_fire"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_fire)
    elseif sName == self.L["unit.boss_earth"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss_earth)
    elseif sName == self.L["unit.flame_wave"] then
        self.core:DrawLine(nId, tUnit, self.config.lines.flame_wave, 25)
    elseif sName == self.L["unit.obsidian"] then
        self.nObsidianCount = self.nObsidianCount + 1
        if self.nObsidianCount <= 5 then
            self.core:AddTimer("NEXT_OBSIDIAN", self.L["label.next_obsidian"], 11, self.config.timers.obsidian)
        end
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.flame_wave"] then
        self.core:RemoveLine(nId)
    elseif sName == self.L["unit.lava_floor"] then
        self.nLavaFloorCount = self.nLavaFloorCount + 1
        if self.nLavaFloorCount <= 2 then
            self.core:AddTimer("NEXT_LAVA_FLOOR", self.L["label.next_lava_floor"], 89, self.config.timers.lava_floor)
        end
    elseif sName == self.L["unit.boss_fire"] then
        self.core:RemoveTimer("NEXT_LAVA_FLOOR")
    elseif sName == self.L["unit.boss_earth"] then
        self.core:RemoveTimer("NEXT_OBSIDIAN")
    end
end

function Mod:OnDatachron(sMessage, sSender, sHandler)
    if sMessage:match(self.L["datachron.lava_floor"]) then
        self.core:AddTimer("LAVA_FLOOR", self.L["label.lava_floor"], 28, self.config.timers.lava_floor)
    elseif sMessage:match(self.L["datachron.enrage"]) then
        self.core:RemoveTimer("AVATUS")
        self.core:AddTimer("ENRAGE", self.L["label.enrage"], 34, self.config.timers.enrage)
    elseif sMessage:match(self.L["datachron.superquake"]) then
        self.core:ShowCast({
            sName = "Superquake",
            nDuration = 2,
            nElapsed = 0,
            nTick = Apollo.GetTickCount()
        }, self.L["label.superquake"], self.config.casts.superquake)
        self.core:ShowAlert(self.L["label.superquake"], self.L["alert.superquake"], self.config.alerts.superquake)
        self.core:PlaySound(self.config.sounds.superquake)
    end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if tData.tUnit:IsInYourGroup() or tData.tUnit:IsThePlayer() then
        Print(sUnitName.." got debuff "..sName.." - Duration: "..tostring(nDuration).." Seconds - SpellID: "..tostring(nSpellId))
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
    self.nObsidianCount = 0
    self.nLavaFloorCount = 0

    self.core:AddTimer("NEXT_LAVA_FLOOR", self.L["label.next_lava_floor"], 94, self.config.timers.lava_floor)
    self.core:AddTimer("NEXT_OBSIDIAN", self.L["label.next_obsidian"], 11, self.config.timers.obsidian)
    self.core:AddTimer("AVATUS", self.L["label.avatus"], 425, self.config.timers.enrage)
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
