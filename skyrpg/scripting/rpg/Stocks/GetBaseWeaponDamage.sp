stock int GetBaseWeaponDamage(int client, int target, float impactX = 0.0, float impactY = 0.0, float impactZ = 0.0, int damagetype, bool bGetBaseDamage = false, bool IsDataSheet = false, int hitgroup = -1, bool isHealing = false) {
	if (myCurrentWeaponPos[client] < 0) return 0;
	bool IsMelee = hasMeleeWeaponEquipped[client];

	// not a boolean because this variable can have other results under edge cases
	//int dontActivateTalentCooldown = (IsDataSheet) ? 1 : 0;

	int WeaponDamage = 0;

	float cpos[3];
	float tpos[3];
	GetClientAbsOrigin(client, cpos);
	if (target != -1) {
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", tpos);
	}
	else {
		tpos[0] = impactX;
		tpos[1] = impactY;
		tpos[2] = impactZ;
	}
	float Distance = GetVectorDistance(cpos, tpos);
	int baseWeaponTemp = 0;
	float TheAbilityMultiplier;
	float MaxMultiplier;
	int clientFlags = GetEntityFlags(client);
	int weaponProficiencyLevel = GetProficiencyData(client, GetWeaponProficiencyType(client), _, _, true);
	float healStrength = 0.0;
	bool IsLegitimateTargetAlive = (IsLegitimateClientAlive(target)) ? true : false;

	DamageValues[client] = GetArrayCell(a_WeaponDamages, myCurrentWeaponPos[client], 1);
	WeaponDamage = GetArrayCell(DamageValues[client], WEAPONINFO_DAMAGE);

	int coherencyDamageBonus = RoundToCeil(GetCoherencyStrength(client, TARGET_ABILITY_EFFECTS, "d", COHERENCY_RANGE));
	// if (IsDataSheet) // we don't need this if statement anymore since the dontActivateTalentCooldown boolean is set based on the variable.
	if (!isHealing) {
		if (IsDataSheet) baseWeaponTemp += RoundToCeil(GetAbilityStrengthByTrigger(client, target, TRIGGER_D, _, WeaponDamage, _, _, RESULT_d, 2, true, _, hitgroup, _, damagetype, 0));	// cooldowns will NOT trigger
		else baseWeaponTemp += RoundToCeil(GetAbilityStrengthByTrigger(client, target, TRIGGER_D, _, WeaponDamage, _, _, RESULT_d, 2, true, _, hitgroup, _, damagetype, 0, true));	// cooldowns will trigger
	}
	else {
		if (!IsMelee) {
			if (IsDataSheet) healStrength = GetAbilityStrengthByTrigger(client, target, TRIGGER_hB, _, _, _, _, RESULT_d, 2, true, _, hitgroup, _, damagetype, 0);	// cooldowns will NOT trigger
			else healStrength = GetAbilityStrengthByTrigger(client, target, TRIGGER_hB, _, _, _, _, RESULT_d, 2, true, _, hitgroup, _, damagetype, 0, true);	// cooldowns will trigger
		}
		else {
			if (IsDataSheet) healStrength = GetAbilityStrengthByTrigger(client, target, TRIGGER_hM, _, _, _, _, RESULT_d, 2, true, _, hitgroup, _, damagetype, 0);	// cooldowns will NOT trigger
			else healStrength = GetAbilityStrengthByTrigger(client, target, TRIGGER_hM, _, _, _, _, RESULT_d, 2, true, _, hitgroup, _, damagetype, 0, true);	// cooldowns will trigger
		}
		if (IsLegitimateTargetAlive) {
			TheAbilityMultiplier = GetAbilityMultiplier(target, "expo");
			if (TheAbilityMultiplier > 0.0) healStrength += RoundToCeil(healStrength * TheAbilityMultiplier);
		}
		if (healStrength <= 0.0) return 0;
		WeaponDamage = RoundToCeil(WeaponDamage * healStrength);
	}
	if (target != -1) {
		float fAmplifyPower = GetAbilityStrengthByTrigger(client, client, TRIGGER_amplify, _, _, _, _, RESULT_d, _, true);
		if (fAmplifyPower > 0.0) baseWeaponTemp += RoundToCeil(WeaponDamage * fAmplifyPower);
	}
	// The player, above, receives a flat damage increase of 50% just for having adrenaline active.
	// Now, we increase their damage if they're in rage ammo, which is a separate thing, although it also provides the adrenaline buff.
	if (fSurvivorBufferBonus > 0.0 && IsSpecialCommonInRange(client, 'b')) baseWeaponTemp += RoundToCeil(WeaponDamage * fSurvivorBufferBonus);
	//if (IsClientInRangeSpecialAmmo(client, "a") == -2.0) baseWeaponTemp += RoundToCeil(WeaponDamage * IsClientInRangeSpecialAmmo(client, "a", false));
	int weaponDamageExperienceCalculator = (!IsDataSheet) ? WeaponDamage : 0;
	float ammoStr = IsClientInRangeSpecialAmmo(client, "d", _, _, weaponDamageExperienceCalculator, target);
	if (ammoStr > 0.0) baseWeaponTemp += RoundToCeil(WeaponDamage * ammoStr);
	ammoStr = IsClientInRangeSpecialAmmo(client, "E", _, _, weaponDamageExperienceCalculator, target);
	if (ammoStr > 0.0) baseWeaponTemp += RoundToCeil(WeaponDamage * ammoStr);
	ammoStr = IsClientInRangeSpecialAmmo(target, "E", _, _, weaponDamageExperienceCalculator, target);
	if (ammoStr > 0.0) baseWeaponTemp += RoundToCeil(WeaponDamage * ammoStr);

	if (!IsDataSheet) {
		// some ammos don't increase damage directly HERE, but we still give experience benefits because they buffed damage elsewhere.
		IsClientInRangeSpecialAmmo(client, "a", _, _, weaponDamageExperienceCalculator, target);
	}
	
	float WeaponRange = GetArrayCell(DamageValues[client], WEAPONINFO_RANGE);
	if (coherencyDamageBonus > 0) baseWeaponTemp += coherencyDamageBonus;

	TheAbilityMultiplier = GetAbilityMultiplier(client, "N");
	if (TheAbilityMultiplier != -1.0) baseWeaponTemp += RoundToCeil(WeaponDamage * TheAbilityMultiplier);
	TheAbilityMultiplier = GetAbilityMultiplier(client, "C");
	if (TheAbilityMultiplier != -1.0) {
		MaxMultiplier = GetAbilityMultiplier(client, "C", 3);
		if (ConsecutiveHits[client] > 0) TheAbilityMultiplier *= ConsecutiveHits[client];
		if (TheAbilityMultiplier > MaxMultiplier) TheAbilityMultiplier = MaxMultiplier;
		if (TheAbilityMultiplier > 0.0) baseWeaponTemp += RoundToCeil(WeaponDamage * TheAbilityMultiplier); // damage dealt is increased
	}
	if (!(clientFlags & FL_ONGROUND)) {
		TheAbilityMultiplier = GetAbilityMultiplier(client, "K");
		if (TheAbilityMultiplier != -1.0) baseWeaponTemp += RoundToCeil(WeaponDamage * TheAbilityMultiplier);
	}
	if ((clientFlags & FL_INWATER)) {
		TheAbilityMultiplier = GetAbilityMultiplier(client, "a");
		if (TheAbilityMultiplier != -1.0) baseWeaponTemp += RoundToCeil(WeaponDamage * TheAbilityMultiplier);
	}
	if ((clientFlags & FL_ONFIRE)) {
		TheAbilityMultiplier = GetAbilityMultiplier(client, "f");
		if (TheAbilityMultiplier != -1.0) baseWeaponTemp += RoundToCeil(WeaponDamage * TheAbilityMultiplier);
	}
	if (!IsDataSheet) {
		lastBaseDamage[client] = WeaponDamage;
		//Format(lastWeapon[client], sizeof(lastWeapon[]), "%s", Weapon);
		lastTarget[client] = target;
	}
	if (weaponProficiencyLevel > 0) baseWeaponTemp += RoundToCeil((weaponProficiencyLevel * fProficiencyLevelDamageIncrease) * WeaponDamage);

	if (baseWeaponTemp > 0) WeaponDamage += baseWeaponTemp;

	float WeaponEffectiveRange = GetArrayCell(DamageValues[client], WEAPONINFO_EFFECTIVE_RANGE);
	// if effective range > range, reduce effective range based on the weapon range increase talents, so that snipers receive their range damage bonus faster
	// if range > effective range, then weapon range talents increase effective range, so damage drop off doesn't start until further away.
	if (!IsMelee) {
		float fEffectiveRangeDamageBonus = 2.0;
		if (WeaponEffectiveRange > WeaponRange) {	// Scale weapons like Snipers that you should deal more damage the FURTHER away you are.
			if (Distance <= WeaponRange) {
				fEffectiveRangeDamageBonus = 1.0;
			}
			else if (Distance < WeaponEffectiveRange) {		// Receive a damage bonus based on how close the player is to the WeaponEffectiveRange versus the WeaponRange
				fEffectiveRangeDamageBonus = 1.0 + (Distance - WeaponRange) / (WeaponEffectiveRange - WeaponRange);
			}
		}
		else {
			float maxWeaponRange = WeaponRange * 2.0;
			// damage is double if the player is the effective range or closer and then the value is not modified.
			if (Distance >= maxWeaponRange) fEffectiveRangeDamageBonus = 0.01;
			else if (Distance >= WeaponRange) {
				fEffectiveRangeDamageBonus = 1.0 - (Distance - WeaponRange) / (maxWeaponRange - WeaponRange);
			}
			else if (Distance >= WeaponEffectiveRange) {	// When double or greater a weapons max effective range, damage is set to 1
				fEffectiveRangeDamageBonus = 2.0 - (Distance - WeaponEffectiveRange) / (WeaponRange - WeaponEffectiveRange);
			}
		}
		WeaponDamage = RoundToCeil(WeaponDamage * fEffectiveRangeDamageBonus);
	}
	if (bIsSurvivorFatigue[client]) {
		int damagePenalty = RoundToCeil(WeaponDamage * fFatigueDamagePenalty);
		WeaponDamage -= damagePenalty;
	}
	return WeaponDamage;
}