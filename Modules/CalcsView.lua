local grid = ...

local s_format = string.format
local m_abs = math.abs
local m_floor = math.floor
local m_min = math.min
local m_max = math.max
local pairs = pairs
local ipairs = ipairs

function formatNumSep(val, dec)
	dec = dec or 0
	val = val or 0
	local neg = val < 0
	val = m_floor(m_abs(val * 10 ^ dec))
	local str = string.reverse(s_format("%.0f", val))
	if #str < (dec + 1) then
		str = str .. string.rep("0", dec + 1 - #str)
	end
	local ret = ""
	local pDec, pThou = dec, 3
	for ci = 1, #str do
		local c = str:sub(ci, ci)
		ret = c .. ret
		if pDec > 0 then
			pDec = pDec - 1
			if pDec == 0 then
				ret = "." .. ret
			end
		else
			pThou = pThou - 1
			if pThou == 0 and ci < #str then
				ret = "," .. ret
				pThou = 3
			end
		end
	end
	return (neg and "-" or "") .. ret
end
function getFormatNumSep(dec)
	return function(val)
		return formatNumSep(val, dec)
	end
end

function formatRound(val, dec)
	dec = dec or 0
	return m_floor(val * 10 ^ dec + 0.5) / 10 ^ dec
end
function getFormatRound(dec)
	return function(val)
		return formatRound(val, dec)
	end
end

function formatPercent(val, dec)
	dec = dec or 0
	return m_floor((val or 0) * 100 * 10 ^ dec) / 10 ^ dec .. "%"
end
function getFormatPercent(dec)
	return function(val)
		return formatPercent(val, dec)
	end
end

function formatSec(val)
	if val == 0 then
		return "0s"
	else
		return s_format("%.2fs", val)
	end
end

local function mkField(x, y, fieldType, name, format, width, list)
	local isFunc = type(format) == "function"
	grid:SetElem(x, y, { 
		type = fieldType,
		name = name,
		format = (isFunc or not format) and "number" or format,
		formatFunc = isFunc and format,
		align = (format == "string" or format == "choice") and "LEFT" or "RIGHT",
		width = width,
		list = list,
	})
end
local function mkFieldWithLabel(x, y, fieldType, label, name, format, width, list)
	grid:SetElem(x, y, {
		type = "label",
		text = label,
		align = "RIGHT"
	})
	if type(name) == "table" then
		for i, n in ipairs(name) do
			if n then
				mkField(x + i, y, fieldType, n, format)
			end
		end
	else
		mkField(x + 1, y, fieldType, name, format, width, list)
	end
end
local function mkFieldTable(x, y, tbl)
	for i, v in ipairs(tbl) do
		if #v == 1 then
			if type(v[1]) == "table" then
				for c, l in ipairs(v[1]) do
					grid:SetElem(x + c - 1, y + i - 1, { type = "label", text = l, align = c == 1 and "RIGHT" or "CENTER" })
				end
			else
				grid:SetElem(x, y + i - 1, { type = "label", text = v[1], align = "RIGHT" })
			end
		elseif #v > 1 then
			mkFieldWithLabel(x, y + i - 1, unpack(v))
		end
	end
end

local function fieldNames(pre, suf, spec)
	return { 
		spec:match("p") and (pre.."_physical"..suf) or false, 
		spec:match("l") and (pre.."_lightning"..suf) or false, 
		spec:match("c") and (pre.."_cold"..suf) or false, 
		spec:match("f") and (pre.."_fire"..suf) or false, 
		spec:match("h") and (pre.."_chaos"..suf) or false, 
		spec:match("a") and (pre.."_damage"..suf) or false,
		spec:match("e") and (pre.."_elem"..suf) or false
	}
end

local columnWidths = {
	120, 60,
	150, 60,
	150, 60,
	160, 90, 90, 90, 90, 90, 90, 70
}

local columns = { }

columns[1] = {
	{
		{ "Player:" },
		{ "input", "Level:", "player_level" },
		{ "output", "Gear Strength:", "gear_strBase" },
		{ "output", "Gear Dexterity:", "gear_dexBase" },
		{ "output", "Gear Intelligence:", "gear_intBase" },
		{ "output", "^xFF7700Strength^7:", "total_str" },
		{ "output", "^x33FF33Dexterity^7:", "total_dex" },
		{ "output", "^x7777FFIntelligence^7:", "total_int" },
		{ },
		{ "Monsters:" },
		{ "input", "Monster level:", "monster_level" },
		{ "output", "Experience:", "monster_xp", formatPercent },
		{ },
		{ "Life:" },
		{ "output", "Spec +:", "spec_lifeBase" },
		{ "output", "Spec %:", "spec_lifeInc" },
		{ "output", "Gear +:", "gear_lifeBase" },
		{ "output", "Gear %:", "gear_lifeInc" },
		{ "output", "Total:", "total_life", formatRound },
		{ "output", "Spec Regen %:", "spec_lifeRegenPercent" },
		{ "output", "Gear Regen +:", "gear_lifeRegenBase" },
		{ "output", "Gear Regen %:", "gear_lifeRegenPercent" },
		{ "output", "Total Regen:", "total_lifeRegen", getFormatRound(1) },
		{ },
		{ "Mana:" },
		{ "output", "Spec +:", "spec_manaBase" },
		{ "output", "Spec %:", "spec_manaInc" },
		{ "output", "Gear +:", "gear_manaBase" },
		{ "output", "Gear %:", "gear_manaInc" },
		{ "output", "Total:", "total_mana", formatRound },
		{ "output", "Spec Regen %:", "spec_manaRegenInc" },
		{ "output", "Gear Regen +:", "gear_manaRegenBase" },
		{ "output", "Gear Regen %:", "gear_manaRegenInc" },
		{ "output", "Total Regen:", "total_manaRegen", getFormatRound(1) },
		{ },
		{ "Auras and Buffs:" },
		{ "input", "Skill 1:", "buff_spec1", "string", 2 },
		{ "input", "Skill 2:", "buff_spec2", "string", 2 },
		{ "input", "Skill 3:", "buff_spec3", "string", 2 },
		{ "input", "Skill 4:", "buff_spec4", "string", 2 },
		{ "input", "Skill 5:", "buff_spec5", "string", 2 },
		{ "input", "Skill 6:", "buff_spec6", "string", 2 },
		{ "input", "Skill 7:", "buff_spec7", "string", 2 },
		{ "input", "Skill 8:", "buff_spec8", "string", 2 },
		{ "input", "Skill 9:", "buff_spec9", "string", 2 },
		{ "input", "Skill 10:", "buff_spec10", "string", 2 },
	}
}

columns[3] = {
	{
		{ "Energy Shield:" },
		{ "output", "Spec +:", "spec_energyShieldBase" },
		{ "output", "Spec %:", "spec_energyShieldInc" },
		{ "output", "Gear +:", "total_gear_energyShieldBase" },
		{ "output", "Gear %:", "gear_energyShieldInc" },
		{ "output", "Total:", "total_energyShield", formatRound },
		{ "output", "Recharge rate:", "total_energyShieldRecharge", getFormatRound(1) },
		{ "output", "Recharge delay:", "total_energyShieldRechargeDelay", formatSec },
		{ },
		{ "Evasion:" },
		{ "output", "Spec +:", "spec_evasionBase" },
		{ "output", "Spec %:", "spec_evasionInc" },
		{ "output", "Gear +:", "total_gear_evasionBase" },
		{ "output", "Gear %:", "gear_evasionInc" },
		{ "output", "Total:", "total_evasion", formatRound },
		{ },
		{ "Armour:" },
		{ "output", "Spec +:", "spec_armourBase" },
		{ "output", "Spec %:", "spec_armourInc" },
		{ "output", "Gear +:", "total_gear_armourBase" },
		{ "output", "Gear %:", "gear_armourInc" },
		{ "output", "Total:", "total_armour", formatRound },
		{ },
		{ "Misc:" },
		{ "input", "Normal Bandit:", "misc_banditNormal", "choice", 1, { "None", "Alira", "Kraityn", "Oak" } },
		{ "input", "Cruel Bandit:", "misc_banditCruel", "choice", 1, { "None", "Alira", "Kraityn", "Oak" } },
		{ "input", "Merciless Bandit:", "misc_banditMerc", "choice", 1, { "None", "Alira", "Kraityn", "Oak" } },
		{ "input", "Always on Low Life?", "cond_LowLife", "check" },
		{ "input", "Always on Full Life?", "cond_FullLife", "check" },
	}
}

columns[5] = {
	{
		{ "Buffs:" },
		{ "input", "Power Charges?", "buff_power", "check" },
	}, {
		flag = "havePower",
		{ "output", "Max Power:", "powerMax" },
	}, {
		{ "input", "Frenzy Charges?", "buff_frenzy", "check" },
	}, {
		flag = "haveFrenzy",
		{ "output", "Max Frenzy:", "frenzyMax" },
	}, {
		{ "input", "Endurance Charges?", "buff_endurance", "check" },
	}, {
		flag = "haveEndurance",
		{ "output", "Max Endurance:", "enduranceMax" },
	}, {
		{ "input", "Onslaught?", "condBuff_Onslaught", "check" },
		{ "input", "Fortify?", "condBuff_Fortify", "check" },
		{ "input", "Using a Flask?", "condBuff_UsingFlask", "check" },
	}, {
		{ },
		{ "For Effective DPS:" },
		{ "input", "Enemy is Bleeding?", "condEff_EnemyBleeding", "check" },
		{ "input", "Enemy is Poisoned?", "condEff_EnemyPoisoned", "check" },
		{ "input", "Enemy is Burning?", "condEff_EnemyBurning", "check" },
		{ "input", "Enemy is Ignited?", "condEff_EnemyIgnited", "check" },
		{ "input", "Enemy is Chilled?", "condEff_EnemyChilled", "check" },
		{ "input", "Enemy is Frozen?", "condEff_EnemyFrozen", "check" },
		{ "input", "Enemy is Shocked?", "condEff_EnemyShocked", "check" },
		{ "input", "Enemy Elem. Resist:", "effective_elemResist" },
		{ },
		{ "Crit Chance:" },
	}, {
		flag = "attack",
		{ "output", "Weapon Crit %:", "gear_weap1_critChanceBase" },
	}, {
		{ "output", "Spec Global Crit %:", "spec_critChanceInc" },
		{ "output", "Gear Global Crit %:", "gear_global_critChanceInc" },
	}, {
		flag = "spell",
		{ "output", "Spec Spell Crit %:", "spec_spell_critChanceInc" },
		{ "output", "Gear Spell Crit %:", "gear_spell_critChanceInc" },
	}, {
		flag = "melee",
		{ "output", "Spec Melee Crit %:", "spec_melee_critChanceInc" },
	}, {
		flag = "totem",
		{ "output", "Spec Totem Crit %:", "spec_totem_critChanceInc" },
	}, {
		flag = "trap",
		{ "output", "Spec Trap Crit %:", "spec_trap_critChanceInc" },
	}, {
		flag = "mine",
		{ "output", "Spec Mine Crit %:", "spec_mine_critChanceInc" },
	}, {
		{ "output", "Crit Chance:", "total_critChance", getFormatPercent(2) },
		{ "output", "Spec Global Multi %:", "spec_critMultiplier" },
		{ "output", "Gear Global Multi %:", "gear_critMultiplier" },
	}, {
		flag = "spell",
		{ "output", "Spec Spell Multi %:", "spec_spell_critMultiplier" },
	}, {
		flag = "melee",
		{ "output", "Spec Melee Multi %:", "spec_melee_critMultiplier" },
	}, {
		flag = "totem",
		{ "output", "Spec Totem Multi %:", "spec_totem_critMultiplier" },
	}, {
		flag = "trap",
		{ "output", "Spec Trap Multi %:", "spec_trap_critMultiplier" },
	}, {
		flag = "mine",
		{ "output", "Spec Mine Multi %:", "spec_mine_critMultiplier" },
	}, {
		{ "output", "Multiplier:", "total_critMultiplier", formatPercent },
	}, {
		flag = "attack",
		{ },
		{ "Accuracy:" },
		{ "output", "Spec Accuracy+:", "spec_accuracyBase" },
		{ "output", "Spec Accuracy %:", "spec_accuracyInc" },
		{ "output", "Gear Accuracy+:", "gear_accuracyBase" },
		{ "output", "Gear Accuracy %:", "gear_accuracyInc" },
		{ "output", "Total Accuracy:", "total_accuracy", formatRound },
		{ "input", "Use Monster Level?", "misc_hitMonsterLevel", "check" },
		{ "output", "Chance to Hit:", "total_hitChance", formatPercent },
	}, {
		{ },
		{ "Stun:" },
		{ "output", "Stun Duration on You:", "stun_duration", formatSec },
		{ "output", "Block Duration on You:", "stun_blockDuration", formatSec },
		{ "output", "Duration on Enemies:", "stun_enemyDuration", formatSec },
		{ "output", "Enemy Threshold Mod:", "stun_enemyThresholdMod", formatPercent },
	}
}

columns[7] = {
	{
		{ "input", "Skill:", "skill_spec", "string", 7 },
	}, {
		flag = "multiPart",
		{ "input", "Skill Part #:", "skill_part" },
		{ "output", "Part:", "skill_partName", "string", 2 },
	}, {
		{ },
		{ "input", "Mode:", "misc_buffMode", "choice", 2, { "Unbuffed", "With buffs", "Effective DPS with buffs" } },
		{ },
	}, {
		flag = "attack",
		{ { "Attack:", "Physical", "Lightning", "Cold", "Fire", "Chaos", "Combined", "Elemental" } },
	}, {
		flag = "weapon1Attack",
		{ "output", "Main Hand:", "gear_weapon1_name", "string", 3 },
		{ "output", "Weapon Min:", fieldNames("gear_weapon1", "Min", "plcfh") },
		{ "output", "Weapon Max:", fieldNames("gear_weapon1", "Max", "plcfh") },
		{ "output", "Weapon APS:", "gear_weapon1_attackRate" },
		{ "output", "Weapon DPS:", fieldNames("weapon1", "DPS", "plcfhae"), getFormatRound(2) },
	}, {
		flag = "weapon2Attack",
		{ "output", "Off Hand:", "gear_weapon2_name", "string", 3 },
		{ "output", "Weapon Min:", fieldNames("gear_weapon2", "Min", "plcfh") },
		{ "output", "Weapon Max:", fieldNames("gear_weapon2", "Max", "plcfh") },
		{ "output", "Weapon APS:", "gear_weapon2_attackRate" },
		{ "output", "Weapon DPS:", fieldNames("weaponon2", "DPS", "plcfhae"), getFormatRound(2) },
	}, {
		flag = "attack",
		{ "output", "Spec Attack Dmg %:", fieldNames("spec_attack", "Inc", "pa") },
		{ "output", "Spec Weapon Dmg %:", fieldNames("spec_weapon", "Inc", "plcfae") },
		{ "output", "Gear Weapon Dmg %:", fieldNames("gear_weapon", "Inc", "plcfae") },
	}, {
		flag = "spell",
		{ { "Spell:", "Physical", "Lightning", "Cold", "Fire", "Chaos", "Combined", "Elemental" } },
		{ "output", "Spec Spell Dmg %:", fieldNames("spec_spell", "Inc", "a") },
		{ "output", "Gear Spell Dmg %:", fieldNames("gear_spell", "Inc", "a") },
	}, {
		flag = "projectile",
		{ "output", "Spec Projectile Dmg %:", fieldNames("spec_projectile", "Inc", "a") },
		{ "output", "Gear Projectile Dmg %:", fieldNames("gear_projectile", "Inc", "a") },
	}, {
		flag = "aoe",
		{ "output", "Spec Area Dmg %:", fieldNames("spec_aoe", "Inc", "a") },
		{ "output", "Gear Area Dmg %:", fieldNames("gear_aoe", "Inc", "a") },
	}, {
		flag = "totem",
		{ "output", "Spec Totem Dmg %:", fieldNames("spec_totem", "Inc", "a") },
		{ "output", "Gear Totem Dmg %:", fieldNames("gear_totem", "Inc", "a") },
	}, {
		flag = "trap",
		{ "output", "Spec Trap Dmg %:", fieldNames("spec_trap", "Inc", "a") },
		{ "output", "Gear Trap Dmg %:", fieldNames("gear_trap", "Inc", "a") },
	}, {
		flag = "mine",
		{ "output", "Spec Mine Dmg %:", fieldNames("spec_mine", "Inc", "a") },
		{ "output", "Gear Mine Dmg %:", fieldNames("gear_mine", "Inc", "a") },
	}, {
		{ "output", "Spec Global %:", fieldNames("spec", "Inc", "plcfhe") },
		{ "output", "Gear Global %:", fieldNames("gear", "Inc", "plcfhae") },
	}, {
		flag = "attack",
		{ "output", "Gear Attack Min+:", fieldNames("gear_attack", "Min", "plcfh") },
		{ "output", "Gear Attack Max+:", fieldNames("gear_attack", "Max", "plcfh") },
	}, {
		flag = "spell",
		{ "output", "Gear Spell Min+:", fieldNames("gear_spell", "Min", "plcfh") },
		{ "output", "Gear Spell Max+:", fieldNames("gear_spell", "Max", "plcfh") },
	}, {
		flag = "attack",
		{ "output", "Spec Attack Speed %:", "spec_attackSpeedInc" },
		{ "output", "Gear Attack Speed %:", "gear_attackSpeedInc" },
		{ "output", "Spec Attack&Cast Sp. %:", "spec_speedInc" },
		{ "output", "Gear Attack&Cast Sp. %:", "gear_speedInc" },
		{ "output", "Attack Damage:", fieldNames("total", "", "plcfha") },
		{ "output", "Average Damage:", "total_avg", getFormatRound(1) },
		{ "output", "Attack Speed:", "total_speed", getFormatRound(2) },
		{ "output", "Attack Time:", "total_time", getFormatRound(2) },
		{ "output", "Attack DPS:", "total_dps", getFormatRound(1) },
	}, {
		flag = "spell",
		{ "output", "Spec Cast Speed %:", "spec_castSpeedInc" },
		{ "output", "Gear Cast Speed %:", "gear_castSpeedInc" },
		{ "output", "Spec Attack&Cast Sp. %:", "spec_speedInc" },
		{ "output", "Gear Attack&Cast Sp. %:", "gear_speedInc" },
		{ "output", "Spell Damage:", fieldNames("total", "", "plcfha") },
		{ "output", "Average Damage:", "total_avg", getFormatRound(1) },
		{ "output", "Cast Rate:", "total_speed", getFormatRound(2) },
		{ "output", "Cast Time:", "total_time", getFormatRound(2) },
		{ "output", "Spell DPS:", "total_dps", getFormatRound(1) },
	}, {
		flag = "cast",
		{ "output", "Secondary Damage:", fieldNames("total", "", "plcfha") },
		{ "output", "Average Damage:", "total_avg", getFormatRound(1) },
	}, {
		{ "output", "Mana Cost:", "total_manaCost", formatRound }
	}, {
		flag = "projectile",
		{ "output", "Spec Pierce Chance %:", "spec_pierceChance" },
		{ "output", "Gear Pierce Chance %:", "gear_pierceChance" },
		{ "output", "Pierce Chance:", "total_pierce", formatPercent },
	}, {
		flag = "duration",
		{ "output", "Spec Duration %:", "spec_durationInc" },
		{ "output", "Skill Duration:", "total_duration", formatSec },
	}, {
		flag = "trap",
		{ "output", "Trap Cooldown:", "total_trapCooldown", formatSec },
	}, {
		flag = "dot",
		{ "output", "Spec DoT Dmg %:", fieldNames("spec_dot", "Inc", "pfa") },
		{ "output", "Gear DoT Dmg %:", fieldNames("gear_dot", "Inc", "pfa") },
		{ "output", "DoT:", fieldNames("total", "Dot", "plcfh"), getFormatRound(1) },
	}, {
		flag = "canBleed",
		{ "output", "Spec Bleed Chance %:", "spec_bleedChance" },
		{ "output", "Gear Bleed Chance %:", "gear_bleedChance" },
		{ "input", "Other Bleed Chance %:", "other_bleedChance" },
	}, {
		flag = "bleed",
		{ "output", "Bleed Chance:", "bleed_chance", formatPercent },
		{ "output", "Bleed DPS:", "bleed_dps", getFormatRound(1) },
		{ "output", "Bleed Duration:", "bleed_duration", formatSec },
	}, {
		flag = "canPoison",
		{ "output", "Spec Poison Chance %:", "spec_poisonChance" },
		{ "output", "Gear Poison Chance %:", "gear_poisonChance" },
		{ "input", "Other Poison Chance %:", "other_poisonChance" },
	}, {
		flag = "poison",
		{ "output", "Spec Poison Dmg %:", "spec_poison_damageInc" },
		{ "output", "Poison Chance:", "poison_chance", formatPercent },
		{ "output", "Poison DPS:", "poison_dps", getFormatRound(1) },
		{ "output", "Poison Duration:", "poison_duration", formatSec },
	}, {
		flag = "canIgnite",
		{ "output", "Spec Ignite Chance %:", "spec_igniteChance" },
		{ "output", "Gear Ignite Chance %:", "gear_igniteChance" },
		{ "input", "Other Ignite Chance %:", "other_igniteChance" },
	}, {
		flag = "ignite",
		{ "output", "Ignite Chance:", "ignite_chance", formatPercent },
		{ "output", "Ignite DPS:", "ignite_dps", getFormatRound(1) },
		{ "output", "Ignite Duration:", "ignite_duration", formatSec },
	}
}

local curFlags

return function(newFlags)
	if curFlags then
		local noNewFlags = true
		local sub = copyTable(curFlags)
		for flag in pairs(newFlags) do
			if curFlags[flag] then
				sub[flag] = nil
			else
				noNewFlags = false
				break
			end
		end
		if noNewFlags and not next(sub) then
			return
		end
	end
	curFlags = copyTable(newFlags)

	grid:Clear()

	for colX, colTables in pairs(columns) do
		local y = 1
		for _, data in ipairs(colTables) do
			if not data.flag or curFlags[data.flag] then
				mkFieldTable(colX, y, data)
				y = y + #data
			end
		end
	end

	for col, width in ipairs(columnWidths) do
		grid:SetColWidth(col, width)
	end
end