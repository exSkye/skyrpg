public Action:Timer_ZeroGravity(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		ModifyGravity(client);
	}
	//ZeroGravityTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_IsMeleeCooldown(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) {

		bIsMeleeCooldown[client] = false;
	}
	return Plugin_Stop;
}

public Action:Timer_DeathCheck(Handle:timer) {

	if (!b_IsActiveRound) {

		return Plugin_Stop;
	}
	if (IsAllSurvivorsDead()) {

		ForceServerCommand("scenario_end");
		CallRoundIsOver();
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Timer_PlayTimeCounter(Handle:timer) {

	if (!b_IsActiveRound) {

		return Plugin_Stop;
	}
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && !b_IsLoading[i]) {

			LastPlayLength[i]++;
		}
	}

	return Plugin_Continue;
}

public Action:Timer_TeleportRespawn(Handle:timer, any:client) {

	if (IsLegitimateClient(client) && IsPlayerAlive(client)) {

		GiveMaximumHealth(client);
		TeleportEntity(client, DeathLocation[client], NULL_VECTOR, NULL_VECTOR);
		/*if (h_PreviousDeath[client] == -1) TeleportEntity(client, DeathLocation[client], NULL_VECTOR, NULL_VECTOR);
		else {

			new TargetClient = h_PreviousDeath[client];
			new Float:TeleportLocation[3];
			GetClientAbsOrigin(TargetClient, Float:TeleportLocation);
			TeleportEntity(client, TeleportLocation, NULL_VECTOR, NULL_VECTOR);
		}*/
	}

	return Plugin_Stop;
}

public Action:Timer_GiveMaximumHealth(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		GiveMaximumHealth(client);		// So instant heal doesn't put a player above their maximum health pool.
	}

	return Plugin_Stop;
}

public Action:Timer_DestroyCombustion(Handle:timer, any:entity)
{
	if (!IsValidEntity(entity)) return Plugin_Stop;
	AcceptEntityInput(entity, "Kill");
	return Plugin_Stop;
}

/*public Action:Timer_DestroyDiscoveryItem(Handle:timer, any:entity) {

	if (IsValidEntity(entity)) {

		new client				= FindAnyRandomClient();

		if (client == -1) return Plugin_Stop;

		decl String:EName[64];
		GetEntPropString(entity, Prop_Data, "m_iName", EName, sizeof(EName));
		if (StrEqual(EName, "slate") || IsStoreItem(client, EName) || IsTalentExists(EName)) {

			if (!AcceptEntityInput(entity, "Kill")) RemoveEdict(entity);
		}
	}

	return Plugin_Stop;
}*/

public Action:Timer_SlowPlayer(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplierBase[client]);
	}
	//SlowMultiplierTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_AwardSkyPoints(Handle:timer) {

	if (!b_IsActiveRound) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR) CheckSkyPointsAward(i);
	}

	return Plugin_Continue;
}

stock CheckSkyPointsAward(client) {

	new SkyPointsAwardTime		=	StringToInt(GetConfigValue("sky points awarded _"));
	new SkyPointsAwardValue		=	StringToInt(GetConfigValue("sky points time required?"));
	new SkyPointsAwardAmount	=	StringToInt(GetConfigValue("sky points award amount?"));

	new seconds					=	0;
	new minutes					=	0;
	new hours					=	0;
	new days					=	0;
	new oldminutes				=	0;
	new oldhours				=	0;
	new olddays					=	0;

	seconds				=	TimePlayed[client];
	while (seconds >= 86400) {

		olddays++;
		seconds -= 86400;
	}
	while (seconds >= 3600) {

		oldhours++;
		seconds -= 3600;
	}
	while (seconds >= 60) {

		oldminutes++;
		seconds -= 60;
	}

	TimePlayed[client]++;

	seconds = TimePlayed[client];

	while (seconds >= 86400) {

		days++;
		seconds -= 86400;
	}
	while (seconds >= 3600) {

		hours++;
		seconds -= 3600;
	}
	while (seconds >= 60) {

		minutes++;
		seconds -= 60;

	}
	if (SkyPointsAwardTime == 2 && days != olddays && days % SkyPointsAwardValue == 0) AwardSkyPoints(client, SkyPointsAwardAmount);
	if (SkyPointsAwardTime == 1 && hours != oldhours && hours % SkyPointsAwardValue == 0) AwardSkyPoints(client, SkyPointsAwardAmount);
	if (SkyPointsAwardTime == 0 && minutes != oldminutes && minutes % SkyPointsAwardValue == 0) AwardSkyPoints(client, SkyPointsAwardAmount);
}

