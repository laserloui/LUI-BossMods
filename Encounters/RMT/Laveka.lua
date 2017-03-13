require "Window"
require "Apollo"

local Mod = {}
local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Encounter = "Laveka"

local Locales = {
	["enUS"] = {
		-- Units
		["unit.boss"] = "Laveka the Dark-Hearted",
		["unit.titan"] = "Risen Titan",
		["unit.boneclaw"] = "Risen Boneclaw",
		["unit.apparition"] = "Tortured Apparition",
		["unit.lost_soul"] = "Lost Soul",
		["unit.circle_telegraph"] = "Hostile Invisible Unit for Fields (0 hit radius)", -- Same name as Field Probes etc
		["unit.essence_void"] = "Essence Void",
		-- Casts
		["cast.devour_souls"] = "Devour Souls",
		["cast.essence_void"] = "Essence Void",
		["cast.expulsion_of_souls"] = "Expulsion of Souls",
		["cast.essence_surge"] = "Essence Surge",
		["cast.cacophony_of_souls"] = "Cacophony of Souls",
		-- Debuffs
		["debuff.necrotic_breath"] = "Necrotic Breath",
		["debuff.barrier_of_souls"] = "Barrier of Souls",
		["debuff.soul_eater"] = "Soul Eater",
		["debuff.boneclaw_gaze"] = "Boneclaw Gaze",
		["debuff.expulsion_of_souls"] = "Expulsion of Souls",
		["debuff.soulfire"] = "Soulfire",
		["debuff.realm_of_the_dead"] = "Realm of the Dead",
		["debuff.spirit_of_soulfire"] = "Spirit of Soulfire",
		-- Alert
		["alert.adds_debuff"] = "You are targeted by adds!",
		["alert.soulfire_debuff"] = "You have dot!",
		["alert.hex_debuff_self"] = "You are targeted by Hex!",
		["alert.hex_debuff"] = "Hex on ",
		["alert.clone_spawn"] = "You can teleport",
		["alert.midphase_soon"] = "Midphase soon",
		["alert.midphase"] = "Next ",
		-- Timers
		["timer.adds_spawn"] = "Adds",
		["timer.orb_spawn"] = "Orbs",
		["timer.hex_spawn"] = "Hex",
		-- Datachron
		["datachron.ablaze"] = "Laveka sets %s's soul ablaze!",
		-- Chat messages
		["chat.dot"] = "Dot on %s!",
		-- Labels
		["label.circle_telegraph"] = "Circle telegraph",
		["label.lost_soul"] = "Lost soul",
		["label.titan_debuff"] = "Titan debuff mark (For healers)",
		["label.soulfire_debuff"] = "Soulfire debuff (For healers)",
		["label.add_spawn"] = "Adds spawn",
		["label.orb_spawn"] = "Orbs spawn",
		["label.hex_debuff_self"] = "Hex on you",
		["label.hex_debuff"] = "Hex on *player*",
		["label.cardinal_baitmarks"] = "Location marks for baiters",
		["label.ringo_line"] = "Entrance line (For tanks)",
		["label.clone_spawn"] = "Lost soul - Teleport spawn",
		["label.orbs_lines"] = "Orb paths",
		["label.orb_spawn_text"] = "Orb location marks",
		["label.middle_point_mark"] = "Mark for Middle of Room",
		["label.essence_int_1"] = "Essence interrupt 1",
		["label.essence_int_2"] = "Essence interrupt 2",
		["label.essence_int_3"] = "Essence interrupt 3",
		["label.essence_int_4"] = "Essence interrupt 4",
		["label.essence_int_5"] = "Essence interrupt 5",
		["label.essence_int_6"] = "Essence interrupt 6",
		["label.orb_spawn_line_1"] = "Orb spawn line 1",
		["label.orb_spawn_line_2"] = "Orb spawn line 2",
		["label.orb_spawn_line_3"] = "Orb spawn line 3",
		["label.orb_spawn_line_4"] = "Orb spawn line 4",
		["label.orb_spawn_line_5"] = "Orb spawn line 5",
		["label.orb_spawn_line_6"] = "Orb spawn line 6",
},
	["deDE"] = {},
	["frFR"] = {},
}

