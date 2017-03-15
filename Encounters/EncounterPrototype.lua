require "Apollo"

local LUI_BossMods = Apollo.GetAddon("LUI_BossMods")
local Mod = {}
local meta = {__index = Mod}
local nilKey = {} --this is the key we identify nil-parameters within event-filtering with.


--[[Creates a Encounter Prototype
	@param Encounter			- Key for this Encounter to identify it (Not Localized!)]]
function LUI_BossMods:EncounterPrototype(Encounter)
	return setmetatable({encounterKey = Encounter}, meta)
end

--[[Sets the Locales for this Encounter.]]
function Mod:Locales(tenUS, tdeDE, tfrFR)
	self.locales = {enUS = tenUS or {}, deDE = tdeDE or {}, frFR = tfrFR or {}}
end

--[[Adds a unit to the list of tracked units.
	@param key					- Config Key to retrieve Options from. - Optional, if not given all other Optionals must be provided.
	@param tUnit				- Unit Object from carbine
	@param bOnCast				- Track Casts of this unit (boolean)
	@param bOnBuff				- Track Buffs of this unit (boolean)
	@param bOnDebuff			- Track Debuffs of this unit (boolean)
	@param sMark				- Letter in Front of UnitFrame 											- Optional, nil for none
	@param uniqueID																						- Optional, Default: key
	@param sName				- Name of the unit 														- Optional, Default: self.config.units[key].label (or the referred self.L[...])
	@param sColor				- Health Bar Color (ARGB String) 										- Optional, Default: self.config.units[key].color
	@param nPriority			- Priority in UnitFrame and Option Panel (Top to Bottom) 				- Optional, Default: self.config.units[key].priority
	@param bShowUnit			- Boolean whether or not unit should be displayed (boss frames) 		- Optional, Default: self.config.units[key].enable]]
function Mod:AddUnit(key, tUnit, bOnCast, bOnBuff, bOnDebuff, sMark, uniqueID, sName, sColor, nPriority, bShowUnit)
	self.core:AddUnit(uniqueID or key, sName or self.L[self.config.units[key].label] or self.config.units[key].label, tUnit, bShowUnit or self.config.units[key].enable, bOnCast, bOnBuff, bOnDebuff, sMark, sColor or self.config.units[key].color, nPriority or self.config.units[key].priority)
end

--[[Removes the unit completely.
	@param uniqueID				- The uniqueID the Unit was added with. (reminder: if it wasnt provided, its just the key)]]
function Mod:RemoveUnit(uniqueID)
	self.core:RemoveUnit(uniqueID)
end


--[[Creates a timer bar
	@param key					- Config Key to retrieve Options from.
	@param nDuration			- Duration in Seconds
	@param uniqueID																						- Optional, Default: key
	@param sText				- Bar Text 																- Optional, Default: self.config.timers[key].label (or the referred self.L[...])
	@param sColor				- Bar Color (ARGB String) 												- Optional, Default: self.config.timers[key].color
	@param bSound				- Play Countdown Sound (boolean)										- Optional, Default: self.config.timers[key].sound
	@param bAlert				- Show Countdown Messages (boolean)										- Optional, Default: self.config.timers[key].alert
	@param fHandler				- Callback function 													- Optional
	@param tData				- Data forwarded by callback function									- Optional]]
function Mod:AddTimer(key, nDuration, uniqueID, sText, sColor, bSound, bAlert, fHandler, tData)
	if self.config.timers[key] and self.config.timers[key].enable then
		local txt = sText or self.L[self.config.timers[key].label] or self.config.timers[key].label
		self.core:AddTimer(uniqueID or key, txt, nDuration, sColor or self.config.timers[key].color, bSound or self.config.timers[key].sound, bAlert or self.config.timers[key].alert, fHandler, tData)
	end
end

--[[Hides the Timer
	@param uniqueID            	- The uniqueID the Timer was created with. (reminder: if it wasnt provided, its just the key)]]
function Mod:RemoveTimer(uniqueID)
	self.core:RemoveTimer(uniqueID)
end


--[[Shows Castbar
	@param key					- Config Key to retrieve Options from.
	@param tCast            	- Cast Object (typically gained from Mod:OnCastStart())
	@param sName            	- Text shown on the Castbar 											- Optional, Default: self.config.casts[key].label (or the referred self.L[...])
	@param sColor           	- Cast Bar Color (ARGB String) 											- Optional, Default: self.config.casts[key].color ]]
