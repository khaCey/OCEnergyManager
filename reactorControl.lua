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
--if component.isAvailable("induction_matrix") then
--	battery = component.induction_matrix
--else print("There is no Battery detected!") proceed = false
--end
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

	if event.pull(0.05, "interrupted") then
		term.clear()
		os.exit()
	end
end
