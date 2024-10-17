stock bool IsSpecialCommon(entity) {
	if (entity > 0 && FindListPositionByEntity(entity, CommonAffixes) >= 0) {
		if (IsCommonInfected(entity)) return true;
		else ClearSpecialCommon(entity, false);
	}
	return false;
}

stock GetSpecialCommonDamage(damage, client, Effect, victim) {

	/*

		Victim is always a survivor, and is only used to pass to the GetCommonsInRange function which uses their level
		to determine its range of buff.
	*/
	float f_Strength = 1.0;

	float ClientPos[3];
	float fEntPos[3];
	if (!IsLegitimateClient(client)) GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	else GetClientAbsOrigin(client, ClientPos);

	int ent = -1;
	char EffectT[4];
	Format(EffectT, sizeof(EffectT), "%c", Effect);

	char AuraEffectIsh[10];
	for (int i = 0 ; i < GetArraySize(CommonAffixes); i++) {

		ent = GetArrayCell(CommonAffixes, i);
		if (ent == client || !IsSpecialCommon(ent)) continue;
		int superPos = GetCommonPos(ent);
		GetCommonValueAtPosEx(AuraEffectIsh, sizeof(AuraEffectIsh), superPos, SUPER_COMMON_AURA_EFFECT);
		if (StrContains(AuraEffectIsh, EffectT, true) != -1) {

			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fEntPos);
			
			//	If the damaging common is in range of an entity meeting the specific effect, then we add its effects. In this case, it's damage.
			
			if (IsInRange(fEntPos, ClientPos, GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_MAX))) {
				f_Strength += (GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_STRENGTH_SPECIAL) * GetEntitiesInRange(ent, victim));
			}
		}
	}
	return RoundToCeil(damage * f_Strength);
}

stock int GetEntitiesInRange(int client, int victim) {
	float ClientPos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);

	int superPos = GetCommonPos(client);

	float AfxRange		= GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_PLAYER_LEVEL) * PlayerLevel[victim];
	float AfxRangeMax	= GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_MAX);
	float AfxRangeBase	= GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_MIN);
	if (AfxRange + AfxRangeBase > AfxRangeMax) AfxRange = AfxRangeMax;
	else AfxRange += AfxRangeBase;
	float EntPos[3];
	int count = 0;
	//int ent = -1;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsLegitimateClientAlive(i) && myCurrentTeam[i] == TEAM_INFECTED) {
			GetClientAbsOrigin(i, EntPos);
			if (IsInRange(ClientPos, EntPos, AfxRange)) count++;
		}
	}
	return count;
}

stock bool IsSpecialCommonInRangeEx(client, char[] vEntity="none", bool IsAuraEffect = true) {	// false for death effect

	float ClientPos[3];
	float fEntPos[3];
	bool bIsLegitimateClient = IsLegitimateClient(client);
	if (!bIsLegitimateClient) GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	else GetClientAbsOrigin(client, ClientPos);

	int ent = -1;
	//new Effect = 't';
	for (int i = 0; i < GetArraySize(CommonAffixes); i++) {
		ent = GetArrayCell(CommonAffixes, i);
		if (ent == client || !IsCommonInfected(ent)) continue;
		if (!StrEqual(vEntity, "none", false)) {
			if(!CommonInfectedModel(ent, vEntity)) continue;
		}

		/*

			At a certain level, like a lower one, it's just too much having to deal with auras, so some players will absolutely be oblivious to the shit
			going on and killing other players who CAN see them.
		*/
		int superPos = GetCommonPos(ent);
		if (bIsLegitimateClient && PlayerLevel[client] < GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_LEVEL_REQ)) return false;

		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fEntPos);
		if (IsInRange(fEntPos, ClientPos, GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_MAX))) return true;
	}
	return false;
}

