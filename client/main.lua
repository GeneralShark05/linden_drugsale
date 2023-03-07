local ox_inventory = exports.ox_inventory

local canSell = false
local isSelling = false
local waitTime = 2000
local lastPed = nil
local numberOfCops = 0

local chanceToNotify = Config.ChanceToNotify
local chanceToRob = Config.ChanceToRob
local chanceToSell = Config.ChanceToSell
local chanceToFight = Config.ChanceToFight

local DrugNames = {}
local drugs = {}
for k, v in pairs(Config.Drugs) do
	table.insert(DrugNames, k)
end

----------------------------------------------------------------------------------
-- Target -- 
----------------------------------------------------------------------------------

StartResource = function()
	PlayerLoaded = true
	local playerPed = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)
	local playerID = GetPlayerServerId(PlayerId())
	StartLoop()
end

StartLoop = function()
	Citizen.CreateThread(function()
		while PlayerLoaded do
			if not isSelling then
				CanSellDrugs()
			else waitTime = 10000 end
			Citizen.Wait(waitTime)
		end
	end)
end

local options = {
	{
        name = 'ox:option2',
        icon = 'fa-solid fa-comment-dots',
        label = 'Sell Drugs',
		distance = 3,
		items = DrugNames,
		anyItem = true,
		onSelect = function(data)
			local playerPed = PlayerPedId()
			local drugCount = CountDrugs()
			canSell = false
			lastPed = data.entity
			TriggerEvent('linden_drugsale:attemptSale', drugCount, playerPed, data.entity)
		end,
         canInteract = function(entity, distance)
             return not IsEntityDead(entity) and distance < 3 and canSell and not isSelling and entity ~= lastPed and GetPedType(entity) ~= 1 and GetPedType(entity) ~= 28 and GetPedType(entity) ~= 2
         end
    }
}

exports.ox_target:addGlobalPed(options)
----------------------------------------------------------------------------------
-- Debug -- 
----------------------------------------------------------------------------------

if Config.Debug then
	for i, j in pairs(Config.SaleLocations) do
		Citizen.CreateThread(function()
				local blip = AddBlipForRadius(j.coords , j.radius) -- you can use a higher number for a bigger zone

				SetBlipHighDetail(blip, true)
				SetBlipColour(blip, 1)
				SetBlipAlpha (blip, 128)
		end)
	end

	RegisterCommand('checkzone', function()
		local playerPed = PlayerPedId()
		local playerCoords = GetEntityCoords(playerPed)
		for i, j in pairs(Config.SaleLocations) do
			distance = #(playerCoords - j.coords)
			if distance < j.radius then
				return TriggerEvent('chat:addMessage', {
					color = { 255, 0, 0},
					multiline = true,
					args = {i}
				  })
			end
		end
		TriggerEvent('chat:addMessage', {
			color = { 255, 0, 0},
			multiline = true,
			args = {'nil'}
		  })
	end, false)
end

----------------------------------------------------------------------------------
-- Functions -- 
----------------------------------------------------------------------------------

CountDrugs = function()
	local drugCount = 0
	for k, v in pairs(Config.Drugs) do
		local search = exports.ox_inventory:Search('count', k)
		if search > 0 then
			drugCount = drugCount+1 
		end
	end
	return drugCount
end

CanSellDrugs = function()
	local itemNames = {}

	for item, data in pairs(exports.ox_inventory:Items()) do
		itemNames[item] = data.label
	end

	isSelling = true
	drugs = {}
	local drugCount = 0
	for k, v in pairs(Config.Drugs) do
		local search = exports.ox_inventory:Search('count', k)
		if search > 0 then
			if drugs[k] then 
				drugs[k].count = drugs[k].count + search 
			else
				drugs[k] = {index=drugCount+1, name=k, count=search, label=itemNames[k]} 
				drugCount = drugCount+1 
			end
		end
	end
	Citizen.CreateThread(function()
		ESX.TriggerServerCallback('linden_drugsale:checkCops', function(copsOnline)
			numberOfCops = copsOnline
			canSell = true
		end)
		isSelling = false
	end)
end

----------------------------------------------------------------------------------
-- Attempt to Sell -- 
----------------------------------------------------------------------------------

