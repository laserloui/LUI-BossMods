require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Starface"

local Locales = {
    ["enUS"] = {
        -- Units
        ["unit.boss"] = "Alpha Cassus",
        ["unit.aldinari"] = "Aldinari",
        ["unit.cassus"] = "Cassus",
        ["unit.vulpes_nix"] = "Vulpes Nix",
        ["unit.rogue_asteroid"] = "Rogue Asteroid",
        ["unit.debris_field"] = "Debris Field",
        ["unit.world_ender"] = "World Ender",
        ["unit.pulsar"] = "Pulsar",
        ["unit.cosmic_debris"] = "Cosmic Debris",
        ["unit.black_hole"] = "Black Hole",
        ["unit.wormhole"] = "Wormhole",
        -- Casts
        ["cast.solar_flare"] = "Solar Flare",
        ["cast.midphase"] = "Catastrophic Solar Event",
        -- Timer
        ["timer.danger_asteroids"] = "Supder duper important Asteroids!",
        -- Alert
        ["alert.world_ender"] = "World Ender spawned!",
        ["alert.pulsar"] = "Pulsar spawned!",
        ["alert.solar_winds"] = "Reset your stacks",
        ["alert.midphase"] = "Midphase soon, reset stacks",
        -- Labels
        ["label.world_ender"] = "World ender spawn points",
        ["label.aldinari_sun"] = "Aldinari to Sun",
        ["label.cassus_sun"] = "Cassus to Sun",
        ["label.vulpes_nix_sun"] = "Vulpes nix to Sun",
        ["label.planet_orbit_aldinari"] = "Planet orbit Aldinari",
        ["label.planet_orbit_cassus"] = "Planet orbit Cassus",
        ["label.planet_orbit_vulpes_nix"] = "Planet orbit Vulpes Nix",
        ["label.world_ender_player"] = "World Ender to player",
        ["label.world_ender_direction"] = "World Ender direction",
        ["label.world_ender_position"] = "World Ender position",
        ["label.wormhole"] = "Wormhole position",
        ["label.rogue_asteroid_player"] = "Rogue Asteroid to player",
        ["label.rogue_asteroid_direction"] = "Rogue Asteroid direction",
        ["label.cardinal"] = "Cardinal directions",
        ["label.solar_winds"] = "Solar Winds warning at 7 stacks",
        ["label.sun_stack_cast"] = "Every other Solar Flare (Tanks/Collectors)",
        ["label.irradiated_armor"] = "Irradiated Armor stack (Tanks/Collectors)",
        ["label.midphase"] = "Midphase warning",
        ["label.solar_winds_timer"] = "Sola Wind debuff timer",
        ["label.world_ender1"] = "World Ender #1",
        ["label.world_ender2"] = "World Ender #2",
        ["label.world_ender3"] = "World Ender #3",
        ["label.world_ender4"] = "World Ender #4",
        ["label.world_ender5"] = "World Ender #5",
        ["label.world_ender6"] = "World Ender #6",
        ["label.asteroids_important"] = "Important Fast Asteroids",
        ["label.asteroids"] = "Asteroids",
        ["label.cosmic_debris_line"] = "Cosmic Debris Line",
        ["label.cosmic_debris_polygon"] = "Cosmic Debris Outline",
    },
    ["deDE"] = {},
    ["frFR"] = {},
}

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.instance = "Redmoon Terror"
    self.displayName = "Starmap"
    self.tTrigger = {
        sType = "ANY",
        tNames = {"unit.boss"},
        tZones = {
            [1] = {
                continentId = 104,
                parentZoneId = 548,
                mapId = 556,
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
                color = "ffff8900",
                position = 1,
            },
            aldinari = {
                enable = true,
                label = "unit.aldinari",
                color = "ff800080",
                position = 2,
            },
            cassus = {
                enable = true,
                label = "unit.cassus",
                color = "ff00bfff",
                position = 3,
            },
            vulpes_nix = {
                enable = true,
                label = "unit.vulpes_nix",
                color = "ffff8c00",
                position = 4,
            },
            world_ender = {
                enable = true,
                label = "unit.world_ender",
                color = "ffff0000",
                position = 5,
            },
            rogue_asteroid = {
                enable = false,
                label = "unit.rogue_asteroid",
                color = "ffff1493",
                position = 6,
            },
            pulsar = {
                enable = true,
                label = "unit.pulsar",
                position = 7,
            },
            black_hole = {
                enable = true,
                label = "unit.black_hole",
                position = 8,
            },
        },
        timers = {
            world_ender = {
                enable = true,
                position = 1,
                color = "ffff0000",
                label = "unit.world_ender",
            },
            rogue_asteroid = {
                enable = true,
                position = 2,
                color = "ffff1493",
                label = "unit.rogue_asteroid",
            },
        },
        alerts = {
            world_ender = {
                enable = true,
                position = 1,
                color = "ffff0000",
                label = "unit.world_ender",
            },
            pulsar = {
                enable = true,
                position = 2,
                color = "ffff0000",
                label = "unit.pulsar",
            },
            solar_winds = {
                enable = true,
                position = 3,
                color = "ffff0000",
                label = "label.solar_winds",
            },
            midphase = {
                enable = true,
                position = 4,
                color = "ffff0000",
                label = "label.midphase",
            },
        },
        sounds = {
            world_ender = {
                enable = true,
                position = 1,
                file = "beware",
                label = "unit.world_ender",
            },
            pulsar = {
                enable = true,
                position = 2,
                file = "alert",
                label = "unit.pulsar",
            },
            solar_winds = {
                enable = true,
                position = 3,
                file = "run-away",
                label = "label.solar_winds",
            },
            irradiated_armor = {
                enable = false,
                position = 4,
                file = "info",
                label = "label.irradiated_armor",
            },
            midphase = {
                enable = true,
                position = 5,
                file = "long",
                label = "label.midphase",
            },
        },
        lines = {
            aldinari_sun = {
                enable = false,
                thickness = 6,
                color = "ff800080",
                label = "label.aldinari_sun",
                position = 1,
            },
            cassus_sun = {
                enable = false,
                thickness = 6,
                color = "ff00bfff",
                label = "label.cassus_sun",
                position = 2,
            },
            vulpes_nix_sun = {
                enable = false,
                thickness = 6,
                color = "ffff8c00",
                label = "label.vulpes_nix_sun",
                position = 3,
            },
            planet_orbit_aldinari = {
                enable = false,
                thickness = 4,
                color = "ff800080",
                label = "label.planet_orbit_aldinari",
                position = 4,
            },
            planet_orbit_cassus = {
                enable = false,
                thickness = 4,
                color = "ff00bfff",
                label = "label.planet_orbit_cassus",
                position = 5,
            },
            planet_orbit_vulpes_nix = {
                enable = false,
                thickness = 4,
                color = "ffff8c00",
                label = "label.planet_orbit_vulpes_nix",
                position = 6,
            },
            world_ender_player = {
                enable = true,
                thickness = 6,
                color = "ffff0000",
                label = "label.world_ender_player",
                position = 7,
            },
            world_ender_direction = {
                enable = true,
                thickness = 4,
                color = "ffffffff",
                label = "label.world_ender_direction",
                position = 8,
            },
            world_ender_position = {
                enable = false,
                thickness = 6,
                color = "ffff4500",
                label = "label.world_ender_position",
                position = 9,
            },
            rogue_asteroid_player = {
                enable = false,
                thickness = 6,
                color = "ffff1493",
                label = "label.rogue_asteroid_player",
                position = 10,
            },
            rogue_asteroid_direction = {
                enable = false,
                thickness = 4,
                color = "ffffffff",
                label = "label.rogue_asteroid_direction",
                position = 11,
            },
            sun_stack_cast = {
                enable = false,
                thickness = 8,
                color = "ffff0000",
                label = "label.sun_stack_cast",
                position = 12,
            },
            debris_field = {
                enable = false,
                thickness = 5,
                color = "ffff0000",
                label = "unit.debris_field",
                position = 13,
            },
            cosmic_debris_line = {
                enable = false,
                thickness = 5,
                color = "ffff8c00",
                label = "label.cosmic_debris_line",
                position = 14,
            },
            cosmic_debris_polygon = {
                enable = true,
                thickness = 5,
                color = "ffff8c00",
                label = "label.cosmic_debris_polygon",
                position = 15,
            },
            wormhole = {
                enable = false,
                thickness = 6,
                color = "ffff8c00",
                label = "label.wormhole",
                position = 16,
            }
        },
        icons = {
            debris_field = {
                enable = true,
                sprite = "LUIBM_monster",
                size = 80,
                color = "ffff0000",
                label = "unit.debris_field",
            },
        },
        texts = {
            world_ender = {
                enable = true,
                color = "ffff4500",
                timer = false,
                label = "label.world_ender",
            },
            cardinal = {
                enable = true,
                color = "ffff4500",
                timer = false,
                label = "label.cardinal",
            },
            asteroid_numbers = {
                enable = true,
                color = "ffff1493",
                timer = false,
                label = "unit.rogue_asteroid",
            },
            solar_winds = {
                enable = true,
                color = "ffffffff",
                timer = true,
                label = "label.solar_winds_timer",
            },
        },
    }
    return o
