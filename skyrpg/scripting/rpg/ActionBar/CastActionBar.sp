stock CMD_CastAction(client, args) {
	char actionpos[64];
	GetCmdArg(1, actionpos, sizeof(actionpos));
	if (StrContains(actionpos, acmd, false) != -1 && !StrEqual(abcmd, actionpos[1], false)) {
		CastActionEx(client, actionpos, sizeof(actionpos));
	}
}

stock CastActionEx(client, char[] t_actionpos = "none", TheSize, pos = -1) {
	int ActionSlots = iActionBarSlots;
	if (pos == -1) pos = StringToInt(t_actionpos[strlen(t_actionpos) - 1]) - 1;//StringToInt(actionpos[strlen(actionpos) - 1]);
	if (pos >= 0 && pos < ActionSlots) {
		int menuPos = GetArrayCell(ActionBarMenuPos[client], pos);
		if (menuPos < 0 || GetArrayCell(MyTalentStrength[client], menuPos) < 1) return;
		
		CastValues[client]			= GetArrayCell(a_Menu_Talents, menuPos, 1);
		if (GetArrayCell(CastValues[client], ABILITY_PASSIVE_ONLY) == 1) return;
		int AbilityTalent = 0;
		float TargetPos[3];
		char TalentName[64];
		GetArrayString(a_Database_Talents, menuPos, TalentName, sizeof(TalentName));

		char hitgroup[4];
		//CastKeys[client]			= GetArrayCell(a_Menu_Talents, menuPos, 0);
		//CastSection[client]			= GetArrayCell(a_Menu_Talents, i, 2);
		AbilityTalent = GetArrayCell(CastValues[client], IS_TALENT_ABILITY);
		int RequiresTarget = GetArrayCell(CastValues[client], ABILITY_IS_SINGLE_TARGET);
		float visualDelayTime = GetArrayCell(CastValues[client], ABILITY_DRAW_DELAY);
		if (visualDelayTime < 1.0) visualDelayTime = 1.0;
		if (RequiresTarget > 0) {
			RequiresTarget = GetAimTargetPosition(client, TargetPos, hitgroup, 4);
			if (IsLegitimateClientAlive(RequiresTarget)) {
				if (AbilityTalent != 1) CastSpell(client, RequiresTarget, TalentName, TargetPos, visualDelayTime, menuPos);
				else UseAbility(client, RequiresTarget, TalentName, CastValues[client], TargetPos, menuPos);
			}
		}
		else {
			GetAimTargetPosition(client, TargetPos, hitgroup, 4);
			if (AbilityTalent != 1) CastSpell(client, _, TalentName, TargetPos, visualDelayTime, menuPos);
			else {
				CheckActiveAbility(client, pos, _, _, true, true);
				UseAbility(client, _, TalentName, CastValues[client], TargetPos, menuPos);
			}
		}
	}
	else {
		PrintToChat(client, "%T", "Action Slot Range", client, white, blue, ActionSlots, white);
	}
}