public Action:Timer_SpeedIncrease(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		SpeedIncrease(client);
	}
	//SpeedMultiplierTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_DamageIncrease(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		DamageMultiplier[client] = DamageMultiplierBase[client];
	}
	//DamageMultiplierTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_BlindPlayer(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) BlindPlayer(client);
	return Plugin_Stop;
}

public Action:Timer_DetectGroundTouch(Handle:timer, any:client) {

	if (IsClientHuman(client) && IsPlayerAlive(client)) {

		if (GetClientTeam(client) == TEAM_SURVIVOR && !(GetEntityFlags(client) & FL_ONGROUND) && b_IsJumping[client] && L4D2_GetInfectedAttacker(client) == -1 && !IsTanksActive()) return Plugin_Continue;
		b_IsJumping[client] = false;
		ModifyGravity(client);
	}
	return Plugin_Stop;
}

public Action:Timer_ResetGravity(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) ModifyGravity(client);
	return Plugin_Stop;
}

public Action:Timer_CloakingDeviceBreakdown(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	return Plugin_Stop;
}

public Action:Timer_ResetPlayerHealth(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		LoadHealthMaximum(client);
		GiveMaximumHealth(client);
	}
	return Plugin_Stop;
}

public Action:Timer_RemoveImmune(Handle:timer, Handle:packy) {

	ResetPack(packy);
	new client			=	ReadPackCell(packy);
	new pos				=	ReadPackCell(packy);

	if (client != -1 && IsClientActual(client) && !IsFakeClient(client)) {

		SetArrayString(PlayerAbilitiesImmune[client], pos, "0");
	}
	else {

		SetArrayString(PlayerAbilitiesImmune_Bots, pos, "0");
	}

	return Plugin_Stop;
}

public Action:Timer_RemoveCooldown(Handle:timer, Handle:packi) {

	ResetPack(packi);
	new client			=	ReadPackCell(packi);
	new pos				=	ReadPackCell(packi);

	if (client != -1 && IsClientActual(client) && !IsFakeClient(client)) {

		SetArrayString(PlayerAbilitiesCooldown[client], pos, "0");
	}
	else {

		SetArrayString(PlayerAbilitiesCooldown_Bots, pos, "0");
	}
	//PlayerAbilitiesCooldown[client][pos] = 0;

	return Plugin_Stop;
}

public Action:Timer_IsIncapacitated(Handle:timer, any:client) {

	static attacker					=	0;

	if (IsLegitimateClientAlive(client) && IsIncapacitated(client)) {
	
		if (attacker == 0) attacker	=	L4D2_GetInfectedAttacker(client);
	
		if (L4D2_GetInfectedAttacker(client) == -1) {
		
			if (attacker == -1) attacker			=	0;
			FindAbilityByTrigger(client, attacker, 'n', FindZombieClass(client), 0);
			if (attacker > 0 && IsClientInGame(attacker)) FindAbilityByTrigger(attacker, client, 'M', FindZombieClass(attacker), 0);
			attacker								=	0;
			return Plugin_Stop;
		}
		return Plugin_Continue;
	}
	attacker						=	0;
	return Plugin_Stop;
}