function Mod:ShowCast(key, tCast, sName, sColor)
	if self.config.casts[key] and self.config.casts[key].enable then
		local txt = sName or self.L[self.config.casts[key].label] or self.config.casts[key].label
		self.core:ShowCast(tCast, txt, sColor or self.config.casts[key].color)
	end		
end

--[[Hides the Castbar]]
function Mod:HideCast()
	self.core:HideCast() --we may need to ask for a key to look up, if this bar is even shown. Not sure.
end

--[[Creates an Aura on your screen (like LUI Aura)
	@param key					- Config Key to retrieve Options from.
	@param nDuration       	 	- Duration in Seconds 													- Optional
	@param bShowDuration    	- Show Duration Text													- Optional, Default: true
	@param uniqueID																						- Optional, Default: key
	@param sSprite          	- Sprite of Aura 														- Optional, Default: self.config.auras[key].sprite
	@param sColor				- Sprite Color (ARGB String) 											- Optional, Default: self.config.auras[key].color
	@param fHandler         	- Callback function 													- Optional
	@param tData            	- Data forwarded by callback function									- Optional]]
function Mod:ShowAura(key, nDuration, bShowDuration, uniqueID, sSprite, sColor, fHandler, tData)
	if self.config.auras[key] and self.config.auras[key].enable then
		self.core:ShowAura(uniqueID or key, sSprite or self.config.auras[key].sprite, sColor or self.config.auras[key].color, nDuration, bShowDuration or true, fHandler, tData)
	end
end

--[[Hides the Aura
	@param uniqueID            	- The uniqueID the Aura was created with. (reminder: if it wasnt provided, its just the key)]]
function Mod:HideAura(uniqueID)
	self.core:HideAura(uniqueID)
end

--[[Shows a Text Notification on your screen
	@param key					- Config Key to retrieve Options from.
	@param sText            	- Text displayed														- Optional, Default: self.config.alerts[key].label (or the referred self.L[...])
	@param nDuration       	 	- Duration in Seconds 													- Optional, Default: self.config.alerts[key].duration
	@param uniqueID																						- Optional, Default: key
	@param sColor				- Text Color (ARGB String) 												- Optional, Default: self.config.alerts[key].color
	@param sFont				- Text Font 															- Optional, Default: self.core.config.alerts.font
	@param fHandler         	- Callback function 													- Optional
	@param tData            	- Data forwarded by callback function									- Optional]]
function Mod:ShowAlert(key, sText, nDuration, uniqueID, sColor, sFont, fHandler, tData)
	if self.config.alerts[key] and self.config.alerts[key].enable then
		local txt = sText or self.L[self.config.alerts[key].label] or self.config.alerts[key].label
		self.core:ShowAlert(uniqueID or key, txt, nDuration or self.config.alerts[key].duration, sColor or self.config.alerts[key].color, sFont or self.core.config.alerts.font, fHandler, tData)
	end
end

--[[Hides the Alert
	@param uniqueID            	- The uniqueID the Alert was created with. (reminder: if it wasnt provided, its just the key)]]
function Mod:HideAlert(uniqueID)
	self.core:HideAlert(uniqueID)
end

--[[Plays a soundfile
	@param key					- Config Key to retrieve Options from.
	@param sound            	- Name of Soundfile (can be either string of filename or number of carbine sound) - Optional, Default:  self.config.sounds[key].file]]
function Mod:PlaySound(key, sound)
    if self.config.sounds[key] and self.config.sounds[key].enable then
		self.core:PlaySound(sound or self.config.sounds[key].file)
	end
end

--[[Draw Icon on top of unit
	@param key					- Config Key to retrieve Options from.
	@param Origin           	- Unit Object
	@param nHeight          	- Height of Icon from bottom
	@param nDuration        	- Duration in seconds before getting removed 							- Optional
	@param bShowOverlay     	- Show Duration Overlay 												- Optional, Default: false
	@param uniqueID																						- Optional, Default: key
	@param sSprite          	- Sprite of Pixie 														- Optional, Default: self.config.icons[key].sprite
	@param nSpriteSize      	- Size of Pixie 														- Optional, Default: self.config.icons[key].size
	@param sColor           	- Text Color (ARGB String) 												- Optional, Default: self.config.icons[key].color
	@param fHandler         	- Callback function 													- Optional
	@param tData            	- Data forwarded by callback function									- Optional]]
