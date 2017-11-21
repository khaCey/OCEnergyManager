local component = require("component")
local keyboard = require("keyboard")
local term = require("term")
local sides = require("sides")
local event = require("event")
local serialization = require("serialization")

local proceed = true
local reactors = {}
local gpu
local storage
local battery

--check for components

if component.isAvailable("gpu") then
	gpu = component.gpu
	gpu.setResolution(66,13)
else print("There is no Graphics card detected!") proceed = false
end
if component.isAvailable("block_refinedstorage_interface") then
	storage = component.block_refinedstorage_interface
else print("There is no Inventory Network detected!") proceed = false
end
if component.isAvailable("induction_matrix") then
	battery = component.induction_matrix
else print("There is no Battery detected!") proceed = false
end
for address, name in component.list() do
	if name == "br_reactor" then
		local reactor = component.proxy(address)
		table.insert(reactors, reactor)
	end
end

--variables
local uranium = 0
local energyCapacity = 0
local energy = 0
local controlRodLevels = 0
local rfpertick = 0
local fuelLifeSpan = 0
local input = 0
local output = 0
--charts
local bar = charts.Container {
  x = 2,
  y = 4,
  bg = 0xffffff,
  width = 61,
  height = 3,
  payload = charts.ProgressBar {
    direction = charts.sides.RIGHT,
    value = 0,
    colorFunc = function(_, perc)
      if perc >= .9 then
        return 0x20afff
      elseif perc >= .75 then
        return 0x20ff20
      elseif perc >= .5 then
        return 0xafff20
      elseif perc >= .25 then
        return 0xffff20
      elseif perc >= .1 then
        return 0xffaf20
      else
        return 0xff2020
      end
    end
  }
}
--functions
local function getUranium()
	local size = 0
	local items = {{name = "bigreactors:ingotmetals"}, {name = "bigreactors:ingotmetals"}}

	for i, item in pairs(items) do
		size = size + storage.getItem(item).size
	end
	return size
end

function getLifeSpan(uranium)
	local fuelConsumption = 0
	for i,reactor in ipairs(reactors) do
		fuelConsumption = fuelConsumption + (reactor.getFuelConsumedLastTick()*1.2)
		print(fuelConsumption)
	end
	local lifespan = uranium / fuelConsumption
	local string = ""
	if (lifespan / 60) >= 1 then
		if(lifespan / 3600 >= 1) then
			string = ("%.2d"):format(("%.0f"):format(lifespan / 3600)) .. ":" .. ("%.2d"):format(("%.0f"):format((lifespan % 3600) / 60))
		else string = "00: " .. ("%.2d"):format(("%.0f"):format((lifespan % 3600) / 60))
		end
	end

	return string
end

--loop
while proceed do
	uranium = getUranium()
	if uranium == 0 then
		print("Critical! No Uranium stored!")

	else
		fuelLifeSpan = getLifeSpan(uranium)
		term.clear()
		gpu.set(1, 2, ("Fuel Life Span: " .. fuelLifeSpan))
	end
	term.clear()
	bar.gpu.set(2, 1, "Energy Capacity Monitor")
	bar.gpu.set(2, 3, "Main RF Network")
	bar.gpu.set(31, 7, ("%.1f"):format(bar.payload.value*100.0) .. "%");
	bar.gpu.set(5, 8, "INFO")
	bar.gpu.set(5, 9, "Capacity : " .. ("%.0f"):format(energy) .. " / " .. energyCapacity)
	bar.gpu.set(5, 10, "Input    : " .. ("%.0f"):format(input) .. "RF/t")
	bar.gpu.set(5, 11, "Output   : " .. ("%.0f"):format(output) .. "RF/t")
	bar.gpu.set(5, 12, "Excess   : " .. ("%.0f"):format(input - output) .. "RF/t")

	bar.payload.value =  (energy / energyCapacity)
	bar:draw()
	if event.pull(0.05, "interrupted") then
		term.clear()
		os.exit()
	end
end