stock bool IsSpecialCommonInRange(client, Effect = -1, vEntity = -1, bool IsAuraEffect = true, infectedTarget = 0) {	// false for death effect

	float ClientPos[3];
	float fEntPos[3];
	bool bIsLegitimateClient = IsLegitimateClient(client);
	if (!bIsLegitimateClient) GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
	else GetClientAbsOrigin(client, ClientPos);

	char EffectT[4];
	Format(EffectT, sizeof(EffectT), "%c", Effect);

	char TheAuras[10];
	char TheDeaths[10];

	if (vEntity != -1) {

		int superPos = GetCommonPos(vEntity);

		GetCommonValueAtPosEx(TheAuras, sizeof(TheAuras), superPos, SUPER_COMMON_AURA_EFFECT);
		GetCommonValueAtPosEx(TheDeaths, sizeof(TheDeaths), superPos, SUPER_COMMON_DEATH_EFFECT);

		float AfxRange = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_PLAYER_LEVEL);
		//new Float:AfxStrengthLevel = StringToFloat(GetCommonValue(vEntity, "level strength?"));
		float AfxRangeMax = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_MAX);
		//new AfxMultiplication = StringToInt(GetCommonValue(vEntity, "enemy multiplication?"));
		//new AfxStrength = StringToInt(GetCommonValue(vEntity, "aura strength?"));
		//new AfxChain = StringToInt(GetCommonValue(vEntity, "chain reaction?"));
		//new Float:AfxStrengthTarget = StringToFloat(GetCommonValue(vEntity, "strength target?"));
		float AfxRangeBase = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_MIN);
		int AfxLevelReq = GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_LEVEL_REQ);

		if (bIsLegitimateClient && myCurrentTeam[client] == TEAM_SURVIVOR && PlayerLevel[client] < AfxLevelReq) return false;

		//new Float:SourcLoc[3];
		//new Float:TargetPosition[3];
		//new t_Strength = 0;
		float t_Range = 0.0;

		if (AfxRange > 0.0) t_Range = AfxRange * (PlayerLevel[client] - AfxLevelReq);
		else t_Range = AfxRangeMax;
		if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
		else t_Range += AfxRangeBase;

		if (IsAuraEffect && StrContains(TheAuras, EffectT, true) != -1 || !IsAuraEffect && StrContains(TheDeaths, EffectT, true) != -1) {

			GetEntPropVector(vEntity, Prop_Send, "m_vecOrigin", fEntPos);
			if (IsInRange(fEntPos, ClientPos, AfxRangeMax)) {
				infectedTarget = vEntity;
				return true;
			}
		}
	}
	else {

		int ent = -1;
		for (int i = 0; i < GetArraySize(CommonAffixes); i++) {

			ent = GetArrayCell(CommonAffixes, i);
			
			if (ent == client) continue;
			if (!IsCommonInfected(ent)) {
				RemoveFromArray(CommonAffixes, i);
				continue;
			}
			if (vEntity >= 0 && ent != vEntity) continue;

			int superPos = GetCommonPos(ent);

			GetCommonValueAtPosEx(TheAuras, sizeof(TheAuras), superPos, SUPER_COMMON_AURA_EFFECT);
			GetCommonValueAtPosEx(TheDeaths, sizeof(TheDeaths), superPos, SUPER_COMMON_DEATH_EFFECT);

			/*

				At a certain level, like a lower one, it's just too much having to deal with auras, so some players will absolutely be oblivious to the shit
				going on and killing other players who CAN see them.
			*/
			if (bIsLegitimateClient && PlayerLevel[client] < GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_LEVEL_REQ)) return false;

			if (IsAuraEffect && StrContains(TheAuras, EffectT, true) != -1 || !IsAuraEffect && StrContains(TheDeaths, EffectT, true) != -1) {

				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", fEntPos);
				if (IsInRange(fEntPos, ClientPos, GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_MAX))) {
					infectedTarget = ent;
					return true;
				}
			} 
		}
	}
	return false;
}

stock SuperCommonsInPlay(char[] Name) {

	int size = GetArraySize(CommonAffixes);
	char text[64];
	int count = 0;
	int ent = -1;
	for (int i = 0; i < size; i++) {
		ent = GetArrayCell(CommonAffixes, i); //GetArrayString(Handle:CommonAffixes, i, text, sizeof(text));
		if (IsValidEntity(ent)) {
			GetEntPropString(ent, Prop_Data, "m_iName", text, sizeof(text));
			if (StrEqual(text, Name)) count++;
		}
	}
	return count;
}

