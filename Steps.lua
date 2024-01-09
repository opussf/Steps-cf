-- STEPS 1.11
STEPS_SLUG, STEPS = ...
STEPS_MSG_ADDONNAME = GetAddOnMetadata( STEPS_SLUG, "Title" )
STEPS_MSG_VERSION   = GetAddOnMetadata( STEPS_SLUG, "Version" )
STEPS_MSG_AUTHOR    = GetAddOnMetadata( STEPS_SLUG, "Author" )

-- Colours
COLOR_RED = "|cffff0000"
COLOR_GREEN = "|cff00ff00"
COLOR_BLUE = "|cff0000ff"
COLOR_PURPLE = "|cff700090"
COLOR_YELLOW = "|cffffff00"
COLOR_ORANGE = "|cffff6d00"
COLOR_GREY = "|cff808080"
COLOR_GOLD = "|cffcfb52b"
COLOR_NEON_BLUE = "|cff4d4dff"
COLOR_END = "|r"

Steps_data = {}
Steps_options = {}
STEPS.steps_per_second = 2/7  -- 2 steps at speed 7
STEPS.pruneDays = 91
STEPS.min = 0
STEPS.ave = 0
STEPS.max = 0
STEPS.commPrefix = "STEPS"
STEPS.stepsColor = { 0.73, 0.52, 0.18, 1 }

-- Setup
function STEPS.OnLoad()
	SLASH_STEPS1 = "/STEPS"
	SlashCmdList["STEPS"] = function(msg) STEPS.Command(msg); end
	STEPS.lastSpeed = 0
	Steps_Frame:RegisterEvent( "ADDON_LOADED" )
	Steps_Frame:RegisterEvent( "VARIABLES_LOADED" )
	Steps_Frame:RegisterEvent( "LOADING_SCREEN_DISABLED" )
	Steps_Frame:RegisterEvent( "CHAT_MSG_ADDON" )
	Steps_Frame:RegisterEvent( "GROUP_ROSTER_UPDATE" )
	Steps_Frame:RegisterEvent( "INSTANCE_GROUP_SIZE_CHANGED" )
end
function STEPS.ADDON_LOADED()
	Steps_Frame:UnregisterEvent( "ADDON_LOADED" )
	STEPS.name = UnitName("player")
	STEPS.realm = GetRealmName()
	STEPS.msgRealm = string.gsub( STEPS.realm, " ", "" )
	TooltipDataProcessor.AddTooltipPostCall( Enum.TooltipDataType.Unit, STEPS.TooltipSetUnit )
end
function STEPS.VARIABLES_LOADED()
	-- Unregister the event for this method.
	Steps_Frame:UnregisterEvent( "VARIABLES_LOADED" )

	Steps_data[STEPS.realm] = Steps_data[STEPS.realm] or {}
	Steps_data[STEPS.realm][STEPS.name] = Steps_data[STEPS.realm][STEPS.name] or { ["steps"] = 0 }
	STEPS.mine = Steps_data[STEPS.realm][STEPS.name]
	STEPS.mine[date("%Y%m%d")] = STEPS.mine[date("%Y%m%d")] or { ["steps"] = 0 }
	STEPS.min, STEPS.ave, STEPS.max = STEPS.CalcMinAveMax()
	STEPS.Prune()
	if Steps_options.show then
		Steps_Frame:SetAlpha(1)
	else
		Steps_Frame:SetAlpha(0)
	end
	if Steps_options.enableChat then
		STEPS.InitChat()
	end
end
function STEPS.SendMessages()
	if not C_ChatInfo.IsAddonMessagePrefixRegistered(STEPS.commPrefix) then
		C_ChatInfo.RegisterAddonMessagePrefix(STEPS.commPrefix)
	end

	STEPS.addonMsg = STEPS.BuildAddonMessage()
	if IsInGuild() then
		C_ChatInfo.SendAddonMessage( STEPS.commPrefix, STEPS.addonMsg, "GUILD" )
	end
	if IsInGroup(LE_PARTY_CATEGORY_HOME) then
		C_ChatInfo.SendAddonMessage( STEPS.commPrefix, STEPS.addonMsg, "PARTY" )
	end
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
		C_ChatInfo.SendAddonMessage( STEPS.commPrefix, STEPS.addonMsg, "INSTANCE_CHAT" )
	end
	STEPS.totalC = math.floor( STEPS.mine.steps / 100 )
