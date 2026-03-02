--[[
	ItemsConfig.lua
	All item and relic definitions for the Anime Simulator.
	Items drop from enemies. Relics complete collection sets for permanent bonuses.
]]

local ItemsConfig = {
	-- Common shards
	{
		itemId = "shard_common",
		name = "Common Shard",
		rarity = "common",
		type = "material",
		stackable = true,
		maxStack = 999,
		sellValue = 2,
		statBonus = nil,
		description = "A fragment of broken gate energy. Sells for a small amount.",
	},
	{
		itemId = "shard_uncommon",
		name = "Uncommon Shard",
		rarity = "uncommon",
		type = "material",
		stackable = true,
		maxStack = 999,
		sellValue = 10,
		statBonus = nil,
		description = "A denser shard with faint glow. Worth more to collectors.",
	},
	{
		itemId = "shard_rare",
		name = "Rare Shard",
		rarity = "rare",
		type = "material",
		stackable = true,
		maxStack = 999,
		sellValue = 50,
		statBonus = nil,
		description = "A brilliant shard pulsing with energy.",
	},
	{
		itemId = "shard_epic",
		name = "Epic Shard",
		rarity = "epic",
		type = "material",
		stackable = true,
		maxStack = 999,
		sellValue = 250,
		statBonus = nil,
		description = "An intensely glowing shard. Highly valuable.",
	},
	{
		itemId = "shard_legendary",
		name = "Legendary Shard",
		rarity = "legendary",
		type = "material",
		stackable = true,
		maxStack = 999,
		sellValue = 1000,
		statBonus = nil,
		description = "An overwhelmingly powerful shard fragment.",
	},

	-- Drop fragments
	{
		itemId = "fang_fragment",
		name = "Fang Fragment",
		rarity = "uncommon",
		type = "equippable",
		stackable = false,
		maxStack = 1,
		sellValue = 15,
		statBonus = { damage = 5 },
		description = "A shard from a Void Hound's fang. Grants slight damage boost.",
	},
	{
		itemId = "feather_shard",
		name = "Feather Shard",
		rarity = "uncommon",
		type = "equippable",
		stackable = false,
		maxStack = 1,
		sellValue = 30,
		statBonus = { speed = 0.05 },
		description = "A crystallized feather from the Sky Realm. Slightly faster fights.",
	},
	{
		itemId = "gear_fragment",
		name = "Gear Fragment",
		rarity = "rare",
		type = "equippable",
		stackable = false,
		maxStack = 1,
		sellValue = 100,
		statBonus = { damage = 50, crit = 0.02 },
		description = "A precision-machined gear from the Forge. Boosts damage and crit.",
	},

	-- Arc 1 Relics (Collection Book)
	{
		itemId = "relic_arc1_shard",
		name = "Gate Shard",
		rarity = "rare",
		type = "relic",
		stackable = false,
		maxStack = 1,
		sellValue = 0, -- relics cannot be sold
		statBonus = nil,
		collectionSet = "arc1_set",
		description = "A piece of the Shattered Gate. Part of a collection.",
	},
	{
		itemId = "relic_arc1_ember",
		name = "Shadow Ember",
		rarity = "rare",
		type = "relic",
		stackable = false,
		maxStack = 1,
		sellValue = 0,
		statBonus = nil,
		collectionSet = "arc1_set",
		description = "A smoldering fragment of shadow. Part of a collection.",
	},
	{
		itemId = "relic_arc1_crest",
		name = "Warden Crest",
		rarity = "epic",
		type = "relic",
		stackable = false,
		maxStack = 1,
		sellValue = 0,
		statBonus = nil,
		collectionSet = "arc1_set",
		description = "The crest of the Shadow Warden. Part of a collection.",
	},

	-- Arc 2 Relics
	{
		itemId = "relic_arc2_feather",
		name = "Storm Feather",
		rarity = "rare",
		type = "relic",
		stackable = false,
		maxStack = 1,
		sellValue = 0,
		statBonus = nil,
		collectionSet = "arc2_set",
		description = "A feather charged with lightning. Part of a collection.",
	},
	{
		itemId = "relic_arc2_prism",
		name = "Sky Prism",
		rarity = "rare",
		type = "relic",
		stackable = false,
		maxStack = 1,
		sellValue = 0,
		statBonus = nil,
		collectionSet = "arc2_set",
		description = "A crystal that bends light from the sky. Part of a collection.",
	},
	{
		itemId = "relic_arc2_wing",
		name = "Sovereign Wing",
		rarity = "epic",
		type = "relic",
		stackable = false,
		maxStack = 1,
		sellValue = 0,
		statBonus = nil,
		collectionSet = "arc2_set",
		description = "A wing fragment from the Tempest Sovereign. Part of a collection.",
	},

	-- Arc 3 Relics
	{
		itemId = "relic_arc3_gear",
		name = "Master Gear",
		rarity = "rare",
		type = "relic",
		stackable = false,
		maxStack = 1,
		sellValue = 0,
		statBonus = nil,
		collectionSet = "arc3_set",
		description = "A perfectly machined gear. Part of a collection.",
	},
	{
		itemId = "relic_arc3_piston",
		name = "Forge Piston",
		rarity = "rare",
		type = "relic",
		stackable = false,
		maxStack = 1,
		sellValue = 0,
		statBonus = nil,
		collectionSet = "arc3_set",
		description = "A steam-powered piston. Part of a collection.",
	},
	{
		itemId = "relic_arc3_core",
		name = "Machinist Core",
		rarity = "epic",
		type = "relic",
		stackable = false,
		maxStack = 1,
		sellValue = 0,
		statBonus = nil,
		collectionSet = "arc3_set",
		description = "The heart of the Grand Machinist. Part of a collection.",
	},
}

-- Collection sets: completing a set grants a permanent stat bonus
local CollectionSets = {
	arc1_set = {
		name = "Shattered Gate Collection",
		requiredItems = { "relic_arc1_shard", "relic_arc1_ember", "relic_arc1_crest" },
		bonus = { damage = 25, dropRate = 0.05 },
	},
	arc2_set = {
		name = "Sky Realm Collection",
		requiredItems = { "relic_arc2_feather", "relic_arc2_prism", "relic_arc2_wing" },
		bonus = { damage = 100, speed = 0.10 },
	},
	arc3_set = {
		name = "Steampunk Forge Collection",
		requiredItems = { "relic_arc3_gear", "relic_arc3_piston", "relic_arc3_core" },
		bonus = { damage = 500, crit = 0.10, income = 100 },
	},
}

-- Rarity color map for UI
local RarityColors = {
	common    = { r = 180, g = 180, b = 180 },
	uncommon  = { r = 100, g = 200, b = 100 },
	rare      = { r = 80,  g = 150, b = 255 },
	epic      = { r = 180, g = 80,  b = 255 },
	legendary = { r = 255, g = 180, b = 40  },
}

-- Build lookup by itemId
local ItemById = {}
for _, item in ipairs(ItemsConfig) do
	ItemById[item.itemId] = item
end

return {
	List = ItemsConfig,
	ById = ItemById,
	CollectionSets = CollectionSets,
	RarityColors = RarityColors,
}