/*

	This function is called when a common infected is spawned, and attempts to roll for affixes.
*/
stock int CreateCommonAffix(int entity) {
	if (iCommonAffixes < 1) return 0;
	if (GetArraySize(CommonAffixes) >= GetSuperCommonLimit()) return 0;	// there's a maximum limit on the # of super commons.
	int size = GetArraySize(a_CommonAffixes);
	float RollChance = 0.0;
	char Section_Name[64];
	char AuraEffectCCA[55];
	char ForceName[64];
	char Model[64];
	Format(ForceName, sizeof(ForceName), "none");
	bool bIsForceName = false;
	if (GetArraySize(SuperCommonQueue) > 0) {
		GetArrayString(SuperCommonQueue, 0, ForceName, sizeof(ForceName));
		RemoveFromArray(SuperCommonQueue, 0);
		bIsForceName = true;
	}
	int maxallowed = 1;
	//char iglowColour[3][4];
	//char glowColour[10];
	//float ModelSize = 1.0;
	bool SurvivorsAreBiled = SurvivorsBiled();
	for (int i = 0; i < size; i++) {
		CCAKeys				= GetArrayCell(a_CommonAffixes, i, 0);
		CCAValues			= GetArrayCell(a_CommonAffixes, i, 1);
		//if (GetArraySize(AfxSection) < 1 || GetArraySize(AfxKeys) < 1) continue;
		if (GetArrayCell(CCAValues, SUPER_COMMON_REQ_BILED_SURVIVORS) == 1 && !SurvivorsAreBiled) continue;
		maxallowed = GetArrayCell(CCAValues, SUPER_COMMON_MAX_ALLOWED);
		if (maxallowed < 0) maxallowed = 1;
		if (SuperCommonsInPlay(Section_Name) >= maxallowed) continue;
		RollChance = GetArrayCell(CCAValues, SUPER_COMMON_SPAWN_CHANCE);
		if (!bIsForceName && GetRandomInt(1, RoundToCeil(1.0 / RollChance)) > 1) continue;		// == 1 for successful roll
		CCASection			= GetArrayCell(a_CommonAffixes, i, 2);
		GetArrayString(CCASection, 0, Section_Name, sizeof(Section_Name));
		if (bIsForceName && !StrEqual(Section_Name, ForceName, false)) continue;

		SetEntPropString(entity, Prop_Data, "m_iName", Section_Name);

		int numOfSuperCommons = GetArraySize(CommonAffixes);
		PushArrayCell(CommonAffixes, entity);
		SetArrayCell(CommonAffixes, numOfSuperCommons, i, 1);
		
		// damage of special commons is held in their commonaffixes handle instead of separately like for specials, witches, and commons
		SetArrayCell(CommonAffixes, numOfSuperCommons, 0, 2);
		//OnCommonCreated(entity);

		GetArrayString(CCAValues, SUPER_COMMON_AURA_EFFECT, AuraEffectCCA, sizeof(AuraEffectCCA));
		GetArrayString(CCAValues, SUPER_COMMON_FORCE_MODEL, Model, sizeof(Model));
		if (IsModelPrecached(Model)) SetEntityModel(entity, Model);
		return 1;		// we only create one affix on a common. maybe we'll allow more down the road.
	}
	return 0;
}

stock int getDamageIncreaseFromBuffer(int entity, int damage) {
	float fStrength = 0.0;
	float cpos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", cpos);
	for (int i = 0; i < GetArraySize(CommonAffixes); i++) {
		int specialCommon = GetArrayCell(CommonAffixes, i);
		if (specialCommon == entity) continue;

		int superPos = GetArrayCell(CommonAffixes, i, 1);
		// only want to calculate if the specialCommon is a buffer
		char effect[4];
		GetCommonValueAtPosEx(effect, sizeof(effect), superPos, SUPER_COMMON_AURA_EFFECT);
		if (StrContains(effect, "b", true) == -1) continue;

		// if the entity isn't within range of this special common, the entity doesn't get whatever the damage buff of this super common is.
		float range = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_MAX);
		float tpos[3];
		GetEntPropVector(specialCommon, Prop_Send, "m_vecOrigin", tpos);
		if (GetVectorDistance(cpos, tpos) > range) continue;

		// this infected is within range, so we get the # of commons that are within range of the buffer.
		int count = setNumberOfEntitiesWithinRangeOfSpecialCommon(specialCommon, i, true);
		float multiplier = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_STRENGTH_TARGET);
		fStrength += (count * multiplier);
	}
	return RoundToCeil(damage * fStrength);
}

stock int setNumberOfEntitiesWithinRangeOfSpecialCommon(int entity, int pos = -1, bool getNumber = false) {
	int count = 0;
	if (getNumber) count = GetArrayCell(CommonAffixes, pos, 3);
	else {
		if (pos == -1) {
			pos = FindListPositionByEntity(entity, CommonAffixes);
			if (pos == -1) return 0;
		}
		int superPos = GetArrayCell(CommonAffixes, pos, 1);
		float range = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_MAX);
		count += LivingEntitiesInRangeByType(entity, range);
		count += LivingEntitiesInRangeByType(entity, range, 1);
		count += LivingEntitiesInRangeByType(entity, range, 2);
		count += LivingEntitiesInRangeByType(entity, range, 3);
		count += LivingEntitiesInRangeByType(entity, range, 4);
		SetArrayCell(CommonAffixes, pos, count, 3);
	}
	if (count > 0) return count;
	return 0;
}