end

local SOLAR_WINDS = 87536
local IRRADIATED_ARMOR = 84305

local ROOM_CENTER = Vector3.New(-76.71, -95.79, 357.12)

local WORMHOLE_SPAWN = {
    ["W1"] = Vector3.New(-155, -97, 347),
    ["W2"] = Vector3.New(-155, -97, 347),
    ["W3"]=  Vector3.New(-43, -97, 284),
    ["W4"] = Vector3.New(-43, -97, 284),
    ["W5"] = Vector3.New(-19.37, -96, 414.22),
    ["W6"] = Vector3.New(-19.37, -96, 414.22),
}

local ENDER_SPAWN = {
    ["W1"] = {
        ["POSITION"] = Vector3.New(-156.30, -96.21, 349.35),
        ["FACING"] = Vector3.New(0.9945, 0, 0.1045),
    },
    ["W2"] = {
        ["POSITION"] = Vector3.New(-178, -95, 292),
        ["FACING"] = Vector3.New(0.8386, 0, 0.5446),
    },
    ["W3"] = {
        ["POSITION"] = Vector3.New(-42.67, -95.79, 281.21),
        ["FACING"] = Vector3.New(-0.4067, 0, 0.9135),
    },
    ["W4"] = {
        ["POSITION"] = Vector3.New(-160, -95, 338),
        ["FACING"] = Vector3.New(0.9902, 0, 0.1391),
    },
    ["W5"] = {
        ["POSITION"] = Vector3.New(-13.66, -96, 411),
        ["FACING"] = Vector3.New(0.9902, 0, 0.1391),
    },
}

