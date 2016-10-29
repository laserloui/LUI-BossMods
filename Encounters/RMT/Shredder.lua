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
        ["unit.regor_the_rancid"] = "Regor the Rancid",
        ["unit.braugh_the_bloodied"] = "Braugh the Bloodied",
        ["unit.sawblade"] = "Sawblade",
        ["unit.circle_telegraph"] = "Hostile Invisible Unit for Fields (1.2 hit radius)",
        -- Casts
        ["cast.necrotic_lash"] = "Necrotic Lash",
        ["cast.deathwail"] = "Deathwail",
        ["cast.gravedigger"] = "Gravedigger",
        -- Alerts
        ["alert.oozing_bile"] = "Oozing Bile - Stop Damage!",
        ["alert.oozing_bile_short"] = "Stop Damage!",
        ["alert.interrupt"] = "Interrupt!",
        -- Debuffs
        ["debuff.oozing_bile"] = "Oozing Bile",
        -- Labels
        ["label.lines_room"] = "Room Dividers",
        ["label.circle_telegraph"] = "Circle Telegraphs",
        -- Texts
        ["text.stackmoron"] = "/p I hit %d stacks because I'm a complete moron.",
    },
    ["deDE"] = {
        ["unit.boss"] = "Swabbie Ski'Li",
        ["unit.noxious_nabber"] = "Noxious Nabber",
        ["unit.regor_the_rancid"] = "Regor the Rancid",
        ["unit.braugh_the_bloodied"] = "Braugh der Blähbauch",
        ["unit.sawblade"] = "Sägeblatt",
        ["unit.circle_telegraph"] = "Feindselige unsichtbare Einheit für Felder (Trefferradius 1.2)",
        -- Casts
        ["cast.necrotic_lash"] = "Nekrotisches Peitschen",
        ["cast.deathwail"] = "Totenklage",
        ["cast.gravedigger"] = "Gravedigger",
        -- Alerts
        ["alert.oozing_bile"] = "Triefende Galle - Stop Damage!",
        ["alert.oozing_bile_short"] = "Stop Damage!",
        ["alert.interrupt"] = "Unterbrechen!",
        -- Debuffs
        ["debuff.oozing_bile"] = "Triefende Galle",
        -- Labels
        ["label.lines_room"] = "Raum Einteilungen",
        ["label.circle_telegraph"] = "Kreis Telegraphen",
        -- Texts
        ["text.stackmoron"] = "/gr Ich Vollidiot habe %d Stacks erreicht!",
    },
    ["frFR"] = {
        -- Units
        ["unit.boss"] = "Swabbie Ski'Li",
        ["unit.noxious_nabber"] = "Harpond Nocif",
        ["unit.regor_the_rancid"] = "Regor le Rancie",
        ["unit.braugh_the_bloodied"] = "Braugh le Sanglant",
        ["unit.sawblade"] = "Scie",
        ["unit.circle_telegraph"] = "Unité de Champs Hostile Invisible (rayon d'action : 1,2)",
        -- Casts
        ["cast.necrotic_lash"] = "Coup de Fouet Nécrotique",
        ["cast.deathwail"] = "Hulement Mortel",
        ["cast.gravedigger"] = "Fossoyer",
        -- Alerts
        ["alert.oozing_bile"] = "Bile Suintante - Stop DPS !",
        ["alert.oozing_bile_short"] = "Stop DPS !",
        ["alert.interrupt"] = "Interromps !",
        -- Debuffs
        ["debuff.oozing_bile"] = "Bile Suintante",
        -- Labels
        ["label.lines_room"] = "Ligne d'ancres",
        ["label.circle_telegraph"] = "Télégraphes Circulaire",
        -- Texts
        ["text.stackmoron"] = "/éq J'ai atteint %d stacks parce que je suis un crétin fini.",
    },
}