function Mod:DrawIcon(key, Origin, nHeight, nDuration, bShowOverlay, uniqueID, sSprite, nSpriteSize, sColor, fHandler, tData)
	if self.config.icons[key] and self.config.icons[key].enable then
		self.core:DrawIcon(uniqueID or key, Origin, sSprite or self.config.icons[key].sprite, nSpriteSize or self.config.icons[key].size, nHeight, sColor or self.config.icons[key].color, nDuration, bShowOverlay or false, fHandler, tData)
	end
end

--[[Removes Icon from Screen
	@param uniqueID            	- The uniqueID the Icon was created with. (reminder: if it wasnt provided, its just the key)]]
function Mod:RemoveIcon(uniqueID)
	self.core:RemoveIcon(uniqueID)
end

--[[Draw Pixie on top of unit or coordinate (Basically a Icon with rotation and offset to the front of a unit.)
	@param key					- Config Key to retrieve Options from. (key inside self.config.icons)
	@param Origin           	- Unit Object / UnitId or Coordinates
	@param nHeight          	- Height of Icon from bottom
	@param nDistance			- Offset to the front of origin 
	@param nRotation			- Rotation in degrees
	@param nDuration        	- Duration in seconds before getting removed 							- Optional
	@param uniqueID																						- Optional, Default: key
	@param sSprite          	- Sprite of Pixie 														- Optional, Default: self.config.icons[key].sprite
	@param nSpriteSize      	- Size of Pixie 														- Optional, Default: self.config.icons[key].size
	@param sColor           	- Text Color (ARGB String) 												- Optional, Default: self.config.icons[key].color
	@param fHandler         	- Callback function 													- Optional
	@param tData            	- Data forwarded by callback function									- Optional]]
function Mod:DrawPixie(key, Origin, nHeight, nDistance, nRotation, nDuration, uniqueID, sSprite, nSpriteSize, sColor, fHandler, tData)
    if self.config.icons[key] and self.config.icons[key].enable then
		self.core:DrawPixie(uniqueID or key, Origin, sSprite or self.config.icons[key].sprite, nSpriteSize or self.config.icons[key].size, nRotation, nDistance, nHeight, sColor or self.config.icons[key].color, nDuration, fHandler, tData)
	end
end

--[[Removes Pixie from Screen
	@param uniqueID            	- The uniqueID the Pixie was created with. (reminder: if it wasnt provided, its just the key)]]
function Mod:RemovePixie(uniqueID)
	self.core:RemovePixie(uniqueID)
end

--[[Draws a polyon on the ground at unit or position
	@param key					- Config Key to retrieve Options from. (key inside self.config.lines)
	@param Origin           	- Unit Object / UnitId or Coordinates
	@param nRadius          	- Radius of Polygon
	@param nSides           	- Amount of Sides of the Polygon
	@param nRotation			- Rotation of the Polygon in Degrees 									- Optional, Default: 0
	@param nDuration        	- Duration in seconds before getting removed 							- Optional
	@param uniqueID																						- Optional, Default: key
	@param nWidth           	- Thickness 															- Optional, Default: self.config.lines[key].thickness
	@param sColor           	- Text Color (ARGB String) 												- Optional, Default: self.config.lines[key].color
	@param fHandler         	- Callback function 													- Optional
	@param tData            	- Data forwarded by callback function 									- Optional]]
function Mod:DrawPolygon(key, Origin, nRadius, nSides, nRotation, nDuration, uniqueID, nWidth, sColor, fHandler, tData)
	if self.config.lines[key] and self.config.lines[key].enable then
		self.core:DrawPolygon(uniqueID or key, Origin, nRadius, nRotation, nWidth or self.config.lines[key].thickness, sColor or self.config.lines[key].color, nSides, nDuration, fHandler, tData)
	end
end

--[[Removes Polygon from Screen
	@param uniqueID            	- The uniqueID the Polygon was created with. (reminder: if it wasnt provided, its just the key)]]
function Mod:RemovePolygon(uniqueID)
    self.core:RemovePixie(uniqueID)
end

--[[Draws a line from unit/coordinate into certain direction (unit facing/north + fixed rotation)
	@param key					- Config Key to retrieve Options from. (key inside self.config.lines)
	@param Origin           	- Unit Object / UnitId or Coordinates
	@param nLength				- Length of the Line
	@param nRotation			- Rotation in degrees 													- Optional, Default: 0
	@param nOffset				- Offset from Origin (in draw-direction) 								- Optional, Default: 0
	@param tVectorOffset		- Offset to Origin (table or vector3) (gets rotated aswell) 			- Optional
	@param nDuration			- Duration in seconds before getting removed 							- Optional
	@param nNumberOfDot			- Amount of dots 														- Optional, Default: 1 (Whole Line)
	@param uniqueID																						- Optional, Default: key
	@param nWidth				- Thickness 															- Optional, Default: self.config.lines[key].thickness
	@param sColor				- Text Color (ARGB String) 												- Optional, Default: self.config.lines[key].color
	@param fHandler				- Callback function 													- Optional
	@param tData				- Data forwarded by callback function									- Optional]]