end
STEPS.LOADING_SCREEN_DISABLED = STEPS.SendMessages
STEPS.GROUP_ROSTER_UPDATE = STEPS.SendMessages
STEPS.INSTANCE_GROUP_SIZE_CHANGED = STEPS.SendMessages
function STEPS.CHAT_MSG_ADDON(...)
	self, prefix, message, distType, sender = ...
	-- STEPS.Print( "p:"..prefix.." m:"..message.." d:"..distType.." s:"..sender )
	if prefix == STEPS.commPrefix and sender ~= STEPS.name.."-"..STEPS.msgRealm then
		STEPS.DecodeMessage( message )
	end
end
function STEPS.BuildAddonMessage()
	STEPS.addonMsgTable = {}
	table.insert( STEPS.addonMsgTable, "v:"..STEPS_MSG_VERSION )
	table.insert( STEPS.addonMsgTable, "r:"..STEPS.realm )
	table.insert( STEPS.addonMsgTable, "n:"..STEPS.name )
	table.insert( STEPS.addonMsgTable, "s:"..math.ceil( STEPS.mine.steps ) )
	for dayBack=0,10 do
		dayStr = date("%Y%m%d", time() - (dayBack*86400) )
		if STEPS.mine[dayStr] then
			table.insert( STEPS.addonMsgTable, "t:"..dayStr.."<"..math.ceil(STEPS.mine[dayStr].steps) )
		end
	end
	return table.concat( STEPS.addonMsgTable, "," )
end
function STEPS.VersionStrToVal( verStr )
	local loc, _, major, minor, patch = string.find( verStr, "^(%d+)%.(%d+)%.*(%d*)" )
	return (loc and math.floor((major*10000)+(minor*100)+(patch and tonumber(patch) or 0)) or 0)
end
STEPS.keyFunctions = {
	v = function(val)
		STEPS.importVersion = val
		if not STEPS.versionAlerted and STEPS.VersionStrToVal(val) > STEPS.VersionStrToVal( STEPS_MSG_VERSION ) then
			STEPS.versionAlerted = true
			STEPS.Print(STEPS.L["A new version of Steps is available."])
		end
	end,
	r = function(val)
		STEPS.importRealm = val
	end,
	n = function(val)
		STEPS.importName = val
	end,
	s = function(val)
		if STEPS.importRealm and STEPS.importName then
			Steps_data[STEPS.importRealm] = Steps_data[STEPS.importRealm] or {}
			Steps_data[STEPS.importRealm][STEPS.importName] = Steps_data[STEPS.importRealm][STEPS.importName] or {}
			Steps_data[STEPS.importRealm][STEPS.importName].steps = tonumber(val)
			Steps_data[STEPS.importRealm][STEPS.importName].version = STEPS.importVersion
		end
	end,
	t = function(val)
		local loc, _, date, steps = string.find(val, "(.+)<(.+)")
		if loc and STEPS.importRealm and STEPS.importName then
			Steps_data[STEPS.importRealm] = Steps_data[STEPS.importRealm] or {}
			Steps_data[STEPS.importRealm][STEPS.importName] = Steps_data[STEPS.importRealm][STEPS.importName] or {}
			Steps_data[STEPS.importRealm][STEPS.importName][date] = { ["steps"] = tonumber(steps) }
		end
	end,
}
function STEPS.DecodeMessage( msgIn )
	for k,v in string.gmatch( msgIn, "(.):([^,]+)" ) do
		-- print(k.."-"..v)
		if STEPS.keyFunctions[k] then
			STEPS.keyFunctions[k](v)
		end
	end
	STEPS.importRealm, STEPS.importName = nil, nil
end

