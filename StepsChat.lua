-- StepsChat.lua 2.0.8
function Steps.InitChat()
	Steps.OriginalSendChatMessage = SendChatMessage
	SendChatMessage = Steps.SendChatMessage
	Steps.OriginalBNSendWhisper = BNSendWhisper
	BNSendWhisper = Steps.BNSendWhisper
	Steps.commandList[""] = {
		["help"] = {Steps.L["{steps}"], Steps.L["Send steps to any chat"]},
	}
end
function Steps.ReplaceMessage( msgIn )
	-- search for and replace {FB}
	--print( "msgIn: "..msgIn )
	Steps.SendMessages()
	msgNew = nil
	local tokenStart, tokenEnd  = strfind( msgIn, "{[sS][tT][eE][pP][sS]*}" )
	if tokenStart then
		msgNew = string.sub( msgIn, 1, tokenStart-1 )..
				Steps.GetPostString()..
				string.sub( msgIn, tokenEnd+1 )
	end
	return( ( msgNew or msgIn ) )
end
function Steps.SendChatMessage( msgIn, system, language, channel )
	Steps.OriginalSendChatMessage( Steps.ReplaceMessage( msgIn ), system, language, channel )
	Steps.SendMessages()
end
function Steps.BNSendWhisper( id, msgIn )
	Steps.OriginalBNSendWhisper( id, Steps.ReplaceMessage( msgIn ) )
end
