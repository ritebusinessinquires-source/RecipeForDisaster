-- Monetization: sell fun, speed and style, never survival. Nothing here protects you from a
-- hazard or brings you back to life.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local Mailbox = require(script.Parent.Mailbox)

local Monetization = {}

local ownership: { [any]: { [string]: boolean } } = {}
local giftTargets: { [any]: { userId: number, pass: string } } = {}
local productHandlers: { [string]: (player: Player, info: any) -> boolean } = {}

Monetization.PassNames = {
	VIP = "VIP Chef",
	DoubleCash = "2x Cash",
	BiggerHand = "Bigger Hand",
	RecipeHints = "Recipe Hints",
	ChefTaunts = "Chef Taunts",
}

function Monetization.owns(player: any, passKey: string): boolean
	local data = PlayerData.get(player)
	if data and data.gifted and data.gifted[passKey] then
		return true
	end
	local o = ownership[player]
	return o ~= nil and o[passKey] == true
end

local function applyPassPerks(player: Player)
	player:SetAttribute("VIP", Monetization.owns(player, "VIP"))
	local data = PlayerData.get(player)
	if data and Monetization.owns(player, "VIP") and not data.cosmetics.owned.hat_gold then
		data.cosmetics.owned.hat_gold = true
		PlayerData.sync(player)
	end
	local passes = {}
	for k in pairs(Config.GamePasses) do
		passes[k] = Monetization.owns(player, k)
	end
	player:SetAttribute("Passes", game:GetService("HttpService"):JSONEncode(passes))
end
Monetization.applyPassPerks = applyPassPerks

function Monetization.refresh(player: Player)
	local o = {}
	for k, pass in pairs(Config.GamePasses) do
		if pass.id > 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.id)
			o[k] = ok and owns or false
		end
	end
	ownership[player] = o
	applyPassPerks(player)
end

function Monetization.cashMultiplier(player: any): number
	local vip = Monetization.owns(player, "VIP")
	local dbl = Monetization.owns(player, "DoubleCash")
	if vip and dbl then
		return Config.Economy.VipAndDoubleMultiplier
	elseif dbl then
		return Config.Economy.DoubleCashMultiplier
	elseif vip then
		return Config.Economy.VipMultiplier
	end
	return 1
end

function Monetization.onProduct(key: string, fn: (Player, any) -> boolean)
	productHandlers[key] = fn
end

local function productKeyById(id: number): string?
	for k, p in pairs(Config.Products) do
		if p.id == id then
			return k
		end
	end
	return nil
end

local function grantGift(buyer: Player, passKey: string, targetUserId: number)
	local name = Monetization.PassNames[passKey] or passKey
	local target = Players:GetPlayerByUserId(targetUserId)
	if target then
		local data = PlayerData.get(target)
		if data then
			data.gifted[passKey] = true
			PlayerData.sync(target)
			applyPassPerks(target)
			Net.fire(target, "Toast", { text = buyer.DisplayName .. " gifted you " .. name .. "! 🎁", kind = "big" })
			return true
		end
	end
	return Mailbox.send(targetUserId, { kind = "gift", pass = passKey, from = buyer.DisplayName })
end

function Monetization.setGiftTarget(player: Player, targetUserId: number, passKey: string)
	if Config.GamePasses[passKey] then
		giftTargets[player] = { userId = targetUserId, pass = passKey }
	end
end

local function processReceipt(receipt: any)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = PlayerData.get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if table.find(data.receipts, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local key = productKeyById(receipt.ProductId)
	if not key then
		warn("[Monetization] unknown product", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local info = Config.Products[key]
	local ok = false
	if info.spins then
		data.spins += info.spins
		Net.fire(player, "Toast", { text = string.format("+%d Spins! 🎡", info.spins), kind = "big" })
		ok = true
	elseif info.cash then
		data.cash += info.cash
		Net.fire(player, "Toast", { text = string.format("+%s Cash! 💰", tostring(info.cash)), kind = "cash", cash = info.cash })
		ok = true
	elseif info.gift then
		local t = giftTargets[player]
		if t and t.pass == info.gift then
			ok = grantGift(player, info.gift, t.userId)
			giftTargets[player] = nil
		end
	elseif productHandlers[key] then
		ok = productHandlers[key](player, info)
	end
	if not ok then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	table.insert(data.receipts, receipt.PurchaseId)
	while #data.receipts > 60 do
		table.remove(data.receipts, 1)
	end
	PlayerData.sync(player)
	task.spawn(PlayerData.save, player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Monetization.init()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased then
			for k, pass in pairs(Config.GamePasses) do
				if pass.id == passId then
					ownership[player] = ownership[player] or {}
					ownership[player][k] = true
					applyPassPerks(player)
					Net.fire(player, "Toast", { text = "Thanks! " .. (Monetization.PassNames[k] or k) .. " unlocked!", kind = "big" })
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		ownership[player] = nil
		giftTargets[player] = nil
	end)
	-- client asks to buy something
	Net.event("PromptPurchase").OnServerEvent:Connect(function(player, req)
		if type(req) ~= "table" then
			return
		end
		if req.kind == "pass" and Config.GamePasses[req.key] and Config.GamePasses[req.key].id > 0 then
			MarketplaceService:PromptGamePassPurchase(player, Config.GamePasses[req.key].id)
		elseif req.kind == "product" and Config.Products[req.key] and Config.Products[req.key].id > 0 then
			MarketplaceService:PromptProductPurchase(player, Config.Products[req.key].id)
		elseif req.kind == "gift" and type(req.target) == "number" and Config.GamePasses[req.key] then
			local productKey = "Gift" .. req.key
			local product = Config.Products[productKey]
			if product and product.id > 0 then
				Monetization.setGiftTarget(player, req.target, req.key)
				MarketplaceService:PromptProductPurchase(player, product.id)
			end
		end
	end)
end

return Monetization
