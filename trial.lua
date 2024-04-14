function toBytes(num)
    -- returns a table of bits, most significant first.
    local t = {} -- will contain the bits
    local strOut = ""

    if num == 0 then
        t[1] = 128
        strOut = string.char(128)
    else
        while num > 0 do
            local byte = ( ( num & 0x7f ) | 0x80 )
            table.insert( t, byte )
            strOut = string.char( byte ) .. strOut
            num = num >> 7
        end
    end

    for _, v in ipairs(t) do
        print( string.format( "%d %d 0x%x", _, v, v ) )
    end

    return t, strOut
end


--[[
To avoid 0 values,

Enocde to 7 bits, with the 8th bit always being 1
(0000 0000  becomes 1000 0000)
Carry the 8th bit to the next byte

fromBytes( string.char( 0x81 )..string.char( 0xd3 )..string.char( 0xb4 )..string.char( 0x88 ) )

]]
function fromBytes( bytes )
    local num = 0

    for i = 1,#bytes do
        local b = string.byte( bytes, i )
        print( string.format( "%d 0x%x %d %d", i, b, b, #bytes-i))
        num = num << 7
        print( string.format( "<< 7: 0x%x + 0x%x", num, b & 0x7f ) )

        num = num + (b & 0x7f)
        print( string.format( "num: %d 0x%x", num, num ) )
    end

    return num
end

function d( str )
    outTable = {}
    k = 1
    for v in string.gmatch(str, "([^|]+)") do
        outTable[k] = v
        if k == 4 then
            outTable[k] = fromBytes(outTable[k])
        end
        if k >= 5 then
            outTable[k] = string.format( "%s%s", fromBytes(string.sub(outTable[k],1,4)), "" )
        end
        print( k, outTable[k] )
        k = k + 1
    end
    return outTable
end