public Action:Timer_CoveredInBile(Handle:timer, Handle:packe) {

	ResetPack(packe);
	new client			=	ReadPackCell(packe);
	new victim			=	ReadPackCell(packe);

	new ExperienceEarned = 0;
	new Float:PointsEarned = 0.0;

	if (IsLegitimateClient(client) && IsLegitimateClient(victim)) {

		decl String:VictimName[MAX_NAME_LENGTH];
		GetClientName(victim, VictimName, sizeof(VictimName));

		if (GetClientTeam(client) == TEAM_SURVIVOR) {

			ExperienceEarned = RoundToFloor(StringToFloat(GetConfigValue("experience multiplier survivor?")) * CoveredInBile[victim][client]);
			PointsEarned = StringToFloat(GetConfigValue("points multiplier survivor?")) * CoveredInBile[victim][client];
		}
		else if (GetClientTeam(client) == TEAM_INFECTED) {

			ExperienceEarned = RoundToFloor(StringToFloat(GetConfigValue("experience multiplier infected?")) * CoveredInBile[victim][client]);
			PointsEarned = StringToFloat(GetConfigValue("points multiplier infected?")) * CoveredInBile[victim][client];
		}

		new RPGMode					= StringToInt(GetConfigValue("rpg mode?"));

		if (RPGMode > 0) {

			ExperienceLevel[client] += ExperienceEarned;
			if (ExperienceLevel[client] > CheckExperienceRequirement(client)) ExperienceLevel[client] = CheckExperienceRequirement(client);
			if (GetClientTeam(victim) == TEAM_INFECTED) PrintToChat(client, "%T", "Bile Damage Experience", client, white, orange, white, green, white, VictimName, ExperienceEarned);
			else if (GetClientTeam(victim) == TEAM_SURVIVOR) PrintToChat(client, "%T", "Bile Damage Experience", client, white, blue, white, green, white, VictimName, ExperienceEarned);
		}
		if (RPGMode != 1) {

			Points[client] += PointsEarned;
			if (GetClientTeam(victim) == TEAM_INFECTED) PrintToChat(client, "%T", "Bile Damage Points", client, white, orange, white, green, white, VictimName, PointsEarned);
			else if (GetClientTeam(victim) == TEAM_SURVIVOR) PrintToChat(client, "%T", "Bile Damage Points", client, white, blue, white, green, white, VictimName, PointsEarned);
		}

		FindAbilityByTrigger(client, victim, 'b', FindZombieClass(client), 0);
	}

	CoveredInBile[victim][client] = -1;
	return Plugin_Stop;
}

public Action:Timer_IsNotImmune(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) b_IsImmune[client] = false;
	return Plugin_Stop;
}

public Action:Timer_TankCooldown(Handle:timer) {

	static Float:Counter								=	0.0;

	if (!b_IsActiveRound) {

		Counter											=	0.0;
		return Plugin_Stop;
	}
	Counter												+=	1.0;
	f_TankCooldown										-=	1.0;
	if (f_TankCooldown < 1.0) {

		Counter											=	0.0;
		f_TankCooldown									=	-1.0;
		for (new i = 1; i <= MaxClients; i++) {

			if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) == TEAM_INFECTED || ReadyUp_GetGameMode() != 2)) {

				PrintToChat(i, "%T", "Tank Cooldown Complete", i, orange, white);
			}
		}

		return Plugin_Stop;
	}
	if (Counter >= StringToFloat(GetConfigValue("versus tank notice?"))) {

		Counter											=	0.0;
		for (new i = 1; i <= MaxClients; i++) {

			if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) == TEAM_INFECTED || ReadyUp_GetGameMode() != 2)) {

				PrintToChat(i, "%T", "Tank Cooldown Remaining", i, green, f_TankCooldown, white, orange, white);
			}
		}
	}

	return Plugin_Continue;
}