-- OnUpdate
function STEPS.OnUpdate()
	local nowTS = time()
	local dateStr = date("%Y%m%d")
	if not STEPS.mine[dateStr] then STEPS.mine[dateStr] = { ["steps"] = 0 } end
	if IsMounted() or IsFlying() then
		STEPS.isMoving = false
		STEPS.lastSpeed = 0
	else
		speed = GetUnitSpeed("player")
		if speed>0 and not STEPS.isMoving then
			STEPS.isMoving = true
			STEPS.lastSpeed = speed
		end
		if speed == 0 and STEPS.isMoving then
			STEPS.isMoving = false
			STEPS.lastSpeed = speed
		end
		if speed ~= STEPS.lastSpeed then
			STEPS.lastSpeed = speed
		end
		if nowTS ~= STEPS.lastUpdate then
			local newSteps = (STEPS.steps_per_second * speed)
			STEPS.mine.steps = STEPS.mine.steps + newSteps
			if not STEPS.mine[dateStr] then
				STEPS.min, STEPS.ave, STEPS.max = STEPS.CalcMinAveMax()
			end
			STEPS.mine[dateStr] = STEPS.mine[dateStr] or { ["steps"] = 0 }
			STEPS.mine[dateStr].steps = STEPS.mine[dateStr].steps + newSteps
		end
	end
	if Steps_options.show and nowTS ~= STEPS.lastUpdate then
		STEPS.max = math.floor( math.max( STEPS.max, STEPS.mine[dateStr].steps ) )
		Steps_StepBar_1:SetMinMaxValues( 0, STEPS.max )
		Steps_StepBar_2:SetMinMaxValues( 0, STEPS.max )
		if STEPS.mine[dateStr].steps > STEPS.ave then
			Steps_StepBar_1:SetValue( STEPS.ave )
			Steps_StepBar_1:SetStatusBarColor( 0, 0, 1, 1 )
			Steps_StepBar_2:SetValue( STEPS.mine[dateStr].steps )
			Steps_StepBar_2:SetStatusBarColor( unpack( STEPS.stepsColor ) )
		else
			Steps_StepBar_2:SetValue( STEPS.ave )
			Steps_StepBar_2:SetStatusBarColor( 0, 0, 1, 1 )
			Steps_StepBar_1:SetValue( STEPS.mine[dateStr].steps )
			Steps_StepBar_1:SetStatusBarColor( unpack( STEPS.stepsColor ) )
		end
		Steps_StepBar_1:Show()
		Steps_StepBar_2:Show()

		Steps_StepBarText:SetText( STEPS.L["Steps"]..": "..math.floor( STEPS.mine[dateStr].steps ).." ("..STEPS.ave..":"..STEPS.max..")" )
	end
	STEPS.lastUpdate = nowTS
	if math.floor( STEPS.mine.steps / 100 ) > STEPS.totalC then
		STEPS.LOADING_SCREEN_DISABLED()
	end
end
function STEPS.CalcMinAveMax()
	-- returns: min, ave, max
	local min, ave, max
	local sum, count = 0, 0
	local dateStr = date("%Y%m%d")
	for date, struct in pairs( STEPS.mine ) do
		if string.len(date) == 8 and date ~= dateStr then
			dSteps = struct.steps
			min = min and math.min(min, dSteps) or dSteps
			max = max and math.max(max, dSteps) or dSteps
			count = count + 1
			sum = sum + dSteps
		end
	end
	ave = count > 0 and sum / count or 0
	return (min and math.floor(min) or 0),
		   (ave and math.floor(ave) or 0),
		   (max and math.floor(max) or 0)
end
-- Support
function STEPS.Prune()
	local pruneTS = time() - ( STEPS.pruneDays * 86400 )
	for r, _ in pairs( Steps_data ) do
		local ncount = 0
		for n, _ in pairs( Steps_data[r] ) do
			local kcount = 0
			for k, _ in pairs( Steps_data[r][n] ) do
				if string.len(k) == 8 then
					local y = strsub( k, 1, 4 )
					local m = strsub( k, 5, 6 )
					local d = strsub( k, 7, 8 )
					local kts = time{ year=y, month=m, day=d }
					if kts < pruneTS then
						Steps_data[r][n][k] = nil
					else
						kcount = kcount + 1
					end
				end
			end
			if kcount == 0 then
				Steps_data[r][n] = nil
			else
				ncount = ncount + 1
			end
		end
		if ncount == 0 then
			Steps_data[r] = nil
		end
	end
end
function STEPS.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_GOLD..STEPS_MSG_ADDONNAME.."> "..COLOR_END..msg
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg )
end
function STEPS.ParseCmd(msg)
	if msg then
		msg = string.lower(msg)
		local a,b,c = strfind(msg, "(%S+)")  --contiguous string of non-space characters
		if a then
			-- c is the matched string, strsub is everything after that, skipping the space
			return c, strsub(msg, b+2)
		else
			return ""
		end
	end
end
function STEPS.Command( msg )
	local cmd, param = STEPS.ParseCmd(msg)
	if STEPS.commandList[cmd] and STEPS.commandList[cmd].alias then
		cmd = STEPS.commandList[cmd].alias
	end
	local cmdFunc = STEPS.commandList[cmd]
	if cmdFunc and cmdFunc.func then
		cmdFunc.func(param)
	else
		STEPS.PrintHelp()
	end
end
function STEPS.PrintHelp()
	STEPS.Print( string.format(STEPS.L["%s (%s) by %s"], STEPS_MSG_ADDONNAME, STEPS_MSG_VERSION, STEPS_MSG_AUTHOR ) )
	for cmd, info in pairs(STEPS.commandList) do
		if info.help then
			local cmdStr = cmd
			for c2, i2 in pairs(STEPS.commandList) do
				if i2.alias and i2.alias == cmd then
					cmdStr = string.format( "%s / %s", cmdStr, c2 )
				end
			end
			STEPS.Print(string.format("%s %s %s -> %s",
				SLASH_STEPS1, cmdStr, info.help[1], info.help[2]))
		end
	end
