local input = matches[2]:trim()
local command, value = input:match("^(%S+)%s*(.*)$")

if command == "slow" then
  command = "speed"
  value = 1.0
elseif command == "fast" then
  command = "speed"
  value = 0.5
end

if command == "stop" then
  -- Stop the speedwalk
  local walking = Mapper.walking

  if not walking then
    cecho("<steel_blue>You are not walking.\n")
  else
    Mapper:ResetWalking()
    cecho("<steel_blue>Speedwalk stopped.\n")
  end
elseif command == "speed" then
  if value ~= "" then
    -- Set new speed (delay)
    Mapper:SetSpeedwalkDelay(value)
  else
    -- Check current speed (delay)
    if Mapper.config.speedwalk_delay == 1 then
      cecho("<steel_blue>Current walk speed is " .. Mapper.config.speedwalk_delay .. " second per step.\n")
    else
      cecho("<steel_blue>Current walk speed is " .. Mapper.config.speedwalk_delay .. " seconds per step.\n")
    end
  end
elseif command == "to" and tonumber(value) then
  local roomNumber = tonumber(value)
  local currentRoom = Mapper.info.current.room_id

  if currentRoom == roomNumber then
    cecho("<orange_red>You are already there.\n")
    return
  end

  local result, message = gotoRoom(roomNumber)

  -- Walk to a specific room number
  if not result then
    cecho("<orange_red>Error: Room " .. message .. "\n")
  end
else
  -- Print out the walk instructions
  cecho("<orange_red>Syntax: walk [stop|slow|fast|speed|speed <seconds>|to <room number>]\n")
end