stock CreateAura(target, auraId) {

	new Handle:Keys = CreateArray(8);
	new Handle:Values = CreateArray(8);
	new size = GetArraySize(a_Uncontrollable_Talents);

	/*

		The aura distance grows when there are other infected with the same aura id within the aura distance.
		We grab the target id so that we don't count themselves as a clone in the calculation.
	*/
	new Handle:TalentKeys = CreateArray(8);
	new Handle:TalentValues = CreateArray(8);
	new Float:auraDistance = 0.0;
	new Float:auraDistanceMin = 0.0;
	new Float:Origin[3];
	new Float:Pos[3];
	decl String:auraeffects[16];
	decl String:aurastrength[16];
	decl String:clientTeam[16];
	new isDisabled = 0;
	new i_auraId = 0;

	//if (!IsWitch(target) && !IsCommonInfected(target)) return;

	for (new i = 0; i < size; i++) {

		Keys = GetArrayCell(a_Uncontrollable_Talents, i, 0);
		Values = GetArrayCell(a_Uncontrollable_Talents, i, 1);

		//	If the aura is disabled on the server, we don't show it at all.
		isDisabled = StringToInt(GetKeyValue(Keys, Values, "disabled?"));
		if (isDisabled == 1) continue;

		i_auraId = StringToInt(GetKeyValue(Keys, Values, "aura id?"));
		if (i_auraId != auraId) {

			continue;
		}
		//if (!IsValidEntity(target)) return;
		Format(auraeffects, sizeof(auraeffects), "%s", GetKeyValue(Keys, Values, "aura effect?"));
		Format(aurastrength, sizeof(aurastrength), "%s", GetKeyValue(Keys, Values, "aura strength?"));
		auraDistanceMin = StringToFloat(GetKeyValue(Keys, Values, "range minimum?"));

		auraDistance = StringToFloat(GetKeyValue(Keys, Values, "aura distance?"));

		/*

			For each aura of the same type within range of each other, a distance multiplier is generated to increase
			their effective ranges. However, for balance purposes, auras will not be considered within range of each
			other if the overlap is caused due to the distance multiplier. That could cause extremely-long chains of
			damage.
		*/
		auraDistance += auraDistance * FindAuraClone(target, auraId, StringToFloat(GetKeyValue(Keys, Values, "aura increase clone?")));

		/*

			The aura in the config matches the aura assigned to the common infected or witch.
		*/
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", Origin);

		new i_Colour[4];
		new TargetEntityId = 0;

		for (new y = 1; y <= MaxClients; y++) {

			/*

				Infected players can be affected by auras (versus and coop)
				However, the defensive / support functions of auras for infected will be
				coded in later. For now, let's get the offensive (damage, specifically) working
				to prototype the module.
			*/
			if (IsLegitimateClient(y) && !IsFakeClient(y)) {

				/*

					Make sure the client Aura list is the same size as the server aura list.
				*/
				if (GetArraySize(Handle:AuraImmune[y]) != size) ResizeArray(Handle:AuraImmune[y], size);

				//	If the team of the player isn't among the listed affected team(s) of the aura, skip the client.
				Format(clientTeam, sizeof(clientTeam), "%d", GetClientTeam(y));
				if (StrContains(GetKeyValue(Keys, Values, "team affected?"), clientTeam, false) == -1) continue;

				/*

					The rest of the aura distance calculations must now be done before the aura is displayed to players.
				*/
				auraDistance -= auraDistance * (StringToFloat(GetKeyValue(Keys, Values, "range reduction?")) * SkyLevel[y]);
				auraDistanceMin *= auraDistance;
				if (auraDistance < auraDistanceMin) {

					auraDistance = auraDistanceMin;
				}
				/*

					If the player is not high enough level for the aura, they don't even see it.
				*/
				if (SkyLevel[y] < StringToInt(GetKeyValue(Keys, Values, "sky level affected?"))) continue;

				/*

					Show the client the aura.
				*/
				Origin[2] += StringToFloat(GetKeyValue(Keys, Values, "height?"));
				i_Colour[0]	= StringToInt(GetKeyValue(Keys, Values, "r"));
				i_Colour[1]	= StringToInt(GetKeyValue(Keys, Values, "g"));
				i_Colour[2]	= StringToInt(GetKeyValue(Keys, Values, "b"));
				i_Colour[3]	= StringToInt(GetKeyValue(Keys, Values, "a"));

				//TargetEntityId = GetArrayCell(Handle:AuraImmune[y], i, 1);

				//if (TargetEntityId != target) {

				TE_SetupBeamRingPoint(Origin, 1.0, 1.0, g_iSprite, g_BeaconSprite, 0, 15, 0.2, 2.0, 0.5, i_Colour, 20, 0);
				TE_SendToClient(y);

					/*SetArrayCell(Handle:AuraImmune[y], i, target, 1);

					new Handle:packie;
					CreateDataTimer(StringToFloat(GetKeyValue(Keys, Values, "aura display delay?")), Timer_BeamImmune, packie, TIMER_FLAG_NO_MAPCHANGE);
					WritePackCell(packie, y);
					WritePackCell(packie, target);*/
				//} else LogMessage("[ DISPLAY OF AURA IS ON COOLDOWN.");

				GetClientAbsOrigin(y, Pos);

				/*

					If the survivor is outside the aura range, they don't suffer the effects of the aura.
				*/
				if (GetVectorDistance(Pos, Origin) > auraDistance) continue;
				/*

					If the player is immune to the aura, we don't give them the effects.
				*/
				//TargetEntityId = GetArrayCell(Handle:AuraImmune[y], i, 0);
				if (TargetEntityId == target) continue;

				/*

					Whether the player is immune to the aura or not, we grant them skills that require being within range of specific auras.
				*/
				FindAbilityByTrigger(y, target, 'W', FindZombieClass(y), 0);

				/*
					Make the player immune to this aura.
					We set the value to the target id, so that when the timer ends, we can use the value to
					verify whether the entity it relates to still exists or not. If it doesn't, we don't need
					to modify the list, as that is done so automatically when the entity is destroyed.
				*/
				//SetArrayCell(Handle:AuraImmune[y], i, target, 0);
				/*

					Pack Order:
					Client, Target (Entity Id), Cell Position
				*/
				new Handle:packet;
				CreateDataTimer(StringToFloat(GetKeyValue(Keys, Values, "cooldown?")), Timer_AuraImmune, packet, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(packet, y);
				WritePackCell(packet, target);

				TriggerAura(y, auraeffects, aurastrength, target);
			}
		}
	}
}

stock TriggerAura(client, String:auraeffects[], String:aurastrength[], entityId) {

	if (FindCharInString(auraeffects, 'd') != -1) DamageAura(client, aurastrength, entityId);
}

stock DamageAura(client, String:aurastrength[], entityId) {

	/*

		We need the entityid so that we can call certain functions, such as IncapacitateOrKill.
	*/
	new Float:f_Strength = -1.0;
	new i_Strength = -1;
	if (FindCharInString(aurastrength, '.') == -1) {

		/*

			Strength is a raw integer value.
			Aura strength never increases, because auras can stack, and that's dangerous enough
			considering only witches and common infected generate auras.
		*/
		i_Strength = StringToInt(aurastrength);
	}
	else f_Strength = StringToFloat(aurastrength);

	if (f_Strength != -1.0) i_Strength = RoundToCeil(f_Strength * GetMaximumHealth(client));
	if (IsIncapacitated(client)) {

		SetClientTotalHealth(client, i_Strength);
		// Find abilities that are triggered when a survivor player takes DAMAGE from an aura.
		FindAbilityByTrigger(client, entityId, 'Z', FindZombieClass(client), i_Strength);
	}
	else if (!IsIncapacitated(client)) {

		IncapacitateOrKill(client);
		FindAbilityByTrigger(client, entityId, 'z', FindZombieClass(client), i_Strength);
	}
}

public Action:Timer_AuraImmune(Handle:timer, Handle:packet) {

	ResetPack(packet);
	new client			=	ReadPackCell(packet);
	new entityId		=	ReadPackCell(packet);
	if (!IsLegitimateClient(client)) return Plugin_Stop;

	new size = GetArraySize(Handle:AuraList);
	new pos				=	FindListPositionByEntity(entityId, Handle:AuraList);

	if (pos >= 0) {

		if (GetArraySize(Handle:AuraImmune[client]) != size) {

			ResizeArray(Handle:AuraImmune[client], size);
		}
		SetArrayCell(Handle:AuraImmune[client], pos, 0, 0);
	}
	return Plugin_Stop;
}

public Action:Timer_BeamImmune(Handle:timer, Handle:packie) {

	ResetPack(packie);
	new client			=	ReadPackCell(packie);
	new entityId		=	ReadPackCell(packie);
	if (!IsLegitimateClient(client)) return Plugin_Stop;

	new size = GetArraySize(Handle:AuraList);
	new pos				=	FindListPositionByEntity(entityId, Handle:AuraList);

	if (pos >= 0) {

		if (GetArraySize(Handle:AuraImmune[client]) != size) {

			ResizeArray(Handle:AuraImmune[client], size);
		}
		SetArrayCell(Handle:AuraImmune[client], pos, 0, 1);
	}
	return Plugin_Stop;
}

public Action:Timer_CreateAura(Handle:timer) {

	if (!b_IsActiveRound) return Plugin_Stop;
	new entityId = 0;
	new auraId = 0;
	
	new size = GetArraySize(Handle:AuraList);
	for (new i = 0; i < size; i++) {

		entityId		= GetArrayCell(Handle:AuraList, i, 0);
		auraId			= GetArrayCell(Handle:AuraList, i, 1);

		CreateAura(entityId, auraId);
	}
	return Plugin_Continue;
}

public Action:Timer_PeriodicTalents(Handle:timer) {

	if (!b_IsActiveRound) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i)) continue;
		if (IsPlayerAlive(i) && GetClientTeam(i) == TEAM_INFECTED ||
			!IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && L4D2_GetInfectedAttacker(i) == -1) FindAbilityByTrigger(i, 0, 'p', FindZombieClass(i), 0);
	}

	return Plugin_Continue;
}

