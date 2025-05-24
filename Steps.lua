-- Steps 2.1.5
STEPS_SLUG, Steps   = ...
STEPS_MSG_ADDONNAME = C_AddOns.GetAddOnMetadata( STEPS_SLUG, "Title" )
STEPS_MSG_VERSION   = C_AddOns.GetAddOnMetadata( STEPS_SLUG, "Version" )
STEPS_MSG_AUTHOR    = C_AddOns.GetAddOnMetadata( STEPS_SLUG, "Author" )

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
Steps.steps_per_second = 2/7  -- 2 steps at speed 7
Steps.pruneDays = 91
Steps.min = 0
Steps.ave = 0
Steps.max = 0
Steps.commPrefix = "STEPS"
Steps.stepsColor = { 0.73, 0.52, 0.18, 1 }
Steps.say = string.lower(_G["SAY"])
Steps.guild = string.lower(_G["GUILD"])
Steps.instance = string.lower(_G["INSTANCE"])
Steps.party = string.lower(_G["PARTY"])
Steps.raid = string.lower(_G["RAID"])
Steps.whisper = string.lower(_G["WHISPER"])
Steps.yell = string.lower(_G["YELL"])

-- Setup
function Steps.OnLoad()
	SLASH_STEPS1 = "/"..Steps.L["Steps"]
	SlashCmdList["STEPS"] = function(msg) Steps.Command(msg) end
	Steps.lastSpeed = 0
	Steps_Frame:RegisterEvent( "ADDON_LOADED" )
	Steps_Frame:RegisterEvent( "VARIABLES_LOADED" )
	Steps_Frame:RegisterEvent( "LOADING_SCREEN_DISABLED" )
	Steps_Frame:RegisterEvent( "CHAT_MSG_ADDON" )
	Steps_Frame:RegisterEvent( "GROUP_ROSTER_UPDATE" )
	Steps_Frame:RegisterEvent( "INSTANCE_GROUP_SIZE_CHANGED" )
end
function Steps.ADDON_LOADED()
	Steps_Frame:UnregisterEvent( "ADDON_LOADED" )
	Steps.name = UnitName("player")
	Steps.realm = GetRealmName()
	Steps.msgRealm = string.gsub( Steps.realm, " ", "" )
	TooltipDataProcessor.AddTooltipPostCall( Enum.TooltipDataType.Unit, Steps.TooltipSetUnit )
end
function Steps.VARIABLES_LOADED()
	-- Unregister the event for this method.
	Steps_Frame:UnregisterEvent( "VARIABLES_LOADED" )

	Steps_data[Steps.realm] = Steps_data[Steps.realm] or {}
	Steps_data[Steps.realm][Steps.name] = Steps_data[Steps.realm][Steps.name] or { ["steps"] = 0 }
	Steps.mine = Steps_data[Steps.realm][Steps.name]
	Steps.mine[date("%Y%m%d")] = Steps.mine[date("%Y%m%d")] or { ["steps"] = 0 }
	Steps.min, Steps.ave, Steps.max = Steps.CalcMinAveMax()
	Steps.totalC = math.floor( Steps.mine.steps / 100 )
	Steps.Prune()
	if Steps_options.show then
		Steps_Frame:SetAlpha(1)
	else
		Steps_Frame:SetAlpha(0)
	end
	if Steps_options.enableChat then
		Steps.InitChat()
	end
end
function Steps.SendMessages()
	if not C_ChatInfo.IsAddonMessagePrefixRegistered(Steps.commPrefix) then
		C_ChatInfo.RegisterAddonMessagePrefix(Steps.commPrefix)
	end

	Steps.addonMsg = Steps.BuildAddonMessage2()
	if IsInGuild() then
		C_ChatInfo.SendAddonMessage( Steps.commPrefix, Steps.addonMsg, "GUILD" )
	end
	if IsInGroup(LE_PARTY_CATEGORY_HOME) then
		C_ChatInfo.SendAddonMessage( Steps.commPrefix, Steps.addonMsg, "PARTY" )
	end
	if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
		C_ChatInfo.SendAddonMessage( Steps.commPrefix, Steps.addonMsg, "INSTANCE_CHAT" )
	end
	Steps.totalC = math.floor( Steps.mine.steps / 100 )
end
function Steps.LOADING_SCREEN_DISABLED()
	Steps.SendMessages()
end
function Steps.GROUP_ROSTER_UPDATE()
	Steps.SendMessages()
end
function Steps.INSTANCE_GROUP_SIZE_CHANGED()
	Steps.SendMessages()