public Action Timer_SetNumberOfEntitiesWithinRangeOfSpecialCommon(Handle timer) {
	if (!b_IsActiveRound) return Plugin_Stop;
	for (int i = 0; i < GetArraySize(CommonAffixes); i++) {
		int specialCommon = GetArrayCell(CommonAffixes, i);
		setNumberOfEntitiesWithinRangeOfSpecialCommon(specialCommon, i);
	}
	return Plugin_Continue;
}

stock CreateDamageStatusEffect(client, type = 0, target = 0, damage = 0, owner = 0, float RangeOverride = 0.0) {
	if (!IsSpecialCommon(client)) return;
	int superPos = GetCommonPos(client);
	float AfxStrengthLevel = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_LEVEL_STRENGTH);
	float AfxRangeMax = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_MAX);
	int AfxMultiplication = GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_ENEMY_MULTIPLICATION);
	int AfxStrength = GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_AURA_STRENGTH);
	float AfxStrengthTarget = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_STRENGTH_TARGET);
	float OnFireBase = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_ONFIRE_BASE_TIME);
	float OnFireLevel = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_ONFIRE_LEVEL);
	float OnFireMax = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_ONFIRE_MAX_TIME);
	int AfxLevelReq = GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_LEVEL_REQ);
	float ClientPosition[3];
	float TargetPosition[3];
	int t_Strength = 0;
	float t_Range = 0.0;
	float t_OnFireRange = 0.0;
	if (damage > 0) {//AfxStrength = damage;	// if we want to base the damage on a specific value, we can override here.
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPosition);
		int NumLivingEntities = LivingEntitiesInRange(client, ClientPosition, AfxRangeMax);
		if (NumLivingEntities > 1) damage = (damage / NumLivingEntities);
		if (target == 0 || IsLegitimateClient(target)) {
			for (int i = 1; i <= MaxClients; i++) {
				if (!IsLegitimateClientAlive(i) || (target != 0 && i != target) || PlayerLevel[i] < AfxLevelReq) continue;		// if type is 1 and target is 0 acid is spread to all players nearby. but if target is not 0 it is spread to only the player the acid zombie hits. or whatever type uses it.
				GetClientAbsOrigin(i, TargetPosition);
				t_Range = AfxRangeMax;
				if (GetVectorDistance(ClientPosition, TargetPosition) > (t_Range / 2)) continue;
				if (AfxMultiplication == 1) {
					if (AfxStrengthTarget < 0.0) t_Strength = AfxStrength * NumLivingEntities;
					else t_Strength = RoundToCeil(AfxStrength * (NumLivingEntities * AfxStrengthTarget));
				}
				else t_Strength = AfxStrength;
				if (AfxStrengthLevel > 0.0) t_Strength += RoundToCeil(t_Strength * ((PlayerLevel[i] - AfxLevelReq) * AfxStrengthLevel));
				t_OnFireRange = OnFireLevel * (PlayerLevel[i] - AfxLevelReq);
				t_OnFireRange += OnFireBase;
				if (t_OnFireRange > OnFireMax) t_OnFireRange = OnFireMax;
				if (IsSpecialCommonInRange(client, 'b')) t_Strength *= 2;//t_Strength = GetSpecialCommonDamage(t_Strength, client, 'b', i);
			}
		}
	}
	else CreateFireEx(client);
	//ClearSpecialCommon(client);
}

