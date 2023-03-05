Config = {}

Config.ChanceToRob = 5 			-- Chance for NPC to steal from player
Config.ChanceToFight = 10 		-- Chance for NPC to fight player
Config.ChanceToNotify = 20		-- Chance for NPC to notify police
Config.ChanceToSell = 50		-- Chance for NPC to buy drugs
Config.AttemptSaleTime = 1500	-- Time taken to attempt sale
Config.SaleConfirmTime = 400	-- Time allowed for player to confirm sale
Config.SaleTime = 3000			-- Time taken to complete the sale
Config.MaxSellAmount = 5		-- Maximum amount to be sold in single transaction
Config.MinimumPayment = 20		-- Minimum amount a drug can sell for (Used to generate random number)
Config.PaymentType = 'money' -- 'black_money'

-- Chance to sell specific item is increased in this location / radius
Config.SaleLocations = {
	Meth = {
		coords = vector3(277.556, -835.5033, 29.2124),
		radius = 20.0,
		increaseSaleOf = 'meth_baggie',
		increaseSaleChance = 60,
		increaseEarnings = 1.40
	},

	Coke = {
		coords = vector3(277.556, -835.5033, 29.2124),
		radius = 20.0,
		increaseSaleOf = 'cocaine_packaged',
		increaseSaleChance = 60,
		increaseChanceToNotify = 35,
		increaseEarnings = 1.40
	},

	AltruistShrooms = {
		coords = vector3(277.556, -835.5033, 29.2124),
		radius = 20.0,
		increaseSaleOf = 'shrooms',
		increaseSaleChance = 70,
		-- increaseFightChange = 30,
		-- increaseChangeToRob = 40,
		-- increaseChanceToNotify = 0,
		increaseEarnings = 1.40
	},

}

-- Max Sell Price
Config.Drugs = {
	['meth_baggie'] = 40,
	['meth_baggief'] = 40,
	['cocaine_packaged'] = 35,
	['cocaine_packaged_f'] = 35,
	['joint'] = 15,
	['fentanyl'] = 45,
	['shrooms'] = 20,
	['3d'] = 75
}