end
function Steps.CHAT_MSG_ADDON(...)
	local prefix, message, distType, sender = ...
	if Steps.debug and prefix == Steps.commPrefix then print( "msg< p:"..prefix.." m:"..message.." d:"..distType.." s:"..sender ) end
	if prefix == Steps.commPrefix and sender ~= Steps.name.."-"..Steps.msgRealm then
		if string.find(message, "v:") then
			Steps.DecodeMessage( message )
		else
			Steps.DecodeMessage2( message )
		end
	end
end
function Steps.toBytes(num)
	-- print( "toBytes( "..num.." )" )
	-- returns a table and string of bytes.  MSB first
	local t = {} -- will contain the bits
	local strOut
	if num == 0 then
		t[1] = 128
		strOut = string.char(128)
	else
		strOut = ""
		while num > 0 do
			local byte = bit.bor( bit.band( num, 0x7f ), 0x80 )
			table.insert( t, 1, byte )
			strOut = string.char( byte ) .. strOut
			num = bit.rshift( num, 7 )
		end
	end
	return t, strOut
end
function Steps.fromBytes( bytes )
	local num = 0

	for i = 1,#bytes do
		local b = string.byte( bytes, i )
		num = bit.lshift(num, 7) + bit.band( b, 0x7f )
	end

	return num
end
function Steps.BuildAddonMessage2()
	local prefixLen = string.len( Steps.commPrefix ) + 1
	local msgStr = string.format("%s|%s|%s|%s",
			STEPS_MSG_VERSION, Steps.realm, Steps.name, select(2, Steps.toBytes( math.ceil( Steps.mine.steps ) ) )
	)
	for dayBack=0,Steps.pruneDays do
		dayStr = date("%Y%m%d", time() - (dayBack*86400) )
		if Steps.mine[dayStr] and Steps.mine[dayStr].steps > 0 then
			local daySteps = string.format("%s%s",
					select(2, Steps.toBytes( tonumber( dayStr ) ) ),
					select(2, Steps.toBytes( math.ceil( Steps.mine[dayStr].steps ) ) )
			)
			if ( prefixLen + string.len( msgStr ) + string.len( daySteps ) + 1 >= 255 ) then
				break
			end
			msgStr = msgStr .. "|" .. daySteps
		end
	end
	return msgStr
end
function Steps.BuildAddonMessage()
	Steps.addonMsgTable = {}
	table.insert( Steps.addonMsgTable, "v:"..STEPS_MSG_VERSION )
	table.insert( Steps.addonMsgTable, "r:"..Steps.realm )
	table.insert( Steps.addonMsgTable, "n:"..Steps.name )
	table.insert( Steps.addonMsgTable, "s:"..math.ceil( Steps.mine.steps ) )
	for dayBack=0,10 do
		dayStr = date("%Y%m%d", time() - (dayBack*86400) )
		if Steps.mine[dayStr] then
			table.insert( Steps.addonMsgTable, "t:"..dayStr.."<"..math.ceil(Steps.mine[dayStr].steps) )
		end
	end
	return table.concat( Steps.addonMsgTable, "," )
end
function Steps.VersionStrToVal( verStr )
	local loc, _, major, minor, patch = string.find( verStr, "^(%d+)%.(%d+)%.*(%d*)" )
	return (loc and math.floor((major*10000)+(minor*100)+(patch and tonumber(patch) or 0)) or 0)
end
Steps.keyFunctions = {
	v = function(val)
		Steps.importVersion = val
		if not Steps.versionAlerted and Steps.VersionStrToVal(val) > Steps.VersionStrToVal( STEPS_MSG_VERSION ) then
			Steps.versionAlerted = true
			Steps.Print(Steps.L["A new version of Steps is available."])
		end
	end,
	r = function(val)
		Steps.importRealm = val
	end,
	n = function(val)
		Steps.importName = val
	end,
	s = function(val)
		if Steps.importRealm and Steps.importName then
			Steps_data[Steps.importRealm] = Steps_data[Steps.importRealm] or {}
			Steps_data[Steps.importRealm][Steps.importName] = Steps_data[Steps.importRealm][Steps.importName] or {}
			Steps_data[Steps.importRealm][Steps.importName].steps = tonumber(val)
			Steps_data[Steps.importRealm][Steps.importName].version = Steps.importVersion
		end
	end,
	t = function(val)
		local loc, _, date, steps = string.find(val, "(.+)<(.+)")
		if loc and Steps.importRealm and Steps.importName then
			Steps_data[Steps.importRealm] = Steps_data[Steps.importRealm] or {}
			Steps_data[Steps.importRealm][Steps.importName] = Steps_data[Steps.importRealm][Steps.importName] or {}
			Steps_data[Steps.importRealm][Steps.importName][date] = { ["steps"] = tonumber(steps) }
		end
	end,
	s2 = function(val)
		Steps.keyFunctions.s( Steps.fromBytes( val ) )
	end,
	t2 = function(val)
		Steps.keyFunctions.t( string.format( "%d<%d",
				Steps.fromBytes( string.sub( val, 1, 4 ) ), Steps.fromBytes( string.sub( val, 5, -1 ) )
		) )
	end,
}
function Steps.DecodeMessage( msgIn )
	if Steps.debug then print( "Decode( "..msgIn.." )" ) end
	for k,v in string.gmatch( msgIn, "(.):([^,]+)" ) do
		if Steps.keyFunctions[k] then
			Steps.keyFunctions[k](v)
		end
	end
	Steps.importRealm, Steps.importName = nil, nil