local DEBUFF_OOZING_BILE = 84321
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
        tNames = {"unit.boss"},
        tZones = {
            [1] = {
                continentId = 104,
                parentZoneId = 548,
                mapId = 549,
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
            noxious_nabber = {
                enable = true,
                label = "unit.noxious_nabber",
                position = 2,
            },
            regor_the_rancid = {
                enable = true,
                label = "unit.regor_the_rancid",
                position = 3,
            },
            braugh_the_bloodied = {
                enable = true,
                label = "unit.braugh_the_bloodied",
                position = 4,
            },
        },
        casts = {
            necrotic_lash = {
                enable = true,
                position = 1,
                label = "cast.necrotic_lash",
            },
            deathwail = {
                enable = true,
                position = 2,
                label = "cast.deathwail",
            },
            gravedigger = {
                enable = true,
                position = 3,
                label = "cast.gravedigger",
            },
        },
        auras = {
            oozing_bile = {
                enable = true,
                sprite = "LUIBM_stop",
                color = "ffff0000",
                label = "debuff.oozing_bile",
            },
        },
        alerts = {
            necrotic_lash = {
                enable = true,
                position = 1,
                label = "cast.necrotic_lash",
            },
            oozing_bile = {
                enable = true,
                position = 2,
                label = "debuff.oozing_bile",
            },
            deathwail = {
                enable = true,
                position = 3,
                label = "cast.deathwail",
            },
            gravedigger = {
                enable = true,
                position = 4,
                label = "cast.gravedigger",
            },
        },
        sounds = {
            necrotic_lash = {
                enable = true,
                position = 1,
                file = "alert",
                label = "cast.necrotic_lash",
            },
            oozing_bile = {
                enable = true,
                position = 2,
                file = "alert",
                label = "debuff.oozing_bile",
            },
            deathwail = {
                enable = true,
                position = 3,
                file = "alert",
                label = "cast.deathwail",
            },
            gravedigger = {
                enable = true,
                position = 4,
                file = "alert",
                label = "cast.gravedigger",
            },
        },
        lines = {
            room = {
                enable = true,
                thickness = 5,
                color = "649932cc",
                label = "label.lines_room",
            },
            sawblade = {
                enable = true,
                thickness = 15,
                color = "ff9932cc",
                label = "unit.sawblade",
            },
            circle_telegraph = {
                enable = true,
                thickness = 7,
                color = "ffff0000",
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

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run then
        return
    end

    if sName == self.L["unit.boss"] and bInCombat then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.boss)
        self.core:DrawLineBetween("ExitLine", EXITLINE_A, EXITLINE_B, self.config.lines.room)
        self.core:DrawLineBetween("CenterLine", CENTERLINE_A, CENTERLINE_B, self.config.lines.room)
        self.core:DrawLineBetween("EntranceLine", ENTRANCELINE_A, ENTRANCELINE_B, self.config.lines.room)
    elseif sName == self.L["unit.noxious_nabber"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.noxious_nabber)
    elseif sName == self.L["unit.regor_the_rancid"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.regor_the_rancid)
    elseif sName == self.L["unit.braugh_the_bloodied"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.braugh_the_bloodied)
    elseif sName == self.L["unit.sawblade"] then
        self.core:DrawLine(nId, tUnit, self.config.lines.sawblade, 60)
    elseif sName == self.L["unit.circle_telegraph"] then
        self.core:DrawPolygon(nId, tUnit, self.config.lines.circle_telegraph, 6.7, 0, 20)
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.sawblade"] then
        self.core:RemoveLine(nId)
    elseif sName == self.L["unit.circle_telegraph"] then
        self.core:RemovePolygon(nId)
    end
end

function Mod:OnHealthChanged(nId, nPercent, sName, tUnit)
    if sName == self.L["unit.noxious_nabber"] or sName == self.L["unit.regor_the_rancid"] or sName == self.L["unit.braugh_the_bloodied"] then
        if tUnit:IsDead() then
            self.core:RemoveUnit(nId)
        end
    end
end

function Mod:OnBuffUpdated(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF_OOZING_BILE == nSpellId then
        if tData.tUnit:IsThePlayer() then
            if nStack >= 8 then
                self.core:ShowAura("OOZE", self.config.auras.oozing_bile, nDuration, self.L["alert.oozing_bile_short"])

                if not self.warned then
                    self.core:PlaySound(self.config.sounds.oozing_bile)
                    self.core:ShowAlert("OOZE", self.L["alert.oozing_bile"], self.config.alerts.oozing_bile)
                    self.warned = true
                end
            end

            if nStack >= 10 then
                ChatSystemLib.Command(self.L["text.stackmoron"]:format(nStack))
            end
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if DEBUFF_OOZING_BILE == nSpellId then
        if tData.tUnit:IsThePlayer() then
            self.core:HideAura("OOZE")
            self.warned = nil
        end
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sName == self.L["unit.noxious_nabber"] then
        if sCastName == self.L["cast.necrotic_lash"] then
            if self.core:GetDistance(tCast.tUnit) < 30 then
                self.core:ShowAlert("necrotic_lash_"..tostring(nId), self.L["alert.interrupt"], self.config.alerts.necrotic_lash)
                self.core:PlaySound(self.config.sounds.necrotic_lash)
                self.core:ShowCast(tCast,sCastName,self.config.casts.necrotic_lash)
            end
        end
    elseif sName == self.L["unit.regor_the_rancid"] or sName == self.L["unit.braugh_the_bloodied"] then
        if sCastName == self.L["cast.deathwail"]  then
            self.core:ShowAlert("deathwail", self.L["alert.interrupt"], self.config.alerts.deathwail)
            self.core:PlaySound(self.config.sounds.deathwail)
            self.core:ShowCast(tCast,sCastName,self.config.casts.deathwail)
        elseif sCastName == self.L["cast.gravedigger"] then
            self.core:ShowAlert("gravedigger", self.L["alert.interrupt"], self.config.alerts.gravedigger)
            self.core:PlaySound(self.config.sounds.gravedigger)
            self.core:ShowCast(tCast,sCastName,self.config.casts.gravedigger)
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
    self.warned = nil
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