function Mod:DrawLine(key, Origin, nLength, nRotation, nOffset, tVectorOffset, nDuration, nNumberOfDot, uniqueID, nWidth, sColor, fHandler, tData)
    if self.config.lines[key] and self.config.lines[key].enable then
		self.core:DrawLine(uniqueID or key, Origin, sColor or self.config.lines[key].color, nWidth or self.config.lines[key].thickness, nLength, nRotation or 0, nOffset or 0, tVectorOffset, nDuration, nNumberOfDot or 1, fHandler, tData)
	end
end

--[[Removes Lines from Screen
	@param uniqueID          	- The uniqueID the Line was created with. (reminder: if it wasnt provided, its just the key)]]
function Mod:RemoveLine(uniqueID)
	self.core:RemoveLine(uniqueID)
end

--[[Draws a line in between two origins (unit/coordinate)
	@param key					- Config Key to retrieve Options from. (key inside self.config.lines)
	@param FromOrigin       	- Unit Object / UnitId or Coordinates
	@param ToOrigin         	- Unit Object / UnitId or Coordinates									- Optional, Default: PlayerUnit (nil)
	@param nDuration			- Duration in seconds before getting removed 							- Optional
	@param nNumberOfDot			- Amount of dots 														- Optional, Default: 1 (Whole Line)
	@param uniqueID																						- Optional, Default: key
	@param nWidth				- Thickness 															- Optional, Default: self.config.lines[key].thickness
	@param sColor				- Text Color (ARGB String) 												- Optional, Default: self.config.lines[key].color
	@param fHandler				- Callback function 													- Optional
	@param tData				- Data forwarded by callback function									- Optional]]
function Mod:DrawLineBetween(key, FromOrigin, ToOrigin, nDuration, nNumberOfDot, uniqueID, nWidth, sColor, fHandler, tData)
	if self.config.lines[key] and self.config.lines[key].enable then
		self.core:DrawLineBetween(uniqueID or key, FromOrigin, ToOrigin, sColor or self.config.lines[key].color, nWidth or self.config.lines[key].thickness, nDuration, nNumberOfDot or 1, fHandler, tData)
	end
end

--[[Removes Lines from Screen
	@param uniqueID             - The uniqueID the Line was created with. (reminder: if it wasnt provided, its just the key)]]
function Mod:RemoveLineBetween(uniqueID)
	self.core:RemoveLineBetween(uniqueID)
end

--[[Returns Icon/Pixie/Polygon/Line/LineBetween according to the uniqueID
	@param uniqueID             - The uniqueID the Line was created with. (reminder: if it wasnt provided, its just the key)]]
function Mod:GetDraw(uniqueID)
    return self.core:GetDraw(uniqueID)
end

--[[Compute the distance between two origins.
	@param FromOrigin       	- Unit Object / UnitId or Coordinates
	@param ToOrigin         	- Unit Object / UnitId or Coordinates 									- Optional, Default: PlayerUnit (nil)
	@return 					- The distance in meter.]]
function Mod:GetDistance(FromOrigin, ToOrigin)
	return self.core:GetDistance(FromOrigin, ToOrigin)
end