end
Steps.keyMap = { "v", "r", "n", "s2" }
function Steps.DecodeMessage2( msgIn )
	if Steps.debug then print( "Decode2( "..msgIn.." )" ) end
	local decodeTable = {}
	k = 1
	for v in string.gmatch( msgIn, "([^|]+)" ) do
		if k <= #Steps.keyMap then
			Steps.keyFunctions[Steps.keyMap[k]](v)
		else
			Steps.keyFunctions.t2(v)
		end
		k = k + 1
	end
	Steps.importRealm, Steps.importName = nil, nil
end

-- OnUpdate
function Steps.OnUpdate()
	local nowTS = time()
	local dateStr = date("%Y%m%d")
	if not Steps.mine[dateStr] then Steps.mine[dateStr] = { ["steps"] = 0 } end
	if IsMounted() or IsFlying() then
		Steps.isMoving = false
		Steps.lastSpeed = 0
	else
		speed = GetUnitSpeed("player")
		if speed>0 and not Steps.isMoving then
			Steps.isMoving = true
			Steps.lastSpeed = speed
		end
		if speed == 0 and Steps.isMoving then
			Steps.isMoving = false
			Steps.lastSpeed = speed
		end
		if speed ~= Steps.lastSpeed then
			Steps.lastSpeed = speed
		end
		if nowTS ~= Steps.lastUpdate then
			local newSteps = (Steps.steps_per_second * speed)
			Steps.mine.steps = Steps.mine.steps + newSteps
			if not Steps.mine[dateStr] then
				Steps.min, Steps.ave, Steps.max = Steps.CalcMinAveMax()
			end
			Steps.mine[dateStr] = Steps.mine[dateStr] or { ["steps"] = 0 }
			Steps.mine[dateStr].steps = Steps.mine[dateStr].steps + newSteps
		end
	end
	if Steps_options.show and nowTS ~= Steps.lastUpdate then
		Steps.max = math.floor( math.max( Steps.max, Steps.mine[dateStr].steps ) )
		Steps_StepBar_1:SetMinMaxValues( 0, Steps.max )
		Steps_StepBar_2:SetMinMaxValues( 0, Steps.max )
		if Steps.mine[dateStr].steps > Steps.ave then
			Steps_StepBar_1:SetValue( Steps.ave )
			Steps_StepBar_1:SetStatusBarColor( 0, 0, 1, 1 )
			Steps_StepBar_2:SetValue( Steps.mine[dateStr].steps )
			Steps_StepBar_2:SetStatusBarColor( unpack( Steps.stepsColor ) )
		else
			Steps_StepBar_2:SetValue( Steps.ave )
			Steps_StepBar_2:SetStatusBarColor( 0, 0, 1, 1 )
			Steps_StepBar_1:SetValue( Steps.mine[dateStr].steps )
			Steps_StepBar_1:SetStatusBarColor( unpack( Steps.stepsColor ) )
		end
		Steps_StepBar_1:Show()
		Steps_StepBar_2:Show()

		Steps_StepBarText:SetText( Steps.L["Steps"]..": "..math.floor( Steps.mine[dateStr].steps ).." ("..Steps.ave..":"..Steps.max..")" )
	end
	Steps.lastUpdate = nowTS
	if math.floor( Steps.mine.steps / 100 ) > Steps.totalC then
		Steps.SendMessages()
	end