AddEventHandler('linden_drugsale:attemptSale', function(drugCount, playerPed, ped)
	SetEntityAsMissionEntity(ped)
	TaskStandStill(ped, 5000)
	TaskChatToPed(ped, playerPed)
	if lib.progressBar({
		duration = Config.AttemptSaleTime,
		label = 'Showing your product...',
		useWhileDead = false,
		canCancel = true,
		disable = {
			car = true,
			move = true,
			combat = true,
			mouse = true,
		},
		anim = {
			dict = 'missheistdockssetup1clipboard@idle_a',
			clip = 'idle_b',
		},
		prop = {
			model = 'prop_poly_bag_01',
			pos = vec3(0.15, -0.15, 0.02),
			rot = vec3(0.0, -40.0, -80.0),
			bone = 18905
		},
	}) then
		ClearPedTasks(playerPed)
		
		local interaction = math.random(1, 100)
		
		local saleChance = math.random(1, 100)
		local drugSelection = math.random(1, drugCount)
		local sellCount = math.random(Config.MaxSellAmount)
		local drugToSell = nil
		local salePrice = 0

		local playerCoords = GetEntityCoords(playerPed)
		local increaseSaleOf = nil
		local saleLocation = nil
		local distance

		for i, j in pairs(Config.SaleLocations) do
			distance = #(playerCoords - j.coords)
			if distance < j.radius then
				local increaseChance = math.random(100)
				chanceToNotify = chanceToNotify + j.increaseNotifyChance
				chanceToRob = chanceToRob + j.increaseRobChance
				chanceToFight = chanceToFight + j.increaseFightChance

				saleLocation = i
				if increaseChance <= j.increaseSaleChance then
					increaseSaleOf = j.increaseSaleOf
				else
					increaseSaleOf = nil
					saleLocation = nil
				end
			end
		end

		if interaction <= chanceToNotify then
			local x, y, z = table.unpack(playerCoords)
			local streetname = GetStreetNameFromHashKey(GetStreetNameAtCoord(x,y,z))
			local postal = exports.postal:getPostal()
			TriggerServerEvent('linden_drugsale:snitch', streetname, tonumber(postal))
		end
		local increaseSalePrice = 1

		for k, v in pairs(drugs) do
			if increaseSaleOf ~= nil then
				if v.name == increaseSaleOf then
					increaseSalePrice = Config.SaleLocations[saleLocation].increaseEarnings
					chanceToSell = chanceToSell + Config.SaleLocations[saleLocation].increaseSaleChance
					chanceToRob = chanceToRob + Config.SaleLocations[saleLocation].increaseRobChance
					drugToSell = v
				elseif v.index == drugSelection then
					drugToSell = v
				end
			else
				if v.index == drugSelection then
					drugToSell = v
				end
			end
		end

		if sellCount > drugToSell.count then
			sellCount = math.random(drugToSell.count)
		end

		salePrice = lib.callback('linden_drugsale:getPrice', false, drugToSell, increaseSalePrice, sellCount)

		if numberOfCops == 2 then
			salePrice = salePrice * 1.1
		elseif numberOfCops == 3 then
			salePrice = salePrice * 1.2
		elseif numberOfCops > 4 then
			salePrice = salePrice * 1.3
		end

		if saleChance <= chanceToSell then
			TriggerEvent('linden_drugsale:requestConfirm', drugToSell.name, drugToSell.label, sellCount, math.floor(salePrice), playerPed, ped)
		else
			lib.notify({
				title = 'Feedback',
				description = 'This shit is weak..',
				type = 'inform'
			})
			PedInteraction(playerPed, ped, drugToSell.name, sellCount)
		end
	end
end)

----------------------------------------------------------------------------------
-- Confirm Sale -- 
----------------------------------------------------------------------------------

AddEventHandler('linden_drugsale:requestConfirm', function(drugToSell, label, sellCount, salePrice, playerPed, ped)
	Citizen.CreateThread(function()
		local timer = 0
		
		while timer < Config.SaleConfirmTime do
			Citizen.Wait(0)
			timer = timer + 1
			if IsControlJustReleased(0, 38) then			
				TriggerEvent('linden_drugsale:confirmSale', drugToSell, sellCount, salePrice, playerPed, ped, label)
				break
			end
		end

		if timer == Config.SaleConfirmTime then
			lib.notify({
				title = 'Timeout',
				description = 'You\'re taking too long, I\'m out of here.',
				type = 'error'
			})			
			PedInteraction(playerPed, ped, drugToSell.name, sellCount)
		end
		timer = 0
	end)
	lib.notify({
		title = 'Confirm Sale',
		description = 'Press [E] Sell '..sellCount..' '..label.. ' for $'..salePrice,
		type = 'inform'
	})
end)

AddEventHandler('linden_drugsale:confirmSale', function(drugToSell, sellCount, salePrice, playerPed, ped, label)
	if lib.progressBar({
		duration = Config.SaleTime,
		label = 'Making the deal...',
		useWhileDead = false,
		canCancel = true,
		disable = {
			car = true,
			move = true,
			combat = true,
			mouse = true,
		},
		anim = {
			dict = 'missheistdockssetup1clipboard@idle_a',
			clip = 'idle_a'
		},
		prop = {
			model = 'prop_drug_package_02',
			pos = vec3(0.00, 0.00, 0.00),
			rot = vec3(0.0, 0.0, -1.5)
		},
	}) then
			lib.notify({
				title = 'Dealt Drugs',
				description = 'You sold '..sellCount..' '..label..'s',
				type = 'success'
			})	
			ClearPedTasks(playerPed)
			TriggerServerEvent('linden_drugsale:sellDrugs', drugToSell, sellCount, salePrice)
			Citizen.Wait(1000)
			SetPedAsNoLongerNeeded(ped)
			isSelling = false
		end
end)

----------------------------------------------------------------------------------
-- Interaction -- 
----------------------------------------------------------------------------------

PedInteraction = function(playerPed, ped, item, count)
	local interaction = 100
	interaction = math.random(100)
	
	if interaction <= chanceToRob then
		TriggerServerEvent('linden_drugsale:robPlayer', item, count)
		lib.notify({
			title = 'You Were Robbed!',
			description = 'Someone took off with your shit!',
			type = 'error'
		})		
		SetPedAsNoLongerNeeded(ped)
		TaskSmartFleePed(ped, playerPed, 1000.0, -1, false, true)
	end

	if interaction <= chanceToFight then
		TaskCombatPed(ped, playerPed, 0, 16)
	end
	isSelling = false
	SetPedAsNoLongerNeeded(ped)
end

if ESX.IsPlayerLoaded() then StartResource() end