function Mod:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	self.instance = "Redmoon Terror"
	self.displayName = "Laveka the Dark-Hearted"
	self.tTrigger = {
		sType = "ANY",
		tNames = {"unit.boss"},
		tZones = {
			[1] = {
				continentId = 104,
				parentZoneId = 548,
				mapId = 559,
			},
			[2] = {
				continentId = 104,
				parentZoneId = 0,
				mapId = 548,
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
			titan = {
				enable = true,
				label = "unit.titan",
				position = 2,
			},
			boneclaw = {
				enable = false,
				label = "unit.boneclaw",
				position = 3,
			},
			lost_soul = {
				enable = false,
				label = "unit.lost_soul",
				position = 4,
			},
			essence_void = {
				enable = false,
				label = "unit.essence_void",
				position = 5,
			},
		},
		timers = {
            add_spawn = {
                enable = true,
                position = 1,
                label = "label.add_spawn",
            },
            orb_spawn = {
                enable = true,
                position = 2,
                label = "label.orb_spawn",
        	},
			expulsion_of_souls = {
                enable = true,
                position = 3,
                label = "cast.expulsion_of_souls",
        	},
		},
		alerts = {
			adds_debuff = {
				enable = true,
				duration = 5,
				position = 1,
				label = "debuff.boneclaw_gaze",
			},
			soulfire_debuff = {
				enable = true,
				duration = 5,
				position = 2,
				label = "debuff.soulfire",
			},
			hex_debuff_self = {
				enable = true,
				duration = 3,
				position = 3,
				label = "label.hex_debuff_self",
			},
			hex_debuff = {
				enable = false,
				duration = 3,
				position = 4,
				label = "label.hex_debuff",
			},
			midphase = {
				enable = true,
				duration = 3,
				position = 5,
				label = "alert.midphase",
			},
		},
		sounds = {
			adds_debuff = {
				enable = true,
				position = 1,
				file = "run-away",
				label = "debuff.boneclaw_gaze",
			},
			soulfire_debuff = {
				enable = true,
				position = 2,
				file = "burn",
				label = "debuff.soulfire",
			},
			midphase = {
				enable = true,
				position = 3,
				file = "alert",
				label = "alert.midphase",
			},
		},
		icons = {
			titan_debuff = {
				enable = false,
				sprite = "LUIBM_radioactive",
				size = 60,
				color = "9600ffff",
				label = "label.titan_debuff",
			},
			adds_debuff = {
				enable = true,
				sprite = "LUIBM_crosshair",
				size = 60,
				color = "ffff0000",
				label = "debuff.boneclaw_gaze",
			},
			soulfire_debuff = {
				enable = false,
				sprite = "LUIBM_fire",
				size = 60,
				color = "ff0000ff",
				label = "label.soulfire_debuff",
			},
			lost_soul = {
				enable = false,
				sprite = "LUIBM_skull4",
				size = 60,
				color = "ff00ff00",
				label = "label.lost_soul",
			},
		},
		lines = {
			lost_soul  = {
				enable = true,
				color = "ff00ff00",
				label = "label.lost_soul",
				thickness = 5,
				position = 1,
			},
			titan  = {
				enable = true,
				color = "ff9400d3",
				label = "unit.titan",
				thickness = 5,
				position = 2,
			},
			titan_debuff  = {
				enable = false,
				color = "9600ffff",
				label = "label.titan_debuff",
				thickness = 5,
				position = 3,
			},
			boneclaw_gaze  = {
				enable = true,
				color = "ffff0000",
				label = "debuff.boneclaw_gaze",
				thickness = 5,
				position = 4,
			},
			soulfire_debuff  = {
				enable = false,
				color = "ff0000ff",
				label = "label.soulfire_debuff",
				thickness = 5,
				position = 5,
			},
			ringo_line  = {
				enable = false,
				color = "ffff1493",
				label = "label.ringo_line",
				thickness = 5,
				position = 6,
			},
			essence_int_line_1  = {
				enable = false,
				color = "ffffd700",
				label = "label.essence_int_1",
				thickness = 6,
				position = 8,
			},
			essence_int_line_2  = {
				enable = false,
				color = "ffffd700",
				label = "label.essence_int_2",
				thickness = 6,
				position = 9,
			},
			essence_int_line_3  = {
				enable = false,
				color = "ffffd700",
				label = "label.essence_int_3",
				thickness = 6,
				position = 10,
			},
			essence_int_line_4  = {
				enable = false,
				color = "ffffd700",
				label = "label.essence_int_4",
				thickness = 6,
				position = 11,
			},
			essence_int_line_5  = {
				enable = false,
				color = "ffffd700",
				label = "label.essence_int_5",
				thickness = 6,
				position = 12,
			},
			orb_spawn_line_1  = {
				enable = true,
				color = "ffff1493",
				label = "label.orb_spawn_line_1",
				thickness = 3,
				position = 13,
			},
			orb_spawn_line_2  = {
				enable = false,
				color = "ffff1493",
				label = "label.orb_spawn_line_2",
				thickness = 3,
				position = 14,
			},
			orb_spawn_line_3  = {
				enable = false,
				color = "ffff1493",
				label = "label.orb_spawn_line_3",
				thickness = 3,
				position = 15,
			},
			orb_spawn_line_4  = {
				enable = false,
				color = "ffff1493",
				label = "label.orb_spawn_line_4",
				thickness = 3,
				position = 16,
			},
			orb_spawn_line_5  = {
				enable = false,
				color = "ffff1493",
				label = "label.orb_spawn_line_5",
				thickness = 3,
				position = 17,
			},
			orb_spawn_line_6  = {
				enable = false,
				color = "ffff1493",
				label = "label.orb_spawn_line_6",
				thickness = 3,
				position = 18,
			},
		},
		texts = {
			cardinal_baitmarks = {
				enable = true,
				color = "ffff4500",
				timer = false,
				label = "label.cardinal_baitmarks",
				position = 1,
			},
			orb_spawn = {
				enable = true,
				color = "ffff4500",
				timer = false,
				label = "label.orb_spawn_text",
				position = 2,
			},
			essence_int_text_1 = {
				enable = false,
				color = "ffffd700",
				timer = false,
				label = "label.essence_int_1",
				position = 3,
			},
			essence_int_text_2 = {
				enable = false,
				color = "ffffd700",
				timer = false,
				label = "label.essence_int_2",
				position = 4,
			},
			essence_int_text_3 = {
				enable = false,
				color = "ffffd700",
				timer = false,
				label = "label.essence_int_3",
				position = 5,
			},
			essence_int_text_4 = {
				enable = false,
				color = "ffffd700",
				timer = false,
				label = "label.essence_int_4",
				position = 6,
			},
			essence_int_text_5 = {
				enable = false,
				color = "ffffd700",
				timer = false,
				label = "label.essence_int_5",
				position = 7,
			},
			middle_point_mark = {
				enable = true,
				color = "ffff0000"
				timer = false,
				label = "label.middle_point_mark",
				position = 8
			},
		},
	}
	return o
end

local roomCenter = Vector3.New(-723.71, 187, -265.18)

local orbSpawns = {
	["S_OL1"] = Vector3.New(-723.71, 187, -259.18),
	["S_OL2"] = Vector3.New(-723.71, 187, -253.18),
	["S_OL3"] = Vector3.New(-723.71, 187, -247.18),
	["S_OL4"] = Vector3.New(-723.71, 187, -241.18),
	["S_OL5"] = Vector3.New(-723.71, 187, -235.18),
	["S_OL6"] = Vector3.New(-723.71, 187, -229.18),
	["N_OL5"] = Vector3.New(-723.71, 187, -295.18),
	["N_OL6"] = Vector3.New(-723.71, 187, -301.18),
	["W_OL5"] = Vector3.New(-753.71, 187, -265.18),
	["W_OL6"] = Vector3.New(-759.71, 187, -265.18),
	["E_OL5"] = Vector3.New(-693.71, 187, -265.18),
	["E_OL6"] = Vector3.New(-687.71, 187, -265.18),
}

local DEBUFF_SOULFIRE = 75574  -- Dot
local DEBUFF_NECROTIC_BREATH = 75608 -- Big skeleton fire cast debuff
local DEBUFF_SOUL_EATER = 87069  -- Stepped in orb
local DEBUFF_BONECLAW_GAZE = 85609  -- Targeted by adds
local DEBUFF_EXPULSION_OF_SOULS = 75550  -- Targeted by hex
local DEBUFF_REALM_OFTHE_DEAD = 75528  -- In spirit realm
local DEBUFF_SPIRIT_OF_SOULFIRE = 75576 -- Boss stacks
local BOSSBUFF_BARRIER_OF_SOULS = 87774  -- Immune to attacks (Midphase)
local CARDINAL_BAIT_SE = Vector3.New(-702.25, 187.17, -247.74)
local CARDINAL_BAIT_SW = Vector3.New(-745.59, 187.16, -247.69)
local CARDINAL_BAIT_NW = Vector3.New(-744.18, 187.15, -283.25)
local MIDDLE_POINT = Vector3.New(-723.71778, 186.8349, -265.1872)
local CARDINAL_BAIT_NE = Vector3.New(-703.35, 187.16, -283.39)
local CARDINAL_LINE_N = Vector3.New(-723.84, 187.02, -252.58)
local CARDINAL_LINE_S = Vector3.New(-723.84, 187.17, -206.61)

function Mod:Init(parent)
	Apollo.LinkAddon(parent, self)

	self.core = parent
	self.L = parent:GetLocale(Encounter,Locales)
	ids = {}
end

function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
	if sName == self.L["unit.boss"] and bInCombat then
		self.core:AddUnit(nId,sName,tUnit,self.config.units.boss)
		self.core:DrawText("CARDINAL_BAIT_SE", CARDINAL_BAIT_SE, self.config.texts.cardinal_baitmarks, "SE")
		self.core:DrawText("CARDINAL_BAIT_SW", CARDINAL_BAIT_SW, self.config.texts.cardinal_baitmarks, "SW")
		self.core:DrawText("CARDINAL_BAIT_NE", CARDINAL_BAIT_NE, self.config.texts.cardinal_baitmarks, "NE")
		self.core:DrawText("CARDINAL_BAIT_NW", CARDINAL_BAIT_NW, self.config.texts.cardinal_baitmarks, "NW")
		self.core:DrawText("MIDDLE_POINT", MIDDLE_POINT, self.config.texts.middle_point_mark, ".")

		self.core:DrawLineBetween("CARDINAL_LINE", CARDINAL_LINE_S, CARDINAL_LINE_N, self.config.lines.ringo_line)

		self.core:AddTimer("ADDS_SPAWN", self.L["label.add_spawn"], 37, self.config.timers.add_spawn)
		self.core:AddTimer("ORBS_SPAWN", self.L["label.orb_spawn"], 75, self.config.timers.orb_spawn)
	elseif sName == self.L["unit.titan"] then
		self.core:AddUnit(nId,sName,tUnit,self.config.units.titan)
		self.core:DrawLineBetween(("RISEN_TITAL_%d"):format(nId), nId, nil, self.config.lines.titan)

	elseif sName == self.L["unit.boneclaw"] then
		self.core:AddUnit(nId,sName,tUnit,self.config.units.boneclaw)

	elseif sName == self.L["unit.lost_soul"] then
		self.core:AddUnit(nId,sName,tUnit,self.config.units.lost_soul)
		self.core:DrawLineBetween(("SOUL_%d"):format(nId), nId, nil, self.config.lines.lost_soul)
		self.core:DrawIcon(("LOST_SOUL_ICON_%d"):format(nId), nId, self.config.icons.lost_soul, true, nil, nil)

	elseif sName == self.L["unit.essence_void"] then
		if not ids[nId] then -- To avoid the stupid event if you target it so they don't become desynced.
			self.nEssenceInt = self.nEssenceInt + 1
			self.core:AddUnit(nId,sName .. " " .. self.nEssenceInt,tUnit,self.config.units.essence_void)

			if self.nEssenceInt == 1 then
				self.core:DrawLineBetween(("ESSENCE_LINE_%d"):format(nId), tUnit, nil, self.config.lines.essence_int_line_1)
				self.core:DrawText(("ESSENCE_TEXT_%d"):format(nId), tUnit, self.config.texts.essence_int_text_1, "1")

			elseif self.nEssenceInt == 2 then
				self.core:DrawLineBetween(("ESSENCE_LINE_%d"):format(nId), tUnit, nil, self.config.lines.essence_int_line_2)
				self.core:DrawText(("ESSENCE_TEXT_%d"):format(nId), tUnit, self.config.texts.essence_int_text_2, "2")

			elseif self.nEssenceInt == 3 then
				self.core:DrawLineBetween(("ESSENCE_LINE_%d"):format(nId), tUnit, nil, self.config.lines.essence_int_line_3)
				self.core:DrawText(("ESSENCE_TEXT_%d"):format(nId), tUnit, self.config.texts.essence_int_text_3, "3")

			elseif self.nEssenceInt == 4 then
				self.core:DrawLineBetween(("ESSENCE_LINE_%d"):format(nId), tUnit, nil, self.config.lines.essence_int_line_4)
				self.core:DrawText(("ESSENCE_TEXT_%d"):format(nId), tUnit, self.config.texts.essence_int_text_4, "4")

			elseif self.nEssenceInt == 5 then
				self.core:DrawLineBetween(("ESSENCE_LINE_%d"):format(nId), tUnit, nil, self.config.lines.essence_int_line_5)
				self.core:DrawText(("ESSENCE_TEXT_%d"):format(nId), tUnit, self.config.texts.essence_int_text_5, "5")
				self.nEssenceInt = 0
			end
			ids[nId] = true

		end
	end
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
	if sName == self.L["unit.essence_void"] then
		self.core:RemoveUnit(nId)
		self.core:RemoveLineBetween(("ESSENCE_LINE_%d"):format(nId))
		self.core:RemoveText(("ESSENCE_TEXT_%d"):format(nId))
	end
end

function Mod:OnCastStart(nId, sCastName, tCast, sName, nDuration)
	if sName == self.L["unit.boss"] then
		if sCastName == self.L["cast.devour_souls"] then
			self.core:DrawText("S_OL1", orbSpawns["S_OL1"], self.config.texts.orb_spawn, "1")
			self.core:DrawText("S_OL2", orbSpawns["S_OL2"], self.config.texts.orb_spawn, "2")
			self.core:DrawText("S_OL3", orbSpawns["S_OL3"], self.config.texts.orb_spawn, "3")
			self.core:DrawText("S_OL4", orbSpawns["S_OL4"], self.config.texts.orb_spawn, "4")
			self.core:DrawText("S_OL5", orbSpawns["S_OL5"], self.config.texts.orb_spawn, "5")
			self.core:DrawText("S_OL6", orbSpawns["S_OL6"], self.config.texts.orb_spawn, "6")
			self.core:DrawText("E_OL5", orbSpawns["E_OL5"], self.config.texts.orb_spawn, "5")
			self.core:DrawText("E_OL6", orbSpawns["E_OL6"], self.config.texts.orb_spawn, "6")
			self.core:DrawText("N_OL5", orbSpawns["N_OL5"], self.config.texts.orb_spawn, "5")
			self.core:DrawText("N_OL6", orbSpawns["N_OL6"], self.config.texts.orb_spawn, "6")
			self.core:DrawText("W_OL5", orbSpawns["W_OL5"], self.config.texts.orb_spawn, "5")
			self.core:DrawText("W_OL6", orbSpawns["W_OL6"], self.config.texts.orb_spawn, "6")
			self.core:DrawPolygon("P1", roomCenter, self.config.lines.orb_spawn_line_1, 6, 0, 32)
			self.core:DrawPolygon("P2", roomCenter, self.config.lines.orb_spawn_line_2, 12, 0, 32)
			self.core:DrawPolygon("P3", roomCenter, self.config.lines.orb_spawn_line_3, 18, 0, 32)
			self.core:DrawPolygon("P4", roomCenter, self.config.lines.orb_spawn_line_4, 24, 0, 32)
			self.core:DrawPolygon("P5", roomCenter, self.config.lines.orb_spawn_line_5, 30, 0, 32)
			self.core:DrawPolygon("P6", roomCenter, self.config.lines.orb_spawn_line_6, 36, 0, 32)

			self.core:AddTimer("Timer_Orbs", self.L["timer.orb_spawn"], 93, self.config.timers.orbs)

		elseif sCastName == self.L["cast.cacophony_of_souls"] then
			self.core:ShowAlert("Alert_Midphase", self.L["alert.midphase"], self.config.alerts.midphase)
			self.core:PlaySound(self.config.sounds.midphase)
			self.nEssenceInt = 0 -- Reset orb counter

		elseif sCastName == self.L["cast.expulsion_of_souls"] then
			self.core:AddTimer("Timer_Expulsion_of_Souls", self.L["timer.hex_spawn"], 35, self.config.timers.expulsion_of_souls)

		elseif sCastName == self.L["cast.animate_bones"] then
			self.core:AddTimer("Timer_Adds", self.L["timer.adds_spawn"], 93, self.config.timers.adds)

		end
	end
end

function Mod:OnCastEnd(nId, sCastName, tCast, sName)
	if sName == self.L["unit.boss"] then
		if sCastName == self.L["cast.devour_souls"] then
			self.core:RemoveText("S_OL1")
			self.core:RemoveText("S_OL2")
			self.core:RemoveText("S_OL3")
			self.core:RemoveText("S_OL4")
			self.core:RemoveText("S_OL5")
			self.core:RemoveText("S_OL6")
			self.core:RemoveText("E_OL5")
			self.core:RemoveText("E_OL6")
			self.core:RemoveText("N_OL5")
			self.core:RemoveText("N_OL6")
			self.core:RemoveText("W_OL5")
			self.core:RemoveText("W_OL6")
			self.core:RemovePolygon("P1")
			self.core:RemovePolygon("P2")
			self.core:RemovePolygon("P3")
			self.core:RemovePolygon("P4")
			self.core:RemovePolygon("P5")
			self.core:RemovePolygon("P6")
		end
	end
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
	if nSpellId == DEBUFF_NECROTIC_BREATH then
		self.core:DrawIcon(("DEBUFF_NECROTIC_BREATH_%d"):format(nId), nId, self.config.icons.titan_debuff, true, nil, nDuration)
		self.core:DrawLineBetween(("DEBUFF_NECROTIC_BREATH_LINE_%d"):format(nId), nId, nil, self.config.lines.titan_debuff)

	elseif nSpellId == DEBUFF_BONECLAW_GAZE then
		if tData.tUnit:IsThePlayer() then
			self.core:PlaySound(self.config.sounds.adds_debuff)
			self.core:ShowAlert("DEBUFF_BONECLAW_GAZE", self.L["alert.adds_debuff"], self.config.alerts.adds_debuff)
			self.core:DrawIcon(("DEBUFF_BONECLAW_GAZE_%d"):format(nId), nId, self.config.icons.adds_debuff, true, nil, nDuration)
			local boneclawtSpell = tData.tSpell
			local boneclawCaster = boneclawtSpell.unitCaster:GetId()
			self.core:DrawLineBetween(("DEBUFF_BONECLAW_GAZE_LINE_%d"):format(nId), boneclawCaster, nil, self.config.lines.boneclaw_gaze)

		end

	elseif nSpellId == DEBUFF_SOULFIRE then
		if tData.tUnit:IsThePlayer() then
			self.core:PlaySound(self.config.sounds.soulfire_debuff)
			self.core:ShowAlert("DEBUFF_SOULFIRE", self.L["alert.soulfire_debuff"], self.config.alerts.soulfire_debuff)
		else
			self.core:DrawLineBetween(("DEBUFF_SOULFIRE_LINE_%d"):format(nId), nId, nil, self.config.lines.soulfire_debuff)
		end
			self.core:DrawIcon(("DEBUFF_SOULFIRE_ICON_%d"):format(nId), nId, self.config.icons.soulfire_debuff, true, nil, nDuration)

	elseif nSpellId == DEBUFF_EXPULSION_OF_SOULS then
		if tData.tUnit:IsThePlayer() then
			self.core:ShowAlert("DEBUFF_EXPULSION_OF_SOULS", self.L["alert.hex_debuff_self"], self.config.alerts.hex_debuff_self)
		else
			self.core:ShowAlert("DEBUFF_EXPULSION_OF_SOULS", self.L["alert.hex_debuff"]..sUnitName, self.config.alerts.hex_debuff)
		end
	elseif nSpellId == BOSSBUFF_BARRIER_OF_SOULS then
		self.core:RemoveTimer("Timer_Adds")
		self.core:RemoveTimer("Timer_Orbs")
		self.core:RemoveTimer("Timer_Expulsion_of_Souls")
	end
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
	if nSpellId == DEBUFF_NECROTIC_BREATH then
		self.core:RemoveIcon(("DEBUFF_NECROTIC_BREATH_%d"):format(nId))
		self.core:RemoveLineBetween(("DEBUFF_NECROTIC_BREATH_LINE_%d"):format(nId))
	elseif nSpellId == DEBUFF_BONECLAW_GAZE then
		self.core:RemoveIcon(("DEBUFF_BONECLAW_GAZE_%d"):format(nId))
		self.core:RemoveLineBetween(("DEBUFF_BONECLAW_GAZE_LINE_%d"):format(nId))
	elseif nSpellId == DEBUFF_SOULFIRE then
		self.core:RemoveIcon(("DEBUFF_SOULFIRE_ICON_%d"):format(nId))
		self.core:RemoveLineBetween(("DEBUFF_SOULFIRE_LINE_%d"):format(nId))
	elseif nSpellId == BOSSBUFF_BARRIER_OF_SOULS then
		self.core:AddTimer("Timer_Adds", self.L["timer.add_spawn"], 16, self.config.timers.adds)
		self.core:AddTimer("Timer_Orbs", self.L["timer.orb_spawn"], 63, self.config.timers.orbs)
	end
end

function Mod:OnHealthChanged(nId, nHealthPercent, sName, tUnit)
	if sName == self.L["unit.boss"] then
		if nHealthPercent <= 77 and self.nMidphaseSoonWarnings == 0 then
			self.core:ShowAlert("Alert_Midphase", self.L["alert.midphase_soon"], self.config.alerts.midphase)
			self.core:PlaySound(self.config.sounds.midphase)
			self.nMidphaseSoonWarnings = 1
		elseif nHealthPercent <= 52 and self.nMidphaseSoonWarnings == 1 then
			self.core:ShowAlert("Alert_Midphase", self.L["alert.midphase_soon"], self.config.alerts.midphase)
			self.core:PlaySound(self.config.sounds.midphase)
			self.nMidphaseSoonWarnings = 2
		elseif nHealthPercent <= 27 and self.nMidphaseSoonWarnings == 2 then
			self.core:ShowAlert("Alert_Midphase", self.L["alert.midphase_soon"], self.config.alerts.midphase)
			self.core:PlaySound(self.config.sounds.midphase)
			self.nMidphaseSoonWarnings = 3
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
	self.nMidphaseSoonWarnings = 0
	self.nEssenceInt = 0
	self.boneclawtSpell = 0
	self.boneclawCaster = 0

	self.core:AddTimer("Timer_Adds", self.L["timer.add_spawn"], 31, self.config.timers.adds)
	self.core:AddTimer("Timer_Orbs", self.L["timer.orb_spawn"], 77, self.config.timers.orbs)
	self.core:AddTimer("Timer_Expulsion_of_Souls", self.L["timer.hex_spawn"], 17, self.config.timers.expulsion_of_souls)
end

function Mod:OnDisable()
	self.run = false
	self.nEssenceInt = 0
end

local ModInst = Mod:new()
LUI_BossMods.modules[Encounter] = ModInst
