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
        ["unit.regor_the_rancid"] = "Regor the Rancid", -- Miniboss during Midphase
        ["unit.braugh_the_bloodied"] = "Braugh the Bloodied", -- Miniboss during Midphase
        ["unit.sawblade"] = "Sawblade",
        ["unit.circle_telegraph"] = "Hostile Invisible Unit for Fields (1.2 hit radius)",
        -- Casts
        ["cast.necrotic_lash"] = "Necrotic Lash", -- Cast by Noxious Nabber (grab and disorient), interruptable
        ["cast.deathwail"] = "Deathwail", -- Miniboss knockdown, interruptable
        ["cast.gravedigger"] = "Gravedigger", -- Miniboss cast
        -- Alerts
        ["alert.oozing_bile"] = "Oozing Bile - Stop Damage!",
        ["alert.interrupt"] = "Interrupt!",
        -- Debuffs
        ["debuff.oozing_bile"] = "Oozing Bile",
        -- Labels
        ["label.lines_room"] = "Room Dividers",
        ["label.circle_telegraph"] = "Circle Telegraphs",
    },
    ["deDE"] = {
		-- Units
        ["unit.boss"] = "Swabbie Ski'Li",
        ["unit.noxious_nabber"] = "Noxious Nabber",
        ["unit.regor_the_rancid"] = "Regor the Rancid", -- Miniboss during Midphase
        ["unit.braugh_the_bloodied"] = "Braugh the Bloodied", -- Miniboss during Midphase --NOT SEEN YET, confim please
        ["unit.sawblade"] = "Sägeblatt",
        ["unit.circle_telegraph"] = "Feindselige unsichtbare Einheit für Felder (Trefferradius 1.2)",
        -- Casts
        ["cast.necrotic_lash"] = "Nekrotisches Peitschen", -- Cast by Noxious Nabber (grab and disorient), interruptable
        ["cast.deathwail"] = "Totenklage", -- Miniboss knockdown, interruptable
        ["cast.gravedigger"] = "Gravedigger", -- Miniboss cast
        -- Alerts
        ["alert.oozing_bile"] = "Oozing Bile - Stop Damage!",
        ["alert.interrupt"] = "Interrupt!",
        -- Debuffs
        ["debuff.oozing_bile"] = "Oozing Bile",
        -- Labels
        ["label.lines_room"] = "Raum Einteilungen",
        ["label.circle_telegraph"] = "Kreis Telegraphen",
	},
    ["frFR"] = {},
}

