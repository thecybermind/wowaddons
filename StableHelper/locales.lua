local addonName, ns = ...
ns.L = ns.L or {}
local L = ns.L

-- return key for default
setmetatable(L, {__index=function(L, key) return key end})
