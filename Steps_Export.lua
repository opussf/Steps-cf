#!/usr/bin/env lua

accountPath = arg[1]
exportType = arg[2]

pathSeparator = string.sub(package.config, 1, 1) -- first character of this string (http://www.lua.org/manual/5.2/manual.html#pdf-package.config)
-- remove 'extra' separators from the end of the given path
while (string.sub( accountPath, -1, -1 ) == pathSeparator) do
	accountPath = string.sub( accountPath, 1, -2 )
end
-- append the expected location of the datafile
dataFilePath = {
	accountPath,
	"SavedVariables",
	"Steps.lua"
}
dataFile = table.concat( dataFilePath, pathSeparator )

function FileExists( name )
	local f = io.open( name, "r" )
	if f then io.close( f ) return true else return false end
end
function DoFile( filename )
	local f = assert( loadfile( filename ) )
	return f()
end
function ExportXML()
	strOut = "<?xml version='1.0' encoding='utf-8' ?>\n"
	strOut = strOut .. "<steps>\n"

	for realm, chars in sorted_pairs( Steps_data ) do
		for name, c in sorted_pairs( chars ) do
			strOut = strOut .. string.format( "<char realm=\"%s\" name=\"%s\" steps=\"%s\">\n", realm, name, math.ceil( c.steps ) )
			for date, dateStruct in pairs( c ) do
				if string.len(date) == 8 then
					strOut = strOut .. string.format( "\t<day date=\"%s-%s-%s\" steps=\"%s\"/>\n", string.sub(date,1,4), string.sub(date,5,6), string.sub(date,7,8), math.ceil( dateStruct.steps ) )
				end
			end
			strOut = strOut .. "</char>\n"
		end
	end

	strOut = strOut .. "</steps>\n"
	return strOut
end
function ExportJSON()
	strOut = "{\"steps\": [\n"

	charsOut = {}
	for realm, chars in sorted_pairs( Steps_data ) do
		for name, c in sorted_pairs( chars ) do
			charOut = {}
			table.insert( charOut, string.format( "\t{\"realm\":\"%s\", \"name\":\"%s\", \"steps\":%s, \"days\":[", realm, name, math.ceil( c.steps ) ) )
			days = {}
			for date, dateStruct in pairs( c ) do
				if string.len(date) == 8 then
					table.insert( days, string.format( "\t\t{\"date\":\"%s-%s-%s\", \"steps\":%s}", string.sub(date,1,4), string.sub(date,5,6), string.sub(date,7,8), math.ceil( dateStruct.steps ) ) )
				end
			end
			table.insert( charOut, table.concat( days, ",\n" ) .. "]}" )
			table.insert( charsOut, table.concat( charOut, "\n" ) )
		end
	end

	strOut = strOut .. table.concat( charsOut, ",\n" ) .. "\n]}"

	return strOut
end
function sorted_pairs( tableIn )
	local keys = {}
	for k in pairs( tableIn ) do table.insert( keys, k ) end
	table.sort( keys )
	local lcv = 0
	local iter = function()
		lcv = lcv + 1
		if keys[lcv] == nil then return nil
		else return keys[lcv], tableIn[keys[lcv]]
		end
	end
	return iter
end

functionList = {
	["xml"] = ExportXML,
	["json"] = ExportJSON
}

func = functionList[string.lower( exportType )]

if dataFile and FileExists( dataFile ) and exportType and func then
	DoFile( dataFile )
	strOut = func()
	print( strOut )
else
	io.stderr:write( "Something is wrong.  Lets review:\n")
	io.stderr:write( "Data file provided: "..( dataFile and " True" or "False" ).."\n" )
	io.stderr:write( "Data file exists  : "..( FileExists( dataFile ) and " True" or "False" ).."\n" )
	io.stderr:write( "ExportType given  : "..( exportType and " True" or "False" ).."\n" )
	io.stderr:write( "ExportType valid  : "..( func and " True" or "False" ).."\n" )
end


