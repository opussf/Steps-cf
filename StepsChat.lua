-- StepsChat.lua 1.10

function STEPS.InitChat()
	STEPS.OriginalSendChatMessage = SendChatMessage
	SendChatMessage = STEPS.SendChatMessage
	STEPS.OriginalBNSendWhisper = BNSendWhisper
	BNSendWhisper = STEPS.BNSendWhisper
	STEPS.commandList[""] = {
		["help"] = {STEPS.L["{steps}"], STEPS.L["Send steps to any chat"]},
	}
end
function STEPS.ReplaceMessage( msgIn )
	-- search for and replace {FB}
	--print( "msgIn: "..msgIn )
	STEPS.SendMessages()
	msgNew = nil
	local tokenStart, tokenEnd  = strfind( msgIn, "{[sS][tT][eE][pP][sS]*}" )
	if tokenStart then
		--print( "tokenStart: "..tokenStart )
		--print( "tokenEnd: "..tokenEnd )
		--print( "index: "..index )
		local dateStr = date("%Y%m%d")
		local stepsStr = string.format("%s: %i", STEPS.L["My steps today"], math.floor( STEPS.mine[dateStr].steps or "0" ) )
		msgNew = string.sub( msgIn, 1, tokenStart-1 )..
				stepsStr..
				string.sub( msgIn, tokenEnd+1 )
	end
	return( ( msgNew or msgIn ) )
end
function STEPS.SendChatMessage( msgIn, system, language, channel )
	STEPS.OriginalSendChatMessage( STEPS.ReplaceMessage( msgIn ), system, language, channel )
end
function STEPS.BNSendWhisper( id, msgIn )
	STEPS.OriginalBNSendWhisper( id, STEPS.ReplaceMessage( msgIn ) )
end