local DEBUFF__OOZING_BILE = 84321
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
        tZones = {
            [1] = {
                continentId = 104,
                parentZoneId = 548,
                mapId = 549,
            },
        },
        tNames = {
            ["enUS"] = {"Swabbie Ski'Li"},
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
                priority = 1,
            },
            noxious_nabber = {
                enable = true,
                label = "unit.noxious_nabber",
                priority = 2,
            },
            regor_the_rancid = {
                enable = true,
                label = "unit.regor_the_rancid",
            },
            braugh_the_bloodied = {
                enable = true,
                label = "unit.braugh_the_bloodied",
            },
        },
        casts = {
            necrotic_lash = {
                enable = true,
                color = "ff9932cc",
                label = "cast.necrotic_lash",
            },
            deathwail = {
                enable = true,
                color = "ff9932cc",
                label = "cast.deathwail",
            },
            gravedigger = {
                enable = true,
                color = "ff9932cc",
                label = "cast.gravedigger",
            },
        },
        auras = {
            oozing_bile = {
                enable = true,
                sprite = "stop2",
                color = "ffff0000",
                label = "debuff.oozing_bile",
            },
        },
        alerts = {
            oozing_bile = {
                enable = true,
                label = "debuff.oozing_bile",
            },
            necrotic_lash = {
                enable = true,
                label = "cast.necrotic_lash",
            },
            deathwail = {
                enable = true,
                label = "cast.deathwail",
                duration = 3,
            },
            gravedigger = {
                enable = true,
                label = "cast.gravedigger",
                duration = 3,
            },
        },
        sounds = {
            oozing_bile = {
                enable = true,
                file = "alert",
                label = "debuff.oozing_bile",
            },
            necrotic_lash = {
                enable = true,
                file = "alert",
                label = "cast.necrotic_lash",
            },
            deathwail = {
                enable = true,
                file = "alert",
                label = "cast.deathwail",
            },
            gravedigger = {
                enable = true,
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

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if not self.run == true then
        return
    end

    if sName == self.L["unit.boss"] and bInCombat == true then
        if self.config.units.boss.enable == true then
            self.core:AddUnit(nId,sName,tUnit,self.config.units.boss.enable,false,false,false,nil,self.config.units.boss.color, self.config.units.boss.priority)
        end

        if self.config.lines.room.enable == true then
            self.core:DrawLineBetween("ExitLine", EXITLINE_A, EXITLINE_B, self.config.lines.room.thickness, self.config.lines.room.color)
            self.core:DrawLineBetween("CenterLine", CENTERLINE_A, CENTERLINE_B, self.config.lines.room.thickness, self.config.lines.room.color)
            self.core:DrawLineBetween("EntranceLine", ENTRANCELINE_A, ENTRANCELINE_B, self.config.lines.room.thickness, self.config.lines.room.color)
        end
    elseif sName == self.L["unit.noxious_nabber"] then
        if self.config.units.noxious_nabber.enable == true then
            self.core:AddUnit(nId,sName,tUnit,self.config.units.noxious_nabber.enable,true,false,false,nil,self.config.units.noxious_nabber.color, self.config.units.noxious_nabber.priority)
        end
    elseif sName == self.L["unit.regor_the_rancid"] then
        if self.config.units.regor_the_rancid.enable == true then
            self.core:AddUnit(nId,sName,tUnit,self.config.units.regor_the_rancid.enable,true,false,false,nil,self.config.units.regor_the_rancid.color, self.config.units.regor_the_rancid.priority)
        end
    elseif sName == self.L["unit.braugh_the_bloodied"] then
        if self.config.units.braugh_the_bloodied.enable == true then
            self.core:AddUnit(nId,sName,tUnit,self.config.units.braugh_the_bloodied.enable,true,false,false,nil,self.config.units.braugh_the_bloodied.color, self.config.units.braugh_the_bloodied.priority)
        end
    elseif sName == self.L["unit.sawblade"] then
        if self.config.lines.sawblade.enable == true then
            self.core:DrawLine(nId, tUnit, self.config.lines.sawblade.color, self.config.lines.sawblade.thickness, 60, 0, 0)
        end
    elseif sName == self.L["unit.circle_telegraph"] then
        if self.config.lines.circle_telegraph.enable == true then
            self.core:DrawPolygon(nId, tUnit, 6.7, 0, self.config.lines.circle_telegraph.thickness, self.config.lines.circle_telegraph.color, 20)
        end
    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.sawblade"] then
        self.core:RemoveLine(nId)
    elseif sName == self.L["unit.circle_telegraph"] then
        self.core:RemovePolygon(nId)
    end
end

function Mod:OnBuffUpdated(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if DEBUFF__OOZING_BILE == nSpellId then
        if tData.tUnit:IsThePlayer() then
            if nStack >= 8 then
                if self.config.auras.oozing_bile.enable == true then
                    self.core:ShowAura("OOZE",self.config.auras.oozing_bile.sprite,self.config.auras.oozing_bile.color,nDuration)
                end

                if not self.warned then
                    if self.config.sounds.oozing_bile.enable == true then
                        self.core:PlaySound(self.config.sounds.oozing_bile.file)
                    end

                    if self.config.alerts.oozing_bile.enable == true then
                        self.core:ShowAlert("OOZE", self.L["alert.oozing_bile"], self.config.alerts.oozing_bile.duration, self.config.alerts.oozing_bile.color)
                    end

                    self.warned = true
                end
            end

            if nStack >= 10 then
                ChatSystemLib.Command("/p I hit " .. nStack .. " stacks because I'm a complete moron.")
            end
        end
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if DEBUFF__OOZING_BILE == nSpellId then
        if tData.tUnit:IsThePlayer() then
            if self.config.auras.oozing_bile.enable == true then
                self.core:HideAura("OOZE")
            end

            self.warned = nil
        end
    end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sName == self.L["unit.noxious_nabber"] then
        if sCastName == self.L["cast.necrotic_lash"] then
            if self.core:GetDistance(tCast.tUnit) < 30 then
                if self.config.alerts.necrotic_lash.enable == true then
                    self.core:ShowAlert("necrotic_lash_"..tostring(nId), self.L["alert.interrupt"], self.config.alerts.necrotic_lash.duration, self.config.alerts.necrotic_lash.color)
                end

                if self.config.sounds.necrotic_lash.enable == true then
                    self.core:PlaySound(self.config.sounds.necrotic_lash.file)
                end

                if self.config.casts.necrotic_lash.enable == true then
                    self.core:ShowCast(tCast,sCastName,self.config.casts.necrotic_lash.color)
                end
            end
        end
    elseif sName == self.L["unit.regor_the_rancid"] or sName == self.L["unit.braugh_the_bloodied"] then
        if sCastName == self.L["cast.deathwail"]  then
            if self.config.alerts.deathwail.enable == true then
                self.core:ShowAlert("deathwail", self.L["alert.interrupt"], self.config.alerts.deathwail.duration, self.config.alerts.deathwail.color)
            end

            if self.config.sounds.deathwail.enable == true then
                self.core:PlaySound(self.config.sounds.deathwail.file)
            end

            if self.config.casts.deathwail.enable == true then
                self.core:ShowCast(tCast,sCastName,self.config.casts.deathwail.color)
            end
        elseif sCastName == self.L["cast.gravedigger"] then
            if self.config.alerts.gravedigger.enable == true then
                self.core:ShowAlert("gravedigger", self.L["alert.interrupt"], self.config.alerts.gravedigger.duration, self.config.alerts.gravedigger.color)
            end

            if self.config.sounds.gravedigger.enable == true then
                self.core:PlaySound(self.config.sounds.gravedigger.file)
            end

            if self.config.casts.gravedigger.enable == true then
                self.core:ShowCast(tCast,sCastName,self.config.casts.gravedigger.color)
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
    self.warned = nil
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