public Action:Timer_DeductStoreTime(Handle:timer) {

	if (!b_IsActiveRound) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i)) RemoveStoreTime(i);
	}

	return Plugin_Continue;
}

public Action:Timer_SettingsCheck(Handle:timer) {

	if (!b_IsActiveRound) return Plugin_Stop;

	SetConVarInt(FindConVar("z_common_limit"), (StringToInt(GetConfigValue("common limit base?")) + (StringToInt(GetConfigValue("common increase per player?")) * (LivingHumanSurvivors() - StringToInt(GetConfigValue("human players required for increase?"))))));
	SetConVarInt(FindConVar("z_reserved_wanderers"), (StringToInt(GetConfigValue("wanderers limit base?")) + (StringToInt(GetConfigValue("wanderers increase per player?")) * (LivingHumanSurvivors() - StringToInt(GetConfigValue("human players required for increase?"))))));
	SetConVarInt(FindConVar("z_mega_mob_size"), (StringToInt(GetConfigValue("mega mob size base?")) + (StringToInt(GetConfigValue("mega mob increase per player?")) * (LivingHumanSurvivors() - StringToInt(GetConfigValue("human players required for increase?"))))));
	SetConVarInt(FindConVar("z_mob_spawn_max_size"), (StringToInt(GetConfigValue("mob size base?")) + (StringToInt(GetConfigValue("mob size increase per player?")) * (LivingHumanSurvivors() - StringToInt(GetConfigValue("human players required for increase?"))))));
	SetConVarInt(FindConVar("z_mob_spawn_finale_size"), (StringToInt(GetConfigValue("mob finale size base?")) + (StringToInt(GetConfigValue("mob finale increase per player?")) * (LivingHumanSurvivors() - StringToInt(GetConfigValue("human players required for increase?"))))));
	SetConVarInt(FindConVar("z_mega_mob_spawn_max_interval"), (StringToInt(GetConfigValue("mega mob max interval base?")) - (StringToInt(GetConfigValue("mega mob interval decrease per player?")) * (LivingHumanSurvivors() - StringToInt(GetConfigValue("human players required for increase?"))))));
	if (ReadyUp_GetGameMode() == 2) SetConVarInt(FindConVar("z_tank_health"), (StringToInt(GetConfigValue("versus base tank health?")) + (StringToInt(GetConfigValue("versus tank health per player?")) * (LivingHumanSurvivors() - StringToInt(GetConfigValue("human players required for increase?"))))));
	
	return Plugin_Continue;
}

