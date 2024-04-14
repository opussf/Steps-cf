-- StepsChat.lua 2.0.1

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
		msgNew = string.sub( msgIn, 1, tokenStart-1 )..
				STEPS.GetPostString()..
				string.sub( msgIn, tokenEnd+1 )
	end
	return( ( msgNew or msgIn ) )
end
function STEPS.SendChatMessage( msgIn, system, language, channel )
	STEPS.OriginalSendChatMessage( STEPS.ReplaceMessage( msgIn ), system, language, channel )
	STEPS.SendMessages()
end
function STEPS.BNSendWhisper( id, msgIn )
	STEPS.OriginalBNSendWhisper( id, STEPS.ReplaceMessage( msgIn ) )
end