stock CreateBomberExplosion(client, target, char[] Effects, basedamage = 0) {

	//if (IsLegitimateClient(target) && !IsPlayerAlive(target)) return;
	if (!IsLegitimateClientAlive(target)) return;
	/*

		When a bomber dies, it explodes.
	*/
	int superPos = GetCommonPos(client);
	float AfxRange = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_PLAYER_LEVEL);
	float AfxStrengthLevel = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_LEVEL_STRENGTH);
	float AfxRangeMax = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_MAX);
	int AfxMultiplication = GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_ENEMY_MULTIPLICATION);
	int AfxStrength = GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_AURA_STRENGTH);
	int AfxChain = GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_CHAIN_REACTION);
	float AfxStrengthTarget = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_STRENGTH_TARGET);
	float AfxRangeBase = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_MIN);
	int AfxLevelReq = GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_LEVEL_REQ);
	int isRaw = GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_RAW_STRENGTH);
	int rawCommon = GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_RAW_COMMON_STRENGTH);
	int rawPlayer = GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_RAW_PLAYER_STRENGTH);


	if (IsSpecialCommon(client) && myCurrentTeam[target] == TEAM_SURVIVOR && PlayerLevel[target] < AfxLevelReq) return;

	float SourcLoc[3];
	float TargetPosition[3];
	int t_Strength = 0;
	float t_Range = 0.0;

	GetClientAbsOrigin(target, SourcLoc);
	//else GetEntPropVector(target, Prop_Send, "m_vecOrigin", SourcLoc);
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", TargetPosition);

	if (AfxRange > 0.0) t_Range = AfxRange * (PlayerLevel[target] - AfxLevelReq);
	else t_Range = AfxRangeMax;
	if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
	else t_Range += AfxRangeBase;

	if (myCurrentTeam[target] == TEAM_SURVIVOR && target != client) {

		if (PlayerLevel[target] < AfxLevelReq) return;
		if (GetVectorDistance(SourcLoc, TargetPosition) > (t_Range / 2)) return;
	}

	int NumLivingEntities = 0;
	int rawStrength = 0;
	int abilityStrength = 0;
	if (isRaw == 0) {
		NumLivingEntities = LivingEntitiesInRange(client, SourcLoc, AfxRangeMax);
		if (AfxMultiplication == 1) {
			if (AfxStrengthTarget < 0.0) t_Strength = basedamage + (AfxStrength * NumLivingEntities);
			else t_Strength = RoundToCeil(basedamage + (AfxStrength * (NumLivingEntities * AfxStrengthTarget)));
		}
		else t_Strength = (basedamage + AfxStrength);
	}
	else {
		rawStrength = rawCommon * LivingEntitiesInRange(client, SourcLoc, AfxRangeMax, 1);
		rawStrength += rawPlayer * LivingEntitiesInRange(client, SourcLoc, AfxRangeMax, 4);
	}

	for (int i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || PlayerLevel[i] < AfxLevelReq) continue;
		GetClientAbsOrigin(i, TargetPosition);

		if (AfxRange > 0.0) t_Range = AfxRange * (PlayerLevel[i] - AfxLevelReq);
		else t_Range = AfxRangeMax;
		if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
		else t_Range += AfxRangeBase;
		if (GetVectorDistance(SourcLoc, TargetPosition) > (t_Range / 2) || !(GetEntityFlags(i) & FL_ONGROUND)) continue;		// player not within blast radius, takes no damage. Or playing is floating.

		// Because range can fluctuate, we want to get the # of entities within range for EACH player individually.
		if (isRaw == 0) {
			abilityStrength = t_Strength;
		}
		else {
			abilityStrength = rawStrength;
		}
		if (AfxStrengthLevel > 0.0) abilityStrength += RoundToCeil(abilityStrength * ((PlayerLevel[i] - AfxLevelReq) * AfxStrengthLevel));

		//if (t_Strength > GetClientHealth(i)) IncapacitateOrKill(i);
		//else SetEntityHealth(i, GetClientHealth(i) - t_Strength);
		if (abilityStrength > 0) SetClientTotalHealth(client, i, abilityStrength);

		if (client == target) {

			// To prevent a never-ending chain reaction, we don't allow it to target the bomber that caused it.

			if (myCurrentTeam[i] == TEAM_SURVIVOR && AfxChain == 1) CreateBomberExplosion(client, i, Effects);
		}
	}
	if (StrContains(Effects, "e", true) != -1 || StrContains(Effects, "x", true) != -1) {

		CreateExplosion(target);	// boom boom audio and effect on the location.
		if (!IsFakeClient(target)) ScreenShake(target);
	}
	if (StrContains(Effects, "B", true) != -1) {

		if (!ISBILED[target]) {

			SDKCall(g_hCallVomitOnPlayer, target, client, true);
			CreateTimer(15.0, Timer_RemoveBileStatus, target, TIMER_FLAG_NO_MAPCHANGE);
			ISBILED[target] = true;
			StaggerPlayer(target, client);
		}
	}
	if (StrContains(Effects, "a", true) != -1) {

		CreateDamageStatusEffect(client, 4, target, abilityStrength);
	}

	if (client == target) CreateBomberExplosion(client, 0, Effects);
}

stock int GetCommonPos(int entity) {
	int pos = FindListPositionByEntity(entity, CommonAffixes);
	if (pos >= 0) return GetArrayCell(CommonAffixes, pos, 1);
	return -1;
}

stock int GetCommonValueIntAtPosEx(int pos, int value) {
	h_CommonValues		= GetArrayCell(a_CommonAffixes, pos, 1);
	int result = GetArrayCell(h_CommonValues, value);
	return result;
}