public Action:Timer_DirectorPurchaseTimer(Handle:timer) {

	static Counter										=	-1;

	if (!b_IsActiveRound) {

		Counter											=	-1;
		return Plugin_Stop;
	}
	if (Counter == -1) {

		Counter = GetTime() + RoundToCeil(StringToFloat(GetConfigValue("director thought process delay?")) - (LivingSurvivors() * StringToFloat(GetConfigValue("director thought process handicap?"))));
		return Plugin_Continue;
	}
	else if (Counter > GetTime()) {

		// We still spawn specials, out of range of players to enforce the active special limit.
		return Plugin_Continue;
	}
	//PrintToChatAll("%t", "Director Think Process", orange, white);


	Counter = GetTime() + RoundToCeil(StringToFloat(GetConfigValue("director thought process delay?")) - (LivingSurvivors() * StringToFloat(GetConfigValue("director thought process handicap?"))));

	new MaximumPriority = StringToInt(GetConfigValue("director priority maximum?"));

	new size				=	GetArraySize(a_DirectorActions);

	for (new i = 1; i <= MaximumPriority; i++) { CheckDirectorActionPriority(i, size); }

	return Plugin_Continue;
}

stock CheckDirectorActionPriority(pos, size) {

	decl String:text[64];
	for (new i = 0; i < size; i++) {

		if (i < GetArraySize(a_DirectorActions_Cooldown)) GetArrayString(a_DirectorActions_Cooldown, i, text, sizeof(text));
		else break;
		if (StringToInt(text) > 0) continue;			// Purchase still on cooldown.
		
		DirectorKeys					=	GetArrayCell(a_DirectorActions, i, 0);
		DirectorValues					=	GetArrayCell(a_DirectorActions, i, 1);

		if (StringToInt(GetKeyValue(DirectorKeys, DirectorValues, "priority?")) != pos || !DirectorPurchase_Valid(DirectorKeys, DirectorValues, i)) continue;
		DirectorPurchase(DirectorKeys, DirectorValues, i);
	}
}

