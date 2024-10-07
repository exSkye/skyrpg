stock SetMyWeapons(client) {
	if (!IsLegitimateClient(client) || GetClientTeam(client) != TEAM_SURVIVOR) return;
	char PlayerWeapon[64];
	int g_iActiveWeaponOffset = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
	int iWeapon = GetEntDataEnt2(client, g_iActiveWeaponOffset);
	
	GetClientWeapon(client, PlayerWeapon, 64);
	if (StrContains(PlayerWeapon, "pain_pills", false) != -1) {
		medItem[client] = 1;
	}
	else if (StrContains(PlayerWeapon, "adrenaline", false) != -1) {
		medItem[client] = 2;
	}
	else if (StrContains(PlayerWeapon, "first_aid", false) != -1) {
		medItem[client] = 3;
	}
	else if (StrContains(PlayerWeapon, "defib", false) != -1) {
		medItem[client] = 4;
	}
	else medItem[client] = 0;
	if (StrContains(PlayerWeapon, "chainsaw", false) != -1) {
		bHasChainsaw[client] = true;
	}
	else bHasChainsaw[client] = false;
	// Skip if it's not weapon slot 0 or 1.
	if (StrContains(PlayerWeapon, "smg", false) == -1 &&
		StrContains(PlayerWeapon, "shotgun", false) == -1 &&
		StrContains(PlayerWeapon, "sniper", false) == -1 &&
		StrContains(PlayerWeapon, "rifle", false) == -1 &&
		StrContains(PlayerWeapon, "melee", false) == -1 &&
		StrContains(PlayerWeapon, "pistol", false) == -1 &&
		StrContains(PlayerWeapon, "chainsaw", false) == -1) return;

	// this is a valid weapon, so store the weapon id
	myCurrentWeaponId[client] = iWeapon;
	if (StrContains(PlayerWeapon, "melee", false) != -1 || bHasChainsaw[client]) {
		if (!bHasChainsaw[client]) {
			GetEntityClassname(iWeapon, PlayerWeapon, sizeof(PlayerWeapon));
			GetEntPropString(iWeapon, Prop_Data, "m_strMapSetScriptName", MyCurrentWeapon[client], 64);
		}
		else {
			iWeapon = GetPlayerWeaponSlot(client, 1);
			GetEntityClassname(iWeapon, MyCurrentWeapon[client], 64);
		}
		hasMeleeWeaponEquipped[client] = true;
		currentWeaponCategory[client]  =																											4096;	// MELEE WEAPONS ONLY (NO GUNS)-------------22
	}
	else if (StrContains(PlayerWeapon, "weapon_", false) != -1) {
		int WeaponId = -1;
		if (StrContains(PlayerWeapon, "pistol", false) == -1) WeaponId = GetPlayerWeaponSlot(client, 0);
		else WeaponId = GetPlayerWeaponSlot(client, 1);
		if (IsValidEntity(WeaponId)) GetEntityClassname(WeaponId, MyCurrentWeapon[client], 64);
		hasMeleeWeaponEquipped[client] = false;
		currentWeaponCategory[client]  =																											2048;	// ALL GUNS---------------------------------21
		bool isHuntingRifle = (StrContains(PlayerWeapon, "hunting", false) != -1) ? true : false;
		if (StrContains(PlayerWeapon, "smg", false) != -1) {
			currentWeaponCategory[client] =																												1;	// all smg									10
			weaponProficiencyType[client] = 2;
		}
		if (StrContains(PlayerWeapon, "shotgun", false) != -1) {
			currentWeaponCategory[client] +=																											2;	// all shotguns								11
			weaponProficiencyType[client] = 3;
		}
		if (StrContains(PlayerWeapon, "pump", false) != -1 || StrContains(PlayerWeapon, "chrome", false) != -1) currentWeaponCategory[client] +=		4;	// tier 1 shotguns (pumps)------------------12
		if (!isHuntingRifle && StrContains(PlayerWeapon, "rifle", false) != -1) {
			currentWeaponCategory[client] +=																											8; // all rifles (including m60)				13
			weaponProficiencyType[client] = 5;
		}
		if (isHuntingRifle || StrContains(PlayerWeapon, "sniper", false) != -1) {
			currentWeaponCategory[client] +=																											16; // all snipers (hunting rifle too)			14
			weaponProficiencyType[client] = 4;
		}
		if (StrContains(PlayerWeapon, "pistol", false) != -1) {
			currentWeaponCategory[client] +=																											32;	// all pistols								15
			weaponProficiencyType[client] = 0;
		}
		if (StrContains(PlayerWeapon, "magnum", false) != -1) currentWeaponCategory[client] +=															64;	// magnum pistol----------------------------16
		if (StrContains(PlayerWeapon, "pistol", false) != -1 && StrContains(PlayerWeapon, "magnum", false) == -1) currentWeaponCategory[client] +=		128;	// dual pistols							17
		if (StrContains(PlayerWeapon, "magnum", false) != -1 || StrContains(PlayerWeapon, "awp", false) != -1) currentWeaponCategory[client] +=			256;	// 50 cal weapons (magnum and awp)		18
		if (StrContains(PlayerWeapon, "awp", false) != -1 || StrContains(PlayerWeapon, "scout", false) != -1) currentWeaponCategory[client] +=			512;	// sniper rifles (bolt only)			19
		if (StrContains(PlayerWeapon, "hunting", false) != -1 || StrContains(PlayerWeapon, "military", false) != -1) currentWeaponCategory[client] +=	1024;	// DMRS (semi-auto snipers)				20
		if ((StrContains(PlayerWeapon, "smg", false) != -1 || StrContains(PlayerWeapon, "chrome", false) != -1 ||
			StrContains(PlayerWeapon, "pump", false) != -1 || StrContains(PlayerWeapon, "pistol", false) != -1) ||
			StrContains(PlayerWeapon, "hunting", false) != -1) currentWeaponCategory[client] +=															8192;	// TIER 1 WEAPONS ONLY					23
		if (StrContains(PlayerWeapon, "spas", false) != -1 || StrContains(PlayerWeapon, "autoshotgun", false) != -1 ||
			StrContains(PlayerWeapon, "sniper", false) != -1 ||
			StrContains(PlayerWeapon, "rifle", false) != -1 && StrContains(PlayerWeapon, "hunting", false) == -1) currentWeaponCategory[client] +=		16384;	// TIER 2 WEAPONS ONLY					24
	}
	int size = GetArraySize(a_WeaponDamages);
	// set current weapon
	for (int i = 0; i < size; i++) {
		WeaponResultSection[client] = GetArrayCell(a_WeaponDamages, i, 2);

		char WeaponName[64];
		GetArrayString(WeaponResultSection[client], 0, WeaponName, sizeof(WeaponName));
		if (!StrEqual(WeaponName, PlayerWeapon, false)) continue;

		myCurrentWeaponPos[client] = i;
		break;
	}

	// store primary weapon
	int primaryWeapon = GetPlayerWeaponSlot(client, 0);
	if (IsValidEntity(primaryWeapon)) {
		char myPrimaryWeapon[64];
		GetEntityClassname(primaryWeapon, myPrimaryWeapon, 64);
		for (int i = 0; i < size; i++) {
			WeaponResultSection[client] = GetArrayCell(a_WeaponDamages, i, 2);

			char primaryWeaponName[64];
			GetArrayString(WeaponResultSection[client], 0, primaryWeaponName, sizeof(primaryWeaponName));
			if (!StrEqual(primaryWeaponName, myPrimaryWeapon, false)) continue;

			myPrimaryWeaponPos[client] = i;
			break;
		}
	}
}