end
function STEPS.ChangeDisplay()
end
-- UI
function STEPS.OnDragStart()
	if Steps_options.unlocked then
		Steps_Frame:StartMoving()
	end
end
function STEPS.OnDragStop()
	Steps_Frame:StopMovingOrSizing()
end
function STEPS.UIReset()
	Steps_Frame:SetSize( 200, 12 )
	Steps_Frame:ClearAllPoints()
	Steps_Frame:SetPoint("BOTTOMLEFT", "$parent", "BOTTOMLEFT")
end
function STEPS.GetTodayTotal( name, realm )
	if name and Steps_data[realm] and Steps_data[realm][name] then
		for dayBack = -1,1 do
			local dateStr = date("%Y%m%d", time() + (dayBack*86400))
			if Steps_data[realm][name][dateStr] then
				today = Steps_data[realm][name][dateStr].steps
			end
		end
		return math.floor( today ), math.floor( Steps_data[realm][name].steps )
	end
end
-- Tooltip
function STEPS.TooltipSetUnit( arg1, arg2 )
	local name = GameTooltip:GetUnit()
	local realm = ""
	if UnitName( "mouseover" ) == name then
		_, realm = UnitName( "mouseover" )
		if not realm then
			realm = GetRealmName()
		end
	end
	today, total = STEPS.GetTodayTotal( name, realm )
	if today then
		GameTooltip:AddLine( "Steps today: "..today.." total: "..total )
	end
end
-- DropDownMenu
function STEPS.AddToDropDownMenu( frame, _, _, level )
	local clicked_frame
	if isElvUIInstalled or isShadowedUnitFrames then
		clicked_frame = frame.unit
	else
		if frame:GetParent() then
			clicked_frame = frame:GetParent().unit
		end
	end
	if clicked_frame and level == 1 then
		local name, realm = UnitName( clicked_frame )
		if not realm then
			realm = GetRealmName()
		end
		today, total = STEPS.GetTodayTotal( name, realm )
		if today then
			UIDropDownMenu_AddSeparator()
			local steps_info = UIDropDownMenu_CreateInfo()
			steps_info.notCheckable = true
			steps_info.isTitle = true
			steps_info.text = "Steps"
			UIDropDownMenu_AddButton( steps_info, 1 )
			steps_info.isTitle = false
			steps_info.text = "today: "..today.." total: "..total
			UIDropDownMenu_AddButton( steps_info, 1 )
		end
	end
end
hooksecurefunc( "UIDropDownMenu_Initialize", STEPS.AddToDropDownMenu )
STEPS.commandList = {
	[STEPS.L["help"]] = {
		["func"] = STEPS.PrintHelp,
		["help"] = {"",STEPS.L["Print this help."]}
	},
	[STEPS.L["show"]] = {
		["func"] = function() Steps_options.show = not Steps_options.show;
						if Steps_options.show then
							Steps_Frame:SetAlpha(1)
						else
							Steps_StepBar_1:Hide()
							Steps_StepBar_2:Hide()
							Steps_Frame:SetAlpha(0)
						end
					end,
		["help"] = {"", STEPS.L["Toggle display."]}
	},
	[STEPS.L["lock"]] = {
		["func"] = function() Steps_options.unlocked = not Steps_options.unlocked
						STEPS.Print( Steps_options.unlocked and STEPS.L["UI unlocked"] or STEPS.L["UI locked"] )
					end,
		["help"] = {"", STEPS.L["Toggle display lock."]}
	},
	[STEPS.L["reset"]] = {
		["func"] = STEPS.UIReset,
		["help"] = {"", "Reset the position of the UI"}
	},
	[STEPS.L["chat"]] = {
		["func"] = function() Steps_options.enableChat = not Steps_options.enableChat;
						if Steps_options.enableChat then
							if not STEPS.OriginalSendChatMessage then
								STEPS.InitChat()
							end
							STEPS.Print(STEPS.L["{steps} now enabled."])
						else
							STEPS.Print(STEPS.L["Please /reload to disable chat integration."])
						end
					end,
		["help"] = {"", STEPS.L["Toggle chat {steps} integration."]}
	}
	-- [STEPS.L["display"]] = {
	-- 	["func"] = STEPS.ChangeDisplay,
	-- 	["help"] = {"",STEPS.L["Cycle through display options."]}
	-- },
}


--[[
https://wowwiki-archive.fandom.com/wiki/API_GetUnitSpeed
value = GetUnitSpeed("unit")

Player unit moving at 100% -- value = 7
Player unit moving at 175% -- value = 12.25
Player unit moving at 200% -- value = 14

]]
