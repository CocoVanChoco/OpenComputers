local component = require("component")
local rs = component.redstone
local sides = require("sides")
local shell = require("shell")

local args, options = shell.parse(...)

local act
local getSlotSize

local s_act_extractor = sides.right
local s_rs_clutch = sides.up
local min_process = 5

local have_ecu = component.isAvailable("EngineControlUnit")

if (component.isAvailable("transposer")) then
  act = component.transposer
  getSlotSize = function(i) return component.transposer.getSlotStackSize(s_act_extractor, i) end
elseif (component.isAvailable("inventory_controller")) then
  act = component.inventory_controller
  getSlotSize = function(i) return component.inventory_controller.getSlotStackSize(s_act_extractor, i) end
else
  getSlotSize = function(i)
    a,b,c,d = component.Extractor.getSlot(i-1)
    if (c==nil) then return 0 end
    return c
  end
end

if (#args > 0) then
  if (args[1] == "off") then
    if (have_ecu) then
      component.EngineControlUnit.setECU(0)
    else
      print("No ECU available!")
    end
    os.exit()
  end
end

local x = 0

local old_step = 0
local old_size = 0

-- EngineControlUnit.setECU(0) -> 4
while true do
  local signal = 2
  local s = {}
  
  s[1] = getSlotSize(1)
  s[2] = getSlotSize(2) + getSlotSize(5)
  s[3] = getSlotSize(3) + getSlotSize(6)
  s[4] = getSlotSize(4) + getSlotSize(7)
  
  local max = s[4]
  local current_step = 4
  
  if (s[3] > max) then
    max = s[3]
    current_step = 3
  end
  if (s[2] > max) then
    max = s[2]
    current_step = 2
  end
  if (s[1] > max) then
    max = s[1]
    current_step = 1
  end
  
  if (max < 64) then
    if ((old_step > 0) and (current_step ~= old_step) and (s[old_step]>0) and ((s[old_step] + min_process)>old_size)) then
      current_step = old_step
    end
  end
  
  if (current_step == 4) then
    signal = 2
  elseif (current_step == 1) then
    signal = 0
  else
    signal = 1
  end
  
  if ((max > 0) and (getSlotSize(8) < 64) and (getSlotSize(9) < 64)) then
    if (x==0) then
      x = os.time()
    end
    if (current_step ~= old_step) then
      old_step = current_step
      old_size = s[current_step]
    end
    if (s[current_step] > old_size) then
      old_size = s[current_step]
    end
    
    if (have_ecu) then
      component.EngineControlUnit.setECU(4)
    end
    rs.setOutput(s_rs_clutch, signal)
    os.sleep(1)
  else
    old_size = 0
    old_step = 0
    if (have_ecu) then
      component.EngineControlUnit.setECU(0)
    end
    if (x>0) then
      print((os.time()-x)/72)
      x = 0
    end
    os.sleep(5)
  end  
end