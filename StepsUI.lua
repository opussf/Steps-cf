STEPS_SLUG, Steps = ...

Steps.MineBars = {}
Steps.HistBars = {}
Steps.XAxis = {}

function Steps.ShowTrend()
	if StepsUI_Frame:IsVisible() then
		StepsUI_Frame:Hide()
		return
	end
	StepsUI_Frame:Show()

	Steps.ShowWeek()
end
function Steps.ShowWeek()
	if Steps.AssureBars( 7, 30 ) < 7 then
		StepsUI_Frame:Hide()
		return
	end
	local dayList = {}
	for dayBack = 1, 7 do
		table.insert( dayList, Steps.L["dow"][tonumber( date( "%w", time() + (dayBack*86400) ) ) ] )
	end
	if Steps.AssureXAxis( 7, 30, dayList ) < 7 then
		StepsUI_Frame:Hide()
		return
	end

	local barMax = 0
	local barData = {}    -- [%Y%m%d] = {mine, total}

	for dayBack=0, 6 do
		dayStr = date( "%Y%m%d", time() - (dayBack*86400) )
		outStr = "Looking at: "..dayStr.." dayBack:"..dayBack
		barData[dayStr] = {0,0}
		for r,ra in pairs( Steps_data ) do
			for n, na in pairs( ra ) do
				if na[dayStr] then
					barData[dayStr][2] = barData[dayStr][2] + na[dayStr].steps
					barMax = max( barMax, barData[dayStr][2] )
				end
			end
		end
		if Steps.mine[dayStr] then
			local steps = math.floor( Steps.mine[dayStr].steps )
			barMax = max( barMax, steps )
			barData[dayStr][1] = steps
			outStr = outStr .. " "..steps.."/"..barMax
		end
		if Steps.debug then Steps.Print( outStr ) end
	end
	for dayBack = 0, 6 do
		dayStr = date( "%Y%m%d", time() - (dayBack*86400) )
		Steps.MineBars[7-dayBack]:SetMinMaxValues( 0, barMax )
		Steps.MineBars[7-dayBack]:SetValue( math.floor( barData[dayStr][1] ) )
		Steps.HistBars[7-dayBack]:SetMinMaxValues( 0, barMax )
		Steps.HistBars[7-dayBack]:SetValue( math.floor( barData[dayStr][2] ) )
	end
end
function Steps.Show2Week()
	if Steps.AssureBars( 14, 15 ) < 7 then
		StepsUI_Frame:Hide()
		return
	end
	local dayList = {}
	for dayBack = 1, 14, 2 do
		table.insert( dayList, Steps.L["dow"][tonumber( date( "%w", time() + (dayBack*86400) ) ) ] )
	end
	if Steps.AssureXAxis( 7, 30, dayList ) < 7 then
		StepsUI_Frame:Hide()
		return
	end

	local barMax = 0
	local barData = {}    -- [%Y%m%d] = {mine, total}

	for dayBack = 0, 13 do
		dayStr = date( "%Y%m%d", time() - (dayBack*86400) )
		outStr = "Looking at: "..dayStr.." dayBack:"..dayBack
		barData[dayStr] = {0,0}
		for r,ra in pairs( Steps_data ) do
			for n,na in pairs( ra ) do
				if na[dayStr] then
					barData[dayStr][2] = barData[dayStr][2] + na[dayStr].steps
					barMax = max( barMax, barData[dayStr][2] )
				end
			end
		end
		if Steps.mine[dayStr] then
			local steps = math.floor( Steps.mine[dayStr].steps )
			barMax = max( barMax, steps )
			barData[dayStr][1] = steps
			outStr = outStr .. " "..steps.."/"..barMax
		end
		if Steps.debug then Steps.Print( outStr ) end
	end
	for dayBack = 0, 13 do
		dayStr = date( "%Y%m%d", time() - (dayBack*86400) )
		Steps.MineBars[14-dayBack]:SetMinMaxValues( 0, barMax )
		Steps.MineBars[14-dayBack]:SetValue( math.floor( barData[dayStr][1] ) )
		Steps.HistBars[14-dayBack]:SetMinMaxValues( 0, barMax )
		Steps.HistBars[14-dayBack]:SetValue( math.floor( barData[dayStr][2] ) )
	end