stock float GetCommonValueFloatAtPosEx(int pos, int value) {	// can override the section
	h_CommonValues		= GetArrayCell(a_CommonAffixes, pos, 1);
	float result = GetArrayCell(h_CommonValues, value);
	return result;
}

stock GetCommonValueAtPosEx(char[] TheString, TheSize, int superPos, valPos) {
	h_CommonValues		= GetArrayCell(a_CommonAffixes, superPos, 1);
	GetArrayString(h_CommonValues, valPos, TheString, TheSize);
}

stock GetCommonValue(char[] TheString, TheSize, entity, char[] Key, pos = 0, bool incrementNonZeroPos = true) {
	char AffixName[2][64];
	int ent = -1;
	if (pos > 0 && incrementNonZeroPos) pos++;
	int size = GetArraySize(CommonAffixes);
	for (int i = pos; i < size; i++) {

		//GetArrayString(Handle:CommonAffixes, i, SectionName, sizeof(SectionName));
		//ent = FindEntityInString(SectionName);
		ent = GetArrayCell(CommonAffixes, i);
		if (!IsValidEntity(ent) || !IsCommonInfected(ent)) {
			RemoveFromArray(CommonAffixes, i);
			i--;
			size--;
			continue;
		}
		if (entity != ent) continue;	// searching for a specific entity.

		//Format(AffixName[0], sizeof(AffixName[]), "%s", SectionName);
		//ExplodeString(AffixName[0], ":", AffixName, 2, 64);
		GetEntPropString(entity, Prop_Data, "m_iName", AffixName[0], sizeof(AffixName[]));

		ent = FindListPositionBySearchKey(AffixName[0], a_CommonAffixes, 2, DEBUG);
		if (ent >= 0) {

			h_CommonKeys		= GetArrayCell(a_CommonAffixes, ent, 0);
			h_CommonValues		= GetArrayCell(a_CommonAffixes, ent, 1);
			FormatKeyValue(TheString, TheSize, h_CommonKeys, h_CommonValues, Key, _, _, SUPER_COMMON_FIRST_RANDOM_KEY_POS, false);
			return i;
		}
	}
	Format(TheString, TheSize, "-1");
	return -1;
}

stock GetCommonValueInt(entity, char[] Key) {
	char AffixName[2][64];
	int ent = -1;

	char text[64];

	int size = GetArraySize(CommonAffixes);
	for (int i = 0; i < size; i++) {

		//GetArrayString(Handle:CommonAffixes, i, SectionName, sizeof(SectionName));
		//ent = FindEntityInString(SectionName);
		ent = GetArrayCell(CommonAffixes, i);
		if (!IsValidEntity(ent) || !IsCommonInfected(ent)) {

			RemoveFromArray(CommonAffixes, i);
			i--;
			size--;
			continue;
		}
		if (entity != ent) continue;	// searching for a specific entity.
		GetEntPropString(entity, Prop_Data, "m_iName", AffixName[0], sizeof(AffixName[]));
		//Format(AffixName[0], sizeof(AffixName[]), "%s", SectionName);
		//ExplodeString(AffixName[0], ":", AffixName, 2, 64);

		ent = FindListPositionBySearchKey(AffixName[0], a_CommonAffixes, 2, DEBUG);
		if (ent < 0) continue;
		h_CommonKeys		= GetArrayCell(a_CommonAffixes, ent, 0);
		h_CommonValues		= GetArrayCell(a_CommonAffixes, ent, 1);
		FormatKeyValue(text, sizeof(text), h_CommonKeys, h_CommonValues, Key);
		return StringToInt(text);
	}
	return -1;
}

stock DrawSpecialInfectedAffixes(int client, int target = -1, float fRange = 256.0) {
	if (target != -1) {
		float clientPos[3];
		float targetPos[3];
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPos);
		for (int c = 1; c <= MaxClients; c++) {
			if (c == target || !IsLegitimateClient(c) || FindZombieClass(c) != ZOMBIECLASS_TANK || !bIsDefenderTank[c]) continue;
			GetEntPropVector(c, Prop_Send, "m_vecOrigin", clientPos);
			if (GetVectorDistance(clientPos, targetPos) <= fRange) return 1;
		}
		return 0;
	}
	char AfxDrawColour[10];
	char AfxDrawPos[10];
	if (FindZombieClass(client) == ZOMBIECLASS_TANK) {
		if (bIsDefenderTank[client]) {
			Format(AfxDrawColour, sizeof(AfxDrawColour), "blue:blue");
			Format(AfxDrawPos, sizeof(AfxDrawPos), "20.0:30.0");
		}
	}
	else return 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;
		CreateRingFromSuperSolo(client, fRange, iDefenderCommonMenuPos, false, 0.25, i);
	}
	return 1;
}