stock bool CastSpell(client, target = -1, char[] TalentName, float TargetPos[3], float visualDelayTime = 1.0, int menuPos) {

	if (!b_IsActiveRound || !IsLegitimateClientAlive(client) || L4D2_GetInfectedAttacker(client) != -1 || GetAmmoCooldownTime(client, TalentName) != -1.0) return false;
	if (IsSpellAnAura(client, menuPos)) {
		GetClientAbsOrigin(client, TargetPos);
		target = client;
	}
	else if (IsLegitimateClientAlive(target)) GetClientAbsOrigin(target, TargetPos);	// if the target is -1 / not alive, TargetPos will have been sent through.

	if (bIsSurvivorFatigue[client]) return false;

	int StaminaCost = RoundToCeil(GetSpecialAmmoStrength(client, TalentName, 2, _, _, menuPos));
 	if (SurvivorStamina[client] < StaminaCost) return false;
 	SurvivorStamina[client] -= StaminaCost;
	if (SurvivorStamina[client] <= 0) {

		bIsSurvivorFatigue[client] = true;
		IsSpecialAmmoEnabled[client][0] = 0.0;
	}

	//IsAbilityActive(client, TalentName, AbilityTime);

	AdvertiseAction(client, TalentName, true);

	//new Float:SpellCooldown = GetSpecialAmmoStrength(client, TalentName, 1);
	//IsAmmoActive(client, TalentName, SpellCooldown);	// place it on cooldown for the lifetime (not the interval, even if it's greater)

	char key[64];
	GetClientAuthId(client, AuthId_Steam2, key, sizeof(key));

	float f_TotalTime = GetSpecialAmmoStrength(client, TalentName, _, _, _, menuPos);
	float SpellCooldown = f_TotalTime + GetSpecialAmmoStrength(client, TalentName, 1, _, _, menuPos);
	
	// It's going to be a headache re-structuring this, so i am doing it in a sequence. to make it easier interval will just clone totaltime for now.
	float f_Interval = f_TotalTime; //GetSpecialAmmoStrength(client, TalentName, 4);
	if (IsSpellAnAura(client, menuPos)) f_Interval = fSpecialAmmoInterval;	// Auras follow players and re-draw on every tick.

	//if (f_Interval > f_TotalTime) f_Interval = f_TotalTime;
	IsAmmoActive(client, TalentName, SpellCooldown);

	for (int i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i)) DrawSpecialAmmoTarget(i, menuPos, TargetPos[0], TargetPos[1], TargetPos[2], f_Interval, client, TalentName, target);
	}

	int bulletStrength = GetBaseWeaponDamage(client, target, TargetPos[0], TargetPos[1], TargetPos[2], DMG_BULLET);
	//bulletStrength = RoundToCeil(GetAbilityStrengthByTrigger(client, -2, "D", _, bulletStrength, _, _, "d", 1, true, _, _, _, DMG_BULLET));
	float amSTR = GetSpecialAmmoStrength(client, TalentName, 5, _, _, menuPos);
	if (amSTR > 0.0) bulletStrength = RoundToCeil(bulletStrength * amSTR);
	//decl String:SpecialAmmoData_s[512];
	//Format(SpecialAmmoData_s, sizeof(SpecialAmmoData_s), "%3.3f %3.3f %3.3f}%s{%d{%d{%3.2f}%s}%3.2f}%d}%3.2f}%d", TargetPos[0], TargetPos[1], TargetPos[2], TalentName, GetTalentStrength(client, TalentName), GetBaseWeaponDamage(client, -1, TargetPos[0], TargetPos[1], TargetPos[2], DMG_BULLET), f_Interval, key, SpellCooldown, -1, GetSpecialAmmoStrength(client, TalentName, 1), target);
	//Format(SpecialAmmoData_s, sizeof(SpecialAmmoData_s), "%3.3f %3.3f %3.3f}%s{%d{%d{%3.2f}%s}%3.2f}%d}%3.2f}%d", TargetPos[0], TargetPos[1], TargetPos[2], TalentName, GetTalentStrength(client, TalentName), bulletStrength, f_Interval, key, f_TotalTime, -1, GetSpecialAmmoStrength(client, TalentName, 1), target);
												//13908.302 2585.922 32.133}adren ammo{1{20{15.00}STEAM_1:1:440606022}15.00}-1}30.00}-1
	//PrintToChatAll("%d", StringToInt(key[10]));
	int sadsize = GetArraySize(SpecialAmmoData);

	ResizeArray(SpecialAmmoData, sadsize + 1);
	SetArrayCell(SpecialAmmoData, sadsize, TargetPos[0], 0);
	SetArrayCell(SpecialAmmoData, sadsize, TargetPos[1], 1);
	SetArrayCell(SpecialAmmoData, sadsize, TargetPos[2], 2);
	SetArrayCell(SpecialAmmoData, sadsize, menuPos, 3); //GetTalentNameAtMenuPosition(client, pos, String:TheString, stringSize) instead of storing TalentName
	//SetArrayCell(SpecialAmmoData, sadsize, GetTalentStrength(client, TalentName), 4);
	SetArrayCell(SpecialAmmoData, sadsize, 1, 4);
	SetArrayCell(SpecialAmmoData, sadsize, bulletStrength, 5);
	SetArrayCell(SpecialAmmoData, sadsize, f_Interval, 6);
	// only captures the #ID: STEAM_0:1:<--cuts off the front, only stores the numbers: 440606022 - is faster than parsing a string every time.
	SetArrayCell(SpecialAmmoData, sadsize, StringToInt(key[10]), 7);
	SetArrayCell(SpecialAmmoData, sadsize, f_TotalTime, 8);
	SetArrayCell(SpecialAmmoData, sadsize, -1, 9);
	SetArrayCell(SpecialAmmoData, sadsize, GetSpecialAmmoStrength(client, TalentName, 1, _, _, menuPos), 10);	// float.
	SetArrayCell(SpecialAmmoData, sadsize, target, 11);
	SetArrayCell(SpecialAmmoData, sadsize, visualDelayTime, 12);	// original value must be stored.
	SetArrayCell(SpecialAmmoData, sadsize, visualDelayTime, 13);



	//PushArrayString(Handle:SpecialAmmoData, SpecialAmmoData_s);
	return true;
}

stock bool PlayerCastSpell(client) {

	int CurrentEntity			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if (!IsValidEntity(CurrentEntity) || CurrentEntity < 1) return false;
	char EntityName[64];


	GetEdictClassname(CurrentEntity, EntityName, sizeof(EntityName));

	int Entity					=	CreateEntityByName(EntityName);
	DispatchSpawn(Entity);

	float Origin[3];
	GetClientAbsOrigin(client, Origin);

	Origin[2] += 64.0;

	TeleportEntity(Entity, Origin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(Entity, MOVETYPE_VPHYSICS);

	if (GetWeaponSlot(Entity) < 2) SetEntProp(Entity, Prop_Send, "m_iClip1", GetEntProp(CurrentEntity, Prop_Send, "m_iClip1"));
	if (CurrentEntity > 0) AcceptEntityInput(CurrentEntity, "Kill");

	return true;
}