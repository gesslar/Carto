local input = matches[2]:trim()
local command, value = input:match("^(%S+)%s*(.*)$")

raiseEvent("carto.config", command, value)