stock DrawCommonAffixes(entity, int superPos) {
	char AfxEffect[64];
	float EntityPos[3];
	float TargetPos[3];
// superpos: 7
// effect: b , range: 0.000 type: 0
// Level req: 0
// Draw color: 38 draw pos: 39
// Draw color: -1 draw pos: -1

	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", EntityPos);
	GetCommonValueAtPosEx(AfxEffect, sizeof(AfxEffect), superPos, SUPER_COMMON_AURA_EFFECT);
	float AfxRangeMax		= GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_MAX);
	int AfxDrawType			= GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_DRAW_TYPE);
	if (AfxDrawType == -1) return;

	int AfxLevelReq = GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_LEVEL_REQ);
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;
		if (myCurrentTeam[i] == TEAM_SURVIVOR && PlayerLevel[i] < AfxLevelReq) continue;
		if (AfxDrawType == 0) CreateRingForCommonEffect(entity, AfxRangeMax, superPos, false, 0.25, i);
	}

	

	//Now we execute the effects, after all players have clearly seen them.

	int t_Strength			= 0;
	int AfxStrength			= GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_AURA_STRENGTH);
	int AfxMultiplication	= GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_ENEMY_MULTIPLICATION);
	float AfxStrengthLevel = GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_LEVEL_STRENGTH);
	
	if (AfxMultiplication == 1) t_Strength = AfxStrength * LivingEntitiesInRange(entity, EntityPos, AfxRangeMax);
	else t_Strength = AfxStrength;

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClientAlive(i) || myCurrentTeam[i] != TEAM_SURVIVOR || PlayerLevel[i] < AfxLevelReq) continue;
		GetClientAbsOrigin(i, TargetPos);
		// Player is outside the applicable range.
		if (!IsInRange(EntityPos, TargetPos, AfxRangeMax)) continue;
		if (AfxStrengthLevel > 0.0) t_Strength += RoundToCeil(t_Strength * (PlayerLevel[i] * AfxStrengthLevel));
		//If they are not immune to the effects, we consider the effects.
		if (StrContains(AfxEffect, "d", true) != -1) {
			//if (t_Strength > GetClientHealth(i)) IncapacitateOrKill(i);
			//else SetEntityHealth(i, GetClientHealth(i) - t_Strength);
			SetClientTotalHealth(entity, i, t_Strength);
		}
		if (StrContains(AfxEffect, "l", true) != -1) {
			//	We don't want multiple blinders to spam blind a player who is already blind.
			//	Furthermore, we don't want it to accidentally blind a player AFTER it dies and leave them permablind.
			//	ISBLIND is tied a timer, and when the timer reverses the blind, it will close the handle.
			if (ISBLIND[i] == INVALID_HANDLE) BlindPlayer(i, 0.0, 255);
		}
		if (StrContains(AfxEffect, "r", true) != -1) {
			//	Freeze players, teleport them up a lil bit.
			if (ISFROZEN[i] == INVALID_HANDLE) FrozenPlayer(i, 0.0);
		}
	}
}

bool ForceClearSpecialCommon(entity, int client = 0, bool killMob = true) {
	int pos		= FindListPositionByEntity(entity, CommonAffixes);
	if (client == 0) {
		if (pos >= 0) RemoveFromArray(CommonAffixes, pos); // bug with common/specials/infected having insane hp is deleting entity from array instead of the position where entity was found xD
	}
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || client > 0 && i != client) continue;
		pos			= FindListPositionByEntity(entity, SpecialCommon[i]);
		if (pos >= 0) RemoveFromArray(SpecialCommon[i], pos);
	}
	if (client == 0 && killMob && IsCommonInfected(entity)) {
		//SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		//SDKUnhook(entity, SDKHook_TraceAttack, OnTraceAttack);
		if (!CommonInfectedModel(entity, FALLEN_SURVIVOR_MODEL)) AcceptEntityInput(entity, "BecomeRagdoll");
		else SetEntProp(entity, Prop_Data, "m_iHealth", 1);
	}
	return true;
}