local CARDINAL = {
    ["N"] = Vector3.New(-76.75, -96.21, 309.26),
    ["S"] = Vector3.New(-76.55, -96.21, 405.18),
    ["E"] = Vector3.New(-30.00, -96.22, 357.03),
    ["W"] = Vector3.New(-124.81, -96.21, 356.96),
}

function Mod:Init(parent)
    Apollo.LinkAddon(parent, self)

    self.core = parent
    self.L = parent:GetLocale(Encounter,Locales)
end

function Mod:EnderTimer(eCount)
    if eCount <= 6 then
        self.core:AddTimer("ENDER_SPAWN", self.L["label.world_ender"..eCount], 78, self.config.timers.world_ender, Mod.EnderTimer, eCount + 1)
    end
end

function Mod:AsteroidsTimer(aCount)
    if aCount == 7 or aCount == 13 then
        self.core:AddTimer("ASTEROIDS", self.L["label.asteroids_important"], 26, self.config.timers.rogue_asteroid, Mod.AsteroidsTimer, aCount + 1)
    elseif aCount == 2 or aCount == 5 or aCount == 8 or aCount == 11 or aCount == 14 or aCount == 17 then
        self.core:AddTimer("ASTEROIDS", self.L["label.asteroids"], 52, self.config.timers.rogue_asteroid, Mod.AsteroidsTimer, aCount + 1)
    else
        self.core:AddTimer("ASTEROIDS", self.L["label.asteroids"], 26, self.config.timers.rogue_asteroid, Mod.AsteroidsTimer, aCount + 1)
    end