local configEnviroment = {}
do
	--[[All of these functions are accessible from inside the Mod:Setup() Method.]]
	function Mod:Setup() end --This function should be overwritten in your Encounter!
	
	local _G = _G
	setfenv(1, configEnviroment)
	
	--[[Sets the triggers for this Encounter. (In which situations this Encounter should be loaded)
		@param sType				- "ALL" or "ANY" - Does the Encounter need every unit from the localized unittable, or only one?
		@param enUnits				- Indexed table of the required units of this Encounter
		@param deUnits				- Localized for the different Client-Languages
		@param frUnits				- Examples: {"Hydroflux", "Pyrobane"} or {"Swabbie Ski'li"}
		@params ...					- All Zones, in which this Encounter could be loaded. Example: {continentId = 104, parentZoneId = 548, mapId = 549} ]]
	function trigger(sType, enUnits, deUnits, frUnits, ...)
		configEnviroment.Mod.tTrigger = {
			sType = sType,
			tNames = {
				["enUS"] = enUnits,
				["deDE"] = deUnits,
				["frFR"] = frUnits,
			},
			tZones = {...},
		}
	end
	
	--[[Sets the categories/names of this encounter within the Option Panel
		@param sInstance			- Name of the Instance e.g.: "Datascape"
		@param sName				- Name of the Encounter e.g.: "System Daemons"
		@param sGroup				- Name of the Group of this Encounter (Optional) e.g.: "Minibosses"
	]]
	function name(sInstance, sName, sGroup)
		configEnviroment.Mod.instance = sInstance
		configEnviroment.Mod.displayName = sName
		configEnviroment.Mod.groupName = sGroup
	end
	
	--[[Disables this Encounter by Default]]
	function disable()
		configEnviroment.Mod.config.enable = false
	end
	
	--[[Disables the Settings-Page of this Encounter]]
	function disableSettings()
		configEnviroment.Mod.bHasSettings = false
	end
	
	--[[Adds the defaults for a unit.
		@param key					- The key for these options
		@param bEnable				- Show this unit in UnitFrame?
		@param sColor				- Default for Health Bar Color (not given: uses Global Setting)
		@param sLabel				- Text in Option Panel (Text or Locale Key)
		@param nPriority			- Priority in UnitFrame and Option Panel (Top to Bottom)]]
	function unit(key, bEnable, sColor, sLabel, nPriority)
		if not configEnviroment.Mod.config.units then configEnviroment.Mod.config.units = {} end
		configEnviroment.Mod.config.units[key] = {
			enable = bEnable,
			priority = nPriority,
			color = sColor,
			label = sLabel,
		}
	end
	
	--[[Adds the defaults for a timer.
		@param key					- The key for these options
		@param bEnable				- Default for Enable/Disable timer
		@param sColor				- Default for Timer Bar Color (not given: uses Global Setting)
		@param sLabel				- Text in Option Panel (Text or Locale Key)
		@param bSound				- Default, if this timer should have a countdown.
		@param bAlert				- Default, if the countdown should appear as Alert.
		@param nPriority			- Priority in Option Panel (Top to Bottom)]]
	function timer(key, bEnable, sColor, sLabel, bSound, bAlert, nPriority)
		if not configEnviroment.Mod.config.timers then configEnviroment.Mod.config.timers = {} end
		configEnviroment.Mod.config.timers[key] = {
			enable = bEnable,
			color = sColor,
			label = sLabel,
			priority = nPriority,
			sound = bSound,
			alert = bAlert,
		}
	end
	
	--[[Adds the defaults for a cast.
		@param key					- The key for these options
		@param bEnable				- Default for Enable/Disable cast
		@param sColor				- Default for Cast Bar Color (not given: uses Global Setting)
		@param sLabel				- Text in Option Panel (Text or Locale Key)
		@param nPriority			- Priority in Option Panel (Top to Bottom)]]
	function cast(key, bEnable, sColor, sLabel, nPriority)
		if not configEnviroment.Mod.config.casts then configEnviroment.Mod.config.casts = {} end
		configEnviroment.Mod.config.casts[key] = {
			enable = bEnable,
			color = sColor,
			label = sLabel,
			priority = nPriority,
		}
	end
	
	--[[Adds the defaults for a alert.
		@param key					- The key for these options
		@param bEnable				- Default for Enable/Disable alert
		@param sColor				- Default for Alert Color (not given: uses Global Setting)
		@param nDuration			- Duration for this alert
		@param sLabel				- Text in Option Panel (Text or Locale Key)
		@param nPriority			- Priority in Option Panel (Top to Bottom)]]
	function alert(key, bEnable, sColor, nDuration, sLabel, nPriority)
		if not configEnviroment.Mod.config.alerts then configEnviroment.Mod.config.alerts = {} end
		configEnviroment.Mod.config.alerts[key] = {
			enable = bEnable,
			color = sColor,
			duration = nDuration,
			label = sLabel,
			priority = nPriority,
		}
	end
	
	--[[Adds the defaults for a sound.
		@param key					- The key for these options
		@param bEnable				- Default for Enable/Disable sound
		@param sFile				- Default for sound-file (can be either string of filename or number of carbine sound)
		@param sLabel				- Text in Option Panel (Text or Locale Key)
		@param nPriority			- Priority in Option Panel (Top to Bottom)]]
	function sound(key, bEnable, sFile, sLabel, nPriority)
		if not configEnviroment.Mod.config.sounds then configEnviroment.Mod.config.sounds = {} end
		configEnviroment.Mod.config.sounds[key] = {
			enable = bEnable,
			file = sFile,
			label = sLabel,
			priority = nPriority,
		}
	end
	
	--[[Adds the defaults for a icon/sprite.
		@param key					- The key for these options
		@param bEnable				- Default for Enable/Disable icon/sprite
		@param sSprite				- Default Sprite for this icon/sprite
		@param nSize				- Default Size for this icon/sprite (not given: uses Global Setting)
		@param sColor				- Default for icon/sprite Color (not given: uses Global Setting)
		@param sLabel				- Text in Option Panel (Text or Locale Key)
		@param nPriority			- Priority in Option Panel (Top to Bottom)]]
	function icon(key, bEnable, sSprite, nSize, sColor, sLabel, nPriority)
		if not configEnviroment.Mod.config.icons then configEnviroment.Mod.config.icons = {} end
		configEnviroment.Mod.config.icons[key] = {
			enable = bEnable,
			sprite = sSprite,
			size = nSize,
			color = sColor,
			label = sLabel,
			priority = nPriority,
		}
	end
	
	--[[Adds the defaults for a aura.
		@param key					- The key for these options
		@param bEnable				- Default for Enable/Disable aura
		@param sSprite				- Default Sprite for this aura
		@param sColor				- Default for aura Color (not given: uses Global Setting)
		@param sLabel				- Text in Option Panel (Text or Locale Key)
		@param nPriority			- Priority in Option Panel (Top to Bottom)]]
	function aura(key, bEnable, sSprite, sColor, sLabel, nPriority)
		if not configEnviroment.Mod.config.auras then configEnviroment.Mod.config.auras = {} end
		configEnviroment.Mod.config.auras[key] = {
			enable = bEnable,
			sprite = sSprite,
			color = sColor,
			label = sLabel,
			priority = nPriority,
		}
	end
	
	--[[Adds the defaults for a line.
		@param key					- The key for these options
		@param bEnable				- Default for Enable/Disable line
		@param sColor				- Default for line Color
		@param nThickness			- Default for line Thickness
		@param sLabel				- Text in Option Panel (Text or Locale Key)
		@param nPriority			- Priority in Option Panel (Top to Bottom)]]
	function line(key, bEnable, sColor, nThickness, sLabel, nPriority)
		if not configEnviroment.Mod.config.lines then configEnviroment.Mod.config.lines = {} end
		configEnviroment.Mod.config.lines[key] = {
			enable = bEnable,
			color = sColor,
			thickness = nThickness,
			label = sLabel,
			priority = nPriority,
		}
	end
	
	--this will build up something like this: self.eventFilters[arg1][arg2][arg3][arg4] = {sMethod, ???} (with nParameters = 4)
	-- nParameters is actually the amount of parameters in ...
	-- arg1 will usually be the original Method to recieve Events from e.g. "OnUnitCreated"
	local function filterEvent(sMethod, nParameters, ...)
		local self = configEnviroment.Mod
		local args = {...}
		if not self.eventFilters then self.eventFilters = {} end
		local curr = self.eventFilters
		for i=1, nParameters, 1 do
			local parameter = args[i]~=nil and args[i] or nilKey
			curr[parameter] = curr[parameter] or {}
			curr = curr[parameter]
		end
		table.insert(curr, sMethod)
	end
	
	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param sName				- The units name													- Optional, nil = dont filter by this parameter
		@param bInCombat			- Is the unit in combat?											- Optional, nil = dont filter by this parameter]]
	function onUnitCreated(sMethod, sName, bInCombat)
		filterEvent(sMethod, 3, "OnUnitCreated", sName, bInCombat)
	end
	
	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param sName				- The units name													- Optional, nil = dont filter by this parameter]]
	function onUnitDestroyed(sMethod, sName)
		filterEvent(sMethod, 2, "OnUnitDestroyed", sName)
	end
	
	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param uniqueID				- The uniqueID the unit was added with								- Optional, nil = dont filter by this parameter
		@param sName				- The units name													- Optional, nil = dont filter by this parameter]]
	function onHealthChanged(sMethod, uniqueID, sName)
		filterEvent(sMethod, 3, "OnHealthChanged", uniqueID, sName)
	end
	
	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param sMessage				- The said message													- Optional, nil = dont filter by this parameter
		@param sName				- The units name													- Optional, nil = dont filter by this parameter
		@param sEvent				- The Original Chat-Event OnNPCSay, OnNPCYell, OnNPCWhisper, OnDatachron - Optional, nil = dont filter by this parameter]]
	function onDatachron(sMethod, sMessage, sName, sEvent)
		filterEvent(sMethod, 4, "OnDatachron", sMessage, sName, sEvent)
	end

	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param uniqueID				- The uniqueID the unit was added with								- Optional, nil = dont filter by this parameter
		@param sUnitName			- The units name													- Optional, nil = dont filter by this parameter
		@param spellID				- The spells ID														- Optional, nil = dont filter by this parameter
		@param sSpellName			- The spells name													- Optional, nil = dont filter by this parameter	
		@param nStack				- The amount of stacks this buff was applied with 					- Optional, nil = dont filter by this parameter]]
	function onBuffAdded(sMethod, uniqueID, sUnitName, spellID, sSpellName, nStack)
		filterEvent(sMethod, 6, "OnBuffAdded", uniqueID, sUnitName, spellID, sSpellName, nStack)
	end

	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param uniqueID				- The uniqueID the unit was added with								- Optional, nil = dont filter by this parameter
		@param sUnitName			- The units name													- Optional, nil = dont filter by this parameter
		@param spellID				- The spells ID														- Optional, nil = dont filter by this parameter
		@param sSpellName			- The spells name													- Optional, nil = dont filter by this parameter	
		@param nStack				- The amount of stacks this buff now has		 					- Optional, nil = dont filter by this parameter]]
	function onBuffUpdated(sMethod, uniqueID, sUnitName, spellID, sSpellName, nStack)
		filterEvent(sMethod, 6, "OnBuffUpdated", uniqueID, sUnitName, spellID, sSpellName, nStack)
	end

	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param uniqueID				- The uniqueID the unit was added with								- Optional, nil = dont filter by this parameter
		@param sUnitName			- The units name													- Optional, nil = dont filter by this parameter
		@param spellID				- The spells ID														- Optional, nil = dont filter by this parameter
		@param sSpellName			- The spells name													- Optional, nil = dont filter by this parameter]]
	function onBuffRemoved(sMethod, uniqueID, sUnitName, spellID, sSpellName)
		filterEvent(sMethod, 5, "OnBuffRemoved", uniqueID, sUnitName, spellID, sSpellName)
	end
	
	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param uniqueID				- The uniqueID the unit was added with								- Optional, nil = dont filter by this parameter
		@param sUnitName			- The units name													- Optional, nil = dont filter by this parameter
		@param sSpellName			- The spells name													- Optional, nil = dont filter by this parameter]]
	function onCastStart(sMethod, uniqueID, sUnitName, sSpellName)
		filterEvent(sMethod, 4, "OnCastStart", uniqueID, sUnitName, sSpellName)
	end
	
	--[[Calls the Method 'sMethod' whenever a matching event was recieved. Passes only events on, which match the parameters after sMethod.
		@param sMethod				- The key, to find the to-be-called method at. (e.g. "Cast123" would call Mod:Cast123(...))
		@param uniqueID				- The uniqueID the unit was added with								- Optional, nil = dont filter by this parameter
		@param sUnitName			- The units name													- Optional, nil = dont filter by this parameter
		@param sSpellName			- The spells name													- Optional, nil = dont filter by this parameter]]
	function onCastEnd(sMethod, uniqueID, sUnitName, sSpellName)
		filterEvent(sMethod, 4, "OnCastStart", uniqueID, sUnitName, sSpellName)
	end
	
	_G.setfenv(1, _G)
	setmetatable(configEnviroment, {__index = _G, __newindex = _G})
