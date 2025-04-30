local addonName, L = ... -- Let's use the private table passed to every .lua file to store our locale
L.L = {}
L.L["dow"] = { [0]="Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
L.L["mon"] = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
local function defaultFunc(L, key)
 -- If this function was called, we have no localization for this key.
 -- We could complain loudly to allow localizers to see the error of their ways,
 -- but, for now, just return the key as its own localization. This allows you to
 -- avoid writing the default localization out explicitly.
 return key
end
setmetatable(L.L, {__index=defaultFunc})
