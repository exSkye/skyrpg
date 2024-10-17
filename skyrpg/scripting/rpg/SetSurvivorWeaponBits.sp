stock SetMyWeapons(client) {
	if (!IsLegitimateClient(client) || GetClientTeam(client) != TEAM_SURVIVOR) return;
	char PlayerWeapon[64];
	int g_iActiveWeaponOffset = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
	int iWeapon = GetEntDataEnt2(client, g_iActiveWeaponOffset);
	GetClientWeapon(client, PlayerWeapon, 64);

	bool bIsMeleeWeapon = StrEqualAtPos(PlayerWeapon, "melee", 7);
	if (!bIsMeleeWeapon && StrEqual(PlayerWeapon, lastCurrentWeapon[client])) return;
	lastCurrentWeapon[client] = PlayerWeapon;

	if (StrEqualAtPos(PlayerWeapon, "pain_pills", 7)) {
		medItem[client] = 1;
	}
	else if (StrEqualAtPos(PlayerWeapon, "adrenaline", 7)) {
		medItem[client] = 2;
	}
	else if (StrEqualAtPos(PlayerWeapon, "first_aid", 7)) {
		medItem[client] = 3;
	}
	else if (StrEqualAtPos(PlayerWeapon, "defib", 7)) {
		medItem[client] = 4;
	}
	else medItem[client] = 0;
	if (StrEqualAtPos(PlayerWeapon, "chainsaw", 7)) {
		bHasChainsaw[client] = true;
	}
	else bHasChainsaw[client] = false;
	// Skip if it's not weapon slot 0 or 1.
	if (!StrEqualAtPos(PlayerWeapon, "smg", 7) &&
		!StrEqualAtPos(PlayerWeapon, "shotgun", 7) &&
		!StrEqualAtPos(PlayerWeapon, "sniper", 7) &&
		!StrEqualAtPos(PlayerWeapon, "rifle", 7) &&
		!bIsMeleeWeapon &&
		!StrEqualAtPos(PlayerWeapon, "pistol", 7) &&
		!StrEqualAtPos(PlayerWeapon, "chainsaw", 7)) return;

	// this is a valid weapon, so store the weapon id
	myCurrentWeaponId[client] = iWeapon;
	if (bIsMeleeWeapon || bHasChainsaw[client]) {
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
	else if (StrBeginsWith(PlayerWeapon, "weapon_")) {
		int WeaponId = -1;
		if (!StrEqualAtPos(PlayerWeapon, "pistol", 7)) WeaponId = GetPlayerWeaponSlot(client, 0);
		else WeaponId = GetPlayerWeaponSlot(client, 1);
		if (IsValidEntity(WeaponId)) GetEntityClassname(WeaponId, MyCurrentWeapon[client], 64);
		hasMeleeWeaponEquipped[client] = false;
		currentWeaponCategory[client]  =																											2048;	// ALL GUNS---------------------------------21
		bool isHuntingRifle = (StrEqualAtPos(PlayerWeapon, "hunting", 7)) ? true : false;
		if (StrEqualAtPos(PlayerWeapon, "smg", 7)) {
			currentWeaponCategory[client] =																												1;	// all smg									10
			weaponProficiencyType[client] = 2;
		}
		if (StrEqualAtPos(PlayerWeapon, "shotgun", 7)) {
			currentWeaponCategory[client] +=																											2;	// all shotguns								11
			weaponProficiencyType[client] = 3;
		}
		if (StrEqualAtPos(PlayerWeapon, "pump", 7) || StrEqualAtPos(PlayerWeapon, "chrome", 7)) currentWeaponCategory[client] +=						4;	// tier 1 shotguns (pumps)------------------12
		if (!isHuntingRifle && StrEqualAtPos(PlayerWeapon, "rifle", 7)) {
			currentWeaponCategory[client] +=																											8; // all rifles (including m60)				13
			weaponProficiencyType[client] = 5;
		}
		if (isHuntingRifle || StrEqualAtPos(PlayerWeapon, "sniper", 7)) {
			currentWeaponCategory[client] +=																											16; // all snipers (hunting rifle too)			14
			weaponProficiencyType[client] = 4;
		}
		if (StrEqualAtPos(PlayerWeapon, "pistol", 7)) {
			currentWeaponCategory[client] +=																											32;	// all pistols								15
			weaponProficiencyType[client] = 0;
		}
		if (StrEqualAtPos(PlayerWeapon, "magnum", 7)) currentWeaponCategory[client] +=																	64;	// magnum pistol----------------------------16
		if (StrEqualAtPos(PlayerWeapon, "pistol", 7) && !StrEqualAtPos(PlayerWeapon, "magnum", 14)) currentWeaponCategory[client] +=					128;	// dual pistols							17
		if (StrEqualAtPos(PlayerWeapon, "magnum", 14) || StrEqualAtPos(PlayerWeapon, "awp", 14)) currentWeaponCategory[client] +=						256;	// 50 cal weapons (magnum and awp)		18
		if (StrEqualAtPos(PlayerWeapon, "awp", 14) || StrEqualAtPos(PlayerWeapon, "scout", 14)) currentWeaponCategory[client] +=						512;	// sniper rifles (bolt only)			19
		if (StrEqualAtPos(PlayerWeapon, "hunting", 7) || StrEqualAtPos(PlayerWeapon, "military", 14)) currentWeaponCategory[client] +=					1024;	// DMRS (semi-auto snipers)				20
		if (StrEqualAtPos(PlayerWeapon, "smg", 7) || StrEqualAtPos(PlayerWeapon, "chrome", 15) ||
			StrEqualAtPos(PlayerWeapon, "pump", 7) || StrEqualAtPos(PlayerWeapon, "pistol", 7) ||
			StrEqualAtPos(PlayerWeapon, "hunting", 7)) currentWeaponCategory[client] +=																	8192;	// TIER 1 WEAPONS ONLY					23
		if (StrEqualAtPos(PlayerWeapon, "spas", 15) || StrEqualAtPos(PlayerWeapon, "autoshotgun", 7) ||
			StrEqualAtPos(PlayerWeapon, "sniper", 7) ||
			StrEqualAtPos(PlayerWeapon, "rifle", 7) && !StrEqualAtPos(PlayerWeapon, "hunting", 7)) currentWeaponCategory[client] +=						16384;	// TIER 2 WEAPONS ONLY					24
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
		if (StrEqual(myPrimaryWeapon, lastPrimaryWeapon[client])) return;
		lastPrimaryWeapon[client] = myPrimaryWeapon;
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