end

function Mod:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.bHasSettings = true
    self.run = false
    self.runtime = {}
    self.config = {                     -- Table of settings for this module (Value "false" will disable certain settings in option panel)
        enable = true,                  -- Enable/Disable Boss Module
    }
	
	LUI_BossMods.modules[self.encounterKey] = o
	
	if self.Setup then
		rawset(configEnviroment, "Mod", self)
		setfenv(self.Setup, configEnviroment)
		self:Setup()
	end

    return o
end

function Mod:Init(parent)
    Apollo.LinkAddon(parent, self)
    self.core = parent
    self.L = parent:GetLocale(self.encounterKey,self.locales)
	
	if self.SetupEvents then
		rawset(configEnviroment, "Mod", self)
		setfenv(self.SetupEvents, configEnviroment)
		self:SetupEvents()
	end
end

function Mod:IsRunning()
    return self.run
end

function Mod:IsEnabled()
    return self.config.enable
end

-- Gets called when player enters combat while module trigger being successful.
function Mod:OnEnable()
    self.run = true
	if self.OnStart then
		self:OnStart()
	end
end

-- Gets called when group wipes on encounter
function Mod:OnDisable()
	if self.OnEnd then
		self:OnEnd()
	end
    self.run = false
end

--could do this recursive aswell, not sure whats better.
-- table insertion or filling stack?
local function passEventOn(self, tArgs, nParameters, ...) --table insertion
	if not self.eventFilters then return end
	local args = {...}
	local curr = {self.eventFilters} -- The searched-in table.
	local wip = {} --work in progress - the currently filling table
	for i=1, nParameters, 1 do
		for _, tbl in ipairs(curr) do --this can end up very often in ipairs({}) for events which are not supposed to reach anwhere. --maybe prevent and return?
			if args[i]~=nil and tbl[args[i]] then
				table.insert(wip, tbl[args[i]])
			end
			if tbl[nilKey] then
				table.insert(wip, tbl[nilKey])
			end
		end
		curr = wip
		wip = {}
	end
	
	--maybe put this into its own function to only unpack() once?
	for _, tbl in ipairs(curr) do --this can end up having a max size of 2^(nParameters-1) - each of which needs to contain at least a single Method to be called.
		for _, sMethod in ipairs(tbl) do --this SHOULD most of the times only return a single one, but... who knows xD?
			self[sMethod](self, unpack(tArgs))
		end
	end