stock bool:DirectorPurchase_Valid(Handle:Keys, Handle:Values, pos) {

	new Float:PointCost		=	0.0;
	new Float:PointCostMin	=	0.0;
	decl String:Cooldown[64];

	GetArrayString(a_DirectorActions_Cooldown, pos, Cooldown, sizeof(Cooldown));
	if (StringToInt(Cooldown) > 0) return false;

	PointCost				=	StringToFloat(GetKeyValue(Keys, Values, "point cost?")) + (StringToFloat(GetKeyValue(Keys, Values, "cost handicap?")) * LivingHumanSurvivors());
	if (PointCost > 1.0) PointCost = 1.0;
	PointCostMin			=	StringToFloat(GetKeyValue(Keys, Values, "point cost minimum?")) + (StringToFloat(GetKeyValue(Keys, Values, "min cost handicap?")) * LivingHumanSurvivors());

	if (Points_Director > 0.0) PointCost *= Points_Director;
	if (PointCost < PointCostMin) PointCost = PointCostMin;

	if (Points_Director >= PointCost) return true;
	return false;
}

stock ActiveTanks() {

	new Count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && IsPlayerAlive(i) && FindZombieClass(i) == ZOMBIECLASS_TANK) Count++;
	}

	return Count;
}

stock DirectorTankLimit() {

	new Float:count = (LivingSurvivors() / StringToFloat(GetConfigValue("director tanks player multiplier?"))) * StringToInt(GetConfigValue("director tanks per _ players?"));
	if (count < 1.0) count = 1.0;

	return RoundToCeil(count);
}