end
function Steps.CalcMinAveMax()
	-- returns: min, ave, max
	local min, ave, max
	local sum, count = 0, 0
	local dateStr = date("%Y%m%d")
	for date, struct in pairs( Steps.mine ) do
		if string.len(date) == 8 and date ~= dateStr and struct.steps > 0 then
			local dSteps = struct.steps
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
function Steps.Prune()
	local pruneTS = time() - ( Steps.pruneDays * 86400 )
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
function Steps.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_GOLD..STEPS_MSG_ADDONNAME.."> "..COLOR_END..msg
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg )
end
function Steps.ParseCmd(msg)
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
function Steps.Command( msg )
	local cmd, param = Steps.ParseCmd(msg)
	if Steps.commandList[cmd] and Steps.commandList[cmd].alias then
		cmd = Steps.commandList[cmd].alias
	end
	local cmdFunc = Steps.commandList[cmd]
	if cmdFunc and cmdFunc.func then
		cmdFunc.func(param)
	else
		Steps.PrintHelp()
	end
end
function Steps.PrintHelp()
	Steps.Print( string.format(Steps.L["%s (%s) by %s"], STEPS_MSG_ADDONNAME, STEPS_MSG_VERSION, STEPS_MSG_AUTHOR ) )
	for cmd, info in pairs(Steps.commandList) do
		if info.help then
			local cmdStr = cmd
			for c2, i2 in pairs(Steps.commandList) do
				if i2.alias and i2.alias == cmd then
					cmdStr = string.format( "%s / %s", cmdStr, c2 )
				end
			end
			Steps.Print(string.format("%s %s %s -> %s",
				SLASH_STEPS1, cmdStr, info.help[1], info.help[2]))
		end
	end
end
-- function Steps.ChangeDisplay()
-- end
-- UI
function Steps.OnDragStart()
	if Steps_options.unlocked then
		Steps_Frame:StartMoving()
	end
end
function Steps.OnDragStop()
	if Steps_options.unlocked then
		Steps_Frame:StopMovingOrSizing()
	else
		Steps.ShowTrend()
	end
end
function Steps.UIReset()
	Steps_Frame:SetSize( 200, 12 )
	Steps_Frame:ClearAllPoints()
	Steps_Frame:SetPoint("BOTTOMLEFT", "$parent", "BOTTOMLEFT")
end
function Steps.DeNormalizeRealm( realm )
	local realmOut = ""
	for s in string.gmatch( realm, "(.)" ) do
		if string.find( s, "[A-Z]" ) then
			s = " "..s
		end
		realmOut = realmOut..s
	end
	b = string.find( realmOut, "of " )
	if b then
		realmOut = string.sub( realmOut, 1, b-1 ).." "..string.sub( realmOut, b, -1 )
	end
	return string.sub( realmOut, 2, -1 )
end
function Steps.GetTodayTotal( name, realm )
	local today = 0
	if name and Steps_data[realm] and Steps_data[realm][name] then
		for dayBack = -1,1 do
			local dateStr = date("%Y%m%d", time() + (dayBack*86400))
			if Steps_data[realm][name][dateStr] then
				today = Steps_data[realm][name][dateStr].steps
			end
		end
		return math.floor( today or 0 ), math.floor( Steps_data[realm][name].steps or 0 )
	end
end
-- Tooltip
function Steps.TooltipSetUnit( arg1, arg2 )
	local name = GameTooltip:GetUnit()
	local realm = ""
	if UnitName( "mouseover" ) == name then
		_, realm = UnitName( "mouseover" )
		if not realm then
			realm = GetRealmName()
		end
	end
	local today, total = Steps.GetTodayTotal( name, realm )
	if Steps.debug then print( name, realm, today, total ) end
	if today then
		GameTooltip:AddLine( Steps.L["Steps today"]..": "..today.." "..Steps.L["total"]..": "..total )
	end
end
-- DropDownMenu
function Steps.ModifyMenu( owner, rootDescription, contextData )
	if Steps.debug then print( owner, rootDescription, contextData ) end
	local today, total = Steps.GetTodayTotal( contextData.name, (contextData.server and Steps.DeNormalizeRealm( contextData.server ) or GetRealmName()) )
	if today then
		rootDescription:CreateDivider()
		rootDescription:CreateTitle( Steps.L["Steps today"]..": "..today.." "..Steps.L["total"]..": "..total )
	end
end
Menu.ModifyMenu("MENU_UNIT_SELF", Steps.ModifyMenu)
Menu.ModifyMenu("MENU_UNIT_COMMUNITIES_GUILD_MEMBER", Steps.ModifyMenu)
Menu.ModifyMenu("MENU_UNIT_PARTY", Steps.ModifyMenu)
Menu.ModifyMenu("MENU_UNIT_RAID", Steps.ModifyMenu)
-- Post
function Steps.GetPostString()
	local dateStr = date("%Y%m%d")
	return string.format("%s: %i", Steps.L["My steps today"], math.floor( Steps.mine[dateStr].steps or "0" ) )