end

--[[ Recursive approach (filling stack)
	local function helper(self, tArgs, tbl, nParameters, arg1, ...)
		if not tbl then return end
		if nParameters==0 then
			for _, sMethod in ipairs(tbl) do
				self[sMethod](self, unpack(tArgs))
			end
		else
			if arg1~=nil then
				helper(self, tArgs, tbl[arg1], nParameters-1, ...)
			end
			helper(self, tArgs, tbl[nilKey], nParameters-1, ...)
		end
	end

	local function passEventOn(self, tArgs, nParameters, ...)
		helper(self, tArgs, self.eventFilters, nParameters, ...)
	end
]]


function Mod:OnUnitCreated(nId, tUnit, sName, bInCombat)
	if not self.run then return end
	passEventOn(self, {nId, tUnit, sName, bInCombat}, 3, "OnUnitCreated", sName, bInCombat)
end

function Mod:OnUnitDestroyed(nId, tUnit, sName)
	if not self.run then return end
	passEventOn(self, {nId, tUnit, sName}, 2, "OnUnitDestroyed", sName)
end

function Mod:OnHealthChanged(nId, nHealthPercent, sName, tUnit)
	if not self.run then return end
	passEventOn(self, {nId, nHealthPercent, sName, tUnit}, 3, "OnHealthChanged", nId, sName)