stock ClearSpecialCommon(entity, bool IsCommonEntity = true, playerDamage = 0, lastAttacker = -1) {
	int pos = FindListPositionByEntity(entity, CommonAffixes);
	if (pos >= 0) {

		if (IsCommonEntity && IsSpecialCommon(entity)) {

			int superPos = GetArrayCell(CommonAffixes, pos, 1);
			char CommonEntityEffect[55];
			GetCommonValueAtPosEx(CommonEntityEffect, sizeof(CommonEntityEffect), superPos, SUPER_COMMON_DEATH_EFFECT);
			// if (IsLegitimateClientAlive(lastAttacker) && GetClientTeam(lastAttacker) == TEAM_SURVIVOR && StrContains(CommonEntityEffect, "f", true) != -1) {
			// 	CreateDamageStatusEffect(entity);
			// }
			if (StrContains(CommonEntityEffect, "f", true) != -1) {
				CreateDamageStatusEffect(entity);
			}

			for (int y = 1; superPos >= 0 && y <= MaxClients; y++) {

				if (!IsLegitimateClientAlive(y)) continue; // || GetClientTeam(y) != TEAM_SURVIVOR) continue;
				if (StrContains(CommonEntityEffect, "x", true) != -1 && IsSpecialCommonInRange(y, 'x', entity, false)) {
					CreateBomberExplosion(entity, y, "x");
				}
				if (StrContains(CommonEntityEffect, "b", true) != -1 && IsSpecialCommonInRange(y, 'b', entity, false) && FindInfectedClient() > 0 && !ISBILED[y]) {
					SDKCall(g_hCallVomitOnPlayer, y, FindInfectedClient(true), true);
					CreateTimer(15.0, Timer_RemoveBileStatus, y, TIMER_FLAG_NO_MAPCHANGE);
					ISBILED[y] = true;
				}
				if (StrContains(CommonEntityEffect, "a", true) != -1 && IsSpecialCommonInRange(y, 'a', entity, false) && FindInfectedClient() > 0) {

					CreateAcid(FindInfectedClient(true), y, 48.0);
					break;
				}
				if (StrContains(CommonEntityEffect, "e", true) != -1 && IsSpecialCommonInRange(y, 'e', entity, false)) {	// false so we compare death effect instead of aura effect which defaults to true

					if (ISEXPLODE[y] == INVALID_HANDLE) {

						ISEXPLODETIME[y] = 0.0;
						Handle packagey;
						ISEXPLODE[y] = CreateDataTimer(GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_DEATH_INTERVAL), Timer_Explode, packagey, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						
						WritePackCell(packagey, y);
						WritePackCell(packagey, GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_AURA_STRENGTH));
						WritePackFloat(packagey, GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_STRENGTH_TARGET));
						WritePackFloat(packagey, GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_LEVEL_STRENGTH));
						WritePackFloat(packagey, GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_RANGE_MAX));
						WritePackFloat(packagey, GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_DEATH_BASE_TIME));
						WritePackFloat(packagey, GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_DEATH_INTERVAL));
						WritePackFloat(packagey, GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_DEATH_MAX_TIME));
						WritePackCell(packagey, GetCommonValueIntAtPosEx(superPos, SUPER_COMMON_LEVEL_REQ));
					}
				}
				if (StrContains(CommonEntityEffect, "s", true) != -1 && IsSpecialCommonInRange(y, 's', entity, false)) {

					if (!ISSLOW[y]) {

						SetSpeedMultiplierBase(y, GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_DEATH_MULTIPLIER));
						SetEntityMoveType(y, MOVETYPE_WALK);
						ISSLOW[y] = true;
						CreateTimer(GetCommonValueFloatAtPosEx(superPos, SUPER_COMMON_DEATH_BASE_TIME), Timer_Slow, y, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				if (StrContains(CommonEntityEffect, "f", true) != -1) {

					CreateDamageStatusEffect(entity, _, y, playerDamage, lastAttacker);
					//if (FindZombieClass(y) == ZOMBIECLASS_TANK) ChangeTankState(y, "burn");
				}
			}
			CalculateInfectedDamageAward(entity, lastAttacker, superPos);
		}
		ForceClearSpecialCommon(entity);
		//if (pos < GetArraySize(CommonList)) RemoveFromArray(CommonList, pos);
		//RemoveCommonAffixes(entity);
		//RemoveCommonInfected(entity, true);
		//if (IsCommonInfected(entity)) AcceptEntityInput(entity, "BecomeRagdoll");
		//if (iDeleteSupersOnDeath == 1 && IsValidEntity(entity)) AcceptEntityInput(entity, "Kill");
	}
	//if (IsValidEntity(entity)) SetInfectedHealth(entity, 1);	// this is so it dies right away.
	return playerDamage;
}