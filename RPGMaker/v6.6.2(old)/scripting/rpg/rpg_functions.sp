/*
 *	Provides a shortcut method to calling ANY value from keys found in CONFIGS/READYUP/RPG/CONFIG.CFG
 *	@return		-1		if the requested key could not be found.
 *	@return		value	if the requested key is found.
 */
stock GetConfigValue(String:TheString[], TheSize, String:KeyName[]) {
	
	static String:text[512];

	new a_Size			= GetArraySize(MainKeys);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:MainKeys, i, text, sizeof(text));

		if (StrEqual(text, KeyName)) {

			GetArrayString(Handle:MainValues, i, TheString, TheSize);
			return;
		}
	}
	Format(TheString, TheSize, "-1");
}

stock Float:GetConfigValueFloat(String:KeyName[]) {
	
	static String:text[512];

	new a_Size			= GetArraySize(MainKeys);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:MainKeys, i, text, sizeof(text));

		if (StrEqual(text, KeyName)) {

			GetArrayString(Handle:MainValues, i, text, sizeof(text));
			return StringToFloat(text);
		}
	}
	return -1.0;
}

stock GetConfigValueInt(String:KeyName[]) {
	
	static String:text[512];

	new a_Size			= GetArraySize(MainKeys);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:MainKeys, i, text, sizeof(text));

		if (StrEqual(text, KeyName)) {

			GetArrayString(Handle:MainValues, i, text, sizeof(text));
			return StringToInt(text);
		}
	}
	return -1;
}

/*
 *	Checks if any survivors are incapacitated.
 *	@return		true/false		depending on the result.
 */
stock bool:AnySurvivorsIncapacitated() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i)) && IsIncapacitated(i)) return true;
	}
	return false;
}

/*
 *	Checks if there are any non-bot, non-spectator players in the game.
 *	@return		true/false		depending on the result.
 */
stock bool:IsPlayersParticipating() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR) return true;
	}
	return false;
}

/*
 *	Finds a random, non-infected client in-game.
 *	@return		client index if found.
 *	@return		-1 if not found.
 */
stock FindAnyRandomClient(bool:bMustBeAlive = false, ignoreclient = 0) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i)) && !IsLedged(i) && (GetEntityFlags(i) & FL_ONGROUND) && i != ignoreclient) {

			if (bMustBeAlive && IsPlayerAlive(i) || !bMustBeAlive) return i;
		}
	}
	return -1;
}

stock bool:IsMeleeWeaponParameter(String:parameter[]) {

	if (StrEqual(parameter, "fireaxe", false) ||
		StrEqual(parameter, "cricket_bat", false) ||
		StrEqual(parameter, "tonfa", false) ||
		StrEqual(parameter, "frying_pan", false) ||
		StrEqual(parameter, "golfclub", false) ||
		StrEqual(parameter, "electric_guitar", false) ||
		StrEqual(parameter, "katana", false) ||
		StrEqual(parameter, "machete", false) ||
		StrEqual(parameter, "crowbar", false)) return true;
	return false;
}

stock GetMeleeWeaponDamage(attacker, victim, String:weapon[]) {

	new zombieclass				= FindZombieClass(victim);
	new size					= GetArraySize(a_Melee_Damage);
	new healthvalue				= 0;

	decl String:s_zombieclass[4];

	for (new i = 0; i < size; i++) {

		MeleeKeys[attacker]		= GetArrayCell(a_Melee_Damage, i, 0);
		MeleeValues[attacker]	= GetArrayCell(a_Melee_Damage, i, 1);
		MeleeSection[attacker]	= GetArrayCell(a_Melee_Damage, i, 2);

		GetArrayString(Handle:MeleeSection[attacker], 0, s_zombieclass, sizeof(s_zombieclass));
		if (StringToInt(s_zombieclass) == zombieclass) {

			healthvalue			= RoundToCeil(GetKeyValueFloat(MeleeKeys[attacker], MeleeValues[attacker], weapon) * GetMaximumHealth(victim));
			if (healthvalue > GetClientTotalHealth(victim)) healthvalue		= GetClientTotalHealth(victim);
			return healthvalue;
		}
	}
	return 0;
}

/*
 *	Checks to see if the client has an active experience booster.
 *	If the client does, ExperienceValue is multiplied against the booster value and returned.
 *	@return (ExperienceValue * Multiplier)		where Multiplier is modified based on the result of AddMultiplier(client, i)
 */
stock Float:CheckExperienceBooster(client, ExperienceValue) {

	// Return ExperienceValue as it is if the client doesn't have a booster active.
	decl String:key[64];
	decl String:value[64];

	new Float:Multiplier					= 0.0;	// 1.0 is the DEFAULT (Meaning NO CHANGE)

	new size								= GetArraySize(a_Store);
	new size2								= 0;
	for (new i = 0; i < size; i++) {

		StoreKeys[client]					= GetArrayCell(a_Store, i, 0);
		StoreValues[client]					= GetArrayCell(a_Store, i, 1);

		size2								= GetArraySize(StoreKeys[client]);
		for (new ii = 0; ii < size2; ii++) {

			GetArrayString(StoreKeys[client], ii, key, sizeof(key));
			GetArrayString(StoreValues[client], ii, value, sizeof(value));

			if (StrEqual(key, "item effect?") && StrEqual(value, "x")) {

				Multiplier += AddMultiplier(client, i);		// If the client has no time in it, it just adds 0.0.
			}
		}
	}

	return Multiplier;
}

/*
 *	Checks to see whether:
 *	a.) The position in the store is an experience booster
 *	b.) If it is, if the client has time remaining in it.
 *	@return		Float:value			time remaining on experience booster. 0.0 if it could not be found.
 */
stock Float:AddMultiplier(client, pos) {

	if (!IsLegitimateClient(client) || pos >= GetArraySize(a_Store_Player[client])) return 0.0;
	decl String:ClientValue[64];
	GetArrayString(a_Store_Player[client], pos, ClientValue, sizeof(ClientValue));

	decl String:key[64];
	decl String:value[64];

	if (StringToInt(ClientValue) > 0) {

		StoreMultiplierKeys[client]			= GetArrayCell(a_Store, pos, 0);
		StoreMultiplierValues[client]		= GetArrayCell(a_Store, pos, 1);

		new size							= GetArraySize(StoreMultiplierKeys[client]);
		for (new i = 0; i < size; i++) {

			GetArrayString(StoreMultiplierKeys[client], i, key, sizeof(key));
			GetArrayString(StoreMultiplierValues[client], i, value, sizeof(value));

			if (StrEqual(key, "item strength?")) return StringToFloat(value);
		}
	}

	return 0.0;		// It wasn't found, so no multiplier is added.
}

stock String:GetEntityName(ent) {

	decl String:EntityName[64];
	if (IsValidEntity(ent)) GetEntityClassname(ent, EntityName, sizeof(EntityName));
}

stock bool:IsPlayerUsingShotgun(client) {

	new CurrentEntity								= GetPlayerWeaponSlot(client, 0);

	decl String:EntityName[64];
	if (IsValidEntity(CurrentEntity)) GetEntityClassname(CurrentEntity, EntityName, sizeof(EntityName));
	if (StrContains(EntityName, "shotgun", false) != -1) return true;
	return false;
}

stock String:GetMeleeWeapon(client) {

	decl String:Weapon[64];
	new g_iActiveWeaponOffset = 0;
	new iWeapon = 0;
	GetClientWeapon(client, Weapon, sizeof(Weapon));
	if (StrEqual(Weapon, "weapon_melee", false)) {

		g_iActiveWeaponOffset = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
		iWeapon = GetEntDataEnt2(client, g_iActiveWeaponOffset);
		GetEntityClassname(iWeapon, Weapon, sizeof(Weapon));
		GetEntPropString(iWeapon, Prop_Data, "m_strMapSetScriptName", Weapon, sizeof(Weapon));
	}
	else Format(Weapon, sizeof(Weapon), "null");
	return Weapon;
}

stock String:GetWeaponName(client) {

	decl String:Weapon[64];
	GetClientWeapon(client, Weapon, sizeof(Weapon));
	return Weapon;
}

stock RefuelAmmo(client) {

	if (!IsLegitimateClientAlive(client) || GetClientTeam(client) != TEAM_SURVIVOR) return -1;

	decl String:Weapon[64];
	new Bullets = 0;
	//new Reserve = 0;
	new WeaponId =	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	new WeaponSlot = -1;
	if (!IsValidEntity(WeaponId)) return -1; // ???
	GetEntityClassname(WeaponId, Weapon, sizeof(Weapon));
	if (StrContains(Weapon, "chainsaw", false) != -1 ||
		StrContains(Weapon, "melee", false) != -1) {

		WeaponSlot = 0;
	}
	else if (StrContains(Weapon, "weapon_", false) != -1) {

		if (StrContains(Weapon, "pistol", false) != -1) return -1;
		WeaponSlot = 1;
	}
	WeaponId =	GetPlayerWeaponSlot(client, WeaponSlot);
	if (!IsValidEntity(WeaponId)) return -1;
	GetEntityClassname(WeaponId, Weapon, sizeof(Weapon));
	if (WeaponSlot == 1) {

		if (StrContains(Weapon, "chainsaw", false) == -1) return -1;
		Bullets = GetEntProp(WeaponId, Prop_Send, "m_iClip1");
		if (Bullets < 30) SetEntProp(WeaponId, Prop_Send, "m_iClip1", Bullets + 1);
	}
	else if (WeaponSlot == 0) {

		/*Reserve = GetEntProp(WeaponId, Prop_Send, "m_iExtraPrimaryAmmo", 4);
		if (StrContains(Weapon, "m60", false) != -1) {

			Bullets = GetEntProp(WeaponId, Prop_Send, "m_iClip1");
			if (Bullets < 150) SetEntProp(WeaponId, Prop_Send, "m_iClip1", Bullets + 1);
			else if (Reserve < 150) SetEntProp(WeaponId, Prop_Send, "m_iExtraPrimaryAmmo", Reserve + 1, 4);
		}
		else if (StrContains(Weapon, "launcher", false) != -1) {

			if (Reserve < 15) SetEntProp(WeaponId, Prop_Send, "m_iExtraPrimaryAmmo", Reserve + 1, 4);
		}
		else if (Reserve < 500) SetEntProp(WeaponId, Prop_Send, "m_iExtraPrimaryAmmo", Reserve + 1, 4);*/

		Bullets = GetEntProp(WeaponId, Prop_Send, "m_iClip1");
		if (StrContains(Weapon, "m60", false) != -1) {

			if (Bullets < 150) SetEntProp(WeaponId, Prop_Send, "m_iClip1", Bullets + 1);
		}
		else if (StrContains(Weapon, "grenade", false) != -1) {

			if (Bullets < 5) SetEntProp(WeaponId, Prop_Send, "m_iClip1", Bullets + 1);
		}
		else if (Bullets < 300) SetEntProp(WeaponId, Prop_Send, "m_iClip1", Bullets + 1);
	}
	return 0;
}

stock bool:IsMeleeWeapon(client) {

	decl String:Weapon[64];
	GetClientWeapon(client, Weapon, sizeof(Weapon));
	if (StrEqual(Weapon, "weapon_melee", false) || StrContains(Weapon, "chainsaw", false) != -1) return true;
	return false;
}

stock DataScreenWeaponDamage(client, bool:bIsBaseDamageOnly = false) {

	decl String:text[64];
	GetClientAimTargetEx(client, text, sizeof(text));

	decl String:aimtarget[3][64];
	ExplodeString(text, " ", aimtarget, 3, 64);

	if (!bIsBaseDamageOnly) return GetBaseWeaponDamage(client, -1, StringToFloat(aimtarget[0]), StringToFloat(aimtarget[1]), StringToFloat(aimtarget[2]), DMG_BULLET);
	else return GetBaseWeaponDamage(client, -1, StringToFloat(aimtarget[0]), StringToFloat(aimtarget[1]), StringToFloat(aimtarget[2]), DMG_BULLET, true);
}

stock GetBaseWeaponDamage(client, target, Float:impactX = 0.0, Float:impactY = 0.0, Float:impactZ = 0.0, damagetype, bool:bGetBaseDamage = false) {

	decl String:WeaponName[512];
	decl String:Weapon[512];
	new WeaponId = -1;
	new g_iActiveWeaponOffset = 0;
	new iWeapon = 0;
	new bool:IsMelee = false;
	GetClientWeapon(client, Weapon, sizeof(Weapon));
	if (StrEqual(Weapon, "weapon_melee", false)) {

		IsMelee = true;
		g_iActiveWeaponOffset = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
		iWeapon = GetEntDataEnt2(client, g_iActiveWeaponOffset);
		GetEntityClassname(iWeapon, Weapon, sizeof(Weapon));
		GetEntPropString(iWeapon, Prop_Data, "m_strMapSetScriptName", Weapon, sizeof(Weapon));
	}
	else if (StrContains(Weapon, "weapon_", false) != -1) {

		if (StrContains(Weapon, "pistol", false) == -1 && StrContains(Weapon, "chainsaw", false) == -1) WeaponId = GetPlayerWeaponSlot(client, 0);
		else {

			WeaponId = GetPlayerWeaponSlot(client, 1);
			if (StrContains(Weapon, "chainsaw", false) != -1) IsMelee = true;
		}
		if (IsValidEntity(WeaponId)) GetEntityClassname(WeaponId, Weapon, sizeof(Weapon));
		else return -1;
	}

	new WeaponDamage = 0;
	new Float:WeaponRange = 0.0;
	new Float:WeaponDamageRangePenalty = 0.0;
	new Float:RangeRequired = 0.0;

	new Float:cpos[3];
	new Float:tpos[3];
	GetClientAbsOrigin(client, cpos);
	if (target != -1) {

		if (IsLegitimateClientAlive(target)) GetClientAbsOrigin(target, tpos);
		else if (IsWitch(target) || IsSpecialCommon(target) || IsCommonInfected(target)) GetEntPropVector(target, Prop_Send, "m_vecOrigin", tpos);
	}
	else {

		tpos[0] = impactX;
		tpos[1] = impactY;
		tpos[2] = impactZ;
	}

	new Float:Distance = GetVectorDistance(cpos, tpos);
	//PrintToChat(client, "Distance: %3.3f", Distance);
	/*new talentclient = client;
	if (IsFakeClient(talentclient)) talentclient = FindAnyRandomClient();
	if (!IsLegitimateClient(talentclient) || IsFakeClient(talentclient)) {	// we don't require life because... maybe we can let bots keep playing if all human survivors are dead?

		return 0;	// if there are no human players in the server at all, the bot can't deal damage, at least to specials and witches.
	}*/

	new baseWeaponTemp = 0;

	new size = GetArraySize(a_WeaponDamages);
	for (new i = 0; i < size; i++) {

		DamageKeys[client] = GetArrayCell(a_WeaponDamages, i, 0);
		DamageValues[client] = GetArrayCell(a_WeaponDamages, i, 1);
		DamageSection[client] = GetArrayCell(a_WeaponDamages, i, 2);
		GetArrayString(Handle:DamageSection[client], 0, WeaponName, sizeof(WeaponName));
		if (!StrEqual(WeaponName, Weapon, false)) continue;
		WeaponDamage = GetKeyValueInt(DamageKeys[client], DamageValues[client], "damage");

		//if (!(damagetype & DMG_BURN)) {

 		//if (HasAdrenaline(attacker)) baseWeaponDamage += RoundToCeil(baseWeaponDamage * GetConfigValueFloat("adrenaline damage modifier?"));

 		baseWeaponTemp = WeaponDamage;
 		baseWeaponTemp = RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "d"));
 		if (target != -1 && !IsSurvivor(target)) baseWeaponTemp += RoundToCeil(GetClassMultiplier(client, WeaponDamage * (1.0 - GetTankingContribution(client, WeaponDamage)), "STK"));
 		if ((GetEntityFlags(client) & FL_INWATER)) {

 			baseWeaponTemp += RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "wtrDMG", _, true));
 		}
 		else if (!(GetEntityFlags(client) & FL_ONGROUND)) {

 			baseWeaponTemp += RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "airDMG", _, true));
 		}
 		if ((GetEntityFlags(client) & FL_ONFIRE)) {

 			baseWeaponTemp += RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "fireDMG", _, true));
 		}

 		// The player, above, receives a flat damage increase of 50% just for having adrenaline active.
 		// Now, we increase their damage if they're in rage ammo, which is a separate thing, although it also provides the adrenaline buff.
 		if (IsClientInRangeSpecialAmmo(client, "a") == -2.0) baseWeaponTemp += RoundToCeil(WeaponDamage * IsClientInRangeSpecialAmmo(client, "a", false, _, WeaponDamage * 1.0));
 		if (IsClientInRangeSpecialAmmo(client, "d") == -2.0) baseWeaponTemp += RoundToCeil(WeaponDamage * IsClientInRangeSpecialAmmo(client, "d", false, _, WeaponDamage * 1.0));
 		if (IsClientInRangeSpecialAmmo(client, "E") == -2.0) baseWeaponTemp += RoundToCeil(WeaponDamage * IsClientInRangeSpecialAmmo(client, "E", false, _, WeaponDamage * 1.0));
 		if (IsLegitimateClientAlive(target) && IsClientInRangeSpecialAmmo(target, "E") == -2.0) baseWeaponTemp += RoundToCeil(WeaponDamage * IsClientInRangeSpecialAmmo(target, "E", false, _, WeaponDamage * 1.0));
		//}
		//else
		if (damagetype == DMG_BURN) baseWeaponTemp += RoundToCeil(GetAbilityStrengthByTrigger(client, target, 'G', FindZombieClass(client), WeaponDamage, _, _, "d", 1));	// THE 1 simply means that it adds the damagevalue before multiplying; if the player has no points in the talent, they do the base damage instead.
		if (damagetype == DMG_BLAST) baseWeaponTemp += RoundToCeil(GetAbilityStrengthByTrigger(client, target, 'S', FindZombieClass(client), WeaponDamage, _, _, "d", 1));
		if (damagetype == DMG_CLUB) baseWeaponTemp += RoundToCeil(GetAbilityStrengthByTrigger(client, target, 'U', FindZombieClass(client), WeaponDamage, _, _, "d", 1));
	 	if (damagetype == DMG_SLASH) baseWeaponTemp += RoundToCeil(GetAbilityStrengthByTrigger(client, target, 'u', FindZombieClass(client), WeaponDamage, _, _, "d", 1));

		if (baseWeaponTemp > 0) WeaponDamage = baseWeaponTemp;
		
		WeaponRange = GetKeyValueFloat(DamageKeys[client], DamageValues[client], "rng");

		//if (!IsMelee && (damagetype & DMG_BULLET)) {
		if (!IsMelee) {

			WeaponRange = GetClassMultiplier(client, WeaponRange, "gunRNG");
			WeaponDamage = RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "gunDMG"));

			if (bIsInCombat[client]) {

				WeaponRange = GetClassMultiplier(client, WeaponRange, "ICwRNG");
				WeaponDamage = RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "ICwDMG"));
			}
			else {

				WeaponRange = GetClassMultiplier(client, WeaponRange, "OCwRNG");
				WeaponDamage = RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "OCwDMG"));
			}
		}
		else if (IsMelee) {

			WeaponDamage = RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "mDMG"));
		}
		RangeRequired = 0.0;
		// StringToFloat(GetKeyValue(DamageKeys[client], DamageValues[client], "range required?"));
		if (Distance > WeaponRange && WeaponRange > 0.0) {

			/*

				In order to balance weapons and prevent one weapon from being the all-powerful go-to choice
				a weapon fall-off range is introduced.
				The amount of damage when receiving this penalty is equal to
				RoundToCeil(((Distance - WeaponRange) / WeaponRange) * damage);

				We subtract this value from overall damage.

				Some weapons (like certain sniper rifles) may not have a fall-off range.
			*/
			WeaponDamageRangePenalty = 1.0 - ((Distance - WeaponRange) / WeaponRange);
			WeaponDamage = RoundToCeil(WeaponDamage * WeaponDamageRangePenalty);
			if (WeaponDamage < 1) WeaponDamage = 1;		// If you're double the range or greater, congrats, bb gun.
		}
		if (Distance <= RangeRequired && RangeRequired > 0.0) {

			WeaponDamageRangePenalty = 1.0 - ((RangeRequired - Distance) / RangeRequired);
			WeaponDamage = RoundToCeil(WeaponDamage * WeaponDamageRangePenalty);
			if (WeaponDamage < 1) WeaponDamage = 1;
		}
		//LogToFile(LogPathDirectory, "%s Damage: %d", Weapon, WeaponDamage);
		//LogMessage("%N will deal %d damage", client, WeaponDamage);

		if (StrContains(Weapon, "sniper", false) != -1 || StrContains(Weapon, "huntingrifle", false) != -1) WeaponDamage = RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "snprDMG"));
		if (StrContains(Weapon, "pistol", false) != -1) WeaponDamage = RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "pstlDMG"));
		if (StrContains(Weapon, "rifle", false) != -1) WeaponDamage = RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "riflDMG"));
		if (StrContains(Weapon, "shotgun", false) != -1) WeaponDamage = RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "shtgDMG"));
		if (StrContains(Weapon, "smg", false) != -1) WeaponDamage = RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "smgDMG"));
		if (StrContains(Weapon, "auto", false) != -1 || StrContains(Weapon, "spas", false) != -1) WeaponDamage = RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "atsgDMG"));
		if (StrContains(Weapon, "pump", false) != -1 || StrContains(Weapon, "chrome", false) != -1) WeaponDamage = RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "pusgDMG"));
		if (StrContains(Weapon, "awp", false) != -1 || StrContains(Weapon, "scout", false) != -1) WeaponDamage = RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "boltDMG"));
		if (StrContains(Weapon, "awp", false) != -1 || StrContains(Weapon, "magnum", false) != -1) WeaponDamage = RoundToCeil(GetClassMultiplier(client, WeaponDamage * 1.0, "50caDMG"));
		return WeaponDamage;
	}
	//LogMessage("Could not find header for %s", Weapon);
	return 0;
}

stock bool:IsSurvivor(client) {

	if (IsLegitimateClient(client) && GetClientTeam(client) == TEAM_SURVIVOR) return true;
	return false;
}

stock bool:IsFireDamage(damagetype) {

	if (damagetype == 8 || damagetype == 2056 || damagetype == 268435464) return true;
	return false;
}

stock String:GetSurvivorBotName(client, String:TheBuffer[], TheSize) {

	decl String:TheName[64];
	GetClientName(client, TheName, sizeof(TheName));
	if (StrContains(TheName, "Survivor Bot", false) != -1) {	// debug

		decl String:TheModel[64];
		GetClientModel(client, TheModel, sizeof(TheModel));	// helms deep creates bots that aren't necessarily on the survivor team.
		
		if (StrEqual(TheModel, NICK_MODEL)) Format(TheName, sizeof(TheName), "Nick");
		else if (StrEqual(TheModel, ROCHELLE_MODEL)) Format(TheName, sizeof(TheName), "Rochelle");
		else if (StrEqual(TheModel, COACH_MODEL)) Format(TheName, sizeof(TheName), "Coach");
		else if (StrEqual(TheModel, ELLIS_MODEL)) Format(TheName, sizeof(TheName), "Ellis");
		else if (StrEqual(TheModel, LOUIS_MODEL)) Format(TheName, sizeof(TheName), "Louis");
		else if (StrEqual(TheModel, ZOEY_MODEL)) Format(TheName, sizeof(TheName), "Zoey");
		else if (StrEqual(TheModel, BILL_MODEL)) Format(TheName, sizeof(TheName), "Bill");
		else if (StrEqual(TheModel, FRANCIS_MODEL)) Format(TheName, sizeof(TheName), "Francis");
	}
	Format(TheBuffer, TheSize, "%s", TheName);
}

stock bool:IsSurvivorBot(client) {

	if (IsLegitimateClient(client) && IsFakeClient(client) && GetClientTeam(client) == TEAM_SURVIVOR) {

		/*decl String:TheCurr[64];
		GetCurrentMap(TheCurr, sizeof(TheCurr));
		if (StrContains(TheCurr, "helms_deep", false) == -1) {

			if (GetClientTeam(client) == TEAM_SURVIVOR) return true;
		}
		else {*/

		decl String:TheModel[64];
		GetClientModel(client, TheModel, sizeof(TheModel));	// helms deep creates bots that aren't necessarily on the survivor team.
		if (StrEqual(TheModel, NICK_MODEL) ||
			StrEqual(TheModel, ROCHELLE_MODEL) ||
			StrEqual(TheModel, COACH_MODEL) ||
			StrEqual(TheModel, ELLIS_MODEL) ||
			StrEqual(TheModel, ZOEY_MODEL) ||
			StrEqual(TheModel, FRANCIS_MODEL) ||
			StrEqual(TheModel, LOUIS_MODEL) ||
			StrEqual(TheModel, BILL_MODEL)) {

			return true;
		}
	}
	return false;
}

stock bool:IsSurvivorPlayer(client) {

	if (IsLegitimateClient(client) && (GetClientTeam(client) == TEAM_SURVIVOR || IsSurvivorBot(client))) return true;
	return false;
}

stock bool:CommonInfectedModel(ent, String:SearchKey[]) {

	decl String:ModelName[64];
 	GetEntPropString(ent, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
 	if (StrContains(ModelName, SearchKey, false) != -1) return true;
 	return false;
}

stock GetSurvivorsInRange(client, Float:Distance) {

	new Float:cpos[3];
	new Float:spos[3];
	new count = 0;
	GetClientAbsOrigin(client, cpos);

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
		GetClientAbsOrigin(i, spos);
		if (GetVectorDistance(cpos, spos) <= Distance) count++;
	}
	return count;
}

stock bool:SurvivorsWithinRange(client, Float:Distance) {

	new Float:cpos[3];
	new Float:spos[3];
	GetClientAbsOrigin(client, cpos);

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
		GetClientAbsOrigin(i, spos);
		if (GetVectorDistance(cpos, spos) <= Distance) return true;
	}
	return false;
}

stock bool:IsClientInRange(client, target, Float:range) {

	new Float:cpos[3];
	new Float:tpos[3];
	if (IsCommonInfected(client) || IsWitch(client)) GetEntPropVector(client, Prop_Send, "m_vecOrigin", cpos);
	else GetClientAbsOrigin(client, cpos);
	if (IsCommonInfected(target) || IsWitch(target)) GetEntPropVector(target, Prop_Send, "m_vecOrigin", tpos);
	else GetClientAbsOrigin(target, tpos);

	if (GetVectorDistance(cpos, tpos) <= range) return true;
	return false;
}

stock bool:CheckTankState(client, String:StateName[]) {

	decl String:text[64];
	for (new i = 0; i < GetArraySize(TankState_Array[client]); i++) {

		GetArrayString(TankState_Array[client], i, text, sizeof(text));
		if (StrEqual(text, StateName)) return true;	
	}
	//if (GetArraySize(TankState_Array[client]))
	return false;
}

stock ChangeTankState(client, String:StateName[], bool:IsDelete = false, bool:GetState = false) {

	if (!b_IsActiveRound) return -1;
	if (!IsLegitimateClientAlive(client) || FindZombieClass(client) != ZOMBIECLASS_TANK) return -3;

	decl String:text[64];
	new size = GetArraySize(TankState_Array[client]);

	decl String:sCurState[64];
	if (size > 0) GetArrayString(TankState_Array[client], 0, sCurState, sizeof(sCurState));

	if (GetState || IsDelete) {

		//if (size < 1 && IsDelete) return 0;
		if (size < 1) return 0;
		if (StrEqual(text, StateName)) {

			if (!IsDelete) return 1;
			ClearArray(TankState_Array[client]);
			return -1;
		}
	}
	else {

		if (iTanksPreset == 0 && size > 0 && !StrEqual(sCurState, StateName) || size < 1) {

			if (size > 0) SetArrayString(Handle:TankState_Array[client], 0, StateName);
			else PushArrayString(Handle:TankState_Array[client], StateName);

			if (iTanksPreset == 1) {

				decl String:sTank[64];
				Format(sTank, sizeof(sTank), "tank spawn:%s", StateName);
				decl String:sText[64];
				for (new i = 1; i <= MaxClients; i++) {

					if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;
					Format(sText, sizeof(sText), "%T", sTank, i);
					PrintToChat(i, "%T", "tank spawn notification", i, orange, sText, white, blue);
				}
			}

			if (StrEqual(StateName, "hulk")) {

				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 0, 255, 0, 255);
				SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.5);
			}
			else if (StrEqual(StateName, "death")) {

				//ClearArray(Handle:TankState_Array[client]);	// you who walks through the valley of death loses everything.

				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 0, 0, 0, 255);
			}
			else if (StrEqual(StateName, "burn")) {

				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 255, 0, 0, 200);
				SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.5);
			}
			else if (StrEqual(StateName, "teleporter")) {

				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 50, 50, 255, 200);
				SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.75);

				if (b_IsActiveRound) FindRandomSurvivorClient(client, true);
			}
			/*else {

				if (StrEqual(StateName, "burn")) {

					if (!(GetEntityFlags(client) & FL_ONFIRE)) IgniteEntity(client, 30.0);
					SetEntityRenderMode(client, RENDER_TRANSCOLOR);
					SetEntityRenderColor(client, 255, 0, 0, 255);
				}
				else if ((GetEntityFlags(client) & FL_ONFIRE)) ExtinguishEntity(client);
			}*/
		}
		return 2;
	}
	return -2;
}

stock FindRandomSurvivorClient(client, bool:bIsTeleportTo = false, bool:bPrioritizeTanks = true) {

	if (!IsLegitimateClientAlive(client) || !b_IsActiveRound) return;

	ClearArray(Handle:RandomSurvivorClient);
	decl String:ClassRoles[64];
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i))) {

			if (client == i) continue;

			if (bPrioritizeTanks) {

				GetMenuOfTalent(i, ActiveClass[i], ClassRoles, sizeof(ClassRoles));
				if (StrContains(ClassRoles, "Tank", false) != -1) PushArrayCell(RandomSurvivorClient, i);
			}
			else PushArrayCell(RandomSurvivorClient, i);
		}
	}
	if (bPrioritizeTanks && GetArraySize(RandomSurvivorClient) < 1) {

		//if (TotalHumanSurvivors() >= 4) FindRandomSurvivorClient(client, bIsTeleportTo, false);	// now all clients are viable.
		return;
	}
	new size = GetArraySize(RandomSurvivorClient);
	if (size < 1) return;

	new target = GetRandomInt(1, size);
	target = GetArrayCell(RandomSurvivorClient, target - 1);

	new Float:Origin[3];
	GetClientAbsOrigin(target, Origin);
	/*decl String:text[64];
	GetClientAimTargetEx(target, text, sizeof(text));

	decl String:aimtarget[3][64];
	ExplodeString(text, " ", aimtarget, 3, 64);

	new Float:Origin[3];
	Origin[0] = StringToFloat(aimtarget[0]);
	Origin[1] = StringToFloat(aimtarget[1]);
	Origin[2] = StringToFloat(aimtarget[2]);*/
	TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
	if (GetClientTeam(client) == TEAM_SURVIVOR && bRushingNotified[client]) {

		bRushingNotified[client] = false;
	}
	if (GetClientTeam(client) == TEAM_INFECTED) bHasTeleported[client] = true;
}

/*bool:AnySurvivorInRange(client, Float:Range) {

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR || IsFakeClient(i)) continue;
		if (IsClientInRange(client, i, Range)) return true;
	}
	return false;
}*/

stock CheckTankSubroutine(tank, survivor = 0, damage = 0, bool:TankIsVictim = false) {

	if (iRPGMode == -1) return;

	//if (IsSurvivalMode) return;

	if (IsLegitimateClientAlive(tank) && FindZombieClass(tank) == ZOMBIECLASS_TANK) {

		new DeathState		= ChangeTankState(tank, "death", _, true);

		if (DeathState != 1 && (IsSpecialCommonInRange(tank, 'w') || IsClientInRangeSpecialAmmo(tank, "W") == -2.0)) {

			//ChangeTankState(client, "hulk", true);
			ChangeTankState(tank, "death");
		}

		//if (survivor == 0 && damage == 0 && !(GetEntityFlags(tank) & FL_ONFIRE) && !SurvivorsInRange(tank)) ChangeTankState(tank, "teleporter");

		//new TankEnrageMechanic			= GetConfigValueInt("boss tank enrage count?");
		//new Float:TankTeleportMechanic	= GetConfigValueFloat("boss tank teleport distance?");

		if (GetEntityFlags(tank) & FL_INWATER) {

			ChangeTankState(tank, "burn", true);
		}
		new bool:IsDeath = false;

		//new DeathState		= ChangeTankState(tank, "death", _, true);
		new BurnState		= ChangeTankState(tank, "burn", _, true);
		new bool:IsOnFire = false;
		if ((GetEntityFlags(tank) & FL_ONFIRE) && BurnState != 1) {

			ExtinguishEntity(tank);
		}
		new bool:IsBiled	= ISBILED[tank];
		new IsHulkState		= ChangeTankState(tank, "hulk", _, true);

		//if (!IsBiled && IsOnFire && !DeathState) ChangeTankState(tank, "burn");
		/*if (IsBiled && BurnState) {

			ChangeTankState(tank, "burn", true);
			BurnState = 0;
			ExtinguishEntity(tank);
		}*/

		if (IsHulkState == 1) {

			if (!b_RescueIsHere) SetSpeedMultiplierBase(tank, 1.0);
			else SetSpeedMultiplierBase(tank, 2.0);

			SetEntityRenderMode(tank, RENDER_TRANSCOLOR);
			SetEntityRenderColor(tank, 0, 255, 0, 255);
		}
		else if (DeathState == 1) {

			if (!b_RescueIsHere) SetSpeedMultiplierBase(tank, 0.25);
			else SetSpeedMultiplierBase(tank, 0.5);

			SetEntityRenderMode(tank, RENDER_TRANSCOLOR);
			SetEntityRenderColor(tank, 0, 0, 0, 255);
		}
		else if (BurnState == 1) {

			if (!b_RescueIsHere) SetSpeedMultiplierBase(tank, 1.25);
			else SetSpeedMultiplierBase(tank, 2.5);

			SetEntityRenderMode(tank, RENDER_TRANSCOLOR);
			SetEntityRenderColor(tank, 255, 0, 0, 255);
			if (!(GetEntityFlags(tank) & FL_ONFIRE)) IgniteEntity(tank, 3.0);
		}
		if (BurnState != 1) ExtinguishEntity(tank);
		/*if (BurnState) {

			SetSpeedMultiplierBase(tank, 1.0);
			ChangeTankState(tank, "hulk", true);
			IsHulkState = 0;
			SetEntityRenderMode(tank, RENDER_TRANSCOLOR);
			SetEntityRenderColor(tank, 255, 0, 0, 255);
		}*/

		if (survivor == 0 || !IsLegitimateClientAlive(survivor) || GetClientTeam(survivor) != TEAM_SURVIVOR) return;

		decl String:ClassRoles[64];
		new bool:bSurvivorTank = false;
		GetMenuOfTalent(survivor, ActiveClass[survivor], ClassRoles, sizeof(ClassRoles));
		if (StrContains(ClassRoles, "Tank") != -1) bSurvivorTank = true;

		//new Float:IsSurvivorWeak = IsClientInRangeSpecialAmmo(survivor, "W");
		new Float:IsSurvivorReflect = 0.0;
		new bool:IsSurvivorBiled = false;

		if (IsLegitimateClientAlive(survivor) && GetClientTeam(survivor) == TEAM_SURVIVOR) {

			//IsClientInRangeSpecialAmmo(survivor, "R");
			//IsCoveredInVomit(survivor);
		}

		if (!TankIsVictim) {

			if (BurnState == 1) {

				new Count = GetClientStatusEffect(survivor, Handle:EntityOnFire, "burn");

				if (!IsSurvivorBiled && Count < iDebuffLimit) {

					//if (IsSurvivorReflect) CreateAndAttachFlame(tank, RoundToCeil(damage * 0.1), 10.0, 1.0, survivor, "burn");
					//else
					if (Count == 0) Count = 1;
					if (!bSurvivorTank) CreateAndAttachFlame(survivor, RoundToCeil((damage * fBurnPercentage) / Count), 10.0, 1.0, tank, "burn");
					else CreateAndAttachFlame(survivor, RoundToCeil((damage * fBurnPercentage) / Count), 5.0, 1.0, tank, "burn");
				}
			}
			if (!bSurvivorTank) ChangeTankState(tank, "hulk");
			else if (IsHulkState == 1 && bSurvivorTank) ChangeTankState(tank, "death");
			else if (DeathState == 1) {

				new SurvivorHealth = GetClientTotalHealth(survivor);

				if (!bSurvivorTank) {

					if (SurvivorHealth > 1) {

						SetClientTotalHealth(survivor, SurvivorHealth - 1);
						AddSpecialInfectedDamage(survivor, tank, SurvivorHealth - 1, true);
					}
				}
				else {

					new SurvivorHalfHealth = SurvivorHealth / 2;
					if (SurvivorHalfHealth / GetMaximumHealth(survivor) > 0.25) {

						SetClientTotalHealth(survivor, SurvivorHalfHealth);
						AddSpecialInfectedDamage(survivor, tank, SurvivorHalfHealth, true);
					}
				}
			}
			else if (IsHulkState == 1) {

				CreateExplosion(survivor, damage, tank, true);
			}
		}
		else {

			if (IsBiled) {

				if (BurnState == 1) ChangeTankState(tank, "hulk");
				SDKCall(g_hCallVomitOnPlayer, survivor, tank, true);
				//IsCoveredInVomit(survivor, tank);
				ISBILED[survivor] = true;
			}
		}
	}
}

stock HemomancerRoutine(client, party, damage, bool:IsAttacker = true) {

	if (IsLegitimateClient(client) && IsLegitimateClient(party) && GetClientTeam(client) == GetClientTeam(party)) return;

	if (StrContains(ActiveClass[client], "hemomancer", false) != -1) {	// hemomancers heal themselves when they deal damage and heal teammates when they take damage.
		
		new Float:HealerAmount = damage * 1.0;
		new bool:TheBool = false;
		if (IsAttacker) TheBool = IsMeleeAttacker(client);

		// when the hemomancer is the attacker.
		if (IsAttacker && (IsCommonInfected(party) || IsWitch(party) || IsLegitimateClientAlive(party) && GetClientTeam(party) != GetClientTeam(client))) {

	 		/*if (!TheBool) HealerAmount = GetClassMultiplier(client, damage * 1.0, "hB");
	 		else if (!bIsMeleeCooldown[client]) {

	 			bIsMeleeCooldown[client] = true;
				CreateTimer(0.05, Timer_IsMeleeCooldown, client, TIMER_FLAG_NO_MAPCHANGE);
	 			HealerAmount = GetClassMultiplier(client, damage * 1.0, "hM");

	 			HealerAmount *= 0.05;
	 		}*/
	 		//HealerAmount *= 0.2;
	 		if (HealerAmount > 0.0 && !HealImmunity[client]) {

	 			HealImmunity[client] = true;
	 			CreateTimer(0.05, Timer_HealImmunity, client, TIMER_FLAG_NO_MAPCHANGE);
	 			HealPlayer(client, client, HealerAmount, 'h', true);
	 		}
	 	}
	 	else if (!IsAttacker && (IsCommonInfected(party) || IsWitch(party) || IsLegitimateClientAlive(party) && GetClientTeam(party) != GetClientTeam(client))) {

	 		// the heal % isn't reduced when healing MULTIPLE teammates, making hemomancers INVALUABLE group healers.

	 		// if the other party is the attacker and the client is victim - hemomancers heal teammates who are in combat (regardless of range) but not themselves.
	 		//HealerAmount = GetClassMultiplier(client, damage * 1.0, "hM");
	 		new playersincombat = 0;
	 		for (new i = 1; i <= MaxClients; i++) {

	 			if (i != client && IsLegitimateClientAlive(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i)) && bIsInCombat[i]) playersincombat++;
	 		}
	 		if (playersincombat < 1) return;
	 		HealerAmount = HealerAmount / playersincombat;
	 		for (new i = 1; i <= MaxClients; i++) {

	 			if (i != client && IsLegitimateClientAlive(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i)) && bIsInCombat[i] && !HealImmunity[i]) {

	 				HealImmunity[i] = true;
	 				CreateTimer(0.05, Timer_HealImmunity, i, TIMER_FLAG_NO_MAPCHANGE);
	 				HealPlayer(i, client, HealerAmount, 'h', true);
	 			}
	 		}
	 	}
 	}
}

public Action:Hook_SetTransmit(entity, client) {
	
	if(EntIndexToEntRef(entity) == eBackpack[client]) return Plugin_Handled;
	return Plugin_Continue;
}

/*
 *	SDKHooks function.
 *	We're using it to prevent any melee damage, due to the bizarre way that melee damage is handled, it's hit or miss whether it is changed.
 *	@return Plugin_Changed		if a melee weapon was used.
 *	@return Plugin_Continue		if a melee weapon was not used.
 */

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage_ignore, &damagetype) {

//stock OnTakeDamage(victim, attacker, inflictor, Float:damage, damagetype) {

	new baseWeaponDamage = 0;
	if (IsLegitimateClient(attacker) && (GetClientTeam(attacker) == TEAM_SURVIVOR || IsSurvivorBot(attacker))) {

		VerifyHandicap(attacker);
		baseWeaponDamage = GetBaseWeaponDamage(attacker, victim, _, _, _, damagetype);
		//PrintToChat(attacker, "damage: %d", baseWeaponDamage);
	}

	new Float:damage = damage_ignore;
	if (damage <= 0.0) {

		// So survivor bots will now damage jimmy gibbs and riot police as if they were not uncommon infected.
		// If we don't do this, the bots don't understand that the weapons that the uncommons are immune to, and if they are in
		// possession of said weapon, will just shoot the bots indefinitely.

		if (!IsSurvivorBot(attacker)) {

			damage_ignore = 0.0;
			return Plugin_Handled;
		}
	}

	new bool:bIsEnrageActive = IsEnrageActive();
	if (bIsEnrageActive && (!IsLegitimateClient(attacker) || GetClientTeam(attacker) == TEAM_INFECTED)) {

		damage *= fEnrageModifier;
	}
	//new IgnoreDamage = 1;
	//new IgnoreTeam = 0;
	decl String:ModelName[64];
	decl String:TheMapName[64];
	GetCurrentMap(TheMapName, sizeof(TheMapName));
	new bool:bIsMeleeAttack = false;

	if (IsLegitimateClientAlive(attacker) && b_IsLoading[attacker] && GetClientTeam(attacker) == TEAM_SURVIVOR) {

		damage = 0.0;
		return Plugin_Handled;
	}
	if (IsLegitimateClientAlive(victim) && b_IsLoading[victim] && GetClientTeam(victim) == TEAM_SURVIVOR) {

		damage = 0.0;
		return Plugin_Handled;
	}

	if (IsLegitimateClientAlive(attacker) && !HasSeenCombat[attacker]) HasSeenCombat[attacker] = true;
	if (IsLegitimateClientAlive(victim) && !HasSeenCombat[victim]) HasSeenCombat[victim] = true;

	new loadtarget[2];
	loadtarget[0] = -1;
	loadtarget[1] = -1;
	if (IsLegitimateClientAlive(attacker) && !b_IsLoading[attacker] && PlayerLevel[attacker] < iPlayerStartingLevel) loadtarget[0] = attacker;
	if (IsLegitimateClientAlive(victim) && !b_IsLoading[victim] && PlayerLevel[victim] < iPlayerStartingLevel) loadtarget[1] = victim;

	decl String:DefaultProfileName[64];
	for (new i = 0; i < 2; i++) {

		if (IsLegitimateClientAlive(loadtarget[i]) && GetClientTeam(loadtarget[i]) == TEAM_SURVIVOR) {

			SetTotalExperienceByLevel(loadtarget[i], iPlayerStartingLevel);
			if (GetClientTeam(loadtarget[i]) == TEAM_SURVIVOR) GetConfigValue(DefaultProfileName, sizeof(DefaultProfileName), "new player profile?");
			else if (GetClientTeam(loadtarget[i]) == TEAM_INFECTED) GetConfigValue(DefaultProfileName, sizeof(DefaultProfileName), "new infected player profile?");
			if (StrContains(DefaultProfileName, "-1", false) == -1) LoadProfileEx(loadtarget[i], DefaultProfileName);
		}
	}
	if (!b_IsActiveRound || b_IsSurvivalIntermission) {

		damage_ignore = 0.0;
		return Plugin_Handled;
	}
	if (IsLegitimateClientAlive(victim) && RespawnImmunity[victim]) {

		damage_ignore = 0.0;
		return Plugin_Handled;
	}
	new Float:TheAbilityMultiplier = 0.0;
	if ((damagetype & DMG_CRUSH) && IsLegitimateClientAlive(victim)) {

		if (bIsCrushCooldown[victim]) {

			damage_ignore = 0.0;
			return Plugin_Handled;
		}
		bIsCrushCooldown[victim] = true;
		CreateTimer(1.0, Timer_ResetCrushImmunity, victim, TIMER_FLAG_NO_MAPCHANGE);
	}
	if ((damagetype & DMG_BURN) && IsLegitimateClientAlive(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && !IsSurvivorBot(victim)) {

		new iBurnCounter = GetClientStatusEffect(victim, Handle:EntityOnFire, "burn");
		//new iBurnDamage = RoundToCeil((1.0 * GetDifficultyRating(victim)) * (iBurnCounter + 1));
		if (iBurnCounter < 1 && fOnFireDebuff[victim] <= 0.0) {

			if (fOnFireDebuff[victim] == -1.0) {

				ExtinguishEntity(victim);
				fOnFireDebuff[victim] = 0.0;
			}
			else {

				fOnFireDebuff[victim] = fOnFireDebuffDelay;
				CreateAndAttachFlame(victim, ((iBurnCounter + 1) * PlayerLevel[victim]), 10.0, 0.4, FindInfectedClient(true), "burn");
			}
		}
		//PrintToChatAll("BURN: %d", iBurnDamage);

		damage_ignore = 0.0;
		return Plugin_Handled;
	}
	new cTank = -1;
	if (IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_INFECTED && FindZombieClass(attacker) == ZOMBIECLASS_TANK) cTank = attacker;
	else if (IsLegitimateClientAlive(victim) && GetClientTeam(victim) == TEAM_INFECTED && FindZombieClass(victim) == ZOMBIECLASS_TANK) cTank = victim;
	if (cTank > 0) {

		if (IsSpecialCommonInRange(cTank, 't') && !bIsDefenderTank[cTank]) {

			// tank copies nearby defender abilities, permanently.
			bIsDefenderTank[cTank] = true;
			SetEntityRenderMode(cTank, RENDER_TRANSCOLOR);
			SetEntityRenderColor(cTank, 0, 0, 255, 200);
			SetEntPropFloat(cTank, Prop_Send, "m_flModelScale", 2.0);
		}
	}
	if (IsCommonInfected(victim) || IsWitch(victim) || (IsLegitimateClientAlive(victim) && GetClientTeam(victim) == TEAM_INFECTED)) {

		//Commons, Witches, and Special Infected.
		if (IsSpecialCommonInRange(victim, 't')) {

			// If a Defender is within range, the entity is immune.
			// If the entity is a tyrant, it's also immune.
			damage_ignore = 0.0;
			return Plugin_Handled;
		}
		
 		GetEntPropString(victim, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
	}
	if (IsLegitimateClient(attacker) && bAutoRevive[attacker] && !IsIncapacitated(attacker)) bAutoRevive[attacker] = false;

	// We want to know what the most recent time a player took damage was. This is so some abilities are active only within a certain period of that time OR don't activate until a certain period after.
	if (IsLegitimateClientAlive(attacker)) LastAttackTime[attacker] = GetEngineTime();
	if (IsLegitimateClientAlive(victim)) LastAttackTime[victim] = GetEngineTime();

	if (IsLegitimateClientAlive(victim) && (GetClientTeam(victim) == TEAM_SURVIVOR || IsSurvivorBot(victim))) {

		CombatTime[victim] = GetEngineTime() + fOutOfCombatTime;
		JetpackRecoveryTime[victim] = GetEngineTime() + 1.0;
		ToggleJetpack(victim, true);

		if (damagetype & DMG_FALL || !IsLegitimateClient(attacker) && !IsCommonInfected(attacker) && !IsWitch(attacker)) {//CheckFallDamage(victim);

			//if (IsLegitimateClientAlive(attacker)) PrintToChat(victim, "%N caused the fall.", attacker);

			if (damagetype & DMG_FALL) {

				//new IncapFallDamage = RoundToCeil((damage * 0.005) * GetMaximumHealth(victim));
				//new DeathFallDamage = 

				new DMGFallDamage = RoundToCeil(damage_ignore);
				new MyInfectedAttacker = L4D2_GetInfectedAttacker(victim);
				if (MyInfectedAttacker != -1) DMGFallDamage = RoundToCeil(DMGFallDamage * 0.4);
				//if (damage < 100) DMGFallDamage = RoundToCeil((damage * 0.01) * GetMaximumHealth(victim));
				TheAbilityMultiplier = GetAbilityMultiplier(victim, 'F');
				if (TheAbilityMultiplier > 0.0) DMGFallDamage -= RoundToCeil(DMGFallDamage * TheAbilityMultiplier);
		
				if (DMGFallDamage < 100) {

					DMGFallDamage = RoundToCeil((damage_ignore * 0.01) * GetMaximumHealth(victim));
					SetClientTotalHealth(victim, DMGFallDamage, _, true);
				}
				else if (DMGFallDamage >= 100 && DMGFallDamage < 200) SetClientTotalHealth(victim, GetClientTotalHealth(victim), _, true);
				else IncapacitateOrKill(victim, _, _, true);
				//if (GetClientTotalHealth(victim) > DMGFallDamage) SetClientTotalHealth(victim, DMGFallDamage);// SetEntityHealth(victim, GetClientHealth(victim) - RoundToCeil(GetMaximumHealth(victim) * clientVel[2]));
				//else IncapacitateOrKill(victim, _, _, true);
				//else SetClientTotalHealth(victim, GetClientTotalHealth(victim));

				damage_ignore = 0.0;
				return Plugin_Handled;
			}
		}
		if (damagetype & DMG_DROWN) {

			if (!IsIncapacitated(victim)) SetClientTotalHealth(victim, GetClientTotalHealth(victim));
			else IncapacitateOrKill(victim, _, _, true);
			damage_ignore = 0.0;
			return Plugin_Handled;
		}
	}

 	new BuffDamage = 0;
 	new DamageShield = 0;
 	new ReflectIncomingDamage = 0;
 	decl String:TheCommonValue[10];

 	new theCount = LivingSurvivorCount();

	if (IsLegitimateClient(attacker) && (GetClientTeam(attacker) == TEAM_SURVIVOR || IsSurvivorBot(attacker))) b_IsDead[attacker] = false;
	if (IsLegitimateClient(victim) && (GetClientTeam(victim) == TEAM_SURVIVOR || IsSurvivorBot(victim))) b_IsDead[victim] = false;
	if (IsWitch(attacker) && IsLegitimateClient(victim) && (GetClientTeam(victim) == TEAM_SURVIVOR || IsSurvivorBot(victim))) {

		new i_WitchDamage = iWitchDamageInitial;
		if (IsSpecialCommonInRange(attacker, 'b')) {

			i_WitchDamage += GetSpecialCommonDamage(i_WitchDamage, attacker, 'b', victim);
		}

		if (fWitchDamageScaleLevel > 0.0 && iRPGMode >= 1) {

			i_WitchDamage += RoundToCeil(fWitchDamageScaleLevel * GetDifficultyRating(victim));
		}
		
		if (theCount >= iSurvivorModifierRequired) i_WitchDamage += RoundToCeil(i_WitchDamage * ((theCount - (iSurvivorModifierRequired - 1)) * fSurvivorDamageBonus));
		i_WitchDamage = RoundToCeil(GetClassMultiplier(victim, i_WitchDamage * 1.0, "D"));
		
		if (IsClientInRangeSpecialAmmo(victim, "D") == -2.0) DamageShield = RoundToCeil(i_WitchDamage * IsClientInRangeSpecialAmmo(victim, "D", false, _, i_WitchDamage * 1.0));
		if (DamageShield > 0) {

			i_WitchDamage -= DamageShield;
			if (i_WitchDamage < 0) i_WitchDamage = 0;
		}

		TheAbilityMultiplier = GetAbilityMultiplier(victim, 'X', 4);
		if (TheAbilityMultiplier >= 1.0) {	// Damage taken reduced to 0.

			damage_ignore = 0.0;
			return Plugin_Handled;
		}
		else if (TheAbilityMultiplier > 0.0) {	// Damage received is reduced by the amount.

			i_WitchDamage -= RoundToCeil(i_WitchDamage * TheAbilityMultiplier);
		}

		if (IsSurvivalMode || RPGRoundTime() < iEnrageTime) Points_Director += (fWitchDirectorPoints * i_WitchDamage);
		else Points_Director += (fEnrageDirectorPoints * i_WitchDamage);

		SetClientTotalHealth(victim, i_WitchDamage);
		ReceiveWitchDamage(victim, attacker, i_WitchDamage);
		GetAbilityStrengthByTrigger(victim, attacker, 'L', FindZombieClass(victim), i_WitchDamage);

		// Reflect damage.
		if (IsClientInRangeSpecialAmmo(victim, "R") == -2.0) ReflectIncomingDamage = RoundToCeil(i_WitchDamage * IsClientInRangeSpecialAmmo(victim, "R", false, _, i_WitchDamage * 1.0));
		
		if (ReflectIncomingDamage > 0) {

			//IgnoreDamage = AddWitchDamage(victim, attacker, ReflectIncomingDamage);
			AddWitchDamage(victim, attacker, ReflectIncomingDamage);
			//IgnoreTeam = 5;
		}
		HemomancerRoutine(victim, attacker, i_WitchDamage, false);
	}
	if ((attacker < 1 || !IsClientActual(attacker)) && IsLegitimateClient(victim) && (GetClientTeam(victim) == TEAM_SURVIVOR || IsSurvivorBot(victim))) {

		new Float:CommonDamageScaleLevel = fCommonDamageLevel;
		
		if (IsLegitimateClientAlive(victim)) b_IsDead[victim] = false;
		//if (ActiveProgressBar(victim))

		if (IsCommonInfected(attacker)) {

			new CommonsDamage = RoundToCeil(damage);
			if (IsSpecialCommonInRange(attacker, 'b')) {

				CommonsDamage += GetSpecialCommonDamage(CommonsDamage, attacker, 'b', victim);
			}
			if (!(damagetype & DMG_DIRECT)) {

				if (b_IsJumping[victim]) ModifyGravity(victim);
							
				//new CommonsDamage = RoundToCeil(damage);
				if (CommonDamageScaleLevel > 0.0) {

					if (iBotLevelType == 0 && iRPGMode >= 1) {

						CommonsDamage = RoundToCeil(CommonsDamage * (CommonDamageScaleLevel * GetDifficultyRating(victim)));
					}
					else {

						CommonsDamage = RoundToCeil(CommonsDamage * (CommonDamageScaleLevel * SurvivorLevels()));
					}
				}
				
				// Commented this out because I don't know why it's here...
				/*if (L4D2_GetInfectedAttacker(victim) != -1) {

					new eInfectedAttacker = L4D2_GetInfectedAttacker(victim);

					isEntityPos = FindListPositionByEntity(eInfectedAttacker, Handle:InfectedHealth[victim]);

					if (isEntityPos < 0) {

						//isArraySize = GetArraySize(Handle:InfectedHealth[victim]);
						isEntityPos = InsertInfected(victim, eInfectedAttacker);
					}
					else if (isEntityPos >= 0 && GetArraySize(InfectedHealth[victim]) > isEntityPos) SetArrayCell(Handle:InfectedHealth[victim], isEntityPos, GetArrayCell(Handle:InfectedHealth[victim], isEntityPos, 3) + CommonsDamage, 3);
				}*/
				if (theCount >= iSurvivorModifierRequired) CommonsDamage += RoundToCeil(CommonsDamage * ((theCount - (iSurvivorModifierRequired - 1)) * fSurvivorDamageBonus));
				//CommonsDamage += RoundToCeil(CommonsDamage * ((LivingSurvivorCount() - 1) * fSurvivorDamageBonus));

				CommonsDamage = RoundToCeil(GetClassMultiplier(victim, CommonsDamage * 1.0, "D"));
				
				if (IsClientInRangeSpecialAmmo(victim, "D") == -2.0) DamageShield = RoundToCeil(CommonsDamage * IsClientInRangeSpecialAmmo(victim, "D", false, _, CommonsDamage * 1.0));
				if (DamageShield > 0) {

					CommonsDamage -= DamageShield;
					if (CommonsDamage < 0) CommonsDamage = 0;
				}
				TheAbilityMultiplier = GetAbilityMultiplier(victim, 'X', 4);
				if (TheAbilityMultiplier >= 1.0) {	// Damage taken reduced to 0.

					damage_ignore = 0.0;
					return Plugin_Handled;
				}
				else if (TheAbilityMultiplier > 0.0) {	// Damage received is reduced by the amount.

					CommonsDamage -= RoundToCeil(CommonsDamage * TheAbilityMultiplier);
				}
				if (IsSurvivalMode || RPGRoundTime() < iEnrageTime) Points_Director += (fCommonDirectorPoints * CommonsDamage);
				else Points_Director += (fEnrageDirectorPoints * CommonsDamage);

				GetAbilityStrengthByTrigger(victim, attacker, 'Y', FindZombieClass(victim), CommonsDamage);
				SetClientTotalHealth(victim, CommonsDamage); //SetEntityHealth(victim, GetClientHealth(victim) - CommonsDamage);
				ReceiveCommonDamage(victim, attacker, CommonsDamage);
				GetAbilityStrengthByTrigger(victim, attacker, 'L', FindZombieClass(victim), CommonsDamage);
			}
			if (IsSpecialCommon(attacker)) {

				decl String:slevelrequired[10];
				GetCommonValue(slevelrequired, sizeof(slevelrequired), attacker, "level required?");
				if (PlayerLevel[victim] >= StringToInt(slevelrequired)) {

					GetCommonValue(TheCommonValue, sizeof(TheCommonValue), attacker, "aura effect?");

					// Flamers explode when they receive or take damage.
					if (StrContains(TheCommonValue, "f", true) != -1) {

						CreateDamageStatusEffect(attacker, _, victim, CommonsDamage);
					}
					if (StrContains(TheCommonValue, "a", true) != -1) {

						//CreateDamageStatusEffect(attacker, 4, victim, CommonsDamage);
						CreateBomberExplosion(attacker, victim, TheCommonValue, CommonsDamage);
					}
					if (StrContains(TheCommonValue, "E", true) != -1) {

						decl String:deatheffectshappen[10];
						GetCommonValue(deatheffectshappen, sizeof(deatheffectshappen), attacker, "death effect?");

						CreateDamageStatusEffect(attacker, _, victim, CommonsDamage);
						CreateBomberExplosion(attacker, victim, deatheffectshappen);
						ClearSpecialCommon(attacker, _, CommonsDamage);
					}
				}
			}
			//if (IsClientInRangeSpecialAmmo(victim, "R") == -2.0) {

			if (IsClientInRangeSpecialAmmo(victim, "R") == -2.0) BuffDamage = RoundToCeil(CommonsDamage * IsClientInRangeSpecialAmmo(victim, "R", false, _, CommonsDamage * 1.0));
			if (BuffDamage > 0) {

				if (IsCommonInfected(attacker) && !IsSpecialCommon(attacker)) {

					//IgnoreDamage = AddCommonInfectedDamage(victim, attacker, BuffDamage);
					AddCommonInfectedDamage(victim, attacker, BuffDamage);
					//IgnoreTeam = 5;
				}
				else if (IsSpecialCommon(attacker)) {

					GetCommonValue(TheCommonValue, sizeof(TheCommonValue), attacker, "aura effect?");

					if (StrContains(TheCommonValue, "d", true) == -1 || IsSurvivorBot(victim))	{

						//IgnoreDamage = AddSpecialCommonDamage(victim, attacker, BuffDamage);
						AddSpecialCommonDamage(victim, attacker, BuffDamage);
						//IgnoreTeam = 5;
					}
					else {	// if a player tries to reflect damage at a reflector, it's moot (ie reflects back to the player) so in this case the player takes double damage, though that's after mitigations.

						SetClientTotalHealth(victim, BuffDamage);
						ReceiveCommonDamage(victim, attacker, BuffDamage);
						HemomancerRoutine(victim, attacker, BuffDamage, false);
					}
				}
			}
			HemomancerRoutine(victim, attacker, CommonsDamage, false);
		}
	}

 	decl String:weapon[64];
 	//new StaminaCost = 0;
 	//new baseWeaponTemp = 0;
 	if (IsLegitimateClient(attacker) && (GetClientTeam(attacker) == TEAM_SURVIVOR || IsSurvivorBot(attacker))) {

 		bIsMeleeAttack = IsMeleeAttacker(attacker);

 		if (IsSpecialCommon(victim) || IsWitch(victim) || IsLegitimateClientAlive(victim)) {

 			if (LastAttackedUser[attacker] == victim) ConsecutiveHits[attacker]++;
			else {

				LastAttackedUser[attacker] = victim;
				ConsecutiveHits[attacker] = 0;
			}
		}

 		//Someday we'll do more common infected stuff here.
 		GetClientWeapon(attacker, weapon, sizeof(weapon));
 		LastWeaponDamage[attacker] = baseWeaponDamage;

 		TheAbilityMultiplier = GetAbilityMultiplier(attacker, 'N');
		if (TheAbilityMultiplier != -1.0) {

			if (TheAbilityMultiplier <= 0.0) {	// Damage dealt reduced to 0

				damage_ignore = 0.0;
				return Plugin_Handled;
			}
			else if (TheAbilityMultiplier > 0.0) { // damage dealt is increased

				baseWeaponDamage += RoundToCeil(baseWeaponDamage * TheAbilityMultiplier);
			}
		}
		if (baseWeaponDamage < 1) baseWeaponDamage = 1;

		TheAbilityMultiplier = GetAbilityMultiplier(attacker, 'C');
		if (TheAbilityMultiplier != -1.0) {

			new Float:MaxMultiplier = GetAbilityMultiplier(attacker, 'C', 3);

			if (ConsecutiveHits[attacker] > 0) TheAbilityMultiplier *= ConsecutiveHits[attacker];
			if (TheAbilityMultiplier > MaxMultiplier) TheAbilityMultiplier = MaxMultiplier;

			/*if (TheAbilityMultiplier <= 0.0) {	// Damage dealt reduced to 0

				damage_ignore = 0.0;
				return Plugin_Handled;
			}*/
			if (TheAbilityMultiplier > 0.0) { // damage dealt is increased

				baseWeaponDamage += RoundToCeil(baseWeaponDamage * TheAbilityMultiplier);
			}
		}

		if (!(GetEntityFlags(attacker) & FL_ONGROUND)) {

			TheAbilityMultiplier = GetAbilityMultiplier(attacker, 'K');
			if (TheAbilityMultiplier != -1.0) {

				baseWeaponDamage += RoundToCeil(baseWeaponDamage * TheAbilityMultiplier);
			}
		}

		if ((GetEntityFlags(attacker) & FL_INWATER)) {

			TheAbilityMultiplier = GetAbilityMultiplier(attacker, 'a');
			if (TheAbilityMultiplier != -1.0) {

				baseWeaponDamage += RoundToCeil(baseWeaponDamage * TheAbilityMultiplier);
			}
		}

		if ((GetEntityFlags(attacker) & FL_ONFIRE)) {

			TheAbilityMultiplier = GetAbilityMultiplier(attacker, 'f');
			if (TheAbilityMultiplier != -1.0) {

				baseWeaponDamage += RoundToCeil(baseWeaponDamage * TheAbilityMultiplier);
			}
		}

		if (baseWeaponDamage < 1) baseWeaponDamage = 1;

 		if (IsWitch(victim) || IsSpecialCommon(victim) || IsCommonInfected(victim)) {

 			//decl String:ModelName[64];
 			Format(ModelName, sizeof(ModelName), "-1");
 			GetEntPropString(victim, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
	 		Format(weapon, sizeof(weapon), "%s", FindPlayerWeapon(attacker));
			if (StrContains(weapon, "melee", false) == -1 && StrContains(weapon, "chainsaw", false) == -1 || !bIsMeleeCooldown[attacker]) {

				if (StrContains(weapon, "melee", false) != -1 || StrContains(weapon, "chainsaw", false) != -1) {

					bIsMeleeCooldown[attacker] = true;				
					CreateTimer(0.05, Timer_IsMeleeCooldown, attacker, TIMER_FLAG_NO_MAPCHANGE);
					//GetAbilityStrengthByTrigger(attacker, victim, 'b', FindZombieClass(attacker), baseWeaponDamage);	// striking a player with a melee weapon
					//GetAbilityStrengthByTrigger(victim, attacker, 'B', FindZombieClass(victim), baseWeaponDamage);	// being struck by a melee weapon
				}
				GetAbilityStrengthByTrigger(attacker, victim, 'D', FindZombieClass(attacker), baseWeaponDamage);
				GetAbilityStrengthByTrigger(victim, attacker, 'L', FindZombieClass(victim), baseWeaponDamage);
				//LogToFile(LogPathDirectory, "%N (%s) damages WITCH for %d (Total %d)", attacker, weapon, baseWeaponDamage, baseWeaponDamage);

				//if (IsSpecialCommon(victim) || IsWitch(victim)) {

					//AddTalentExperience(attacker, "agility", RoundToCeil(GetClassMultiplier(attacker, baseWeaponDamage * 1.0, "agX", true, true)));
				if (!bIsMeleeAttack) AddTalentExperience(attacker, "agility", baseWeaponDamage);
				else AddTalentExperience(attacker, "constitution", baseWeaponDamage);
				//}
				if (IsWitch(victim)) {

					if (FindListPositionByEntity(victim, Handle:WitchList) >= 0) {

						new WitchActive = GetEntProp(victim, Prop_Send, "m_mobRush");
						if (WitchActive < 1) SetEntProp(victim, Prop_Send, "m_mobRush", 1);

						//IgnoreDamage = AddWitchDamage(attacker, victim, baseWeaponDamage);
						AddWitchDamage(attacker, victim, baseWeaponDamage);
						//IgnoreTeam = 4;
					}
					//else OnWitchCreated(victim, true);
				}
				else if (IsSpecialCommon(victim)) {

					//IgnoreDamage = AddSpecialCommonDamage(attacker, victim, baseWeaponDamage);
					AddSpecialCommonDamage(attacker, victim, baseWeaponDamage);
					//IgnoreTeam = 4;
				}
				else if (IsCommonInfected(victim)) {

					//IgnoreDamage = AddCommonInfectedDamage(attacker, victim, baseWeaponDamage);
					AddCommonInfectedDamage(attacker, victim, baseWeaponDamage);
					if (IsCommonInfectedDead(victim))  {

						SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage);
						damage_ignore = (baseWeaponDamage * 1.0);
						return Plugin_Changed;
					}
					//IgnoreTeam = 4;
				}
				if (iDisplayHealthBars == 1) {

					DisplayInfectedHealthBars(attacker, victim);
				}
				if (CheckTeammateDamages(victim, attacker) >= 1.0 ||
					CheckTeammateDamages(victim, attacker, true) >= 1.0) {

					if (IsWitch(victim)) OnWitchCreated(victim, true);
					else if (IsSpecialCommon(victim)) {

						if (IsIncapacitated(attacker)) GetAbilityStrengthByTrigger(attacker, victim, 'K', FindZombieClass(attacker), baseWeaponDamage);
						ClearSpecialCommon(victim, _, baseWeaponDamage, attacker);
					}
					else if (IsCommonInfected(victim)) {

						OnCommonInfectedCreated(victim, true, attacker);
					}
				}
				else {

					/*

							So the player / common took damage.
					*/
					if (IsSpecialCommon(victim)) {

						GetCommonValue(TheCommonValue, sizeof(TheCommonValue), victim, "damage effect?");

						// The bomber explosion initially targets itself so that the chain-reaction (if enabled) doesn't go indefinitely.
						if (StrContains(TheCommonValue, "f", true) != -1) {

							CreateDamageStatusEffect(victim, _, attacker, baseWeaponDamage);
						}
						if (!IsSurvivorBot(attacker) && StrContains(TheCommonValue, "d", true) != -1) {

							CreateDamageStatusEffect(victim, 3, attacker, baseWeaponDamage);		// attacker is not target but just used to pass for reference.
						}
					}
				}
			}
			CombatTime[attacker] = GetEngineTime() + fOutOfCombatTime;
		}
		else if (IsLegitimateClient(victim) && GetClientTeam(victim) == TEAM_INFECTED) {//} && !(damagetype & DMG_DIRECT)) {

			if (L4D2_GetSurvivorVictim(victim) != -1) GetAbilityStrengthByTrigger(victim, attacker, 't', FindZombieClass(victim), baseWeaponDamage);

			if ((((StrContains(weapon, "molotov", false) != -1 || (damagetype & DMG_BURN)) && iIsSpecialFire != 1) || (!bIsMeleeAttack && TankState[victim] == TANKSTATE_DEATH)) && IsPlayerAlive(victim)) {

				damage_ignore = 0.0;	// *reference to damage
				return Plugin_Handled;
			}
			if (StrContains(weapon, "molotov", false) == -1 && IsPlayerAlive(victim) && !RestrictedWeaponList(weapon)) {

				if ((StrContains(weapon, "melee", false) != -1 || StrContains(weapon, "chainsaw", false) != -1) && !bIsMeleeCooldown[attacker]) {

					bIsMeleeCooldown[attacker] = true;
					CreateTimer(0.05, Timer_IsMeleeCooldown, attacker, TIMER_FLAG_NO_MAPCHANGE);
					//GetAbilityStrengthByTrigger(attacker, victim, 'b', FindZombieClass(attacker), baseWeaponDamage);	// striking a player with a melee weapon
					//GetAbilityStrengthByTrigger(victim, attacker, 'B', FindZombieClass(victim), baseWeaponDamage);	// being struck by a melee weapon
				}
				GetAbilityStrengthByTrigger(attacker, victim, 'D', FindZombieClass(attacker), baseWeaponDamage);
				GetAbilityStrengthByTrigger(victim, attacker, 'L', FindZombieClass(victim), baseWeaponDamage);
				
				if (FindZombieClass(victim) == ZOMBIECLASS_TANK) CheckTankSubroutine(victim, attacker, baseWeaponDamage, true);
				if (IsLegitimateClientAlive(victim)) {

					//AddTalentExperience(attacker, "agility", RoundToCeil(GetClassMultiplier(attacker, baseWeaponDamage * 1.0, "agX", true, true)));
					//AddTalentExperience(attacker, "agility", baseWeaponDamage);
					//AddTalentExperience(attacker, "constitution", baseWeaponDamage);
					if (!bIsMeleeAttack) AddTalentExperience(attacker, "agility", baseWeaponDamage);
					else AddTalentExperience(attacker, "constitution", baseWeaponDamage);
					AddSpecialInfectedDamage(attacker, victim, baseWeaponDamage);
				}
				if (iDisplayHealthBars == 1) {

					DisplayInfectedHealthBars(attacker, victim);
				}
				CombatTime[attacker] = GetEngineTime() + fOutOfCombatTime;
				//CheckTeammateDamagesEx(attacker, victim, baseWeaponDamage);
			}
		}
 		if (IsSpecialCommonInRange(attacker, 'd') && (damagetype & DMG_BULLET)) {

 			SetClientTotalHealth(attacker, baseWeaponDamage);// CreateDamageStatusEffect(attacker, 3, attacker, baseWeaponDamage);
 		}
 		if (IsLegitimateClientAlive(victim) && (GetClientTeam(victim) != GetClientTeam(attacker) || iIsPvpServer == 1) || IsCommonInfected(victim) || IsWitch(victim)) {

	 		//if (damagetype & DMG_BLAST) GetAbilityStrengthByTrigger(attacker, victim, 'S', FindZombieClass(attacker), baseWeaponDamage);
	 		//if (damagetype & DMG_CLUB) GetAbilityStrengthByTrigger(attacker, victim, 'U', FindZombieClass(attacker), baseWeaponDamage);
	 		//if (damagetype & DMG_SLASH) GetAbilityStrengthByTrigger(attacker, victim, 'u', FindZombieClass(attacker), baseWeaponDamage);
	 		//if (damagetype & DMG_BURN) DoBurn(attacker, victim, baseWeaponDamage);
	 	}
 		if (baseWeaponDamage == -1) {

 			damage_ignore = 0.0;
 			return Plugin_Handled;
 		}
 		/*if (GetConfigValueInt("special ammo requires target?") == 1 && (damagetype & DMG_BULLET)) {

 			//Bullets trigger special ammo.
 			if (HasSpecialAmmo(attacker) && IsSpecialAmmoEnabled[attacker][0] == 1.0) {

 				if (DrawSpecialAmmoTarget(attacker, _, true) == 1) {

 					StaminaCost = RoundToCeil(GetSpecialAmmoStrength(attacker, ActiveSpecialAmmo[attacker], 2));
 					if (SurvivorStamina[attacker] >= StaminaCost) {

 						//if (CheckActiveAmmoCooldown(attacker, ActiveSpecialAmmo[attacker]) == 1) {
 						if (!IsAmmoActive(attacker, ActiveSpecialAmmo[attacker])) {
	 					//if (CreateActiveTime(attacker, ActiveSpecialAmmo[attacker], GetSpecialAmmoStrength(attacker, ActiveSpecialAmmo[attacker])) == 1) {

	 						if (TriggerSpecialAmmo(attacker, victim, baseWeaponDamage, GetSpecialAmmoStrength(attacker, ActiveSpecialAmmo[attacker]), GetSpecialAmmoStrength(attacker, ActiveSpecialAmmo[attacker], 4))) {

		 						SurvivorStamina[attacker] -= StaminaCost;
								if (SurvivorStamina[attacker] <= 0) {

									bIsSurvivorFatigue[attacker] = true;
									IsSpecialAmmoEnabled[attacker][0] = 0.0;
								}
							}
						}
	 				}
		 		}
 			}
 		}*/
 		if ((StrContains(weapon, "melee", false) != -1 || StrContains(weapon, "chainsaw", false) != -1) && bIsMeleeCooldown[attacker]) {

 			damage_ignore = 0.0;
			return Plugin_Handled;
 		}
 		HemomancerRoutine(attacker, victim, baseWeaponDamage, true);
 	}
 	//HemomancerRoutine(client, party, damage, bool:IsAttacker = true)
 	//HemomancerRoutine(attacker, victim, baseWeaponDamage, true);

 	if (SameTeam_OnTakeDamage(attacker, victim, baseWeaponDamage, _, damagetype)) {

 		damage_ignore = 0.0;
 		return Plugin_Handled;
 	}
 	if (IsLegitimateClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED && IsLegitimateClient(victim) && (GetClientTeam(victim) == TEAM_SURVIVOR || IsSurvivorBot(victim))) {// && !(damagetype & DMG_DIRECT)) {

 		//CombatTime[victim] = GetEngineTime() + StringToFloat(GetConfigValue("out of combat time?"));
 		CombatTime[victim] = GetEngineTime() + fOutOfCombatTime;
 		if (b_IsJumping[victim]) ModifyGravity(victim);
		new totalIncomingDamage = RoundToCeil(damage);
		new myzombieclass = FindZombieClass(attacker);
		if (IsSpecialCommonInRange(attacker, 'b')) {

			totalIncomingDamage += GetSpecialCommonDamage(totalIncomingDamage, attacker, 'b', victim);
		}
		new MaxLevelCalc = iMaxDifficultyLevel;
				
		//Incoming Damage is calculated a very specific way, so that handicap is always the final calculation.
		if (iRPGMode >= 1) {

			//Format(idpLevel, sizeof(idpLevel), "(%d) damage player level?", FindZombieClass(attacker));
			
			if (iBotLevelType == 1) {

				if (myzombieclass != ZOMBIECLASS_TANK) totalIncomingDamage += RoundToFloor(totalIncomingDamage * (SurvivorLevels() * fDamagePlayerLevel[myzombieclass - 1]));
				else totalIncomingDamage += RoundToFloor(totalIncomingDamage * (SurvivorLevels() * fDamagePlayerLevel[myzombieclass - 2]));
			}
			else {

				if (PlayerLevel[victim] < MaxLevelCalc) MaxLevelCalc = PlayerLevel[victim];
				if (myzombieclass != ZOMBIECLASS_TANK) totalIncomingDamage += RoundToFloor(totalIncomingDamage * ((MaxLevelCalc - iPlayerStartingLevel) * fDamagePlayerLevel[myzombieclass - 1]));
				else totalIncomingDamage += RoundToFloor(totalIncomingDamage * ((MaxLevelCalc - iPlayerStartingLevel) * fDamagePlayerLevel[myzombieclass - 2]));
			}
		}

		//decl String:s_findZombie[64];
		/*if (HandicapLevel[victim] != -1) {

			//Format(s_findZombie, sizeof(s_findZombie), "(%d) damage increase?", FindZombieClass(attacker));
			//new Float:f_InfectedHealthMultiplier = StringToFloat(GetConfigValue(s_findZombie)) * HandicapLevel[victim];
			//totalIncomingDamage += RoundToCeil(totalIncomingDamage * f_InfectedHealthMultiplier);
			Format(s_findZombie, sizeof(s_findZombie), "(%d) new damage?", FindZombieClass(attacker));
			totalIncomingDamage += RoundToCeil(totalIncomingDamage * GetHandicapStrength(s_findZombie, HandicapLevel[victim]));
		}*/
		//LogToFile(LogPathDirectory, "[INFECTED DAMAGE] %N hits %N for %d", attacker, victim, totalIncomingDamage);

		//if (totalIncomingDamage >= GetClientTotalHealth(victim)) IncapacitateOrKill(victim, attacker, totalIncomingDamage);
		//else

		if (!IsSurvivorBot(victim)) {

			if (iNoobAssistance[victim] == 1) {

				totalIncomingDamage = RoundToCeil(totalIncomingDamage * fNoobAssistanceResistance);
			}
		}

		new totalIncomingTemp = 0;

		// INFECTED MULTIPLIERS FOR VERSUS AND COOP

		// berserk ammo affects both the attacker and the victim (increases the attackers damage and increases the damage the victim receives)
		if (IsClientInRangeSpecialAmmo(victim, "E") == -2.0) totalIncomingTemp = RoundToCeil(totalIncomingDamage * IsClientInRangeSpecialAmmo(victim, "E", false, _, totalIncomingDamage * 1.0));
		if (totalIncomingTemp > 0) totalIncomingDamage += totalIncomingTemp;
		if (IsClientInRangeSpecialAmmo(attacker, "E") == -2.0) totalIncomingTemp = RoundToCeil(totalIncomingDamage * IsClientInRangeSpecialAmmo(attacker, "E", false, _, totalIncomingDamage * 1.0));
		if (totalIncomingTemp > 0) totalIncomingDamage += totalIncomingTemp;

		if (theCount >= iSurvivorModifierRequired) totalIncomingDamage += RoundToCeil(totalIncomingDamage * ((theCount - (iSurvivorModifierRequired - 1)) * fSurvivorDamageBonus));
		//totalIncomingDamage += RoundToCeil(totalIncomingDamage * ((LivingSurvivorCount() - 1) * fSurvivorDamageBonus));

		totalIncomingDamage = RoundToCeil(GetClassMultiplier(victim, totalIncomingDamage * 1.0, "D"));

		if (IsClientInRangeSpecialAmmo(victim, "D") == -2.0) DamageShield = RoundToCeil(totalIncomingDamage * IsClientInRangeSpecialAmmo(victim, "D", false, _, totalIncomingDamage * 1.0));
		if (DamageShield > 0) {

			totalIncomingDamage -= DamageShield;
			if (totalIncomingDamage < 0) totalIncomingDamage = 0;
		}

		TheAbilityMultiplier = GetAbilityMultiplier(victim, 'X', 4);
		if (TheAbilityMultiplier >= 1.0) {	// Damage taken reduced to 0.

			damage_ignore = 0.0;
			return Plugin_Handled;
		}
		else if (TheAbilityMultiplier > 0.0) {	// Damage received is reduced by the amount.

			totalIncomingDamage -= RoundToCeil(totalIncomingDamage * TheAbilityMultiplier);
		}

		if (CheckActiveAbility(victim, totalIncomingDamage, 1) > 0.0) {

			SetClientTotalHealth(victim, totalIncomingDamage);
			AddSpecialInfectedDamage(victim, attacker, totalIncomingDamage, true);	// bool is tanking instead.
		}

		if (FindZombieClass(attacker) == ZOMBIECLASS_TANK) CheckTankSubroutine(attacker, victim, totalIncomingDamage);
		//RoundDamageTotal += totalIncomingDamage;
		//RoundDamage[attacker] += totalIncomingDamage;
		//DamageAward[attacker][victim] += totalIncomingDamage;
		if (IsFakeClient(attacker)) {

			if (IsSurvivalMode || RPGRoundTime() < iEnrageTime) Points_Director += (totalIncomingDamage * fPointsMultiplierInfected);
			else Points_Director += ((totalIncomingDamage * fPointsMultiplierInfected) * fEnrageDirectorPoints);

			//ExperienceLevel_Bots += RoundToCeil(totalIncomingDamage * GetConfigValueFloat("experience multiplier infected?"));
			//if (ExperienceLevel_Bots > CheckExperienceRequirement(-1)) ExperienceLevel_Bots = CheckExperienceRequirement(-1);
		}

		new bool:bIsInfectedSwarm = false;
		if (StrEqual(weapon, "insect_swarm")) bIsInfectedSwarm = true;

		if (L4D2_GetSurvivorVictim(attacker) != -1) GetAbilityStrengthByTrigger(attacker, victim, 'v', FindZombieClass(attacker), totalIncomingDamage);
		if (bIsInfectedSwarm) GetAbilityStrengthByTrigger(attacker, victim, 'T', FindZombieClass(attacker), totalIncomingDamage);
		else GetAbilityStrengthByTrigger(victim, attacker, 'L', FindZombieClass(victim), totalIncomingDamage);
		GetAbilityStrengthByTrigger(attacker, victim, 'D', FindZombieClass(attacker), totalIncomingDamage);
		if (L4D2_GetInfectedAttacker(victim) == attacker) GetAbilityStrengthByTrigger(victim, attacker, 's', FindZombieClass(victim), totalIncomingDamage);
		if (L4D2_GetInfectedAttacker(victim) != -1 && L4D2_GetInfectedAttacker(victim) != attacker) {

			// If the infected player dealing the damage isn't the player hurting the victim, we give the victim a chance to strike at both! This is balance!
			GetAbilityStrengthByTrigger(victim, L4D2_GetInfectedAttacker(victim), 'V', FindZombieClass(victim), totalIncomingDamage);
			if (attacker != L4D2_GetInfectedAttacker(victim)) GetAbilityStrengthByTrigger(victim, attacker, 'V', FindZombieClass(victim), totalIncomingDamage);
		}
		if (!bIsInfectedSwarm && IsClientInRangeSpecialAmmo(victim, "R") == -2.0) ReflectIncomingDamage = RoundToCeil(totalIncomingDamage * IsClientInRangeSpecialAmmo(victim, "R", false, _, totalIncomingDamage * 1.0));
		if (ReflectIncomingDamage > 0) {

			/*for (new i = 1; i <= MaxClients; i++) {

				if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR && i != victim) {	// we don't allow the buffer to gain experience off their own buffs that are applied to themselves. (if they increase their damage, they'll get bonus xp from THAT)

					IsClientInRangeSpecialAmmo(victim, "R", false, _, totalIncomingDamage * 1.0, i);			// this will reward each of the players who have buffed the individual with experience.
				}
			}*/
			//IgnoreDamage = AddSpecialInfectedDamage(victim, attacker, ReflectIncomingDamage);
			AddSpecialInfectedDamage(victim, attacker, ReflectIncomingDamage);
			//IgnoreTeam = 2;
		}
		HemomancerRoutine(victim, attacker, totalIncomingDamage, false);
		/*if ((damagetype & DMG_CRUSH)) {

			bIsCrushCooldown[victim] = true;
			LogMessage("%N crushed by an object for %d damage", victim, RoundToCeil(totalIncomingDamage));
			CreateTimer(1.0, Timer_ResetCrushImmunity, victim, TIMER_FLAG_NO_MAPCHANGE);
		}*/
	}
	// IgnoreTeam = 1 when the attacker is survivor.
	// IgnoreTeam = 2 when the attacker is infected.
	// IgnoreTeam = 3 when the victim is infected.
	// IgnoreTeam = 4 when the victim is common/witch
	// IgnoreTeam = 5 when the attacker is common/witch
	//damage_ignore = 0.0;
	//return Plugin_Handled;

	if (IsLegitimateClientAlive(victim) && GetClientTeam(victim) == TEAM_INFECTED ||
		IsCommonInfected(victim) && FindListPositionByEntity(victim, Handle:CommonInfected) >= 0 ||
		IsWitch(victim) && FindListPositionByEntity(victim, Handle:WitchList) >= 0) {

		if (IsWitch(victim)) {

			damage_ignore = 1.0;
			return Plugin_Changed;
		}
		damage_ignore = 0.0;
		return Plugin_Handled;
	}
	damage_ignore = damage;
	return Plugin_Changed;

	//if (IgnoreDamage == 1) return -1;
	//return 0;
	/*if (IgnoreDamage == 1 || IgnoreTeam == 3 || IgnoreTeam == 2 && IsLegitimateClient(victim)) {

		//if (IgnoreDamage == 1 && (IsWitch(victim) || IsCommonInfected(victim))) {

			//if (GetInfectedHealth(victim) < 100) SetInfectedHealth(victim, 40000);
			//damage_ignore = 1.0;
			//return Plugin_Changed;
			//return -1;
		}
		if ((damagetype & DMG_CRUSH) && IsLegitimateClientAlive(victim)) {

			damage_ignore = 0.0;
			return Plugin_Handled;
		}
		//damage_ignore = 0.0;
		//return Plugin_Handled;
		return -1;
	}
	else {

		if (IgnoreTeam == 1 || IgnoreTeam == 2 || IgnoreTeam == 4) SetInfectedHealth(victim, 1);
		else if (IgnoreTeam == 5) SetInfectedHealth(attacker, 1);

		//damage_ignore = IgnoreDamage * 1.0;
		//return Plugin_Changed;
		return 0;
	}*/
}

stock bool:IsMeleeAttacker(client) {

	decl String:weapon[64];
	GetClientWeapon(client, weapon, sizeof(weapon));
	if (StrContains(weapon, "melee", false) != -1 || StrContains(weapon, "chainsaw", false) != -1) {

		if (!bIsMeleeCooldown[client]) return true;
		return false;
	}
	return false;
}

stock SpawnAnyInfected(client) {

	if (IsLegitimateClientAlive(client)) {

		decl String:InfectedName[20];
		new rand = GetRandomInt(1,6);
		if (rand == 1) Format(InfectedName, sizeof(InfectedName), "smoker");
		else if (rand == 2) Format(InfectedName, sizeof(InfectedName), "boomer");
		else if (rand == 3) Format(InfectedName, sizeof(InfectedName), "hunter");
		else if (rand == 4) Format(InfectedName, sizeof(InfectedName), "spitter");
		else if (rand == 5) Format(InfectedName, sizeof(InfectedName), "jockey");
		else Format(InfectedName, sizeof(InfectedName), "charger");
		Format(InfectedName, sizeof(InfectedName), "%s auto", InfectedName);

		ExecCheatCommand(client, "z_spawn_old", InfectedName);
	}
}

stock GetInfectedCount(zombieclass = 0) {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_INFECTED && (zombieclass == 0 || FindZombieClass(i) == zombieclass)) count++;
	}
	return count;
}

stock CreateMyHealthPool(client, bool:IMeanDeleteItInstead = false) {

	new whatami = 3;
	if (IsCommonInfected(client) && !IsSpecialCommon(client)) whatami = 0;
	else if (IsSpecialCommon(client)) whatami = 1;
	else if (IsWitch(client)) whatami = 2;

	/*if (IsLegitimateClientAlive(client) && FindZombieClass(client) == ZOMBIECLASS_TANK && iTankRush == 1) {

		SetSpeedMultiplierBase(client, 1.0);
	}*/

	/*if (!b_IsFinaleActive && IsEnrageActive() && whatami == 3 && IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_INFECTED && FindZombieClass(client) == ZOMBIECLASS_TANK && !IsTyrantExist()) {

		IsTyrant[client] = true;
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 0, 255, 0, 255);
	}
	else*/

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i))) {

			if (!IMeanDeleteItInstead) {

				if (whatami == 0) AddCommonInfectedDamage(i, client, -1);
				else if (whatami == 1) AddSpecialCommonDamage(i, client, -1);
				else if (whatami == 2) AddWitchDamage(i, client, -1);
				else if (whatami == 3) AddSpecialInfectedDamage(i, client, -1);
			}
			else {

				if (whatami == 0) AddCommonInfectedDamage(i, client, -2);
				else if (whatami == 1) AddSpecialCommonDamage(i, client, -2);
				else if (whatami == 2) AddWitchDamage(i, client, -2);
				else if (whatami == 3) AddSpecialInfectedDamage(i, client, -2);
			}
		}
	}
}

stock EnsnaredInfected() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED && IsEnsnarer(i)) count++;
	}
	return count;
}

stock bool:IsEnsnarer(client, class = 0) {

	new zombieclass = class;
	if (class == 0) zombieclass = FindZombieClass(client);
	if (zombieclass == ZOMBIECLASS_HUNTER ||
		zombieclass == ZOMBIECLASS_SMOKER ||
		zombieclass == ZOMBIECLASS_JOCKEY ||
		zombieclass == ZOMBIECLASS_CHARGER) return true;
	return false;
}

stock AddSpecialInfectedDamage(client, target, TotalDamage, bool:IsTankingInstead = false, damagevariant = -1) {

	new isEntityPos = FindListPositionByEntity(target, Handle:InfectedHealth[client]);
	//new f 0;
	if (isEntityPos >= 0 && TotalDamage <= -1) {

		// delete the mob.
		RemoveFromArray(Handle:InfectedHealth[client], isEntityPos);
		if (TotalDamage == -2) return 0;
		isEntityPos = -1;
	}

	new myzombieclass = FindZombieClass(target, true);
	if (myzombieclass < 1) return 0;

	if (isEntityPos < 0) {

		new t_InfectedHealth = DefaultHealth[target];
		isEntityPos = GetArraySize(Handle:InfectedHealth[client]);
		ResizeArray(Handle:InfectedHealth[client], isEntityPos + 1);
		SetArrayCell(Handle:InfectedHealth[client], isEntityPos, target, 0);

		//An infected wasn't added on spawn to this player, so we add it now based on class.
		if (myzombieclass == ZOMBIECLASS_TANK) t_InfectedHealth = 4000;
		else if (myzombieclass == ZOMBIECLASS_HUNTER || myzombieclass == ZOMBIECLASS_SMOKER) t_InfectedHealth = 200;
		else if (myzombieclass == ZOMBIECLASS_BOOMER) t_InfectedHealth = 50;
		else if (myzombieclass == ZOMBIECLASS_SPITTER) t_InfectedHealth = 100;
		else if (myzombieclass == ZOMBIECLASS_CHARGER) t_InfectedHealth = 600;
		else if (myzombieclass == ZOMBIECLASS_JOCKEY) t_InfectedHealth = 300;

		OriginalHealth[target] = t_InfectedHealth;
		GetAbilityStrengthByTrigger(target, _, 'a', myzombieclass, 0);
		if (DefaultHealth[target] < OriginalHealth[target]) DefaultHealth[target] = OriginalHealth[target];
		if (!IsFakeClient(target)) {

			DefaultHealth[target] = SetMaximumHealth(target);
		}
		else OverHealth[target] = 0;

		if (iBotLevelType == 1) {

			if (myzombieclass != ZOMBIECLASS_TANK) t_InfectedHealth += RoundToCeil(t_InfectedHealth * (SurvivorLevels() * fHealthPlayerLevel[myzombieclass - 1]));
			else t_InfectedHealth += RoundToCeil(t_InfectedHealth * (SurvivorLevels() * fHealthPlayerLevel[myzombieclass - 2]));
		}
		else {

			if (myzombieclass != ZOMBIECLASS_TANK) t_InfectedHealth += RoundToCeil(t_InfectedHealth * (GetDifficultyRating(client) * fHealthPlayerLevel[myzombieclass - 1]));
			else t_InfectedHealth += RoundToCeil(t_InfectedHealth * (GetDifficultyRating(client) * fHealthPlayerLevel[myzombieclass - 2]));
		}

		// only add raid health if > 4 survivors.
		new theCount = LivingSurvivorCount();
		if (theCount >= iSurvivorModifierRequired) t_InfectedHealth += RoundToCeil(t_InfectedHealth * ((theCount - (iSurvivorModifierRequired - 1)) * fSurvivorHealthBonus));

		SetArrayCell(Handle:InfectedHealth[client], isEntityPos, t_InfectedHealth + OverHealth[target], 1);
		SetArrayCell(Handle:InfectedHealth[client], isEntityPos, 0, 2);
		SetArrayCell(Handle:InfectedHealth[client], isEntityPos, 0, 3);
		SetArrayCell(Handle:InfectedHealth[client], isEntityPos, 0, 4);
		// This slot is only for versus/human infected players; health remaining after "ARMOR" (global health) is gone.

		if (!bHealthIsSet[target]) {

			bHealthIsSet[target] = true;
			ResizeArray(Handle:InfectedHealth[target], GetArraySize(Handle:InfectedHealth[target]) + 1);
			SetArrayCell(Handle:InfectedHealth[target], 0, DefaultHealth[target], 5);
			SetArrayCell(Handle:InfectedHealth[target], 0, 0, 6);
			//SetArrayCell(Handle:InfectedHealth[client], isEntityPos, t_InfectedHealth, 5);
		}
	}
	if (TotalDamage < 1) return 0;

	new i_DamageBonus = TotalDamage;
	new i_InfectedMaxHealth = GetArrayCell(Handle:InfectedHealth[client], isEntityPos, 1);
	new i_InfectedCurrent = GetArrayCell(Handle:InfectedHealth[client], isEntityPos, 2);
	//new i_HealthRemaining = i_InfectedMaxHealth - i_InfectedCurrent;

	new TrueHealthRemaining = RoundToCeil((1.0 - CheckTeammateDamages(target, client)) * i_InfectedMaxHealth);
	if (i_InfectedCurrent < 0) i_InfectedCurrent = 0;
	if (i_DamageBonus > TrueHealthRemaining) i_DamageBonus = TrueHealthRemaining;

	if (!IsTankingInstead) {

		if (IsSpecialCommonInRange(target, 't')) return 0;
		if (damagevariant != 2) {

			SetArrayCell(Handle:InfectedHealth[client], isEntityPos, i_InfectedCurrent + i_DamageBonus, 2);
			RoundDamageTotal += (i_DamageBonus);
			RoundDamage[client] += (i_DamageBonus);

			if (i_DamageBonus > 0) {

				if (damagevariant == 1) AddTalentExperience(client, "endurance", i_DamageBonus);
				else if (damagevariant == -1) {

					new bool:bIsMeleeAttack = IsMeleeAttacker(client);
					if (!bIsMeleeAttack) AddTalentExperience(client, "agility", i_DamageBonus);
					else AddTalentExperience(client, "constitution", i_DamageBonus);
				}
			}
		}
		else {

			SetArrayCell(Handle:InfectedHealth[client], isEntityPos, i_InfectedMaxHealth - i_DamageBonus, 1);	// lowers the total health pool if variant = 2 (bot damage)
		}
	}
	else {

		// Certain classes take reduced damage. If that class takes damage, we want to treat the rating bonus for the damage as if they took 1.0 (normal) damage
		new Float:RatingReductionMult = GetClassMultiplier(client, -1.0, "D");
		if (RatingReductionMult == -1.0) RatingReductionMult = 1.0;
		RatingReductionMult = (1.0 / RatingReductionMult);

		i_InfectedCurrent = GetArrayCell(Handle:InfectedHealth[client], isEntityPos, 3);
		i_DamageBonus = RoundToCeil(i_DamageBonus * RatingReductionMult);
		//if (FindZombieClass(target) == ZOMBIECLASS_TANK)
		//i_DamageBonus = RoundToCeil(GetClassMultiplier(client, i_DamageBonus * 1.0, "tXP"));
		i_InfectedCurrent += i_DamageBonus;
		//PrintToChat(client, "Damage Bonus: %d Damage Current: %d", i_DamageBonus, i_InfectedCurrent);
		SetArrayCell(Handle:InfectedHealth[client], isEntityPos, i_InfectedCurrent, 3);
		//if (damagevariant == 1) AddTalentExperience(client, "endurance", RoundToCeil(GetClassMultiplier(client, i_DamageBonus * 0.5, "enX", true, true)));
	}
	ThreatCalculator(client, i_DamageBonus);
	CheckTeammateDamagesEx(client, target, i_DamageBonus);
	return 0;
}

stock ThreatCalculator(client, iThreatAmount) {

	if (IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR) {

		new Float:TheAbilityMultiplier = GetAbilityMultiplier(client, 't');
		if (TheAbilityMultiplier != -1.0) {

			TheAbilityMultiplier *= (iThreatAmount * 1.0);
			iThreatLevel[client] += (iThreatAmount - RoundToFloor(TheAbilityMultiplier));
		}
		else {

			iThreatLevel[client] += iThreatAmount;
		}
		decl String:ClassRoles[64];
		GetMenuOfTalent(client, ActiveClass[client], ClassRoles, sizeof(ClassRoles));
		if (StrContains(ClassRoles, "Tank", false) != -1) {

			iThreatLevel[client] += RoundToCeil(iThreatAmount * fTankThreatBonus);
		}
	}
}

stock AddSpecialCommonDamage(client, entity, playerDamage, bool:IsStatusDamage = false, damagevariant = -1) {

	if (!IsSpecialCommon(entity)) {

		//ClearSpecialCommon(entity, _, playerDamage);
		return 1;
	}
	new pos		= FindListPositionByEntity(entity, Handle:CommonList);
	if (pos < 0) return 1;

	new damageTotal = -1;
	new healthTotal = -1;

	new my_size	= GetArraySize(Handle:SpecialCommon[client]);
	new my_pos	= FindListPositionByEntity(entity, Handle:SpecialCommon[client]);


	if (my_pos >= 0 && playerDamage <= -1) {

		// delete the mob.
		RemoveFromArray(Handle:SpecialCommon[client], my_pos);
		if (playerDamage == -2) return 0;
		my_pos = -1;
	}
	if (my_pos < 0) {

		new CommonHealth = GetCommonValueInt(entity, "base health?");

		if (iBotLevelType == 1) CommonHealth += RoundToCeil(CommonHealth * (SurvivorLevels() * GetCommonValueFloat(entity, "health per level?")));
		else CommonHealth += RoundToCeil(CommonHealth * (GetDifficultyRating(client) * GetCommonValueFloat(entity, "health per level?")));

		// only add raid health if > 4 survivors.
		new theCount = LivingSurvivorCount();
		if (theCount >= iSurvivorModifierRequired) CommonHealth += RoundToCeil(CommonHealth * ((theCount - (iSurvivorModifierRequired - 1)) * fSurvivorHealthBonus));

		ResizeArray(Handle:SpecialCommon[client], my_size + 1);
		SetArrayCell(Handle:SpecialCommon[client], my_size, entity, 0);
		SetArrayCell(Handle:SpecialCommon[client], my_size, CommonHealth, 1);
		SetArrayCell(Handle:SpecialCommon[client], my_size, 0, 2);
		SetArrayCell(Handle:SpecialCommon[client], my_size, 0, 3);
		SetArrayCell(Handle:SpecialCommon[client], my_size, 0, 4);

		my_pos = my_size;
	}
	if (IsSpecialCommonInRange(entity, 't')) return 1;
	if (playerDamage >= 0) {

		damageTotal = GetArrayCell(Handle:SpecialCommon[client], my_pos, 2);
		healthTotal = GetArrayCell(Handle:SpecialCommon[client], my_pos, 1);

		new TrueHealthRemaining = RoundToCeil((1.0 - CheckTeammateDamages(entity, client)) * healthTotal);	// in case other players have damaged the mob - we can't just assume the remaining health without comparing to other players.
		
		if (damageTotal < 0) damageTotal = 0;

		if (playerDamage > TrueHealthRemaining) playerDamage = TrueHealthRemaining;
		SetArrayCell(Handle:SpecialCommon[client], my_pos, damageTotal + playerDamage, 2);
		if (playerDamage > 0) {

			if (damagevariant == 1) AddTalentExperience(client, "endurance", playerDamage);
			else if (damagevariant == -1) {

				new bool:bIsMeleeAttack = IsMeleeAttacker(client);
				if (!bIsMeleeAttack) AddTalentExperience(client, "agility", playerDamage);
				else AddTalentExperience(client, "constitution", playerDamage);
			}
		}
	}
	else {

		damageTotal = GetArrayCell(Handle:SpecialCommon[client], my_pos, 1);
		SetArrayCell(Handle:SpecialCommon[client], my_pos, damageTotal + playerDamage, 1);
	}
	ThreatCalculator(client, playerDamage);
	if (CheckIfEntityShouldDie(entity, client, playerDamage, IsStatusDamage) == 1) {

		return (damageTotal + playerDamage);
	}
	return 1;
}

stock AwardExperience(client, type = 0, AMOUNT = 0, bool:TheRoundHasEnded=false) {

	decl String:pct[4];
	Format(pct, sizeof(pct), "%");

	if (type == -1){//} && RoundExperienceMultiplier[client] > 0.0) {	//	This occurs when a player fully loads-in to a game, and is bonus container from previous round.

		//new RewardWaiting = RoundToCeil(BonusContainer[client] * RoundExperienceMultiplier[client]);
		//BonusContainer[client] += RoundToCeil(BonusContainer[client] * RoundExperienceMultiplier[client]);
		//PrintToChat(client, "%T", "bonus experience waiting", client, blue, green, AddCommasToString(RewardWaiting), blue, orange, blue, orange, blue, green, RoundExperienceMultiplier[client] * 100.0, pct);
		//PrintToChat(client, "%T", "round bonus private", )
		return;
	}

	new InfectedBotLevelType = iBotLevelType;

	if (TheRoundHasEnded || !b_IsFinaleActive && !IsEnrageActive() && AMOUNT == 0 && !bIsInCombat[client]) {

		new Float:PointsMultiplier = fPointsMultiplier;
		new Float:HealingMultiplier = fHealingMultiplier;
		new Float:BuffingMultiplier = fBuffingMultiplier;
		new Float:HexingMultiplier = fHexingMultiplier;

		if (IsPlayerAlive(client)) {

			new h_Contribution = 0;
			if (HealingContribution[client] > 0) h_Contribution = RoundToCeil(HealingContribution[client] * HealingMultiplier);

			new Float:SurvivorPoints = 0.0;
			if (h_Contribution > 0) SurvivorPoints = (h_Contribution * (PointsMultiplier * HealingMultiplier));

			new Bu_Contribution = 0;
			if (BuffingContribution[client] > 0) Bu_Contribution = RoundToCeil(BuffingContribution[client] * BuffingMultiplier);

			if (Bu_Contribution > 0) SurvivorPoints += (Bu_Contribution * (PointsMultiplier * BuffingMultiplier));

			new He_Contribution = 0;
			if (HexingContribution[client] > 0) He_Contribution = RoundToCeil(HexingContribution[client] * HexingMultiplier);
			if (He_Contribution > 0) SurvivorPoints += (He_Contribution * (PointsMultiplier * HexingMultiplier));

			//ReceiveInfectedDamageAward(client, 0, DamageContribution[client], PointsContribution[client], TankingContribution[client], h_Contribution, Bu_Contribution, He_Contribution, TheRoundHasEnded);
			ReceiveInfectedDamageAward(client, 0, DamageContribution[client], PointsContribution[client], TankingContribution[client], h_Contribution, Bu_Contribution, He_Contribution, TheRoundHasEnded);
		}
		HealingContribution[client] = 0;
		PointsContribution[client] = 0.0;
		TankingContribution[client] = 0;
		DamageContribution[client] = 0;
		BuffingContribution[client] = 0;
		HexingContribution[client] = 0;
			//ReceiveInfectedDamageAward(i, client, SurvivorExperience, SurvivorPoints, t_Contribution, h_Contribution);
	}
	if (!TheRoundHasEnded && (InfectedBotLevelType == 1 || bIsInCombat[client] || b_IsFinaleActive || IsEnrageActive() || DoomTimer != 0)) {

		new bAMOUNT = 0;
		if (RoundExperienceMultiplier[client] > 0.0) {

			bAMOUNT = AMOUNT + RoundToCeil(AMOUNT * RoundExperienceMultiplier[client]);
		}
		else bAMOUNT = AMOUNT;
		if (type == 1) HealingContribution[client] += bAMOUNT;
		else if (type == 2) BuffingContribution[client] += bAMOUNT;
		else if (type == 3) HexingContribution[client] += bAMOUNT;
		AddTalentExperience(client, "endurance", bAMOUNT);
	}
}

stock bool:IsClassType(client, String:SearchString[]) {


}

stock String:GetClassMultiplierText(client, String:ClassEffect[], String:TalentName[], bool:IsCartel = false) {

	decl String:text[512];
	decl String:t_temp[512];

	decl String:EffectValue[2][512];
	new ExplodeCount = GetDelimiterCount(ClassEffect, "+") + 1;
	decl String:t_Effects[ExplodeCount][512];
	ExplodeString(ClassEffect, "+", t_Effects, ExplodeCount, 512);

	for (new i = 0; i < ExplodeCount; i++) {

		if (i > 0) Format(text, sizeof(text), "%s\n", text);

		ExplodeString(t_Effects[i], ":", EffectValue, 2, 512);
		if (StrContains(EffectValue[0], "_", false) == -1) Format(t_temp, sizeof(t_temp), "%s class info", EffectValue[0]);
		else {	// For dynamic effects, such as tSTR_ which affects any talent (such as tSTR_H for health)

			Format(t_temp, sizeof(t_temp), "%s class talent info", EffectValue[0][FindDelim(EffectValue[0], "_")]);
		}
		Format(t_temp, sizeof(t_temp), "%T", t_temp, client);

		if (StringToFloat(EffectValue[1]) == 0.0) Format(t_temp, sizeof(t_temp), "%s Disabled", t_temp);
		else Format(t_temp, sizeof(t_temp), "%3.2fx %s", StringToFloat(EffectValue[1]), t_temp);

		if (i == 0) Format(text, sizeof(text), "%s", t_temp);
		else Format(text, sizeof(text), "%s%s", text, t_temp);
	}
	if (!IsCartel) {

		if (StrContains(TalentName, "death", false) != -1) {

			Format(t_temp, sizeof(t_temp), "%T", "dark sacrifice", client);
			Format(text, sizeof(text), "%s\n%s", text, t_temp);
		}
		if (StrContains(TalentName, "spacex", false) != -1) {

			Format(t_temp, sizeof(t_temp), "%T", "elon mastery", client);
			Format(text, sizeof(text), "%s\n%s", text, t_temp);
		}
		if (StrContains(TalentName, "zora", false) != -1) {

			Format(t_temp, sizeof(t_temp), "%T", "zora mastery", client);
			Format(text, sizeof(text), "%s\n%s", text, t_temp);
		}
		/*if (StrContains(TalentName, "crusader", false) != -1) {

			Format(t_temp, sizeof(t_temp), "%T", "blessed by the light", client);
			Format(text, sizeof(text), "%s\n%s", text, t_temp);
		}*/
		if (StrContains(TalentName, "shaman", false) != -1) {

			Format(t_temp, sizeof(t_temp), "%T", "totem spirit", client);
			Format(text, sizeof(text), "%s\n%s", text, t_temp);
		}
		if (StrContains(TalentName, "hemomancer", false) != -1) {

			Format(t_temp, sizeof(t_temp), "%T", "hemomancy", client);
			Format(text, sizeof(text), "%s\n%s", text, t_temp);
		}
		if (StrContains(TalentName, "healer", false) != -1) {

			Format(t_temp, sizeof(t_temp), "%T", "healer aura", client);
			Format(text, sizeof(text), "%s\n%s", text, t_temp);
		}
		if (StrContains(TalentName, "commando", false) != -1) {

			Format(t_temp, sizeof(t_temp), "%T", "commando aura", client);
			Format(text, sizeof(text), "%s\n%s", text, t_temp);
		}
		if (StrContains(TalentName, "blaster", false) != -1) {

			Format(t_temp, sizeof(t_temp), "%T", "explosive impact", client);
			Format(text, sizeof(text), "%s\n%s", text, t_temp);
		}
		if (StrContains(TalentName, "firebug", false) != -1) {

			Format(t_temp, sizeof(t_temp), "%T", "fire crater", client);
			Format(text, sizeof(text), "%s\n%s", text, t_temp);
		}
		if (StrContains(TalentName, "scout", false) != -1) {

			Format(t_temp, sizeof(t_temp), "%T", "space force", client);
			Format(text, sizeof(text), "%s\n%s", text, t_temp);
		}
	}
	return text;
}

stock GetClassValue(client, String:TheString[], TheSize, String:TheSearchKey[]) {

	if (!IsLegitimateClient(client) || !IsLegitimateClass(client)) return;
	new size = GetArraySize(a_Menu_Talents);
	decl String:text[64];

	for (new i = 0; i < size; i++) {

		GCVKeys[client]		= GetArrayCell(a_Menu_Talents, i, 0);
		GCVValues[client]	= GetArrayCell(a_Menu_Talents, i, 1);
		GCVSection[client]	= GetArrayCell(a_Menu_Talents, i, 2);
		GetArrayString(Handle:GCVSection[client], 0, text, sizeof(text));
		if (!StrEqual(ActiveClass[client], text, false)) continue;

		FormatKeyValue(TheString, TheSize, GCVKeys[client], GCVValues[client], TheSearchKey);
		break;
	}
	return;
}

stock GetPassiveStrength(client, String:SearchKey[], String:TalentName[], TheSize = 64) {

	if (IsLegitimateClient(client)) {

		new size = GetArraySize(a_Menu_Talents);
		decl String:SearchValue[64];
		//decl String:TalentName[64];
		Format(TalentName, TheSize, "-1");
		new pos = -1;

		for (new i = 0; i < size; i++) {

			PassiveStrengthKeys[client] = GetArrayCell(a_Menu_Talents, i, 0);
			PassiveStrengthValues[client] = GetArrayCell(a_Menu_Talents, i, 1);

			
			FormatKeyValue(SearchValue, sizeof(SearchValue), PassiveStrengthKeys[client], PassiveStrengthValues[client], "passive ability?");
			
			if (!StrEqual(SearchKey, SearchValue)) continue;
			PassiveTalentName[client] = GetArrayCell(a_Menu_Talents, i, 2);
			GetArrayString(Handle:PassiveTalentName[client], 0, TalentName, TheSize);

			pos = GetDatabasePosition(client, TalentName);
			if (pos >= 0) {

				GCMKeys[client] = PassiveStrengthKeys[client];
				GCMValues[client] = PassiveStrengthValues[client];

				return GetArrayCell(Handle:a_Database_PlayerTalents[client], pos);
			}
			break;	// should never get here unless there's a spelling mistake in code/config
		}
	}
	return 0;
}

stock Float:GetPassiveInfo(client, target, Handle:Keys, Handle:Values, String:TalentName[], bool:bIsCreateCooldown = false) {

	new Float:f_FirstPoint	= GetTalentInfo(client, Keys, Values, _, _, TalentName, target);
	new Float:f_EachPoint	= GetTalentInfo(client, Keys, Values, 1, _, TalentName, target);
	//new Float:f_Time		= GetTalentInfo(client, Keys, Values, 2, _, TalentName, target);
	new Float:f_Cooldown	= GetTalentInfo(client, Keys, Values, 3, _, TalentName, target);

	new Float:f_Strength			=	f_FirstPoint + f_EachPoint;

	if (bIsCreateCooldown && f_Cooldown > 0.00) CreateCooldown(client, GetTalentPosition(client, TalentName), f_Cooldown);
	return f_Strength;
}

stock GetDatabasePosition(client, String:TalentName[]) {

	new size				=	0;
	if (client != -1) size	=	GetArraySize(a_Database_PlayerTalents[client]);
	else size				=	GetArraySize(a_Database_PlayerTalents_Bots);
	decl String:text[64];

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(TalentName, text)) return i;
	}
	return -1;
}

stock Float:GetClassMultiplier(client, Float:value, String:ClassEffect[], catType = 0, bool:AddingToValue = false, target = 0) {

	if (target == 0) target = client;

	if (!IsLegitimateClient(client) || (!IsLegitimateClass(client) && iIsClassesEnabled == 1) || value == 0.0 || iIsClassesEnabled != 1 && catType != 0) return value;

	if (iIsClassesEnabled != 1) {

		decl String:TalentName[64];
		new iTalentPoints = GetPassiveStrength(client, ClassEffect, TalentName);
		if (IsAbilityCooldown(client, TalentName) || iTalentPoints < 1) return value;
		new Float:fValue = GetPassiveInfo(client, target, GCMKeys[client], GCMValues[client], TalentName, true);
		if (value > 0.0) {

			if (AddingToValue) return value + fValue;
			return value * fValue;
		}
		return value;
	}

	decl String:text[2048];
	decl String:EffectValue[2][64];

	new size = GetArraySize(a_Menu_Talents);
	for (new i = 0; i < size; i++) {

		ClassKeys[client]		= GetArrayCell(a_Menu_Talents, i, 0);
		ClassValues[client]	= GetArrayCell(a_Menu_Talents, i, 1);
		ClassSection[client]	= GetArrayCell(a_Menu_Talents, i, 2);
		GetArrayString(Handle:ClassSection[client], 0, text, sizeof(text));
		if (!StrEqual(text, ActiveClass[client], false)) continue;

		if (catType == 0) FormatKeyValue(text, sizeof(text), ClassKeys[client], ClassValues[client], "class effect?");
		else if (catType == 1) FormatKeyValue(text, sizeof(text), ClassKeys[client], ClassValues[client], "cartel xp?");
		//else FormatKeyValue(text, sizeof(text), ClassKeys[client], ClassValues[client], "cartel effect?");
		break;
	}
	if (StrContains(text, ":", false) == -1) return value;

	new ExplodeCount = GetDelimiterCount(text, "+") + 1;
	decl String:t_Effects[ExplodeCount][64];
	ExplodeString(text, "+", t_Effects, ExplodeCount, 64);

	for (new ii = 0; ii < ExplodeCount; ii++) {

		ExplodeString(t_Effects[ii], ":", EffectValue, 2, 64);
		if (!StrEqual(EffectValue[0], ClassEffect, true)) continue;
		if (value == -1.0) return StringToFloat(EffectValue[1]);
		return value *= StringToFloat(EffectValue[1]);
	}
	if (!AddingToValue) return value;
	else return 0.0;
}

bool:IsTalentClassAllowed(String:sClassList[], String:sClientClass[]) {

	new ExplodeCount = GetDelimiterCount(sClassList, "|") + 1;
	decl String:sClasses[ExplodeCount][64];
	ExplodeString(sClassList, "|", sClasses, ExplodeCount, 64);
	for (new i = 0; i < ExplodeCount; i++) {

		if (!StrEqual(sClasses[i], sClientClass)) continue;
		return true;
	}
	return false;
}

bool:TalentRequirementsMet(client, String:sTalentsRequired[], String:sTalentList[] = "none", TheSize = 0) {

	if (!StrEqual(sTalentsRequired, "-1")) {

		new ExplodeCount = GetDelimiterCount(sTalentsRequired, "|") + 1;
		decl String:sTalents[ExplodeCount][64];
		ExplodeString(sTalentsRequired, "|", sTalents, ExplodeCount, 64);

		decl String:sTalentStrength[2][64];
		decl String:sTalentName[64];
		decl String:text[64];
		for (new i = 0; i < ExplodeCount; i++) {

			ExplodeString(sTalents[i], "_", sTalentStrength, 2, 64);

			if (!StrEqual(sTalentList, "none")) {

				Format(sTalentName, sizeof(sTalentName), "%T", sTalentStrength[0], client);
				Format(sTalentName, sizeof(sTalentName), "%s: %d / %d", sTalentName, GetTalentStrength(client, sTalentStrength[0]), StringToInt(sTalentStrength[1]));
				if (i > 0) Format(text, sizeof(text), "%s\n%s", text, sTalentName);
				else Format(text, sizeof(text), "%s", sTalentName);

				if (i + 1 >= ExplodeCount) {

					Format(sTalentList, TheSize, "%s", text);
					return true;
				}
			}
			else if (GetTalentStrength(client, sTalentStrength[0]) < StringToInt(sTalentStrength[1])) return false;
		}
	}
	return true;

}

stock Float:GetAbilityStrengthByTrigger(activator, target = 0, Ability, zombieclass = 0, damagevalue = 0, bool:IsOverdriveStacks = false, bool:IsCleanse = false, String:ResultEffects[] = "none", ResultType = 0) {	// activator, target, trigger ability, survivor effects, infected effects, common effects, zombieclass, damage

	if (iRPGMode <= 0 || IsLegitimateClient(activator) && (GetClientTeam(activator) == TEAM_SURVIVOR || IsSurvivorBot(activator)) && StrEqual(ActiveClass[activator], "none", false)) return 0.0;
	// ResultType:
	// 0 Activator
	// 1 Target
	//ResultEffects are so when compounding talents we know which type to pull from.
	//This is an alternative to GetAbilityStrengthByTrigger for talents that need it, and maybe eventually the whole system.
	if (target == -2) target = FindAnyRandomClient();
	if (target < 1) target = activator;
	if (!IsLegitimateClient(activator)) return 0.0;

	new talenttarget = 0;
	if (target != activator && IsLegitimateClient(target)) talenttarget = target;
	//if (IsCommonInfected(target)) return 0.0;	// test for lag
	//new Float:EffectValue = 0.0;

	decl String:AbilityT[4];
	Format(AbilityT, sizeof(AbilityT), "%c", Ability);

	new Effect = 0;

	decl String:EffectLoop[55];
	Format(EffectLoop, sizeof(EffectLoop), "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz");

	decl String:activatorteam[10];
	decl String:targetteam[10];

	decl String:activatoreffects[64];
	decl String:targeteffects[64];

	decl String:t_Effect[4];
	Format(t_Effect, sizeof(t_Effect), "%c", Effect);

	//decl String:ActivatorClassRequired[32];
	decl String:TargetClassRequired[32];

	decl String:ActivatorClass[32];
	decl String:TargetClass[32];
	if (IsWitch(target)) Format(TargetClass, sizeof(TargetClass), "7");
	else if (IsSpecialCommon(target)) Format(TargetClass, sizeof(TargetClass), "9");
	else if (IsCommonInfected(target)) Format(TargetClass, sizeof(TargetClass), "a");
	else if (IsLegitimateClient(target)) {

		if (GetClientTeam(target) == TEAM_INFECTED) Format(TargetClass, sizeof(TargetClass), "%d", FindZombieClass(target));
		else Format(TargetClass, sizeof(TargetClass), "0");
	}
	if (GetClientTeam(activator) == TEAM_INFECTED) Format(ActivatorClass, sizeof(ActivatorClass), "%d", FindZombieClass(activator));
	else Format(ActivatorClass, sizeof(ActivatorClass), "0");

	Format(activatorteam, sizeof(activatorteam), "%d", GetClientTeam(activator));
	Format(targetteam, sizeof(targetteam), "0");

	decl String:WeaponsPermitted[512];
	//decl String:WeaponsPermittedStrict[64];
	decl String:PlayerWeapon[64];
	if (GetClientTeam(activator) == TEAM_SURVIVOR || IsSurvivorBot(activator)) GetClientWeapon(activator, PlayerWeapon, sizeof(PlayerWeapon));
	else Format(PlayerWeapon, sizeof(PlayerWeapon), "ignore");


	new Float:f_Strength			= 0.0;
	//new i_Strength = 0;
	new Float:f_FirstPoint			= 0.0;

	new Float:f_EachPoint			= 0.0;

	new Float:f_Time				= 0.0;

	new Float:f_Cooldown			= 0.0;

	new Float:p_Strength			= 0.0;
	new Float:t_Strength			= 0.0;
	//new Float:p_FirstPoint			= 0.0;
	//new Float:p_EachPoint			= 0.0;
	new Float:p_Time				= 0.0;
	//new Float:p_Cooldown			= 0.0;
	new bool:bIsCompounding = false;

	new ASize = GetArraySize(a_Menu_Talents);
	decl String:TalentName[64];
	//decl String:EffectT[5];
	//while (strlen(EffectLoop) > 1) {

	/*
		The idea is all talents can combine with their respective siblings.
	*/
	//Effect = EffectLoop[strlen(EffectLoop) - 1];
	//EffectLoop[strlen(EffectLoop) - 1] = ' ';
	//TrimString(EffectLoop);
	//Format(EffectT, sizeof(EffectT), "%c", Effect);


	new bool:iHasWeakness = PlayerHasWeakness(activator);
	decl String:TheString[64];
	decl String:MultiplierText[64];
	new Float:ExplosiveAmmoRange = 0.0;
	new TheTalentStrength = 0;

	new CombatStateRequired = 0;
	new Float:healregenrange = -1.0;
	new Float:healerpos[3], Float:targetpos[3];

	new iStrengthOverride = 0;
	//new TeamRatingBonus = RaidCommonBoost(true);

	decl String:sClassAllowed[64];
	decl String:sClassID[64];
	decl String:sTalentsRequired[512];

	new bool:bIsStatusEffects = false;

	for (new i = 0; i < ASize; i++) {

		iStrengthOverride = 0;
		bIsStatusEffects = false;
		bIsCompounding = false;

		TriggerKeys[activator]		= GetArrayCell(a_Menu_Talents, i, 0);
		TriggerValues[activator]	= GetArrayCell(a_Menu_Talents, i, 1);

		FormatKeyValue(TheString, sizeof(TheString), TriggerKeys[activator], TriggerValues[activator], "passive ability?");
		if (!StrEqual(TheString, "-1")) continue;	// passive abilities from classes don't trigger here, they have specific points of trigger!

		FormatKeyValue(TheString, sizeof(TheString), TriggerKeys[activator], TriggerValues[activator], "ability trigger?");
		if (StrContains(TheString, AbilityT, true) == -1) continue;
		if (GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "is sub menu?") == 1) continue;

		if (GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "compounding talent?") == 1) bIsCompounding = true;
		if (StrEqual(ResultEffects, "none", false) && bIsCompounding) continue;

		FormatKeyValue(targeteffects, sizeof(targeteffects), TriggerKeys[activator], TriggerValues[activator], "target ability effects?");
		FormatKeyValue(activatoreffects, sizeof(activatoreffects), TriggerKeys[activator], TriggerValues[activator], "activator ability effects?");
		if (bIsCompounding || ResultType == 1) {

			if (ResultType == 0 && StrContains(ResultEffects, activatoreffects, true) == -1) continue;
			if (ResultType == 1) {

				if (IsWitch(target) && StrContains(ResultEffects, targeteffects, true) == -1) continue;
				else if (IsCommonInfected(target) && StrContains(ResultEffects, targeteffects, true) == -1) continue;
				else if (IsLegitimateClient(target) && (GetClientTeam(target) == TEAM_SURVIVOR || IsSurvivorBot(target)) && StrContains(ResultEffects, targeteffects, true) == -1) continue;
				else if (IsLegitimateClient(target) && GetClientTeam(target) == TEAM_INFECTED && StrContains(ResultEffects, targeteffects, true) == -1) continue;
			}
		}

		FormatKeyValue(TheString, sizeof(TheString), TriggerKeys[activator], TriggerValues[activator], "activator team required?");
		if (StrContains(TheString, activatorteam) == -1) continue;
		FormatKeyValue(TheString, sizeof(TheString), TriggerKeys[activator], TriggerValues[activator], "activator class required?");
		if (StrContains(TheString, ActivatorClass) == -1) continue;

		if (GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "is ability?") == 1) continue;
		if (GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "special ammo?") == 1) continue;

		TriggerSection[activator]	= GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(Handle:TriggerSection[activator], 0, TalentName, sizeof(TalentName));
		if (GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "is survivor class role?") == 1) continue;	// class roles aren't talents.
		FormatKeyValue(sTalentsRequired, sizeof(sTalentsRequired), TriggerKeys[activator], TriggerValues[activator], "talents required?");

		//if (!TalentRequirementsMet(activator, sTalentsRequired)) {
		if (!StrEqual(sTalentsRequired, "-1")) {
				
			if (TheTalentStrength > 0) {

				FreeUpgrades[activator] += TheTalentStrength;
				PlayerUpgradesTotal[activator] -= TheTalentStrength;
				AddTalentPoints(activator, TalentName, 0);
			}
			continue;
		}
		
		if (IsSurvivorBot(activator) || !IsFakeClient(activator)) {

			TheTalentStrength = GetTalentStrength(activator, TalentName);
			if (TheTalentStrength < 1) continue;
			if (IsAbilityCooldown(activator, TalentName)) continue;

			FormatKeyValue(sClassAllowed, sizeof(sClassAllowed), TriggerKeys[activator], TriggerValues[activator], "classes allowed?");
			if (!StrEqual(sClassAllowed, "-1")) {

				GetClassValue(activator, sClassID, sizeof(sClassID), "class id?");
				if (!IsTalentClassAllowed(sClassAllowed, sClassID)) continue;
			}
		}
		else {
		//else if (IsLegitimateClient(activator) && IsFakeClient(activator) && iActivatorTeam == TEAM_INFECTED) {

			//if (IsAbilityCooldown(activator, TalentName)) continue;

			if (GetClientTeam(target) == TEAM_SURVIVOR) {

				TheTalentStrength = (Rating[target] / InfectedTalentLevel);
				if (TheTalentStrength < 1) TheTalentStrength = 1;
			}
			else {

				TheTalentStrength = 1;
			}

			iStrengthOverride = TheTalentStrength;
		}
		//if (IsAbilityCooldown(activator, TalentName)) continue;

		//TheTalentStrength = GetTalentStrength(activator, TalentName);
		//if (TheTalentStrength < 1) continue;
		f_Strength	=	TheTalentStrength * 1.0;
		//if (f_Strength <= 0.000) continue;
		//if (IsAbilityCooldown(activator, TalentName)) continue;

		CombatStateRequired = GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "combat state required?");

		if (CombatStateRequired == 1 && !bIsInCombat[activator] ||
			CombatStateRequired == 0 && bIsInCombat[activator]) continue;
		if (!ComparePlayerState(activator, GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "player state required?"))) continue;
		if (!ISBILED[activator] && GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "vomit state required?") == 1) continue;
		if (!HasAdrenaline(activator) && GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "require adrenaline effect?") == 1) continue;
		if (!GetActiveSpecialAmmo(activator, TalentName) && GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "special ammo?") == 1) continue;
		if (iHasWeakness && GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "disabled if weakness?") == 1) continue;
		if (!iHasWeakness && GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "require weakness?") == 1) continue;
		FormatKeyValue(TargetClassRequired, sizeof(TargetClassRequired), TriggerKeys[activator], TriggerValues[activator], "target class required?");
		if (StrContains(TargetClassRequired, TargetClass, false) == -1 && (IsPvP[activator] == 0 || !StrEqual(TargetClass, "0"))) continue;

		if (IsCleanse && GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "cleanse trigger?") != 1) continue;

		if (target != activator) {

			if (IsWitch(target)) {

				if (StrContains(targeteffects, "0", false) != -1) continue;
				Format(targetteam, sizeof(targetteam), "6");
			}

			if (IsCommonInfected(target)) {

				if (StrContains(targeteffects, "0", false) != -1) continue;
				if (IsSpecialCommon(target)) Format(targetteam, sizeof(targetteam), "4");
				else Format(targetteam, sizeof(targetteam), "5");
			}
			if (!IsLegitimateClient(target) && !IsWitch(target) && !IsCommonInfected(target)) continue;
			//if (IsLegitimateClient(target) && GetClientTeam(target) == TEAM_SURVIVOR && StrContains(survivoreffects, EffectT, true) == -1) continue;
			//if (IsLegitimateClient(target) && GetClientTeam(target) == TEAM_INFECTED && StrContains(infectedeffects, EffectT, true) == -1) continue;
			if (IsLegitimateClient(target)) {

				if ((GetClientTeam(target) == TEAM_SURVIVOR || IsSurvivorBot(target)) && StrContains(targeteffects, "0", false) != -1) continue;
				if (GetClientTeam(target) == TEAM_INFECTED && StrContains(targeteffects, "0", false) != -1) continue;
				Format(targetteam, sizeof(targetteam), "%d", GetClientTeam(target));
			}
		}
		else if (StrContains(activatoreffects, "0", false) != -1) continue;
		/*if (IsLegitimateClient(target)) {
			PrintToChat(activator, "survivoreffects: %s Effect: %s", GetKeyValue(TriggerKeys[activator], TriggerValues[activator], "survivor ability effects?"), EffectT);
		}*/
					
		else if (IsLegitimateClient(target)) Format(targetteam, sizeof(targetteam), "%d", GetClientTeam(target));

		if (StrContains(GetKeyValue(TriggerKeys[activator], TriggerValues[activator], "target team required?"), targetteam, false) == -1 && (IsPvP[activator] == 0 || !StrEqual(TargetClass, "0"))) continue;

		if (!StrEqual(PlayerWeapon, "ignore", false)) {

			FormatKeyValue(WeaponsPermitted, sizeof(WeaponsPermitted), TriggerKeys[activator], TriggerValues[activator], "weapons permitted?");
			if (StrEqual(WeaponsPermitted, "melee", false)) {

				if (!IsMeleeAttacker(activator)) continue;
			}
			else if (!StrEqual(WeaponsPermitted, "-1", false) && !StrEqual(WeaponsPermitted, "ignore", false) && !StrEqual(WeaponsPermitted, "all", false) && StrContains(WeaponsPermitted, PlayerWeapon, false) == -1) continue;
		}

		//Format(EffectT, sizeof(EffectT), "%c", Effect);

		//if (GetTalentStrength(activator, TalentName) < 1) continue;

		f_FirstPoint			= GetTalentInfo(activator, TriggerKeys[activator], TriggerValues[activator], _, _, TalentName, talenttarget, iStrengthOverride);
		f_EachPoint				= GetTalentInfo(activator, TriggerKeys[activator], TriggerValues[activator], 1, _, TalentName, talenttarget, iStrengthOverride);
		f_Time					= GetTalentInfo(activator, TriggerKeys[activator], TriggerValues[activator], 2, _, TalentName, talenttarget, iStrengthOverride);
		f_Cooldown				= GetTalentInfo(activator, TriggerKeys[activator], TriggerValues[activator], 3, _, TalentName, talenttarget, iStrengthOverride);

		f_Strength			=	f_FirstPoint + f_EachPoint;

		if (f_Cooldown > 0.00) {

			//if (IsSurvivorBot(activator) || !IsFakeClient(activator))
			CreateCooldown(activator, GetTalentPosition(activator, TalentName), f_Cooldown);
			//if (IsLegitimateClient(target)) CreateImmune(activator, target, GetTalentPosition(target, TalentName), f_Cooldown);
		}
		p_Strength += f_Strength;
		p_Time += f_Time;
		/*
			If an effect was specified, only talents that have that effect will have added talents strength and time.
			The talents that contribute to this combined value each go on their respective cooldowns, so that if they
			come off cooldown at different times, that the player must manage this or experiment with the different outcomes.
		*/
		if (p_Strength > 0.000) {

			/*if (activator == target) Format(MultiplierText, sizeof(MultiplierText), "tS_%s", activatoreffects);
			else if (IsCommonInfected(target)) Format(MultiplierText, sizeof(MultiplierText), "tS_%s", commoneffects);
			else if (IsWitch(target)) Format(MultiplierText, sizeof(MultiplierText), "tS_%s", witcheffects);
			else if (IsLegitimateClientAlive(target)) {
				if (GetClientTeam(target) == TEAM_SURVIVOR || IsSurvivorBot(target)) Format(MultiplierText, sizeof(MultiplierText), "tS_%s", survivoreffects);
				else if (GetClientTeam(target) == TEAM_INFECTED) Format(MultiplierText, sizeof(MultiplierText), "tS_%s", infectedeffects);
			}*/
			if (activator == target) Format(MultiplierText, sizeof(MultiplierText), "tS_%s", activatoreffects);
			else Format(MultiplierText, sizeof(MultiplierText), "tS_%s", targeteffects);
			
			p_Strength = GetClassMultiplier(activator, p_Strength, MultiplierText, _, _, target);

			if (GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "status effect multiplier?") == 1) bIsStatusEffects = true;

			if (bIsCompounding || ResultType == 1) {

				if (!bIsStatusEffects) t_Strength += p_Strength;
				else t_Strength += (p_Strength * MyStatusEffects[activator]);
			}
			else {

				if (!IsOverdriveStacks) {

					if (GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "cleanse trigger?") == 1) {

						p_Strength = (CleanseStack[activator] * p_Strength);
					}
					if (!IsCleanse || GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "is own talent?") == 1) {

						if (bIsStatusEffects) p_Strength = (p_Strength * MyStatusEffects[activator]);
						if (target != activator) {

							//AddTalentExperience(activator, "resilience", RoundToCeil(GetClassMultiplier(activator, p_Strength * 100.0, "reX", true, true)));
							//AddTalentExperience(activator, "technique", RoundToCeil(GetClassMultiplier(activator, p_Strength * 100.0, "teX", true, true)));
							AddTalentExperience(activator, "resilience", RoundToCeil(p_Strength * 100.0));
							AddTalentExperience(activator, "technique", RoundToCeil(p_Strength * 100.0));

							/*if (IsCommonInfected(target)) ActivateAbilityEx(activator, target, damagevalue, targeteffects, p_Strength, p_Time, target);
							if (IsWitch(target)) ActivateAbilityEx(activator, target, damagevalue, targeteffects, p_Strength, p_Time, target);
							if (IsLegitimateClient(target) && GetClientTeam(target) == TEAM_INFECTED) ActivateAbilityEx(activator, target, damagevalue, targeteffects, p_Strength, p_Time, target);
							if (IsLegitimateClient(target) && (GetClientTeam(target) == TEAM_SURVIVOR || IsSurvivorBot(target))) ActivateAbilityEx(activator, target, damagevalue, targeteffects, p_Strength, p_Time, target);*/
							
							ActivateAbilityEx(activator, target, damagevalue, targeteffects, p_Strength, p_Time, target);
						}
						else {

							if (StrContains(TalentName, "regen", false) != -1) {

								if (StrContains(ActiveClass[activator], "shaman", false) != -1) {

									ExplosiveAmmoRange = GetSpecialAmmoStrength(activator, "explosive ammo", 3, _, TheTalentStrength);
									if (!EnemiesWithinExplosionRange(activator, ExplosiveAmmoRange, p_Strength * fTotemRating)) ActivateAbilityEx(activator, activator, damagevalue, activatoreffects, p_Strength, p_Time, target);
								}
								if (StrContains(ActiveClass[activator], "healer", false) != -1 && GetTalentStrength(activator, "healing ammo") > 0) {	// when a healers health regen tics, it heals all teammates nearby, too.

									healregenrange = GetSpecialAmmoStrength(activator, "healing ammo", 3) * 2.0;
									CreateRing(activator, healregenrange, "green:ignore", "20.0:30.0", false, 0.5);	// healer aura is always present on classes that support it.
									GetClientAbsOrigin(activator, healerpos);
									for (new y = 1; y <= MaxClients; y++) {

										if (y == activator) continue;	// client doesn't get double heal.
										if (IsLegitimateClientAlive(y) && (GetClientTeam(y) == TEAM_SURVIVOR || IsSurvivorBot(y)) && bIsInCombat[y]) {

											GetClientAbsOrigin(y, targetpos);
											if (GetVectorDistance(healerpos, targetpos) > healregenrange) continue;

											HealPlayer(y, activator, p_Strength, 'h', true);
										}
									}
								}
								if (StrContains(ActiveClass[activator], "commando", false) != -1 && GetTalentStrength(activator, "healing ammo") > 0) {

									healregenrange = GetSpecialAmmoStrength(activator, "healing ammo", 3);
									CreateRing(activator, healregenrange, "black:ignore", "40.0:50.0", false, 0.5);
									GetClientAbsOrigin(activator, healerpos);
									for (new y = 1; y <= MaxClients; y++) {

										if (y == activator) continue;	// client doesn't get double heal.
										if (IsLegitimateClientAlive(y) && (GetClientTeam(y) == TEAM_SURVIVOR || IsSurvivorBot(y)) && bIsInCombat[y]) {

											GetClientAbsOrigin(y, targetpos);
											if (GetVectorDistance(healerpos, targetpos) > healregenrange) continue;

											//HealPlayer(y, activator, p_Strength, 'h', true);
											RestoreHealBullet(y, RoundToCeil(p_Strength));
										}
									}
								}
							}
							ActivateAbilityEx(activator, activator, damagevalue, activatoreffects, p_Strength, p_Time, target);
						}
					}
					else t_Strength += (CleanseStack[activator] * p_Strength);
				}
				else {

					if (!bIsStatusEffects) t_Strength += p_Strength;
					else t_Strength += (p_Strength * MyStatusEffects[activator]);
				}
			}
			p_Strength = 0.0;
			p_Time = 0.0;
		}
	}
	if (damagevalue > 0) {

		if (ResultType == 0) return (t_Strength * damagevalue);
		if (ResultType == 1) return (damagevalue + (t_Strength * damagevalue));
	}
	return t_Strength;
}

stock bool:EnemiesWithinExplosionRange(client, Float:TheRange, Float:TheStrength) {

	if (!IsLegitimateClientAlive(client)) return false;
	new Float:MyRange[3];
	GetClientAbsOrigin(client, MyRange);

	new ent = -1;

	new bool:IsInRangeTheRange = false;
	new RealStrength = RoundToCeil(TheStrength * GetClientHealth(client));
	if (RealStrength < 1) return false;

	new Float:TheirRange[3];

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || i == client || (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i))) continue;
		GetClientAbsOrigin(i, TheirRange);
		if (GetVectorDistance(MyRange, TheirRange) <= TheRange) {

			if (!IsInRangeTheRange) {

				IsInRangeTheRange = true;
				CreateAmmoExplosion(client, MyRange[0], MyRange[1], MyRange[2]);		// Boom!
			}
			if (IsSpecialCommonInRange(i, 't')) continue;	// even though the mob is within the explosion range, it is immune because a defender is nearby.
			AddSpecialInfectedDamage(client, i, RealStrength, _, 1);
			CheckTeammateDamagesEx(client, i, RealStrength);
		}
	}
	for (new zombie = 0; zombie < GetArraySize(Handle:CommonInfected); zombie++) {

		ent = GetArrayCell(Handle:CommonInfected, zombie);
		if (!IsCommonInfected(ent)) continue;	// || IsClientInRangeSpecialAmmo(ent, DataAmmoEffect, _, i) != -2.0) continue;
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TheirRange);
		if (GetVectorDistance(MyRange, TheirRange) <= TheRange) {

			if (!IsInRangeTheRange) {

				IsInRangeTheRange = true;
				CreateAmmoExplosion(client, MyRange[0], MyRange[1], MyRange[2]);
			}

			if (IsSpecialCommon(ent)) AddSpecialCommonDamage(client, ent, RealStrength, _, 1);
			else AddCommonInfectedDamage(client, ent, RealStrength, _, 1);
		}
	}
	for (new zombie = 0; zombie < GetArraySize(Handle:WitchList); zombie++) {

		ent = GetArrayCell(Handle:WitchList, zombie);
		if (!IsWitch(ent)) continue;
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TheirRange);
		if (GetVectorDistance(MyRange, TheirRange) <= TheRange) {

			if (!IsInRangeTheRange) {

				IsInRangeTheRange = true;
				CreateAmmoExplosion(client, MyRange[0], MyRange[1], MyRange[2]);
			}
			AddWitchDamage(client, ent, RealStrength, _, 1);
		}
	}
	return IsInRangeTheRange;
}

stock bool:ComparePlayerState(client, CombatState) {

	if (CombatState <= 0) return true;
	//new MyCombatState = -1;
	if (CombatState == 1 && IsIncapacitated(client)) return true;
	if (CombatState == 2 && !IsIncapacitated(client)) return true;
	if (CombatState == 3 && L4D2_GetInfectedAttacker(client) == -1 && !IsIncapacitated(client)) return true;
	//if (CombatState )
	return false;
}

stock GetPIV(client, Float:Distance, bool:IsSameTeam = true) {

	new Float:ClientOrigin[3];
	new Float:iOrigin[3];

	GetClientAbsOrigin(client, ClientOrigin);

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || i == client) continue;
		if (IsSameTeam && GetClientTeam(client) != GetClientTeam(i)) continue;
		GetClientAbsOrigin(i, iOrigin);
		if (GetVectorDistance(ClientOrigin, iOrigin) <= Distance) count++;
	}
	return count;
}

stock Float:GetPlayerDistance(client, target) {

	new Float:ClientDistance[3];
	if (!IsWitch(client) && !IsCommonInfected(client)) GetClientAbsOrigin(client, ClientDistance);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientDistance);

	new Float:TargetDistance[3];
	if (!IsWitch(target) && !IsCommonInfected(target)) GetClientAbsOrigin(target, TargetDistance);
	else GetEntPropVector(target, Prop_Send, "m_vecOrigin", TargetDistance);

	return GetVectorDistance(ClientDistance, TargetDistance);
}

stock bool:TriggerAbility(client, victim, ability, pos, Handle:Keys, Handle:Values, String:TalentName[]) {

	if (IsLegitimateClient(client) && (victim == 0 || (IsLegitimateClient(victim) || IsWitch(victim) || IsCommonInfected(victim)))) {// (victim == 0 || (victim > 0 && IsLegitimateClient(victim)))) {

		decl String:abilities[64];
		decl String:DefenseAbility[64];
		Format(DefenseAbility, sizeof(DefenseAbility), "defense");
		FormatKeyValue(abilities, sizeof(abilities), Keys, Values, "ability trigger?");
		if (StrContains(abilities, "c", true) == -1) {				// No chance roll required to execute this ability.

			if (victim == 0 || IsWitch(victim) || IsCommonInfected(victim)) return true;			// Common infected, always returns true if there's no chance roll.
			if (IsLegitimateClient(victim)) return true;
		}
		else if (AbilityChanceSuccess(client, TalentName)) return true;
		//else if (AbilityChanceSuccess(client, TalentName) && (!IsClientActual(victim) || IsFakeClient(victim))) return true;
	}
	return false;
}

stock String:FindAbilityEffects(client, Handle:Keys, Handle:Values, team = 0) {

	decl String:text[64];
	Format(text, sizeof(text), "0");

	if (team == TEAM_SURVIVOR) FormatKeyValue(text, sizeof(text), Keys, Values, "survivor ability effects?");
	else if (team == TEAM_INFECTED) FormatKeyValue(text, sizeof(text), Keys, Values, "infected ability effects?");
	else if (team == 4) FormatKeyValue(text, sizeof(text), Keys, Values, "common ability effects?");
	else if (team == 0) FormatKeyValue(text, sizeof(text), Keys, Values, "witch ability effects?");
	return text;
}

/*stock bool:AbilityChanceUpgradesExist(client, String:s_TalentName[] = "none") {

	

		In order to stream-line the extremely-complex system and introduce it to players in phases
		menus that require the ability chance talent will not be displayed to a player if they have
		not yet placed points in ability chance.
		This prevents a player from accidentally upgrading a ton of abilities that require ability
		chance without upgrading ability chance, simply due to the obtuse design of the talent system.
	
	if (IsLegitimateClient(client)) {

		new pos				=	FindChanceRollAbility(client, s_TalentName);

		if (pos == -1) SetFailState("Ability Requires \'C\' but no ability with effect \'C\' could be found.");

		decl String:talentname[64];
		new i_Strength		=	0;
		new range			=	0;

		AbilityKeys[client]			= GetArrayCell(a_Menu_Talents, pos, 0);
		AbilityValues[client]		= GetArrayCell(a_Menu_Talents, pos, 1);
		AbilitySection[client]		= GetArrayCell(a_Menu_Talents, pos, 2);

		GetArrayString(Handle:AbilitySection[client], 0, talentname, sizeof(talentname));

		i_Strength			=	GetTalentStrength(client, talentname);
		if (i_Strength == 0) return false;
		else return true;
	}
	return false;
}*/

stock bool:AbilityChanceSuccess(client, String:s_TalentName[] = "none") {

	if (IsLegitimateClient(client)) {

		new pos				=	FindChanceRollAbility(client, s_TalentName);

		if (pos == -1) {

			//LogToFile(LogPathDirectory, "Talent Name: %s Ability Requires \'C\' but no ability with effect \'C\' could be found.", s_TalentName);
			return false;
		}
		//if (IsFakeClient(client)) return false;

		decl String:talentname[64];

		new Float:i_FirstPoint	=	0.0;
		new Float:i_EachPoint	=	0.0;
		new i_Strength		=	0;
		new range			=	0;
		new i_Strength_Temp	=	0;
		new Float:i_FirstPoint_Temp = 0.0;
		new Float:i_EachPoint_Temp = 0.0;

		AbilityKeys[client]			= GetArrayCell(a_Menu_Talents, pos, 0);
		AbilityValues[client]		= GetArrayCell(a_Menu_Talents, pos, 1);
		AbilitySection[client]		= GetArrayCell(a_Menu_Talents, pos, 2);

		GetArrayString(Handle:AbilitySection[client], 0, talentname, sizeof(talentname));

		i_FirstPoint			= GetTalentInfo(client, AbilityKeys[client], AbilityValues[client], _, _, talentname);
		i_EachPoint				= GetTalentInfo(client, AbilityKeys[client], AbilityValues[client], 1, _, talentname);
		range					= RoundToCeil(1.0 / ((i_FirstPoint + i_EachPoint) * 100.0));

		i_Strength = GetTalentStrength(client, talentname);
		if (i_Strength == 0) return false;
		i_Strength				= RoundToCeil(i_FirstPoint + (i_EachPoint * i_Strength));

		range				=	GetRandomInt(1, range);

		if (range <= i_Strength) return true;
	}
	return false;
}

stock GetAugmentStrength(augmentId, String:TalentName[]) {

	// Augments have their own unique identifiers that aren't tied to players, even though a player can have the particular item equipped at any time.
}

stock GetUpgradesByCategory(client, String:sTalentCategory[]) {

	new size = GetArraySize(a_Menu_Talents);
	decl String:tValue[64];
	new iCategoryUpgrades = 0;
	for (new i = 0; i < size; i++) {

		UpgradeCategoryKeys[client] = GetArrayCell(a_Menu_Talents, i, 0);
		UpgradeCategoryValues[client] = GetArrayCell(a_Menu_Talents, i, 1);

		FormatKeyValue(tValue, sizeof(tValue), UpgradeCategoryKeys[client], UpgradeCategoryValues[client], "talent tree name?");
		if (!StrEqual(sTalentCategory, tValue)) continue;

		UpgradeCategoryName[client] = GetArrayCell(a_Menu_Talents, i, 2);
		GetArrayString(Handle:UpgradeCategoryName[client], 0, tValue, sizeof(tValue));

		iCategoryUpgrades += GetTalentStrength(client, tValue);
	}
	return iCategoryUpgrades;
}

stock GetTalentStrength(client, String:TalentName[], target = 0) {

	if (!IsLegitimateClient(client)) return 0;
	if (GetClientTeam(client) == TEAM_INFECTED && IsFakeClient(client)) {

		//new counter = RaidCommonBoost(true);
		new counter = 1;
		if (target > 0 && IsLegitimateClient(target) && GetClientTeam(target) == TEAM_SURVIVOR) {

			counter = (Rating[target] / InfectedTalentLevel);
		}
		if (counter < 1) counter = 1;
		return counter;
	}

	new iIsResetTalent = -1;

	new pos = GetMenuPosition(client, TalentName);
	if (pos >= 0) {

		GetTalentStrengthKeys[client] = GetArrayCell(a_Menu_Talents, pos, 0);
		GetTalentStrengthValues[client] = GetArrayCell(a_Menu_Talents, pos, 1);

		if (GetKeyValueInt(GetTalentStrengthKeys[client], GetTalentStrengthValues[client], "is ability?") == 1) return 1;	// abilities are always unlocked for everyone.
		
		if (GetKeyValueInt(GetTalentStrengthKeys[client], GetTalentStrengthValues[client], "is survivor class role?") != 1 &&
			GetKeyValueInt(GetTalentStrengthKeys[client], GetTalentStrengthValues[client], "is sub menu?") != 1) {

			decl String:sClassAllowed[64];
			decl String:sClassID[64];
			FormatKeyValue(sClassAllowed, sizeof(sClassAllowed), GetTalentStrengthKeys[client], GetTalentStrengthValues[client], "classes allowed?");
			if (!StrEqual(sClassAllowed, "-1")) {

				GetClassValue(client, sClassID, sizeof(sClassID), "class id?");
				if (!IsTalentClassAllowed(sClassAllowed, sClassID)) iIsResetTalent = 0;
			}
		}
	}

	//Format(text, sizeof(text), "-1");
	//if (IsLegitimateClient(client)) {

	new size				=	0;
	if (client != -1) size	=	GetArraySize(a_Database_PlayerTalents[client]);
	else size				=	GetArraySize(a_Database_PlayerTalents_Bots);
	decl String:text[64];

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(TalentName, text)) {

			if (iIsResetTalent == 0) {

				iIsResetTalent = GetArrayCell(Handle:a_Database_PlayerTalents[client], i);
				SetArrayCell(Handle:a_Database_PlayerTalents[client], i, 0);
				FreeUpgrades[client] += iIsResetTalent;
				return 0;
			}
			else return GetArrayCell(Handle:a_Database_PlayerTalents[client], i);
		}
	}
	return 0;
}

stock GetKeyPos(Handle:Keys, String:SearchKey[]) {

	decl String:key[64];
	new size = GetArraySize(Keys);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		if (StrEqual(key, SearchKey)) return i;
	}
	return -1;
}

stock FormatKeyValue(String:TheValue[], TheSize, Handle:Keys, Handle:Values, String:SearchKey[], String:DefaultValue[] = "none", bool:bDebug = false) {

	static String:key[64];

	new size = GetArraySize(Keys);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		if (StrEqual(key, SearchKey)) {

			GetArrayString(Handle:Values, i, TheValue, TheSize);
			return;
		}
	}
	if (StrEqual(DefaultValue, "none", false)) Format(TheValue, TheSize, "-1");
	else Format(TheValue, TheSize, "%s", DefaultValue);
}

stock String:GetKeyValue(Handle:Keys, Handle:Values, String:SearchKey[], String:DefaultValue[] = "none", bool:bDebug = false) {

	static String:key[64];

	new size = GetArraySize(Keys);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		if (StrEqual(key, SearchKey)) {

			GetArrayString(Handle:Values, i, key, sizeof(key));
			return key;
		}
	}
	if (StrEqual(DefaultValue, "none", false)) Format(key, sizeof(key), "-1");
	else Format(key, sizeof(key), "%s", DefaultValue);
	return key;
}

stock Float:GetKeyValueFloat(Handle:Keys, Handle:Values, String:SearchKey[], String:DefaultValue[] = "none", bool:bDebug = false) {

	static String:key[64];

	new size = GetArraySize(Keys);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		if (StrEqual(key, SearchKey)) {

			GetArrayString(Handle:Values, i, key, sizeof(key));
			return StringToFloat(key);
		}
	}
	if (StrEqual(DefaultValue, "none", false)) return -1.0;
	return StringToFloat(DefaultValue);
}

stock GetKeyValueInt(Handle:Keys, Handle:Values, String:SearchKey[], String:DefaultValue[] = "none", bool:bDebug = false) {

	static String:key[64];

	new size = GetArraySize(Keys);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		if (StrEqual(key, SearchKey)) {

			GetArrayString(Handle:Values, i, key, sizeof(key));
			return StringToInt(key);
		}
	}
	if (StrEqual(DefaultValue, "none", false)) return -1;
	return StringToInt(DefaultValue);
}

stock GetMenuOfTalent(client, String:TalentName[], String:TheText[], TheSize) {

	decl String:s_TalentName[64];

	new size = GetArraySize(a_Menu_Talents);
	for (new i = 0; i < size; i++) {

		MOTKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
		MOTValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);
		MOTSection[client]		= GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(Handle:MOTSection[client], 0, s_TalentName, sizeof(s_TalentName));
		if (!StrEqual(s_TalentName, TalentName, false)) continue;
		FormatKeyValue(TheText, TheSize, MOTKeys[client], MOTValues[client], "part of menu named?");
		return;
	}
	Format(TheText, TheSize, "-1");
}

stock FindChanceRollAbility(client, String:s_TalentName[] = "none") {

	if (IsLegitimateClient(client)) {

		new a_Size			=	0;

		a_Size		= GetArraySize(a_Menu_Talents);

		decl String:TalentName[64];
		decl String:MenuName[64];

		for (new i = 0; i < a_Size; i++) {

			ChanceKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
			ChanceValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);
			ChanceSection[client]		= GetArrayCell(a_Menu_Talents, i, 2);

			//GetArrayString(Handle:ChanceSection[client], 0, TalentName, sizeof(TalentName));
			//Format(TalentName, sizeof(TalentName), "%s", GetKeyValue(ChanceKeys[client], ChanceValues[client], "part of menu named?"));
			FormatKeyValue(TalentName, sizeof(TalentName), ChanceKeys[client], ChanceValues[client], "part of menu named?");
			GetMenuOfTalent(client, s_TalentName, MenuName, sizeof(MenuName));
			if (!StrEqual(TalentName, MenuName, false)) continue;

			FormatKeyValue(TalentName, sizeof(TalentName), ChanceKeys[client], ChanceValues[client], "activator ability effects?");

			if (StrContains(TalentName, "C", true) != -1) return i;
		}
	}
	return -1;
}

stock GetWeaponSlot(entity) {

	if (IsValidEntity(entity)) {

		decl String:Classname[64];
		GetEntityClassname(entity, Classname, sizeof(Classname));

		if (StrContains(Classname, "pistol", false) != -1 || StrContains(Classname, "chainsaw", false) != -1) return 1;
		if (StrContains(Classname, "molotov", false) != -1 || StrContains(Classname, "pipe_bomb", false) != -1 || StrContains(Classname, "vomitjar", false) != -1) return 2;
		if (StrContains(Classname, "defib", false) != -1 || StrContains(Classname, "first_aid", false) != -1) return 3;
		if (StrContains(Classname, "adren", false) != -1 || StrContains(Classname, "pills", false) != -1) return 4;
		return 0;
	}
	return -1;
}

stock BeanBag(client, Float:force) {

	if (IsLegitimateClientAlive(client)) {

		new myteam = GetClientTeam(client);

		if (myteam == TEAM_INFECTED && L4D2_GetSurvivorVictim(client) != -1 || (GetEntityFlags(client) & FL_ONGROUND)) {

			new Float:Velocity[3];

			Velocity[0]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
			Velocity[1]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
			Velocity[2]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");

			new Float:Vec_Pull;
			new Float:Vec_Lunge;

			Vec_Pull	=	GetRandomFloat(force * -1.0, force);
			Vec_Lunge	=	GetRandomFloat(force * -1.0, force);
			Velocity[2]	+=	force;

			if (Vec_Pull < 0.0 && Velocity[0] > 0.0) Velocity[0] *= -1.0;
			Velocity[0] += Vec_Pull;

			if (Vec_Lunge < 0.0 && Velocity[1] > 0.0) Velocity[1] *= -1.0;
			Velocity[1] += Vec_Lunge;

			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Velocity);
			if (myteam == TEAM_INFECTED) {

				new victim = L4D2_GetSurvivorVictim(client);
				if (victim != -1) TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, Velocity);
			}
		}
	}
}

stock CreateExplosion(client, damage = 0, attacker = 0, bool:IsAOE = false, Float:fRange = 96.0) {

	new entity 				= CreateEntityByName("env_explosion");
	new Float:loc[3], Float:tloc[3];
	new totalIncomingDamage = 0, aClient = 0;
	if (IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_INFECTED) aClient = client;
	if (IsLegitimateClientAlive(client)) GetClientAbsOrigin(client, loc);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", loc);

	DispatchKeyValue(entity, "fireballsprite", "sprites/zerogxplode.spr");
	DispatchKeyValue(entity, "iMagnitude", "0");	// we don't want the fireball dealing damage - we do this manually.
	DispatchKeyValue(entity, "iRadiusOverride", "0");
	DispatchKeyValue(entity, "rendermode", "5");
	DispatchKeyValue(entity, "spawnflags", "0");
	DispatchSpawn(entity);
	TeleportEntity(entity, Float:loc, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "explode");

	new zombieclass = -1;
	if (aClient > 0) FindZombieClass(client);

	if (damage > 0 || zombieclass == ZOMBIECLASS_TANK) {

		if (IsAOE) {

			for (new i = 1; i <= MaxClients; i++) {

				if (!IsLegitimateClientAlive(i)) continue;
				if (!IsSurvivorBot(i) && GetClientTeam(i) != TEAM_SURVIVOR) continue;

				GetClientAbsOrigin(i, tloc);
				if (GetVectorDistance(loc, tloc) > fRange) continue;

				totalIncomingDamage = RoundToCeil(GetClassMultiplier(i, damage * 1.0, "D"));
				if (totalIncomingDamage > 0) {

					SetClientTotalHealth(i, totalIncomingDamage);
					if (aClient > 0 && GetClientTeam(aClient) == TEAM_INFECTED) AddSpecialInfectedDamage(i, client, totalIncomingDamage, true);
				}
				if (zombieclass == ZOMBIECLASS_TANK) {

					// tank aoe jump explosion.
					ScreenShake(i);
					decl String:clientname[64];
					GetClientName(i, clientname, sizeof(clientname));
					ExecCheatCommand(-1, "sm_slap", clientname);
					//L4D_StaggerPlayer(i, client, NULL_VECTOR);
				}
			}
			return;
		}

		if (IsWitch(client)) {

			if (FindListPositionByEntity(client, Handle:WitchList) >= 0) AddWitchDamage(attacker, client, damage);
			else OnWitchCreated(client, true);
		}
		else if (IsSpecialCommon(client)) AddSpecialCommonDamage(attacker, client, damage);
		else if (IsCommonInfected(client)) AddCommonInfectedDamage(attacker, client, damage);
		else if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(attacker) && FindZombieClass(attacker) == ZOMBIECLASS_TANK) {

			totalIncomingDamage = RoundToCeil(GetClassMultiplier(client, damage * 1.0, "D"));

			if ((GetEntityFlags(client) & FL_ONGROUND)) {

				if (CheckActiveAbility(client, totalIncomingDamage, 1) > 0.0) {

					if (GetClientTotalHealth(client) <= totalIncomingDamage) ChangeTankState(attacker, "hulk", true);

					SetClientTotalHealth(client, totalIncomingDamage);
					AddSpecialInfectedDamage(client, attacker, totalIncomingDamage, true);	// bool is tanking instead.
				}
			}
			else {

				// If a player follows the mechanic successfully, hulk ends and changes to death state.

				//ChangeTankState(attacker, "hulk", true);
				//ChangeTankState(attacker, "death");
			}
		}
	}
}

stock CreateAmmoExplosion(client, Float:PosX=0.0, Float:PosY=0.0, Float:PosZ=0.0) {

	new entity 				= CreateEntityByName("env_explosion");
	new Float:loc[3];
	loc[0] = PosX;
	loc[1] = PosY;
	loc[2] = PosZ;

	DispatchKeyValue(entity, "fireballsprite", "sprites/zerogxplode.spr");
	DispatchKeyValue(entity, "iMagnitude", "0");	// we don't want the fireball dealing damage - we do this manually.
	DispatchKeyValue(entity, "iRadiusOverride", "0");
	DispatchKeyValue(entity, "rendermode", "5");
	DispatchKeyValue(entity, "spawnflags", "0");
	DispatchSpawn(entity);
	TeleportEntity(entity, Float:loc, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "explode");
	if (IsValidEntity(entity)) AcceptEntityInput(entity, "Kill");
}

stock ScreenShake(client) {

	new entity = CreateEntityByName("env_shake");

	new Float:loc[3];
	GetClientAbsOrigin(client, loc);
	if(entity >= 0)
	{
		DispatchKeyValue(entity, "spawnflags", "8");
		DispatchKeyValue(entity, "amplitude", "16.0");
		DispatchKeyValue(entity, "frequency", "1.5");
		DispatchKeyValue(entity, "duration", "0.9");
		DispatchKeyValue(entity, "radius", "0.0");
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "Enable");

		TeleportEntity(entity, Float:loc, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "StartShake");

		SetVariantString("OnUser1 !self:Kill::1.1:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

stock ZeroGravity(client, victim, Float:g_TalentStrength, Float:g_TalentTime) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(victim)) {

		if (L4D2_GetSurvivorVictim(victim) != -1 || ((GetEntityFlags(victim) & FL_ONGROUND) || !b_GroundRequired[victim])) {


		//if (GetEntityFlags(victim) & FL_ONGROUND || !b_GroundRequired[victim]) {

			//if (ZeroGravityTimer[victim] == INVALID_HANDLE) {

			new Float:vel[3];
			vel[0] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[0]");
			vel[1] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[1]");
			vel[2] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[2]");
			//ZeroGravityTimer[victim] = 
			CreateTimer(g_TalentTime, Timer_ZeroGravity, victim, TIMER_FLAG_NO_MAPCHANGE);
			SetEntityGravity(victim, GravityBase[victim] - g_TalentStrength);
			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vel);

			new survivor = L4D2_GetSurvivorVictim(victim);
			if (survivor != -1) {

				//ZeroGravityTimer[survivor] = 
				CreateTimer(g_TalentTime, Timer_ZeroGravity, survivor, TIMER_FLAG_NO_MAPCHANGE);
				SetEntityGravity(survivor, GravityBase[survivor] - g_TalentStrength);
				TeleportEntity(survivor, NULL_VECTOR, NULL_VECTOR, vel);
			}
			//}
		}
	}
}

/*stock SpeedIncrease(client, Float:effectTime = 0.0, Float:amount = -1.0, bool:IsTeamAffected = false) {

	if (IsLegitimateClientAlive(client)) {

		//if (amount == -1.0) amount = SpeedMultiplierBase[client];

		//if (effectTime == 0.0) {

		//	if (!IsFakeClient(client)) SpeedMultiplier[client] = SpeedMultiplierBase[client] + (Agility[client] * 0.01) + amount;
		//	else SpeedMultiplier[client] = SpeedMultiplierBase[client] + (Agility_Bots * 0.01) + amount;
		//}
		//else {

		if (amount >= 0.0) {

			SpeedMultiplier[client] = SpeedMultiplierBase[client] + amount;
			//if (SpeedMultiplierTimer[client] != INVALID_HANDLE) {

			//	KillTimer(SpeedMultiplierTimer[client]);
			//	SpeedMultiplierTimer[client] = INVALID_HANDLE;
			//}
			//SpeedMultiplierTimer[client] =
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[client]);
			CreateTimer(effectTime, Timer_SpeedIncrease, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else {

			SetSpeedMultiplierBase(client);
			//SpeedMultiplier[client] = SpeedMultiplierBase[client];
		}
		//LogMessage("%N Base: %3.3f amount: %3.3f Current: %3.3f", client, SpeedMultiplierBase[client], amount, SpeedMultiplier[client]);

		if (IsTeamAffected) {

			for (new i = 1; i <= MaxClients; i++) {

				if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == GetClientTeam(client) && client != i) {

					if (effectTime == 0.0) SpeedMultiplier[i] = SpeedMultiplierBase[i] + (Agility[i] * 0.01) + amount;
					else {

						SpeedMultiplier[i] = SpeedMultiplierBase[i] + amount;
						//if (SpeedMultiplierTimer[i] != INVALID_HANDLE) {

						//	KillTimer(SpeedMultiplierTimer[i]);
						//	SpeedMultiplierTimer[i] = INVALID_HANDLE;
						//}
						//SpeedMultiplierTimer[i] = 
						CreateTimer(effectTime, Timer_SpeedIncrease, i, TIMER_FLAG_NO_MAPCHANGE);
					}
					SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[i]);
				}
			}
		}
	}
}*/

stock SlowPlayer(client, Float:g_TalentStrength, Float:g_TalentTime) {

	if (IsLegitimateClientAlive(client) && ISSLOW[client] == INVALID_HANDLE) {

		//if (SlowMultiplierTimer[client] != INVALID_HANDLE) {

		//	KillTimer(SlowMultiplierTimer[client]);
		//	SlowMultiplierTimer[client] = INVALID_HANDLE;
		//}
		//SlowMultiplierTimer[client] = 
		ISSLOW[client] = CreateTimer(g_TalentTime, Timer_Slow, client, TIMER_FLAG_NO_MAPCHANGE);
		fSlowSpeed[client] = 0.5;
	}
}

stock DamageBonus(attacker, victim, damagevalue, Float:amount) {

	if (IsLegitimateClientAlive(victim)) {

		new i_DamageBonus = RoundToFloor(damagevalue * amount);

		if (GetClientTeam(victim) == TEAM_SURVIVOR || IsSurvivorBot(victim)) {

			//if (GetClientTotalHealth(victim) > i_DamageBonus)
			SetClientTotalHealth(victim, i_DamageBonus); //SetEntityHealth(victim, GetClientHealth(victim) - CommonsDamage);
			//else if (GetClientTotalHealth(victim) <= i_DamageBonus) IncapacitateOrKill(victim, attacker);
		}
		else {

			new isEntityPos = FindListPositionByEntity(victim, Handle:InfectedHealth[attacker]);

			if (isEntityPos < 0) {

				new t_InfectedHealth = DefaultHealth[victim];
				isEntityPos = GetArraySize(Handle:InfectedHealth[attacker]);
				ResizeArray(Handle:InfectedHealth[attacker], isEntityPos + 1);
				SetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, victim, 0);

				new myzombieclass = FindZombieClass(victim);

				//An infected wasn't added on spawn to this player, so we add it now based on class.
				if (myzombieclass == ZOMBIECLASS_TANK) {

					t_InfectedHealth = 4000;
					if (iTankRush == 1) t_InfectedHealth = 1000;
				}
				else if (myzombieclass == ZOMBIECLASS_HUNTER || myzombieclass == ZOMBIECLASS_SMOKER) t_InfectedHealth = 200;
				else if (myzombieclass == ZOMBIECLASS_BOOMER) t_InfectedHealth = 50;
				else if (myzombieclass == ZOMBIECLASS_SPITTER) t_InfectedHealth = 100;
				else if (myzombieclass == ZOMBIECLASS_CHARGER) t_InfectedHealth = 600;
				else if (myzombieclass == ZOMBIECLASS_JOCKEY) t_InfectedHealth = 300;

				if (!IsFakeClient(target)) {

					DefaultHealth[target] = SetMaximumHealth(target);
				}
				else OverHealth[target] = 0;

				if (iBotLevelType == 1) {

					if (myzombieclass != ZOMBIECLASS_TANK) t_InfectedHealth += RoundToCeil(t_InfectedHealth * (SurvivorLevels() * fHealthPlayerLevel[myzombieclass - 1]));
					else t_InfectedHealth += RoundToCeil(t_InfectedHealth * (SurvivorLevels() * fHealthPlayerLevel[myzombieclass - 2]));
				}
				else {

					if (myzombieclass != ZOMBIECLASS_TANK) t_InfectedHealth += RoundToCeil(t_InfectedHealth * (GetDifficultyRating(client) * fHealthPlayerLevel[myzombieclass - 1]));
					else t_InfectedHealth += RoundToCeil(t_InfectedHealth * (GetDifficultyRating(client) * fHealthPlayerLevel[myzombieclass - 2]));
				}
				//t_InfectedHealth += RoundToCeil(t_InfectedHealth * fSurvivorHealthBonus);

				// only add raid health if > 4 survivors.
				new theCount = LivingSurvivorCount();
				if (theCount >= iSurvivorModifierRequired) t_InfectedHealth += RoundToCeil(t_InfectedHealth * ((theCount - (iSurvivorModifierRequired - 1)) * fSurvivorHealthBonus));

				SetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, t_InfectedHealth + OverHealth[victim], 1);
				SetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, 0, 2);
				SetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, 0, 3);
				SetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, 0, 4);
				if (!bHealthIsSet[victim]) {

					bHealthIsSet[victim] = true;

					SetArrayCell(Handle:InfectedHealth[victim], 0, DefaultHealth[victim], 5);
					SetArrayCell(Handle:InfectedHealth[victim], 0, 0, 6);
				}
			}

			if (damagevalue <= 0) return;

			new i_InfectedMaxHealth = GetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, 1);
			new i_InfectedCurrent = GetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, 2);
			new i_HealthRemaining = i_InfectedMaxHealth - i_InfectedCurrent;
			if (i_HealthRemaining <= 0 && !IsFakeClient(victim)) i_HealthRemaining = GetArrayCell(Handle:InfectedHealth[victim], 0, 5);
			if (i_DamageBonus > i_HealthRemaining) i_DamageBonus = i_HealthRemaining;
			SetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, GetArrayCell(Handle:InfectedHealth[attacker], isEntityPos, 2) + i_DamageBonus, 2);

			if (i_InfectedMaxHealth - i_InfectedCurrent <= 0) SetArrayCell(Handle:InfectedHealth[victim], 0, GetArrayCell(Handle:InfectedHealth[victim], 0, 5) + i_DamageBonus, 6);
			RoundDamageTotal += i_DamageBonus;
			RoundDamage[attacker] += i_DamageBonus;
			//LogToFile(LogPathDirectory, "[PLAYER %N] Damage Bonus against %N for %d (base damage: %d)", attacker, victim, i_DamageBonus, damagevalue);

			if (iDisplayHealthBars == 1) {

				DisplayInfectedHealthBars(attacker, victim);
			}
			if (CheckTeammateDamages(victim, attacker) >= 1.0 ||
				CheckTeammateDamages(victim, attacker, true) >= 1.0) {

				if (!IsFakeClient(victim)) {

					decl String:ePct[64];
					ExperienceBar(client, ePct, sizeof(ePct), 2, true);
					if (StringToFloat(ePct) < 100.0) return;
				}
				CalculateInfectedDamageAward(victim, attacker);
			}
		}
	}
}

stock CreateLineSolo(client, target, String:DrawColour[], String:DrawPos[], Float:lifetime = 0.5, targetClient = 0) {

	new Float:ClientPos[3];
	new Float:TargetPos[3];
	if (!IsWitch(client) && !IsCommonInfected(client)) GetClientAbsOrigin(client, ClientPos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	if (!IsWitch(target) && !IsCommonInfected(target)) GetClientAbsOrigin(target, TargetPos);
	else GetEntPropVector(target, Prop_Send, "m_vecOrigin", TargetPos);

	new DrawColourCount = GetDelimiterCount(DrawColour, ":") + 1;
	decl String:t_DrawColour[DrawColourCount][12];
	ExplodeString(DrawColour, ":", t_DrawColour, DrawColourCount, 12);

	decl String:t_DrawPos[DrawColourCount][10];
	ExplodeString(DrawPos, ":", t_DrawPos, DrawColourCount, 10);

	new Float:t_ClientPos[3];
	t_ClientPos = ClientPos;
	new Float:t_TargetPos[3];
	t_TargetPos = TargetPos;

	for (new i = 0; i < DrawColourCount; i++) {

		t_ClientPos = ClientPos;
		t_TargetPos = TargetPos;

		t_ClientPos[2] += StringToFloat(t_DrawPos[i]);
		t_TargetPos[2] += StringToFloat(t_DrawPos[i]);

		if (StrEqual(t_DrawColour[i], "green", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 255, 0, 200}, 50);
		else if (StrEqual(t_DrawColour[i], "red", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 0, 0, 200}, 50);
		else if (StrEqual(t_DrawColour[i], "blue", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 0, 255, 200}, 50);
		else if (StrEqual(t_DrawColour[i], "purple", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 0, 255, 200}, 50);
		else if (StrEqual(t_DrawColour[i], "yellow", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 255, 0, 200}, 50);
		else if (StrEqual(t_DrawColour[i], "orange", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 69, 0, 200}, 50);
		else if (StrEqual(t_DrawColour[i], "black", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 0, 0, 200}, 50);
		else if (StrEqual(t_DrawColour[i], "brightblue", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {132, 112, 255, 200}, 50);
		else if (StrEqual(t_DrawColour[i], "darkgreen", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {178, 34, 34, 200}, 50);
		else continue;
		TE_SendToClient(targetClient);
	}
}
stock CreateRingSolo(client, Float:RingAreaSize, String:DrawColour[], String:DrawPos[], bool:IsPulsing = true, Float:lifetime = 1.0, targetClient, Float:PosX=0.0, Float:PosY=0.0, Float:PosZ=0.0) {

	new Float:ClientPos[3];
	//if (!IsWitch(client) && !IsCommonInfected(client)) GetClientAbsOrigin(client, ClientPos);
	if (client != -1) {

		if (IsLegitimateClient(client)) GetClientAbsOrigin(client, ClientPos);
		else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	}
	else {

		ClientPos[0] = PosX;
		ClientPos[1] = PosY;
		ClientPos[2] = PosZ;
	}

	new Float:pulserange = 0.0;
	if (IsPulsing) pulserange = 32.0;
	else pulserange = RingAreaSize - 32.0;
	//LogMessage("==============\nDraw Colour: %s\n===============", DrawColour);

	new DrawColourCount = GetDelimiterCount(DrawColour, ":") + 1;
	decl String:t_DrawColour[DrawColourCount][12];
	ExplodeString(DrawColour, ":", t_DrawColour, DrawColourCount, 12);

	decl String:t_DrawPos[DrawColourCount][10];
	ExplodeString(DrawPos, ":", t_DrawPos, DrawColourCount, 10);

	ClientPos[2] += 20.0;

	new Float:t_ClientPos[3];
	t_ClientPos = ClientPos;

	for (new i = 0; i < DrawColourCount; i++) {

		t_ClientPos = ClientPos;

		t_ClientPos[2] += StringToFloat(t_DrawPos[i]);

		if (StrEqual(t_DrawColour[i], "green", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 255, 0, 200}, 50, 0);
		else if (StrEqual(t_DrawColour[i], "red", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 0, 200}, 50, 0);
		else if (StrEqual(t_DrawColour[i], "blue", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 255, 200}, 50, 0);
		else if (StrEqual(t_DrawColour[i], "purple", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 255, 200}, 50, 0);
		else if (StrEqual(t_DrawColour[i], "yellow", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 0, 200}, 50, 0);
		else if (StrEqual(t_DrawColour[i], "orange", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 69, 0, 200}, 50, 0);
		else if (StrEqual(t_DrawColour[i], "black", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 0, 200}, 50, 0);
		else if (StrEqual(t_DrawColour[i], "brightblue", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {132, 112, 255, 200}, 50, 0);
		else if (StrEqual(t_DrawColour[i], "darkgreen", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {178, 34, 34, 200}, 50, 0);
		else continue;
		TE_SendToClient(targetClient);
	}
}

// line 840
stock CreateLine(client, target, String:DrawColour[], String:DrawPos[], Float:lifetime = 0.5, targetClient = 0) {

	new Float:ClientPos[3];
	new Float:TargetPos[3];
	if (!IsWitch(client) && !IsCommonInfected(client)) GetClientAbsOrigin(client, ClientPos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	if (!IsWitch(target) && !IsCommonInfected(target)) GetClientAbsOrigin(target, TargetPos);
	else GetEntPropVector(target, Prop_Send, "m_vecOrigin", TargetPos);

	new DrawColourCount = GetDelimiterCount(DrawColour, ":") + 1;
	decl String:t_DrawColour[DrawColourCount][12];
	ExplodeString(DrawColour, ":", t_DrawColour, DrawColourCount, 12);

	decl String:t_DrawPos[DrawColourCount][10];
	ExplodeString(DrawPos, ":", t_DrawPos, DrawColourCount, 10);

	new Float:t_ClientPos[3];
	t_ClientPos = ClientPos;
	new Float:t_TargetPos[3];
	t_TargetPos = TargetPos;

	for (new i = 0; i < DrawColourCount; i++) {

		t_ClientPos = ClientPos;
		t_TargetPos = TargetPos;

		t_ClientPos[2] += StringToFloat(t_DrawPos[i]);
		t_TargetPos[2] += StringToFloat(t_DrawPos[i]);

		for (new y = 1; y <= MaxClients; y++) {

			if (IsLegitimateClient(y) && !IsFakeClient(y) && (y == targetClient || targetClient == 0)) {

				if (StrEqual(t_DrawColour[i], "green", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 255, 0, 200}, 50);
				else if (StrEqual(t_DrawColour[i], "red", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 0, 0, 200}, 50);
				else if (StrEqual(t_DrawColour[i], "blue", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 0, 255, 200}, 50);
				else if (StrEqual(t_DrawColour[i], "purple", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 0, 255, 200}, 50);
				else if (StrEqual(t_DrawColour[i], "yellow", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 255, 0, 200}, 50);
				else if (StrEqual(t_DrawColour[i], "orange", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {255, 69, 0, 200}, 50);
				else if (StrEqual(t_DrawColour[i], "black", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {0, 0, 0, 200}, 50);
				else if (StrEqual(t_DrawColour[i], "brightblue", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {132, 112, 255, 200}, 50);
				else if (StrEqual(t_DrawColour[i], "darkgreen", false)) TE_SetupBeamPoints(t_ClientPos, t_TargetPos, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, 0, 0.5, {178, 34, 34, 200}, 50);
				else continue;
				TE_SendToClient(y);
			}
		}
	}
}

stock CreateRing(client, Float:RingAreaSize, String:DrawColour[], String:DrawPos[], bool:IsPulsing = true, Float:lifetime = 1.0, targetClient = 0) {

	new Float:ClientPos[3];
	if (!IsWitch(client) && !IsCommonInfected(client)) GetClientAbsOrigin(client, ClientPos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);

	new Float:pulserange = 0.0;
	if (IsPulsing) pulserange = 32.0;
	else pulserange = RingAreaSize - 32.0;
	//LogMessage("==============\nDraw Colour: %s\n===============", DrawColour);

	new DrawColourCount = GetDelimiterCount(DrawColour, ":") + 1;
	decl String:t_DrawColour[DrawColourCount][12];
	ExplodeString(DrawColour, ":", t_DrawColour, DrawColourCount, 12);

	decl String:t_DrawPos[DrawColourCount][10];
	ExplodeString(DrawPos, ":", t_DrawPos, DrawColourCount, 10);

	new Float:t_ClientPos[3];
	t_ClientPos = ClientPos;

	for (new i = 0; i < DrawColourCount; i++) {

		t_ClientPos = ClientPos;

		t_ClientPos[2] += StringToFloat(t_DrawPos[i]);

		for (new y = 1; y <= MaxClients; y++) {

			if (IsLegitimateClient(y) && !IsFakeClient(y) && (y == targetClient || targetClient == 0)) {

				if (StrEqual(t_DrawColour[i], "green", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 255, 0, 200}, 50, 0);
				else if (StrEqual(t_DrawColour[i], "red", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 0, 200}, 50, 0);
				else if (StrEqual(t_DrawColour[i], "blue", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 255, 200}, 50, 0);
				else if (StrEqual(t_DrawColour[i], "purple", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 0, 255, 200}, 50, 0);
				else if (StrEqual(t_DrawColour[i], "yellow", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 255, 0, 200}, 50, 0);
				else if (StrEqual(t_DrawColour[i], "orange", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {255, 69, 0, 200}, 50, 0);
				else if (StrEqual(t_DrawColour[i], "black", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {0, 0, 0, 200}, 50, 0);
				else if (StrEqual(t_DrawColour[i], "brightblue", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {132, 112, 255, 200}, 50, 0);
				else if (StrEqual(t_DrawColour[i], "darkgreen", false)) TE_SetupBeamRingPoint(t_ClientPos, pulserange, RingAreaSize, g_iSprite, g_BeaconSprite, 0, 15, lifetime, 2.0, 0.5, {178, 34, 34, 200}, 50, 0);
				else continue;
				TE_SendToClient(y);
			}
		}
	}
}

/*stock BeaconCorpsesInRange(client) {

	new Float:ClientPos[3];
	GetClientAbsOrigin(client, ClientPos);
	new Float:Pos[3];

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i) || GetClientTeam(i) != TEAM_SURVIVOR || IsFakeClient(i) || IsPlayerAlive(i)) continue;
		if (GetVectorDistance(ClientPos, DeathLocation[i]) < 1024.0) {

			Pos[0] = DeathLocation[i][0];
			Pos[1] = DeathLocation[i][1];
			Pos[2] = DeathLocation[i][2] + 40.0;
			TE_SetupBeamRingPoint(Pos, 128.0, 256.0, g_iSprite, g_BeaconSprite, 0, 15, 0.5, 2.0, 0.5, {20, 20, 150, 150}, 50, 0);
			TE_SendToClient(client);
		}
	}
}*/

stock CreateBeacons(client, Float:Distance) {

	new Float:Pos[3];
	new Float:Pos2[3];

	GetClientAbsOrigin(client, Pos);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsLegitimateClientAlive(i) && i != client && GetClientTeam(i) != GetClientTeam(client)) {

			GetClientAbsOrigin(i, Pos2);
			if (GetVectorDistance(Pos, Pos2) > Distance) continue;

			Pos2[2] += 20.0;
			TE_SetupBeamRingPoint(Pos2, 32.0, 128.0, g_iSprite, g_BeaconSprite, 0, 15, 0.5, 2.0, 0.5, {20, 20, 150, 150}, 50, 0);
			TE_SendToClient(client);
		}
	}
}

stock FrozenPlayer(client, Float:effectTime = 3.0, amount = 100) {

	if (IsLegitimateClient(client)) {

		if (amount < 0) amount = 0;
	
		if (amount > 0) {

			SetEntityMoveType(client, MOVETYPE_NONE);
			if (effectTime > 0.0) CreateTimer(effectTime, Timer_FrozenPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
			else if (ISFROZEN[client] == INVALID_HANDLE) ISFROZEN[client] = CreateTimer(0.25, Timer_Freezer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		else SetEntityMoveType(client, MOVETYPE_WALK);

		if (!IsFakeClient(client)) {

			new clients[2];
			clients[0] = client;
			new UserMsg:BlindMsgID = GetUserMessageId("Fade");
			new Handle:message = StartMessageEx(BlindMsgID, clients, 1);

			BfWriteShort(message, 1536);
			BfWriteShort(message, 1536);
			
			if (amount == 0) BfWriteShort(message, (0x0001 | 0x0010));
			else BfWriteShort(message, (0x0002 | 0x0008));

			BfWriteByte(message, 132);
			BfWriteByte(message, 112);
			BfWriteByte(message, 255);
			BfWriteByte(message, amount);

			EndMessage();
		}	
	}
}

stock EnrageBlind(client, amount=0) {

	if (IsLegitimateClient(client) && !IsFakeClient(client)) {

		new clients[2];
		clients[0] = client;
		new UserMsg:BlindMsgID = GetUserMessageId("Fade");
		new Handle:message = StartMessageEx(BlindMsgID, clients, 1);
		BfWriteShort(message, 1536);
		BfWriteShort(message, 1536);
		
		if (amount == 0)
		{
			BfWriteShort(message, (0x0001 | 0x0010));
		}
		else
		{
			BfWriteShort(message, (0x0002 | 0x0008));
		}

		if (amount > 0) {

			BfWriteByte(message, 100);
			BfWriteByte(message, 20);
			BfWriteByte(message, 20);
		}
		else {

			BfWriteByte(message, 0);
			BfWriteByte(message, 0);
			BfWriteByte(message, 0);
		}
		BfWriteByte(message, amount);
		EndMessage();
	}
}

stock BlindPlayer(client, Float:effectTime = 3.0, amount = 0) {

	if (IsLegitimateClient(client) && !IsFakeClient(client)) {

		new clients[2];
		clients[0] = client;
		new UserMsg:BlindMsgID = GetUserMessageId("Fade");
		new Handle:message = StartMessageEx(BlindMsgID, clients, 1);
		BfWriteShort(message, 1536);
		BfWriteShort(message, 1536);
		
		if (amount == 0)
		{
			BfWriteShort(message, (0x0001 | 0x0010));
		}
		else
		{
			BfWriteShort(message, (0x0002 | 0x0008));
		}

		BfWriteByte(message, 0);
		BfWriteByte(message, 0);
		BfWriteByte(message, 0);
		
		if (amount > 0) {

			//b_IsBlind[client] = true;
			if (effectTime > 0.0) CreateTimer(effectTime, Timer_BlindPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
			else {

				/*

					Special Commons set an effect time of 0.0.
				*/
				if (ISBLIND[client] == INVALID_HANDLE) ISBLIND[client] = CreateTimer(0.25, Timer_Blinder, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			BfWriteByte(message, amount);
		}
		else {

			//b_IsBlind[client] = false;
			BfWriteByte(message, 0);
		}
		EndMessage();
	}
}

stock CreateFireEx(client)
{
	if (IsLegitimateClient(client)) {

		decl Float:pos[3];
		GetClientAbsOrigin(client, pos);
		CreateFire(pos);
	}
}

static const String:MODEL_PIPEBOMB[] = "models/w_models/weapons/w_eq_pipebomb.mdl;"

static const String:MODEL_GASCAN[] = "models/props_junk/gascan001a.mdl";
stock CreateFire(const Float:BombOrigin[3])
{
	new entity = CreateEntityByName("prop_physics");
	DispatchKeyValue(entity, "physdamagescale", "0.0");
	if (!IsModelPrecached(MODEL_GASCAN))
	{
		PrecacheModel(MODEL_GASCAN);
	}
	DispatchKeyValue(entity, "model", MODEL_GASCAN);
	DispatchSpawn(entity);
	TeleportEntity(entity, BombOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
	AcceptEntityInput(entity, "Break");
}

stock bool:EnemyCombatantsWithinRange(client, Float:f_Distance) {

	new Float:d_Client[3];
	new Float:e_Client[3]
	GetClientAbsOrigin(client, d_Client);
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) != GetClientTeam(client)) {

			GetClientAbsOrigin(i, e_Client);
			if (GetVectorDistance(d_Client, e_Client) <= f_Distance) return true;
		}
	}
	return false;
}

stock bool:IsTanksActive() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_INFECTED && FindZombieClass(i) == ZOMBIECLASS_TANK) return true;
	}
	return false;
}

stock ModifyGravity(client, Float:g_Gravity = 1.0, Float:g_Time = 0.0, bool:b_Jumping = false) {

	if (IsLegitimateClientAlive(client)) {

		//if (b_IsJumping[client]) return;	// survivors only, for the moon jump ability
		if (b_Jumping) {

			b_IsJumping[client] = true;
			CreateTimer(0.1, Timer_DetectGroundTouch, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		if (g_Gravity == 1.0) SetEntityGravity(client, g_Gravity);
		else {

			if (g_Gravity > 1.0 && g_Gravity < 100.0) g_Gravity *= 0.01;
			else if (g_Gravity > 1.0 && g_Gravity < 1000.0) g_Gravity *= 0.001;
			else if (g_Gravity > 1.0 && g_Gravity < 10000.0) g_Gravity *= 0.0001;
			SetEntityGravity(client, 1.0 - g_Gravity);
		}
		if (g_Gravity < 1.0 && !b_Jumping) CreateTimer(g_Time, Timer_ResetGravity, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock bool:OnPlayerRevived(client, targetclient) {

	if (SetTempHealth(client, targetclient, GetMaximumHealth(targetclient) * fHealthSurvivorRevive, true)) return true;
	return false;
}

stock Float:GetTempHealth(client) {

	return Float:GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
}

stock SetMaximumHealth(client, bool:bIsTemporaryHealth = false, Float:TalentStrength = 0.0) {

	if (GetClientTeam(client) != TEAM_SURVIVOR && !IsSurvivorBot(client)) return DefaultHealth[client];

	if (TalentStrength <= 0.0) {

		TalentStrength = GetAbilityStrengthByTrigger(client, client, 'p', FindZombieClass(client), 0, _, _, "H");
		/*

			If we check if the talent strenght is <= 0.0 here, then we can apply overdose on ALL players (even level 1)
			Keep in mind we allow talent strength of < 1 and > 0 to go through, which means players can actually have less than 100 life when a class is active.
		*/
		if (TalentStrength <= 0.0) {

			TalentStrength = 1.0;
		}
	}

	new Float:TheAbilityMultiplier = GetAbilityMultiplier(client, 'V');
	if (TheAbilityMultiplier == -1.0) TheAbilityMultiplier = 0.0;

	if (GetClientTeam(client) == TEAM_SURVIVOR || IsSurvivorBot(client)) {

		if (!IsIncapacitated(client) && IsClientInRangeSpecialAmmo(client, "O") == -2.0) TalentStrength += (TalentStrength * IsClientInRangeSpecialAmmo(client, "O", false, _, TalentStrength));
		if (!IsFakeClient(client)) DefaultHealth[client] = iSurvivorBaseHealth + RoundToCeil(iSurvivorBaseHealth * (TalentStrength + (TalentStrength * TheAbilityMultiplier)));
		else DefaultHealth[client] = iSurvivorBotBaseHealth + RoundToCeil(iSurvivorBotBaseHealth * (TalentStrength + (TalentStrength * TheAbilityMultiplier)));
	}
	else DefaultHealth[client] = RoundToCeil(OriginalHealth[client] * (TalentStrength + (TalentStrength * TheAbilityMultiplier)));

	//TalentStrength += (TalentStrength * TheAbilityMultiplier);
	if (DefaultHealth[client] > 50000) {

		if (GetClientTeam(client) == TEAM_INFECTED) OverHealth[client] = DefaultHealth[client] - 50000;
		DefaultHealth[client] = 50000;
	}
	else OverHealth[client] = 0;
	//if (TalentStrength > 0.0) DefaultHealth[client] = RoundToCeil(TalentStrength * DefaultHealth[client]);
	//PrintToChat(client, "Default health: %d %3.3f", DefaultHealth[client], TalentStrength);

	/*if (!bIsTemporaryHealth) SetEntProp(client, Prop_Send, "m_iMaxHealth", DefaultHealth[client]);
	else {

		SetTempHealth(client, client, GetTempHealth(client) + (DefaultHealth[client] * 1.0), false);
	}*/
	//LogToFile(LogPathDirectory, "%N Health: %d", DefaultHealth[client]);
	SetEntProp(client, Prop_Send, "m_iMaxHealth", DefaultHealth[client]);
	if ((GetClientTeam(client) == TEAM_SURVIVOR || IsSurvivorBot(client)) && IsIncapacitated(client) && bIsGiveIncapHealth[client]) {

		bIsGiveIncapHealth[client] = false;
		GiveMaximumHealth(client);
	}
	if (GetClientHealth(client) > DefaultHealth[client]) GiveMaximumHealth(client);
	//if (bIsTemporaryHealth) SetTempHealth(client, client, DefaultHealth[client] * 1.0, false);
	return DefaultHealth[client];
}

stock FindZombieClass(client, bool:SIOnly = false)
{
	if (!SIOnly) {

		if (IsWitch(client)) return 7;
		if (IsSpecialCommon(client)) return 8;
		if (IsCommonInfected(client)) return 9;
		if (GetClientTeam(client) == TEAM_SURVIVOR || IsSurvivorBot(client)) return 0;
	}
	if (IsLegitimateClient(client)) return GetEntProp(client, Prop_Send, "m_zombieClass");
	return -1;
}

stock SetInfectedHealth(client, value) {

	SetEntProp(client, Prop_Data, "m_iHealth", value);
}

stock GetInfectedHealth(client) {

	return GetEntProp(client, Prop_Data, "m_iHealth");
}

stock SetBaseHealth(client) {

	SetEntProp(client, Prop_Send, "m_iMaxHealth", DefaultHealth[client]);
}

stock GiveMaximumHealth(client) {

	if (IsLegitimateClientAlive(client) && !b_IsLoading[client]) {
	
		GetAbilityStrengthByTrigger(client, _, 'a', FindZombieClass(client), 0);
		if (GetClientTeam(client) == TEAM_INFECTED || !IsIncapacitated(client)) {

			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
			SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
			SetEntityHealth(client, GetMaximumHealth(client));
		}
		else {

			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", GetMaximumHealth(client) * 1.0);
			if (!IsLedged(client)) SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
			else SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
		}
	}
}

stock GetMaximumHealth(client)
{
	if (IsLegitimateClient(client)) {

		//return GetEntProp(client, Prop_Send, "m_iMaxHealth");
		new iMaxHealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
		if (iMaxHealth > DefaultHealth[client]) DefaultHealth[client] = iMaxHealth;
		return iMaxHealth;
	}
	else return 0;
}

// This is for active statuses, not buffs/talents/etc.
CheckActiveStatuses(client, String:sStatus[], bool:bGetStatus = true, bool:bDeleteStatus = false) {

	decl String:text[64];

	new size = GetArraySize(Handle:ActiveStatuses[client]);

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:ActiveStatuses[client], i, text, sizeof(text));
		if (StrEqual(sStatus, text)) {

			if (!bDeleteStatus || bGetStatus) return 2;	// 2 - Cannot add status because it is already in effect.
			RemoveFromArray(Handle:ActiveStatuses[client], i);
			return 0;									// 0 - means the status was deleted.
		}
	}
	if (!bDeleteStatus && !bGetStatus) {

		PushArrayString(Handle:ActiveStatuses[client], sStatus);
		return 1;										// 1 - status inserted
	}
	return -1;											// -1 - status not found.
}

stock CloakingDevice(client) {

	new theresult = CheckActiveStatuses(client, "lunge");

	if (IsLegitimateClientAlive(client) && theresult == -1) {

		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 0);
		//CreateTimer(g_Time, Timer_CloakingDeviceBreakdown, client, TIMER_FLAG_NO_MAPCHANGE);

		CheckActiveStatuses(client, "lunge", false);	// adds the lunge effect to the active statuses.
	}
}

stock AbsorbDamage(client, Float:s_Strength, damage) {

	if (IsLegitimateClientAlive(client)) {

		if (GetClientTeam(client) == TEAM_INFECTED || !IsIncapacitated(client)) {

			new absorb = RoundToFloor(s_Strength);
			if (absorb > damage) absorb = damage;

			SetEntityHealth(client, GetClientHealth(client) + absorb);
		}
	}
}

stock DamagePlayer(client, victim, Float:s_Strength) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(victim)) {

		new d_Damage = RoundToFloor(s_Strength);

		if (GetClientHealth(victim) > 1) {

			if (GetClientHealth(victim) + 1 < d_Damage) d_Damage = GetClientHealth(victim) - 1;
			if (d_Damage > 0) {

				DamageAward[client][victim] += d_Damage;
				SetEntityHealth(victim, GetClientHealth(victim) - d_Damage);
			}
		}
	}
}

stock WipeDamageAward(client) {

	for (new i = 1; i <= MaxClients; i++) {

		DamageAward[client][i] = 0;
	}
}

stock ReflectDamage(client, target, AttackDamage) {

	if (IsSpecialCommon(target)) AddSpecialCommonDamage(client, target, AttackDamage, true);
	else if (IsCommonInfected(target)) {

		AddCommonInfectedDamage(client, target, AttackDamage, true);
	}
	else if (IsWitch(target)) {

		if (FindListPositionByEntity(target, Handle:WitchList) < 0) OnWitchCreated(target, true);
		AddWitchDamage(client, target, AttackDamage, true);
	}
	else if (IsLegitimateClientAlive(target)) {

		if (GetClientTeam(target) == TEAM_INFECTED) {

			//LogMessage("Survivor %N reflects %d damage at a special!", client, AttackDamage);

			AddSpecialInfectedDamage(client, target, AttackDamage);
			//AddSpecialInfectedDamage(client, target, -1);
		}
		//if (GetClientTeam(target) == TEAM_SURVIVOR) LogMessage("Infected reflecting damage on survivor (ignored)");
	}
	if (IsSpecialCommon(target) || IsWitch(target) || IsLegitimateClientAlive(target)) {

		if (LastAttackedUser[client] == target) ConsecutiveHits[client]++;
		else {

			LastAttackedUser[client] = target;
			ConsecutiveHits[client] = 0;
		}
	}
	if (!IsLegitimateClient(target) || GetClientTeam(target) == TEAM_INFECTED) {

		CheckTeammateDamagesEx(client, target, AttackDamage);
		/*if (IsCommonInfected(target)) LogMessage("Survivor %N reflects %d damage at a common!", client, AttackDamage);
		else if (IsWitch(target)) LogMessage("Survivor %N reflects %d damage at the witch!", client, AttackDamage);
		else if (IsLegitimateClientAlive(target)) LogMessage("Survivor %N reflects %d damage at a special!", client, AttackDamage);*/
	}
}

stock CheckTeammateDamagesEx(client, target, TotalDamage, bool:bSpellDeath = false) {

	// Ex is backwards, client, target
	// CTD is target, client
	if (CheckTeammateDamages(target, client) >= 1.0 ||
		CheckTeammateDamages(target, client, true) >= 1.0) {

		if (IsLegitimateClientAlive(target)) {

			GetAbilityStrengthByTrigger(client, target, 'e', FindZombieClass(client), TotalDamage);
			GetAbilityStrengthByTrigger(target, client, 'E', FindZombieClass(target), TotalDamage);

			CalculateInfectedDamageAward(target, client);
		}
		else if (IsWitch(target)) OnWitchCreated(target, true);
		else if (IsSpecialCommon(target)) {

			ClearSpecialCommon(target, _, TotalDamage, client);
		}
		else if (IsCommonInfected(target)) {

			if (!bSpellDeath) OnCommonInfectedCreated(target, true, client);
			else OnCommonInfectedCreated(target, true, client, true);
		}
	}
}

/*stock ReflectDamage(client, victim, Float:g_TalentStrength, d_Damage) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(victim)) {

		new reflectHealth = RoundToFloor(g_TalentStrength);
		new reflectValue = 0;
		if (reflectHealth > d_Damage) reflectHealth = d_Damage;
		if (!IsIncapacitated(client) && IsPlayerAlive(client)) {

			if (GetClientHealth(client) > reflectHealth) reflectValue = reflectHealth;
			else reflectValue = GetClientHealth(client) - 1;
			SetEntityHealth(client, GetClientHealth(client) - reflectValue);
			DamageAward[client][victim] -= reflectValue;
			DamageAward[victim][client] += reflectValue;
		}
	}
}*/

stock SendPanelToClientAndClose(Handle:panel, client, MenuHandler:handler, time) {

	SendPanelToClient(panel, client, handler, time);
	CloseHandle(panel);
}

stock CreateAcid(client, victim, Float:radius = 128.0) {

	if (IsCommonInfected(client) || IsLegitimateClient(client)) {

		if (IsCommonInfected(victim) || IsLegitimateClientAlive(victim)) {

			new Float:pos[3];
			if (IsLegitimateClient(victim)) GetClientAbsOrigin(victim, pos);
			else GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);
			pos[2] += 12.0;
			new acidball = CreateEntityByName("spitter_projectile");
			if (IsValidEntity(acidball)) {

				DispatchSpawn(acidball);
				SetEntPropEnt(acidball, Prop_Send, "m_hThrower", client);
				SetEntPropFloat(acidball, Prop_Send, "m_DmgRadius", radius);
				SetEntProp(acidball, Prop_Send, "m_bIsLive", 1);
				TeleportEntity(acidball, pos, NULL_VECTOR, NULL_VECTOR);
				SDKCall(g_hCreateAcid, acidball);
			}
		}
	}
}

stock ForceClientJump(activator, Float:g_TalentStrength, victim = 0) {

	if (IsLegitimateClient(activator)) {

		if (GetEntityFlags(activator) & FL_ONGROUND || victim > 0 && GetEntityFlags(victim) & FL_ONGROUND) {

			//new attacker = -1;
			//if (GetClientTeam(activator) != TEAM_INFECTED) attacker = L4D2_GetInfectedAttacker(activator);
			//if (attacker == -1 || !IsClientActual(attacker) || GetClientTeam(attacker) != TEAM_INFECTED || (FindZombieClass(attacker) != ZOMBIECLASS_JOCKEY && FindZombieClass(attacker) != ZOMBIECLASS_CHARGER)) attacker = -1;

			new Float:vel[3];
			vel[0] = GetEntPropFloat(activator, Prop_Send, "m_vecVelocity[0]");
			vel[1] = GetEntPropFloat(activator, Prop_Send, "m_vecVelocity[1]");
			vel[2] = GetEntPropFloat(activator, Prop_Send, "m_vecVelocity[2]");
			vel[2] += g_TalentStrength;
			if (victim == 0) TeleportEntity(activator, NULL_VECTOR, NULL_VECTOR, vel);
			else TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vel);
		}
	}
}

stock ActivateAbilityEx(activator, target, d_Damage, String:Effects[], Float:g_TalentStrength, Float:g_TalentTime, victim = 0, String:Trigger[] = "0") {

	//PrintToChat(activator, "damage %d Effects: %s Strength: %3.2f", d_Damage, Effects, g_TalentStrength);
	// Activator is ALWAYS the person who holds the talent. The TARGET is who the ability ALWAYS activates on.

	if (g_TalentStrength > 0.0) {

		new iDamage = RoundToCeil(d_Damage * g_TalentStrength);
		new oDamage = d_Damage;
		if (iDamage - d_Damage < 0) oDamage = 0;

		if (StrContains(Effects, "a", true) != -1 && !HasAdrenaline(target)) SDKCall(g_hEffectAdrenaline, target, g_TalentTime);
		if (StrContains(Effects, "A", true) != -1 && (GetClientTeam(target) == TEAM_SURVIVOR || IsSurvivorBot(target)) && b_HasDeathLocation[target]) {

			if (!IsPlayerAlive(target)) {

				SDKCall(hRoundRespawn, target);
				b_HasDeathLocation[target] = false;
				CreateTimer(1.0, Timer_TeleportRespawn, target, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		if (StrContains(Effects, "b", true) != -1) BeanBag(target, g_TalentStrength);
		if (StrContains(Effects, "c", true) != -1) {

			//CreateCombustion(target, g_TalentStrength, g_TalentTime);
			if (FindZombieClass(target) != ZOMBIECLASS_TANK) CreateAndAttachFlame(target, iDamage, g_TalentTime, 0.25, activator, "burn");
		}
		if (StrContains(Effects, "d", true) != -1) {

			//if (IsSpecialCommonInRange(activator, 'd')) CreateDamageStatusEffect(, 3, activator, RoundToCeil(d_Damage * g_TalentStrength));
			// If the player is biled, we want to trigger abilities that trigger based on damage dealt when biled on, as the player has just dealt bonus damage.
			// they"ll deal additional bonus damage to the target if this is the case.
			// To prevent potential loops we don"t allow a trigger that calls a damage bonus to trigger any talents that use the same trigger in this regard.
			if (ISBILED[activator]) GetAbilityStrengthByTrigger(activator, target, 'B', FindZombieClass(activator), d_Damage);
			if (IsWitch(target)) AddWitchDamage(activator, target, iDamage, true);
			else if (IsSpecialCommon(target)) AddSpecialCommonDamage(activator, target, iDamage, true);
			else if (IsCommonInfected(target)) {

				AddCommonInfectedDamage(activator, target, iDamage, true);
			}
			else if (IsLegitimateClientAlive(target)) {

				if (GetClientTeam(activator) == TEAM_SURVIVOR && GetClientTeam(target) == GetClientTeam(activator) && activator != target) SameTeam_OnTakeDamage(activator, target, iDamage - oDamage, true);
				else if (GetClientTeam(target) == TEAM_INFECTED) {

					CheckTankSubroutine(target, activator, iDamage, true);
					AddSpecialInfectedDamage(activator, target, iDamage); //DamageBonus(activator, target, d_Damage, g_TalentStrength);
				}
			}
 			if (iDisplayHealthBars == 1) {

				DisplayInfectedHealthBars(activator, target);
			}
			if (CheckTeammateDamages(target, activator) >= 1.0 ||
				CheckTeammateDamages(target, activator, true) >= 1.0) {

				if (IsWitch(target)) OnWitchCreated(target, true);
				else if (IsSpecialCommon(target)) {

					if (IsIncapacitated(activator)) GetAbilityStrengthByTrigger(activator, target, 'K', FindZombieClass(activator), iDamage);
					ClearSpecialCommon(target, _, iDamage, activator);
					//IgniteEntity(target, 1.0);
				}
				else if (IsCommonInfected(target)) {

					OnCommonInfectedCreated(target, true, activator);
					IgniteEntity(target, 1.0);
				}
			}
			else {

				/*

						So the player / common took damage.
				*/
				if (IsSpecialCommon(target)) {

					decl String:TheValue[10];
					GetCommonValue(TheValue, sizeof(TheValue), target, "damage effect?");

					// The bomber explosion initially targets itself so that the chain-reaction (if enabled) doesn"t go indefinitely.
					if (StrContains(TheValue, "f", true) != -1) {

						//CreateExplosion(activator);
						CreateDamageStatusEffect(target, _, activator, iDamage);
					}
					if (!IsSurvivorBot(activator) && StrContains(TheValue, "d", true) != -1) {

						CreateDamageStatusEffect(target, 3, activator, iDamage);		// attacker is not target but just used to pass for reference.
					}
				}
			}
		}

		if (StrContains(Effects, "f", true) != -1 && IsLegitimateClient(target)) CreateFireEx(target);
		if (StrContains(Effects, "E", true) != -1) {

			// Healing based on damage RECEIVED.
			HealPlayer(target, activator, (d_Damage * g_TalentStrength) * 1.0, 'h', true);
		}

		if (StrContains(Effects, "e", true) != -1) CreateBeacons(target, g_TalentStrength);
		//if (StrContains(Effects, "E", true) != -1) SetTempHealth(activator, target, GetMaximumHealth(target) * g_TalentStrength); //SetClientTempHealth(activator, RoundToCeil(GetMaximumHealth(activator) * g_TalentStrength));
		if (StrContains(Effects, "g", true) != -1) ModifyGravity(target, g_TalentStrength, g_TalentTime, true);
		if (StrContains(Effects, "h", true) != -1) {

			HealPlayer(target, activator, g_TalentStrength, 'h');
		}
		if (StrContains(Effects, "u", true) != -1) {

			HealPlayer(target, activator, (d_Damage * g_TalentStrength) * 1.0, 'h', true);
		}
		// the difference is U affects only players not the caster and u affects everyone. we will code a change later on to free this char
		if (StrContains(Effects, "U", true) != -1) {

			if (target != activator && IsLegitimateClientAlive(activator)) {

				HealPlayer(target, activator, (d_Damage * g_TalentStrength) * 1.0, 'h', true);
			}
		}
		if (StrContains(Effects, "H", true) != -1) {

			//ModifyHealth(target, GetAbilityStrengthByTrigger(activator, activator, 'p', FindZombieClass(activator), d_Damage, _, _, "H"), g_TalentTime);
			ModifyHealth(target, g_TalentStrength, g_TalentTime);
		}
		if (StrContains(Effects, "i", true) != -1 && IsLegitimateClientAlive(target)) {

			SDKCall(g_hCallVomitOnPlayer, target, activator, true);
			//IsCoveredInVomit(target, activator);
			ISBILED[target] = true;
		}
		if (StrContains(Effects, "j", true) != -1) ForceClientJump(activator, g_TalentStrength, victim);
		if (StrContains(Effects, "l", true) != -1) CloakingDevice(target);
		if (StrContains(Effects, "m", true) != -1) DamagePlayer(activator, target, g_TalentStrength);
		if (StrContains(Effects, "M", true) != -1) ModifyPlayerAmmo(target, g_TalentStrength);
		if (StrContains(Effects, "o", true) != -1) AbsorbDamage(target, g_TalentStrength, d_Damage);
		//if (StrContains(Effects, "r", true) != -1) SetTempHealth(activator, target, (GetMaximumHealth(target) * g_TalentStrength) + d_Damage, true, true);

		if (StrContains(Effects, "R", true) != -1) {

			//LogToFile(LogPathDirectory, "%N used reflect for %d damage", activator, RoundToCeil(g_TalentStrength * d_Damage));
			//if (IsSpecialCommon(target)) LogToFile(LogPathDirectory, "%N reflected %d to a special common!", activator, RoundToCeil(g_TalentStrength * d_Damage));
			//else if (IsCommonInfected(target)) LogToFile(LogPathDirectory, "%N reflected %d to a common!", activator, RoundToCeil(g_TalentStrength * d_Damage));

			ReflectDamage(activator, target, RoundToCeil(g_TalentStrength * d_Damage));
		}
		if (StrContains(Effects, "s", true) != -1) SlowPlayer(target, 0.5, g_TalentTime);
		if (StrContains(Effects, "S", true) != -1) {

			//L4D_StaggerPlayer(target, activator, NULL_VECTOR);
			//ExecCheatCommand(target, "sm_slap");// this is a workaround but i dont really want the ability in the game anymore. freebies != soulslike
			decl String:clientname[64];
			GetClientName(target, clientname, sizeof(clientname));
			ExecCheatCommand(-1, "sm_slap", clientname);
		}
		if (StrContains(Effects, "t", true) != -1) CreateAcid(activator, target, 512.0);
		if (StrContains(Effects, "T", true) != -1) HealPlayer(target, activator, g_TalentStrength, 'T');
		if (StrContains(Effects, "z", true) != -1) ZeroGravity(activator, target, g_TalentStrength, g_TalentTime);
	}
}


/*new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new weaponIndex = GetPlayerWeaponSlot(client, 0);
	
	if(weaponIndex == -1)
		return Plugin_Continue;
	
	new String:classname[64];
	
	GetEdictClassname(weaponIndex, classname, sizeof(classname));
	
	if(StrEqual(classname, "weapon_rifle_m60") || StrEqual(classname, "weapon_grenade_launcher"))
	{
		new iClip1 = GetEntProp(weaponIndex, Prop_Send, "m_iClip1");
		new iPrimType = GetEntProp(weaponIndex, Prop_Send, "m_iPrimaryAmmoType");
		
		if(StrEqual(classname, "weapon_rifle_m60"))
		{
			SetEntProp(client, Prop_Send, "m_iAmmo", ((GetConVarInt(hM60Ammo)+150)-iClip1), _, iPrimType);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_iAmmo", ((GetConVarInt(hGLAmmo)+1)-iClip1), _, iPrimType);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;


stock bool:CanIReloadTheM60(client) {

	new PlayerWeapon = GetPlayerWeaponSlot(client, 0);
	if (IsValidEntity(PlayerWeapon)) {

		decl String:Classname[64];
		GetEdictClassname(PlayerWeapon, Classname, sizeof(Classname));
		if (StrContains(Classname, "m60", false) != -1) {

			new PlayerAmmo = GetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", 1);
			if (PlayerAmmo < 150) return true;
		}
	}
	return false;
}

stock ReturnClipOnReload(client, activator = -1) {

	if (activator == -1 || !IsLegitimateClient(activator)) activator = client;
	new PlayerWeapon = GetPlayerWeaponSlot(client, 0);	// we only refill primary ammo
	if (!IsValidEntity(PlayerWeapon)) return 0;
	decl String:Classname[64];
	GetEdictClassname(PlayerWeapon, Classname, sizeof(Classname));

	new PlayerAmmo	= GetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", 1);
	new AmmoType	= GetEntProp(PlayerWeapon, Prop_Send, "m_iPrimaryAmmoType");

	if (StrContains(Classname, "m60", false) != -1) {	// the m60 doesn't have reserve ammo, so we call this differently for the m60

		SetEntProp(PlayerWeapon, Prop_Send, "m_iAmmo", 300 - PlayerAmmo);
	}
	else if (StrContains(Classname, "launcher", false) != -1) {

	}
	else {

	}
	return 1;
}*/

stock RestoreHealBullet(client, bulletsRestored = 1) {

	if (!IsMeleeAttacker(client)) {

		new WeaponSlot = GetActiveWeaponSlot(client);
		new PlayerWeapon = GetPlayerWeaponSlot(client, WeaponSlot);
		if (PlayerWeapon < 0 || !IsValidEntity(PlayerWeapon)) return;
		new bullets = GetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", 1);
		if (bullets + bulletsRestored < 200) SetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", bullets + bulletsRestored);
		else SetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", 200);
	}
}

stock ModifyPlayerAmmo(target, Float:g_TalentStrength) {

	new PlayerWeapon = GetPlayerWeaponSlot(target, 0);
	if (!IsValidEntity(PlayerWeapon)) return;

	new PlayerAmmo = GetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", 1);
	//new PlayerMaxAmmo = GetEntProp(PlayerWeapon, Prop_Send, "m_iMaxClip1", 1);
	new PlayerAmmoAward = RoundToCeil(g_TalentStrength * PlayerAmmo);
	PlayerAmmoAward = GetRandomInt(1, PlayerAmmoAward);

	/*

		If the players clip reaches the max, it resets to the default.
	*/
	//new PlayerMaxIncrease = PlayerMaxAmmo + RoundToCeil(PlayerMaxAmmo * g_TalentStrength);
	SetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", PlayerAmmo + PlayerAmmoAward, 1);

	//if (PlayerAmmo + PlayerAmmoAward >= PlayerMaxIncrease) SetEntProp(PlayerWeapon, Prop_Send, "m_iClip1", PlayerMaxAmmo, 1);
}

stock bool:RestrictedWeaponList(String:WeaponName[]) {	// Some weapons might be insanely powerful, so we see if they're in this string and don't let them damage multiplier if they are.

	if (StrContains(RestrictedWeapons, WeaponName, false) != -1) return true;
	return false;
}

stock ConfirmExperienceAction(client, bool:TheRoundHasEnded = false, bool:IsAllowLevelUp = false) {

	if (!IsLegitimateClient(client)) return;

	new ExperienceRequirement = CheckExperienceRequirement(client, _, PlayerLevel[client]);

	if (iIsLevelingPaused[client] == 1) {

		if (ExperienceLevel[client] > ExperienceRequirement) {

			ExperienceOverall[client] -= (ExperienceLevel[client] - ExperienceRequirement);
			ExperienceLevel[client] = ExperienceRequirement;
		}
	}
	if (ExperienceLevel[client] >= ExperienceRequirement && (iIsLevelingPaused[client] == 0 || IsAllowLevelUp)) {

		decl String:Name[64];
		if (!IsSurvivorBot(client)) GetClientName(client, Name, sizeof(Name));
		else GetSurvivorBotName(client, Name, sizeof(Name));
		new count = 0;
		new MaxLevel = iMaxLevel;

		if (PlayerLevel[client] < MaxLevel) {

			LogMessage("Leveling up!\nLevel: %d\nExp: %d\nReq: %d", PlayerLevel[client], ExperienceLevel[client], ExperienceRequirement);

			while (ExperienceLevel[client] >= ExperienceRequirement) {

				ExperienceLevel[client] -= ExperienceRequirement;
				if (PlayerLevel[client] + count <= MaxLevel)	count++;
				if (PlayerLevel[client] + count < MaxLevel) {

					ExperienceRequirement		= CheckExperienceRequirement(client, _, PlayerLevel[client] + count);
				}
				else {

					//ExperienceLevel[client]		= 1;
					ExperienceRequirement		= CheckExperienceRequirement(client, _, MaxLevel);
				}
			}
		}
		else {

			if (ExperienceLevel[client] >= ExperienceRequirement) {

				ExperienceLevel[client] -= ExperienceRequirement;
				count = 1;
			}
		}
		if (ExperienceLevel[client] < 1) ExperienceLevel[client] = 1;
		if (count >= 1) {

			if (count > 0) {

				if (PlayerLevel[client] < MaxLevel) {

					PlayerLevel[client] += count;
					UpgradesAwarded[client] += count;
					UpgradesAvailable[client] += count;
					TotalTalentPoints[client] += count;
					if (!IsSurvivorBot(client)) PrintToChat(client, "%T", "upgrade awarded", client, white, green, orange, white, count);
					PlayerLevelUpgrades[client] = 0;
				}

				if (count == 1) PrintToChatAll("%t", "player level up", green, white, green, Name, PlayerLevel[client]);
				else PrintToChatAll("%t", "player multiple level up", blue, Name, white, green, count, white, blue, AddCommasToString(PlayerLevel[client]));
			}
			else {

				// experience resets & cartel are awarded, but no level if at cap

				//ExperienceLevel[client] = 1;
			}
			// Whenever a player levels, we also level up talents that have earned enough experience for at least 1 point gain.
			ConfirmExperienceActionTalents(client, _, TheRoundHasEnded);

			bIsSettingsCheck = true;
		}
	}
}

stock ConfirmExperienceActionTalents(client, bool:WipeXP = false, bool:TheRoundHasEnded = false) {

	if (!IsLegitimateClient(client) || IsFakeClient(client) && !IsSurvivorBot(client)) return;

	new size = GetArraySize(a_Menu_Talents);
	decl String:text[64];
	decl String:text2[64];
	decl String:Name[64];

	if (!IsSurvivorBot(client)) GetClientName(client, Name, sizeof(Name));
	else GetSurvivorBotName(client, Name, sizeof(Name));
	new count = 0;
	new talentlevel = 0;
	new ExperienceValue = 0;
	new ExperienceRequirement = 0;

	/*if (WipeXP) {
	
		new WipedExperience = RoundToCeil(ExperienceLevel[client] * fDeathPenalty);
		if (WipedExperience > 1) {

			ExperienceOverall[client] -= WipedExperience;
			ExperienceLevel[client] -= WipedExperience;

			if (!IsFakeClient(client)) PrintToChat(client, "%T", "groupmate death penalty", client, blue, orange, green, AddCommasToString(WipedExperience), blue);
			// a member of your group has died!
			// you have lost x experience!
		}
	}*/

	for (new i = 0; i < size; i++) {

		TalentActionKeys[client]		= GetArrayCell(a_Menu_Talents, i, 0);
		TalentActionValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);

		if (GetKeyValueInt(TalentActionKeys[client], TalentActionValues[client], "is sub menu?") == 1) continue;
		if (GetKeyValueInt(TalentActionKeys[client], TalentActionValues[client], "talent type?") <= 0) continue;

		ExperienceValue = GetArrayCell(a_Database_PlayerTalents_Experience[client], i);

		if (WipeXP) {

			ExperienceValue -= RoundToCeil(ExperienceValue * fDeathPenalty);	//	 ExperienceValue = 0;
			if (ExperienceValue < 0) ExperienceValue = 0;
		}
		else {

			TalentActionSection[client]		= GetArrayCell(a_Menu_Talents, i, 2);

			//GetArrayString(a_Database_PlayerTalents_Experience[client], i, text, sizeof(text));
			//GetArrayString(a_Database_PlayerTalents[client], i, text2, sizeof(text2));
			talentlevel = GetArrayCell(a_Database_PlayerTalents[client], i);
			//ExperienceValue = GetArrayCell(a_Database_PlayerTalents_Experience[client], i);
			GetArrayString(TalentActionSection[client], 0, text, sizeof(text));

			ExperienceRequirement		= CheckExperienceRequirementTalents(client, text, talentlevel, i);
			
			//while ((PlayerLevel[client] >= iMaxLevel || talentlevel + count < PlayerLevel[client]) && ExperienceValue >= ExperienceRequirement) {
			while (ExperienceValue >= ExperienceRequirement) {

				ExperienceValue -= ExperienceRequirement;
				count++;
				ExperienceRequirement	= CheckExperienceRequirementTalents(client, text, talentlevel + count, i);
			}
			if (count < 1) continue;	// no level-ups
			for (new ii = 1; ii <= MaxClients; ii++) {

				if (!IsLegitimateClient(ii) || IsFakeClient(ii)) continue;
				Format(text2, sizeof(text2), "%T", text, ii);
				PrintToChat(ii, "%T", "talent level up", ii, blue, Name, white, green, count, white, orange, text2);	//{1}{2} {3}has gained {4}{5} {6}points of {7}{8}
			}
			SetArrayCell(a_Database_PlayerTalents[client], i, talentlevel + count);
		}
		SetArrayCell(a_Database_PlayerTalents_Experience[client], i, ExperienceValue);
		count = 0;
	}
	// if wiping experience, we are also killing the survivor. class data auto-saves when a round ends, when player data saves.
	// to prevent a redundant save, when a player dies, we check that there are other survivors still alive before saving their data.
	if (!TheRoundHasEnded && (!WipeXP || LivingSurvivorCount(client) > 0)) SaveClassData(client);
}

stock AddTalentExperience(client, String:TalentName[], ExperienceAmount, posover = -1) {

	if (b_IsLoading[client]) return;

	new pos = posover;
	if (posover == -1) pos = GetTalentPosition(client, TalentName);
	if (pos == -1) return;
	new size = GetArraySize(a_Menu_Talents);
	if (GetArraySize(a_Database_PlayerTalents[client]) != size) {

		ResizeArray(a_Database_PlayerTalents[client], size);
		ResizeArray(PlayerAbilitiesCooldown[client], size);
		ResizeArray(a_Database_PlayerTalents_Experience[client], size);
		return;
		//for (new i = 1; i <= MAXPLAYERS; i++) ResizeArray(PlayerAbilitiesImmune[client][i], size);
	}
	//if (GetTalentLevel(client, TalentName) < PlayerLevel[client] || PlayerLevel[client] >= iMaxLevel) SetArrayCell(a_Database_PlayerTalents_Experience[client], pos, GetArrayCell(a_Database_PlayerTalents_Experience[client], pos) + ExperienceAmount);
	//if (PlayerLevel[client] < iMaxLevel)
	SetArrayCell(a_Database_PlayerTalents_Experience[client], pos, GetArrayCell(a_Database_PlayerTalents_Experience[client], pos) + ExperienceAmount);
	//else SetArrayCell(a_Database_PlayerTalents_Experience[client], pos, 0);
}

stock CheckExperienceRequirementTalents(client, String:TalentName[], iLevel = 0, posover = -1) {

	if (!IsLegitimateClient(client)) return 0;
	new pos = posover;
	if (posover == -1) pos = GetTalentPosition(client, TalentName);

	new TalentLevel = 0;
	new Float:RequirementMultiplier = 0.0;
	new RequirementStart = 0;

	TalentExperienceKeys[client]		= GetArrayCell(a_Menu_Talents, pos, 0);
	TalentExperienceValues[client]		= GetArrayCell(a_Menu_Talents, pos, 1);

	if (GetKeyValueInt(TalentExperienceKeys[client], TalentExperienceValues[client], "is sub menu?") == 1) return -1;
	if (GetKeyValueInt(TalentExperienceKeys[client], TalentExperienceValues[client], "talent type?") <= 0) return -1;	// incompatible talent.

	RequirementStart = GetKeyValueInt(TalentExperienceKeys[client], TalentExperienceValues[client], "experience start?");
	RequirementMultiplier = GetKeyValueFloat(TalentExperienceKeys[client], TalentExperienceValues[client], "requirement multiplier?");

	/*

		Starting XP for CARTEL categories is dependent on what class the player is using.
		This means we can lean certain classes to have an easier time with leveling certain categories.
	*/
	decl String:sTalentName[4];
	Format(sTalentName, sizeof(sTalentName), "%s", TalentName);

	new iClassRequirement = RoundToCeil(GetClassMultiplier(client, -1.0, sTalentName, 1));
	if (iClassRequirement != -1.0) RequirementStart = iClassRequirement;

	TalentLevel = GetArrayCell(a_Database_PlayerTalents[client], pos);

	if (iLevel == 0) RequirementMultiplier		= RequirementMultiplier * (TalentLevel - 1);
	else RequirementMultiplier					= RequirementMultiplier * (iLevel - 1);

	if (TalentLevel > 0) RequirementStart						+= RoundToCeil(RequirementStart * RequirementMultiplier);

	return RequirementStart;

}

stock CheckExperienceRequirement(client, bool:bot = false, iLevel = 0) {

	new experienceRequirement = 0;
	if (IsLegitimateClient(client)) {

		experienceRequirement			=	iExperienceStart;
		new Float:experienceMultiplier	=	0.0;

		if (iLevel == 0) experienceMultiplier		=	fExperienceMultiplier * (PlayerLevel[client] - 1);
		else experienceMultiplier 					=	fExperienceMultiplier * (iLevel - 1);


		//else experienceMultiplier					=	GetConfigValueFloat("requirement multiplier?") * (PlayerLevel_Bots - 1);

		experienceRequirement			+=	RoundToCeil(experienceRequirement * experienceMultiplier);
	}

	return experienceRequirement;
}

/*stock StrengthValue(client) {

	if (GetRandomInt(1, 100) <= Luck[client]) return GetRandomInt(0, Strength[client]);
	return 0;
}*/

/*stock bool:IsAbilityImmune(owner, client, String:TalentName[]) {

	if (IsLegitimateClient(client)) {

		new a_Size				=	0;
		if (!IsFakeClient(client)) a_Size					=	GetArraySize(a_Database_PlayerTalents[client]);
		else a_Size											=	GetArraySize(a_Database_PlayerTalents_Bots);

		decl String:Name[PLATFORM_MAX_PATH];

		for (new i = 0; i < a_Size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {

				decl String:t_Cooldown[8];
				GetArrayString(Handle:PlayerAbilitiesImmune[owner][client], i, t_Cooldown, sizeof(t_Cooldown));

				//if (!IsFakeClient(client)) GetArrayString(Handle:PlayerAbilitiesImmune[client], i, t_Cooldown, sizeof(t_Cooldown));
				//else GetArrayString(Handle:PlayerAbilitiesImmune_Bots, i, t_Cooldown, sizeof(t_Cooldown));
				if (StrEqual(t_Cooldown, "1")) return true;
				break;
			}
		}
	}
	return false;
}*/

stock bool:SurvivorsBiled() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i)) && ISBILED[i]) return true;
	}
	return false;
}

stock SuperCommonsInPlay(String:Name[]) {

	new size = GetArraySize(Handle:CommonAffixes);
	decl String:text[64];
	new count = 0;

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:CommonAffixes, i, text, sizeof(text));
		if (StrContains(text, Name) != -1) count++;
	}
	return count;
}

/*

	This function is called when a common infected is spawned, and attempts to roll for affixes.
*/
stock CreateCommonAffix(entity) {

	new size = GetArraySize(a_CommonAffixes);
	if (GetArraySize(CommonAffixes) >= iSuperCommonLimit) return;	// there's a maximum limit on the # of super commons.
	//new Float:flMovementSpeed = 1.0;

	//decl String:EntityId[64];
	//Format(EntityId, sizeof(EntityId), "%d", entity);

	new Float:RollChance = 0.0;
	decl String:Section_Name[64];
	decl String:AuraEffectCCA[55];
	decl String:ForceName[64];
	decl String:Model[64];
	Format(ForceName, sizeof(ForceName), "none");
	if (GetArraySize(Handle:SuperCommonQueue) > 0) {

		GetArrayString(Handle:SuperCommonQueue, 0, ForceName, sizeof(ForceName));
		RemoveFromArray(Handle:SuperCommonQueue, 0);
	}

	new maxallowed = 1;

	for (new i = 0; i < size; i++) {

		CCASection			= GetArrayCell(a_CommonAffixes, i, 2);
		CCAKeys				= GetArrayCell(a_CommonAffixes, i, 0);
		CCAValues			= GetArrayCell(a_CommonAffixes, i, 1);

		//if (GetArraySize(AfxSection) < 1 || GetArraySize(AfxKeys) < 1) continue;

		RollChance = GetKeyValueFloat(CCAKeys, CCAValues, "chance?");
		if (!SurvivorsBiled() && GetKeyValueInt(CCAKeys, CCAValues, "require bile?") == 1) continue;
		//if (GetTankWithState(GetKeyValueInt(CCAKeys, CCAValues, "require boss state?")) == 0 && GetKeyValueInt(CCAKeys, CCAValues, "require boss state?") >= 0) continue;		// no tanks with the required state.
		//LogMessage("Roll is 1 - %d (Roll Chance is %3.3f)", RoundToCeil(1.0 / RollChance), RollChance);

		if (StrEqual(ForceName, "none", false) && GetRandomInt(1, RoundToCeil(1.0 / RollChance)) > 1) {

			continue;		// == 1 for successful roll
		}
		//LogMessage("Common %d rolled successfully!", entity);
		GetArrayString(Handle:CCASection, 0, Section_Name, sizeof(Section_Name));
		if (!StrEqual(ForceName, "none", false) && !StrEqual(Section_Name, ForceName, false)) continue;

		maxallowed = GetKeyValueInt(CCAKeys, CCAValues, "max allowed?");
		if (maxallowed < 0) maxallowed = 1;
		if (SuperCommonsInPlay(Section_Name) >= maxallowed) continue;
		
		Format(Section_Name, sizeof(Section_Name), "%s:%d", Section_Name, entity);

		PushArrayString(Handle:CommonAffixes, Section_Name);
		OnCommonCreated(entity);

		//	Now that we've confirmed this common is special, let's go ahead and activate pertinent functions...
		//	Doing some of these, repeatedly, in a timer is a) wasteful and b) crashy. I know, from experience.

		if (GetKeyValueInt(CCAKeys, CCAValues, "glow?") == 1) {

			SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
			SetEntProp(entity, Prop_Send, "m_nGlowRange", RoundToCeil(GetKeyValueFloat(CCAKeys, CCAValues, "glow range?")));
			decl String:iglowColour[3][4];
			ExplodeString(GetKeyValue(CCAKeys, CCAValues, "glow colour?"), " ", iglowColour, 3, 4);
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", StringToInt(iglowColour[0]) + (StringToInt(iglowColour[1]) * 256) + (StringToInt(iglowColour[2]) * 65536));
			AcceptEntityInput(entity, "StartGlowing");
		}
		FormatKeyValue(AuraEffectCCA, sizeof(AuraEffectCCA), CCAKeys, CCAValues, "aura effect?");
		if (StrContains(AuraEffectCCA, "f", true) != -1) CreateAndAttachFlame(entity, _, _, _, _, "burn");
		//else if (StrContains(AuraEffectCCA, "a", true) != -1) CreateAndAttachFlame(entity, _, _, _, _, "acid");		// true for it to deal no damage.

		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", GetKeyValueFloat(CCAKeys, CCAValues, "model size?"));

		//flMovementSpeed = StringToFloat(GetKeyValue(CCAKeys, CCAValues, "movement speed?"));
		//if (flMovementSpeed < 0.5) flMovementSpeed = 1.0;
		//SetEntPropFloat(entity, Prop_Data, "m_flSpeed", flMovementSpeed);
		FormatKeyValue(Model, sizeof(Model), CCAKeys, CCAValues, "force model?");
		if (!StrEqual(Model, "-1") && IsModelPrecached(Model)) SetEntityModel(entity, Model);
		else if (GetArraySize(CommonInfectedQueue) > 0) {

			GetArrayString(Handle:CommonInfectedQueue, 0, Model, sizeof(Model));
			if (IsModelPrecached(Model)) SetEntityModel(entity, Model);
			RemoveFromArray(Handle:CommonInfectedQueue, 0);
		}
		return;		// we only create one affix on a common. maybe we'll allow more down the road.
	}
	// If no special common affix was successful, it's a standard common.

	//ClearArray(Handle:AfxSection);
	//ClearArray(Handle:AfxKeys);
	//ClearArray(Handle:AfxValues);
	//LogMessage("This common remains normal... %d", entity);
}



/*

		2nd / 3rd args have defaults for use with special common infected.
		When these special commons explode, they can apply custom versions of these flames to players
		and the plugin will check every so often to see if a player has such an entity attached to them.
		If they do, they'll burn. Players can have multiple of these, so it is dangerous.
*/
stock CreateAndAttachFlame(client, damage = 0, Float:lifetime = 600.0, Float:tickInt = 1.0, owner = -1, String:DebuffName[] = "burn", Float:tickIntContinued = -2.0) {

	if (IsSurvivalMode && IsCommonInfected(client)) {

		OnCommonInfectedCreated(client, true);
		return;
	}

	//if (!IsClientStatusEffect(client, Handle:EntityOnFire)) {

	decl String:SteamID[512];
	if (IsSurvivorBot(owner)) {

		decl String:TheName[64];
		GetSurvivorBotName(owner, TheName, sizeof(TheName));
		Format(SteamID, sizeof(SteamID), "%s%s", sBotTeam, TheName);
	}
	else {

		if (IsLegitimateClient(owner) && GetClientTeam(owner) == TEAM_SURVIVOR) GetClientAuthString(owner, SteamID, sizeof(SteamID));
		else Format(SteamID, sizeof(SteamID), "%d", owner);
	}
	new Float:TheAbilityMultiplier = GetAbilityMultiplier(client, 'B');
	if (TheAbilityMultiplier > 0.0) damage += RoundToCeil(damage * TheAbilityMultiplier);
	//if (oldowner != -1) Format(SteamID, sizeof(SteamID), "%s_%d", SteamID, oldowner);

	decl String:t_EntityOnFire[64];
	if (tickIntContinued <= 0.0) tickIntContinued = tickInt;
	Format(t_EntityOnFire, sizeof(t_EntityOnFire), "%d+%d+%3.2f+%3.2f+%3.2f+%s+%s", client, damage, lifetime, tickInt, tickIntContinued, SteamID, DebuffName);
	PushArrayString(Handle:EntityOnFire, t_EntityOnFire);
	if (StrEqual(DebuffName, "burn", false)) {

		if (IsLegitimateClient(client) && !(GetEntityFlags(client) & FL_ONFIRE)) {

			//if (FindZombieClass(client) == ZOMBIECLASS_TANK) LogMessage("CreateAndAttachFlame() on tank");
			IgniteEntity(client, lifetime);
		}
	}
	if (StrEqual(DebuffName, "acid", false) && (IsLegitimateClient(client) || damage == 0 && IsCommonInfected(client))) CreateAcid(FindInfectedClient(true), client, 128.0);

	//}
}

stock TransferStatusEffect(client, Handle:EffectHandle, target) {

	new size = GetArraySize(Handle:EffectHandle);
	decl String:Evaluate[7][64];
	decl String:Value[64];
	decl String:ClientS[512];
	decl String:TargetS[64];
	decl String:TheName[64];
	if (IsSurvivorBot(client)) {

		GetSurvivorBotName(client, TheName, sizeof(TheName));
		Format(ClientS, sizeof(ClientS), "%s%s", sBotTeam, TheName);
	}
	else {

		if (IsLegitimateClient(client) && GetClientTeam(client) == TEAM_SURVIVOR) GetClientAuthString(client, ClientS, sizeof(ClientS));
		else Format(ClientS, sizeof(ClientS), "%d", client);
	}
	if (IsSurvivorBot(target)) {

		GetSurvivorBotName(target, TheName, sizeof(TheName));
		Format(TargetS, sizeof(TargetS), "%s%s", sBotTeam, TheName);
	}
	else {

		GetClientAuthString(target, TargetS, sizeof(TargetS));
	}
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:EffectHandle, i, Value, sizeof(Value));
		ExplodeString(Value, "+", Evaluate, 7, 64);

		if (StrEqual(ClientS, Evaluate[5], false)) {

			//CreateAndAttachFlame(target, StringToInt(Evaluate[1]), StringToFloat(Evaluate[2]), StringToFloat(Evaluate[3]), -2, Evaluate[6], StringToFloat(Evaluate[4]));	//owner as -2 indicates cleansing debuff.
			CleansingContribution[target] += StringToInt(Evaluate[1]);
			RemoveFromArray(Handle:EffectHandle, i);
			return;
		}
	}
}

stock GetClientStatusEffect(client, Handle:EffectHandle, String:EffectName[] = "burn") {

	new Count = 0;
	decl String:Evaluate[7][64];
	decl String:Value[64];
	decl String:ClientS[512];
	decl String:TheName[64];
	/*if (IsSurvivorBot(client)) {

		GetSurvivorBotName(client, TheName, sizeof(TheName));
		Format(ClientS, sizeof(ClientS), "%s%s", sBotTeam, TheName);
	}
	else {

		if (IsLegitimateClient(client) && GetClientTeam(client) == TEAM_SURVIVOR) GetClientAuthString(client, ClientS, sizeof(ClientS));
		else Format(ClientS, sizeof(ClientS), "%d", client);
	}*/
	Format(ClientS, sizeof(ClientS), "%d", client);
	for (new i = 0; i < GetArraySize(Handle:EffectHandle); i++) {

		GetArrayString(Handle:EffectHandle, i, Value, sizeof(Value));
		ExplodeString(Value, "+", Evaluate, 7, 64);

		if (StrEqual(ClientS, Evaluate[0], false)) {

			if (StrEqual(EffectName, Evaluate[6], false)) Count++;
		}
	}
	return Count;
}

stock GetClientCleanse(client, Handle:EffectHandle) {

	new Count = 0;
	new size = GetArraySize(Handle:EffectHandle);
	decl String:Evaluate[7][64];
	decl String:Value[64];
	decl String:ClientS[512];
	decl String:TheName[64];

	if (IsSurvivorBot(client)) {

		GetSurvivorBotName(client, TheName, sizeof(TheName));
		Format(ClientS, sizeof(ClientS), "%s%s", sBotTeam, TheName);
	}
	else {

		if (IsLegitimateClient(client) && GetClientTeam(client) == TEAM_SURVIVOR) GetClientAuthString(client, ClientS, sizeof(ClientS));
		else Format(ClientS, sizeof(ClientS), "%d", client);
	}
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:EffectHandle, i, Value, sizeof(Value));
		ExplodeString(Value, "+", Evaluate, 7, 64);

		if (client == StringToInt(Evaluate[0]) && StrEqual(Evalulate[5], "-2", false)) Count++;
	}
	return Count;
}

stock bool:IsClientStatusEffect(client, Handle:EffectHandle, bool:RemoveIt=false, String:EffectName[] = "burn") {

	new size = GetArraySize(Handle:EffectHandle);
	decl String:Evaluate[7][64];
	decl String:Value[64];
	decl String:ClientS[512];
	decl String:TheName[64];

	if (IsSurvivorBot(client)) {

		GetSurvivorBotName(client, TheName, sizeof(TheName));
		Format(ClientS, sizeof(ClientS), "%s%s", sBotTeam, TheName);
	}
	else {

		if (IsLegitimateClient(client) && GetClientTeam(client) == TEAM_SURVIVOR) GetClientAuthString(client, ClientS, sizeof(ClientS));
		else Format(ClientS, sizeof(ClientS), "%d", client);
	}
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:EffectHandle, i, Value, sizeof(Value));
		ExplodeString(Value, "+", Evaluate, 7, 64);

		if (StrEqual(ClientS, Evaluate[5], false) && StrEqual(EffectName, Evaluate[6], false)) {

			if (RemoveIt) RemoveFromArray(Handle:EffectHandle, i);
			return true;
		}
	}
	return false;
}

stock ClearRelevantData() {

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsClientActual(i) || !IsClientInGame(i)) continue;
		ResetOtherData(i);
	}
	//ClearArray(Handle:WitchList);
}

stock WipeDebuffs(bool:IsEndOfCampaign = false, client = -1, bool:IsDisconnect = false) {

	if (client == -1) {

		ResetArray(Handle:CommonInfected);
		ResetArray(Handle:WitchList);
		ResetArray(Handle:CommonList);

		if (IsEndOfCampaign) {

			ClearArray(Handle:EntityOnFire);
			ClearArray(Handle:CommonInfectedQueue);
			ClearArray(Handle:CommonList);
			Points_Director = 0.0;

			for (new i = 1; i <= MaxClients; i++) {

				if (IsLegitimateClient(i)) Points[i] = 0.0;
			}
		}
	}
	else {

		b_HardcoreMode[client] = false;
		ResetCDImmunity(client);
		EnrageBlind(client, 0);

		if (IsDisconnect) {

			CleanseStack[client] = 0;
			CounterStack[client] = 0.0;
			MultiplierStack[client] = 0;
			Format(BuildingStack[client], sizeof(BuildingStack[]), "none");

			Points[client] = 0.0;
		}
		b_IsFloating[client] = false;
		if (b_IsActiveRound) b_IsInSaferoom[client] = false;
		else b_IsInSaferoom[client] = true;
		b_IsBlind[client]				= false;
		b_IsImmune[client]				= false;
		b_IsJumping[client]				= false;
		CommonKills[client]				= 0;
		CommonKillsHeadshot[client]		= 0;
		bIsMeleeCooldown[client]			= false;
		AmmoTriggerCooldown[client] = false;
		ExplosionCounter[client][0] = 0.0;
		ExplosionCounter[client][1] = 0.0;
		HealingContribution[client] = 0;
		TankingContribution[client] = 0;
		DamageContribution[client] = 0;
		PointsContribution[client] = 0.0;
		HexingContribution[client] = 0;
		BuffingContribution[client] = 0;
		CleansingContribution[client] = 0;
		//if (HandicapLevel[client] < 1) HandicapLevel[client] = -1;
		if (PlayerHasWeakness(client)) bHasWeakness[client] = false;
		bIsHandicapLocked[client] = false;
		WipeDamageContribution(client);
	}
}

public Action:Timer_EntityOnFire(Handle:timer) {

	if (!b_IsActiveRound) {

		for (new i = 1; i <= MAXPLAYERS; i++) {

			ClearArray(Handle:CommonInfectedDamage[i]);
		}
		return Plugin_Stop;
	}
	static String:Value[64];
	static String:Evaluate[7][512];
	static Client = 0;
	static damage = 0;
	static Owner = 0;
	static Float:FlTime = 0.0;
	static Float:TickInt = 0.0;
	static Float:TickIntOriginal = 0.0;
	static t_Damage = 0;
	//decl String:t_Delim[2][64];
	static String:t_EntityOnFire[64];
	static String:ModelName[64];
	static DamageShield = 0;

	//decl String:EntityClassname[64];
	//decl String:Remainder[64];
	//decl String:SteamID[64];

	//new size = GetArraySize(Handle:EntityOnFire);
	for (new i = 0; i < GetArraySize(Handle:EntityOnFire); i++) {

		GetArrayString(Handle:EntityOnFire, i, Value, sizeof(Value));
		ExplodeString(Value, "+", Evaluate, 7, 512);

		Client = StringToInt(Evaluate[0]);
		if (!IsCommonInfected(Client) && !IsWitch(Client) && !IsLegitimateClientAlive(Client)) {

			RemoveFromArray(Handle:EntityOnFire, i);
			//if (i > 0) i--;
			//size = GetArraySize(Handle:EntityOnFire);
			continue;
		}
		/*

			Grab the damage n stuff
		*/
		damage = StringToInt(Evaluate[1]);
		//if (damage == 0) continue;	// for the mobs we don't want to deal damage to / we want the fire to exist until they die.

		FlTime = StringToFloat(Evaluate[2]);
		TickInt = StringToFloat(Evaluate[3]);
		TickIntOriginal = StringToFloat(Evaluate[4]);
		if (!StrEqual(Evaluate[5], "-1", false)) Owner = FindClientWithAuthString(Evaluate[5]);

		FlTime -= 0.5;
		TickInt -= 0.5;
		if (TickInt <= 0.0) {

			TickInt = TickIntOriginal;

			t_Damage = RoundToCeil(damage / (FlTime / TickInt));
			damage -= t_Damage;

			// HERE WE FIND OUT IF THE COMMON OR WITCH OR WHATEVER IS IMMUNE TO THE DAMAGE
			//CODEBEAN

			GetEntPropString(Client, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
			if (IsLegitimateClient(Client) && (GetClientTeam(Client) == TEAM_SURVIVOR || IsSurvivorBot(Client)) || !IsSpecialCommonInRangeEx(Client, "jimmy") && StrContains(ModelName, "jimmy", false) == -1 && !IsSpecialCommonInRange(Client, 't')) {

				if (IsLegitimateClientAlive(Client)) {

					if (IsClientInRangeSpecialAmmo(Client, "D") == -2.0) {

						DamageShield = RoundToCeil(t_Damage * (1.0 - IsClientInRangeSpecialAmmo(Client, "D", false, _, t_Damage * 1.0)));
						if (DamageShield > 0) SetClientTotalHealth(Client, DamageShield);
					}
					else SetClientTotalHealth(Client, t_Damage);
				}
				else EntityStatusEffectDamage(Client, t_Damage);
				if (StrEqual(Evaluate[6], "burn", false) && FindZombieClass(Client) != ZOMBIECLASS_TANK) {

					IgniteEntity(Client, TickInt);
				}
				else if (StrEqual(Evaluate[6], "acid", false)) CreateAcid(FindInfectedClient(true), Client, 48.0);
				if (IsLegitimateClientAlive(Owner)) {

					HexingContribution[Owner] += t_Damage;
					GetAbilityStrengthByTrigger(Client, Owner, 'L', FindZombieClass(Client), t_Damage);
				}
				if (StrEqual(Evaluate[5], "-2", false)) CleansingContribution[Client] += t_Damage;
			}
		}
		if (FlTime <= 0.0 || damage <= 0) {

			RemoveFromArray(Handle:EntityOnFire, i);
			//if (i > 0) i--;
			//size = GetArraySize(Handle:EntityOnFire);
			continue;
		}
		Format(t_EntityOnFire, sizeof(t_EntityOnFire), "%d+%d+%3.2f+%3.2f+%3.2f+%s+%s", Client, damage, FlTime, TickInt, TickIntOriginal, Evaluate[5], Evaluate[6]);
		//ogMessage("ON FIRE CONTINUE %s", t_EntityOnFire);
		SetArrayString(Handle:EntityOnFire, i, t_EntityOnFire);
	}
	return Plugin_Continue;
}

stock CreateCombustion(client, Float:g_Strength, Float:f_Time)
{
	new entity				= CreateEntityByName("env_fire");
	new Float:loc[3];
	GetClientAbsOrigin(client, loc);

	decl String:s_Strength[64];
	Format(s_Strength, sizeof(s_Strength), "%3.3f", g_Strength);

	DispatchKeyValue(entity, "StartDisabled", "0");
	DispatchKeyValue(entity, "damagescale", s_Strength);
	decl String:s_Health[64];
	Format(s_Health, sizeof(s_Health), "%3.3f", f_Time);

	DispatchKeyValue(entity, "fireattack", "2");
	DispatchKeyValue(entity, "firesize", "128");
	DispatchKeyValue(entity, "health", s_Health);
	DispatchKeyValue(entity, "ignitionpoint", "1");
	DispatchSpawn(entity);

	TeleportEntity(entity, Float:loc, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "Enable");
	AcceptEntityInput(entity, "StartFire");
	
	CreateTimer(f_Time, Timer_DestroyCombustion, entity, TIMER_FLAG_NO_MAPCHANGE);
}


// FIX THIS FIRST
stock GetSpecialCommonDamage(damage, client, Effect, victim) {

	/*

		Victim is always a survivor, and is only used to pass to the GetCommonsInRange function which uses their level
		to determine its range of buff.
	*/
	new Float:f_Strength = 1.0;

	new Float:ClientPos[3], Float:fEntPos[3];
	if (IsCommonInfected(client) || IsWitch(client)) GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	else if (IsLegitimateClientAlive(client)) GetClientAbsOrigin(client, ClientPos);

	new ent = -1;
	decl String:EffectT[4];
	Format(EffectT, sizeof(EffectT), "%c", Effect);

	decl String:AuraEffectIsh[10];
	for (new i = 0 ; i < GetArraySize(Handle:CommonInfected); i++) {

		ent = GetArrayCell(Handle:CommonInfected, i);
		if (ent == client || !IsSpecialCommon(ent)) continue;
		GetCommonValue(AuraEffectIsh, sizeof(AuraEffectIsh), ent, "aura effect?");
		if (StrContains(AuraEffectIsh, EffectT, true) != -1) {

			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fEntPos);
			
			//	If the damaging common is in range of an entity meeting the specific effect, then we add its effects. In this case, it's damage.
			
			if (IsInRange(fEntPos, ClientPos, GetCommonValueFloat(ent, "range max?"), GetCommonValueFloat(ent, "model size?"))) {

				f_Strength += (GetCommonValueFloat(ent, "strength target?") * GetEntitiesInRange(ent, victim, 0));
				f_Strength += (GetCommonValueFloat(ent, "strength special?") * GetEntitiesInRange(ent, victim, 1));
			}
		}
	}
	return RoundToCeil(damage * f_Strength);
}

stock GetEntitiesInRange(client, victim, EntityType) {

	new Float:ClientPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);

	new Float:AfxRange		= GetCommonValueFloat(client, "range player level?") * PlayerLevel[victim];
	new Float:AfxRangeMax	= GetCommonValueFloat(client, "range max?");
	new Float:ModelSize		= GetCommonValueFloat(client, "model size?");
	new Float:AfxRangeBase	= GetCommonValueFloat(client, "range minimum?");
	if (AfxRange + AfxRangeBase > AfxRangeMax) AfxRange = AfxRangeMax;
	else AfxRange += AfxRangeBase;

	new ent = -1;
	new Float:EntPos[3];

	new count = 0;
	if (EntityType == 0) {

		for (new i = 0; i < GetArraySize(Handle:CommonInfected); i++) {

			ent = GetArrayCell(Handle:CommonInfected, i);
			if (ent != client && IsCommonInfected(ent)) {

				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", EntPos);
				if (IsInRange(ClientPos, EntPos, AfxRange, ModelSize)) count++;
			}
		}
	}
	else {

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_INFECTED) {

				GetClientAbsOrigin(i, EntPos);
				if (IsInRange(ClientPos, EntPos, AfxRange, ModelSize)) count++;
			}
		}
	}
	return count;
}

stock bool:IsSpecialCommonInRangeEx(client, String:vEntity[]="none", bool:IsAuraEffect = true) {	// false for death effect

	new Float:ClientPos[3];
	new Float:fEntPos[3];
	if (IsCommonInfected(client) || IsWitch(client)) GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	else if (IsLegitimateClientAlive(client)) GetClientAbsOrigin(client, ClientPos);

	new ent = -1;
	//new Effect = 't';
	for (new i = 0; i < GetArraySize(Handle:CommonInfected); i++) {

		ent = GetArrayCell(Handle:CommonInfected, i);
		if (ent == client || !IsCommonInfected(ent)) continue;

		if (!StrEqual(vEntity, "none", false)) {

			if(!CommonInfectedModel(ent, vEntity)) continue;
		}
		else if (!IsSpecialCommon(ent)) continue;

		/*

			At a certain level, like a lower one, it's just too much having to deal with auras, so some players will absolutely be oblivious to the shit
			going on and killing other players who CAN see them.
		*/
		if (IsLegitimateClient(client) && PlayerLevel[client] < GetCommonValueInt(ent, "level required?")) return false;

		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fEntPos);
		if (IsInRange(fEntPos, ClientPos, GetCommonValueFloat(ent, "range max?"), GetCommonValueFloat(ent, "model size?"))) return true;
	}
	return false;
}

stock bool:IsSpecialCommonInRange(client, Effect = -1, vEntity = -1, bool:IsAuraEffect = true) {	// false for death effect

	new Float:ClientPos[3];
	new Float:fEntPos[3];
	if (IsCommonInfected(client) || IsWitch(client)) GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	else if (IsLegitimateClientAlive(client)) GetClientAbsOrigin(client, ClientPos);

	decl String:EffectT[4];
	Format(EffectT, sizeof(EffectT), "%c", Effect);

	decl String:TheAuras[10];
	decl String:TheDeaths[10];

	if (vEntity != -1) {

		GetCommonValue(TheAuras, sizeof(TheAuras), vEntity, "aura effect?");
		GetCommonValue(TheDeaths, sizeof(TheDeaths), vEntity, "death effect?");

		new Float:AfxRange = GetCommonValueFloat(vEntity, "range player level?");
		//new Float:AfxStrengthLevel = StringToFloat(GetCommonValue(vEntity, "level strength?"));
		new Float:AfxRangeMax = GetCommonValueFloat(vEntity, "range max?");
		//new AfxMultiplication = StringToInt(GetCommonValue(vEntity, "enemy multiplication?"));
		//new AfxStrength = StringToInt(GetCommonValue(vEntity, "aura strength?"));
		//new AfxChain = StringToInt(GetCommonValue(vEntity, "chain reaction?"));
		//new Float:AfxStrengthTarget = StringToFloat(GetCommonValue(vEntity, "strength target?"));
		new Float:AfxRangeBase = GetCommonValueFloat(vEntity, "range minimum?");
		new AfxLevelReq = GetCommonValueInt(vEntity, "level required?");

		if (IsLegitimateClient(client) && (GetClientTeam(client) == TEAM_SURVIVOR || IsSurvivorBot(client)) && PlayerLevel[client] < AfxLevelReq) return false;

		//new Float:SourcLoc[3];
		//new Float:TargetPosition[3];
		//new t_Strength = 0;
		new Float:t_Range = 0.0;

		if (AfxRange > 0.0) t_Range = AfxRange * (PlayerLevel[client] - AfxLevelReq);
		else t_Range = AfxRangeMax;
		if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
		else t_Range += AfxRangeBase;

		if (IsAuraEffect && StrContains(TheAuras, EffectT, true) != -1 || !IsAuraEffect && StrContains(TheDeaths, EffectT, true) != -1) {

			GetEntPropVector(vEntity, Prop_Send, "m_vecOrigin", fEntPos);
			if (IsInRange(fEntPos, ClientPos, t_Range)) return true;
		}
	}
	else {

		new ent = -1;
		for (new i = 0; i < GetArraySize(Handle:CommonInfected); i++) {

			ent = GetArrayCell(Handle:CommonInfected, i);
			
			if (ent == client || !IsSpecialCommon(ent)) continue;
			if (vEntity >= 0 && ent != vEntity) continue;

			GetCommonValue(TheAuras, sizeof(TheAuras), ent, "aura effect?");
			GetCommonValue(TheDeaths, sizeof(TheDeaths), ent, "death effect?");

			/*

				At a certain level, like a lower one, it's just too much having to deal with auras, so some players will absolutely be oblivious to the shit
				going on and killing other players who CAN see them.
			*/
			if (IsLegitimateClient(client) && PlayerLevel[client] < GetCommonValueInt(ent, "level required?")) return false;

			if (IsAuraEffect && StrContains(TheAuras, EffectT, true) != -1 || !IsAuraEffect && StrContains(TheDeaths, EffectT, true) != -1) {

				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fEntPos);
				if (IsInRange(fEntPos, ClientPos, GetCommonValueFloat(ent, "range max?"))) return true;
			} 
		}
	}
	return false;
}

/*

	This timer runs 100 times / second. =)
	Overseer of the Common Affixes Program or CAP.
*/

public Action:Timer_CommonAffixes(Handle:timer) {

	if (!b_IsActiveRound) {

		for (new i = 1; i <= MaxClients; i++) {

			ClearArray(CommonAffixesCooldown[i]);
			ClearArray(SpecialCommon[i]);
		}
		ResetArray(Handle:CommonInfected);
		ResetArray(Handle:WitchList);
		ResetArray(Handle:CommonList);
		ResetArray(Handle:CommonAffixes);
		return Plugin_Stop;
	}
	static ent = -1;
	static IsCommonAffixesEnabled = -2;
	if (IsCommonAffixesEnabled == -2) IsCommonAffixesEnabled = iCommonAffixes;
	if (IsCommonAffixesEnabled < 1) return Plugin_Continue;
	for (new zombie = 0; zombie < GetArraySize(Handle:CommonInfected); zombie++) {

		ent = GetArrayCell(Handle:CommonInfected, zombie);
		if (IsSpecialCommon(ent)) {

			DrawCommonAffixes(ent);
		}
	}
	// tanks with cloned abilities
	/*for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_INFECTED || FindZombieClass(i) != ZOMBIECLASS_TANK) continue;
		if (bIsDefenderTank[i]) {

			// draw defender tank rings
			DrawCommonAffixes(i, "t");	// second argument forces it to clone the effects of this specific common affix
		}
	}*/
	
	return Plugin_Continue;
}

stock GetCommonValue(String:TheString[], TheSize, entity, String:Key[]) {

	decl String:SectionName[64];
	decl String:AffixName[2][64];
	new ent = -1;

	new size = GetArraySize(CommonAffixes);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:CommonAffixes, i, SectionName, sizeof(SectionName));
		ent = FindEntityInString(SectionName);
		if (!IsValidEntity(ent)) {

			RemoveFromArray(Handle:CommonAffixes, i);
			size--;
			continue;
		}
		if (entity != ent) continue;	// searching for a specific entity.

		Format(AffixName[0], sizeof(AffixName[]), "%s", SectionName);
		ExplodeString(AffixName[0], ":", AffixName, 2, 64);

		ent = FindListPositionBySearchKey(AffixName[0], a_CommonAffixes, 2, DEBUG);
		if (ent < 0) LogMessage("[GetCommonValue] failed at FindListPositionBySearchKey(%s)", AffixName[0]);
		else {

			h_CommonKeys		= GetArrayCell(a_CommonAffixes, ent, 0);
			h_CommonValues		= GetArrayCell(a_CommonAffixes, ent, 1);
			FormatKeyValue(TheString, TheSize, h_CommonKeys, h_CommonValues, Key);
			return;
		}
	}
	Format(TheString, TheSize, "-1");
}

stock GetCommonValueInt(entity, String:Key[]) {

	decl String:SectionName[64];
	decl String:AffixName[2][64];
	new ent = -1;

	decl String:text[64];

	new size = GetArraySize(CommonAffixes);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:CommonAffixes, i, SectionName, sizeof(SectionName));
		ent = FindEntityInString(SectionName);
		if (!IsValidEntity(ent)) {

			RemoveFromArray(Handle:CommonAffixes, i);
			size--;
			continue;
		}
		if (entity != ent) continue;	// searching for a specific entity.

		Format(AffixName[0], sizeof(AffixName[]), "%s", SectionName);
		ExplodeString(AffixName[0], ":", AffixName, 2, 64);

		ent = FindListPositionBySearchKey(AffixName[0], a_CommonAffixes, 2, DEBUG);
		if (ent < 0) LogMessage("[GetCommonValue] failed at FindListPositionBySearchKey(%s)", AffixName[0]);
		else {

			h_CommonKeys		= GetArrayCell(a_CommonAffixes, ent, 0);
			h_CommonValues		= GetArrayCell(a_CommonAffixes, ent, 1);
			FormatKeyValue(text, sizeof(text), h_CommonKeys, h_CommonValues, Key);
			return StringToInt(text);
		}
	}
	return -1;
}

stock Float:GetCommonValueFloat(entity, String:Key[], String:Section_Name[] = "none") {	// can override the section

	decl String:SectionName[64];
	decl String:AffixName[2][64];
	new ent = -1;

	decl String:text[64];

	new size = GetArraySize(CommonAffixes);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:CommonAffixes, i, SectionName, sizeof(SectionName));
		ent = FindEntityInString(SectionName);
		if (!IsValidEntity(ent)) {

			RemoveFromArray(Handle:CommonAffixes, i);
			size--;
			continue;
		}
		if (entity != ent) continue;	// searching for a specific entity.

		Format(AffixName[0], sizeof(AffixName[]), "%s", SectionName);
		ExplodeString(AffixName[0], ":", AffixName, 2, 64);

		ent = FindListPositionBySearchKey(AffixName[0], a_CommonAffixes, 2, DEBUG);
		if (ent < 0) LogMessage("[GetCommonValue] failed at FindListPositionBySearchKey(%s)", AffixName[0]);
		else {

			h_CommonKeys		= GetArrayCell(a_CommonAffixes, ent, 0);
			h_CommonValues		= GetArrayCell(a_CommonAffixes, ent, 1);
			FormatKeyValue(text, sizeof(text), h_CommonKeys, h_CommonValues, Key);
			return StringToFloat(text);
		}
	}
	return -1.0;
}

stock bool:IsInRange(Float:EntitLoc[3], Float:TargetLo[3], Float:AllowsMaxRange, Float:ModeSize = 1.0) {

	//new Float:ModelSize = 48.0 * ModeSize;
	
	if (GetVectorDistance(EntitLoc, TargetLo) <= (AllowsMaxRange / 2)) return true;
	return false;
}

stock DrawCommonAffixes(entity, String:sForceAuraEffect[] = "none") {

	decl String:AfxEffect[64];
	decl String:AfxDrawColour[64];
	new Float:AfxRange = -1.0;
	new Float:AfxRangeMax = -1.0;
	decl String:AfxDrawPos[64];
	new AfxDrawType = -1;

	new Float:EntityPos[3];
	new Float:TargetPos[3];
	if (!IsValidEntity(entity) || !IsSpecialCommon(entity)) return;

	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", EntityPos);

	//GetCommonValue(CommonEntityEffect, sizeof(CommonEntityEffect), entity, "death effect?");

	new Float:ModelSize = GetCommonValueFloat(entity, "model size?");
	new Float:AfxRangeBase = -1.0;

	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", ModelSize);

	GetCommonValue(AfxEffect, sizeof(AfxEffect), entity, "aura effect?");
	AfxRange		= GetCommonValueFloat(entity, "range player level?");
	AfxRangeMax		= GetCommonValueFloat(entity, "range max?");
	AfxDrawType		= GetCommonValueInt(entity, "draw type?");
	if (AfxDrawType == -1) return;
	AfxRangeBase	= GetCommonValueFloat(entity, "range minimum?");

	new AfxLevelReq = GetCommonValueInt(entity, "level required?");



	//AfxRange += AfxRangeBase;

	GetCommonValue(AfxDrawColour, sizeof(AfxDrawColour), entity, "draw colour?");
	GetCommonValue(AfxDrawPos, sizeof(AfxDrawPos), entity, "draw pos?");
	if (StrEqual(AfxDrawColour, "-1", false)) return;		// if there's no colour, we return otherwise you'll get errors like this: TE_Send Exception reported: No TempEntity call is in progress

	new Float:t_Range = -1.0;

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;
		if ((GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i)) && PlayerLevel[i] < AfxLevelReq) continue;

		if (AfxRange > 0.0) t_Range = AfxRange * (PlayerLevel[i] - AfxLevelReq);
		else t_Range = AfxRangeMax;
		if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
		else t_Range += AfxRangeBase;

		if (AfxDrawType == 0) CreateRingSolo(entity, t_Range, AfxDrawColour, AfxDrawPos, false, 0.25, i);
		else if (AfxDrawType == 1) {

			for (new y = 1; y <= MaxClients; y++) {

				if (!IsLegitimateClient(y) || IsFakeClient(y) || GetClientTeam(y) != TEAM_SURVIVOR) continue;
				GetClientAbsOrigin(y, TargetPos);
				// Player is outside the applicable range.
				if (!IsInRange(EntityPos, TargetPos, t_Range, ModelSize)) continue;

				CreateLineSolo(entity, y, AfxDrawColour, AfxDrawPos, 0.25, i);	// the last arg makes sure the line is drawn only for the player, otherwise it is drawn for all players, and that is bad as we are looping all players here already.
			}
		}
		t_Range = 0.0;
	}

	

	//Now we execute the effects, after all players have clearly seen them.

	new t_Strength			= 0;
	new AfxStrength			= GetCommonValueInt(entity, "aura strength?");
	new AfxMultiplication	= GetCommonValueInt(entity, "enemy multiplication?");
	new Float:AfxStrengthLevel = GetCommonValueFloat(entity, "level strength?");
	
	if (AfxMultiplication == 1) t_Strength = AfxStrength * LivingEntitiesInRange(entity, EntityPos, t_Range);
	else t_Strength = AfxStrength;

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR || PlayerLevel[i] < AfxLevelReq) continue;
		GetClientAbsOrigin(i, TargetPos);

		if (AfxRange > 0.0) t_Range = AfxRange * (PlayerLevel[i] - AfxLevelReq);
		else t_Range = AfxRangeMax;
		if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
		else t_Range += AfxRangeBase;

		// Player is outside the applicable range.
		if (!IsInRange(EntityPos, TargetPos, t_Range, ModelSize)) continue;

		if (AfxStrengthLevel > 0.0) t_Strength += RoundToCeil(t_Strength * (PlayerLevel[i] * AfxStrengthLevel));

		//If they are not immune to the effects, we consider the effects.
		
		if (StrContains(AfxEffect, "d", true) != -1) {

			//if (t_Strength > GetClientHealth(i)) IncapacitateOrKill(i);
			//else SetEntityHealth(i, GetClientHealth(i) - t_Strength);
			if (!IsSurvivorBot(i)) SetClientTotalHealth(i, t_Strength);
		}
		if (StrContains(AfxEffect, "l", true) != -1) {


			//	We don't want multiple blinders to spam blind a player who is already blind.
			//	Furthermore, we don't want it to accidentally blind a player AFTER it dies and leave them permablind.

			//	ISBLIND is tied a timer, and when the timer reverses the blind, it will close the handle.
			if (ISBLIND[i] == INVALID_HANDLE) BlindPlayer(i, 0.0, 255);
		}
		if (StrContains(AfxEffect, "r", true) != -1) {

			//

			//	Freeze players, teleport them up a lil bit.

			//
			if (ISFROZEN[i] == INVALID_HANDLE) FrozenPlayer(i, 0.0);
		}
	}
	new ent = -1;
	new pos = -1;
	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_INFECTED) continue;
		GetClientAbsOrigin(i, TargetPos);

		if (IsInRange(EntityPos, TargetPos, AfxRangeMax, ModelSize)) {

			if (StrContains(AfxEffect, "h", true) != -1) {

				for (new y = 1; y <= MaxClients; y++) {

					if (!IsLegitimateClient(y) || GetClientTeam(y) != TEAM_SURVIVOR) continue;
					pos = FindListPositionByEntity(entity, Handle:InfectedHealth[y]);
					if (pos < 0) continue;
					SetArrayCell(Handle:InfectedHealth[y], pos, GetArrayCell(Handle:InfectedHealth[y], pos, 1) + t_Strength, 1);
				}
			}
		}
	}
	for (new i = 0; i < GetArraySize(Handle:CommonInfected); i++) {

		ent = GetArrayCell(Handle:CommonInfected, i);		
		
		if (ent != entity && IsCommonInfected(ent)) {

			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TargetPos);
			if (IsInRange(EntityPos, TargetPos, AfxRangeMax, ModelSize)) {

				if (StrContains(AfxEffect, "h", true) != -1) {

					//

					//	We heal the entity.
					//
					//if (IsCommonInfected(ent)) {

					//	pos = FindListPositionByEntity(ent, Handle:CommonInfectedDamage);
					//	if (pos >= 0) SetArrayCell(Handle:CommonInfectedDamage, pos, GetArrayCell(Handle:CommonInfectedDamage, pos, 1) + t_Strength, 1);
					//}
					for (new ii = 1; ii <= MaxClients; ii++) {

						if (!IsLegitimateClient(ii) || GetClientTeam(ii) != TEAM_SURVIVOR) continue;
						if (IsSpecialCommon(ent)) {

							pos = FindListPositionByEntity(ent, Handle:SpecialCommon[ii]);
							if (pos < 0) continue;
							SetArrayCell(Handle:SpecialCommon[ii], pos, GetArrayCell(Handle:SpecialCommon[ii], pos, 1) + t_Strength, 1);
						}
						else if (IsCommonInfected(ent)) {

							pos = FindListPositionByEntity(ent, Handle:CommonInfectedDamage[ii]);
							if (pos < 0) continue;
							SetArrayCell(Handle:CommonInfectedDamage[ii], pos, GetArrayCell(Handle:CommonInfectedDamage[ii], pos, 1) + t_Strength, 1);
						}
					}
				}
			}
		}
	}
}

stock LivingEntitiesInRange(entity, Float:SourceLoc[3], Float:EffectRange) {

	new count = 0;
	new Float:Pos[3];
	new Float:ModelSize = 48.0 * GetEntPropFloat(entity, Prop_Send, "m_flModelScale");
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i)) {

			GetClientAbsOrigin(i, Pos);
			//if (SourceLoc[2] + ModelSize < Pos[2] ||
			//	SourceLoc[2] - ModelSize > Pos[2]) continue;
			if (!IsInRange(SourceLoc, Pos, EffectRange, ModelSize)) continue;
			count++;
		}
	}
	new ent = -1;
	for (new i = 0; i < GetArraySize(Handle:CommonInfected); i++) {

		ent = GetArrayCell(Handle:CommonInfected, i);
		if (IsCommonInfected(ent)) {

			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", Pos);
			if (!IsInRange(SourceLoc, Pos, EffectRange, ModelSize)) continue;
			count++;
		}
	}
	return count;
}

stock bool:IsAbilityCooldown(client, String:TalentName[]) {

	if (IsClientActual(client)) {

		new a_Size				=	0;
		//if (IsSurvivorBot(client) || !IsFakeClient(client) && (GetClientTeam(client) == TEAM_SURVIVOR || IsSurvivorBot(client)))
		a_Size					=	GetArraySize(a_Database_PlayerTalents[client]);
		//else a_Size											=	GetArraySize(a_Database_PlayerTalents_Bots);

		decl String:Name[PLATFORM_MAX_PATH];

		for (new i = 0; i < a_Size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {

				decl String:t_Cooldown[8];
				//if (IsSurvivorBot(client) || !IsFakeClient(client) && (GetClientTeam(client) == TEAM_SURVIVOR || IsSurvivorBot(client)))
				GetArrayString(Handle:PlayerAbilitiesCooldown[client], i, t_Cooldown, sizeof(t_Cooldown));
				//else GetArrayString(Handle:PlayerAbilitiesCooldown_Bots, i, t_Cooldown, sizeof(t_Cooldown));
				if (StrEqual(t_Cooldown, "1")) return true;
				break;
			}
		}
	}
	return false;
}

stock GetMenuPosition(client, String:TalentName[]) {

	if (IsClientActual(client)) {

		new size						=	GetArraySize(a_Menu_Talents);
		decl String:Name[PLATFORM_MAX_PATH];

		for (new i = 0; i < size; i++) {

			MenuPosition[client]				= GetArrayCell(a_Menu_Talents, i, 2);

			GetArrayString(Handle:MenuPosition[client], 0, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {

				return i;
			}
		}
	}
	return -1;
}


stock GetTalentPosition(client, String:TalentName[]) {

	new pos = 0;
	if (IsClientActual(client)) {

		new a_Size				=	0;
		//if (IsSurvivorBot(client) || !IsFakeClient(client) && GetClientTeam(client) == TEAM_SURVIVOR)
		a_Size					=	GetArraySize(a_Database_PlayerTalents[client]);
		//else a_Size											=	GetArraySize(a_Database_PlayerTalents_Bots);

		decl String:Name[PLATFORM_MAX_PATH];

		for (new i = 0; i < a_Size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {

				pos = i;
				break;
			}
		}
	}
	return pos;
}

stock RemoveImmunities(client) {

	// We remove all immunities when a round ends, otherwise they may not properly remove and then players become immune, forever.
	new size = 0;
	if (client == -1) {

		size = GetArraySize(PlayerAbilitiesCooldown_Bots);
		for (new i = 0; i < size; i++) {

			//SetArrayString(PlayerAbilitiesImmune_Bots, i, "0");
			SetArrayString(PlayerAbilitiesCooldown_Bots, i, "0");
		}
		for (new i = 1; i <= MAXPLAYERS; i++) {

			RemoveImmunities(i);
		}
	}
	else {

		size = GetArraySize(PlayerAbilitiesCooldown[client]);
		for (new i = 0; i < size; i++) {

			//SetArrayString(PlayerAbilitiesImmune[client], i, "0");
			SetArrayString(PlayerAbilitiesCooldown[client], i, "0");
		}
	}
}

/*stock CreateImmune(activator, client, pos, Float:f_Cooldown) {

	if (IsLegitimateClient(client)) {

		//if (!IsFakeClient(client)) SetArrayString(PlayerAbilitiesImmune[client], pos, "1");
		//else SetArrayString(PlayerAbilitiesImmune_Bots, pos, "1");
		SetArrayString(PlayerAbilitiesImmune[client][activator], pos, "1");

		new Handle:packy;
		CreateDataTimer(f_Cooldown, Timer_RemoveImmune, packy, TIMER_FLAG_NO_MAPCHANGE);
		if (IsFakeClient(client)) client = -1;
		WritePackCell(packy, client);
		WritePackCell(packy, pos);
		WritePackCell(packy, activator);
	}
}*/

// GetTargetOnly is set to true only when casting single-target spells, which require an actual target.
stock GetClientAimTargetEx(client, String:TheText[], TheSize, bool:GetTargetOnly = false) {

	new Float:ClientEyeAngles[3];
	new Float:ClientEyePosition[3];
	new Float:ClientLookTarget[3];

	GetClientEyeAngles(client, ClientEyeAngles);
	GetClientEyePosition(client, ClientEyePosition);

	new Handle:trace = TR_TraceRayFilterEx(ClientEyePosition, ClientEyeAngles, MASK_SHOT, RayType_Infinite, TraceRayIgnoreSelf, client);

	if (TR_DidHit(trace)) {

		new Target = TR_GetEntityIndex(trace);
		if (GetTargetOnly) {

			if (IsLegitimateClientAlive(Target)) Format(TheText, TheSize, "%d", Target);
			else Format(TheText, TheSize, "-1");
		}
		else {

			TR_GetEndPosition(ClientLookTarget, trace);
			Format(TheText, TheSize, "%3.3f %3.3f %3.3f", ClientLookTarget[0], ClientLookTarget[1], ClientLookTarget[2]);
		}
	}
	CloseHandle(trace);
}

public bool:TraceRayIgnoreSelf(entity, mask, any:client) {
	
	if (entity < 1 || entity == client) return false;
	return true;
}

public Action:Timer_AmmoActiveTimer(Handle:timer) {

	if (!b_IsActiveRound) {

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i)) {

				ClearArray(PlayerActiveAmmo[i]);
				ClearArray(PlayActiveAbilities[i]);
			}
		}

		return Plugin_Stop;
	}

	SortThreatMeter();
	//new size = 0;
	static String:result[2][64];
	//new currSize = -1;
	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i)) continue;
		if (bJumpTime[i]) JumpTime[i] += 0.2;
		if (fOnFireDebuff[i] > 0.0) {

			fOnFireDebuff[i] -= 0.2;
			if (fOnFireDebuff[i] <= 0.0) fOnFireDebuff[i] = -1.0;
		}

		if (!IsFakeClient(i)) {

			if (!bIsHideThreat[i]) SendPanelToClientAndClose(ShowThreatMenu(i), i, ShowThreatMenu_Init, 1); //ShowThreatMenu(i);
			else if (IsPlayerAlive(i) && DisplayActionBar[i]) ShowActionBar(i);
		}
		
		// timer for the cooldowns of anything on the action bar (ammos, abilities)
		//currSize = GetArraySize(PlayerActiveAmmo[i]);
		if (GetArraySize(PlayerActiveAmmo[i]) > 0) {

			for (new ii = 0; ii < GetArraySize(PlayerActiveAmmo[i]); ii++) {

				GetArrayString(PlayerActiveAmmo[i], ii, result[0], sizeof(result[]));
				ExplodeString(result[0], ":", result, 2, 64);
				if (StringToFloat(result[1]) - 0.2 <= 0.0) {

					RemoveFromArray(PlayerActiveAmmo[i], ii);
					//if (ii > 0) ii--;
					//size = GetArraySize(PlayerActiveAmmo[i]);
					continue;
				}
				Format(result[0], sizeof(result[]), "%s:%3.3f", result[0], StringToFloat(result[1]) - 0.2);
				SetArrayString(Handle:PlayerActiveAmmo[i], ii, result[0]);
			}
		}
		//currSize = GetArraySize(PlayActiveAbilities[i]);
		if (GetArraySize(PlayActiveAbilities[i]) > 0) {

			for (new ii = 0; ii < GetArraySize(PlayActiveAbilities[i]); ii++) {

				GetArrayString(PlayActiveAbilities[i], ii, result[0], sizeof(result[]));
				ExplodeString(result[0], ":", result, 2, 64);
				if (StringToFloat(result[1]) - 0.2 <= 0.0) RemoveFromArray(PlayActiveAbilities[i], ii);
				else {

					Format(result[0], sizeof(result[]), "%s:%3.3f", result[0], StringToFloat(result[1]) - 0.2);
					SetArrayString(Handle:PlayActiveAbilities[i], ii, result[0]);
				}
			}
		}
	}
	return Plugin_Continue;
}

stock CheckActiveAmmoCooldown(client, String:TalentName[], bool:bIsCreateCooldown=false) {

	/*

		The original function is below. Rewritten after adding new functionality to function as originally intended.
	*/
	if (!IsLegitimateClient(client)) return -1;
	if (IsAmmoActive(client, TalentName)) return 2;	// even if bIsCreateCooldown, if it is on cooldown already, we don't create another cooldown.
	else if (bIsCreateCooldown) IsAmmoActive(client, TalentName, GetSpecialAmmoStrength(client, TalentName, 1));
	else return 1;
	return 0;
}

stock bool:IsAmmoActive(client, String:TalentName[], Float:f_Delay=0.0, bool:IsActiveAbility = false) {

	//Push to an array.
	decl String:result[2][64];
	if (f_Delay == 0.0) {

		new size = GetArraySize(PlayerActiveAmmo[client]);
		if (IsActiveAbility) size = GetArraySize(PlayActiveAbilities[client]);
		for (new i = 0; i < size; i++) {

			if (!IsActiveAbility) {

				GetArrayString(PlayerActiveAmmo[client], i, result[0], sizeof(result[]));
			}
			else {

				GetArrayString(PlayActiveAbilities[client], i, result[0], sizeof(result[]));
			}
			ExplodeString(result[0], ":", result, 2, 64);
			if (StrEqual(result[0], TalentName, false)) return true;

		}
		return false;
	}
	else {

		Format(result[0], sizeof(result[]), "%s:%3.2f", TalentName, f_Delay);
		if (!IsActiveAbility) {

			PushArrayString(PlayerActiveAmmo[client], result[0]);
		}
		else {

			PushArrayString(PlayActiveAbilities[client], result[0]);
		}
	}
	return false;
}

stock Float:GetAmmoCooldownTime(client, String:TalentName[], bool:IsActiveTimeInstead = false) {

	//Push to an array.
	decl String:result[2][64];
	new size = GetArraySize(PlayerActiveAmmo[client]);
	if (IsActiveTimeInstead) size = GetArraySize(PlayActiveAbilities[client]);
	for (new i = 0; i < size; i++) {

		if (!IsActiveTimeInstead) GetArrayString(PlayerActiveAmmo[client], i, result[0], sizeof(result[]));
		else GetArrayString(PlayActiveAbilities[client], i, result[0], sizeof(result[]));

		ExplodeString(result[0], ":", result, 2, 64);
		if (StrEqual(result[0], TalentName, false)) return StringToFloat(result[1]);
	}
	return -1.0;
}

stock Float:GetAbilityValue(client, String:TalentName[], String:TheKey[]) {

	decl String:TheTalent[64];

	new size = GetArraySize(a_Menu_Talents);
	for (new i = 0; i < size; i++) {

		AbilityConfigKeys[client]		= GetArrayCell(a_Menu_Talents, i, 0);
		AbilityConfigValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);
		AbilityConfigSection[client]	= GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(Handle:AbilityConfigSection[client], 0, TheTalent, sizeof(TheTalent));
		if (!StrEqual(TheTalent, TalentName)) continue;
		return (GetKeyValueFloat(AbilityConfigKeys[client], AbilityConfigValues[client], TheKey) * 1.0);
	}
	return -1.0;
}

stock bool:IsAbilityInstant(client, String:TalentName[]) {

	if (GetAbilityValue(client, TalentName, "active time?") > 0.0) return false;
	return true;
}

// by default this function does not handle instants, so we use an override to force it.
stock Float:GetAbilityMultiplier(client, ability, override = 0, String:TalentName_t[] = "none") { // we need the option to force certain results in the menus (1) active (2) passive

	//if (IsSurvivorBot(client)) return -1.0;

	decl String:TalentName[64];
	decl String:abilityT[4];
	decl String:effect[4];

	new Float:totalStrength = 0.0, Float:theStrength = 0.0;
	new bool:foundone = false;

	if (StrEqual(TalentName_t, "none")) Format(abilityT, sizeof(abilityT), "%c", ability);
	decl String:MyTeam[6], String:TheTeams[6];
	Format(MyTeam, sizeof(MyTeam), "%d", GetClientTeam(client));

	new size = GetArraySize(a_Menu_Talents);
	new Float:fCooldownRemaining = 0.0;
	for (new i = 0; i < size; i++) {

		GetAbilityKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
		GetAbilityValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);
		if (GetKeyValueInt(GetAbilityKeys[client], GetAbilityValues[client], "is ability?") != 1) continue;
		
		FormatKeyValue(TheTeams, sizeof(TheTeams), GetAbilityKeys[client], GetAbilityValues[client], "teams allowed?");
		if (StrContains(TheTeams, MyTeam) == -1) continue;

		GetAbilitySection[client]		= GetArrayCell(a_Menu_Talents, i, 2);
		
		GetArrayString(GetAbilitySection[client], 0, TalentName, sizeof(TalentName));

		if (StrEqual(TalentName_t, "none") && !IsAbilityEquipped(client, TalentName) ||
			!StrEqual(TalentName_t, "none") && !StrEqual(TalentName, TalentName_t)) continue;

		fCooldownRemaining = GetAmmoCooldownTime(client, TalentName, true);

		//if (override == 0 && GetAmmoCooldownTime(client, TalentName, true) != -1.0 || override == 1) {
		
		theStrength = GetKeyValueFloat(GetAbilityKeys[client], GetAbilityValues[client], "cooldown strength?");
		if (override == 4 || fCooldownRemaining > 0.0 && theStrength > 0.0) {

			if (!StrEqual(abilityT, effect)) continue;
			if (theStrength > 0.0) return theStrength;
		}
		if (override == 3) {

			if (!IsAbilityActive(client, TalentName)) return GetKeyValueFloat(GetAbilityKeys[client], GetAbilityValues[client], "maximum passive multiplier?");
			else return GetKeyValueFloat(GetAbilityKeys[client], GetAbilityValues[client], "maximum active multiplier?");
		}
		else if (override == 1 || IsAbilityActive(client, TalentName)) {

			if (StrEqual(TalentName_t, "none")) {

				FormatKeyValue(effect, sizeof(effect), GetAbilityKeys[client], GetAbilityValues[client], "active effect?");
				if (!StrEqual(abilityT, effect)) continue;
			}
			theStrength = GetKeyValueFloat(GetAbilityKeys[client], GetAbilityValues[client], "active strength?");
		}
		else if (override == 2 || GetAmmoCooldownTime(client, TalentName) == -1.0 || GetKeyValueInt(GetAbilityKeys[client], GetAbilityValues[client], "passive ignores cooldown?") == 1) {

			if (StrEqual(TalentName_t, "none")) {

				FormatKeyValue(effect, sizeof(effect), GetAbilityKeys[client], GetAbilityValues[client], "passive effect?");
				if (!StrEqual(abilityT, effect)) continue;
			}
			theStrength = GetKeyValueFloat(GetAbilityKeys[client], GetAbilityValues[client], "passive strength?");
		}
		else continue;	// If it's not active, or it's on cooldown, we ignore its value.
		
		if (override == 4) {

			totalStrength += ((1.0 - totalStrength) * theStrength);
		} 
		else totalStrength += theStrength;
		foundone = true;
	}
	if (!foundone) totalStrength = -1.0;
	return totalStrength;
}

stock bool:IsAbilityEquipped(client, String:TalentName[]) {

	decl String:text[64];

	new size = iActionBarSlots;
	if (GetArraySize(Handle:ActionBar[client]) != size) ResizeArray(Handle:ActionBar[client], size);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:ActionBar[client], i, text, sizeof(text));
		if (!StrEqual(text, TalentName)) continue;
		if (VerifyActionBar(client, TalentName, i)) return true;
	}
	return false;
}

/*stock bool:IsAbilityActive(client, String:TalentName[], Float:thetime = 0.0) {

	decl String:result[2][64];
	if (thetime == 0.0) {

		new size = GetArraySize(PlayActiveAbilities[client][0]);
		for (new i = 0; i < size; i++) {

			GetArrayString(PlayActiveAbilities[client][2], i, result[0], sizeof(result[]));
			ExplodeString(result[0], ":", result, 2, 64);
			if (StrEqual(result[0], TalentName, false)) return true;

		}
		return false;
	}
	else {

		Format(result[0], sizeof(result[]), "%s:%3.2f", TalentName, thetime);
		PushArrayString(PlayActiveAbilities[client][2], result[0]);
	}
	return false;
}*/

stock bool:IsAbilityActive(client, String:TalentName[]) {

	new Float:fCooldownRemaining = GetAmmoCooldownTime(client, TalentName, true);
	new Float:fCooldown			 = GetAbilityValue(client, TalentName, "cooldown?");
	new Float:fActiveTime		 = GetAbilityValue(client, TalentName, "active time?");

	if (fCooldownRemaining != -1.0) {

		fActiveTime				 = fActiveTime - (fActiveTime - fCooldownRemaining);
		if (fActiveTime > 0.0) return true;
	}
	return false;
}

/*

	Return different types of results about the special ammo. 0, the default, returns its active time
	0	Ability Time
	1	Cooldown Time
	2	Stamina Cost
	3	Range
	4	Interval Time
	5	Effect Strength
*/
stock Float:GetSpecialAmmoStrength(client, String:TalentName[], resulttype=0, bool:bGetNextUpgrade=false, TalentStrengthOverride = 0) {

	new pos							=	GetMenuPosition(client, TalentName);
	if (pos == -1) return -1.0;		// no ammo is selected.
	new TheStrength = GetTalentStrength(client, TalentName);
	new Float:f_Str					=	TheStrength * 1.0;
	new Float:baseTalentStrength	= 0.0;
	new Float:i_FirstPoint			= 0.0;
	new Float:i_FirstPoint_Temp		= 0.0;
	//new Float:i_Time_Temp			= 0.0;
	new Float:i_Cooldown_Temp		= 0.0;
	//new Float:f_Min					= 0.0;
	new Float:i_EachPoint			= 0.0;
	new Float:i_EachPoint_Temp		= 0.0;
	new Float:i_CooldownStart		= 0.0;
	if (TalentStrengthOverride != 0) f_Str = TalentStrengthOverride * 1.0;
	else if (bGetNextUpgrade) f_Str++;		// We add 1 point if we're showing the next upgrade value.

	SpecialAmmoStrengthKeys[client]			= GetArrayCell(a_Menu_Talents, pos, 0);
	SpecialAmmoStrengthValues[client]		= GetArrayCell(a_Menu_Talents, pos, 1);

	new Cons = GetTalentStrength(client, "constitution");
	new Agil = GetTalentStrength(client, "agility");
	new Resi = GetTalentStrength(client, "resilience");
	new Tech = GetTalentStrength(client, "technique");
	new Endu = GetTalentStrength(client, "endurance");
	//new Luck = GetTalentStrength(client, "luck");

	new Float:f_StrEach = f_Str - 1;
	new Float:TheAbilityMultiplier = 0.0;


	if (resulttype == 5) return GetClassMultiplier(client, GetKeyValueFloat(SpecialAmmoStrengthKeys[client], SpecialAmmoStrengthValues[client], "effect strength?"), "amSTR");

	if (f_Str > 0.0) {

		if (resulttype == 0) {		// Ability Time

			i_FirstPoint		=	GetKeyValueFloat(SpecialAmmoStrengthKeys[client], SpecialAmmoStrengthValues[client], "active time first point?");
			i_FirstPoint_Temp	=	(i_FirstPoint * (ConsMult * Cons));	// Constitution increases the first point value of spells.
			i_FirstPoint		+= i_FirstPoint_Temp;


			
			i_EachPoint			=	(GetKeyValueFloat(SpecialAmmoStrengthKeys[client], SpecialAmmoStrengthValues[client], "active time per point?"));
			i_EachPoint			+=	(i_EachPoint * (EnduMult * Endu));
			if (i_EachPoint < 0.0) i_EachPoint = 0.0;

			i_EachPoint *= f_StrEach;

			f_Str			=	i_FirstPoint + i_EachPoint;
		}
		else if (resulttype == 1) {		// Cooldown Time

			i_CooldownStart			=	GetKeyValueFloat(SpecialAmmoStrengthKeys[client], SpecialAmmoStrengthValues[client], "cooldown start?");
			i_FirstPoint			=	GetKeyValueFloat(SpecialAmmoStrengthKeys[client], SpecialAmmoStrengthValues[client], "cooldown first point?");
			i_EachPoint				=	GetKeyValueFloat(SpecialAmmoStrengthKeys[client], SpecialAmmoStrengthValues[client], "cooldown per point?");

			i_EachPoint_Temp		=	(i_EachPoint * (ResiMult * Resi))
			i_EachPoint_Temp		-=	(i_EachPoint * (ConsMult * Cons));
			if (i_EachPoint_Temp > 0.0) i_EachPoint -= i_EachPoint_Temp;
			if (i_EachPoint < 0.0) i_EachPoint = 0.0;


			TheAbilityMultiplier = GetAbilityMultiplier(client, 'L');
			if (TheAbilityMultiplier != -1.0) {

				if (TheAbilityMultiplier < 0.0) TheAbilityMultiplier = 0.1;
				else if (TheAbilityMultiplier > 0.0) { //cooldowns are reduced

					i_FirstPoint		*= TheAbilityMultiplier;
					i_EachPoint			*= TheAbilityMultiplier;
				}
			}

			i_EachPoint *= f_StrEach;

			f_Str			=	i_FirstPoint + i_EachPoint;
			f_Str			+=	i_CooldownStart;
			f_Str = GetClassMultiplier(client, f_Str, "amCD");
		}
		else if (resulttype == 2) {		// Stamina Cost

			i_FirstPoint						=	GetKeyValueInt(SpecialAmmoStrengthKeys[client], SpecialAmmoStrengthValues[client], "base stamina required?") * 1.0;
			i_FirstPoint_Temp					=	(i_FirstPoint * (ConsMult * Cons));
			i_FirstPoint_Temp					-=	(i_FirstPoint * (EnduMult * Endu));
			if (i_FirstPoint_Temp > 0.0) i_FirstPoint += i_FirstPoint_Temp;
			baseTalentStrength = i_FirstPoint;

			i_EachPoint							=	GetKeyValueFloat(SpecialAmmoStrengthKeys[client], SpecialAmmoStrengthValues[client], "stamina per point?");
			i_EachPoint_Temp					=	(i_EachPoint * (ResiMult * Resi));
			i_EachPoint							-=	i_EachPoint_Temp;
			if (i_EachPoint < 0.0) i_EachPoint = 0.0;

			i_EachPoint *= f_StrEach;

			f_Str								=	i_FirstPoint + i_EachPoint;
			if (f_Str < baseTalentStrength) f_Str = baseTalentStrength;
			// we do class multiplier after because we want to allow classes to modify the restrictions
			f_Str = GetClassMultiplier(client, f_Str, "stam");
		}
		else if (resulttype == 3) {		// Range

			i_FirstPoint						=	GetKeyValueFloat(SpecialAmmoStrengthKeys[client], SpecialAmmoStrengthValues[client], "range first point value?");
			i_FirstPoint 						=	GetClassMultiplier(client, i_FirstPoint, "fprange");
			i_FirstPoint_Temp					=	(i_FirstPoint * (TechMult * Tech));
			i_FirstPoint						+=	i_FirstPoint_Temp;



			i_EachPoint							=	GetKeyValueFloat(SpecialAmmoStrengthKeys[client], SpecialAmmoStrengthValues[client], "range per point?");
			i_EachPoint							=	GetClassMultiplier(client, i_EachPoint, "eprange");
			i_EachPoint_Temp					=	(i_EachPoint * (EnduMult * Endu));
			i_EachPoint_Temp					-=	(i_EachPoint * (AgilMult * Agil));
			if (i_EachPoint_Temp > 0.0) i_EachPoint += i_EachPoint_Temp;

			i_EachPoint *= f_StrEach;

			f_Str			=	i_FirstPoint + i_EachPoint;
			f_Str			=	GetClassMultiplier(client, f_Str, "sprange");
		}
		else if (resulttype == 4) {		// Interval

			i_FirstPoint		=	GetKeyValueFloat(SpecialAmmoStrengthKeys[client], SpecialAmmoStrengthValues[client], "interval first point?");
			i_FirstPoint_Temp	=	(i_FirstPoint * (TechMult * Tech));
			i_FirstPoint		+=	i_FirstPoint_Temp;

			i_EachPoint			=	GetKeyValueFloat(SpecialAmmoStrengthKeys[client], SpecialAmmoStrengthValues[client], "interval per point?");
			i_EachPoint_Temp	=	(i_EachPoint * (AgilMult * Agil));
			i_EachPoint_Temp	-=	(i_EachPoint * (ResiMult * Resi));
			if (i_EachPoint_Temp > 0.0) i_EachPoint += i_EachPoint_Temp;

			i_EachPoint *= f_StrEach;
			f_Str			=	i_FirstPoint + i_EachPoint;
		}
	}
	//if (resulttype == 3) return (f_Str / 2);	// we always measure from the center-point.
	return f_Str;
}

/*stock CreateActiveTime(client, String:TalentName[], Float:f_Delay) {

	if (IsLegitimateClient(client)) {

		if (IsAmmoActive(client, TalentName)) return 2;	// we don't need to initiate the ammo's activation period if it's already active.
		IsAmmoActive(client, TalentName, f_Delay);
		return 1;
	}
	return 0;
}*/

public Action:Timer_RemoveCooldown(Handle:timer, Handle:packi) {

	ResetPack(packi);
	new client				=	ReadPackCell(packi);
	new pos					=	ReadPackCell(packi);
	decl String:StackType[64];
	ReadPackString(packi, StackType, sizeof(StackType));
	//new StackCount			=	ReadPackCell(packi);
	new target				=	ReadPackCell(packi);
	new Float:f_Cooldown	= ReadPackFloat(packi);


	if (StrEqual(StackType, "none", false)) {

		if (IsLegitimateClient(client)) {

		//if (client != -1 || (GetClientTeam(client) == TEAM_SURVIVOR || IsSurvivorBot(client))) {

			SetArrayString(PlayerAbilitiesCooldown[client], pos, "0");
		}
		//}
		/*else {

			SetArrayString(PlayerAbilitiesCooldown_Bots, pos, "0");
		}*/
	}
	else if (IsLegitimateClient(target)) {

		CleanseStack[client]--;		// again we will open this for more expansion later.

		CounterStack[target] -= f_Cooldown;
		if (CounterStack[target] <= 0.0) {

			MultiplierStack[target] = 0;
			Format(BuildingStack[target], sizeof(BuildingStack[]), "none");
		}
	}
	return Plugin_Stop;
}

stock CreateCooldown(client, pos, Float:f_Cooldown, String:StackType[] = "none", StackCount = 0, target = 0) {

	if (IsLegitimateClient(client)) {

		if (target == 0) target = client;

		if (GetArraySize(PlayerAbilitiesCooldown[client]) < pos) ResizeArray(PlayerAbilitiesCooldown[client], pos + 1);
		//if (GetClientTeam(client) == TEAM_SURVIVOR || IsSurvivorBot(client))
		SetArrayString(PlayerAbilitiesCooldown[client], pos, "1");
		//else SetArrayString(PlayerAbilitiesCooldown_Bots, pos, "1");

		new Handle:packi;
		CreateDataTimer(f_Cooldown, Timer_RemoveCooldown, packi, TIMER_FLAG_NO_MAPCHANGE);
		//if (IsFakeClient(client)) client = -1;
		WritePackCell(packi, client);
		WritePackCell(packi, pos);

		if (!StrEqual(StackType, "none", false)) {

			CounterStack[target] += f_Cooldown;		// we subtract this value when the datatimer executes and if it is <= 0.0 then we set the building stack type to none.

			if (!StrEqual(StackType, BuildingStack[target], false)) {

				MultiplierStack[target] = 0;	// if the cleanse removes a different effect, we reset the overdrive, but it is also refreshed.
				Format(BuildingStack[target], sizeof(BuildingStack[]), "%s", StackType);
				PrintToChat(target, "%T", "building stack change", target, orange, blue, StackType, orange, green, f_Cooldown, blue);
			}
		}
		// So we can let clients build special stacks.
		WritePackString(packi, StackType);
		//WritePackCell(packi, StackCount);
		WritePackCell(packi, target);
		WritePackFloat(packi, f_Cooldown);
	}
}

stock bool:HasAbilityPoints(client, String:TalentName[]) {

	if (IsLegitimateClientAlive(client)) {

		// Check if the player has any ability points in the specified ability

		new a_Size				=	0;
		//if (client != -1)
		a_Size		=	GetArraySize(a_Database_PlayerTalents[client]);
		//else a_Size						=	GetArraySize(a_Database_PlayerTalents_Bots);

		decl String:Name[PLATFORM_MAX_PATH];

		for (new i = 0; i < a_Size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {

				//if (client != -1)
				GetArrayString(Handle:a_Database_PlayerTalents[client], i, Name, sizeof(Name));
				//else GetArrayString(Handle:a_Database_PlayerTalents_Bots, i, Name, sizeof(Name));
				if (StringToInt(Name) > 0) return true;
			}
		}
	}
	return false;
}

/*stock AwardSkyPoints(client, amount) {

	decl String:thetext[64];
	GetConfigValue(thetext, sizeof(thetext), "donator package flag?");


	if (HasCommandAccess(client, thetext)) amount = RoundToCeil(amount * 2.0);
	SkyPoints[client] += amount;
	decl String:Name[64];
	GetClientName(client, Name, sizeof(Name));

	GetConfigValue(thetext, sizeof(thetext), "sky points menu name?");
	PrintToChatAll("%t", "Sky Points Award", green, amount, orange, thetext, white, green, Name, white);
}*/

stock String:GetTimePlayed(client) {

	decl String:text[64];
	new seconds				=	TimePlayed[client];
	new days				=	0;
	while (seconds >= 86400) {

		days++;
		seconds -= 86400;
	}
	new hours				=	0;
	while (seconds >= 3600) {

		hours++;
		seconds -= 3600;
	}
	new minutes				=	0;
	while (seconds >= 60) {

		minutes++;
		seconds -= 60;
	}
	decl String:Days_t[64];
	decl String:Hours_t[64];
	decl String:Minutes_t[64];
	decl String:Seconds_t[64];

	if (days > 0 && days < 10) Format(Days_t, sizeof(Days_t), "0%d", days);
	else if (days >= 10) Format(Days_t, sizeof(Days_t), "%d", days);
	else Format(Days_t, sizeof(Days_t), "0");
	if (hours > 0 && hours < 10) Format(Hours_t, sizeof(Hours_t), "0%d", hours);
	else if (hours >= 10) Format(Hours_t, sizeof(Hours_t), "%d", hours);
	else Format(Hours_t, sizeof(Hours_t), "0");
	if (minutes > 0 && minutes < 10) Format(Minutes_t, sizeof(Minutes_t), "0%d", minutes);
	else if (minutes >= 10) Format(Minutes_t, sizeof(Minutes_t), "%d", minutes);
	else Format(Minutes_t, sizeof(Minutes_t), "0");
	if (seconds > 0 && seconds < 10) Format(Seconds_t, sizeof(Seconds_t), "0%d", seconds);
	else if (seconds >= 10) Format(Seconds_t, sizeof(Seconds_t), "%d", seconds);
	else Format(Seconds_t, sizeof(Seconds_t), "0");

	Format(text, sizeof(text), "%T", "Time Played", client, Days_t, Hours_t, Minutes_t, Seconds_t);
	return text;
}

stock GetUpgradeExperienceCost(client, bool:b_IsLevelUp = false) {

	new experienceCost = 0;
	if (IsLegitimateClient(client)) {

		//if (client == -1) return RoundToCeil(CheckExperienceRequirement(-1) * ((PlayerLevelUpgrades_Bots + 1) * fUpgradeExpCost));
		
		//new Float:Multiplier		= (PlayerUpgradesTotal[client] * 1.0) / (MaximumPlayerUpgrades(client) * 1.0);
		if (fUpgradeExpCost < 1.0) experienceCost		= RoundToCeil(CheckExperienceRequirement(client) * ((UpgradesAwarded[client] + 1) * fUpgradeExpCost));
		else experienceCost = CheckExperienceRequirement(client);
		//experienceCost				= RoundToCeil(CheckExperienceRequirement(client) * Multiplier);
	}
	return experienceCost;
}

stock PrintToSurvivors(RPGMode, String:SurvivorName[], String:InfectedName[], SurvExp, Float:SurvPoints) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

			if (RPGMode == 1) PrintToChat(i, "%T", "Experience Earned Total Team Survivor", i, white, blue, white, orange, white, green, white, SurvivorName, InfectedName, SurvExp);
			else if (RPGMode == 2) PrintToChat(i, "%T", "Experience Points Earned Total Team Survivor", i, white, blue, white, orange, white, green, white, green, white, SurvivorName, InfectedName, SurvExp, SurvPoints);
		}
	}
}

stock PrintToInfected(RPGMode, String:SurvivorName[], String:InfectedName[], InfTotalExp, Float:InfTotalPoints) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED) {

			if (RPGMode == 1) PrintToChat(i, "%T", "Experience Earned Total Team", i, white, orange, white, green, white, InfectedName, InfTotalExp);
			else if (RPGMode == 2) PrintToChat(i, "%T", "Experience Points Earned Total Team", i, white, orange, white, green, white, green, white, InfectedName, InfTotalExp, InfTotalPoints);
		}
	}
}

stock ResetOtherData(client) {

	if (IsLegitimateClient(client)) {

		for (new i = 1; i <= MAXPLAYERS; i++) {

			DamageAward[client][i]		=	0;
			DamageAward[i][client]		=	0;
			CoveredInBile[client][i]	=	-1;
			CoveredInBile[i][client]	=	-1;
		}
	}
}

stock LivingInfected(bool:KillAll=false) {

	new countt = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_INFECTED && FindZombieClass(i) != ZOMBIECLASS_TANK) {

			if (KillAll) ForcePlayerSuicide(i);
			else countt++;
		}
	}
	return countt;
}

/*stock bool:SurvivorsHaveHandicap() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && HandicapLevel[i] != -1) return true;
	}
	return false;
}*/

stock LivingSurvivors() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i))) count++;
	}
	return count;
}

stock TotalSurvivors() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i))) count++;
	}
	return count;
}

stock TotalHumanSurvivors(ignore = -1) {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsSurvivorBot(i)) continue;
		if (ignore != -1 && i == ignore) continue;
		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) count++;
	}
	return count;
}

stock LivingHumanSurvivors() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsSurvivorBot(i)) continue;
		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) count++;
	}
	return count;
}

stock HumanPlayersInGame() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR) count++;
	}
	return count;
}

public Action:Cmd_ResetTPL(client, args) { PlayerLevelUpgrades[client] = 0; }
//public Action Cmd_ResetTPL(client, args) { PlayerLevelUpgrades[client] = 0; }

stock String:FormatDatabase() {
	
	decl String:text[PLATFORM_MAX_PATH];

	new a_Size			=	GetArraySize(MainKeys);
}

stock bool:StringExistsArray(String:Name[], Handle:array) {

	decl String:text[PLATFORM_MAX_PATH];

	new a_Size			=	GetArraySize(array);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:array, i, text, sizeof(text));

		if (StrEqual(Name, text)) return true;
	}

	return false;
}

stock String:AddCommasToString(value) 
{
	new String:buffer[128];
	new String:separator[1];
	separator = ",";
	buffer[0] = '\0'; 
	new divisor = 1000; 
	new offcut = 0;
	
	while (value >= 1000 || value <= -1000)
	{
		offcut = value % divisor;
		value = RoundToFloor(float(value) / float(divisor));
		Format(buffer, sizeof(buffer), "%s%03.d%s", separator, offcut, buffer); 
	}
	
	Format(buffer, sizeof(buffer), "%d%s", value, buffer);
	return buffer;
}

stock HandicapDifference(client, target) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(target)) {

		new clientLevel = 0;
		new targetLevel = 0;

		if (GetClientTeam(client) == TEAM_SURVIVOR || IsSurvivorBot(client)) clientLevel = PlayerLevel[client];
		else clientLevel = PlayerLevel_Bots;

		if (GetClientTeam(client) == TEAM_SURVIVOR || IsSurvivorBot(client)) targetLevel = PlayerLevel[target];
		else targetLevel = PlayerLevel_Bots;

		if (targetLevel < clientLevel) {
		
			new dif = clientLevel - targetLevel;
			new han = iHandicapLevelDifference;

			if (dif > han) return (dif - han);
		}
	}
	return 0;
}

/*stock EnforceServerTalentMaximum(client) {

	new Handle:MKeys = CreateArray(8);
	new Handle:MValues = CreateArray(8);
	new Handle:MSection = CreateArray(8);

	new TalentMaximum = 0;
	new PlayerTalentPoints = 0;

	decl String:TalentName[64];

	new size						=	GetArraySize(a_Menu_Talents);

	for (new i = 0; i < size; i++) {

		MKeys			= GetArrayCell(a_Menu_Talents, i, 0);
		MValues			= GetArrayCell(a_Menu_Talents, i, 1);
		MSection		= GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(Handle:MSection, 0, TalentName, sizeof(TalentName));

		TalentMaximum = StringToInt(GetKeyValue(MKeys, MValues, "maximum talent points allowed?"));

		PlayerTalentPoints = GetTalentStrength(client, TalentName);
		if (PlayerTalentPoints > TalentMaximum) {

		//

			The player was on a server with different talent settings; specifically,
			it's clear some talents allowed greater values. Since this server doesn't,
			we set them to the maximum, refund the extra points.
		//
			FreeUpgrades[client] += (PlayerTalentPoints - TalentMaximum);
			PlayerUpgradesTotal[client] -= (PlayerTalentPoints - TalentMaximum);
			AddTalentPoints(client, TalentName, TalentMaximum);
		}
	}
}*/

stock ReceiveCommonDamage(client, entity, playerDamageTaken) {

	/*new pos = -1;
	if (IsSpecialCommon(entity)) pos = FindListPositionByEntity(entity, Handle:CommonList);
	else if (IsCommonInfected(entity)) pos = FindListPositionByEntity(entity, Handle:CommonInfected);*/

	/*if (pos < 0) {

		OnCommonCreated(entity);
		pos = FindListPositionByEntity(entity, Handle:CommonInfected);
	}*/
	new Float:RatingReductionMult = GetClassMultiplier(client, -1.0, "D");
	if (RatingReductionMult == -1.0) RatingReductionMult = 1.0;
	RatingReductionMult = (1.0 / RatingReductionMult);
	playerDamageTaken = RoundToCeil(playerDamageTaken * RatingReductionMult);

	new my_pos = 0;
	if (IsSpecialCommon(entity)) {

		AddSpecialCommonDamage(client, entity, 0);
		my_pos = FindListPositionByEntity(entity, Handle:SpecialCommon[client]);
		if (my_pos >= 0) SetArrayCell(Handle:SpecialCommon[client], my_pos, GetArrayCell(Handle:SpecialCommon[client], my_pos, 3) + playerDamageTaken, 3);
	}
	else if (IsCommonInfected(entity)) {

		AddCommonInfectedDamage(client, entity, 0);
		my_pos = FindListPositionByEntity(entity, Handle:CommonInfectedDamage[client]);
		if (my_pos >= 0) SetArrayCell(Handle:CommonInfectedDamage[client], my_pos, GetArrayCell(Handle:CommonInfectedDamage[client], my_pos, 3) + playerDamageTaken, 3);
	}

}

stock ReceiveWitchDamage(client, entity, playerDamageTaken) {

	if (!IsWitch(entity)) {

		OnWitchCreated(entity, true);
		return;
	}
	new pos = FindListPositionByEntity(entity, Handle:WitchList);
	if (pos < 0) {

		OnWitchCreated(entity);
		pos = FindListPositionByEntity(entity, Handle:WitchList);
	}

	new Float:RatingReductionMult = GetClassMultiplier(client, -1.0, "D");
	if (RatingReductionMult == -1.0) RatingReductionMult = 1.0;
	RatingReductionMult = (1.0 / RatingReductionMult);
	playerDamageTaken = RoundToCeil(playerDamageTaken * RatingReductionMult);

	new my_size = GetArraySize(Handle:WitchDamage[client]);
	new my_pos = FindListPositionByEntity(entity, Handle:WitchDamage[client]);
	if (my_pos < 0) {

		new WitchHealth = iWitchHealthBase;
		WitchHealth += RoundToCeil(WitchHealth * (GetDifficultyRating(client) * fWitchHealthMult));

		ResizeArray(Handle:WitchDamage[client], my_size + 1);
		SetArrayCell(Handle:WitchDamage[client], my_size, entity, 0);
		SetArrayCell(Handle:WitchDamage[client], my_size, WitchHealth, 1);
		SetArrayCell(Handle:WitchDamage[client], my_size, 0, 2);
		SetArrayCell(Handle:WitchDamage[client], my_size, playerDamageTaken, 3);
		SetArrayCell(Handle:WitchDamage[client], my_size, 0, 4);
	}
	else {

		SetArrayCell(Handle:WitchDamage[client], my_pos, GetArrayCell(Handle:WitchDamage[client], my_pos, 3) + playerDamageTaken, 3);
	}
}

stock EntityStatusEffectDamage(client, damage) {

	/*

		This function rotates through the list of all players who have an initialized health pool with this entity.
		If they don't, it will create one.

		To simulate the illusion of the entity taking fire damage when players are not dealing damage to it, we instead
		remove the value from its total health pool. Everyone's CNT bars will rise, and the entity's E.HP bar will fall.
	*/
	new pos = -1;
	if (IsWitch(client)) pos = FindListPositionByEntity(client, Handle:WitchList);
	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;

		if (IsWitch(client) && pos >= 0) {

			AddWitchDamage(i, client, 0, true);	// If the player doesn't have the witch, it will be initialized for them.
			AddWitchDamage(i, client, damage * -1, true);		// After we verify initialization, we multiple damage by -1 so the function knows to remove health instead of add contribution.
		}
		else if (IsSpecialCommon(client)) {

			AddSpecialCommonDamage(i, client, 0, true);
			AddSpecialCommonDamage(i, client, damage * -1, true);
		}
		else if (IsCommonInfected(client)) {

			AddCommonInfectedDamage(i, client, 0, true);
			AddCommonInfectedDamage(i, client, damage * -1, true);
		}
	}
}

stock GetDifficultyRating(client, bool:JustBaseRating = false) {

	if (iTankRush == 1) RatingHandicap[client] = RatingPerLevel;
	new iRatingPerLevel = RatingPerLevel;
	if (iRatingPerLevel < RatingHandicap[client]) iRatingPerLevel = RatingHandicap[client];
	//iRatingPerLevel *= PlayerLevel[client];
	iRatingPerLevel *= CartelLevel(client);
	if (!JustBaseRating) return iRatingPerLevel + Rating[client];
	return iRatingPerLevel;
}

stock AddCommonInfectedDamage(client, entity, playerDamage, bool:IsStatusDamage = false, damagevariant = -1) {

	/*if (!IsCommonInfected(entity)) {

		OnCommonInfectedCreated(entity, true, client);
		return;
	}*/
	new damageTotal = -1;
	new healthTotal = -1;
	new pos		= FindListPositionByEntity(entity, Handle:CommonInfected);
	//if (pos < 0) OnCommonInfectedCreated(entity);

	if (pos < 0) {

		if (IsCommonInfected(entity)) return 2;
		return 1;
	}

	new my_size	= GetArraySize(Handle:CommonInfectedDamage[client]);
	new my_pos	= FindListPositionByEntity(entity, Handle:CommonInfectedDamage[client]);
	if (my_pos >= 0 && playerDamage <= -1) {

		// delete the mob.
		RemoveFromArray(Handle:CommonInfectedDamage[client], my_pos);
		if (playerDamage == -2) return 0;
		my_pos = -1;
	}
	if (my_pos < 0) {

		new CommonHealth = iCommonBaseHealth;
		new InfectedType = iBotLevelType;

		if (InfectedType == 1) CommonHealth += RoundToCeil(CommonHealth * (SurvivorLevels() * fCommonRaidHealthMult));
		else CommonHealth += RoundToCeil(CommonHealth * (GetDifficultyRating(client) * fCommonLevelHealthMult));

		ResizeArray(Handle:CommonInfectedDamage[client], my_size + 1);
		SetArrayCell(Handle:CommonInfectedDamage[client], my_size, entity, 0);
		SetArrayCell(Handle:CommonInfectedDamage[client], my_size, CommonHealth, 1);
		SetArrayCell(Handle:CommonInfectedDamage[client], my_size, 0, 2);
		SetArrayCell(Handle:CommonInfectedDamage[client], my_size, 0, 3);
		SetArrayCell(Handle:CommonInfectedDamage[client], my_size, 0, 4);
		my_pos = my_size;
	}
	if (IsSpecialCommonInRange(entity, 't')) return 1;
	if (playerDamage >= 0) {

		damageTotal = GetArrayCell(Handle:CommonInfectedDamage[client], my_pos, 2);
		healthTotal = GetArrayCell(Handle:CommonInfectedDamage[client], my_pos, 1);

		new TrueHealthRemaining = RoundToCeil((1.0 - CheckTeammateDamages(entity, client)) * healthTotal);	// in case other players have damaged the mob - we can't just assume the remaining health without comparing to other players.
		
		if (damageTotal < 0) damageTotal = 0;

		if (playerDamage > TrueHealthRemaining) playerDamage = TrueHealthRemaining;
		SetArrayCell(Handle:CommonInfectedDamage[client], my_pos, damageTotal + playerDamage, 2);
		CheckTeammateDamagesEx(client, entity, playerDamage);
		if (playerDamage > 0) {

			//if (damagevariant == 1) AddTalentExperience(client, "endurance", RoundToCeil(GetClassMultiplier(client, playerDamage * 1.0, "enX", true, true)));
			if (damagevariant == 1) AddTalentExperience(client, "endurance", playerDamage);
			else if (damagevariant == -1) {

				new bool:bIsMeleeAttack = IsMeleeAttacker(client);
				if (!bIsMeleeAttack) AddTalentExperience(client, "agility", playerDamage);
				else AddTalentExperience(client, "constitution", playerDamage);
			}
		}
	}
	else {

		/*

			When the witch is burning, or hexed (ie it is simply losing health) we come here instead.
			Negative values detract from the overall health instead of adding player contribution.
		*/
		damageTotal = GetArrayCell(Handle:CommonInfectedDamage[client], my_pos, 1);
		SetArrayCell(Handle:CommonInfectedDamage[client], my_pos, damageTotal + playerDamage, 1);
	}
	ThreatCalculator(client, playerDamage);
	if (playerDamage > 0 && CheckIfEntityShouldDie(entity, client, playerDamage, IsStatusDamage) == 1) {

		return (damageTotal + playerDamage);
	}
	return 1;
}

stock AddWitchDamage(client, entity, playerDamageToWitch, bool:IsStatusDamage = false, damagevariant = -1) {

	if (!IsWitch(entity)) {

		OnWitchCreated(entity, true);
		return 1;
	}
	if (IsSpecialCommonInRange(entity, 't')) return 1;

	new damageTotal = -1;
	new healthTotal = -1;
	new pos		= FindListPositionByEntity(entity, Handle:WitchList);
	if (pos < 0) return -1;
	if (client == -1) {

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClientAlive(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i))) {

				AddWitchDamage(i, entity, playerDamageToWitch, _, 2);	// 2 so we subtract from her health but don't reward any players.
			}
		}
		return 1;
	}

	new my_size	= GetArraySize(Handle:WitchDamage[client]);
	new my_pos	= FindListPositionByEntity(entity, Handle:WitchDamage[client]);
	if (my_pos < 0) {

		new WitchHealth = iWitchHealthBase;
		WitchHealth += RoundToCeil(WitchHealth * (GetDifficultyRating(client) * fWitchHealthMult));
		//WItchHealth += RoundToCeil(WitchHealth * fSurvivorHealthBonus);

		new theCount = LivingSurvivorCount();
		if (theCount >= iSurvivorModifierRequired) WitchHealth += RoundToCeil(WitchHealth * ((theCount - (iSurvivorModifierRequired - 1)) * fSurvivorHealthBonus));

		ResizeArray(Handle:WitchDamage[client], my_size + 1);
		SetArrayCell(Handle:WitchDamage[client], my_size, entity, 0);
		SetArrayCell(Handle:WitchDamage[client], my_size, WitchHealth, 1);
		SetArrayCell(Handle:WitchDamage[client], my_size, 0, 2);
		SetArrayCell(Handle:WitchDamage[client], my_size, 0, 3);
		SetArrayCell(Handle:WitchDamage[client], my_size, 0, 4);
		my_pos = my_size;
	}
	if (playerDamageToWitch >= 0) {

		healthTotal = GetArrayCell(Handle:WitchDamage[client], my_pos, 1);

		new TrueHealthRemaining = RoundToCeil((1.0 - CheckTeammateDamages(entity, client)) * healthTotal);	// in case other players have damaged the mob - we can't just assume the remaining health without comparing to other players.
		
		if (damagevariant != 2) {

			damageTotal = GetArrayCell(Handle:WitchDamage[client], my_pos, 2);

			if (damageTotal < 0) damageTotal = 0;
			//if (IsSpecialCommonInRange(entity, 't')) return 1;
			if (playerDamageToWitch > TrueHealthRemaining) playerDamageToWitch = TrueHealthRemaining;

			SetArrayCell(Handle:WitchDamage[client], my_pos, damageTotal + playerDamageToWitch, 2);
			if (playerDamageToWitch > 0) {

				//if (damagevariant == 1) AddTalentExperience(client, "endurance", RoundToCeil(GetClassMultiplier(client, playerDamageToWitch * 1.0, "enX", true, true)));
				if (damagevariant == 1) AddTalentExperience(client, "endurance", playerDamageToWitch);
				else if (damagevariant == -1) {

					new bool:bIsMeleeAttack = IsMeleeAttacker(client);
					if (!bIsMeleeAttack) AddTalentExperience(client, "agility", playerDamageToWitch);
					else AddTalentExperience(client, "constitution", playerDamageToWitch);
				}
			}
		}
		else SetArrayCell(Handle:WitchDamage[client], my_pos, healthTotal - playerDamageToWitch, 1);
	}
	else {

		/*

			When the witch is burning, or hexed (ie it is simply losing health) we come here instead.
			Negative values detract from the overall health instead of adding player contribution.
		*/
		damageTotal = GetArrayCell(Handle:WitchDamage[client], my_pos, 1);
		SetArrayCell(Handle:WitchDamage[client], my_pos, damageTotal + playerDamageToWitch, 1);
	}
	if (playerDamageToWitch > 0 && CheckIfEntityShouldDie(entity, client, playerDamageToWitch, IsStatusDamage) == 1) {

		return (damageTotal + playerDamageToWitch);
	}
	return 1;
}

stock CheckIfEntityShouldDie(victim, attacker, damage = 0, bool:IsStatusDamage = false) {

	if (CheckTeammateDamages(victim, attacker) >= 1.0 ||
		CheckTeammateDamages(victim, attacker, true) >= 1.0) {

		if (IsWitch(victim)) OnWitchCreated(victim, true);
		else if (IsSpecialCommon(victim)) {

			ClearSpecialCommon(victim, _, damage, attacker);
			return 1;
		}
		else if (IsCommonInfected(victim)) {

			OnCommonInfectedCreated(victim, true, attacker);
		}
		else return 1;
		if (IsStatusDamage) {

			IgniteEntity(victim, 1.0);
		}
		else return 1;
	}
	else {

		/*

			So the player / common took damage.
		*/
		if (IsSpecialCommon(victim)) {

			decl String:AuraEffs[10];
			GetCommonValue(AuraEffs, sizeof(AuraEffs), victim, "aura effect?");

			// The bomber explosion initially targets itself so that the chain-reaction (if enabled) doesn't go indefinitely.
			if (StrContains(AuraEffs, "f", true) != -1) {

				//CreateDamageStatusEffect(victim);		// 0 is the default, which is fire.
				//CreateExplosion(attacker);
				CreateDamageStatusEffect(victim, _, attacker, damage);
			}
		}
	}
	return 0;
}

/*

	This function removes a dying (or dead) common infected from all client cooldown arrays.
*/
stock RemoveCommonAffixes(entity) {

	new size = GetArraySize(Handle:CommonAffixes);

	decl String:EntityId[64];
	decl String:SectionName[64];
	Format(EntityId, sizeof(EntityId), "%d", entity);

	for (new i = 0; i < size; i++) {

		//CASection			= GetArrayCell(CommonAffixes, i, 2);
		//if (GetArraySize(CASection) < 1) continue;
		GetArrayString(Handle:CommonAffixes, i, SectionName, sizeof(SectionName));
		if (StrContains(SectionName, EntityId, false) == -1) continue;
		RemoveFromArray(Handle:CommonAffixes, i);
		break;
	}
	for (new i = 1; i <= MaxClients; i++) {

		size = GetArraySize(CommonAffixesCooldown[i]);
		for (new y = 0; y < size; y++) {

			RCAffixes[i]			= GetArrayCell(CommonAffixesCooldown[i], y, 2);
			GetArrayString(Handle:RCAffixes[i], 0, SectionName, sizeof(SectionName));
			if (StrContains(SectionName, EntityId, false) == -1) continue;
			RemoveFromArray(Handle:CommonAffixesCooldown[i], y);
			break;
		}
	}
}

stock OnCommonCreated(entity, bool:bIsDestroyed = false) {

	//decl String:EntityId[64];
	//Format(EntityId, sizeof(EntityId), "%d", entity);

	if (!bIsDestroyed) PushArrayCell(Handle:CommonList, entity);
	else if (IsSpecialCommon(entity)) ClearSpecialCommon(entity);
}

stock FindInfectedClient(bool:GetClient=false) {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_INFECTED) {

			if (GetClient) return i;
			count++;
		}
	}
	return count;
}

stock GetExplosionDamage(target, damage, survivor) {

	if (StrContains(ActiveClass[survivor], "blaster", false) != -1) {

		new TheStrength = GetTalentStrength(survivor, "explosive ammo");

		if (TheStrength > 0) {	// when a healers health regen tics, it heals all teammates nearby, too.

			new Float:explosionrange = GetSpecialAmmoStrength(survivor, "explosive ammo", 3) * 2.0;
			new Float:TargetPos[3];
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", TargetPos);
			TheStrength = LivingEntitiesInRange(target, TargetPos, explosionrange);
			if (TheStrength > 0) return (damage / TheStrength);
		}
	}
	return 0;
}

stock ClearSpecialCommon(entity, bool:IsCommonEntity = true, playerDamage = 0, lastAttacker = -1) {

	if (CommonList == INVALID_HANDLE) return;

	decl String:TheDraws[64];
	decl String:ThePos[64];

	new pos = FindListPositionByEntity(entity, Handle:CommonList);
	if (pos >= 0) {

		if (IsCommonEntity && IsSpecialCommon(entity)) {

			decl String:CommonEntityEffect[55];
			GetCommonValue(CommonEntityEffect, sizeof(CommonEntityEffect), entity, "death effect?");
			if (IsLegitimateClientAlive(lastAttacker) && (GetClientTeam(lastAttacker) == TEAM_SURVIVOR || IsSurvivorBot(lastAttacker)) && StrContains(ActiveClass[lastAttacker], "firebug", false) != -1 || StrContains(CommonEntityEffect, "f", true) != -1) {

				if (IsLegitimateClientAlive(lastAttacker) && (GetClientTeam(lastAttacker) == TEAM_SURVIVOR || IsSurvivorBot(lastAttacker)) && StrContains(ActiveClass[lastAttacker], "firebug", false) != -1) CreateDamageStatusEffect(entity, _, _, playerDamage, lastAttacker, GetSpecialAmmoStrength(lastAttacker, "fire ammo", 3) * 2.0);
				else if (StrContains(CommonEntityEffect, "f", true) != -1) CreateDamageStatusEffect(entity);
			}
			if (IsLegitimateClientAlive(lastAttacker) && (GetClientTeam(lastAttacker) == TEAM_SURVIVOR || IsSurvivorBot(lastAttacker))) {

				if (StrContains(ActiveClass[lastAttacker], "blaster", false) != -1) CreateExplosion(entity, GetExplosionDamage(entity, playerDamage, lastAttacker), lastAttacker);
			}

			for (new y = 1; y <= MaxClients; y++) {

				if (!IsLegitimateClientAlive(y)) continue; // || GetClientTeam(y) != TEAM_SURVIVOR) continue;
				if (StrContains(CommonEntityEffect, "b", true) != -1 && IsSpecialCommonInRange(y, 'b', entity, false) && FindInfectedClient() > 0) {

					SDKCall(g_hCallVomitOnPlayer, y, FindInfectedClient(true), true);
					//IsCoveredInVomit(y, y);
					ISBILED[y] = true;
				}
				if (StrContains(CommonEntityEffect, "a", true) != -1 && IsSpecialCommonInRange(y, 'a', entity, false) && FindInfectedClient() > 0) {

					CreateAcid(FindInfectedClient(true), y, 48.0);
					break;
				}
				if (StrContains(CommonEntityEffect, "e", true) != -1 && IsSpecialCommonInRange(y, 'e', entity, false)) {	// false so we compare death effect instead of aura effect which defaults to true

					if (ISEXPLODE[y] == INVALID_HANDLE) {

						ISEXPLODETIME[y] = 0.0;
						new Handle:packagey;
						ISEXPLODE[y] = CreateDataTimer(GetCommonValueFloat(entity, "death interval?"), Timer_Explode, packagey, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						WritePackCell(packagey, y);
						WritePackCell(packagey, GetCommonValueInt(entity, "aura strength?"));
						WritePackFloat(packagey, GetCommonValueFloat(entity, "strength target?"));
						WritePackFloat(packagey, GetCommonValueFloat(entity, "level strength?"));
						WritePackFloat(packagey, GetCommonValueFloat(entity, "range max?"));
						WritePackFloat(packagey, GetCommonValueFloat(entity, "death multiplier?"));
						WritePackFloat(packagey, GetCommonValueFloat(entity, "death base time?"));
						WritePackFloat(packagey, GetCommonValueFloat(entity, "death interval?"));
						WritePackFloat(packagey, GetCommonValueFloat(entity, "death max time?"));
						GetCommonValue(TheDraws, sizeof(TheDraws), entity, "draw colour?");
						WritePackString(packagey, TheDraws);
						GetCommonValue(ThePos, sizeof(ThePos), entity, "draw pos?");
						WritePackString(packagey, ThePos);
						WritePackCell(packagey, GetCommonValueInt(entity, "level required?"));
					}
				}
				if (StrContains(CommonEntityEffect, "s", true) != -1 && IsSpecialCommonInRange(y, 's', entity, false)) {

					if (ISSLOW[y] == INVALID_HANDLE) {

						SetSpeedMultiplierBase(y, GetCommonValueFloat(entity, "death multiplier?"));
						SetEntityMoveType(y, MOVETYPE_WALK);
						ISSLOW[y] = CreateTimer(GetCommonValueFloat(entity, "death base time?"), Timer_Slow, y, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				if (StrContains(CommonEntityEffect, "f", true) != -1) {

					CreateDamageStatusEffect(entity, _, y, playerDamage);
					//if (FindZombieClass(y) == ZOMBIECLASS_TANK) ChangeTankState(y, "burn");
				}
			}

			CalculateInfectedDamageAward(entity, lastAttacker);
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		}
		if (pos < GetArraySize(Handle:CommonList)) RemoveFromArray(Handle:CommonList, pos);
		RemoveCommonAffixes(entity);
	}
	if (IsValidEntity(entity)) {

		AcceptEntityInput(entity, "Kill");
		//IgniteEntity(entity, 1.0);
	}
}

/*stock WipeAllCommons(bool:IsSpecialCommon = false) {

	new entity = -1;
	if (!IsSpecialCommon) {

		while (GetArraySize(Handle:CommonInfected) >= 1) {

			entity = GetArrayCell(Handle:CommonInfected, 0);
			//CalculateInfectedDamageAward(entity, 0);
			RemoveFromArray(Handle:CommonInfected, 0);
			if (IsValidEntity(entity)) {

				SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
	else {

		while (GetArraySize(Handle:CommonList) >= 1) {

			entity = GetArrayCell(Handle:CommonList, 0);
			RemoveFromArray(Handle:CommonList, 0);
			if (IsValidEntity(entity)) {

				SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
}*/

stock bool:IsCommonInfectedDead(entity) {

	if (FindListPositionByEntity(entity, Handle:CommonInfected) < 0) return true;
	return false;
}

stock OnCommonInfectedCreated(entity, bool:bIsDestroyed = false, finalkillclient=0, bool:IsIgnite = false) {

	if (CommonInfected == INVALID_HANDLE) return;
	if (!b_IsActiveRound) return;

	new pos = FindListPositionByEntity(entity, Handle:CommonInfected);
	//new ASize = GetArraySize(Handle:CommonInfected);

	if (!bIsDestroyed && pos < 0) {

		PushArrayCell(Handle:CommonInfected, entity);
		//ResizeArray(Handle:CommonInfected, ASize + 1);
		//SetArrayCell(Handle:CommonInfected, ASize, entity);

		/*for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i))) {

				AddCommonInfectedDamage(i, entity, 0);
			}
		}*/
	}
	else if (pos >= 0) {

		CalculateInfectedDamageAward(entity, finalkillclient);
		//SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		RemoveFromArray(Handle:CommonInfected, pos);
		if (IsIgnite) {

			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
			IgniteEntity(entity, 1.0);
		}
	}
}

/*

	Witches are created different than other infected.
	If we want to track them and then remove them when they die
	we need to write custom code for it.

	This function serves to manage, maintain, and remove dead witches
	from both the list of active witches as well as reward players who
	hurt them and then reset that said damage as well.
*/
stock OnWitchCreated(entity, bool:bIsDestroyed = false) {

	if (WitchList == INVALID_HANDLE) return;

	if (!bIsDestroyed) {

		/*

			When a new witch is created, we add them to the list, and then we
			make sure all survivor players lists are the same size.
		*/
		//LogMessage("[WITCH_LIST] Witch Created %d", entity);
		PushArrayCell(Handle:WitchList, entity);
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);

		//CreateMyHealthPool(entity);
	}
	else {

		/*

			When a Witch dies, we reward all players who did damage to the witch
			and then we remove the row of the witch id in both the witch list
			and in player lists.
		*/
		new pos = FindListPositionByEntity(entity, Handle:WitchList);
		if (pos < 0) {

			LogMessage("[WITCH_LIST] Could not find Witch by id %d", entity);
		}
		else {

			CalculateInfectedDamageAward(entity);
			//ogMessage("[WITCH_LIST] Witch %d Killed", entity);
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
			AcceptEntityInput(entity, "Kill");
			RemoveFromArray(Handle:WitchList, pos);		// Delete the witch. Forever.
		}
	}
}

stock FindEntityInString(String:SearchKey[], String:Delim[] = ":") {

	if (StrContains(SearchKey, Delim, false) == -1) return -1;
	decl String:tExploded[2][64];

	ExplodeString(SearchKey, Delim, tExploded, 2, 64);
	return StringToInt(tExploded[1]);
}

stock GetArraySizeEx(String:SearchKey[], String:Delim[] = ":") {

	new count = 0;
	for (new i = 0; i <= strlen(SearchKey); i++) {

		if (StrContains(SearchKey[i], Delim, false) != -1) count++;
	}
	if (count == 0) return -1;
	return count + 1;
}

stock FindDelim(String:EntityName[], String:Delim[] = ":") {

	decl String:DelimStr[2];

	for (new i = 0; i <= strlen(EntityName); i++) {

		Format(DelimStr, sizeof(DelimStr), "%s", EntityName[i]);
		if (StrContains(DelimStr, Delim, false) != -1) {

			// Found it!
			return i + 1;
		}
	}
	return -1;
}

stock GetDelimiterCount(String:TextCase[], String:Delimiter[]) {

	new count = 0;
	decl String:Delim[2];
	for (new i = 0; i <= strlen(TextCase); i++) {

		Format(Delim, sizeof(Delim), "%s", TextCase[i]);
		if (StrContains(Delim, Delimiter, false) != -1) count++;
	}
	return count;
}

stock FindListPositionBySearchKey(String:SearchKey[], Handle:h_SearchList, block = 0, bool:bDebug = false) {

	/*

		Some parts of rpg are formatted differently, so we need to check by entityname instead of id.
	*/
	decl String:SearchId[64];

	//new Handle:Section = CreateArray(8);

	new size = GetArraySize(Handle:h_SearchList);
	if (bDebug) {

		LogMessage("=== FindListPositionBySearchKey ===");
		LogMessage("Searchkey: %s", SearchKey);
	}
	for (new i = 0; i < size; i++) {

		//size = GetArraySize(Handle:h_SearchList);
		//if (i >= size) continue;

		SearchKey_Section						= GetArrayCell(h_SearchList, i, block);

		if (GetArraySize(SearchKey_Section) < 1) {

			//if (bDebug) LogMessage("Section header cannot be found for pos %d in the array", i);
			continue;
		}

		GetArrayString(Handle:SearchKey_Section, 0, SearchId, sizeof(SearchId));
		if (bDebug) {

			LogMessage("Section: %s", SearchId);
			LogMessage("Pos: %d", i);
			LogMessage("Size: %d", size);
		}
		if (StrEqual(SearchId, SearchKey, false)) {

			if (bDebug) {

				LogMessage("Searchkey Found!");
				LogMessage("===================================");
			}

			//ClearArray(Handle:Section);
			return i;
		}
		else if (bDebug) LogMessage("Wrong Searchkey (%s)", SearchId);
	}
	if (bDebug) {

		LogMessage("Searchkey not found :(");
		LogMessage("===================================");
	}
	//ClearArray(Handle:Section);
	return -1;
}

stock GetCommonAffixesPosByEntId(String:SearchKey[], bool:bDebug = false) {

	new size = GetArraySize(Handle:CommonAffixes);

	decl String:text[64];
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:CommonAffixes, i, text, sizeof(text));
		if (bDebug) LogMessage("CommonAffix text: %s (Searching for: %s)", text, SearchKey);
		if (StrContains(text, SearchKey, false) == -1) continue;
		return i;
	}
	return -1;
}

stock FindListPositionByEntity(entity, Handle:h_SearchList, block = 0) {

	new size = GetArraySize(Handle:h_SearchList);
	if (size < 1) return -1;
	for (new i = 0; i < size; i++) {

		if (GetArrayCell(Handle:h_SearchList, i, block) == entity) return i;
	}
	return -1;	// returns false
}

stock bool:SurvivorsSaferoomWaiting() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR && !IsFakeClient(i) && bIsInCheckpoint[i]) count++;
	}
	if (count >= LivingHumanSurvivors()) return true;
	return false;
}

stock SurvivorBotsRegroup(client) {

	if (IsLegitimateClient(client) && !IsFakeClient(client)) return;
	if (IsSurvivorBot(client)) {

		new Float:Origin[3];

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR && !IsFakeClient(i)) {

				GetClientAbsOrigin(i, Origin);
				TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
				return;
			}
		}
	}
}

stock PenalizeGroupmates(client) {

	//ew size = GetArraySize(Handle:MyGroup[client]);
	decl String:text[64];
	new jerk = 0;

	new Float:ThePenalty = 1.0 / GetArraySize(MyGroup[client]);

	while (GetArraySize(Handle:MyGroup[client]) > 0) {

		GetArrayString(MyGroup[client], 0, text, sizeof(text));
		jerk = FindClientWithAuthString(text, true);

		if (IsLegitimateClientAlive(jerk) && !IsFakeClient(jerk) && GetClientTeam(jerk) == TEAM_SURVIVOR) LogMessage("steamid: %s, size: %d", text, GetArraySize(MyGroup[client]));//ConfirmExperienceActionTalents(jerk, true, _, ThePenalty);
		RemoveFromArray(MyGroup[client], 0);
	}

	/*for (new i = 0; i < size; i++) {

		GetArrayString(MyGroup[client], i, text, sizeof(text));
		jerk = FindClientWithAuthString(text, true);

		if (IsLegitimateClientAlive(jerk) && !IsFakeClient(jerk) && GetClientTeam(jerk) == TEAM_SURVIVOR) {

			ConfirmExperienceActionTalents(jerk, true, _, ThePenalty);
		}
	}*/
	ClearArray(Handle:MyGroup[client]);
}

stock bool:IsSurvivorInAGroup(client) {

	if (IsFakeClient(client)) return false;	// we don't penalize players if bots die, so we always assume bots "aren't in a group" during this phase

	ClearArray(Handle:MyGroup[client]);
	// Checks if a player is in a group, right before they die.
	// While the dying player loses it all, group members will also lose a percentage of their XP, based on their group size.
	// Small groups have a larger split of the total XP, which means they also take a larger penalty when one of their members goes out.

	new Float:Origin[3];
	GetClientAbsOrigin(client, Origin);

	new Float:Pos[3];
	decl String:AuthID[64];
	for (new i = 1; i <= MaxClients; i++) {

		if (i == client || !IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR || IsFakeClient(i)) continue;
		GetClientAbsOrigin(i, Pos);
		if (GetVectorDistance(Origin, Pos) <= 1536.0 || IsPlayerRushing(i)) {	// rushers get treated like they're a member of everyone who dies group, so that they are punished every time someone dies.

			GetClientAuthString(i, AuthID, sizeof(AuthID));
			PushArrayString(MyGroup[client], AuthID);
			LogMessage("Size is now: %d added new steamid: %s of %N", GetArraySize(MyGroup[client]), AuthID, i);
		}
	}
	if (GetArraySize(MyGroup[client]) < iSurvivorGroupMinimum) return false;
	return true;
}

stock bool:IsPlayerRushing(client, Float:fDistance = 2048.0) {

	new TotalClients = LivingHumanSurvivors();
	new MyGroupSize = GroupSize(client);
	new LargestGroup = GroupSize();

	if (!AnyGroups() && MyGroupSize >= LargestGroup || TotalClients <= iSurvivorGroupMinimum || NearbySurvivors(client, fDistance, true, true) >= iSurvivorGroupMinimum) return false;
	return true;
}

stock Float:SurvivorRushingMultiplier(client, bool:IsForTankTeleport = false) {

	new SurvivorsCount	= LivingHumanSurvivors();
	if (SurvivorsCount <= iSurvivorGroupMinimum) return 1.0;	// no penalty if less players than group minimum exist.

	new SurvivorsNear	= NearbySurvivors(client, 1536.0, true, true);
	if (SurvivorsNear >= iSurvivorGroupMinimum) return 1.0; // If the player is in a group of players, they take no penalty.
	else if (IsForTankTeleport) return -2.0;					// If tanks are trying to find a player to teleport to, if this player isn't in a group, they are eligible targets.

	new Float:GetMultiplier = 1.0 / SurvivorsCount;
	GetMultiplier *= SurvivorsNear;
	return GetMultiplier;
}

stock bool:AnyGroups() {

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
		if (NearbySurvivors(i, 1536.0, true) >= iSurvivorGroupMinimum) return true;
	}
	return false;
}

stock GroupSize(client = 0) {

	if (client > 0) return NearbySurvivors(client, 1536.0, true);
	new largestGroup = 0;
	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (client == i || !IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
		count = NearbySurvivors(i, 1536.0, true);
		if (count > largestGroup) largestGroup = count;
	}
	return count;
}

stock NearbySurvivors(client, Float:range = 512.0, bool:Survivors = false, bool:IsRushing = false) {

	new Float:pos[3];
	if (IsLegitimateClientAlive(client)) GetClientAbsOrigin(client, pos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	new Float:spos[3];

	new count = 0;
	new TheTime = GetTime();

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR && i != client) {

			if (Survivors && IsSurvivorBot(i)) continue;
			if (IsRushing && (MyBirthday[i] == 0 || (TheTime - MyBirthday[i]) < 60 || NearbySurvivors(i, 1536.0, true) < iSurvivorGroupMinimum)) {

				// If a player has only been in the game a short time, or is not near enough survivors to be in a group, we consider them part of everyone's group.

				count++;
				continue;
			}

			GetClientAbsOrigin(i, spos);
			if (GetVectorDistance(pos, spos) <= range) count++;
		}
	}
	return count;
}

stock bool:SurvivorsInRange(client, Float:range = 512.0, bool:Survivors = false) {

	new Float:pos[3];
	if (IsLegitimateClientAlive(client)) GetClientAbsOrigin(client, pos);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	new Float:spos[3];

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR && i != client) {

			if (Survivors && IsSurvivorBot(i)) continue;

			GetClientAbsOrigin(i, spos);
			if (GetVectorDistance(pos, spos) <= range) return true;
		}
	}
	return false;
}

stock bool:AnyTanksNearby(client, Float:range = 0.0) {

	if (range == 0.0) range = TanksNearbyRange;

	new Float:pos[3];
	new Float:ipos[3];
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_INFECTED && FindZombieClass(i) == ZOMBIECLASS_TANK) {

			GetClientAbsOrigin(client, pos);
			GetClientAbsOrigin(i, ipos);
			if (GetVectorDistance(pos, ipos) <= range) return true;
		}
	}
	return false;
}

stock bool:IsVectorsCrossed(client, Float:torigin[3], Float:aorigin[3], Float:f_Distance) {

	new Float:porigin[3];
	new Float:vorigin[3];
	MakeVectorFromPoints(torigin, aorigin, vorigin);
	if (GetVectorDistance(porigin, vorigin) <= f_Distance) return true;
	return false;
}

/*public OnEntityDestroyed(entity) {

	if (!b_IsActiveRound) return;
	//new pos = FindListPositionByEntity(entity, Handle:CommonList);
	//if (pos >= 0) OnCommonCreated(entity, true);

	//if (IsCommonInfected(entity)) SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
}*/

/*stock DestroyCommons() {

	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE) {
	    
		AcceptEntityInput(entity, "Kill");
		//SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		//IgniteEntity(100.0);
	}
}*/

public Action:Timer_DestroyRock(Handle:timer, any:ent) {

	if (IsValidEntity(ent) && IsValidEdict(ent)) {

		decl String:classname[64];
		GetEntityClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "tank_rock", false)) {

			new Float:fTankPos[3], Float:fRockPos[3], tank = -1;
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fRockPos);
			for (new i = 1; i <= MaxClients; i++) {

				if (!IsLegitimateClientAlive(i) || GetClientTeam(i) != TEAM_INFECTED || FindZombieClass(i) != ZOMBIECLASS_TANK) continue;
				GetClientAbsOrigin(i, fTankPos);
				if (GetVectorDistance(fTankPos, fRockPos) >= 32.0) continue;

				tank = i;
				break;
			}
			if (!AcceptEntityInput(ent, "Kill")) LogMessage("Could not destroy rock.");
			if (tank != -1) {

				ChangeTankState(tank, "burn");
				FindRandomSurvivorClient(tank, true);
			}
		}
	}

	return Plugin_Stop;
}

public OnEntityCreated(entity, const String:classname[]) {

	//if (!b_IsActiveRound) return;
	if (iTankRush > 0 && StrEqual(classname, "tank_rock", false)) {

		if (IsValidEntity(entity) && IsValidEdict(entity)) {

			//new eOwner = GetEntProp(entity, Prop_Data, "m_hOwnerEntity");
			//PrintToChatAll("tank : %d", eOwner);
			//if (FindZombieClass(eOwner) == ZOMBIECLASS_TANK) PrintToChatAll("it is a tank!");
			//if (!AcceptEntityInput(entity, "Kill"))
			CreateTimer(1.4, Timer_DestroyRock, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
		return;
	}
	if (StrEqual(classname, "infected", false)) {

		if (!b_IsActiveRound) return;

		/*if (!b_IsActiveRound) return;
		if (iTankRush == 1 && !b_IsFinaleActive && !IsEnrageActive()) {

			new pos = FindListPositionByEntity(entity, Handle:CommonInfected);
			if (pos >= 0) RemoveFromArray(Handle:CommonInfected, pos);
			if (entity != INVALID_ENT_REFERENCE) {

				SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
				//AcceptEntityInput(entity, "Kill");
				IgniteEntity(entity, 100.0);
			}
			return;
		}*/
		OnCommonInfectedCreated(entity);	// ALL commons (including specials) get stored.

		/*if (GetArraySize(CommonInfectedQueue) > 0) {

			decl String:Model[64];
			GetArrayString(Handle:CommonInfectedQueue, 0, Model, sizeof(Model));
			if (IsModelPrecached(Model)) SetEntityModel(entity, Model);
			RemoveFromArray(Handle:CommonInfectedQueue, 0);
		}*/
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		if (iCommonAffixes == 1) CreateCommonAffix(entity);
		else if (GetArraySize(CommonInfectedQueue) > 0) {

			decl String:Model[64];
			GetArrayString(Handle:CommonInfectedQueue, 0, Model, sizeof(Model));
			if (IsModelPrecached(Model)) SetEntityModel(entity, Model);
			RemoveFromArray(Handle:CommonInfectedQueue, 0);
		}
	}
	else if (b_IsActiveRound && IsWitch(entity)) OnWitchCreated(entity);
}

bool:IsWitch(entity) {

	if (entity <= 0 || !IsValidEntity(entity)) return false;

	decl String:className[16];
	GetEntityClassname(entity, className, sizeof(className));
	return strcmp(className, "witch") == 0;
}

bool:IsCommonInfected(entity) {

	if (entity <= 0 || !IsValidEntity(entity)) return false;

	decl String:className[16];
	GetEntityClassname(entity, className, sizeof(className));
	return strcmp(className, "infected") == 0;
}

stock ExperienceBarBroadcast(client, String:sStatusEffects[]) {

	decl String:eBar[64];
	if (GetClientTeam(client) == TEAM_SURVIVOR) {

		ExperienceBar(client, eBar, sizeof(eBar));

		if (BroadcastType == 0) PrintHintText(client, "%T", "Hint Text Broadcast 0", client, eBar);
		if (BroadcastType == 1) PrintHintText(client, "%T", "Hint Text Broadcast 1", client, eBar, AddCommasToString(ExperienceLevel[client]), AddCommasToString(CheckExperienceRequirement(client)));
		if (BroadcastType == 2) PrintHintText(client, "%T", "Hint Text Broadcast 2", client, eBar, AddCommasToString(ExperienceLevel[client]), AddCommasToString(CheckExperienceRequirement(client)), Points[client]);
	}
	else if (GetClientTeam(client) == TEAM_INFECTED) {

		ExperienceBar(client, eBar, sizeof(eBar), 1);	// armor
		decl String:aBar[64];
		ExperienceBar(client, aBar, sizeof(aBar), 2);	// actual health
		new tHealth = GetArrayCell(InfectedHealth[client], 0, 5);	// total health
		new dHealth = GetArrayCell(InfectedHealth[client], 0, 6);	// damage to health

		PrintHintText(client, "%T", "Infected Health Broadcast", client, eBar, aBar, AddCommasToString(tHealth - dHealth), AddCommasToString(tHealth), sStatusEffects);
	}
}

stock CheckTankingDamage(infected, client) {

	new pos = -1;
	new cDamage = 0;

	if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) pos = FindListPositionByEntity(infected, Handle:InfectedHealth[client]);
	else if (IsWitch(infected)) pos = FindListPositionByEntity(infected, Handle:WitchDamage[client]);
	else if (IsSpecialCommon(infected)) pos = FindListPositionByEntity(infected, Handle:SpecialCommon[client]);
	else if (IsCommonInfected(infected)) pos = FindListPositionByEntity(infected, Handle:CommonInfectedDamage[client]);

	if (pos < 0) return 0;

	if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) cDamage = GetArrayCell(Handle:InfectedHealth[client], pos, 3);
	else if (IsWitch(infected)) cDamage = GetArrayCell(Handle:WitchDamage[client], pos, 3);
	else if (IsSpecialCommon(infected)) cDamage = GetArrayCell(Handle:SpecialCommon[client], pos, 3);
	else if (IsCommonInfected(infected)) cDamage = GetArrayCell(Handle:CommonInfectedDamage[client], pos, 3);
	
	/*

		If the player dealt more damage to the special than took damage from it, they do not receive tanking rewards.
	*/
	return cDamage;
}

/*stock CheckHealingAward(infected, client) {

	new pos = -1;
	if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) pos = FindListPositionByEntity(infected, Handle:InfectedHealth[client]);
	else if (IsWitch(infected)) pos = FindListPositionByEntity(infected, Handle:WitchDamage[client]);
	else if (IsSpecialCommon(infected)) pos = FindListPositionByEntity(infected, Handle:SpecialCommon[client]);
	else if (IsCommonInfected(infected)) pos = FindListPositionByEntity(infected, Handle:CommonInfectedDamage[client]);

	if (pos < 0) return 0;
	if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) return GetArrayCell(Handle:InfectedHealth[client], pos, 4);
	else if (IsWitch(infected)) return GetArrayCell(Handle:WitchDamage[client], pos, 4);
	else if (IsSpecialCommon(infected)) return GetArrayCell(Handle:SpecialCommon[client], pos, 4);
	else if (IsCommonInfected(infected)) return GetArrayCell(Handle:CommonInfectedDamage[client], pos, 4);
	return 0;
}*/

stock WipeDamageContribution(client) {

	/*

		This function will completely wipe out a players contribution and earnings.
		Use this when a player dies to essentially "give back" the health equal to contribution.
		Other players can then earn the contribution that is restored, albeit a mob that was about to die would
		suddenly gain a bunch of its life force back.
	*/
	if (IsLegitimateClient(client)) {

		ClearArray(Handle:InfectedHealth[client]);
		ClearArray(Handle:WitchDamage[client]);
		ClearArray(Handle:SpecialCommon[client]);
		ClearArray(Handle:CommonInfectedDamage[client]);
	}
}

stock Float:CheckTeammateDamages(infected, client = -1, bool:bIsMyDamageOnly = false) {

	/*

		Common Infected have a shared-health pool, as a result we compare a players
		damage only when considering commons damage; the player who deals the killing blow
		on a common will receive the bonus.

		However, special commons and special infected will have separate health pools.
	*/

	new Float:isDamageValue = 0.0;
	new pos = -1;
	new cHealth = 0;
	new tHealth = 0;
	new Float:tBonus = 0.0;
	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;
		if (bIsMyDamageOnly && client != i) continue;
		/*
			isDamageValue is a percentage of the total damage a player has dealt to the special infected.
			We calculate this by taking the player damage contribution and dividing it by the total health of the infected.
			we then add this value, and return the total of all players.
			if the value > or = to 1.0, the infected player dies.

			This health bar will display two health bars.
			True health: The actual health the infected player has remaining
			E. Health: The health the infected has FOR YOU
		*/
		if (IsLegitimateClient(infected)) {

			pos = FindListPositionByEntity(infected, Handle:InfectedHealth[i]);
			if (pos < 0) continue;	// how?
			cHealth = GetArrayCell(Handle:InfectedHealth[i], pos, 2);
			tHealth = GetArrayCell(Handle:InfectedHealth[i], pos, 1);
		}
		else if (IsWitch(infected)) {

			pos = FindListPositionByEntity(infected, Handle:WitchDamage[i]);
			if (pos < 0) continue;
			cHealth = GetArrayCell(Handle:WitchDamage[i], pos, 2);
			tHealth = GetArrayCell(Handle:WitchDamage[i], pos, 1);
		}
		else if (IsSpecialCommon(infected)) {

			pos = FindListPositionByEntity(infected, Handle:SpecialCommon[i]);
			if (pos < 0) continue;
			cHealth = GetArrayCell(Handle:SpecialCommon[i], pos, 2);
			tHealth = GetArrayCell(Handle:SpecialCommon[i], pos, 1);
		}
		else if (IsCommonInfected(infected)) {

			pos = FindListPositionByEntity(infected, Handle:CommonInfectedDamage[i]);
			if (pos < 0) continue;
			cHealth = GetArrayCell(Handle:CommonInfectedDamage[i], pos, 2);
			tHealth = GetArrayCell(Handle:CommonInfectedDamage[i], pos, 1);
		}
		tBonus = (cHealth * 1.0) / (tHealth * 1.0);
		isDamageValue += tBonus;
	}
	//PrintToChatAll("Damage percent: %3.3f", isDamageValue);
	if (isDamageValue > 1.0) isDamageValue = 1.0;
	return isDamageValue;
}

stock DisplayInfectedHealthBars(survivor, infected) {

	if (iRPGMode == -1) return;

	decl String:text[512];
	if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) GetClientName(infected, text, sizeof(text));
	else if (IsWitch(infected)) Format(text, sizeof(text), "Bitch");
	else if (IsSpecialCommon(infected)) GetCommonValue(text, sizeof(text), infected, "name?");
	else if (IsCommonInfected(infected)) Format(text, sizeof(text), "Common");

	//Format(text, sizeof(text), "%s %s", GetConfigValue("director team name?"), text);
	if (LivingSurvivorCount() > 1) {

		Format(text, sizeof(text), "E.HP%s(%s)\nCNT%s", GetInfectedHealthBar(survivor, infected, true), text, GetInfectedHealthBar(survivor, infected, false));
		//Format(text, sizeof(text), "%s\nCNT%s", text, GetInfectedHealthBar(survivor, infected, false));
		//Format(text, sizeof(text), "%s\t%s\n%s", GetStatusEffects(survivor), GetStatusEffects(survivor, 1), text);
	}
	else Format(text, sizeof(text), "CNT%s(%s)", GetInfectedHealthBar(survivor, infected, false), text);
	PrintCenterText(survivor, text);
}

stock String:GetStatusEffects(client, EffectType = 0) {

	decl String:eBar[512];
	new Count = 0;
	new iNumStatusEffects = 0;
	// NEGATIVE effects
	//new printClient = client;

	//decl String:TargetName[64];
	//GetClientAimTargetEx(client, TargetName, sizeof(TargetName), true);
	//client = StringToInt(TargetName);
	//if (!IsLegitimateClientAlive(client) || GetClientTeam(client) != GetClientTeam(printClient)) client = printClient;
	if (EffectType == 0) {

		//new AcidCount = GetClientStatusEffect(client, Handle:EntityOnFire, "acid");
		new FireCount = GetClientStatusEffect(client, Handle:EntityOnFire);
		Format(eBar, sizeof(eBar), "[-]");
		if (DoomTimer != 0) Format(eBar, sizeof(eBar), "[Dm%d]%s", iDoomTimer - DoomTimer, eBar);
		if (bIsSurvivorFatigue[client]) Format(eBar, sizeof(eBar), "[Fa]%s", eBar);
		/*Count = GetClientStatusEffect(client, Handle:EntityOnFire, "burn");
		if (Count > 1) Format(eBar, sizeof(eBar), "[Bu%d]%s", Count, eBar);
		Count = GetClientStatusEffect(client, Handle:EntityOnFire, "acid")
		if (Count > 1) Format(eBar, sizeof(eBar), "[Ab%d]%s", Count, eBar);
		Count = GetClientStatusEffect(client, Handle:EntityOnFire, "reflect");
		if (Count > 1) Format(eBar, sizeof(eBar), "[Re%d]%s", Count, eBar);*/
		Count = GetClientStatusEffect(client, Handle:EntityOnFire, "burn");
		if (Count > 0) iNumStatusEffects++;
		if (Count >= 3) Format(eBar, sizeof(eBar), "[Bu++]%s", eBar);
		else if (Count >= 2) Format(eBar, sizeof(eBar), "[Bu+]%s", eBar);
		else if (Count > 0) Format(eBar, sizeof(eBar), "[Bu]%s", eBar);

		Count = GetClientStatusEffect(client, Handle:EntityOnFire, "acid");
		if (Count > 0) iNumStatusEffects++;
		if (Count >= 3) Format(eBar, sizeof(eBar), "[Ab++]%s", eBar);
		else if (Count >= 2) Format(eBar, sizeof(eBar), "[Ab+]%s", eBar);
		else if (Count > 0) Format(eBar, sizeof(eBar), "[Ab]%s", eBar);

		Count = GetClientStatusEffect(client, Handle:EntityOnFire, "reflect");
		if (Count > 0) iNumStatusEffects++;
		if (Count >= 3) Format(eBar, sizeof(eBar), "[Re++]%s", eBar);
		else if (Count >= 2) Format(eBar, sizeof(eBar), "[Re+]%s", eBar);
		else if (Count > 0) Format(eBar, sizeof(eBar), "[Re]%s", eBar);

		if (ISBLIND[client] != INVALID_HANDLE) {

			Format(eBar, sizeof(eBar), "[Bl]%s", eBar);
			iNumStatusEffects++;
		}
		if (ISEXPLODE[client] != INVALID_HANDLE || IsClientInRangeSpecialAmmo(client, "x") == -2.0) {

			Format(eBar, sizeof(eBar), "[Ex]%s", eBar);
			iNumStatusEffects++;
		}
		if (ISFROZEN[client] != INVALID_HANDLE) {

			Format(eBar, sizeof(eBar), "[Fr]%s", eBar);
			iNumStatusEffects++;
		}
		
		if (ISSLOW[client] != INVALID_HANDLE || IsClientInRangeSpecialAmmo(client, "s") == -2.0) {

			Format(eBar, sizeof(eBar), "[Sl]%s", eBar);
			iNumStatusEffects++;
		}
		//if (ISSLOW[client] != INVALID_HANDLE) Format(eBar, sizeof(eBar), "[Sl]%s", eBar);
		
		if (ISFROZEN[client] != INVALID_HANDLE && FireCount > 0) {

			Format(eBar, sizeof(eBar), "[Tx]%s", eBar);
			iNumStatusEffects++;
		}
		if (ISEXPLODE[client] != INVALID_HANDLE && FireCount > 0) {

			Format(eBar, sizeof(eBar), "[Sc]%s", eBar);
			iNumStatusEffects++;
		}
		if (!(GetEntityFlags(client) & FL_ONGROUND)) {

			Format(eBar, sizeof(eBar), "[Fl]%s", eBar);
			iNumStatusEffects++;
		}
		if (bIsInCombat[client]) Format(eBar, sizeof(eBar), "[Ic]%s", eBar);
		if (ISBILED[client]) {

			Format(eBar, sizeof(eBar), "[Bi]%s", eBar);
			iNumStatusEffects++;
		}
		if (ISDAZED[client] > GetEngineTime()) {

			Format(eBar, sizeof(eBar), "[Dz]%s", eBar);
			iNumStatusEffects++;
		}
		
		if (PlayerHasWeakness(client)) {

			Format(eBar, sizeof(eBar), "[Wk]%s", eBar);
			iNumStatusEffects++;
		}
		
		if (IsSpecialCommonInRange(client, 'd')) {

			Format(eBar, sizeof(eBar), "[Re]%s", eBar);
			iNumStatusEffects++;
		}
		
		/*if (IsActiveAmmoCooldown(client, 'H')) Format(eBar, sizeof(eBar), "[HeA]%s", eBar);
		if (IsActiveAmmoCooldown(client, 'h')) Format(eBar, sizeof(eBar), "[LeA]%s", eBar);
		if (IsActiveAmmoCooldown(client, 'b')) Format(eBar, sizeof(eBar), "[BeA]%s", eBar);
		if (IsActiveAmmoCooldown(client, 's')) Format(eBar, sizeof(eBar), "[SlA]%s", eBar);
		if (IsActiveAmmoCooldown(client, 'x')) Format(eBar, sizeof(eBar), "[ExA]%s", eBar);
		if (IsActiveAmmoCooldown(client, 'g')) Format(eBar, sizeof(eBar), "[GrA]%s", eBar);
		if (IsActiveAmmoCooldown(client, 'B')) Format(eBar, sizeof(eBar), "[BiA]%s", eBar);
		if (IsActiveAmmoCooldown(client, 'O')) Format(eBar, sizeof(eBar), "[OdA]%s", eBar);
		if (IsActiveAmmoCooldown(client, 'E')) Format(eBar, sizeof(eBar), "[BkA]%s", eBar);
		if (IsActiveAmmoCooldown(client, 'a')) Format(eBar, sizeof(eBar), "[AdA]%s", eBar);
		if (IsActiveAmmoCooldown(client, 'W')) Format(eBar, sizeof(eBar), "[DkA]%s", eBar);*/

		//if (printClient != client) Format(eBar, sizeof(eBar), "%s\n%s", TargetName, eBar);
	}
	else if (EffectType == 1) {		// POSITIVE EFFECTS

		Format(eBar, sizeof(eBar), "[+]");
		//if (printClient != client) Format(eBar, sizeof(eBar), "%s\n%s", TargetName, eBar);
		if (!bIsInCombat[client]) Format(eBar, sizeof(eBar), "%s[Oc]", eBar);
		/*if (IsSpecialAmmoEnabled[client][0] == 1.0) {

			//Format(text, sizeof(text), "%s (%s)", text, ActiveSpecialAmmo[client]);
			// Need to get active ammo effect type
			if (GetActiveSpecialAmmoType(client, 's') && !IsActiveAmmoCooldown(client, 's')) Format(eBar, sizeof(eBar), "%s[SlA]", eBar);
			else if (GetActiveSpecialAmmoType(client, 'b') && !IsActiveAmmoCooldown(client, 'b')) Format(eBar, sizeof(eBar), "%s[BeA]", eBar);
			else if (GetActiveSpecialAmmoType(client, 'h') && !IsActiveAmmoCooldown(client, 'h')) Format(eBar, sizeof(eBar), "%s[LeA]", eBar);
			else if (GetActiveSpecialAmmoType(client, 'x') && !IsActiveAmmoCooldown(client, 'x')) Format(eBar, sizeof(eBar), "%s[ExA]", eBar);
			else if (GetActiveSpecialAmmoType(client, 'g') && !IsActiveAmmoCooldown(client, 'g')) Format(eBar, sizeof(eBar), "%s[GrA]", eBar);
			else if (GetActiveSpecialAmmoType(client, 'H') && !IsActiveAmmoCooldown(client, 'H')) Format(eBar, sizeof(eBar), "%s[HeA]", eBar);
			else if (GetActiveSpecialAmmoType(client, 'd') && !IsActiveAmmoCooldown(client, 'd')) Format(eBar, sizeof(eBar), "%s[DaA]", eBar);
			else if (GetActiveSpecialAmmoType(client, 'D') && !IsActiveAmmoCooldown(client, 'D')) Format(eBar, sizeof(eBar), "%s[DsA]", eBar);
			else if (GetActiveSpecialAmmoType(client, 'R') && !IsActiveAmmoCooldown(client, 'R')) Format(eBar, sizeof(eBar), "%s[ReA]", eBar);
			else if (GetActiveSpecialAmmoType(client, 'B') && !IsActiveAmmoCooldown(client, 'B')) Format(eBar, sizeof(eBar), "%s[BiA]", eBar);
			else if (GetActiveSpecialAmmoType(client, 'O') && !IsActiveAmmoCooldown(client, 'O')) Format(eBar, sizeof(eBar), "%s[OdA]", eBar);
			else if (GetActiveSpecialAmmoType(client, 'E') && !IsActiveAmmoCooldown(client, 'E')) Format(eBar, sizeof(eBar), "%s[BkA]", eBar);
			else if (GetActiveSpecialAmmoType(client, 'a') && !IsActiveAmmoCooldown(client, 'a')) Format(eBar, sizeof(eBar), "%s[AdA]", eBar);
			else if (GetActiveSpecialAmmoType(client, 'W') && !IsActiveAmmoCooldown(client, 'W')) Format(eBar, sizeof(eBar), "%s[DkA]", eBar);
			else if (GetActiveSpecialAmmoType(client, 'C') && !IsActiveAmmoCooldown(client, 'C')) Format(eBar, sizeof(eBar), "%s[ClA]", eBar);
		}*/
		if (IsClientInRangeSpecialAmmo(client, "b") == -2.0) {

			Format(eBar, sizeof(eBar), "%s[Be]", eBar);
			iNumStatusEffects++;
		}
		if (IsClientInRangeSpecialAmmo(client, "h") == -2.0) {

			Format(eBar, sizeof(eBar), "%s[Le]", eBar);
			iNumStatusEffects++;
		}
		if (IsClientInRangeSpecialAmmo(client, "g") == -2.0) {

			Format(eBar, sizeof(eBar), "%s[Gr]", eBar);
			iNumStatusEffects++;
		}
		if (IsClientInRangeSpecialAmmo(client, "H") == -2.0) {

			Format(eBar, sizeof(eBar), "%s[He]", eBar);
			iNumStatusEffects++;
		}
		if (IsClientInRangeSpecialAmmo(client, "d") == -2.0) {

			Format(eBar, sizeof(eBar), "%s[Da]", eBar);
			iNumStatusEffects++;
		}
		if (IsClientInRangeSpecialAmmo(client, "D") == -2.0) {

			Format(eBar, sizeof(eBar), "%s[Ds]", eBar);
			iNumStatusEffects++;
		}
		if (IsClientInRangeSpecialAmmo(client, "R") == -2.0) {

			Format(eBar, sizeof(eBar), "%s[Re]", eBar);
			iNumStatusEffects++;
		}
		if (IsClientInRangeSpecialAmmo(client, "B") == -2.0) {

			Format(eBar, sizeof(eBar), "%s[Bi]", eBar);
			iNumStatusEffects++;
		}
		if (IsClientInRangeSpecialAmmo(client, "O") == -2.0) {

			Format(eBar, sizeof(eBar), "%s[Od]", eBar);
			iNumStatusEffects++;
		}
		if (IsClientInRangeSpecialAmmo(client, "E") == -2.0) {

			Format(eBar, sizeof(eBar), "%s[Bk]", eBar);
			iNumStatusEffects++;
		}
		if (HasAdrenaline(client)) {

			Format(eBar, sizeof(eBar), "%s[Ad]", eBar);
			iNumStatusEffects++;
		}
		if (GetEntityFlags(client) & FL_INWATER) {

			Format(eBar, sizeof(eBar), "%s[Wa]", eBar);
			iNumStatusEffects++;
		}
	}
	if (IsPvP[client] != 0) Format(eBar, sizeof(eBar), "%s[PvP]", eBar);

	MyStatusEffects[client] = iNumStatusEffects;
	return eBar;
}

/*stock ToggleTank(client, bool:bDisableTank = false) {

	if (!bDisableTank && (!IsValidEntity(MyVomitChase[client]) || MyVomitChase[client] == -1)) {

		decl String:TargetName[64];

		if (IsValidEntity(MyVomitChase[client])) {

			AcceptEntityInput(MyVomitChase[client], "Kill");
			MyVomitChase[client] = -1;
		}
		MyVomitChase[client] = CreateEntityByName("info_goal_infected_chase");
		if (IsValidEntity(MyVomitChase[client])) {

			new Float:ClientPos[3];
			GetClientAbsOrigin(client, ClientPos);
			ClientPos[2] += 20.0;

			DispatchKeyValueVector(MyVomitChase[client], "origin", ClientPos);
			Format(TargetName, sizeof(TargetName), "goal_infected%d", client);
			DispatchKeyValue(MyVomitChase[client], "targetname", TargetName);
			GetClientName(client, TargetName, sizeof(TargetName));
			DispatchKeyValue(client, "parentname", TargetName);
			DispatchSpawn(MyVomitChase[client]);
			SetVariantString(TargetName);
			AcceptEntityInput(MyVomitChase[client], "SetParent", MyVomitChase[client], MyVomitChase[client], 0);
			ActivateEntity(MyVomitChase[client]);
			AcceptEntityInput(MyVomitChase[client], "Enable");
		}
	}
	else if (bDisableTank) {

		if (IsValidEntity(MyVomitChase[client])) AcceptEntityInput(MyVomitChase[client], "Kill");
		MyVomitChase[client] = -1;
	}
}*/

stock bool:IsClientCleansing(client) {

	if (IsClientInRangeSpecialAmmo(client, "C") == -2.0 && !IsPlayerFeeble(client)) return true;
	return false;
}

stock bool:IsActiveAmmoCooldown(client, effect) {

	decl String:result[2][64];
	decl String:EffectT[4];
	Format(EffectT, sizeof(EffectT), "%c", effect);

	new size = GetArraySize(PlayerActiveAmmo[client]);
	new pos = -1;
	for (new i = 0; i < size; i++) {

		GetArrayString(PlayerActiveAmmo[client], i, result[0], sizeof(result[]));
		ExplodeString(result[0], ":", result, 2, 64);

		pos			= GetMenuPosition(client, result[0]);
		if (pos == -1) continue;	// wtf?

		ActiveAmmoCooldownKeys[client]				= GetArrayCell(a_Menu_Talents, pos, 0);
		ActiveAmmoCooldownValues[client]			= GetArrayCell(a_Menu_Talents, pos, 1);
		if (StrContains(GetKeyValue(ActiveAmmoCooldownKeys[client], ActiveAmmoCooldownValues[client], "ammo effect?"), EffectT, true) == -1) continue;
		if (CheckActiveAmmoCooldown(client, result[0]) == 2) return true;
	}
	return false;
}

stock GetSpecialAmmoEffect(String:TheValue[], TheSize, client, String:TalentName[]) {

	new pos			= GetMenuPosition(client, TalentName);
	if (pos >= 0) {

		SpecialAmmoEffectKeys[client]				= GetArrayCell(a_Menu_Talents, pos, 0);
		SpecialAmmoEffectValues[client]			= GetArrayCell(a_Menu_Talents, pos, 1);

		FormatKeyValue(TheValue, TheSize, SpecialAmmoEffectKeys[client], SpecialAmmoEffectValues[client], "ammo effect?");
	}
}

stock GetPlayerStamina(client) {

	/*

		This function gets a players maximum stamina, which is important so they don't regenerate beyond it.
	*/
	/*new StaminaMax = GetConfigValueInt("survivor stamina?");
	new StaminaMax_Temp = 0;
	new Endu = GetTalentStrength(client, "endurance");
	for (new i = 0; i < Endu; i++) {

		StaminaMax_Temp += RoundToCeil(StaminaMax * GetConfigValueFloat("endurance stam?"));
	}
	StaminaMax += StaminaMax_Temp;*/

	new StaminaMax = iSurvivorStaminaMax + (PlayerLevel[client] - iPlayerStartingLevel);

	new Float:TheAbilityMultiplier = 0.0;
	TheAbilityMultiplier = GetAbilityMultiplier(client, 'T');
	if (TheAbilityMultiplier == -1.0) TheAbilityMultiplier = 0.0;	// no change

	StaminaMax += RoundToCeil(StaminaMax * TheAbilityMultiplier);
	return StaminaMax;
}

stock String:GetCombatState(client) {

	decl String:text[64];
	if (!bIsInCombat[client]) Format(text, sizeof(text), "%T", "out of combat state", client);
	else Format(text, sizeof(text), "%T", "in combat state", client, CombatTime[client] - GetEngineTime());
	return text;
}

stock DisplayInfectedHUD(client, statusType) {

	ExperienceBarBroadcast(client, GetStatusEffects(client, statusType));
}

stock DisplayHUD(client, statusType) {


	if (iRPGMode >= 1) {

		if (IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_INFECTED && !IsFakeClient(client)) {

			new healthremaining = GetHumanInfectedHealth(client);
			if (healthremaining > 0) SetEntityHealth(client, GetHumanInfectedHealth(client));
		}

		decl String:text[64];
		//decl String:text2[64];
		decl String:testelim[1];
		decl String:EnemyName[64];
		GetClientAimTargetEx(client, EnemyName, sizeof(EnemyName), true);
		//new enemycombatant = LastAttackedUser[client];
		new enemycombatant = StringToInt(EnemyName);
		//if (!IsWitch(enemycombatant) && !IsLegitimateClientAlive(enemycombatant) || IsLegitimateClientAlive(enemycombatant) && !IsFakeClient(enemycombatant)) enemycombatant = -1;
		if (IsCommonInfected(enemycombatant) && !IsSpecialCommon(enemycombatant)) enemycombatant = -1;
		else if (!IsCommonInfected(enemycombatant) && !IsWitch(enemycombatant) && !IsLegitimateClientAlive(enemycombatant)) enemycombatant = -1;
		
		if (enemycombatant != -1) {

			if (IsSpecialCommon(enemycombatant)) GetCommonValue(EnemyName, sizeof(EnemyName), enemycombatant, "name?");
			else if (IsWitch(enemycombatant)) Format(EnemyName, sizeof(EnemyName), "Witch");
			else if (IsLegitimateClientAlive(enemycombatant)) {

				if (!IsSurvivorBot(enemycombatant)) GetClientName(enemycombatant, EnemyName, sizeof(EnemyName));
				else GetSurvivorBotName(enemycombatant, EnemyName, sizeof(EnemyName));
			}
			else enemycombatant = -1;
		}
		//new bool:DisplayEnrage = true;
		//if (StrContains(ActiveClass[client], "death", false) == -1 || IsEnrageActive()) DisplayEnrage = false;
		Format(testelim, sizeof(testelim), " ");
		if (IsLegitimateClientAlive(enemycombatant) && (GetClientTeam(enemycombatant) == TEAM_SURVIVOR || IsSurvivorBot(enemycombatant))) {

			decl String:TheClass[64];
			new myClassLevel = CartelLevel(enemycombatant);
			if (myClassLevel < 0) myClassLevel = 0;
			//if (StrContains(ActiveClass[enemycombatant], "none", false) == -1 && strlen(ActiveClass[enemycombatant]) >= 4)
			if (IsLegitimateClass(enemycombatant)) {

				Format(TheClass, sizeof(TheClass), "%T", ActiveClass[enemycombatant], client);
				Format(EnemyName, sizeof(EnemyName), "(TLv.%s)(%s Lv.%s) %s", AddCommasToString(PlayerLevel[enemycombatant]), TheClass, AddCommasToString(myClassLevel), EnemyName);
			}
			else {

				Format(TheClass, sizeof(TheClass), "%T", "Vanilla", client);
				Format(EnemyName, sizeof(EnemyName), "(TLv.%s)Vanilla %s", AddCommasToString(PlayerLevel[enemycombatant]), EnemyName);
			}
			//Format(EnemyName, sizeof(EnemyName), "%s %s Lv.%d", TheClass, EnemyName, PlayerLevel[enemycombatant]);
			//if (IsPvP[enemycombatant] != 0) Format(EnemyName, sizeof(EnemyName), "%s[PvP]", EnemyName);
		}

		//if (!StrEqual(ActiveSpecialAmmo[client], "none")) Format(text, sizeof(text), "HC %s %s STA %s %s %s", testelim, testelim, testelim, testelim, ActiveSpecialAmmo[client]);

		if (bJetpack[client]) {

			new PlayerMaxStamina = GetPlayerStamina(client);
			new Float:PlayerCurrStamina = ((SurvivorStamina[client] * 1.0) / (PlayerMaxStamina * 1.0)) * 100.0;

			decl String:pct[4];
			Format(pct, sizeof(pct), "%");

			Format(text, sizeof(text), "Jetpack Fuel: %3.2f %s\n%s", PlayerCurrStamina, pct, GetStatusEffects(client, statusType));
		}
		else if (enemycombatant != -1) {

			if (IsSpecialCommon(enemycombatant) || IsWitch(enemycombatant) || IsLegitimateClientAlive(enemycombatant) && GetClientTeam(enemycombatant) != TEAM_SURVIVOR) Format(text, sizeof(text), "%s: %sHP\n%s\n%d HITS!", EnemyName, AddCommasToString(GetTargetHealth(client, enemycombatant)), GetStatusEffects(client, statusType), ConsecutiveHits[client]);
			else if (IsLegitimateClientAlive(enemycombatant) && (GetClientTeam(enemycombatant) == TEAM_SURVIVOR || IsSurvivorBot(enemycombatant))) Format(text, sizeof(text), "%s HP: %s %s\n%s\n%d HITS!", EnemyName, testelim, AddCommasToString(GetTargetHealth(client, enemycombatant, true)), GetStatusEffects(enemycombatant, statusType), ConsecutiveHits[client]);
		}
		else Format(text, sizeof(text), "%s", GetStatusEffects(client, statusType));
		/*else if (IsSpecialAmmoEnabled[client][0] == 1.0 || enemycombatant == -1) {

			new ExplodeCount = GetDelimiterCount(ActiveSpecialAmmo[client], " ") + 1;
			decl String:AmmoName[ExplodeCount][64];

			ExplodeString(ActiveSpecialAmmo[client], " ", AmmoName, ExplodeCount, 64);
			//Format(AmmoName[0], sizeof(AmmoName[]), "%s %s %s", testelim, testelim, AmmoName[0]);

			new Float:AmmoCooldownTime = GetAmmoCooldownTime(client, ActiveSpecialAmmo[client]);

			if (AmmoCooldownTime == -1.0) Format(text2, sizeof(text2), "%s", AmmoName[0]);
			else Format(text2, sizeof(text2), "%s(%3.2f)", AmmoName[0], AmmoCooldownTime);

			Format(text, sizeof(text), "Mana: %s\nAmmo: %s", AddCommasToString(SurvivorStamina[client]), text2);
			if (IsSpecialAmmoEnabled[client][0] == 0.0) Format(text, sizeof(text), "%s(Off)", text);
			Format(text, sizeof(text), "%s\n%s", text, GetStatusEffects(client, statusType));

		}*/
		if (strlen(text) > 1) PrintHintText(client, text);
	}
}

stock String:GetPlayerStaminaBar(client) {

	decl String:eBar[64];
	Format(eBar, sizeof(eBar), "[----------]");
	if (IsLegitimateClientAlive(client)) {

		/*

			Players have a stamina bar.
		*/

		new Float:eCnt = 0.0;
		new Float:ePct = (SurvivorStamina[client] * 1.0 / (GetPlayerStamina(client) * 1.0)) * 100.0;
		for (new i = 1; i < strlen(eBar); i++) {

			if (eCnt + 10.0 <= ePct) {

				eBar[i] = '=';
				eCnt += 10.0;
			}
		}
	}
	return eBar;
}

/*
if (StrContains(ClassRoles, "Tank") != -1) {


		//2800 / 319860
		//Tanking rating: 44

		//DamageTaken = GetClassMultiplier(survivor, DamageTaken * 1.0, "tXP"));
		new Float:RatingReductionMult = GetClassMultiplier(survivor, -1.0, "D");
		if (RatingReductionMult == -1.0) RatingReductionMult = 1.0;
		DamageTaken = RoundToCeil(DamageTaken / RatingReductionMult);

		if (DamageTaken > TotalHealth) DamageTaken = TotalHealth;
		RatingRewardTanking = RoundToCeil(((DamageTaken * 100.0) / TotalHealth) * RatingMultiplier);
	}
*/

stock Float:GetTankingContribution(survivor, infected) {

	new TotalHealth = 0;
	new DamageTaken = 0;

	new pos = -1;
	if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) pos = FindListPositionByEntity(infected, Handle:InfectedHealth[survivor]);
	else if (IsWitch(infected)) pos = FindListPositionByEntity(infected, Handle:WitchDamage[survivor]);
	else if (IsSpecialCommon(infected)) pos = FindListPositionByEntity(infected, Handle:SpecialCommon[survivor]);

	if (pos < 0) return 0.0;

	if (IsWitch(infected)) {

		TotalHealth		= GetArrayCell(Handle:WitchDamage[survivor], pos, 1);
		DamageTaken		= GetArrayCell(Handle:WitchDamage[survivor], pos, 3);
	}
	else if (IsSpecialCommon(infected)) {

		TotalHealth		= GetArrayCell(Handle:SpecialCommon[survivor], pos, 1);
		DamageTaken		= GetArrayCell(Handle:SpecialCommon[survivor], pos, 3);
	}
	else if (IsLegitimateClient(infected) && GetClientTeam(infected) == TEAM_INFECTED) {

		TotalHealth		= GetArrayCell(Handle:InfectedHealth[survivor], pos, 1);
		DamageTaken		= GetArrayCell(Handle:InfectedHealth[survivor], pos, 3);
	}
	if (DamageTaken == 0) return 0.0;
	if (DamageTaken > TotalHealth) return 1.0;
	//new Float:TheDamageTaken = (DamageTaken * 1.0) / (TotalHealth * 1.0);
	return ((DamageTaken * 1.0) / (TotalHealth * 1.0));
}

stock GetTargetHealth(client, target, bool:MyHealth = false) {

	new TotalHealth = 0;
	new DamageDealt = 0;

	new pos = -1;
	if (IsSpecialCommon(target)) pos = FindListPositionByEntity(target, Handle:SpecialCommon[client]);
	else if (IsWitch(target)) pos = FindListPositionByEntity(target, Handle:WitchDamage[client]);
	else if (IsLegitimateClientAlive(target) && GetClientTeam(target) == TEAM_INFECTED) pos = FindListPositionByEntity(target, Handle:InfectedHealth[client]);
	else if (IsLegitimateClientAlive(target) && (GetClientTeam(target) == TEAM_SURVIVOR || IsSurvivorBot(target))) {

		return GetClientHealth(target);
	}

	if (pos >= 0) {

		if (IsWitch(target)) {

			TotalHealth		= GetArrayCell(Handle:WitchDamage[client], pos, 1);
			DamageDealt		= GetArrayCell(Handle:WitchDamage[client], pos, 2);
		}
		else if (IsLegitimateClient(target) && GetClientTeam(target) == TEAM_INFECTED) {

			TotalHealth		= GetArrayCell(Handle:InfectedHealth[client], pos, 1);
			DamageDealt		= GetArrayCell(Handle:InfectedHealth[client], pos, 2);
		}
		else if (IsSpecialCommon(target)) {

			TotalHealth		= GetArrayCell(Handle:SpecialCommon[client], pos, 1);
			DamageDealt		= GetArrayCell(Handle:SpecialCommon[client], pos, 2);
		}
		if (!MyHealth) TotalHealth = RoundToCeil((1.0 - CheckTeammateDamages(target, client)) * TotalHealth);
		else TotalHealth -= DamageDealt;
	}
	return TotalHealth;
}

stock GetRatingReward(survivor, infected) {

	new RatingRewardDamage = 0;
	new RatingRewardTanking = 0;

	// If the player took less total damage than the health of the mob, you do Rating += RoundToFloor((PlayerDamageTaken / MobTotalHealth) * 100.0);
	new TotalHealth = 0;
	new DamageTaken = 0;
	//new DamageDealt = 0;
	new Float:RatingMultiplier = 0.0;

	new pos = -1;
	if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) pos = FindListPositionByEntity(infected, Handle:InfectedHealth[survivor]);
	else if (IsWitch(infected)) pos = FindListPositionByEntity(infected, Handle:WitchDamage[survivor]);
	else if (IsSpecialCommon(infected)) pos = FindListPositionByEntity(infected, Handle:SpecialCommon[survivor]);
	else if (IsCommonInfected(infected)) pos = FindListPositionByEntity(infected, Handle:CommonInfectedDamage[survivor]);

	if (pos < 0) return 0;

	if (IsWitch(infected)) {

		TotalHealth		= GetArrayCell(Handle:WitchDamage[survivor], pos, 1);
		DamageTaken		= GetArrayCell(Handle:WitchDamage[survivor], pos, 3);
		RatingMultiplier = fRatingMultSpecials;
	}
	else if (IsSpecialCommon(infected)) {

		TotalHealth		= GetArrayCell(Handle:SpecialCommon[survivor], pos, 1);
		DamageTaken		= GetArrayCell(Handle:SpecialCommon[survivor], pos, 3);
		RatingMultiplier = fRatingMultSupers;
	}
	else if (IsCommonInfected(infected)) {

		TotalHealth		= GetArrayCell(Handle:CommonInfectedDamage[survivor], pos, 1);
		DamageTaken		= GetArrayCell(Handle:CommonInfectedDamage[survivor], pos, 3);
		RatingMultiplier = fRatingMultCommons;
	}
	else if (IsLegitimateClient(infected) && GetClientTeam(infected) == TEAM_INFECTED) {

		TotalHealth		= GetArrayCell(Handle:InfectedHealth[survivor], pos, 1);
		DamageTaken		= GetArrayCell(Handle:InfectedHealth[survivor], pos, 3);
		if (FindZombieClass(infected) != ZOMBIECLASS_TANK) RatingMultiplier = fRatingMultSpecials;
		else RatingMultiplier = fRatingMultTank;
	}
	if (RatingMultiplier <= 0.0) return 0;

	//if (DamageDealt > TotalHealth) DamageDealt = TotalHealth;

	RatingRewardDamage = RoundToFloor(CheckTeammateDamages(infected, survivor, true) * 100.0);
	
	if (TotalHealth <= 0) return 0;

	decl String:ClassRoles[64];
	GetMenuOfTalent(survivor, ActiveClass[survivor], ClassRoles, sizeof(ClassRoles));
	if (StrContains(ClassRoles, "Tank") != -1) {


		//2800 / 319860
		//Tanking rating: 44

		//DamageTaken = GetClassMultiplier(survivor, DamageTaken * 1.0, "tXP"));
		new Float:RatingReductionMult = GetClassMultiplier(survivor, -1.0, "D");
		if (RatingReductionMult == -1.0) RatingReductionMult = 1.0;
		DamageTaken = RoundToCeil(DamageTaken / RatingReductionMult);

		if (DamageTaken > TotalHealth) DamageTaken = TotalHealth;
		RatingRewardTanking = RoundToCeil(((DamageTaken * 100.0) / TotalHealth) * RatingMultiplier);
	}

	//RatingRewardTanking = RoundToCeil(RatingReductionMult * RatingRewardTanking);

	RatingRewardDamage = RoundToFloor(RatingRewardDamage * RatingMultiplier);
	RatingRewardDamage += RatingRewardTanking;	// 0 if the user is not a tank
	return RatingRewardDamage;
}

stock GetHumanInfectedHealth(client) {

	new Float:isHealthRemaining = CheckTeammateDamages(client);
	return RoundToCeil(GetMaximumHealth(client) * isHealthRemaining);
}

stock String:GetInfectedHealthBar(survivor, infected, bool:bTrueHealth = false) {

	decl String:eBar[256];
	Format(eBar, sizeof(eBar), "[----------------------------------------]");

	new pos = 0;
	if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) pos = FindListPositionByEntity(infected, Handle:InfectedHealth[survivor]);
	else if (IsWitch(infected)) pos = FindListPositionByEntity(infected, Handle:WitchDamage[survivor]);
	else if (IsSpecialCommon(infected)) pos = FindListPositionByEntity(infected, Handle:SpecialCommon[survivor]);
	else if (IsCommonInfected(infected)) pos = FindListPositionByEntity(infected, Handle:CommonInfectedDamage[survivor]);
	if (pos >= 0) {

		new Float:isHealthRemaining = CheckTeammateDamages(infected, survivor);

		// isDamageContribution is the total damage the player has, themselves, dealt to the special infected.
		new isDamageContribution = 0;
		new isTotalHealth = 0;
		if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) {

			isDamageContribution = GetArrayCell(Handle:InfectedHealth[survivor], pos, 2);
			isTotalHealth = GetArrayCell(Handle:InfectedHealth[survivor], pos, 1);
		}
		else if (IsWitch(infected)) {

			isDamageContribution = GetArrayCell(Handle:WitchDamage[survivor], pos, 2);
			isTotalHealth = GetArrayCell(Handle:WitchDamage[survivor], pos, 1);
		}
		else if (IsSpecialCommon(infected)) {

			isDamageContribution = GetArrayCell(Handle:SpecialCommon[survivor], pos, 2);
			isTotalHealth = GetArrayCell(Handle:SpecialCommon[survivor], pos, 1);
		}
		else if (IsCommonInfected(infected)) {

			isDamageContribution = GetArrayCell(Handle:CommonInfectedDamage[survivor], pos, 2);
			isTotalHealth = GetArrayCell(Handle:CommonInfectedDamage[survivor], pos, 1);
		}

		
		new Float:tPct = 100.0 - (isHealthRemaining * 100.0);
		new Float:yPct = ((isDamageContribution * 1.0) / (isTotalHealth * 1.0) * 100.0);
		new Float:ePct = 0.0;

		if (bTrueHealth) ePct = tPct;
		else ePct = yPct;
		new Float:eCnt = 0.0;

		for (new i = 1; i + 1 < strlen(eBar); i++) {

			if (eCnt + 2.5 < ePct) {

				eBar[i] = '|';
				eCnt += 2.5;
			}
		}
	}
	return eBar;
}

stock ExperienceBar(client, String:sTheString[], iTheSize, iBarType = 0, bool:bReturnValue = false) {// 0 XP, 1 Infected armor (humans only), 2 Infected Health from talents, etc. (humans only)

	//decl String:eBar[256];
	new Float:ePct = 0.0;
	if (iBarType == 0) ePct = ((ExperienceLevel[client] * 1.0) / (CheckExperienceRequirement(client) * 1.0)) * 100.0;
	else if (iBarType == 1) ePct = 100.0 - CheckTeammateDamages(client) * 100.0;
	else if (iBarType == 2) {

		ePct = (GetArrayCell(Handle:InfectedHealth[client], 0, 6) / GetArrayCell(Handle:InfectedHealth[client], 0, 5)) * 100.0;
	}
	if (bReturnValue) {

		Format(sTheString, iTheSize, "%3.3f", ePct);
	}
	else {

		new Float:eCnt = 0.0;
		//Format(eBar, sizeof(eBar), "[--------------------]");
		Format(sTheString, iTheSize, "[----------]");

		for (new i = 1; i + 1 <= strlen(sTheString); i++) {

			if (eCnt + 10.0 < ePct) {

				sTheString[i] = '=';
				eCnt += 10.0;
			}
		}
	}

	//return eBar;
}

stock String:MenuExperienceBar(client, currXP = -1, nextXP = -1) {

	decl String:eBar[256];
	new Float:ePct = 0.0;
	if (currXP == -1) currXP = ExperienceLevel[client];
	if (nextXP == -1) nextXP = CheckExperienceRequirement(client);
	ePct = ((currXP * 1.0) / (nextXP * 1.0)) * 100.0;

	new Float:eCnt = 0.0;
	Format(eBar, sizeof(eBar), "[----------]");

	for (new i = 1; i + 1 <= strlen(eBar); i++) {

		if (eCnt < ePct) {

			eBar[i] = '=';
			eCnt += 10.0;
		}
	}

	return eBar;
}

stock ChangeInfectedClass(client, zombieclass) {

	if (IsLegitimateClient(client) && !IsFakeClient(client) || IsLegitimateClientAlive(client) && IsFakeClient(client)) {

		if (GetClientTeam(client) == TEAM_INFECTED) {

			if (!IsGhost(client)) SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
			new wi;
			while ((wi = GetPlayerWeaponSlot(client, 0)) != -1) {

				RemovePlayerItem(client, wi);
				AcceptEntityInput(wi, "Kill");
			}
			SDKCall(g_hSetClass, client, zombieclass);
			AcceptEntityInput(MakeCompatEntRef(GetEntProp(client, Prop_Send, "m_customAbility")), "Kill");
			if (IsPlayerAlive(client)) SetEntProp(client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_hCreateAbility, client), g_oAbility));
			if (!IsGhost(client))
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);		// client can be killed again.
				SpeedMultiplier[client] = 1.0;		// defaulting the speed. It'll get modified in speed modifer spawn talents.
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[client]);

				GetAbilityStrengthByTrigger(client, _, 'a', FindZombieClass(client), 0);	// activator, target, trigger ability, effects, zombieclass, damage
			}
		}
	}
}

public Action:CMD_TeamChatCommand(client, args) {

	if (QuickCommandAccess(client, args, true)) {

		// Set colors for chat
		if (ChatTrigger(client, args, true)) return Plugin_Continue;
		else return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:CMD_ChatCommand(client, args) {

	if (QuickCommandAccess(client, args, false)) {

		// Set Colors for chat
		if (ChatTrigger(client, args, false)) return Plugin_Continue;
		else return Plugin_Handled;
	}
	return Plugin_Handled;
}

stock CartelLevel(client) {

	new CartelStrength = GetTalentStrength(client, "constitution") + GetTalentStrength(client, "agility") + GetTalentStrength(client, "resilience") + GetTalentStrength(client, "technique") + GetTalentStrength(client, "endurance") + GetTalentStrength(client, "luck");
	return CartelStrength;
}

public bool:ChatTrigger(client, args, bool:teamOnly) {

	if (!IsLegitimateClient(client) || StrEqual(ActiveClass[client], "none")) return true;
	decl String:sBuffer[MAX_CHAT_LENGTH];
	decl String:Message[MAX_CHAT_LENGTH];
	decl String:Name[64];

	decl String:authString[64];
	GetClientAuthString(client, authString, sizeof(authString));

	GetClientName(client, Name, sizeof(Name));
	GetCmdArg(1, sBuffer, sizeof(sBuffer));
	//StripQuotes(sBuffer);
	//if (StrEqual(sBuffer, LastSpoken[client], false)) return false;
	Format(LastSpoken[client], sizeof(LastSpoken[]), "%s", sBuffer);
	//if (GetClientTeam(client) == TEAM_SPECTATOR) return true;

	decl String:TagColour[64];
	decl String:TagName[64];
	decl String:ChatColour[64];

	//new InfectedLevelType = iBotLevelType;

	if (GetArraySize(Handle:ChatSettings[client]) != 3) {

		ResizeArray(ChatSettings[client], 3);
		Format(TagColour, sizeof(TagColour), "none");
		Format(TagName, sizeof(TagName), "none");
		Format(ChatColour, sizeof(ChatColour), "none");
	}
	else {

		GetArrayString(Handle:ChatSettings[client], 0, TagColour, sizeof(TagColour));
		GetArrayString(Handle:ChatSettings[client], 1, TagName, sizeof(TagName));
		GetArrayString(Handle:ChatSettings[client], 2, ChatColour, sizeof(ChatColour));
	}
	if (StrEqual(TagColour, "none", false)) {

		Format(TagColour, sizeof(TagColour), "N");
		SetArrayString(Handle:ChatSettings[client], 0, TagColour);
	}
	if (!StrEqual(TagName, "none", false)) {

		//Format(Message, sizeof(Message), "{N}[{%s}%s{N}]", TagColour, TagName);
		Format(Message, sizeof(Message), "{%s}%s", TagColour, TagName);
	}
	else {

		GetClientName(client, Message, sizeof(Message));
		Format(Message, sizeof(Message), "{%s}%s", TagColour, Message);
	}
	if (StrEqual(ChatColour, "none", false)) {

		Format(ChatColour, sizeof(ChatColour), "N");
		SetArrayString(Handle:ChatSettings[client], 2, ChatColour);
	}

	if (iRPGMode > 0) {

		decl String:theclassname[64];
		Format(theclassname, sizeof(theclassname), "%T", ActiveClass[client], client);

		if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Message, sizeof(Message), "{N}({B}TLv.%d{N})({B}%s Lv.%s{N}) %s", PlayerLevel[client], theclassname, AddCommasToString(CartelLevel(client)), Message);
		else if (GetClientTeam(client) == TEAM_INFECTED) Format(Message, sizeof(Message), "{N}({R}TLv.%d{N})({R}%s Lv.%s{N}) %s", PlayerLevel[client], theclassname, AddCommasToString(CartelLevel(client)), Message);
		else if (GetClientTeam(client) == TEAM_SPECTATOR) Format(Message, sizeof(Message), "{N}({GRA}TLv.%d{N})({GRA}%s Lv.%s{N}) %s", PlayerLevel[client], theclassname, AddCommasToString(CartelLevel(client)), Message);

		if (SkyLevel[client] >= 1) Format(Message, sizeof(Message), "{N}({B}SLv.%d{N})%s", SkyLevel[client], Message);
	}

	Format(sBuffer, sizeof(sBuffer), "{N}-> {%s}%s", ChatColour, sBuffer);

	if (GetClientTeam(client) == TEAM_SPECTATOR) Format(Message, sizeof(Message), "{N}[{GRA}SPEC{N}] %s", Message);
	else {

		if (IsGhost(client)) Format(Message, sizeof(Message), "{N}[{B}ghost{N}] %s", Message);
		else if (!IsPlayerAlive(client)) {

			if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Message, sizeof(Message), "{N}[{B}DEAD{N}] %s", Message);
			else Format(Message, sizeof(Message), "{N}[{R}DEAD{N}] %s", Message);
		}
		else if (IsIncapacitated(client)) Format(Message, sizeof(Message), "{N}[{B}INCAP{N}] %s", Message);
	}
	if (teamOnly) {

		if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Message, sizeof(Message), "{N}[{B}TEAM{N}] %s", Message);
		else if (GetClientTeam(client) == TEAM_INFECTED) Format(Message, sizeof(Message), "{N}[{R}TEAM{N}] %s", Message);
		Format(Message, sizeof(Message), "%s %s", Message, sBuffer);
		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i) && GetClientTeam(i) == GetClientTeam(client)) {

				/*if (GetClientTeam(client) == TEAM_SPECTATOR && !StrEqual(Spectator_LastChatUser, authString, false) ||
					GetClientTeam(client) == TEAM_SURVIVOR && !StrEqual(Survivor_LastChatUser, authString, false) ||
					GetClientTeam(client) == TEAM_INFECTED && !StrEqual(Infected_LastChatUser, authString, false)) {

					Client_PrintToChat(i, true, Message);
				}*/
				Client_PrintToChat(i, true, Message);
			}
		}
		if (GetClientTeam(client) == TEAM_SPECTATOR) Format(Spectator_LastChatUser, sizeof(Spectator_LastChatUser), "%s", authString);
		else if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Survivor_LastChatUser, sizeof(Survivor_LastChatUser), "%s", authString);
		else if (GetClientTeam(client) == TEAM_INFECTED) Format(Infected_LastChatUser, sizeof(Infected_LastChatUser), "%s", authString);
	}
	else {

		Format(Message, sizeof(Message), "%s %s", Message, sBuffer);

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i)) {

				/*if (!StrEqual(Public_LastChatUser, authString, false)) {

					Client_PrintToChat(i, true, Message);
				}*/
				Client_PrintToChat(i, true, Message);
			}
		}
		//Format(Public_LastChatUser, sizeof(Public_LastChatUser), "%s", authString);
	}
	return false;
}

stock GetTargetClient(client, String:TargetName[]) {

	decl String:Name[64];
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && i != client && GetClientTeam(i) == GetClientTeam(client)) {

			GetClientName(i, Name, sizeof(Name));
			if (StrContains(Name, TargetName, false) != -1) {

				// The name the player entered has been found, is a member of their team.
				//PrintToChatAll("Found %s , client %d", Name, i);
				return i;
			}
			/*else {

				PrintToChatAll("String: %s CLIENT NAME: %s CLIENT ID: %d", TargetName, Name, i);
			}*/
		}
	}
	return -1;
}

stock TeamworkRewardNotification(client, target, Float:PointCost, String:ItemName[]) {

	// Client is the user who purchased the item.
	// Target is the user who received it the item.
	// PointCost is the actual price the client paid - to determine their experience reward.

	if (client == target || b_IsFinaleActive) return;
	if (PointCost > fTeamworkExperience) PointCost = fTeamworkExperience;
	// there's no teamwork in 'i'
	new experienceReward	= RoundToCeil(PointCost * (fItemMultiplierTeam * (GetRandomInt(1, GetTalentStrength(client, "luck")) * fItemMultiplierLuck)));

	decl String:ClientName[MAX_NAME_LENGTH];
	GetClientName(client, ClientName, sizeof(ClientName));
	decl String:ItemName_s[64];
	Format(ItemName_s, sizeof(ItemName_s), "%T", ItemName, target);

	PrintToChat(target, "%T", "received item from teammate", target, green, ItemName_s, white, blue, ClientName);
	// {1}{2} {3}purchased and given to you by {4}{5}

	Format(ItemName_s, sizeof(ItemName_s), "%T", ItemName, client);
	GetClientName(target, ClientName, sizeof(ClientName));
	PrintToChat(client, "%T", "teamwork reward notification", client, green, ClientName, white, blue, ItemName_s, white, green, experienceReward);
	// {1}{2} {3}has received {4}{5}{6}: {7}{8}

	ExperienceLevel[client] += experienceReward;
	ExperienceOverall[client] += experienceReward;
	ConfirmExperienceAction(client);
}

stock GetActiveWeaponSlot(client) {

	decl String:Weapon[64];
	GetClientWeapon(client, Weapon, sizeof(Weapon));
	if (StrEqual(Weapon, "weapon_melee", false) || StrContains(Weapon, "pistol", false) != -1 || StrContains(Weapon, "chainsaw", false) != -1) return 1;
	return 0;
}

public Action:CMD_FireSword(client, args) {

	decl String:Weapon[64];
	new g_iActiveWeaponOffset = 0;
	new iWeapon = 0;
	GetClientWeapon(client, Weapon, sizeof(Weapon));
	if (StrEqual(Weapon, "weapon_melee", false)) {

		g_iActiveWeaponOffset = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
		iWeapon = GetEntDataEnt2(client, g_iActiveWeaponOffset);
	}
	else {

		if (StrContains(Weapon, "pistol", false) == -1) iWeapon = GetPlayerWeaponSlot(client, 0);
		else iWeapon = GetPlayerWeaponSlot(client, 1);
	}

	if (IsValidEntity(iWeapon)) {

		ExtinguishEntity(iWeapon);
		IgniteEntity(iWeapon, 30.0);
	}
}

public Action:CMD_LoadoutName(client, args) {

	if (args < 1) {

		PrintToChat(client, "!loadoutname <name identifier>");
		return Plugin_Handled;
	}
	GetCmdArg(1, LoadoutName[client], sizeof(LoadoutName[]));
	if (strlen(LoadoutName[client]) < 4) {

		PrintToChat(client, "loadout name must be >= 4 chars.");
		return Plugin_Handled;
	}
	if (StrContains(LoadoutName[client], "SavedProfile", false) != -1) {

		PrintToChat(client, "invalid loadout name, try again.");
		return Plugin_Handled;
	}
	ReplaceString(LoadoutName[client], sizeof(LoadoutName[]), "+", " ");	// this way the delimiter only shows where it's supposed to.
	SQL_EscapeString(Handle:hDatabase, LoadoutName[client], LoadoutName[client], sizeof(LoadoutName[]));
	Format(LoadoutName[client], sizeof(LoadoutName[]), "%s", LoadoutName[client]);
	PrintToChat(client, "%T", "loadout name set", client, orange, green, LoadoutName[client]);
	return Plugin_Handled;
}

public Action:CMD_TalentUpgrade(client, args) {

	if (args < 2)
	{
		PrintToChat(client, "!talentupgrade <idcode> <value>");
		return Plugin_Handled;
	}
	if (FreeUpgrades[client] < 1) FreeUpgrades[client] = 0;
	decl String:TalentName[64];
	new bool:bIsRefund = false;

	decl String:arg[64];
	decl String:idNum[64];
	GetCmdArg(1, idNum, sizeof(idNum));
	GetCmdArg(2, arg, sizeof(arg));
	new value = StringToInt(arg);

	if (value < 0) {

		value *= -1;
		bIsRefund = true;
	}
	decl String:StringComp[64];
	new size = GetArraySize(a_Menu_Talents);
	for (new i = 0; i < size; i++) {

		TalentUpgradeKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
		TalentUpgradeValues[client]			= GetArrayCell(a_Menu_Talents, i, 1);
		if (GetKeyValueInt(TalentUpgradeKeys[client], TalentUpgradeValues[client], "is sub menu?") == 1) continue;

		TalentUpgradeSection[client]		= GetArrayCell(a_Menu_Talents, i, 2);
		if (GetKeyValueInt(TalentUpgradeKeys[client], TalentUpgradeValues[client], "talent type?") == 1) continue;

		GetArrayString(Handle:TalentUpgradeSection[client], 0, TalentName, sizeof(TalentName));
		FormatKeyValue(StringComp, sizeof(StringComp), TalentUpgradeKeys[client], TalentUpgradeValues[client], "id_number");
		if (!StrEqual(StringComp, idNum, false)) continue;

		if (!bIsRefund) {

			if (FreeUpgrades[client] >= value && GetTalentStrength(client, TalentName) + value <= GetKeyValueInt(TalentUpgradeKeys[client], TalentUpgradeValues[client], "maximum talent points allowed?")) {

				PlayerUpgradesTotal[client] += value;
				PurchaseTalentPoints[client] += value;
				FreeUpgrades[client] -= value;
				AddTalentPoints(client, TalentName, GetTalentStrength(client, TalentName) + value);
				return Plugin_Handled;
			}
		}
		else {

			if (value > GetTalentStrength(client, TalentName)) value = GetTalentStrength(client, TalentName);
			AddTalentPoints(client, TalentName, GetTalentStrength(client, TalentName) - value);
			FreeUpgrades[client] += value;
			PlayerUpgradesTotal[client] -= value;
			PurchaseTalentPoints[client] -= value;
			return Plugin_Handled;
		}
	}
	if (FreeUpgrades[client] < 0) FreeUpgrades[client] = 0;
	return Plugin_Handled;
}

stock Float:GetMissingHealth(client) {

	return ((GetClientHealth(client) * 1.0) / (GetMaximumHealth(client) * 1.0));
}

stock bool:QuickCommandAccess(client, args, bool:b_IsTeamOnly) {

	if (IsLegitimateClient(client) && GetClientTeam(client) != TEAM_SPECTATOR) CMD_CastAction(client, args);
	decl String:Command[64];
	GetCmdArg(1, Command, sizeof(Command));
	StripQuotes(Command);
	if (Command[0] != '/' && Command[0] != '!') return true;

	return QuickCommandAccessEx(client, Command, b_IsTeamOnly);
}

stock bool:QuickCommandAccessEx(client, String:sCommand[], bool:b_IsTeamOnly = false, bool:bGiveProfileItem = false, bool:bIsItemExists = false) {

	new TargetClient = -1;
	decl String:SplitCommand[2][64];
	decl String:Command[64];
	Format(Command, sizeof(Command), "%s", sCommand);
	if (!bIsItemExists && !bGiveProfileItem && StrContains(Command, " ", false) != -1) {

		ExplodeString(Command, " ", SplitCommand, 2, 64);
		Format(Command, sizeof(Command), "%s", SplitCommand[0]);
		TargetClient	 = GetTargetClient(client, SplitCommand[1]);
		if (StrContains(Command, "revive", false) != -1 && TargetClient != client) return false;
	//	if (StrContains(Command, "@") != -1 && HasCommandAccess(client, GetConfigValue("reload configs flags?"))) {

		//	if (StrContains(Command, "commons", true) != -1) WipeAllCommons();
			//else if (StrContains(Command, "supercommons", true) != -1) WipeAllCommons(true);
		//}
	}

	decl String:text[512];
	decl String:cost[64];
	decl String:bind[64];
	decl String:pointtext[64];
	decl String:description[512];
	decl String:team[64];
	decl String:CheatCommand[64];
	decl String:CheatParameter[64];
	decl String:Model[64];
	decl String:Count[64];
	decl String:CountHandicap[64];
	decl String:Drop[64];
	new Float:PointCost		= 0.0;
	new Float:PointCostM	= 0.0;
	decl String:MenuName[64];
	new Float:f_GetMissingHealth = 1.0;

	new size					=	0;
	decl String:Description_Old[512];
	decl String:ItemName[64];
	decl String:IsRespawn[64];
	new RemoveClient = -1;
	new iWeaponCat = -1;
	new iTargetClient = -1;

	//if (StringToInt(GetConfigValue("rpg mode?")) != 1) BuyItem(client, Command[1]);

	if ((iRPGMode != 1 || !b_IsActiveRound || bIsItemExists || bGiveProfileItem) && iRPGMode >= 0) {

		//GetConfigValue(thetext, sizeof(thetext), "quick bind help?");

		if (StrEqual(Command[1], sQuickBindHelp, false)) {

			size						=	GetArraySize(a_Points);

			for (new i = 0; i < size; i++) {

				MenuKeys[client]		=	GetArrayCell(a_Points, i, 0);
				MenuValues[client]		=	GetArrayCell(a_Points, i, 1);

				//size2					=	GetArraySize(MenuKeys[client]);

				PointCost				= GetKeyValueFloat(MenuKeys[client], MenuValues[client], "point cost?");
				if (PointCost < 0.0) continue;

				PointCostM				= GetKeyValueFloat(MenuKeys[client], MenuValues[client], "point cost minimum?");
				FormatKeyValue(bind, sizeof(bind), MenuKeys[client], MenuValues[client], "quick bind?");
				Format(bind, sizeof(bind), "!%s", bind);
				FormatKeyValue(description, sizeof(description), MenuKeys[client], MenuValues[client], "description?");
				Format(description, sizeof(description), "%T", description, client);
				FormatKeyValue(team, sizeof(team), MenuKeys[client], MenuValues[client], "team?");

				/*
						
						Determine the actual cost for the player.
				*/
				
				if (Points[client] == 0.0 || Points[client] > 0.0 && (Points[client] * PointCost) < PointCostM) PointCost = PointCostM;
				else {

					PointCost += (PointCost * fPointsCostLevel);
					if (PointCost > 1.0) PointCost = 1.0;
					PointCost *= Points[client];
				}
				Format(cost, sizeof(cost), "%3.3f", PointCost);
				

				if (StringToInt(team) != GetClientTeam(client)) continue;
				Format(pointtext, sizeof(pointtext), "%T", "Points", client);
				Format(pointtext, sizeof(pointtext), "%s %s", cost, pointtext);

				Format(text, sizeof(text), "%T", "Command Information", client, orange, bind, white, green, pointtext, white, blue, description);
				if (StrEqual(Description_Old, bind, false)) continue;		// in case there are duplicates
				Format(Description_Old, sizeof(Description_Old), "%s", bind);
				PrintToConsole(client, text);
			}
			PrintToChat(client, "%T", "Commands Listed Console", client, orange, white, green);
		}
		else {

			size						=	GetArraySize(a_Points);

			new iPreGameFree			=	0;

			for (new i = 0; i < size; i++) {

				MenuKeys[client]		=	GetArrayCell(a_Points, i, 0);
				MenuValues[client]		=	GetArrayCell(a_Points, i, 1);
				MenuSection[client]		=	GetArrayCell(a_Points, i, 2);

				GetArrayString(Handle:MenuSection[client], 0, ItemName, sizeof(ItemName));

				PointCost		= GetKeyValueFloat(MenuKeys[client], MenuValues[client], "point cost?");
				PointCostM		= GetKeyValueFloat(MenuKeys[client], MenuValues[client], "point cost minimum?");
				FormatKeyValue(bind, sizeof(bind), MenuKeys[client], MenuValues[client], "quick bind?");
				FormatKeyValue(team, sizeof(team), MenuKeys[client], MenuValues[client], "team?");
				FormatKeyValue(CheatCommand, sizeof(CheatCommand), MenuKeys[client], MenuValues[client], "command?");
				FormatKeyValue(CheatParameter, sizeof(CheatParameter), MenuKeys[client], MenuValues[client], "parameter?");

				if (bIsItemExists && StrEqual(Command, ItemName)) return true;

				iWeaponCat = GetKeyValueInt(MenuKeys[client], MenuValues[client], "weapon category?");
				if (bGiveProfileItem) {

					if (StrEqual(Command, ItemName)) {

						if (iWeaponCat == 0) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Primary);
						else if (iWeaponCat == 1) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);

						if (!StrEqual(CheatCommand, "melee")) ExecCheatCommand(client, CheatCommand, CheatParameter);
						else {

							new ent			= CreateEntityByName("weapon_melee");

							DispatchKeyValue(ent, "melee_script_name", CheatParameter);
							DispatchSpawn(ent);

							EquipPlayerWeapon(client, ent);
						}
						return true;
					}
					continue;
				}



				FormatKeyValue(Model, sizeof(Model), MenuKeys[client], MenuValues[client], "model?");
				FormatKeyValue(Count, sizeof(Count), MenuKeys[client], MenuValues[client], "count?");
				FormatKeyValue(CountHandicap, sizeof(CountHandicap), MenuKeys[client], MenuValues[client], "count handicap?");
				FormatKeyValue(Drop, sizeof(Drop), MenuKeys[client], MenuValues[client], "drop?");
				FormatKeyValue(MenuName, sizeof(MenuName), MenuKeys[client], MenuValues[client], "part of menu named?");
				FormatKeyValue(IsRespawn, sizeof(IsRespawn), MenuKeys[client], MenuValues[client], "isrespawn?");
				iPreGameFree = GetKeyValueInt(MenuKeys[client], MenuValues[client], "pre-game free?");

				if (StrEqual(Command[1], bind, false) && StringToInt(team) == GetClientTeam(client)) {		// we found the bind the player used, and the player is on the appropriate team.

					if (StringToInt(IsRespawn) == 1) {

						if (TargetClient == -1) {

							if (!b_HasDeathLocation[client] || IsPlayerAlive(client) || IsEnrageActive()) return false;
						}
						if (TargetClient != -1) {

							if (IsPlayerAlive(TargetClient) || IsEnrageActive()) return false;
						}
					}
					if (TargetClient != -1 && IsPlayerAlive(TargetClient)) {

						if (IsIncapacitated(TargetClient)) f_GetMissingHealth	= 0.0;	// Player is incapped, has no missing life.
						else f_GetMissingHealth	= GetMissingHealth(TargetClient);
					}

					new ExperienceCost			=	0;
					new TargetClient_s			=	0;

					if (FindCharInString(CheatCommand, ':') != -1) {

						BuildPointsMenu(client, CheatCommand[1], CONFIG_POINTS);		// Always CONFIG_POINTS for quick commands
					}
					else {

						if (GetClientTeam(client) == TEAM_INFECTED) {

							if (StringToInt(CheatParameter) == 8 && ActiveTanks() >= iTankLimitVersus) {

								PrintToChat(client, "%T", "Tank Limit Reached", client, orange, green, iTankLimitVersus, white);
								return false;
							}
							else if (StringToInt(CheatParameter) == 8 && f_TankCooldown != -1.0) {

								PrintToChat(client, "%T", "Tank On Cooldown", client, orange, white);
								return false;
							}
						}
						if (Points[client] == 0.0 || Points[client] > 0.0 && (Points[client] * PointCost) < PointCostM) PointCost = PointCostM;
						else PointCost *= Points[client];

						if (Points[client] >= PointCost ||
							PointCost == 0.0 ||
							(!b_IsActiveRound && iPreGameFree == 1) ||
							GetClientTeam(client) == TEAM_INFECTED && StrEqual(CheatCommand, "change class", false) && StringToInt(CheatParameter) != 8 && (TargetClient == -1 && IsGhost(client) || TargetClient != -1 && IsGhost(TargetClient))) {

							if (!StrEqual(CheatCommand, "change class") ||
								StrEqual(CheatCommand, "change class") && StrEqual(CheatParameter, "8") ||
								StrEqual(CheatCommand, "change class") && (TargetClient == -1 && IsPlayerAlive(client) && !IsGhost(client) || TargetClient != -1 && IsPlayerAlive(TargetClient) && !IsGhost(TargetClient))) {

								if (PointPurchaseType == 0 && (Points[client] >= PointCost || PointCost == 0.0 || (!b_IsActiveRound && iPreGameFree == 1))) {

									if (PointCost > 0.0 && Points[client] >= PointCost || PointCost <= 0.0) {

										if (iPreGameFree != 1 || b_IsActiveRound) Points[client] -= PointCost;
									}
								}
								else if (PointPurchaseType == 1 && (ExperienceLevel[client] >= ExperienceCost || ExperienceCost == 0)) ExperienceLevel[client] -= ExperienceCost;
							}

							if (StrEqual(CheatParameter, "common") && StrContains(Model, ".mdl", false) != -1) {

								Format(Count, sizeof(Count), "%d", StringToInt(Count) + (StringToInt(CountHandicap) * LivingSurvivorCount()));

								for (new iii = StringToInt(Count); iii > 0 && GetArraySize(CommonInfectedQueue) < iCommonQueueLimit; iii--) {

									if (StringToInt(Drop) == 1) {

										ResizeArray(Handle:CommonInfectedQueue, GetArraySize(Handle:CommonInfectedQueue) + 1);
										ShiftArrayUp(Handle:CommonInfectedQueue, 0);
										SetArrayString(Handle:CommonInfectedQueue, 0, Model);
										TargetClient_s		=	FindLivingSurvivor();
										if (TargetClient_s > 0) ExecCheatCommand(TargetClient_s, CheatCommand, CheatParameter);
									}
									else PushArrayString(Handle:CommonInfectedQueue, Model);
								}
							}
							else if (StrEqual(CheatCommand, "change class")) {

								// We don't give them points back if ghost because we don't take points if ghost.
								//if (IsGhost(client) && PointPurchaseType == 0) Points[client] += PointCost;
								//else if (IsGhost(client) && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
								if ((!IsGhost(client) && FindZombieClass(client) == ZOMBIECLASS_TANK && TargetClient == -1 ||
									TargetClient != -1 && !IsGhost(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_TANK) && PointPurchaseType == 0) Points[client] += PointCost;
								else if ((!IsGhost(client) && FindZombieClass(client) == ZOMBIECLASS_TANK && TargetClient == -1 || TargetClient != -1 && !IsGhost(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_TANK) && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
								else if ((!IsGhost(client) && IsPlayerAlive(client) && FindZombieClass(client) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(client) != -1 && TargetClient == -1 ||
										  TargetClient != -1 && !IsGhost(TargetClient) && IsPlayerAlive(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(TargetClient) == -1) && PointPurchaseType == 0) Points[client] += PointCost;
								else if ((!IsGhost(client) && IsPlayerAlive(client) && FindZombieClass(client) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(client) != -1 && TargetClient == -1 ||
										  TargetClient != -1 && !IsGhost(TargetClient) && IsPlayerAlive(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(TargetClient) == -1) && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
								if (FindZombieClass(client) != ZOMBIECLASS_TANK && TargetClient == -1 || TargetClient != -1 && FindZombieClass(TargetClient) != ZOMBIECLASS_TANK) {

									if (TargetClient == -1) ChangeInfectedClass(client, StringToInt(CheatParameter));
									else ChangeInfectedClass(TargetClient, StringToInt(CheatParameter));

									if (TargetClient != -1) TeamworkRewardNotification(client, TargetClient, PointCost, ItemName);
								}
							}
							else if (StringToInt(IsRespawn) == 1) {

								if (TargetClient == -1 && !IsPlayerAlive(client) && b_HasDeathLocation[client]) {

									SDKCall(hRoundRespawn, client);
									b_HasDeathLocation[client] = false;
									CreateTimer(1.0, Timer_TeleportRespawn, client, TIMER_FLAG_NO_MAPCHANGE);
								}
								else if (TargetClient != -1 && !IsPlayerAlive(TargetClient) && b_HasDeathLocation[TargetClient]) {

									SDKCall(hRoundRespawn, TargetClient);
									b_HasDeathLocation[TargetClient] = false;
									CreateTimer(1.0, Timer_TeleportRespawn, TargetClient, TIMER_FLAG_NO_MAPCHANGE);

									TeamworkRewardNotification(client, TargetClient, PointCost, ItemName);
								}
							}
							else {

								//CheckIfRemoveWeapon(client, CheatParameter);
								RemoveClient = client;
								if (IsLegitimateClientAlive(TargetClient)) RemoveClient = TargetClient;
								if ((PointCost == 0.0 || (iPreGameFree == 1 && !b_IsActiveRound)) && GetClientTeam(RemoveClient) == TEAM_SURVIVOR) {

									// there is no code here to give a player a FREE weapon forcefully because that would be fucked up. TargetClient just gets ignored here.
									if (StrContains(CheatParameter, "pistol", false) != -1 || IsMeleeWeaponParameter(CheatParameter)) L4D_RemoveWeaponSlot(RemoveClient, L4DWeaponSlot_Secondary);
									else L4D_RemoveWeaponSlot(RemoveClient, L4DWeaponSlot_Primary);
								}
								if (IsMeleeWeaponParameter(CheatParameter)) {

									// Get rid of their old weapon
									if (TargetClient == -1)	L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
									else L4D_RemoveWeaponSlot(TargetClient, L4DWeaponSlot_Secondary);

									new ent			= CreateEntityByName("weapon_melee");

									DispatchKeyValue(ent, "melee_script_name", CheatParameter);
									DispatchSpawn(ent);

									if (TargetClient == -1) EquipPlayerWeapon(client, ent);
									else EquipPlayerWeapon(TargetClient, ent);
								}
								else {

									if (StrContains(CheatParameter, "pistol", false) != -1) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
									else if (iWeaponCat >= 0 && iWeaponCat <= 1) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Primary);

									if (TargetClient == -1) {

										iTargetClient = client;

										if (StrEqual(CheatParameter, "health")) {

											if (L4D2_GetInfectedAttacker(client) != -1) Points[client] += PointCost;
											else {

												ExecCheatCommand(client, CheatCommand, CheatParameter);
												GiveMaximumHealth(client);		// So instant heal doesn't put a player above their maximum health pool.
											}
										}
										else ExecCheatCommand(client, CheatCommand, CheatParameter);
									}
									else {

										iTargetClient = TargetClient;

										if (StrEqual(CheatParameter, "health")) {

											if (L4D2_GetInfectedAttacker(TargetClient) != -1 || f_GetMissingHealth > fHealRequirementTeam) Points[client] += PointCost;
											else {

												ExecCheatCommand(TargetClient, CheatCommand, CheatParameter);
												GiveMaximumHealth(TargetClient);		// So instant heal doesn't put a player above their maximum health pool.
											}
										}
										else ExecCheatCommand(TargetClient, CheatCommand, CheatParameter);
									}
									if (StrContains(CheatParameter, "pistol", false) != -1 && StrContains(CheatParameter, "magnum", false) == -1) {

										CreateTimer(0.5, Timer_GiveSecondPistol, iTargetClient, TIMER_FLAG_NO_MAPCHANGE);
									}
									if (iWeaponCat == 0 && SkyLevel[client] > 0) CreateTimer(0.5, Timer_GiveLaserBeam, iTargetClient, TIMER_FLAG_NO_MAPCHANGE);
								}
								if (TargetClient != -1) {

									if (StrEqual(CheatParameter, "health", false) && L4D2_GetInfectedAttacker(TargetClient) == -1 && f_GetMissingHealth <= fHealRequirementTeam || !StrEqual(CheatParameter, "health", false)) {

										if (StrEqual(CheatParameter, "health", false)) TeamworkRewardNotification(client, TargetClient, PointCost * (1.0 - f_GetMissingHealth), ItemName);
										else TeamworkRewardNotification(client, TargetClient, PointCost, ItemName);
									}
								}
							}
							//if (TargetClient != -1) LogMessage("%N bought %s for %N", client, CheatParameter, TargetClient);
						}
						else {

							if (PointPurchaseType == 0) PrintToChat(client, "%T", "Not Enough Points", client, orange, white, PointCost);
							else if (PointPurchaseType == 1) PrintToChat(client, "%T", "Not Enough Experience", client, orange, white, ExperienceCost);
						}
					}
					break;
				}
			}
			if (bIsItemExists) return false;
		}
	}
	if (Command[0] == '!') return true;
	return false;
}

stock LoadHealthMaximum(client) {

	if (GetClientTeam(client) == TEAM_INFECTED) DefaultHealth[client] = GetClientHealth(client);
	else {

		if (!IsFakeClient(client)) DefaultHealth[client] = iSurvivorBaseHealth;	// 100 is the default. no reason to think otherwise.
		else DefaultHealth[client] = iSurvivorBotBaseHealth;
	}

	// testing new system
	GetAbilityStrengthByTrigger(client, _, 'a', FindZombieClass(client), 0);	// activator, target, trigger ability, effects, zombieclass, damage
}

stock SetSpeedMultiplierBase(attacker, Float:amount = 1.0) {

	if (GetClientTeam(attacker) == TEAM_SURVIVOR || IsSurvivorBot(attacker)) SetEntPropFloat(attacker, Prop_Send, "m_flLaggedMovementValue", fBaseMovementSpeed);
	else SetEntPropFloat(attacker, Prop_Send, "m_flLaggedMovementValue", amount);
}

stock PlayerSpawnAbilityTrigger(attacker) {

	if (IsLegitimateClientAlive(attacker)) {

		TankState[attacker] = TANKSTATE_TIRED;

		SetSpeedMultiplierBase(attacker);

		SpeedMultiplier[attacker] = SpeedMultiplierBase[attacker];		// defaulting the speed. It'll get modified in speed modifer spawn talents.
		
		if (GetClientTeam(attacker) == TEAM_INFECTED) DefaultHealth[attacker] = GetClientHealth(attacker);
		else {

			if (!IsFakeClient(attacker)) DefaultHealth[attacker] = iSurvivorBaseHealth;
			else DefaultHealth[attacker] = iSurvivorBotBaseHealth;
		}
		b_IsImmune[attacker] = false;

		GetAbilityStrengthByTrigger(attacker, _, 'a', FindZombieClass(attacker), 0);
		if (GetClientTeam(attacker) != TEAM_SURVIVOR && !IsSurvivorBot(attacker)) {

			GiveMaximumHealth(attacker);
			CreateMyHealthPool(attacker);		// when the infected spawns, if there are any human players, they'll automatically be added to their pools to ensure that bots don't one-shot them.
		}
	}
}

stock bool:NoHumanInfected() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED) return false;
	}

	return true;
}

stock InfectedBotSpawn(client) {

	//new Float:HealthBonus = 0.0;
	//new Float:SpeedBonus = 0.0;

	if (IsLegitimateClient(client)) {

		/*

			In the new health adjustment system, it is based on the number of living players as well as their total level.
			Health bonus is multiplied by the number of total levels of players alive in the session.
		*/
		/*decl String:InfectedHealthBonusType[64];
		Format(InfectedHealthBonusType, sizeof(InfectedHealthBonusType), "(%d) infected health bonus", FindZombieClass(client));
		HealthBonus = StringToFloat(GetConfigValue(InfectedHealthBonusType)) * (SurvivorLevels() * 1.0);*/

		//GetAbilityStrengthByTrigger(client, _, 'a', 0, 0);
	}
}

stock TruRating(client) {

	new TrueRating = RatingPerLevel;
	if (RatingHandicap[client] > TrueRating) TrueRating = RatingHandicap[client];
	//TrueRating *= PlayerLevel[client];
	TrueRating *= CartelLevel(client);
	TrueRating += Rating[client];
	return TrueRating;
}

stock bool:CheckServerLevelRequirements(client) {

	if (iServerLevelRequirement > 0) {

		if (IsFakeClient(client)) {

			if (IsSurvivorBot(client) && PlayerLevel[client] < iServerLevelRequirement) SetTotalExperienceByLevel(client, iServerLevelRequirement);
			return true;
		}
		LogMessage("Level required to enter is %s and %N is %s", AddCommasToString(iServerLevelRequirement), client, AddCommasToString(PlayerLevel[client]));
	}
	if (IsFakeClient(client)) return true;
	decl String:LevelKickMessage[128];
	if (iServerLevelRequirement == -2 && !IsGroupMember[client]) {

		// some servers can allow only steamgroup members to join.
		b_IsLoading[client] = true;
		Format(LevelKickMessage, sizeof(LevelKickMessage), "Only steamgroup members can access this server.");
		KickClient(client, LevelKickMessage);
		return false;
	}
	if (PlayerLevel[client] < iServerLevelRequirement) {

		b_IsLoading[client] = true;	// prevent saving data on kick

		Format(LevelKickMessage, sizeof(LevelKickMessage), "Your level: %s\nSorry, you must be level %s to enter this server.", AddCommasToString(PlayerLevel[client]), AddCommasToString(iServerLevelRequirement));
		KickClient(client, LevelKickMessage);
		return false;
	}
	else bIsSettingsCheck = true;
	//EnforceServerTalentMaximum(client);
	return true;
}

stock GetSpecialInfectedLimit(bool:IsTankLimit = false) {

	new speciallimit = 0;
	new Dividend = iRatingSpecialsRequired;
	if (IsTankLimit) Dividend = iRatingTanksRequired;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i))) {

			if (Rating[i] < 1) Rating[i] = 1;
			speciallimit += Rating[i];
		}
	}
	if (iIgnoredRating > 0) {

		new ignoredRating = TotalSurvivors() * iIgnoredRating;
		if (ignoredRating > iIgnoredRatingMax) ignoredRating = iIgnoredRatingMax;

		speciallimit -= ignoredRating;
		if (speciallimit < 0) speciallimit = 0;
	}
	speciallimit = RoundToCeil(speciallimit * 1.0 / Dividend * 1.0);
	if (speciallimit < 1) {

		if (b_IsFinaleActive) speciallimit = 2;
		else speciallimit = 1;
	}
	return speciallimit;
}

stock RaidCommonBoost(bool:bInfectedTalentStrength = false) {

	new fff = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i))) {

			if (Rating[i] < 1) Rating[i] = 1;
			fff += Rating[i];
		}
	}
	new Multiplier = RaidLevMult;
	if (bInfectedTalentStrength) Multiplier = InfectedTalentLevel;

	if (iIgnoredRating > 0) {

		new ignoredRating = TotalSurvivors() * iIgnoredRating;
		if (ignoredRating > iIgnoredRatingMax) ignoredRating = iIgnoredRatingMax;

		fff -= ignoredRating;
		if (fff < 0) fff = 0;
	}

	fff /= Multiplier;
	if (fff < 1) fff = 1;
	return fff;
}

stock HumanSurvivorLevels() {

	new fff = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

			if (Rating[i] < 1) Rating[i] = 1;
			fff += Rating[i];
		}
	}
	//if (StringToInt(GetConfigValue("infected bot level type?")) == 1) return f;	// player combined level
	//if (LivingHumanSurvivors() > 0) return f / LivingHumanSurvivors();
	if (iIgnoredRating > 0) {

		new ignoredRating = TotalSurvivors() * iIgnoredRating;
		if (ignoredRating > iIgnoredRatingMax) ignoredRating = iIgnoredRatingMax;

		fff -= ignoredRating;
		if (fff < 0) fff = 0;
	}
	return fff;
}

stock SurvivorLevels() {

	new fff = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i))) {

			if (Rating[i] < 1) Rating[i] = 1;
			fff += Rating[i];
		}
	}
	//if (StringToInt(GetConfigValue("infected bot level type?")) == 1) return f;	// player combined level
	//if (LivingHumanSurvivors() > 0) return f / LivingHumanSurvivors();
	if (iIgnoredRating > 0) {

		new ignoredRating = TotalSurvivors() * iIgnoredRating;
		if (ignoredRating > iIgnoredRatingMax) ignoredRating = iIgnoredRatingMax;

		fff -= ignoredRating;
		if (fff < 0) fff = 0;
	}
	return fff;
}

stock bool:IsLegitimateClient(client) {

	if (client < 1 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) return false;
	return true;
}

stock bool:IsLegitimateClientAlive(client) {

	if (IsLegitimateClient(client) && IsPlayerAlive(client)) return true;
	return false;
}

stock RaidInfectedBotLimit() {

	/*new count = LivingHumanSurvivors() + 1;
	new CurrInfectedLevel = SurvivorLevels();
	new RaidLevelRequirement = RaidLevMult;
	while (CurrInfectedLevel >= RaidLevelRequirement) {

		CurrInfectedLevel -= RaidLevelRequirement;
		count++;
	}
	new HumanInGame = HumanPlayersInGame();
	if (HumanInGame > 4) count = HumanInGame;*/

	bIsSettingsCheck = true;
	new count = GetSpecialInfectedLimit();

	ReadyUp_NtvHandicapChanged(count);
}

stock RefreshSurvivor(client, bool:IsUnhook = false) {

	if (IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR) {

		SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
		StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
		if (IsFakeClient(client)) {

			//SetMaximumHealth(client);
			//Rating[client] = 1;
			//PlayerLevel[client] = iPlayerStartingLevel;
		}
	}
}

public Action:Timer_CheckForExperienceDebt(Handle:timer, any:client) {

	if (!IsLegitimateClient(client)) return Plugin_Stop;
	return Plugin_Stop;
}

stock DeleteMeFromExistence(client) {

	new pos = -1;

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i)) continue;
		pos = FindListPositionByEntity(client, Handle:InfectedHealth[i]);
		if (pos >= 0) RemoveFromArray(InfectedHealth[i], pos);
	}
	ForcePlayerSuicide(client);
}

stock IncapacitateOrKill(client, attacker = 0, healthvalue = 0, bool:bIsFalling = false, bool:bIsLifelinkPenalty = false, bool:ForceKill = false) {

	if ((ForceKill || IsLegitimateClientAlive(client)) && (GetClientTeam(client) != TEAM_INFECTED || IsSurvivorBot(client))) {

		//new IncapCounter	= GetEntProp(client, Prop_Send, "m_currentReviveCount");
		if (ForceKill || IsIncapacitated(client) || bIsFalling && !IsLedged(client) || PlayerHasWeakness(client) || StrContains(ActiveClass[client], "death", false) != -1 || GetIncapCount(client) >= iMaxIncap) {

			decl String:PlayerName[64];
			decl String:PlayerID[64];
			if (!IsSurvivorBot(client)) {

				GetClientName(client, PlayerName, sizeof(PlayerName));
				GetClientAuthString(client, PlayerID, sizeof(PlayerID));
			}
			else {

				GetSurvivorBotName(client, PlayerName, sizeof(PlayerName));
				Format(PlayerID, sizeof(PlayerID), "%s%s", sBotTeam, PlayerName);
			}
			decl String:pct[4];
			Format(pct, sizeof(pct), "%");
			if (iRPGMode >= 0 && IsPlayerAlive(client)) {

				if (iIsLevelingPaused[client] == 1 || PlayerLevel[client] >= iMaxLevel || PlayerLevel[client] >= iHardcoreMode && fDeathPenalty > 0.0 && iDeathPenaltyPlayers > 0 && TotalHumanSurvivors() >= iDeathPenaltyPlayers) ConfirmExperienceActionTalents(client, true);

				if (iIsLevelingPaused[client] == 1 || PlayerLevel[client] >= iMaxLevel) {

					ExperienceOverall[client] -= (ExperienceLevel[client] - 1);
					ExperienceLevel[client] = 1;
				}

				new LivingHumansCounter = LivingSurvivors() - 1;
				if (LivingHumansCounter < 0) LivingHumansCounter = 0;

				PrintToChatAll("%t", "teammate has died", blue, PlayerName, orange, green, (LivingHumansCounter * fSurvivorExpMult) * 100.0, pct);
				if (RoundExperienceMultiplier[client] > 0.0) {

					PrintToChatAll("%t", "bonus container burst", blue, PlayerName, orange, green, 100.0 * RoundExperienceMultiplier[client], orange, pct);
					BonusContainer[client] = 0;
					RoundExperienceMultiplier[client] = 0.0;
				}
			} 

			decl String:text[512];
			decl String:ColumnName[64];
			//new TheGameMode = ReadyUp_GetGameMode();
			if (Rating[client] > BestRating[client]) {

				BestRating[client] = Rating[client];
				Format(ColumnName, sizeof(ColumnName), "%s", sDbLeaderboards);
				if (StrEqual(ColumnName, "-1")) {

					if (ReadyUpGameMode != 3) Format(ColumnName, sizeof(ColumnName), "%s", COOPRECORD_DB);
					else Format(ColumnName, sizeof(ColumnName), "%s", SURVRECORD_DB);
				}
				Format(text, sizeof(text), "UPDATE `%s` SET `%s` = '%d' WHERE `steam_id` = '%s';", TheDBPrefix, ColumnName, BestRating[client], PlayerID);
				SQL_TQuery(hDatabase, QueryResults, text, client);
			}
			//if (ReadyUpGameMode != 3)
			Rating[client] = (Rating[client] / 2) + 1;
			if (!IsSurvivorBot(client)) {

				decl String:MyName[64];
				GetClientName(client, MyName, sizeof(MyName));
				if (!CheckServerLevelRequirements(client)) {

					PrintToChatAll("%t", "player no longer eligible", blue, MyName, orange);
					return;
				}
			}
			RaidInfectedBotLimit();

			if (iIsLifelink == 1 && !bIsLifelinkPenalty) {	// prevents looping

				for (new i = 1; i <= MaxClients; i++) {

					if (IsLegitimateClientAlive(i) && (GetClientTeam(i) == TEAM_SURVIVOR || IsSurvivorBot(i))) IncapacitateOrKill(i, _, _, true, true);		// second true prevents this loop from being triggered by the function.
				}
			}

			//if (!bIsFalling) b_HasDeathLocation[client] = true;
			//else b_HasDeathLocation[client] = false;
			if (!ForceKill) {

				GetClientAbsOrigin(client, Float:DeathLocation[client]);
				b_HasDeathLocation[client] = true;
			}
			/*LogMessage("%N HAS DIED!!!", client);
			if (GetArraySize(Handle:InfectedHealth[client]) > 0 && IsSurvivorInAGroup(client)) {

				ClearArray(Handle:InfectedHealth[client]);	// infected get their health back when a player dies and the player gets no XP for their contributions.
				PenalizeGroupmates(client);
			}*/
			ForcePlayerSuicide(client);
			iThreatLevel[client] = 0;
			bIsGiveProfileItems[client] = true;		// so when the player returns to life, their weapon loadout for that profile will be given to them.
			MyBirthday[client] = 0;
			
			HealingContribution[client] = 0;
			DamageContribution[client] = 0;
			PointsContribution[client] = 0.0;
			TankingContribution[client] = 0;
			BuffingContribution[client] = 0;
			HexingContribution[client] = 0;

			bIsInCombat[client] = false;
			MyRespawnTarget[client] = client;
			//CreateTimer(1.0, Timer_CheckForExperienceDebt, client, TIMER_FLAG_NO_MAPCHANGE);
			//ToggleTank(client, true);
			//IsCoveredInVomit(client, _, true);
			ISBILED[client] = false;
			if (eBackpack[client] > 0 && IsValidEntity(eBackpack[client])) {

				AcceptEntityInput(eBackpack[client], "Kill");
				eBackpack[client] = 0;
			}
			if (RatingHandicap[client] > RatingPerLevel) {

				RatingHandicap[client] = RatingPerLevel;
				PrintToChat(client, "%T", "player handicap", client, blue, orange, green, RatingHandicap[client]);
			}

			RefreshSurvivor(client);
			//AutoAdjustHandicap(client, 1);
			//if (ReadyUp_GetGameMode() == 3 && Rating[client] > PlayerLevel[client]) Rating[client] = PlayerLevel[client];		// death in survival resets the handicap.
			//WipeDamageContribution(client);

			GetAbilityStrengthByTrigger(client, attacker, 'E', FindZombieClass(client), 0);
			if (attacker > 0) GetAbilityStrengthByTrigger(attacker, client, 'e', FindZombieClass(attacker), healthvalue);
			if (IsLegitimateClientAlive(attacker) && FindZombieClass(attacker) == ZOMBIECLASS_TANK) {

				if (IsFakeClient(attacker)) ChangeTankState(attacker, "death");
			}
			SaveAndClear(client);
		}
		else if (!IsIncapacitated(client)) {

			SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
			iThreatLevel[client] /= 2;
			//bIsGiveIncapHealth[client] = true;	// because we do it here
			ModifyHealth(client, GetAbilityStrengthByTrigger(client, client, 'p', FindZombieClass(client), 0, _, _, "H"), 0.0);
			GiveMaximumHealth(client);
			
			//GiveMaximumHealth(client);
			b_HasDeathLocation[client] = false;
			//SetTempHealth(client, client, GetMaximumHealth(client) * 1.0);

			// After setting initial temp health we can set a different one if they have the talent
			if (attacker != 0 && IsLegitimateClient(attacker)) GetAbilityStrengthByTrigger(client, attacker, 'N', FindZombieClass(client), healthvalue);
			else GetAbilityStrengthByTrigger(client, attacker, 'n', FindZombieClass(client), healthvalue);
			/*new Float:IncapHealthStrength = GetAbilityStrengthByTrigger(client, client, 'p', FindZombieClass(client), 0, _, _, "H");
			if (IncapHealthStrength < 1.0) IncapHealthStrength = (iSurvivorBaseHealth * 1.0) / 100.0;	// 100 health if nothing.
			if (iRPGMode >= 1) ModifyHealth(client, IncapHealthStrength, 0.0);
			else ModifyHealth(client, iSurvivorBaseHealth * 4.0, 0.0);*/
			//SetEntityHealth(client, RoundToCeil(GetMaximumHealth(client) * StringToFloat(GetConfigValue("survivor incap health?"))));
			//SetClientTotalHealth(client, GetMaximumHealth(client), true);
			//SetClientTempHealth(client);
			RoundIncaps[client]++;
			//if (ReadyUp_GetGameMode() != 3) AutoAdjustHandicap(client, 0);

			if (L4D2_GetInfectedAttacker(client) == -1) GetAbilityStrengthByTrigger(client, attacker, 'n', FindZombieClass(client), healthvalue);
			else {							
				
				//CreateTimer(1.0, Timer_IsIncapacitated, victim, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				GetAbilityStrengthByTrigger(client, attacker, 'N', FindZombieClass(client), healthvalue);
				if (L4D2_GetInfectedAttacker(client) == attacker) GetAbilityStrengthByTrigger(attacker, client, 'm', FindZombieClass(attacker), healthvalue);
				else GetAbilityStrengthByTrigger(client, L4D2_GetInfectedAttacker(client), 'm', FindZombieClass(client), healthvalue);
			}
		}
	}
}

stock CreateItemRoll(client, thekiller) {

	if (!b_IsActiveRound || GetArraySize(ItemDropArray) < 1 || iDropsEnabled == 0) return;

	new Float:fDropChance = 0.0;
	new theRoll	= 0;
	new theRange = 0;
	if (IsSpecialCommon(client)) fDropChance			= fDropChanceSpecial;
	else if (IsCommonInfected(client)) fDropChance		= fDropChanceCommon;
	else if (IsWitch(client)) fDropChance				= fDropChanceWitch;
	else if (IsLegitimateClientAlive(client)) {

		if (GetClientTeam(client) == TEAM_INFECTED) {

			if (FindZombieClass(client) == ZOMBIECLASS_TANK) fDropChance	= fDropChanceTank;
			else fDropChance												= fDropChanceInfected;
		}
	}

	if (IsLegitimateClientAlive(thekiller)) {

		new Float:TheAbilityMultiplier = GetAbilityMultiplier(thekiller, 'O');
		if (TheAbilityMultiplier > 0.0) fDropChance += TheAbilityMultiplier;
	}

	new Float:cfDropChance = fDropChance;
	new randomrarity = 0;

	for (new i = 0; i <= iRarityMax; i++) {

		if (cfDropChance >= 1.0) {

			// if the user has more than 100% we give them a random chance at all rarities.
			// this is a wildcard roll.

			randomrarity = GetRandomInt(1, (iRarityMax + 1));
			theRange = RoundToCeil((1.0 * randomrarity) / fDropChance);
			if (GetRandomInt(1, theRange) == 1) {

				cfDropChance -= 1.0;
				CreateItemDrop(client, randomrarity - 1);
			}

		}

		theRange = RoundToCeil((1.0 * (i + 1)) / fDropChance);
		theRoll = GetRandomInt(1, theRange);
		if (theRoll == 1) {

			CreateItemDrop(client, i);
			return;
		}
	}
}

stock CreateItemDrop(client, rarity = 0) {

	if (!b_IsActiveRound) return;

	new Float:Origin[3];
	if (IsLegitimateClientAlive(client)) GetClientAbsOrigin(client, Origin);
	else GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);

	decl String:t_ItemDropArray[iRarityMax + 1][64];

	ExplodeString(ItemDropArraySize, ",", t_ItemDropArray, iRarityMax + 1, 64);
	new maxrange = StringToInt(t_ItemDropArray[rarity]);

	//new pos = GetRandomInt(1, GetArraySize(ItemDropArray));
	new pos = GetRandomInt(1, maxrange);
	pos = GetArrayCell(ItemDropArray, pos - 1, rarity);

	decl String:text[64];
	Format(text, sizeof(text), "rpgitem_%d", pos);

	new entity = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(entity, "targetname", text);
	DispatchKeyValue(entity, "spawnflags", "1");
	DispatchKeyValue(entity, "glowstate", "3");
	DispatchKeyValue(entity, "glowrange", "512");

	GiveItemDrop(_, pos, true, text, sizeof(text));

	DispatchKeyValue(entity, "glowcolor", text);
	DispatchKeyValue(entity, "solid", "6");
	DispatchKeyValue(entity, "model", sItemModel);
	DispatchSpawn(entity);

	decl String:iColor[4][64];
	ExplodeString(text, " ", iColor, 4, 64);

	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, StringToInt(iColor[0]), StringToInt(iColor[1]), StringToInt(iColor[2]), StringToInt(iColor[3]));
	Format(text, sizeof(text), "%d:%d", entity, GetTime());
	PushArrayString(Handle:persistentCirculation, text);
	//PushArrayCell(Handle:persistentCirculation, entity);

	new Float:vel[3];
	vel[0] = GetRandomFloat(-500.0, 500.0);
	vel[1] = GetRandomFloat(-500.0, 500.0);
	vel[2] = GetRandomFloat(10.0, 500.0);

	Origin[2] += 32.0;
	TeleportEntity(entity, Float:Origin, NULL_VECTOR, vel);
}

stock CheckIfItemPickup(client) {

	new entity = -1;
	decl String:text[64], String:tentity[2][64];
	new expirydate = 0;
	new Float:myPos[3], Float:itemPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", myPos);
	new theTime = GetTime();

	new size = GetArraySize(persistentCirculation);

	for (new i = 0; i < size; i++) {

		GetArrayString(persistentCirculation, i, text, sizeof(text));
		ExplodeString(text, ":", tentity, 2, 64);
		entity = StringToInt(tentity[0]);
		expirydate = StringToInt(tentity[1]);
		//PrintToChatAll("current time: %d - %d >= %d then destroy", theTime, expirydate, iItemExpireDate);
		if (theTime - expirydate >= iItemExpireDate || !IsValidEntity(entity)) {

			if (IsValidEntity(entity)) AcceptEntityInput(entity, "Kill");
			RemoveFromArray(persistentCirculation, i);
			if (i > 0) i--;
			size = GetArraySize(persistentCirculation);
			continue;
		}
		//entity = GetArrayCell(persistentCirculation, i);
	    
		if (IsValidEntity(entity)) {

			GetEntPropString(entity, Prop_Data, "m_iName", text, sizeof(text));
			//LogMessage("entity name: %s", text);
			if (StrContains(text, "rpgitem_") != -1) {

				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", itemPos);
				if (GetVectorDistance(myPos, itemPos) < 32.0) {

					AcceptEntityInput(entity, "Kill");
					RemoveFromArray(persistentCirculation, i);
					GiveItemDrop(client, StringToInt(text[FindDelim(text, "_")]));
					return;
				}
			}
		}
	}
}

stock GiveItemDrop(client = -1, pos, bool:GetColor = false, String:theref[] = "none", thesize = 0) {

	if (client != -1 && !IsLegitimateClientAlive(client)) return;

	ItemDropKeys				= GetArrayCell(a_Menu_Talents, pos, 0);
	ItemDropValues				= GetArrayCell(a_Menu_Talents, pos, 1);

	if (GetColor) {

		if (!StrEqual(theref, "none")) FormatKeyValue(theref, thesize, ItemDropKeys, ItemDropValues, "item glow?");
		return;
	}


	ItemDropSection				= GetArrayCell(a_Menu_Talents, pos, 2);

	decl String:effect[10];
	FormatKeyValue(effect, sizeof(effect), ItemDropKeys, ItemDropValues, "item effect?");
	new Float:fStrength = GetKeyValueFloat(ItemDropKeys, ItemDropValues, "item strength?");

	decl String:Command[64], String:Parameter[64];
	FormatKeyValue(Command, sizeof(Command), ItemDropKeys, ItemDropValues, "command?");
	FormatKeyValue(Parameter, sizeof(Parameter), ItemDropKeys, ItemDropValues, "parameter?");

	new Float:TheAbilityMultiplier = GetAbilityMultiplier(client, 'M');
	if (TheAbilityMultiplier > 0.0) fStrength += TheAbilityMultiplier;

	new iMyHealth = GetMaximumHealth(client);
	new iMyStamina = GetPlayerStamina(client);
	if (StrContains(effect, "hpPot", true) != -1) {

		HealPlayer(client, client, iMyHealth * fStrength, 'h', true);
	}
	if (StrContains(effect, "stPot", true) != -1) {	// If you have noticed, items can have multiple effects

		iMyHealth = RoundToCeil(GetPlayerStamina(client) * fStrength);
		if (SurvivorStamina[client] + iMyHealth > iMyStamina) {

			SurvivorStamina[client] = iMyStamina;
		}
		else SurvivorStamina[client] += iMyHealth;
	}
	if (StrContains(effect, "adPot", true) != -1) {

		SetAdrenalineState(client, fStrength);
	}
	if (StrContains(Command, "-1") == -1) {		// this potion has a command tied to it, so it gives the user an actual item.

		//if (StrContains(effect, "exPot", true) != -1)	// do not need to specify potion type for command-based potions.
		ExecCheatCommand(client, Command, Parameter);
	}

	decl String:itemname[64];
	GetArrayString(ItemDropSection, 0, itemname, sizeof(itemname));

	decl String:clientname[64];
	GetClientName(client, clientname, sizeof(clientname));

	decl String:itemname_s[64];
	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;
		Format(itemname_s, sizeof(itemname_s), "%T", itemname, i);
		PrintToChat(i, "%T", "item obtained by player", i, blue, clientname, white, green, itemname_s);
	}
}

stock bool:EquipBackpack(client) {

	if (eBackpack[client] > 0 && IsValidEntity(eBackpack[client])) {

		AcceptEntityInput(eBackpack[client], "Kill");
		eBackpack[client] = 0;
	}

	if (eBackpack[client] > 0 && IsValidEntity(eBackpack[client]) || !IsLegitimateClientAlive(client)) return false;	// backpack is already created.
	new Float:Origin[3];

	new entity = CreateEntityByName("prop_dynamic_override");

	GetClientAbsOrigin(client, Origin);

	decl String:text[64];
	Format(text, sizeof(text), "%d", client);
	DispatchKeyValue(entity, "model", sBackpackModel);
	//DispatchKeyValue(entity, "parentname", text);
	DispatchSpawn(entity);

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);
	SetVariantString("spine");
	AcceptEntityInput(entity, "SetParentAttachment");

	// Lux
	AcceptEntityInput(entity, "DisableCollision");
	SetEntProp(entity, Prop_Send, "m_noGhostCollision", 1, 1);
	SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0x0004);
	new Float:dFault[3];
	SetEntPropVector(entity, Prop_Send, "m_vecMins", dFault);
	SetEntPropVector(entity, Prop_Send, "m_vecMaxs", dFault);
	// Lux

	//TeleportEntity(entity, g_vPos[index], g_vAng[index], NULL_VECTOR);
	SetEntProp(entity, Prop_Data, "m_iEFlags", 0);


	Origin[0] += 10.0;

	TeleportEntity(entity, Origin, NULL_VECTOR, NULL_VECTOR);
	eBackpack[client] = entity;

	return true;
}

stock bool:GetClientStance(client, Float:fChaseTime = 20.0) {

	//if (stance == ClientActiveStance[client]) return true;
	/*if (bChangeStance) {

		ClientActiveStance[client] = stance;

		if (stance == 1) {

			new entity = CreateEntityByName("info_goal_infected_chase");
			if (entity > 0)
			{
				iChaseEnt[client] = EntIndexToEntRef(entity);

				DispatchSpawn(entity);
				new Float:vPos[3];
				GetClientAbsOrigin(client, vPos);
				vPos[2] += 20.0;
				TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", client);

				decl String:temp[32];
				Format(temp, sizeof temp, "OnUser4 !self:Kill::300.0:-1");
				SetVariantString(temp);
				AcceptEntityInput(entity, "AddOutput");
				AcceptEntityInput(entity, "FireUser4");

				//iChaseEnt[client] = entity;
			}
		}
		else {

			if(iChaseEnt[client] && EntRefToEntIndex(iChaseEnt[client]) != INVALID_ENT_REFERENCE) AcceptEntityInput(iChaseEnt[client], "Kill");
			iChaseEnt[client] = -1;
		}
		return true;
	}*/
	if (ClientActiveStance[client] == 1) return false;

	new entity = CreateEntityByName("info_goal_infected_chase");
	if (entity > 0) {
		
		iChaseEnt[client] = EntIndexToEntRef(entity);

		DispatchSpawn(entity);
		new Float:vPos[3];
		GetClientAbsOrigin(client, vPos);
		vPos[2] += 20.0;
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);

		decl String:temp[32];
		Format(temp, sizeof temp, "OnUser4 !self:Kill::%f:-1", fChaseTime);
		SetVariantString(temp);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser4");

		ClientActiveStance[client] = 1;
		CreateTimer(fChaseTime, Timer_ForcedThreat, client, TIMER_FLAG_NO_MAPCHANGE);

		iThreatLevel[client] = iTopThreat + 1;

		return true;
	}
	return false;
}

public Action:Timer_ForcedThreat(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) {

		ClientActiveStance[client] = 0;
		if(iChaseEnt[client] && EntRefToEntIndex(iChaseEnt[client]) != INVALID_ENT_REFERENCE) AcceptEntityInput(iChaseEnt[client], "Kill");
		iChaseEnt[client] = -1;
	}
	return Plugin_Stop;
}

stock bool:IsAllSurvivorsDead() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) return false;
	}
	return true;
}

stock GiveAdrenaline(client, bool:Remove=false) {

	if (Remove) SetEntProp(client, Prop_Send, "m_bAdrenalineActive", 0);
	else if (!HasAdrenaline(client)) SetEntProp(client, Prop_Send, "m_bAdrenalineActive", 1);
}

stock bool:HasAdrenaline(client) {

	if (IsClientInRangeSpecialAmmo(client, "a") == -2.0) return true;
	return bool:GetEntProp(client, Prop_Send, "m_bAdrenalineActive");
}

/*stock bool:IsDualWield(client) {

	return bool:GetEntProp(client, Prop_Send, "m_isDualWielding");
}*/

stock bool:IsLedged(client) {

	return bool:GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

stock bool:FallingFromLedge(client) {

	return bool:GetEntProp(client, Prop_Send, "m_isFallingFromLedge");
}

stock SetAdrenalineState(client, Float:time=10.0) {

	if (!HasAdrenaline(client)) SDKCall(g_hEffectAdrenaline, client, time);
}

stock GetClientTotalHealth(client) {

	new SolidHealth			= GetClientHealth(client);
	new Float:TempHealth	= GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	//if (IsIncapacitated(client)) TempHealth = 0.0;

	if (!IsIncapacitated(client)) return RoundToCeil(SolidHealth + TempHealth);
	else return RoundToCeil(TempHealth);
}
 
stock SetClientTotalHealth(client, damage, bool:IsSetHealthInstead = false, bool:bIgnoreMultiplier = false) {

	new Float:fHealthBuffer = 0.0;

	if (IsSetHealthInstead) {

		SetMaximumHealth(client);
		SetEntityHealth(client, damage);
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", damage * 1.0);
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
		return;
	}

	if (GetClientTeam(client) == TEAM_SURVIVOR || IsSurvivorBot(client)) {

		fHealthBuffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
		if (fHealthBuffer > 0.0) {

			if (damage >= fHealthBuffer) {	// temporary health is always checked first.

				if (IsIncapacitated(client)) IncapacitateOrKill(client);	// kill
				else {

					SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
					SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
					damage -= RoundToFloor(fHealthBuffer);
				}
			}
			else {

				fHealthBuffer -= damage;
				SetEntityHealth(client, RoundToCeil(fHealthBuffer));
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealthBuffer);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
				damage = 0;
			}
		}
		if (IsPlayerAlive(client)) {

			if (damage >= GetClientTotalHealth(client)) IncapacitateOrKill(client);	// hint: they won't be killed.
			else if (!IsIncapacitated(client)) {

				SetEntityHealth(client, GetClientHealth(client) - damage);
				//damage = RoundToCeil(GetClassMultiplier(client, damage * 1.0, "coX", true, true));

				// Normalization for tanking :3
				// It's happening bleh
				// Don't tell Billy
				new Float:RatingReductionMult = GetClassMultiplier(client, -1.0, "D");
				if (RatingReductionMult == -1.0 || bIgnoreMultiplier) RatingReductionMult = 1.0;
				//RatingReductionMult = (1.0 / RatingReductionMult);
				//t_reward = RoundToCeil(GetClassMultiplier(client, t_reward * 1.0, "tXP"));
				AddTalentExperience(client, "constitution", RoundToCeil(damage / RatingReductionMult));
			}
		}
	}
	else {

		if (damage >= GetClientHealth(client)) CalculateInfectedDamageAward(client);
		else SetEntityHealth(client, GetClientHealth(client) - damage);
	}
}

stock RestoreClientTotalHealth(client, damage) {

	new SolidHealth			= GetClientHealth(client);
	new Float:TempHealth	= 0.0;
	if (GetClientTeam(client) == TEAM_SURVIVOR || IsSurvivorBot(client)) TempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	if (RoundToFloor(TempHealth) > 0) {

		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", TempHealth + damage);
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	}
	else SetEntityHealth(client, SolidHealth + damage);
}

stock bool:SetTempHealth(client, targetclient, Float:TemporaryHealth=30.0, bool:IsRevive=false, bool:IsInNeedOfPickup=false) {

	if (!IsLegitimateClientAlive(targetclient)) return false;
	if (IsRevive) {

		if (IsInNeedOfPickup) ReviveDownedSurvivor(targetclient);

		// When a player revives someone (or is revived) we call the SetTempHealth function and here
		// It simply calls itself 
		GetAbilityStrengthByTrigger(targetclient, client, 'R', FindZombieClass(targetclient), 0);
		GetAbilityStrengthByTrigger(client, targetclient, 'r', FindZombieClass(client), 0);
		//GiveMaximumHealth(targetclient);
	}
	else {

		SetEntPropFloat(targetclient, Prop_Send, "m_healthBuffer", TemporaryHealth);
		SetEntPropFloat(targetclient, Prop_Send, "m_healthBufferTime", GetGameTime());
	}
	if (client != targetclient) AwardExperience(client, 1, RoundToCeil(TemporaryHealth));
	return true;
}

/*stock ModifyTempHealth(client, Float:health) {

	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", health);
}*/

/*stock SetClientMaximumTempHealth(client) {

	SetMaximumHealth(client);
	SetEntityHealth(client, 1);
	SetClientTempHealth(client, GetMaximumHealth(client) - 1);
}*/

stock ModifyHealth(client, Float:TalentStrength, Float:TalentTime) {

	if (!IsLegitimateClientAlive(client)) return;
	if (GetClientTeam(client) == TEAM_INFECTED) {

		DefaultHealth[client] = OriginalHealth[client] + RoundToCeil(OriginalHealth[client] * TalentStrength);
		SetMaximumHealth(client, false, DefaultHealth[client] * 1.0);
	}
	else {

		//if (IsClientInRangeSpecialAmmo(client, "O") == -2.0) {
		
		//if (IsClientInRangeSpecialAmmo(client, "O") == -2.0) TalentStrength += (TalentStrength * IsClientInRangeSpecialAmmo(client, "O", false, _, TalentStrength));
		
		//if (TalentStrength < 1.0) TalentStrength = 1.0; 
		SetMaximumHealth(client, false, TalentStrength);
		//else SetMaximumHealth(client, false, TalentStrength * StringToFloat(GetConfigValue("survivor incap health?")));
	}
}

stock ReviveDownedSurvivor(client) {

	//if (IsLedged(client)) HealPlayer(client, client, 1.0, 'h');
	//else
	ExecCheatCommand(client, "give", "health");
	//SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
	SetMaximumHealth(client);
}

/*
if (RoundToFloor(PlayerHealth_Temp + HealAmount) >= GetMaximumHealth(client) && IsIncapacitated(client)) {

		//SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
		ReviveDownedSurvivor(client);
		GetAbilityStrengthByTrigger(client, activator, 'R', FindZombieClass(client), 0);
		GetAbilityStrengthByTrigger(activator, client, 'r', FindZombieClass(activator), 0);
		GiveMaximumHealth(client);
	}
	*/

stock GetIncapCount(client) {

	return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}

stock bool:IsBeingRevived(client) {

	new target = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
	if (IsLegitimateClientAlive(target)) return true;
	return false;
}

stock HealPlayer(client, activator, Float:f_TalentStrength, ability, bool:IsStrength = false) {	// must heal for abilities that instant-heal

	if (!IsLegitimateClientAlive(client)) return 0;
	new MyMaximumHealth = GetMaximumHealth(client);
	new PlayerHealth = GetClientHealth(client);
	if (PlayerHealth >= MyMaximumHealth && !IsIncapacitated(client)) {

		SetMaximumHealth(client);
		return 0;
	}
	if (L4D2_GetInfectedAttacker(client) != -1) return 0;
	new Float:TalentStrength = GetAbilityMultiplier(activator, 'E');
	if (TalentStrength == -1.0) TalentStrength = 0.0;
	TalentStrength = f_TalentStrength + (TalentStrength * f_TalentStrength);
	//if (!IsIncapacitated(client)) PlayerHealth = GetClientHealth(client) * 1.0;
	new Float:PlayerHealth_Temp = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");

	new HealAmount = 0;
	if (IsStrength) HealAmount = RoundToCeil(TalentStrength);
	else {

		if (TalentStrength > 1.0) TalentStrength = 1.0;
		HealAmount = RoundToCeil(GetMaximumHealth(client) * TalentStrength);
	}

	if (HealAmount < 1) return 0;

	new NewHealth = PlayerHealth + HealAmount;

	if (IsIncapacitated(client)) {

		if (!IsLedged(client)) {

			if (NewHealth <= MyMaximumHealth) {	// Incap health can't exceed actual player health - or they get instantly ressed. that's wrong and i'll fix it, later. noted.

				SetEntityHealth(client, NewHealth);
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", NewHealth * 1.0);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
			}
			else {

				HealAmount = MyMaximumHealth - PlayerHealth;
				SetEntityHealth(client, MyMaximumHealth);
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());

				//OnPlayerRevived(activator, client);

				GetAbilityStrengthByTrigger(client, activator, 'R', FindZombieClass(client), 0);
				GetAbilityStrengthByTrigger(activator, client, 'r', FindZombieClass(activator), 0);
			}
			// We auto-revive any survivor who heals over their maximum incap health.
			// We also give them a default health on top of the overheal, to help them maybe not get knocked again, immediately.
			// You don't die if you get incapped too many times, but it would be a pretty annoying game play loop.
			if (NewHealth >= MyMaximumHealth) {

				if (!IsBeingRevived(client)) {

					SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
					new reviveOwner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
					if (IsLegitimateClientAlive(reviveOwner)) SetEntPropEnt(reviveOwner, Prop_Send, "m_reviveTarget", -1);
					SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);

					NewHealth -= MyMaximumHealth;
					SetEntityMoveType(client, MOVETYPE_WALK);
					SetEntityHealth(client, RoundToCeil(GetMaximumHealth(client) * fHealthSurvivorRevive) + NewHealth);
				}
				else {

					SetEntityHealth(client, MyMaximumHealth);
					SetEntPropFloat(client, Prop_Send, "m_healthBuffer", MyMaximumHealth * 1.0);
					SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
				}
			}
		}
	}
	else {

		if (RoundToCeil(PlayerHealth + PlayerHealth_Temp + HealAmount) >= MyMaximumHealth) {

			new TempDiff = MyMaximumHealth - (PlayerHealth + HealAmount);

			if (TempDiff > 0) {

				HealAmount = MyMaximumHealth - RoundToFloor(PlayerHealth + PlayerHealth_Temp);

				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
				GiveMaximumHealth(client);
			}
			else {

				SetEntityHealth(client, PlayerHealth + HealAmount);
				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", TempDiff * 1.0);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
			}
		}
		else {

			SetEntityHealth(client, PlayerHealth + HealAmount);
			if (PlayerHealth_Temp > 0.0) {

				SetEntPropFloat(client, Prop_Send, "m_healthBuffer", PlayerHealth_Temp);
				SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
			}
		}
	}
	if (HealAmount > 0 && bIsInCombat[activator]) {	// you don't get XP for healing if you're not in combat! If you are healing someone who is, you'd be in combat, too!

		if (IsLegitimateClientAlive(activator) && activator != client) {

			AwardExperience(activator, 1, HealAmount);
			new Float:TheAbilityMultiplier = GetAbilityMultiplier(activator, 't');
			if (TheAbilityMultiplier != -1.0) {

				TheAbilityMultiplier *= (HealAmount * 1.0);
				iThreatLevel[activator] += (HealAmount - RoundToFloor(TheAbilityMultiplier));
			}
			else {

				iThreatLevel[activator] += HealAmount;
			}
			//AddTalentExperience(activator, "endurance", RoundToCeil(GetClassMultiplier(activator, HealAmount * 0.5, "enX", true, true)));
		}
		// friendly fire module is no longer used - depricated //if (ability == 'T') ReadyUp_NtvFriendlyFire(activator, client, 0 - HealAmount, GetClientHealth(client), 1, 0);	// we "subtract" negative values from health.
	}

	return HealAmount;		// to prevent cartel being awarded for overheal.
}

stock EnableHardcoreMode(client, bool:Disable=false) {

	if (!Disable) {
	
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 0, 0, 255);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
		EmitSoundToClient(client, "player/heartbeatloop.wav");
	}
	else {

		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
	}
}

/*

	Helping new players adjust to the game brought on the idea of Pets.
	Pets provide benefits to the user, and can be changed at any time.

	Pets that have not yet been discovered are hidden from player view.
	This function properly positions the pet.
*/
/*
new entity = CreateEntityByName("prop_dynamic_override");
	if( entity != -1 )
	{
		SetEntityModel(entity, g_sModels[index]);
		DispatchSpawn(entity);
		if( g_bLeft4Dead2 )
		{
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", g_fSize[index]);
		}

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client);
		SetVariantString("eyes");
		AcceptEntityInput(entity, "SetParentAttachment");
		TeleportEntity(entity, g_vPos[index], g_vAng[index], NULL_VECTOR);
		SetEntProp(entity, Prop_Data, "m_iEFlags", 0);

		if( g_iCvarOpaq )
		{
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 255, 255, 255, g_iCvarOpaq);
		}

		g_iSelected[client] = index;
		g_iHatIndex[client] = EntIndexToEntRef(entity);

		if( !g_bHatView[client] )
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);

		if( g_bTranslation == false )
		{
			CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Wearing", g_sNames[index]);
		}
		else
		{
			decl String:sMsg[128];
			Format(sMsg, sizeof(sMsg), "Hat %d", index + 1);
			Format(sMsg, sizeof(sMsg), "%T", sMsg, client);
			CPrintToChat(client, "%s%t", CHAT_TAG, "Hat_Wearing", sMsg);
		}

		return true;
	}
*/