end

function Mod:OnDatachron(sMessage, sSender, sHandler)
	if not self.run then return end
	passEventOn(self, {sMessage, sSender, sHandler}, 4, "OnDatachron", sMessage, sSender, sHandler)
end

function Mod:OnBuffAdded(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
	if not self.run then return end
	passEventOn(self, {nId, nSpellId, sName, tData, sUnitName, nStack, nDuration}, 6, "OnBuffAdded", nId, sUnitName, nSpellId, sName, nStack)
end

function Mod:OnBuffUpdated(nId, nSpellId, sName, tData, sUnitName, nStack, nDuration)
	if not self.run then return end
	passEventOn(self, {nId, nSpellId, sName, tData, sUnitName, nStack, nDuration}, 6, "OnBuffUpdated", nId, sUnitName, nSpellId, sName, nStack)
end

function Mod:OnBuffRemoved(nId, nSpellId, sName, tData, sUnitName)
	if not self.run then return end
	passEventOn(self, {nId, nSpellId, sName, tData, sUnitName}, 5, "OnBuffUpdated", nId, sUnitName, nSpellId, sName)
end

function Mod:OnCastStart(nId, sCastName, tCast, sName, nDuration)
	if not self.run then return end
	passEventOn(self, {nId, sCastName, tCast, sName, nDuration}, 4, "OnCastStart", nId, sName, sCastName)
end

function Mod:OnCastEnd(nId, sCastName, tCast, sName)
	if not self.run then return end
	passEventOn(self, {nId, sCastName, tCast, sName}, 4, "OnCastEnd", nId, sName, sCastName)
end