end


function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
    if sName == self.L["unit.boss"] and bInCombat then
        if not self.tIds[nId] then
            self.core:AddUnit(nId,sName,tUnit,self.config.units.boss)

            self.core:AddTimer("ENDER_SPAWN", self.L["label.world_ender1"], 52, self.config.timers.world_ender, Mod.EnderTimer, 2)
            self.core:AddTimer("ASTEROIDS", self.L["label.asteroids"], 26, self.config.timers.rogue_asteroid, Mod.AsteroidsTimer, 2)

            self.core:DrawText("ENDER_SPAWN1", ENDER_SPAWN["W1"]["POSITION"], self.config.texts.world_ender, "W1")
            self.core:DrawText("ENDER_SPAWN2", ENDER_SPAWN["W2"]["POSITION"], self.config.texts.world_ender, "W2")
            self.core:DrawText("ENDER_SPAWN3", ENDER_SPAWN["W3"]["POSITION"], self.config.texts.world_ender, "W3")
            self.core:DrawText("ENDER_SPAWN4", ENDER_SPAWN["W4"]["POSITION"], self.config.texts.world_ender, "W4")
            self.core:DrawText("ENDER_SPAWN5", ENDER_SPAWN["W5"]["POSITION"], self.config.texts.world_ender, "W5")

            self.core:DrawLine("ENDER_SPAWN1_LINE", ENDER_SPAWN["W1"]["POSITION"], self.config.lines.world_ender_position, 45, 0, 0, nil, ENDER_SPAWN["W1"]["FACING"])
            self.core:DrawLine("ENDER_SPAWN2_LINE", ENDER_SPAWN["W2"]["POSITION"], self.config.lines.world_ender_position, 45, 0, 0, nil, ENDER_SPAWN["W2"]["FACING"])
            self.core:DrawLine("ENDER_SPAWN3_LINE", ENDER_SPAWN["W3"]["POSITION"], self.config.lines.world_ender_position, 45, 0, 0, nil, ENDER_SPAWN["W3"]["FACING"])
            self.core:DrawLine("ENDER_SPAWN4_LINE", ENDER_SPAWN["W4"]["POSITION"], self.config.lines.world_ender_position, 45, 0, 0, nil, ENDER_SPAWN["W4"]["FACING"])
            self.core:DrawLine("ENDER_SPAWN5_LINE", ENDER_SPAWN["W5"]["POSITION"], self.config.lines.world_ender_position, 45, 0, 0, nil, ENDER_SPAWN["W5"]["FACING"])

            self.core:DrawLineBetween("WORMHOLE_LINE", WORMHOLE_SPAWN["W1"], nil, self.config.lines.wormhole)

            self.core:DrawText("CARDINAL_N", CARDINAL["N"], self.config.texts.cardinal, "N")
            self.core:DrawText("CARDINAL_S", CARDINAL["S"], self.config.texts.cardinal, "S")
            self.core:DrawText("CARDINAL_E", CARDINAL["E"], self.config.texts.cardinal, "E")
            self.core:DrawText("CARDINAL_W", CARDINAL["W"], self.config.texts.cardinal, "W")

            self.core:DrawPolygon("P1_I", tUnit, self.config.lines.planet_orbit_aldinari, 16, 0, 40)
            self.core:DrawPolygon("P1_O", tUnit, self.config.lines.planet_orbit_aldinari, 24, 0, 40)

            self.core:DrawPolygon("P2_I", tUnit, self.config.lines.planet_orbit_cassus, 35, 0, 50)
            self.core:DrawPolygon("P2_O", tUnit, self.config.lines.planet_orbit_cassus, 45, 0, 50)

            self.core:DrawPolygon("P3_I", tUnit, self.config.lines.planet_orbit_vulpes_nix, 53, 0, 60)
            self.core:DrawPolygon("P3_O", tUnit, self.config.lines.planet_orbit_vulpes_nix, 66, 0, 60)

            self.tIds[nId] = true
        end

    elseif sName == self.L["unit.aldinari"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.aldinari)
        self.core:DrawLineBetween("ALDINARI_SUN", nId, ROOM_CENTER, self.config.lines.aldinari_sun)
        self.aldinariId = nId

    elseif sName == self.L["unit.cassus"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.cassus)
        self.core:DrawLineBetween("CASSUS_SUN", nId, ROOM_CENTER, self.config.lines.cassus_sun)

    elseif sName == self.L["unit.vulpes_nix"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.vulpes_nix)
        self.core:DrawLineBetween("VULPES_NIX_SUN", nId, ROOM_CENTER, self.config.lines.vulpes_nix_sun)

    elseif sName == self.L["unit.rogue_asteroid"] then
        if not self.tIds[nId] then
            self.nTotalAsteroidCount = self.nTotalAsteroidCount + 1
            self.core:AddUnit(nId,sName,tUnit,self.config.units.rogue_asteroid)
            self.core:DrawLineBetween(("ROGUE_ASTEROID_%d"):format(nId), nId, nil, self.config.lines.rogue_asteroid_player)
            self.core:DrawLine(nId, tUnit, self.config.lines.rogue_asteroid_direction, 20)
            self.core:DrawText(("ROUGE_ASTEROID_%d"):format(nId), nId, self.config.texts.asteroid_numbers, self.nTotalAsteroidCount, false, 0)

            self.tIds[nId] = true
        end

    elseif sName == self.L["unit.world_ender"] then
        if not self.tIds[nId] then
            self.core:RemoveLine("ENDER_SPAWN"..self.nEnderCount.."_LINE")

            self.core:AddUnit(nId,sName,tUnit,self.config.units.world_ender)
            self.core:PlaySound(self.config.sounds.world_ender)
            self.core:ShowAlert("Alert_Worldender", self.L["alert.world_ender"], self.config.alerts.world_ender)
            self.core:DrawLineBetween("WORLD_ENDER", nId, nil, self.config.lines.world_ender_player)
            self.core:DrawLine("WORLD_ENDER_DIR", nId, self.config.lines.world_ender_direction, 10)

            self.nEnderCount = self.nEnderCount + 1
            self.tIds[nId] = true
        end

    elseif sName == self.L["unit.wormhole"] then
        if not self.tIds[nId] then
            self.nWormholeCount = self.nWormholeCount + 1

            if self.nWormholeCount <= 6 then
                self.core:DrawLineBetween("WORMHOLE_LINE", WORMHOLE_SPAWN["W"..tostring(self.nWormholeCount)], nil, self.config.lines.wormhole)
            else
                self.core:RemoveLineBetween("WORMHOLE_LINE")
            end

            self.tIds[nId] = true
        end
    elseif sName == self.L["unit.pulsar"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.pulsar)
        self.core:PlaySound(self.config.sounds.pulsar)
        self.core:ShowAlert("Alert_Pulsar", self.L["alert.pulsar"], self.config.alerts.pulsar)

    elseif sName == self.L["unit.debris_field"] then
        self.core:DrawIcon(("DEBRIS_FIELD_%d"):format(nId), nId, self.config.icons.debris_field, true, nil)
        self.core:DrawLineBetween(("DEBRIS_FIELD_LINE_%d"):format(nId), nId, nil, self.config.lines.debris_field)

    elseif sName == self.L["unit.cosmic_debris"] then
        self.core:DrawLineBetween(("COSMIC_DEBRIS_LINE_%d"):format(nId), nId, nil, self.config.lines.cosmic_debris_line)
        self.core:DrawPolygon(("COSMIC_DEBRIS_POLYGON_%d"):format(nId), nId, self.config.lines.cosmic_debris_polygon, 3, 0, 6)

    elseif sName == self.L["unit.black_hole"] then
        self.core:AddUnit(nId,sName,tUnit,self.config.units.black_hole)

    end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
    if sName == self.L["unit.rogue_asteroid"] then
        self.core:RemoveLineBetween(("ROGUE_ASTEROID_%d"):format(nId))
    elseif sName == self.L["unit.cosmic_debris"] then
        self.core:RemoveLineBetween(("COSMIC_DEBRIS_LINE_%d"):format(nId))
        self.core:RemovePolygon(("COSMIC_DEBRIS_POLYGON_%d"):format(nId))
    elseif sName == self.L["unit.world_ender"] then
        self.core:RemoveLineBetween("WORLD_ENDER")
        self.core:RemoveLine("WORLD_ENDER_DIR")
        self.core:RemoveText("ENDER_SPAWN"..tostring(self.nEnderCount - 1))
    end