end
function Steps.Post( param )
	local chatChannel, toWhom
	if( param ) then
		if( param == "say" ) then
			chatChannel = "SAY"
		elseif( param == "yell") then
			chatChannel = "YELL"
		elseif( param == "guild" and IsInGuild() ) then
			chatChannel = "GUILD"
		elseif( param == "party" and IsInGroup( LE_PARTY_CATEGORY_HOME ) ) then
			chatChannel = "PARTY"
		elseif( param == "instance" and IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) ) then
			chatChannel = "INSTANCE_CHAT"
		elseif( param == "instance" and IsInGroup( LE_PARTY_CATEGORY_HOME ) ) then
			chatChannel = "PARTY"
		elseif( param == 'raid' and IsInRaid() ) then
			chatChannel = "RAID"
		elseif( param ~= "" ) then
			chatChannel = "WHISPER"
			toWhom = param
		end

		if( chatChannel ) then
			SendChatMessage( Steps.GetPostString(), chatChannel, nil, toWhom )  -- toWhom will be nil for most
			Steps.SendMessages()
		end
	end
end
function Steps.UpdateBars()
	if Steps_options.show then
		Steps_Frame:SetAlpha(1)
	else
		Steps_StepBar_1:Hide()
		Steps_StepBar_2:Hide()
		Steps_Frame:SetAlpha(0)
	end
end

Steps.commandList = {
	[Steps.L["help"]] = {
		["func"] = Steps.PrintHelp,
		["help"] = {"",Steps.L["Print this help."]}
	},
	[Steps.L["show"]] = {
		["func"] = function() Steps_options.show = not Steps_options.show; Steps.UpdateBars(); end,
		["help"] = {"", Steps.L["Toggle display."]}
	},
	[Steps.L["lock"]] = {
		["func"] = function() Steps_options.unlocked = not Steps_options.unlocked
						Steps.Print( Steps_options.unlocked and Steps.L["UI unlocked"] or Steps.L["UI locked"] )
					end,
		["help"] = {"", Steps.L["Toggle display lock."]}
	},
	[Steps.L["reset"]] = {
		["func"] = Steps.UIReset,
		["help"] = {"", Steps.L["Reset the position of the UI"]}
	},
	[Steps.L["chat"]] = {
		["func"] = function() Steps_options.enableChat = not Steps_options.enableChat;
						if Steps_options.enableChat then
							if not Steps.OriginalSendChatMessage then
								Steps.InitChat()
							end
							Steps.Print(Steps.L["{steps} now enabled."])
						else
							Steps.Print(Steps.L["Please /reload to disable chat integration."])
						end
					end,
		["help"] = {"", Steps.L["Toggle chat {steps} integration."]}
	},
	[Steps.say] = { ["alias"] = "say" },
	["say"] = {
		["func"] = function() Steps.Post("say") end,
		["help"] = { "| guild | party | instance | raid | whisper <playerName>", "Post steps report to channel or player."}
	},
	[Steps.yell] = { ["alias"] = "yell" },
	["yell"] = {
		["func"] = function() Steps.Post("yell") end,
	},
	[Steps.guild] = { ["alias"] = "guild" },
	["guild"] = {
		["func"] = function() Steps.Post("guild") end,
	},
	[Steps.party] = { ["alias"] = "party" },
	["party"] = {
		["func"] = function() Steps.Post("party") end,
	},
	[Steps.instance] = { ["alias"] = "instance" },
	["instance"] = {
		["func"] = function() Steps.Post("instance") end,
	},
	[Steps.raid] = { ["alias"] = "raid" },
	["raid"] = {
		["func"] = function() Steps.Post("raid") end,
	},
	[Steps.whisper] = { ["alias"] = "whisper" },
	["whisper"] = {
		["func"] = function(target) Steps.Post(target) end,
	},
	[Steps.L["trend"]] = {
		["func"] = function() Steps.ShowTrend() end,
	},
	["debug"] = {
		["func"] = function() Steps.debug = not Steps.debug; Steps.Print( "Debug is "..(Steps.debug and "On" or "Off") ) end
	},
	-- [Steps.L["display"]] = {
	-- 	["func"] = Steps.ChangeDisplay,
	-- 	["help"] = {"",Steps.L["Cycle through display options."]}
	-- },
}