stock DirectorPurchase(Handle:Keys, Handle:Values, pos) {

	decl String:Command[64];
	decl String:Parameter[64];
	decl String:Model[64];
	new IsPlayerDrop		=	0;
	new Count				=	0;

	new Float:PointCost		=	0.0;
	new Float:PointCostMin	=	0.0;

	new Float:MinimumDelay	=	0.0;

	PointCost				=	StringToFloat(GetKeyValue(Keys, Values, "point cost?")) + (StringToFloat(GetKeyValue(Keys, Values, "cost handicap?")) * LivingHumanSurvivors());
	PointCostMin			=	StringToFloat(GetKeyValue(Keys, Values, "point cost minimum?")) + (StringToFloat(GetKeyValue(Keys, Values, "min cost handicap?")) * LivingHumanSurvivors());
	Format(Parameter, sizeof(Parameter), "%s", GetKeyValue(Keys, Values, "parameter?"));
	Count					=	StringToInt(GetKeyValue(Keys, Values, "count?"));
	Format(Command, sizeof(Command), "%s", GetKeyValue(Keys, Values, "command?"));
	IsPlayerDrop			=	StringToInt(GetKeyValue(Keys, Values, "drop?"));
	Format(Model, sizeof(Model), "%s", GetKeyValue(Keys, Values, "model?"));
	MinimumDelay			=	StringToFloat(GetKeyValue(Keys, Values, "minimum delay?"));

	if (PointCost > 1.0) {

		PointCost			=	1.0;
	}

	if (StrContains(Parameter, "tank", false) != -1 && (ActiveTanks() >= DirectorTankLimit() || f_TankCooldown != -1.0)) return;

	if (StrEqual(Parameter, "common")) {

		if (GetArraySize(CommonInfectedQueue) + Count >= StringToInt(GetConfigValue("common queue limit?"))) {

			LogMessage("Cannot buy commons, it would exceed the limit of the allowed size.");
			return;
		}
	}

	/*if ((StrEqual(Command, "director_force_panic_event") || IsPlayerDrop) && b_IsFinaleActive) {

		return;
	}*/
	if (StrEqual(Command, "director_force_panic_event") && b_IsFinaleActive) {

		return;
	}

	if (Points_Director > 0.0) PointCost *= Points_Director;
	if (PointCost < PointCostMin) PointCost = PointCostMin;

	if (Points_Director < PointCost) return;

	if (LivingHumanSurvivors() < StringToInt(GetKeyValue(Keys, Values, "living survivors?"))) return;

	new Client				=	FindLivingSurvivor();
	if (Client < 1) return;
	Points_Director -= PointCost;

	if (MinimumDelay > 0.0) {

		SetArrayString(a_DirectorActions_Cooldown, pos, "1");
		MinimumDelay = MinimumDelay - (LivingHumanSurvivors() * StringToFloat(GetConfigValue("director thought process handicap?"))) - (StringToFloat(GetKeyValue(Keys, Values, "delay handicap?")) * LivingHumanSurvivors());
		if (MinimumDelay < 0.0) MinimumDelay = 0.0;
		CreateTimer((StringToFloat(GetConfigValue("director thought process delay?")) - (LivingHumanSurvivors() * StringToFloat(GetConfigValue("director thought process handicap?")))) + MinimumDelay, Timer_DirectorActions_Cooldown, pos, TIMER_FLAG_NO_MAPCHANGE);
	}

	if (!StrEqual(Parameter, "common")) ExecCheatCommand(Client, Command, Parameter);
	else SpawnCommons(Client, Count, Command, Parameter, Model, IsPlayerDrop);
}

stock SpawnCommons(Client, Count, String:Command[], String:Parameter[], String:Model[], IsPlayerDrop) {

	new TargetClient				=	-1;
	if (StrContains(Model, ".mdl", false) != -1) {

		for (new i = Count; i > 0 && GetArraySize(CommonInfectedQueue) < StringToInt(GetConfigValue("common queue limit?")); i--) {

			if (IsPlayerDrop == 1) {

				ResizeArray(Handle:CommonInfectedQueue, GetArraySize(Handle:CommonInfectedQueue) + 1);
				ShiftArrayUp(Handle:CommonInfectedQueue, 0);
				SetArrayString(Handle:CommonInfectedQueue, 0, Model);
				TargetClient		=	FindLivingSurvivor();
				if (TargetClient > 0) ExecCheatCommand(TargetClient, Command, Parameter);
			}
			else PushArrayString(Handle:CommonInfectedQueue, Model);
		}
	}
}

stock FindLivingSurvivor() {


	/*new Client = -1;
	while (Client == -1 && LivingSurvivorCount() > 0) {

		Client = GetRandomInt(1, MaxClients);
		if (!IsClientInGame(Client) || !IsClientHuman(Client) || !IsPlayerAlive(Client) || GetClientTeam(Client) != TEAM_SURVIVOR) Client = -1;
	}
	return Client;*/
	for (new i = LastLivingSurvivor; i <= MaxClients && LivingSurvivorCount() > 0; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

			LastLivingSurvivor = i;
			return i;
		}
	}
	LastLivingSurvivor = 1;
	if (LivingSurvivorCount() < 1) return -1;
	return -1;
}

stock LivingSurvivorCount() {

	new Count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) Count++;
	}
	return Count;
}

public Action:Timer_DirectorActions_Cooldown(Handle:timer, any:pos) {

	SetArrayString(a_DirectorActions_Cooldown, pos, "0");
	return Plugin_Stop;
}