end


function Mod:OnCastStart(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss"] then
        if sCastName == self.L["cast.solar_flare"] then
            self.nSunCast = self.nSunCast + 1
            if self.nSunCast == 1 then
                self.core:DrawLine("BOSS_STACK_CAST", nId, self.config.lines.sun_stack_cast, 25)
            end
        elseif sCastName == self.L["cast.midphase"] then
            self.nSunCast = 0
        end
    end
end

function Mod:OnCastEnd(nId, sCastName, tCast, sName)
    if sName == self.L["unit.boss"] then
        if sCastName == self.L["cast.solar_flare"] then
            if self.nSunCast == 1 then
                self.core:RemoveLineBetween("BOSS_STACK_CAST")
            elseif self.nSunCast == 2 then
                self.nSunCast = 0
            end
        end
    end
end


function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if nSpellId == IRRADIATED_ARMOR then
        self.core:PlaySound(self.config.sounds.irradiated_armor)
    elseif nSpellId == SOLAR_WINDS and tData.tUnit:IsThePlayer() then
        self.core:DrawText(nId, self.aldinariId, self.config.texts.solar_winds, "", false, 0, 4)
    end
end

function Mod:OnBuffUpdated(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
    if nSpellId == SOLAR_WINDS and tData.tUnit:IsThePlayer() then
        self.core:DrawText(nId, self.aldinariId, self.config.texts.solar_winds, "", false, 0, 4)

        if nStack >= 7 and self.aSolarWindWarned == false then
            self.core:PlaySound(self.config.sounds.solar_winds)
            self.core:ShowAlert("SOLAR_WINDS_ALRT", self.L["alert.solar_winds"], self.config.alerts.solar_winds)
            self.aSolarWindWarned = true
        end
    elseif nSpellId == IRRADIATED_ARMOR and nStack >= 2 then
        self.core:PlaySound(self.config.sounds.irradiated_armor)
    end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
    if nSpellId == SOLAR_WINDS and tData.tUnit:IsThePlayer() then
        self.aSolarWindWarned = false
        self.core:RemoveText(nId)
    end
end


function Mod:OnHealthChanged(nId, nHealthPercent, sName, tUnit)
    if sName == self.L["unit.boss"] then
        if nHealthPercent <= 77 and self.nMidphaseWarnings == 0 then
            self.core:ShowAlert("Alert_Midphase", self.L["alert.midphase"], self.config.alerts.midphase)
            self.core:PlaySound(self.config.sounds.midphase)
            self.nMidphaseWarnings = 1
        elseif nHealthPercent <= 47 and self.nMidphaseWarnings == 1 then
            self.core:ShowAlert("Alert_Midphase", self.L["alert.midphase"], self.config.alerts.midphase)
            self.core:PlaySound(self.config.sounds.midphase)
            self.nMidphaseWarnings = 2
        elseif nHealthPercent <= 15 and self.nMidphaseWarnings == 2 then
            self.core:ShowAlert("Alert_Midphase", self.L["alert.midphase"], self.config.alerts.midphase)
            self.core:PlaySound(self.config.sounds.midphase)
            self.nMidphaseWarnings = 3
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
    self.aSolarWindWarned = false
    self.nSunCast = 0
    self.nMidphaseWarnings = 0
    self.nTotalAsteroidCount = 0
    self.nEnderCount = 1
    self.nWormholeCount = 0
    self.tIds = {}
end

function Mod:OnDisable()
    self.run = false
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