end
function Steps.ShowMonth()
	if Steps.AssureBars( 4, 52 ) < 4 then
		StepsUI_Frame:Hide()
		return
	end
	local barData = {}  -- [1] = {mine,all}
	local dayList = {}  -- [1] = {"mar ##","Apr 20"}
	local barMax = 0
	local i = 1
	for dayBack = 0, 34 do
		local dayStr = date( "%Y%m%d", time() - (dayBack*86400) )
		local dow = tonumber( date( "%w", time() - (dayBack*86400) ) )
		barData[i] = barData[i] or {0,0}

		for r,ra in pairs( Steps_data ) do
			for n,na in pairs( ra ) do
				if na[dayStr] then
					barData[i][2] = barData[i][2] + na[dayStr].steps
					barMax = max( barMax, barData[i][2] )
				end
			end
		end
		if Steps.mine[dayStr] then
			barData[i][1] = barData[i][1] + math.floor( Steps.mine[dayStr].steps )
			barMax = max( barMax, barData[i][1] )
		end
		if dow == 0 then
			table.insert( dayList, 1, date( "%d ", time() - (dayBack*86400) )..Steps.L["mon"][tonumber( date( "%m", time() - (dayBack*86400) ) ) ] )
			i = i + 1
		end
	end
	-- Steps.Print( "#barData: "..#barData.."  #dayList: "..#dayList )
	while #barData > 4 do table.remove(barData) end
	while #dayList > 4 do table.remove(dayList, 1) end

	-- for i = 1, 4 do
	-- 	print( dayList[5-i].." = {"..barData[i][1]..", "..barData[i][2].." }" )
	-- end
	if Steps.AssureXAxis( 4, 52, dayList ) < 4 then
		StepsUI_Frame:Hide()
		return
	end
	for i = 1, 4 do
		Steps.MineBars[5-i]:SetMinMaxValues( 0, barMax )
		Steps.MineBars[5-i]:SetValue( math.floor( barData[i][1] ) )
		Steps.HistBars[5-i]:SetMinMaxValues( 0, barMax )
		Steps.HistBars[5-i]:SetValue( math.floor( barData[i][2] ) )
	end
end
function Steps.Show2Month()
	if Steps.AssureBars( 8, 26 ) < 4 then
		StepsUI_Frame:Hide()
		return
	end
	local barData = {}  -- [1] = {mine,all}
	local dayList = {}  -- [1] = {"Apr 20"}
	local barMax = 0
	local i = 1
	for dayBack = 0, 59 do
		local dayStr = date( "%Y%m%d", time() - (dayBack*86400) )
		local dow = tonumber( date( "%w", time() - (dayBack*86400) ) )
		-- Steps.Print( i..":"..dayStr..":"..dow )
		barData[i] = barData[i] or {0,0}

		for r,ra in pairs( Steps_data ) do
			for n,na in pairs( ra ) do
				if na[dayStr] then
					barData[i][2] = barData[i][2] + na[dayStr].steps
					barMax = max( barMax, barData[i][2] )
				end
			end
		end
		if Steps.mine[dayStr] then
			barData[i][1] = barData[i][1] + math.floor( Steps.mine[dayStr].steps )
			barMax = max( barMax, barData[i][1] )
		end
		if dow == 0 then -- 0 = Sun
			if i%2 == 0 then
				table.insert( dayList, 1, string.sub( date( "%d", time() - (dayBack*86400) )..Steps.L["mon"][tonumber( date( "%m", time() - (dayBack*86400) ) ) ], 1, 3 ) )
			end
			i = i + 1
		end
	end
	-- Steps.Print( "#barData: "..#barData.."  #dayList: "..#dayList )
	while #barData > 8 do table.remove(barData ) end
	while #dayList > 8 do table.remove(dayList, 1) end
	-- for i = 1, 8 do
	-- 	print( i.." = {"..barData[i][1]..", "..barData[i][2].." }" )
	-- end
	if Steps.AssureXAxis( 4, 52.5, dayList ) < 4 then
		StepsUI_Frame:Hide()
		return
	end
	for i = 1, 8 do
		Steps.MineBars[9-i]:SetMinMaxValues( 0, barMax )
		Steps.MineBars[9-i]:SetValue( math.floor( barData[i][1] ) )
		Steps.HistBars[9-i]:SetMinMaxValues( 0, barMax )
		Steps.HistBars[9-i]:SetValue( math.floor( barData[i][2] ) )
	end
end
function Steps.Show3Month()
	if Steps.AssureBars( 12, 17.5 ) < 4 then
		StepsUI_Frame:Hide()
		return
	end
	local barData = {}  -- [1] = {mine,all}
	local dayList = {}  -- [1] = {"Apr 20"}
	local barMax = 0
	local i = 1
	for dayBack = 0, 91 do
		local dayStr = date( "%Y%m%d", time() - (dayBack*86400) )
		local dow = tonumber( date( "%w", time() - (dayBack*86400) ) )
		-- Steps.Print( i..":"..dayStr..":"..dow )
		barData[i] = barData[i] or {0,0}

		for r,ra in pairs( Steps_data ) do
			for n,na in pairs( ra ) do
				if na[dayStr] then
					barData[i][2] = barData[i][2] + na[dayStr].steps
					barMax = max( barMax, barData[i][2] )
				end
			end
		end
		if Steps.mine[dayStr] then
			barData[i][1] = barData[i][1] + math.floor( Steps.mine[dayStr].steps )
			barMax = max( barMax, barData[i][1] )
		end
		if dow == 0 then -- 0 = Sun
			if i%3 == 0 then
				table.insert( dayList, 1, string.sub( date( "%d", time() - (dayBack*86400) )..Steps.L["mon"][tonumber( date( "%m", time() - (dayBack*86400) ) ) ], 1, 3 ) )
			end
			i = i + 1
		end
	end
	-- Steps.Print( "#barData: "..#barData.."  #dayList: "..#dayList )
	while #barData > 12 do table.remove(barData ) end
	while #dayList > 12 do table.remove(dayList, 1) end
	-- for i = 1, 12 do
	-- 	print( i.." = {"..barData[i][1]..", "..barData[i][2].." }" )
	-- end
	if Steps.AssureXAxis( 4, 52.5, dayList ) < 4 then
		StepsUI_Frame:Hide()
		return
	end
	for i = 1, 12 do
		Steps.MineBars[13-i]:SetMinMaxValues( 0, barMax )
		Steps.MineBars[13-i]:SetValue( math.floor( barData[i][1] ) )
		Steps.HistBars[13-i]:SetMinMaxValues( 0, barMax )
		Steps.HistBars[13-i]:SetValue( math.floor( barData[i][2] ) )
	end
end
function Steps.AssureBars( barsNeeded, width )
	width = width or 30
	local count = #Steps.MineBars
	if( not InCombatLockdown() and barsNeeded > count  ) then
		if Steps.debug then Steps.Print( "I need "..barsNeeded.."/"..count.." bars." ) end
		for i = count+1, barsNeeded do
			if Steps.debug then Steps.Print( "Creating bar# "..i ) end
			local newBar = CreateFrame( "StatusBar", "Steps_MineBar"..i, StepsUI_BarFrame, "Steps_TrendBarTemplate" )  --template can be last parameter
			newBar:SetFrameStrata( "MEDIUM" )
			newBar:SetStatusBarColor( unpack( Steps.stepsColor ) )  -- Should be the gold color
			if( i == 1 ) then
				newBar:SetPoint( "TOPLEFT", "StepsUI_BarFrame", "TOPLEFT" )
			else
				newBar:SetPoint( "TOPLEFT", Steps.MineBars[i-1], "TOPRIGHT" )
			end
			Steps.MineBars[i] = newBar
			newBar = CreateFrame( "StatusBar", "Steps_HistBar"..i, StepsUI_BarFrame, "Steps_TrendBarTemplate" )
			newBar:SetFrameStrata( "LOW" )
			if( i == 1 ) then
				newBar:SetPoint( "TOPLEFT", "StepsUI_BarFrame", "TOPLEFT" )
			else
				newBar:SetPoint( "TOPLEFT", Steps.HistBars[i-1], "TOPRIGHT" )
			end
			Steps.HistBars[i] = newBar
		end
	end
	for i = 1, barsNeeded do
		Steps.MineBars[i]:Show()
		Steps.MineBars[i]:SetWidth( width )
		Steps.HistBars[i]:Show()
		Steps.HistBars[i]:SetWidth( width )
	end
	for i = barsNeeded+1, count do
		Steps.MineBars[i]:Hide()
		Steps.HistBars[i]:Hide()
	end
	return max( count, barsNeeded )
end
function Steps.AssureXAxis( needed, width, labels )
	local count = #Steps.XAxis
	if( not InCombatLockdown() and needed > count ) then
		if Steps.debug then Steps.Print( "I need "..needed.."/"..count.." XAxis." ) end
		local dayIndex = 1
		for i = count+1, needed do
			if Steps.debug then Steps.Print( "Creating XAxis# "..i ) end
			local newButton = CreateFrame( "Button", "Steps_XAxis"..i, StepsUI_Frame, "Steps_XAxisButtonTemplate" )
			newButton:SetSize( width, 20 )
			if( i == 1 ) then
				newButton:SetPoint( "BOTTOMLEFT", "StepsUI_Frame", "BOTTOMLEFT" )
			else
				newButton:SetPoint( "BOTTOMLEFT", Steps.XAxis[i-1], "BOTTOMRIGHT" )
			end
			newButton:SetText( labels[dayIndex] )
			dayIndex = dayIndex + 1
			Steps.XAxis[i] = newButton
		end
	end
	for i = 1, needed do
		Steps.XAxis[i]:SetSize( width, 20 )
		Steps.XAxis[i]:SetText( labels[i] )
		Steps.XAxis[i]:Show()
	end
	for i = needed+1, count do
		Steps.XAxis[i]:Hide()
	end
	return max( count, needed )
end