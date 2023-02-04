// Every single event in the events.cfg is called by this function, and then sent off to a specific function.
// This way a separate template isn't required for events that have different event names.
public Action:Event_Occurred(Handle:event, String:event_name[], bool:dontBroadcast) {

	//if (b_IsSurvivalIntermission) return Plugin_Handled;

	new a_Size						= 0;
	a_Size							= GetArraySize(a_Events);

	decl String:EventName[PLATFORM_MAX_PATH];
	new eventresult = 0;

	decl String:CurrMap[64];
	GetCurrentMap(CurrMap, sizeof(CurrMap));

	for (new i = 0; i < a_Size; i++) {

		EventSection						= GetArrayCell(a_Events, i, 2);
		GetArrayString(Handle:EventSection, 0, EventName, sizeof(EventName));

		if (StrEqual(EventName, event_name)) {

			//if (Call_Event(event, event_name, dontBroadcast, i) == -1) {

				/*if (StrEqual(EventName, "infected_hurt") || StrEqual(EventName, "player_hurt")) {

					

					//	Returns -1 when infected_hurt or player_hurt and the cause of the damage is not a common infected or a player
					//	or if the damage is "inferno" which can be discerned through the player_hurt event only; we have to resort to
					//	the prior for infected_hurt
					

					return Plugin_Handled;
				}*/
			//}
			eventresult = Call_Event(event, event_name, dontBroadcast, i);
			break;
		}
	}
	//if (StrEqual(EventName, "player_shoved", false)) PrintToChatAll("player shoved!");
	//if (StrEqual(EventName, "entity_shoved", false)) PrintToChatAll("entity shoved!");
	if (StrContains(EventName, "finale_radio_start", false) != -1) return Plugin_Continue;
	if (eventresult == -1 && b_IsActiveRound) return Plugin_Handled;
	return Plugin_Continue;
	//if (StrEqual(EventName, "infected_hurt") || StrEqual(EventName, "player_hurt")) return Plugin_Handled;
	//else return Plugin_Continue;
}

public SubmitEventHooks(value) {

	new size = GetArraySize(a_Events);
	decl String:text[64];

	for (new i = 0; i < size; i++) {

		HookSection = GetArrayCell(a_Events, i, 2);
		GetArrayString(Handle:HookSection, 0, text, sizeof(text));
		if (StrEqual(text, "player_hurt", false) ||
			StrEqual(text, "infected_hurt", false)) {

			if (value == 0) UnhookEvent(text, Event_Occurred, EventHookMode_Pre);
			else HookEvent(text, Event_Occurred, EventHookMode_Pre);
		}
		else {

			if (value == 0) UnhookEvent(text, Event_Occurred);
			else HookEvent(text, Event_Occurred);
		}
	}
}

stock FindPlayerWeapon(client, String:weapon[], size) {
	if (IsLegitimateClient(client) && GetClientTeam(client) == TEAM_INFECTED) {
		GetClientWeapon(client, weapon, size);
	}
	else {
		new g_iActiveWeaponOffset = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
		new iWeapon = GetEntDataEnt2(client, g_iActiveWeaponOffset);
		if (IsValidEdict(iWeapon)) GetEdictClassname(iWeapon, weapon, size);
		else Format(weapon, size, "-1");
	}
}

public Call_Event(Handle:event, String:event_name[], bool:dontBroadcast, pos) {
	CallKeys							= GetArrayCell(a_Events, pos, 0);
	CallValues							= GetArrayCell(a_Events, pos, 1);

	decl String:ThePerp[64];
	FormatKeyValue(ThePerp, sizeof(ThePerp), CallKeys, CallValues, "perpetrator?");
	new attacker = GetClientOfUserId(GetEventInt(event, ThePerp));

	FormatKeyValue(ThePerp, sizeof(ThePerp), CallKeys, CallValues, "victim?");
	new victim = GetClientOfUserId(GetEventInt(event, ThePerp));

	if (IsLegitimateClient(attacker) && (IsLegitimateClient(victim) || IsCommonInfected(victim) || IsWitch(victim))) {
		if (IsWitch(victim)) {
			if (FindListPositionByEntity(victim, Handle:WitchList) < 0) OnWitchCreated(victim);
		}
		// These calls are specific to special infected and survivor events - does not handle common infected, super infected, or witches.

		// Talents/Nodes can be triggered when specific events occur.
		// They can be special calls, so that it looks for specific case-sens strings instead of characters.
		if (((IsCommonInfected(victim) || IsWitch(victim)) && GetClientTeam(attacker) == TEAM_SURVIVOR) ||
			IsLegitimateClient(victim) && (!IsLegitimateClient(attacker) || GetClientTeam(attacker) != GetClientTeam(victim) || GetKeyValueInt(CallKeys, CallValues, "same team event trigger?") == 1)) {
			decl String:abilityTriggerActivator[64];
			decl String:abilityTriggerTarget[64];

			FormatKeyValue(abilityTriggerActivator, sizeof(abilityTriggerActivator), CallKeys, CallValues, "perpetrator team required?");
			if (!StrEqual(abilityTriggerActivator, "-1")) {
				Format(ThePerp, sizeof(ThePerp), "%d", GetClientTeam(attacker));
				if (StrContains(abilityTriggerActivator, ThePerp) != -1) {
					FormatKeyValue(abilityTriggerActivator, sizeof(abilityTriggerActivator), CallKeys, CallValues, "perpetrator ability trigger?");
					if (!StrEqual(abilityTriggerActivator, "-1")) GetAbilityStrengthByTrigger(attacker, victim, abilityTriggerActivator);
				}
			}
			FormatKeyValue(abilityTriggerTarget, sizeof(abilityTriggerTarget), CallKeys, CallValues, "victim team required?");
			if (!StrEqual(abilityTriggerTarget, "-1")) {
				Format(ThePerp, sizeof(ThePerp), "%d", GetClientTeam(victim));
				if (StrContains(abilityTriggerTarget, ThePerp) != -1) {
					FormatKeyValue(abilityTriggerTarget, sizeof(abilityTriggerTarget), CallKeys, CallValues, "victim ability trigger?");
					if (!StrEqual(abilityTriggerTarget, "-1")) GetAbilityStrengthByTrigger(victim, attacker, abilityTriggerTarget);
				}
			}
		}
	}
	decl String:weapon[64];
	//decl String:key[64];
	if (StrEqual(event_name, "player_left_start_area") && IsLegitimateClient(attacker)) {

		if (GetClientTeam(attacker) == TEAM_SURVIVOR) {

			if (IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && !b_IsLoaded[attacker]) IsClientLoadedEx(attacker);

			if (b_IsInSaferoom[attacker] && RoundExperienceMultiplier[attacker] > 0.0) {

				b_IsInSaferoom[attacker] = false;
				//PrintToChat(attacker, "%T", "bonus container locked", attacker, orange, blue);
				decl String:saferoomName[64];
				GetClientName(attacker, saferoomName, sizeof(saferoomName));
				decl String:pct[4];
				Format(pct, sizeof(pct), "%");
				PrintToChatAll("%t", "round bonus multiplier", blue, saferoomName, white, orange, (1.0 + RoundExperienceMultiplier[attacker]) * 100.0, orange, pct, white);
			}
		}
	}
	if (IsLegitimateClientAlive(attacker)) {

		if (StrEqual(event_name, "player_entered_checkpoint")) bIsInCheckpoint[attacker] = true;
		if (StrEqual(event_name, "player_left_checkpoint")) bIsInCheckpoint[attacker] = false;
	}
	if (StrEqual(event_name, "player_spawn")) {

		if (IsLegitimateClient(attacker)) {
			ClearArray(Handle:ActiveStatuses[attacker]);
			if (GetClientTeam(attacker) == TEAM_SURVIVOR) {
				ChangeHook(attacker, true);
				RefreshSurvivor(attacker);
				RaidInfectedBotLimit();
			}//EquipBackpack(attacker);
			if (GetClientTeam(attacker) == TEAM_INFECTED) {
				SetInfectedHealth(attacker, 99999);
				//if (b_IsActiveRound || !IsFakeClient(attacker)) {
				if (!IsFakeClient(attacker)) PlayerSpawnAbilityTrigger(attacker);
				if (!IsSurvivorBot(attacker)) {
					ClearArray(Handle:PlayerAbilitiesCooldown[attacker]);
					ClearArray(Handle:InfectedHealth[attacker]);
					new aDbSize = GetArraySize(a_Database_Talents);
					ResizeArray(a_Database_PlayerTalents[attacker], aDbSize);
					ResizeArray(PlayerAbilitiesCooldown[attacker], aDbSize);
					ResizeArray(a_Database_PlayerTalents_Experience[attacker], aDbSize);
					ResizeArray(Handle:InfectedHealth[attacker], 1);	// infected player stores their actual health (from talents, abilities, etc.) locally...
					bHealthIsSet[attacker] = false;
					if (!b_IsHooked[attacker]) {
						ChangeHook(attacker, true);
						CreateMyHealthPool(attacker, true);
					}
					if (FindZombieClass(attacker) == ZOMBIECLASS_TANK) {
						ClearArray(TankState_Array[attacker]);
						bHasTeleported[attacker] = false;
						if (iTanksPreset == 1) {
							new iRand = GetRandomInt(1, 3);
							if (iRand == 1) ChangeTankState(attacker, "hulk");
							else if (iRand == 2) ChangeTankState(attacker, "death");
							else if (iRand == 3) ChangeTankState(attacker, "burn");
							//else if (iRand == 4) ChangeTankState(attacker, "teleporter");
							//else if (iRand == 5) ChangeTankState(attacker, "reflect");
						}
					}
				}
			}
		}
	}
	if (!b_IsActiveRound || IsLegitimateClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && !b_IsLoaded[attacker]) {
		return 0;		// don't track ANYTHING when it's not an active round.
	}
	decl String:curEquippedWeapon[64];
	if (StrEqual(event_name, "weapon_reload") || StrEqual(event_name, "bullet_impact")) {
		new WeaponId =	GetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon");
		GetEntityClassname(WeaponId, curEquippedWeapon, sizeof(curEquippedWeapon));
	}
	if (IsLegitimateClient(victim) && GetClientTeam(victim) == TEAM_SURVIVOR) {
		if (StrEqual(event_name, "revive_success")) {
			if (attacker != victim) {
				GetAbilityStrengthByTrigger(victim, attacker, "R", _, 0);
				GetAbilityStrengthByTrigger(attacker, victim, "r", _, 0);
			}
			SetEntPropEnt(victim, Prop_Send, "m_reviveOwner", -1);
			SetEntPropEnt(attacker, Prop_Send, "m_reviveTarget", -1);
			new reviveOwner = GetEntPropEnt(victim, Prop_Send, "m_reviveOwner");
			if (IsLegitimateClient(reviveOwner)) {

				SetEntPropEnt(reviveOwner, Prop_Send, "m_reviveTarget", -1);
			}
			GiveMaximumHealth(victim);
		}
	}
	FormatKeyValue(ThePerp, sizeof(ThePerp), CallKeys, CallValues, "damage type?");
	new damagetype = GetEventInt(event, ThePerp);

	if (StrEqual(event_name, "finale_radio_start") && !b_IsFinaleActive) {

		// When the finale is active, players can earn experience whilst camping (not moving from a spot, re: farming)
		b_IsFinaleActive = true;
		if (GetInfectedCount(ZOMBIECLASS_TANK) < 1) b_IsFinaleTanks = true;
		if (iTankRush == 1) {

			PrintToChatAll("%t", "the zombies are coming", blue, orange, blue);
			ExecCheatCommand(FindAnyRandomClient(), "director_force_panic_event");
		}

		//PrintToChatAll("%t", "Farming Prevention Disabled", white, orange, white, orange, white, blue);
	}
	if (StrEqual(event_name, "finale_vehicle_ready")) {

		// When the vehicle arrives, the finale is no longer active, but no experience can be earned. This stops farming.
		if (b_IsFinaleActive) {

			b_RescueIsHere = true;

			b_IsFinaleActive = false;

			new TheInfectedLevel = HumanSurvivorLevels();

			new TheHumans = HumanPlayersInGame();
			new TheLiving = LivingSurvivorCount();

			//new RatingMult = GetConfigValueInt("rating level multiplier?");
			new InfectedLevelType = iBotLevelType;

			for (new i = 1; i <= MaxClients; i++) {

				if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) {
				
					if (InfectedLevelType == 0) Rating[i] += (RaidLevMult / TheLiving);
					else {

						if (!bIsSoloHandicap) Rating[i] += (TheInfectedLevel / TheHumans);
						else Rating[i] += RaidLevMult;
					}
					RoundExperienceMultiplier[i] += FinSurvBon;
				}
			}
		}

		//PrintToChatAll("%t", "Experience Gains Disabled", orange, white, orange, white, blue);
	}

	// Declare the values that can be defined by the event config, so we know whether to consider them.

	//new RPGMode						= iRPGMode;	// 1 experience 2 experience & points

	decl String:AbilityUsed[PLATFORM_MAX_PATH];
	decl String:abilities[PLATFORM_MAX_PATH];

	FormatKeyValue(ThePerp, sizeof(ThePerp), CallKeys, CallValues, "health?");
	new healthvalue = GetEventInt(event, ThePerp);

	new isdamageaward = GetKeyValueInt(CallKeys, CallValues, "damage award?");
	//new healing = GetKeyValueInt(CallKeys, CallValues, "healing?");

	//new deathaward = GetKeyValueInt(CallKeys, CallValues, "death award?");
	FormatKeyValue(abilities, sizeof(abilities), CallKeys, CallValues, "abilities?");
	new tagability = GetKeyValueInt(CallKeys, CallValues, "tag ability?");
	//new tagexperience = GetKeyValueInt(CallKeys, CallValues, "tag experience?");
	//new Float:tagpoints = GetKeyValueFloat(CallKeys, CallValues, "tag points?");
	new originvalue = GetKeyValueInt(CallKeys, CallValues, "origin?");
	new distancevalue = GetKeyValueInt(CallKeys, CallValues, "distance?");
	new Float:multiplierpts = GetKeyValueFloat(CallKeys, CallValues, "multiplier points?");
	new Float:multiplierexp = GetKeyValueFloat(CallKeys, CallValues, "multiplier exp?");
	new isshoved = GetKeyValueInt(CallKeys, CallValues, "shoved?");
	new bulletimpact = GetKeyValueInt(CallKeys, CallValues, "bulletimpact?");
	new isinsaferoom = GetKeyValueInt(CallKeys, CallValues, "entered saferoom?");

	if (bulletimpact == 1) {

		if (IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR) {

			new bulletsFired = 0;
			GetTrieValue(currentEquippedWeapon[attacker], curEquippedWeapon, bulletsFired);
			SetTrieValue(currentEquippedWeapon[attacker], curEquippedWeapon, bulletsFired + 1);

			new Float:Coords[3];
			Coords[0] = GetEventFloat(event, "x");
			Coords[1] = GetEventFloat(event, "y");
			Coords[2] = GetEventFloat(event, "z");
			new Float:TargetPos[3];
			new target = GetAimTargetPosition(attacker, TargetPos);

			if (AllowShotgunToTriggerNodes(attacker)) LastWeaponDamage[attacker] = GetBaseWeaponDamage(attacker, target, Coords[0], Coords[1], Coords[2], damagetype);

			if (iIsBulletTrails[attacker] == 1) {
				new Float:EyeCoords[3];
				GetClientEyePosition(attacker, EyeCoords);
				// Adjust the coords so they line up with the gun
				EyeCoords[2] -= 10.0;

				new TrailsColours[4];
				TrailsColours[3] = 200;

				decl String:ClientModel[64];
				decl String:TargetModel[64];
				GetClientModel(attacker, ClientModel, sizeof(ClientModel));

				new bulletsize		= GetArraySize(a_Trails);
				for (new i = 0; i < bulletsize; i++) {

					TrailsKeys[attacker] = GetArrayCell(a_Trails, i, 0);
					TrailsValues[attacker] = GetArrayCell(a_Trails, i, 1);

					FormatKeyValue(TargetModel, sizeof(TargetModel), TrailsKeys[attacker], TrailsValues[attacker], "model affected?");

					if (StrEqual(TargetModel, ClientModel)) {

						TrailsColours[0]		= GetKeyValueInt(TrailsKeys[attacker], TrailsValues[attacker], "red?");
						TrailsColours[1]		= GetKeyValueInt(TrailsKeys[attacker], TrailsValues[attacker], "green?");
						TrailsColours[2]		= GetKeyValueInt(TrailsKeys[attacker], TrailsValues[attacker], "blue?");
						break;
					}
				}

				for (new i = 1; i <= MaxClients; i++) {

					if (IsLegitimateClient(i) && !IsFakeClient(i)) {

						TE_SetupBeamPoints(EyeCoords, Coords, g_iSprite, 0, 0, 0, 0.06, 0.09, 0.09, 1, 0.0, TrailsColours, 0);
						TE_SendToClient(i);
					}
				}
			}
		}
	}

	if (StrEqual(event_name, "player_hurt") || StrEqual(event_name, "infected_hurt")) {
		if (IsCommonInfected(victim) || IsWitch(victim)) SetInfectedHealth(victim, 50000);	// we don't want NPC zombies to die prematurely.
		if (IsLegitimateClient(attacker) && IsPlayerUsingShotgun(attacker)) {
			if (!shotgunCooldown[attacker]) CheckIfHeadshot(attacker, victim, event, healthvalue);
			else return 0;
			shotgunCooldown[attacker] = true;
			CreateTimer(0.1, Timer_ResetShotgunCooldown, attacker, TIMER_FLAG_NO_MAPCHANGE);
		}

		if (IsLegitimateClientAlive(victim) && !b_IsHooked[victim]) ChangeHook(victim, true);
		//if (IsLegitimateClientAlive(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && !b_IsHooked[victim]) ChangeHook(victim, true);
		
		if (IsLegitimateClient(attacker) && IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && !b_IsLoaded[attacker]) IsClientLoadedEx(attacker);
		if (IsLegitimateClient(victim) && IsFakeClient(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && !b_IsLoaded[victim]) IsClientLoadedEx(victim);
	}
	if (IsLegitimateClient(victim) && GetClientTeam(victim) == TEAM_INFECTED) {
		SetEntityHealth(victim, 400000);
	}
	if (tagability == 1 && IsLegitimateClient(victim)) {
		if (!ISBILED[victim]) CreateTimer(15.0, Timer_RemoveBileStatus, victim, TIMER_FLAG_NO_MAPCHANGE);
		ISBILED[victim] = true;
	}
	if (tagability == 2 && IsLegitimateClient(attacker)) ISBILED[attacker] = false;
	
	if (isdamageaward == 1) {

		if (IsLegitimateClient(attacker) && IsLegitimateClient(victim) && GetClientTeam(attacker) == GetClientTeam(victim)) {

			if (!(damagetype & DMG_BURN) && !StrEqual(weapon, "inferno")) {

				// damage-based triggers now only occur under the circumstances in the code above. No longer do we have triggers for same-team damaging. Maybe at a later date, but it will not be the same ability trigger.
				GetAbilityStrengthByTrigger(attacker, victim, "d", _, healthvalue);
				GetAbilityStrengthByTrigger(victim, attacker, "l", _, healthvalue);
			}
			else {

				ReadyUp_NtvFriendlyFire(attacker, victim, healthvalue, GetClientHealth(victim), 1, 0);
			}
		}
		if (IsLegitimateClient(victim) && GetClientTeam(victim) == TEAM_INFECTED) SetEntityHealth(victim, 40000);
		if (IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && isinsaferoom == 1) b_IsInSaferoom[attacker] = true;
	}
	if (isshoved == 1 && IsLegitimateClientAlive(victim) && IsLegitimateClientAlive(attacker) && GetClientTeam(victim) != GetClientTeam(attacker)) {

		if (GetClientTeam(victim) == TEAM_INFECTED) SetEntityHealth(victim, GetClientHealth(victim) + healthvalue);

		GetAbilityStrengthByTrigger(victim, attacker, "H", _, 0);
	}
	if (isshoved == 2 && IsLegitimateClientAlive(attacker) && IsCommonInfected(victim) && !IsCommonStaggered(victim)) {
		//decl String:staggerData[64];
		//Format(staggerData, sizeof(staggerData), "%d:2.0", victim);
		//PushArrayString(StaggeredTargets, staggerData);
		new staggeredSize = GetArraySize(StaggeredTargets);
		ResizeArray(StaggeredTargets, staggeredSize + 1);
		SetArrayCell(StaggeredTargets, staggeredSize, victim, 0);
		SetArrayCell(StaggeredTargets, staggeredSize, 2.0, 1);
	}
	if (StrEqual(event_name, "weapon_reload")) {
		if (IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR) {
			ConsecutiveHits[attacker] = 0;	// resets on reload.
			RemoveFromTrie(currentEquippedWeapon[attacker], curEquippedWeapon);
		}
	}
	/*if (StrEqual(EventName, "player_team")) {

		if (IsLegitimateClient(attacker) && !IsFakeClient(attacker)) CreateTimer(1.0, Timer_SwitchTeams, attacker, TIMER_FLAG_NO_MAPCHANGE);
	}*/
	if (StrEqual(event_name, "player_spawn") && IsLegitimateClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED) {

		if (IsFakeClient(attacker)) {

			new changeClassId = 0;
			new myzombieclass = FindZombieClass(attacker);

			if (iSpecialsAllowed == 0 && myzombieclass != ZOMBIECLASS_TANK) {

				ForcePlayerSuicide(attacker);
			}
			if (iSpecialsAllowed == 1 && !StrEqual(sSpecialsAllowed, "-1")) {

				decl String:myClass[5];
				Format(myClass, sizeof(myClass), "%d", myzombieclass);

				if (StrContains(sSpecialsAllowed, myClass) == -1) {

					while (StrContains(sSpecialsAllowed, myClass) == -1) {

						changeClassId = GetRandomInt(1,6);
						Format(myClass, sizeof(myClass), "%d", changeClassId);
					}
					ChangeInfectedClass(attacker, changeClassId);
				}
			}

			// In solo games, we restrict the number of ensnarement infected.
			IsAirborne[attacker] = false;
			b_GroundRequired[attacker] = false;
			HasSeenCombat[attacker] = false;
			MyBirthday[attacker] = GetTime();

			new iTankCount = GetInfectedCount(ZOMBIECLASS_TANK);
			new iTankLimit = DirectorTankLimit();
			new theClient = FindAnyRandomClient();
			new iSurvivors = TotalHumanSurvivors();
			new iSurvivorBots = TotalSurvivors() - iSurvivors;
			new iLivSurvs = LivingSurvivorCount();
			if (iSurvivorBots >= 2) iSurvivorBots /= 2;
			new requiredTankCount = GetAlwaysTanks(iSurvivors + iSurvivorBots);

			if (myzombieclass == ZOMBIECLASS_TANK) {

				if (b_IsFinaleActive && b_IsFinaleTanks) {

					b_IsFinaleTanks = false;
					for (new i = 0; i + iTankCount < iTankLimit; i++) {

						ExecCheatCommand(theClient, "z_spawn_old", "tank auto");
					}
				}
				else {

					if (iTankCount > iTankLimit || f_TankCooldown != -1.0) {

						//PrintToChatAll("killing tank.");
						//ForcePlayerSuicide(attacker);
					}
				}
			}

			if (iNoSpecials == 1 || iTankRush == 1) {

				if (myzombieclass != ZOMBIECLASS_TANK) {

					//if (!IsEnrageActive())
					ForcePlayerSuicide(attacker);
					if (iSurvivors >= 1 && (iTankCount < requiredTankCount || !b_IsFinaleActive && iTankCount < iTankLimit)) {
						ExecCheatCommand(theClient, "z_spawn_old", "tank auto");
					}
				}
			}
			else if (myzombieclass != ZOMBIECLASS_TANK) {

				new iEnsnaredCount = EnsnaredInfected();
				new livingSurvivors = LivingHumanSurvivors();
				if (IsEnsnarer(attacker)) {

					if (iInfectedLimit == -1 || iInfectedLimit == 0 && iEnsnaredCount > livingSurvivors + RaidCommonBoost(_, true) || iInfectedLimit > 0 && iEnsnaredCount > iInfectedLimit || iIsLifelink > 1 && iLivSurvs < iIsLifelink && iLivSurvs < iMinSurvivors) {

						while (IsEnsnarer(attacker, changeClassId)) {

							changeClassId = GetRandomInt(1,6);
						}
						ChangeInfectedClass(attacker, changeClassId);
					}
				}
			}
		}
		else SetSpecialInfectedHealth(attacker);
	}
	if (StrEqual(event_name, "ability_use")) {

		if (GetClientTeam(attacker) == TEAM_INFECTED) GetAbilityStrengthByTrigger(attacker, victim, "infected_abilityuse");

		if (IsLegitimateClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED) {

			GetEventString(event, "ability", AbilityUsed, sizeof(AbilityUsed));
			if (StrContains(AbilityUsed, "ability_throw") != -1) {

				if (!(GetEntityFlags(attacker) & FL_ONFIRE) && !SurvivorsInRange(attacker, 128.0)) ChangeTankState(attacker, "burn");
				else {

					ChangeTankState(attacker, "hulk");
					if (!SurvivorsInRange(attacker, 128.0)) ForceClientJump(attacker, 1000.0);
				}
			}
			/*if (StrContains(AbilityUsed, abilities, false) != -1) {

				if (FindZombieClass(attacker) == ZOMBIECLASS_HUNTER) PrintToChatAll("Pouncing!");

				// check for any abilities that are based on abilityused.
				GetClientAbsOrigin(attacker, Float:f_OriginStart[attacker]);
				//GetAbilityStrengthByTrigger(attacker, 0, 'A', FindZombieClass(attacker), healthvalue);
				GetAbilityStrengthByTrigger(attacker, _, 'A', FindZombieClass(attacker), healthvalue);	// activator, target, trigger ability, effects, zombieclass, damage
			}*/
		}
	}

	if (IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_INFECTED) {

		new Float:Distance = 0.0;
		new Float:fTalentStrength = 0.0;

		if (originvalue > 0 || distancevalue > 0) {

			if (originvalue == 1 || distancevalue == 1) {

				GetClientAbsOrigin(attacker, Float:f_OriginStart[attacker]);
				if (FindZombieClass(attacker) != ZOMBIECLASS_HUNTER &&
					FindZombieClass(attacker) != ZOMBIECLASS_SPITTER) {

					fTalentStrength = GetAbilityStrengthByTrigger(attacker, _, "Q", _, 0);
				}
				if (FindZombieClass(attacker) == ZOMBIECLASS_HUNTER) {

					// check for any abilities that are based on abilityused.
					GetClientAbsOrigin(attacker, Float:f_OriginStart[attacker]);
					//GetAbilityStrengthByTrigger(attacker, 0, 'A', FindZombieClass(attacker), healthvalue);
					GetAbilityStrengthByTrigger(attacker, _, "A", _, healthvalue);
				}
				if (FindZombieClass(attacker) == ZOMBIECLASS_CHARGER) {

					CreateTimer(0.1, Timer_ChargerJumpCheck, attacker, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			if (originvalue == 2 || distancevalue == 2) {

				fTalentStrength = GetAbilityStrengthByTrigger(attacker, _, "q", _, 0);
				if (CheckActiveStatuses(attacker, "lunge", false, true) == 0) {

					SetEntityRenderMode(attacker, RENDER_NORMAL);
					SetEntityRenderColor(attacker, 255, 255, 255, 255);

					fTalentStrength += GetAbilityStrengthByTrigger(attacker, _, "A", _, 0);
				}

				GetClientAbsOrigin(attacker, Float:f_OriginEnd[attacker]);

				if (IsLegitimateClientAlive(victim) && GetClientTeam(victim) == TEAM_SURVIVOR) {

					Distance = GetVectorDistance(f_OriginStart[attacker], f_OriginEnd[attacker]);
					if (fTalentStrength > 0.0) Distance += (Distance * fTalentStrength);

					//SetClientTotalHealth(victim, RoundToCeil(Distance), _, true);
				}
			}

			if (FindZombieClass(attacker) == ZOMBIECLASS_JOCKEY || (distancevalue == 2 && t_Distance[attacker] > 0)) {

				if (distancevalue == 1) t_Distance[attacker] = GetTime();
				if (distancevalue == 2) {

					t_Distance[attacker] = GetTime() - t_Distance[attacker];
					multiplierexp *= t_Distance[attacker];
					multiplierpts *= t_Distance[attacker];
					t_Distance[attacker] = 0;

				}
			}
			else {

				if (distancevalue == 3 && IsLegitimateClientAlive(victim)) GetClientAbsOrigin(victim, Float:f_OriginStart[attacker]);
				if (distancevalue == 2 || originvalue == 2 || distancevalue == 4 && IsLegitimateClientAlive(victim)) {

					if (distancevalue == 4) GetClientAbsOrigin(victim, Float:f_OriginEnd[attacker]);

					//new Float:Distance = GetVectorDistance(f_OriginStart[attacker], f_OriginEnd[attacker]);
					multiplierexp *= Distance;
					multiplierpts *= Distance;
				}
			}
			if (originvalue == 2 || distancevalue == 2 || distancevalue == 4) {

				if (iRPGMode >= 1 && multiplierexp > 0.0) {

					ExperienceLevel[attacker] += RoundToCeil(multiplierexp);
					ExperienceOverall[attacker] += RoundToCeil(multiplierexp);
					ConfirmExperienceAction(attacker);

					if (iAwardBroadcast > 0 && !IsFakeClient(attacker)) PrintToChat(attacker, "%T", "distance experience", attacker, white, green, RoundToCeil(multiplierexp), white);
				}
				if (iRPGMode != 1 && multiplierpts > 0.0) {

					Points[attacker] += multiplierpts;
					if (iAwardBroadcast > 0 && !IsFakeClient(attacker)) PrintToChat(attacker, "%T", "distance points", attacker, white, green, multiplierpts, white);
				}
			}
		}
	}
	return 0;
}

stock bool:AddOTEffect(client, target, String:clientSteamID[], Float:fStrength, OTtype = 0) {
	new Float:fClientStrength = 0.0;
	new Float:fTargetStrength = 0.0;
	new Float:fIntervalTime = 0.0;
	//new Float:fCurrentEffectStrength = 0.0;
	new iNewEffectStrength = 0;
	decl String:SearchKey[64], String:SearchValue[64];
	GetClientAuthString(target, SearchKey, sizeof(SearchKey));
	Format(SearchKey, sizeof(SearchKey), "%s:%s:%d", clientSteamID, SearchKey, OTtype);
	if (OTtype == 0) {
		fClientStrength = GetAbilityStrengthByTrigger(client, client, "outhealingbonus", _, 0, _, _, "d", 1, true);	// we need a way to return a default value if there are no points in a category without using global variables. delete when this is solved.
		fIntervalTime	= GetAbilityStrengthByTrigger(client, client, "healingtickrate", _, 0, _, _, "d", 1, true);
		fTargetStrength = GetAbilityStrengthByTrigger(target, target, "inchealingbonus", _, 0, _, _, "d", 1, true);
		iNewEffectStrength = RoundToCeil((fClientStrength + fTargetStrength) * fStrength);	// uhhhhhhh this is a balance modifier for PvE/PvP
	}
	else if (OTtype == 1) {
		fClientStrength = GetAbilityStrengthByTrigger(client, client, "outdamagebonus", _, 0, _, _, "d", 1, true);
		fIntervalTime	= GetAbilityStrengthByTrigger(client, client, "damagetickrate", _, 0, _, _, "d", 1, true);
		fTargetStrength = GetAbilityStrengthByTrigger(target, target, "incdamagebonus", _, 0, _, _, "d", 1, true);
	}
	new size = GetArraySize(Handle:EffectOverTime);
	ResizeArray(Handle:EffectOverTime, size + 1);
	SetArrayCell(Handle:EffectOverTime, size, fIntervalTime, 0);
	SetArrayCell(Handle:EffectOverTime, size, fIntervalTime, 1);
	SetArrayCell(Handle:EffectOverTime, size, iNewEffectStrength, 2);
	//Format(SearchValue, sizeof(SearchValue), "%3.2f:%3.2f:%d", fIntervalTime, fIntervalTime, iNewEffectStrength);
	// a player could have multiple minor buffs or effects over time active at a time on them.
	//SetTrieString(EffectOverTime, SearchKey, SearchValue);
	GetAbilityStrengthByTrigger(client, client, "damagebonus", _, 0, _, _, "d", 1, true);
}

stock StoreItemName(client, pos, String:s[], size) {

	StoreItemNameSection[client]					= GetArrayCell(a_Store, pos, 2);
	GetArrayString(StoreItemNameSection[client], 0, s, size);
}

stock bool:IsStoreItem(client, String:EName[], bool:b_IsAwarding = true) {

	decl String:Name[64];
	new size				= GetArraySize(a_Store);

	for (new i = 0; i < size; i++) {

		StoreItemSection[client]				= GetArrayCell(a_Store, i, 2);
		GetArrayString(StoreItemSection[client], 0, Name, sizeof(Name));

		if (StrEqual(Name, EName)) {

			if (b_IsAwarding) GiveClientStoreItem(client, i);
			return true;
		}
	}
	return false;
}

public Action:Timer_ChargerJumpCheck(Handle:timer, any:client) {

	if (IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == TEAM_INFECTED) {

		if (FindZombieClass(client) != ZOMBIECLASS_CHARGER || !IsPlayerAlive(client)) return Plugin_Stop;
		new victim = L4D2_GetSurvivorVictim(client);
		if (victim == -1) return Plugin_Continue;
		if ((GetEntityFlags(client) & FL_ONGROUND)) {

			GetAbilityStrengthByTrigger(client, victim, "v", _, 0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

stock bool:PlayerCastSpell(client) {

	new CurrentEntity			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if (!IsValidEntity(CurrentEntity) || CurrentEntity < 1) return Plugin_Handled;
	decl String:EntityName[64];


	GetEdictClassname(CurrentEntity, EntityName, sizeof(EntityName));

	new Entity					=	CreateEntityByName(EntityName);
	DispatchSpawn(Entity);

	new Float:Origin[3];
	GetClientAbsOrigin(client, Origin);

	Origin[2] += 64.0;

	TeleportEntity(Entity, Origin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(Entity, MOVETYPE_VPHYSICS);

	if (GetWeaponSlot(Entity) < 2) SetEntProp(Entity, Prop_Send, "m_iClip1", GetEntProp(CurrentEntity, Prop_Send, "m_iClip1"));
	AcceptEntityInput(CurrentEntity, "Kill");

	return Plugin_Handled;
}

stock CreateGravityAmmo(client, Float:Force, Float:Range, bool:UseTheForceLuke=false) {

	new entity		= CreateEntityByName("point_push");
	if (!IsValidEntity(entity)) return -1;
	decl String:value[64];

	new Float:Origin[3];
	new Float:Angles[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
	GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
	Angles[0] += -90.0;

	DispatchKeyValueVector(entity, "origin", Origin);
	DispatchKeyValueVector(entity, "angles", Angles);
	Format(value, sizeof(value), "%d", RoundToCeil(Range / 2));
	DispatchKeyValue(entity, "radius", value);
	if (!UseTheForceLuke) DispatchKeyValueFloat(entity, "magnitude", Force * -1.0);
	else DispatchKeyValueFloat(entity, "magnitude", Force);
	DispatchKeyValue(entity, "spawnflags", "8");
	AcceptEntityInput(entity, "Enable");
	return entity;
}

/*

	Need to determine if the player has special ammo or not.
*/
stock bool:HasSpecialAmmo(client, String:TalentNameEx[] = "none") {

	decl String:TalentName[64];
	new ArraySize = GetArraySize(a_Menu_Talents);
	for (new i = 0; i < ArraySize; i++) {

		SpecialAmmoKeys[client]		= GetArrayCell(a_Menu_Talents, i, 0);
		SpecialAmmoValues[client]	= GetArrayCell(a_Menu_Talents, i, 1);
		SpecialAmmoSection[client]	= GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(Handle:SpecialAmmoSection[client], 0, TalentName, sizeof(TalentName));
		if (!StrEqual(TalentNameEx, "none", false) && !StrEqual(TalentName, TalentNameEx, false)) continue;

		if (GetKeyValueInt(SpecialAmmoKeys[client], SpecialAmmoValues[client], "special ammo?") == 0) continue;
		if ((GetTalentStrength(client, TalentName) * 1.0) <= 0.0) continue;

		return true;
	}
	return false;
}

stock bool:GetActiveSpecialAmmoType(client, effect) {

	decl String:EffectT[4];
	Format(EffectT, sizeof(EffectT), "%c", effect);
	decl String:TheAmmoEffect[10];
	GetSpecialAmmoEffect(TheAmmoEffect, sizeof(TheAmmoEffect), client, ActiveSpecialAmmo[client]);

	if (StrContains(TheAmmoEffect, EffectT, true) != -1) return true;
	return false;
}

/*

	Checks whether a player is within range of a special ammo, and if they are, how affected they are.
	GetStatusOnly is so we know whether to start the revive bar for revive ammo, without triggering the actual effect, we just want to know IF they're affected, for example.
	If ammoposition is >= 0 AND GetStatus is enabled, it will return only for the ammo in question.
*/

stock Float:IsClientInRangeSpecialAmmo(client, String:EffectT[], bool:GetStatusOnly=true, AmmoPosition=-1, Float:baseeffectvalue=0.0, realowner=0) {
	static Float:EntityPos[3];
	static String:TalentInfo[4][512];
	static owner = 0;
	static pos = -1;
	//decl String:newvalue[10];

	static String:value[10];
	//new Float:f_Strength = 0.0;
	//decl String:t_effect[4];

	static Float:EffectStrength = 0.0;
	static Float:EffectStrengthBonus = 0.0;
	static bool:IsInfected = false;
	static bool:IsSameteam = false;

	static Float:ClientPos[3];
	//decl String:EffectT[4];
	if (!IsLegitimateClient(client) || !IsPlayerAlive(client)) return EffectStrength;
	if (IsLegitimateClient(client)) GetClientAbsOrigin(client, ClientPos);
	else {
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
		IsInfected = true;
	}

	static Float:EffectStrengthValue = 0.0;
	static Float:EffectMultiplierValue = 0.0;

	static Float:t_Range	= 0.0;
	static baseeffectbonus = 0;

	if (GetArraySize(SpecialAmmoData) < 1) return 0.0;
	//new Float:fAmmoRangeTalentBonus = GetAbilityStrengthByTrigger(client, client, "aamRNG", FindZombieClass(client), 0, _, _, "d", 1, true);	// true at the end makes sure we don't actually fire off the ability or really check the "d" (resulteffects) here
	//if (fAmmoRangeTalentBonus < 1.0) fAmmoRangeTalentBonus = 1.0;

	//Format(EffectT, sizeof(EffectT), "%c", effect);
	for (new i = AmmoPosition; i < GetArraySize(SpecialAmmoData); i++) {
		if (i < 0) i = 0;
		if (AmmoPosition != -1 && i != AmmoPosition) continue;
		EntityPos[0] = GetArrayCell(SpecialAmmoData, i, 0);
		EntityPos[1] = GetArrayCell(SpecialAmmoData, i, 1);
		EntityPos[2] = GetArrayCell(SpecialAmmoData, i, 2);

		// TalentInfo[0] = TalentName of ammo.
		// TalentInfo[1] = Talent Strength (so use StringToInt)
		// TalentInfo[2] = Talent Damage
		// TalentInfo[3] = Talent Interval
		owner = FindClientByIdNumber(GetArrayCell(SpecialAmmoData, i, 7));

		if (!IsLegitimateClientAlive(owner) || GetArrayCell(SpecialAmmoData, i, 6) <= 0.0) continue;

		pos			= GetArrayCell(SpecialAmmoData, i, 3);
		IsClientInRangeSAKeys[owner]				= GetArrayCell(a_Menu_Talents, pos, 0);
		IsClientInRangeSAValues[owner]				= GetArrayCell(a_Menu_Talents, pos, 1);
		FormatKeyValue(value, sizeof(value), IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "ammo effect?");
		if (!StrEqual(value, EffectT, true)) continue;
		
		GetTalentNameAtMenuPosition(client, GetArrayCell(SpecialAmmoData, i, 3), TalentInfo[0], sizeof(TalentInfo[]));

		if (GetSpecialAmmoStrength(owner, TalentInfo[0], 3) == -1.0) continue;
		if (IsPvP[owner] != 0 && client != owner) continue;
		t_Range		= GetSpecialAmmoStrength(owner, TalentInfo[0], 3);

		if (GetVectorDistance(ClientPos, EntityPos) > (t_Range / 2)) continue;
		if (GetStatusOnly) {

			//LogMessage("Entity %d in range of ammo %c", client, effect);
			return -2.0;		// -2.0 is a special designation.
		}

		if (realowner == 0 || realowner == owner) {

			EffectStrengthValue = GetKeyValueFloat(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "effect strength?");
			EffectMultiplierValue = GetKeyValueFloat(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "effect multiplier?");

			if (EffectStrengthBonus == 0.0) {

				EffectStrength += EffectStrengthValue;
				EffectStrengthBonus = EffectMultiplierValue;
			}
			else {

				EffectStrength += (EffectStrengthValue * EffectStrengthBonus);
				EffectStrengthBonus *= EffectMultiplierValue;
			}

			if (baseeffectvalue > 0.0 && owner != client) {

				/*

					Award the user who has buffed a player.
				*/

				if (!IsInfected && GetClientTeam(client) == GetClientTeam(owner)) IsSameteam = true;





				baseeffectbonus = RoundToCeil(baseeffectvalue + (baseeffectvalue * EffectStrengthValue));
				baseeffectbonus += RoundToCeil(baseeffectbonus * SurvivorExperienceMult);
				if (baseeffectbonus > 0) {

					if (IsSameteam) {

						if (StrEqual(EffectT, "H", true)) AwardExperience(owner, 1, baseeffectbonus);
						if (StrEqual(EffectT, "d", true) ||
							StrEqual(EffectT, "D", true) ||
							StrEqual(EffectT, "R", true) ||
							StrEqual(EffectT, "E", true) ||
							StrEqual(EffectT, "W", true) ||
							StrEqual(EffectT, "a", true)) AwardExperience(owner, 2, baseeffectbonus);
					}
					else {

						if ((StrEqual(EffectT, "F", true) || StrEqual(EffectT, "W", true) || StrEqual(EffectT, "x", true)) && IsLegitimateClient(client) && GetClientTeam(client) != GetClientTeam(owner) ||
							(StrEqual(EffectT, "F", true) || StrEqual(EffectT, "x", true)) && IsInfected) AwardExperience(owner, 3, baseeffectbonus);
					}
				}
			}
		}
		if (AmmoPosition != -1) break;
	}
	return EffectStrength;
}

public Action:Timer_AmmoTriggerCooldown(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) AmmoTriggerCooldown[client] = false;
	return Plugin_Stop;
}

stock AdvertiseAction(client, String:TalentName[], bool:isSpell = false) {

	decl String:TalentName_Temp[64];
	decl String:Name[64];
	decl String:text[64];

	GetTranslationOfTalentName(client, TalentName, text, sizeof(text), _, true);
	if (StrEqual(text, "-1")) GetTranslationOfTalentName(client, TalentName, text, sizeof(text), true);

	GetClientName(client, Name, sizeof(Name));



	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClient(i) || IsFakeClient(i)) continue;

		Format(TalentName_Temp, sizeof(TalentName_Temp), "%T", text, i);
		if (isSpell) PrintToChat(i, "%T", "player uses spell", i, blue, Name, orange, green, TalentName_Temp, orange);
		else PrintToChat(i, "%T", "player uses ability", i, blue, Name, orange, green, TalentName_Temp, orange);
	}
}

stock Float:GetSpellCooldown(client, String:TalentName[]) {

	new Float:SpellCooldown = GetAbilityValue(client, TalentName, "cooldown?");
	if (SpellCooldown == -1.0) return 0.0;
	new Float:TheAbilityMultiplier = GetAbilityMultiplier(client, "L", -1);

	if (TheAbilityMultiplier != -1.0) {

		if (TheAbilityMultiplier < 0.0) TheAbilityMultiplier = 0.1;
		else if (TheAbilityMultiplier > 0.0) { //cooldowns are reduced

			SpellCooldown -= (SpellCooldown * TheAbilityMultiplier);
			if (SpellCooldown < 0.0) SpellCooldown = 0.0;
		}
	}
	return SpellCooldown;
}

stock bool:UseAbility(client, target = -1, String:TalentName[], Handle:Keys, Handle:Values, Float:TargetPos[3]) {

	if (!b_IsActiveRound || GetAmmoCooldownTime(client, TalentName, true) != -1.0 || IsAbilityActive(client, TalentName)) return false;
	if (IsLegitimateClientAlive(target)) GetClientAbsOrigin(target, TargetPos);

	new Float:TheAbilityMultiplier = 0.0;
	if (GetKeyValueInt(Keys, Values, "cannot be ensnared?") == 1 && L4D2_GetInfectedAttacker(client) != -1) return false;

	new Float:ClientPos[3];
	GetClientAbsOrigin(client, ClientPos);

	new MySecondary = GetPlayerWeaponSlot(client, 1);
	decl String:MyWeapon[64];

	decl String:Effects[64];
	//new Float:AbilityTime = GetAbilityValue(client, TalentName, "active time?");
	new Float:SpellCooldown = GetSpellCooldown(client, TalentName);

	//new MyAttacker = L4D2_GetInfectedAttacker(client);
	new MyStamina = GetPlayerStamina(client);
	new MyBonus = 0;
	//new MyMaxHealth = GetMaximumHealth(client);
	new iSkyLevelRequirement = GetKeyValueInt(Keys, Values, "sky level requirement?");
	if (iSkyLevelRequirement < 0) iSkyLevelRequirement = 0;

	if (SkyLevel[client] < iSkyLevelRequirement) return false;
	FormatKeyValue(Effects, sizeof(Effects), Keys, Values, "toggle effect?");
	if (StrEqual(Effects, "r", true)) {

		if (!IsPlayerAlive(client) && b_HasDeathLocation[client]) {

			RespawnImmunity[client] = true;
			MyRespawnTarget[client] = -1;
			SDKCall(hRoundRespawn, client);
			CreateTimer(0.1, Timer_TeleportRespawn, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.1, Timer_GiveMaximumHealth, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(3.0, Timer_ImmunityExpiration, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else return false;
	}
	if (StrEqual(Effects, "P", true)) {

		// Toggles between pistol / magnum
		if (IsValidEntity(MySecondary)) {

			GetEntityClassname(MySecondary, MyWeapon, sizeof(MyWeapon));
			if (StrEqual(MyWeapon, "pistol", false)) {

				// This ability only works if a melee weapon is not equipped.
				RemovePlayerItem(client, MySecondary);
				AcceptEntityInput(MySecondary, "Kill");
				if (StrEqual(MyWeapon, "magnum", false)) {

					// give them a magnum.
					ExecCheatCommand(client, "give", "pistol_magnum");
				}
				else {

					// make them dual wield.
					ExecCheatCommand(client, "give", "pistol");
					CreateTimer(0.5, Timer_GiveSecondPistol, client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
	if (StrEqual(Effects, "T", true)) {
		GetClientStance(client, GetAmmoCooldownTime(client, TalentName, true));
	}
	/*if (StrContains(Effects, "S", true) != -1) {
		StaggerPlayer(client, client);
	}*/
	FormatKeyValue(Effects, sizeof(Effects), Keys, Values, "active effect?");
	if (!StrEqual(Effects, "-1")) {

		//if (AbilityTime > 0.0) IsAbilityActive(client, TalentName, AbilityTime);
		//We check active time another way now

		if (StrEqual(Effects, "A", true)) { // restores stamina

			TheAbilityMultiplier = GetAbilityMultiplier(client, "A", 1);
			MyBonus = RoundToCeil(MyStamina * TheAbilityMultiplier);
			if (SurvivorStamina[client] + MyBonus > MyStamina) {

				SurvivorStamina[client] = MyStamina;
			}
			else SurvivorStamina[client] += MyBonus;
		}
		if (StrEqual(Effects, "H", true)) {	// heals the individual

			TheAbilityMultiplier = GetAbilityMultiplier(client, "H", 1);
			HealPlayer(client, client, TheAbilityMultiplier, 'h');
		}
		if (StrEqual(Effects, "t", true)) {	// instantly lowers threat by a percentage

			TheAbilityMultiplier = GetAbilityMultiplier(client, "t", 1);
			iThreatLevel[client] -= RoundToFloor(iThreatLevel[client] * TheAbilityMultiplier);
		}
	}

	//if (menupos >= 0) CheckActiveAbility(client, menupos, _, _, true, true);
	//AdvertiseAction(client, TalentName, false);
	//IsAmmoActive(client, TalentName, SpellCooldown, true);

	// We do this AFTER we've activated the talent.
	if (GetKeyValueInt(Keys, Values, "reactive ability?") == 2) {	// instant, one-time-use abilities that have a cast-bar and then fire immediately.
		if (GetAbilityMultiplier(client, Effects, 5) == -2.0) {
			new reactiveType = GetKeyValueInt(Keys, Values, "reactive type?");
			if (reactiveType == 1) StaggerPlayer(client, GetAnyPlayerNotMe(client));
			else if (reactiveType == 2) {
				new Float:fActiveTime = GetKeyValueFloat(Keys, Values, "active time?");
				CreateProgressBar(client, fActiveTime);
				new Handle:datapack;
				CreateDataTimer(fActiveTime, Timer_ReactiveCast, datapack, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(datapack, client);
				WritePackCell(datapack, RoundToCeil(GetMaximumHealth(client) * GetKeyValueFloat(Keys, Values, "active strength?")));
			}
			AdvertiseAction(client, TalentName, false);
			IsAmmoActive(client, TalentName, SpellCooldown, true);
		}
	}
	else {
		AdvertiseAction(client, TalentName, false);
		IsAmmoActive(client, TalentName, SpellCooldown, true);
	}

	return true;
}

public Action:Timer_ReactiveCast(Handle:timer, Handle:datapack) {
	ResetPack(datapack);
	new client = ReadPackCell(datapack);
	if (IsLegitimateClient(client)) {
		new amount = ReadPackCell(datapack);
		CreateFireEx(client);
		DoBurn(client, client, amount);

		// we also do this burn damage to all supers, witches, and specials in range of the fire.
		// because molotov is a set size, trying to match that here.
		new Float:cpos[3];
		GetClientAbsOrigin(client, cpos);
		new Float:tpos[3];
		// specials
		for (new target = 1; target <= MaxClients; target++) {
			if (!IsLegitimateClient(target) || GetClientTeam(target) != TEAM_INFECTED) continue;
			GetClientAbsOrigin(target, tpos);
			if (GetVectorDistance(cpos, tpos) > 256.0) continue;
			DoBurn(target, client, amount);
		}
		// supers
		new common;
		/*for (new target = 0; target < GetArraySize(CommonInfected); target++) {
			common = GetArrayCell(CommonInfected, target);
			if (!IsSpecialCommon(common)) continue;
			GetEntPropVector(common, Prop_Send, "m_vecOrigin", tpos);
			if (GetVectorDistance(cpos, tpos) > 256.0) continue;
			DoBurn(common, client, amount);
		}*/
		// witches
		for (new target = 0; target < GetArraySize(WitchList); target++) {
			common = GetArrayCell(WitchList, target);
			if (!IsWitch(common)) continue;
			GetEntPropVector(common, Prop_Send, "m_vecOrigin", tpos);
			if (GetVectorDistance(cpos, tpos) > 256.0) continue;
			DoBurn(common, client, amount);
		}
	}
	return Plugin_Stop;
}

public Action:Timer_GiveSecondPistol(Handle:timer, any:client) {

	if (IsLegitimateClientAlive(client)) {

		ExecCheatCommand(client, "give", "pistol");
	}
	return Plugin_Stop;
}

/* returns the # of unlocks a player will receive for the next prestige
   Put this here because we're going to use this to verify # of player upgrades.
*/
stock GetPrestigeLevelNodeUnlocks(level) {
	if (iSkyLevelNodeUnlocks > 0) return iSkyLevelNodeUnlocks;
	return level;
}

stock bool:CastSpell(client, target = -1, String:TalentName[], Float:TargetPos[3], Float:visualDelayTime = 1.0) {

	if (!b_IsActiveRound || !IsLegitimateClientAlive(client) || L4D2_GetInfectedAttacker(client) != -1 || GetAmmoCooldownTime(client, TalentName) != -1.0) return false;
	if (IsSpellAnAura(client, TalentName)) {
		GetClientAbsOrigin(client, TargetPos);
		target = client;
	}
	else if (IsLegitimateClientAlive(target)) GetClientAbsOrigin(target, TargetPos);	// if the target is -1 / not alive, TargetPos will have been sent through.

	if (bIsSurvivorFatigue[client]) return false;

	new StaminaCost = RoundToCeil(GetSpecialAmmoStrength(client, TalentName, 2));
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

	decl String:key[64];
	GetClientAuthString(client, key, sizeof(key));
	new ClientMenuPosition = GetMenuPosition(client, TalentName);

	new Float:f_TotalTime = GetSpecialAmmoStrength(client, TalentName);
	new Float:SpellCooldown = f_TotalTime + GetSpecialAmmoStrength(client, TalentName, 1);
	
	// It's going to be a headache re-structuring this, so i am doing it in a sequence. to make it easier interval will just clone totaltime for now.
	new Float:f_Interval = f_TotalTime; //GetSpecialAmmoStrength(client, TalentName, 4);
	if (IsSpellAnAura(client, TalentName)) f_Interval = fSpecialAmmoInterval;	// Auras follow players and re-draw on every tick.

	//if (f_Interval > f_TotalTime) f_Interval = f_TotalTime;
	IsAmmoActive(client, TalentName, SpellCooldown);

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i)) DrawSpecialAmmoTarget(i, _, _, ClientMenuPosition, TargetPos[0], TargetPos[1], TargetPos[2], f_Interval, client, TalentName, target);
	}

	new bulletStrength = RoundToCeil(GetBaseWeaponDamage(client, target, TargetPos[0], TargetPos[1], TargetPos[2], DMG_BULLET) * 0.1);
	bulletStrength = RoundToCeil(GetAbilityStrengthByTrigger(client, -2, "D", _, bulletStrength, _, _, "D", 1, true));
	new Float:amSTR = GetSpecialAmmoStrength(client, TalentName, 5);
	if (amSTR > 0.0) bulletStrength = RoundToCeil(bulletStrength * amSTR);
	//decl String:SpecialAmmoData_s[512];
	//Format(SpecialAmmoData_s, sizeof(SpecialAmmoData_s), "%3.3f %3.3f %3.3f}%s{%d{%d{%3.2f}%s}%3.2f}%d}%3.2f}%d", TargetPos[0], TargetPos[1], TargetPos[2], TalentName, GetTalentStrength(client, TalentName), GetBaseWeaponDamage(client, -1, TargetPos[0], TargetPos[1], TargetPos[2], DMG_BULLET), f_Interval, key, SpellCooldown, -1, GetSpecialAmmoStrength(client, TalentName, 1), target);
	//Format(SpecialAmmoData_s, sizeof(SpecialAmmoData_s), "%3.3f %3.3f %3.3f}%s{%d{%d{%3.2f}%s}%3.2f}%d}%3.2f}%d", TargetPos[0], TargetPos[1], TargetPos[2], TalentName, GetTalentStrength(client, TalentName), bulletStrength, f_Interval, key, f_TotalTime, -1, GetSpecialAmmoStrength(client, TalentName, 1), target);
												//13908.302 2585.922 32.133}adren ammo{1{20{15.00}STEAM_1:1:440606022}15.00}-1}30.00}-1
	//PrintToChatAll("%d", StringToInt(key[10]));
	new sadsize = GetArraySize(SpecialAmmoData);

	ResizeArray(SpecialAmmoData, sadsize + 1);
	SetArrayCell(SpecialAmmoData, sadsize, TargetPos[0], 0);
	SetArrayCell(SpecialAmmoData, sadsize, TargetPos[1], 1);
	SetArrayCell(SpecialAmmoData, sadsize, TargetPos[2], 2);
	SetArrayCell(SpecialAmmoData, sadsize, ClientMenuPosition, 3); //GetTalentNameAtMenuPosition(client, pos, String:TheString, stringSize) instead of storing TalentName
	SetArrayCell(SpecialAmmoData, sadsize, GetTalentStrength(client, TalentName), 4);
	SetArrayCell(SpecialAmmoData, sadsize, bulletStrength, 5);
	SetArrayCell(SpecialAmmoData, sadsize, f_Interval, 6);
	SetArrayCell(SpecialAmmoData, sadsize, StringToInt(key[10]), 7);	// only captures the #ID: 440606022 - is faster than parsing a string every time.
	SetArrayCell(SpecialAmmoData, sadsize, f_TotalTime, 8);
	SetArrayCell(SpecialAmmoData, sadsize, -1, 9);
	SetArrayCell(SpecialAmmoData, sadsize, GetSpecialAmmoStrength(client, TalentName, 1), 10);	// float.
	SetArrayCell(SpecialAmmoData, sadsize, target, 11);
	SetArrayCell(SpecialAmmoData, sadsize, visualDelayTime, 12);	// original value must be stored.
	SetArrayCell(SpecialAmmoData, sadsize, visualDelayTime, 13);



	//PushArrayString(Handle:SpecialAmmoData, SpecialAmmoData_s);
	return true;
}

stock DoBurn(attacker, victim, baseWeaponDamage) {

	//if (iTankRush == 1 && FindZombieClass(victim) == ZOMBIECLASS_TANK) return;

	if (IsLegitimateClientAlive(victim)) {

		bIsBurnCooldown[victim] = true;
		CreateTimer(1.0, Timer_ResetBurnImmunity, victim, TIMER_FLAG_NO_MAPCHANGE);
	}
 	new hAttacker = attacker;
 	if (!IsLegitimateClient(hAttacker)) hAttacker = -1;

 	if (IsCommonInfected(victim) || IsWitch(victim) && !(GetEntityFlags(victim) & FL_ONFIRE)) {

		if (IsCommonInfected(victim)) {

			if (!IsSpecialCommon(victim)) OnCommonInfectedCreated(victim, true);
			else AddSpecialCommonDamage(attacker, victim, baseWeaponDamage, true);
		}
		else {
			IgniteEntity(victim, 10.0);
			AddWitchDamage(attacker, victim, baseWeaponDamage, true);
		}
	}
 	if (IsLegitimateClientAlive(victim) && GetClientStatusEffect(victim, "burn") < iDebuffLimit) {

		if (ISEXPLODE[victim] == INVALID_HANDLE) CreateAndAttachFlame(victim, RoundToCeil(baseWeaponDamage * TheInfernoMult), 10.0, 0.5, hAttacker, "burn");
		else CreateAndAttachFlame(victim, RoundToCeil((baseWeaponDamage * TheInfernoMult) * TheScorchMult), 10.0, 0.5, hAttacker, "burn");
 	}
}

stock BeanBagAmmo(client, Float:force, TalentClient) {

	if (!IsCommonInfected(client) && !IsLegitimateClientAlive(client)) return;
	if (!IsLegitimateClientAlive(TalentClient)) return;

	new Float:Velocity[3];
	
	Velocity[0]	=	GetEntPropFloat(TalentClient, Prop_Send, "m_vecVelocity[0]");
	Velocity[1]	=	GetEntPropFloat(TalentClient, Prop_Send, "m_vecVelocity[1]");
	Velocity[2]	=	GetEntPropFloat(TalentClient, Prop_Send, "m_vecVelocity[2]");

	new Float:Vec_Pull;
	new Float:Vec_Lunge;
	/*if (client != TalentClient) {

		//new CartXP = RoundToCeil(GetClassMultiplier(TalentClient, force, "enX", true));
		//AddTalentExperience(TalentClient, "endurance", RoundToCeil(force));
	}*/

	Vec_Pull	=	GetRandomFloat(force * -1.0, force);
	Vec_Lunge	=	GetRandomFloat(force * -1.0, force);
	Velocity[2]	+=	force;

	if (Vec_Pull < 0.0 && Velocity[0] > 0.0) Velocity[0] *= -1.0;
	Velocity[0] += Vec_Pull;

	if (Vec_Lunge < 0.0 && Velocity[1] > 0.0) Velocity[1] *= -1.0;
	Velocity[1] += Vec_Lunge;

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Velocity);
}

/*

	When a client who has special ammo enabled has an eligible target highlighted, we want to draw an aura around that target (just for the client)
	This aura will cycle appropriately as a player cycles their active ammo.

	I have consciously made the decision (ahead of time, having this foresight) to design it so special ammos cannot be used on self. If a client
	wants to use a defensive ammo, for example, on themselves, they would need to shoot an applicable target (enemy, teammate, vehicle... lol) and then step
	into the range.
*/

// no one sees my special ammo because it should be drawing it based on MY size not theirs but it's drawing it based on theirs and if they have zero points in the talent then they can't see it.
stock DrawSpecialAmmoTarget(TargetClient, bool:IsDebugMode=false, bool:IsValidTarget=false, CurrentPosEx=-1, Float:PosX=0.0, Float:PosY=0.0, Float:PosZ=0.0, Float:f_ActiveTime=0.0, owner=0, String:TalentName[]="none", Target = -1) {		// If we aren't actually drawing..? Stoned idea lost in thought but expanded somewhat not on the original path

	new client = TargetClient;
	if (owner != 0) client = owner;

	if (iRPGMode <= 0) {

		return -1;
	}

	new CurrentPos	= GetMenuPosition(client, TalentName);
	new bool:i_IsDebugMode = false;

	DrawSpecialAmmoKeys[client]		= GetArrayCell(a_Menu_Talents, CurrentPos, 0);
	DrawSpecialAmmoValues[client]	= GetArrayCell(a_Menu_Talents, CurrentPos, 1);

	if (CurrentPosEx == -1) {
		new bool:IsTargetCommonInfected = IsCommonInfected(Target);

		if (GetKeyValueInt(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "humanoid only?") == 1) {

			//Humanoid Only could apply to a wide-range so we break it down here.
			if (!IsTargetCommonInfected && !IsLegitimateClientAlive(Target)) i_IsDebugMode = true;
		}
		if (GetKeyValueInt(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "inanimate only?") == 1) {

			//This is things like vehicles, dumpsters, and other objects that can one-shot your teammates.
			if (IsTargetCommonInfected || IsLegitimateClientAlive(Target)) i_IsDebugMode = true;
		}
		if (GetKeyValueInt(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "allow commons?") == 0 && IsTargetCommonInfected ||
			GetKeyValueInt(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "allow specials?") == 0 && IsLegitimateClientAlive(Target) && GetClientTeam(Target) == TEAM_INFECTED ||
			GetKeyValueInt(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "allow survivors?") == 0 && IsLegitimateClientAlive(Target) && GetClientTeam(Target) == TEAM_SURVIVOR) i_IsDebugMode = true;

		if (i_IsDebugMode && !IsDebugMode) return 0;		// ie if an invalid target is highlighted and debug mode is disabled we don't draw and we don't tell the player anything.
		if (IsValidTarget) {

			if (i_IsDebugMode) return 0;
			else return 1;
		}
	}
	new Float:AfxRange			= GetSpecialAmmoStrength(client, TalentName, 3);

	new Float:AfxRangeBonus = GetAbilityStrengthByTrigger(client, TargetClient, "aamRNG", _, 0, _, _, "d", 1, true);
	if (AfxRangeBonus > 0.0) AfxRangeBonus *= (1.0 + AfxRangeBonus);
	new Float:HighlightTime = fAmmoHighlightTime;

	decl String:AfxDrawPos[64];
	decl String:AfxDrawColour[64];
	new drawpos = 0;
	new drawcolor = 0;
	while (drawpos >= 0 && drawcolor >= 0) {
		drawpos = FormatKeyValue(AfxDrawPos, sizeof(AfxDrawPos), DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "draw pos?", _, _, drawpos);
		drawcolor = FormatKeyValue(AfxDrawColour, sizeof(AfxDrawColour), DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "draw colour?", _, _, drawcolor);
		if (drawpos < 0 || drawcolor < 0) return -1;
		//if (StrEqual(AfxDrawColour, "-1", false)) return -1;		// if there's no colour, we return otherwise you'll get errors like this: TE_Send Exception reported: No TempEntity call is in progress (return 0 here would cause endless loop set to -1 as it is ignored i broke the golden rule lul)
		if (CurrentPosEx != -1) {
			CreateRingSoloEx(-1, AfxRange, AfxDrawColour, AfxDrawPos, false, f_ActiveTime, TargetClient, PosX, PosY, PosZ);
		}
		else {

			CreateRingSoloEx(Target, AfxRange, AfxDrawColour, AfxDrawPos, false, HighlightTime, TargetClient);
			IsSpecialAmmoEnabled[client][3] = Target * 1.0;
		}
	}
	return 2;
}

// < 0 is no entity. 0 is invalid entity. we only draw invalid entities (red rings) if debug mode is enabled.
//if (DrawSpecialAmmoTarget(client) == 0 && IsPlayerDebugMode[client] == 1) DrawSpecialAmmoTarget(client, true);

/*

	Using the position of the current special ammo, we find out what the previous or next slot in the array is that contains a special ammo
	depending on what direction the player is going.
*/
stock CycleSpecialAmmo(client, bool:IsMoveForward=true, bool:GetCurrentPos=false) {

	new CurrentPos = -1;
	new firstPosition = -1;
	decl String:TalentName[64];
	new ArraySize = GetArraySize(a_Menu_Talents);
	for (new i = 0; i < ArraySize; i++) {

		SpecialAmmoKeys[client]		= GetArrayCell(a_Menu_Talents, i, 0);
		SpecialAmmoValues[client]	= GetArrayCell(a_Menu_Talents, i, 1);
		SpecialAmmoSection[client]	= GetArrayCell(a_Menu_Talents, i, 2);
		if (GetKeyValueInt(SpecialAmmoKeys[client], SpecialAmmoValues[client], "special ammo?") != 1) continue;
		GetArrayString(Handle:SpecialAmmoSection[client], 0, TalentName, sizeof(TalentName));
		if (GetTalentStrength(client, TalentName) < 1 || IsAbilityCooldown(client, TalentName)) continue;					// necessary in case a player has the ammo equipped and then respecs into a different ammo. have to make sure any current ammo has talent points.
		if (firstPosition == -1) firstPosition = i;

		if (GetActiveSpecialAmmo(client, TalentName)) {

			CurrentPos = i;
			break;
		}
	}
	if (CurrentPos == -1) CurrentPos = firstPosition;

	if (GetCurrentPos) return CurrentPos;

	firstPosition = -1;
	new lastPosition = -1;
	for (new i = 0; i < ArraySize; i++) {

		SpecialAmmoKeys[client]		= GetArrayCell(a_Menu_Talents, i, 0);
		SpecialAmmoValues[client]	= GetArrayCell(a_Menu_Talents, i, 1);
		SpecialAmmoSection[client]	= GetArrayCell(a_Menu_Talents, i, 2);
		if (GetKeyValueInt(SpecialAmmoKeys[client], SpecialAmmoValues[client], "special ammo?") != 1) continue;
		GetArrayString(Handle:SpecialAmmoSection[client], 0, TalentName, sizeof(TalentName));
		if (GetTalentStrength(client, TalentName) < 1 || IsAbilityCooldown(client, TalentName)) continue;

		if (firstPosition == -1) {

			firstPosition = i;
			if (CurrentPos == -1) return firstPosition;								// If the player doesn't have a selected active talent, we default to the first one they have available.
		}
		if (!IsMoveForward && CurrentPos == firstPosition) lastPosition = i;		// Keep incrementing the last position and return whatever it ends up being if the current position is the first because we need the last.
		else {																		// But if we're moving forward or the last position is the current position, this is how we do it.

			if (!IsMoveForward && CurrentPos == i) break;							// If we're trying to get the previous ammo, and the current isn't the first, then it's obviously the last recorded, and we break out!
			if (IsMoveForward && CurrentPos == lastPosition && lastPosition != i) {
				
				lastPosition = i;													// Looking at the code may seem odd, but this saves us having to create an extra variable/statement.
				break;
			}
			lastPosition = i;

		}
	}
	if (IsMoveForward && CurrentPos == lastPosition && firstPosition != -1) SpecialAmmoSection[client]	= GetArrayCell(a_Menu_Talents, firstPosition, 2);
	else if (lastPosition != -1) SpecialAmmoSection[client]	= GetArrayCell(a_Menu_Talents, lastPosition, 2);

	if (firstPosition != -1) GetArrayString(Handle:SpecialAmmoSection[client], 0, TalentName, sizeof(TalentName));
	else Format(TalentName, sizeof(TalentName), "none");
	Format(ActiveSpecialAmmo[client], sizeof(ActiveSpecialAmmo[]), "%s", TalentName);

	return 0;
}

/*

	We need to get the talent name of the active special ammo.
	This way when an ammo activate triggers it only goes through if that ammo is the type the player currently has selected.
*/
stock bool:GetActiveSpecialAmmo(client, String:TalentName[]) {

	if (!StrEqual(TalentName, ActiveSpecialAmmo[client], false)) return false;
	// So if the talent is the one equipped...
	return true;
}

stock CreateProgressBar(client, Float:TheTime, bool:NahDestroyItInstead=false, bool:NoAdrenaline=false) {

	if (TheTime >= 1.0) {

		new Float:fActionTimeToReduce = GetAbilityStrengthByTrigger(client, client, "progbarspeed", _, 0, _, _, _, 1, true);
		if (fActionTimeToReduce > 0.0) TheTime *= (1.0 - fActionTimeToReduce);
	}

	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	if (NahDestroyItInstead) SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	else {

		new Float:TheRealTime = TheTime;
		if (!NoAdrenaline && HasAdrenaline(client)) TheRealTime *= fAdrenProgressMult;

		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", TheRealTime);
		UseItemTime[client] = TheRealTime + GetEngineTime();
	}
}

stock AdjustProgressBar(client, Float:TheTime) { SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", TheTime); }

stock bool:ActiveProgressBar(client) {

	if (GetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration") <= 0.0) return false;
	return true;
}

public Action:Timer_ImmunityExpiration(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) RespawnImmunity[client] = false;
	return Plugin_Stop;
}

stock Defibrillator(client, target = 0, bool:IgnoreDistance = false) {

	if (target > 0 && IsLegitimateClientAlive(target)) return;


	// respawn people near the player.
	new respawntarget = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

			respawntarget = i;
			break;
		}
	}
	new Float:Origin[3];
	if (client > 0) GetClientAbsOrigin(client, Origin);

	// target defaults to 0.
	for (new i = target; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsPlayerAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR && (i != client || target == 0) && i != target) {

			if (target > 0 && i != target) continue;

			if (target == 0 && b_HasDeathLocation[i] && (IgnoreDistance || GetVectorDistance(Origin, DeathLocation[i]) < 256.0)) {

				PrintToChatAll("%t", "rise again", white, orange, white);
				RespawnImmunity[i] = true;
				MyRespawnTarget[i] = i;
				SDKCall(hRoundRespawn, i);
				CreateTimer(0.1, Timer_TeleportRespawn, i, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.0, Timer_ImmunityExpiration, i, TIMER_FLAG_NO_MAPCHANGE);
			}
			else if (target == 0 && !b_HasDeathLocation[i] && IsLegitimateClientAlive(respawntarget)) {

				SDKCall(hRoundRespawn, i);
				RespawnImmunity[i] = true;
				MyRespawnTarget[i] = respawntarget;
				CreateTimer(0.1, Timer_TeleportRespawn, i, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(3.0, Timer_ImmunityExpiration, i, TIMER_FLAG_NO_MAPCHANGE);
			}
			//SDKCall(hRoundRespawn, i);
			//if (client > 0) LastDeathTime[i] = GetEngineTime() + StringToFloat(GetConfigValue("death weakness time?"));
			//b_HasDeathLocation[i] = false;
		}
	}
}

/*public Action:Timer_BeaconCorpses(Handle:timer) {

	new CurrentEntity			=	-1;
	decl String:EntityName[64];
	if (!b_IsActiveRound) return Plugin_Stop;

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || IsFakeClient(i) || GetClientTeam(i) != TEAM_SURVIVOR || IsIncapacitated(i)) continue;

		BeaconCorpsesCounter[i] += 0.01;
		if (BeaconCorpsesCounter[i] < 0.25) continue;

		CurrentEntity										= GetEntPropEnt(i, Prop_Data, "m_hActiveWeapon");
		if (IsValidEntity(CurrentEntity)) GetEdictClassname(CurrentEntity, EntityName, sizeof(EntityName));
		if (StrContains(EntityName, "defib", false) == -1) continue;

		BeaconCorpsesCounter[i] = 0.0;
		BeaconCorpsesInRange(i);
	}
	return Plugin_Continue;
}*/

stock InventoryItem(client, String:EntityName[] = "none", bool:bIsPickup = false, entity = -1) {

	decl String:ItemName[64];

	new ExplodeCount = GetDelimiterCount(EntityName, ":");
	decl String:Classname[ExplodeCount][64];
	ExplodeString(EntityName, ":", Classname, ExplodeCount, 64);

	if (bIsPickup) {	// Picking up the entity. We store it in the users inventory.

		GetEntityClassname(entity, Classname[0], sizeof(Classname[]));
		GetEntPropString(entity, Prop_Data, "m_iName", ItemName, sizeof(ItemName));
	}
	else {		// Creating the entity. Defaults to -1

		entity	= CreateEntityByName(Classname[0]);
		DispatchKeyValue(entity, "targetname", Classname[1]);
		DispatchKeyValue(entity, "rendermode", "5");
		DispatchKeyValue(entity, "spawnflags", "0");
		DispatchSpawn(entity);
		TeleportEntity(entity, Float:loc, NULL_VECTOR, NULL_VECTOR);
	}
}
stock bool:IsCommonStaggered(client) {
	//decl String:clientId[2][64];
	//decl String:text[64];
	//static Float:timeRemaining = 0.0;
	for (new i = 0; i < GetArraySize(StaggeredTargets); i++) {
		//GetArrayString(StaggeredTargets, i, text, sizeof(text));
		//ExplodeString(text, ":", clientId, 2, 64);
		if (GetArrayCell(StaggeredTargets, i, 0) == client) return true;
		//if (StringToInt(clientId[0]) == client) return true;
	}
	return false;
}

public Action:Timer_StaggerTimer(Handle:timer) {
	//decl String:clientId[2][64];
	//decl String:text[64];
	if (!b_IsActiveRound) {
		ClearArray(Handle:StaggeredTargets);
		return Plugin_Stop;
	}
	static Float:timeRemaining = 0.0;
	for (new i = 0; i < GetArraySize(StaggeredTargets); i++) {
		//GetArrayString(StaggeredTargets, i, text, sizeof(text));
		//ExplodeString(text, ":", clientId, 2, 64);
		//timeRemaining = StringToFloat(clientId[1]);
		timeRemaining = GetArrayCell(StaggeredTargets, i, 1);
		if (timeRemaining <= fStaggerTickrate) RemoveFromArray(StaggeredTargets, i);
		else {
			SetArrayCell(StaggeredTargets, i, timeRemaining - fStaggerTickrate, 1);
			//Format(text, sizeof(text), "%s:%3.3f", clientId[0], timeRemaining - fStaggerTickrate);
			//SetArrayString(StaggeredTargets, i, text);
		}
	}
	return Plugin_Continue;
}

stock EntityWasStaggered(victim, attacker = 0) {
	if (attacker != 0 && IsLegitimateClient(attacker) && (!IsLegitimateClient(victim) || GetClientTeam(victim) != GetClientTeam(attacker))) GetAbilityStrengthByTrigger(attacker, victim, "didStagger");
	if (victim != 0 && IsLegitimateClient(victim) && (!IsLegitimateClient(attacker) || GetClientTeam(attacker) != GetClientTeam(victim))) GetAbilityStrengthByTrigger(victim, attacker, "wasStagger");
}

public Action:Timer_ResetStaggerCooldownOnTriggers(Handle:timer, any:client) {
	if (IsLegitimateClient(client)) staggerCooldownOnTriggers[client] = false;
	return Plugin_Stop;
}

public Action:OnPlayerRunCmd(client, &buttons) {
	if (IsLegitimateClientAlive(client)) {
		// call the stagger ability triggers only when a fresh stagger occurs (and not if multiple staggers happen too-often within each other (2.0 seconds is slightly-longer than one stagger.))
		if (!staggerCooldownOnTriggers[client] && SDKCall(g_hIsStaggering, client)) {
			staggerCooldownOnTriggers[client] = true;
			CreateTimer(2.0, Timer_ResetStaggerCooldownOnTriggers, client, TIMER_FLAG_NO_MAPCHANGE);
			EntityWasStaggered(client);
		}
		//new myTeam = GetClientTeam(client);
		//if (myTeam == TEAM_SURVIVOR) {
			//if ((GetEntityFlags(client) & IN_DUCK)) GetAbilityStrengthByTrigger(client, _, "crouch");
 			//if ((GetEntityFlags(client) & FL_INWATER)) GetAbilityStrengthByTrigger(client, _, "wtr");
 			//else if (!(GetEntityFlags(client) & FL_ONGROUND)) GetAbilityStrengthByTrigger(client, _, "grnd");
 			//if ((GetEntityFlags(client) & FL_ONFIRE)) GetAbilityStrengthByTrigger(client, _, "onfire");
		//}
	}

	new Float:TheTime = GetEngineTime();
	/*if ((buttons & IN_ZOOM)) {
		if (ZoomcheckDelayer[client] == INVALID_HANDLE) {
			ZoomcheckDelayer[client] = CreateTimer(0.1, Timer_ZoomcheckDelayer, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	if ((buttons & IN_ATTACK)) {
		new weaponEntity = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		new bulletsRemaining = 0;
		if (IsValidEntity(weaponEntity)) {
			bulletsRemaining = GetEntProp(weaponEntity, Prop_Send, "m_iClip1");
			if (bulletsRemaining == LastBulletCheck[client]) bulletsRemaining = 0;
			else LastBulletCheck[client] = bulletsRemaining;
		}
		if (bulletsRemaining > 0 && GetEntProp(weaponEntity, Prop_Data, "m_bInReload") != 1 && L4D2_GetInfectedAttacker(client) == -1) {
			holdingFireCheckToggle(client, true);
		}
	}
	else holdingFireCheckToggle(client);*/

	if ((buttons & IN_SPEED)) {

		bIsSprinting[client] = true;
	}
	else bIsSprinting[client] = false;

	//if (IsFakeClient(client)) return Plugin_Continue;

	if ((buttons & IN_USE) && b_IsRoundIsOver) {

		if (ReadyUpGameMode == 3 || StrContains(TheCurrentMap, "zerowarn", false) != -1) {

			decl String:EName[64];
			new entity = GetClientAimTarget(client, false);

			if (entity != -1) {

				//GetEntPropString(entity, Prop_Data, "m_iName", EName, sizeof(EName));
				GetEntityClassname(entity, EName, sizeof(EName));
				//PrintToChat(client, "Name: %s", EName);

				//PrintToChat(client, "ENTITY: %s", EName);
				//if (StrEqual(EName, "survival_alarm_button", false) ||
				//	StrEqual(EName, "escape_gate_button_survival", false)) {
				if (StrContains(EName, "weapon", false) != -1 || StrContains(EName, "physics", false) != -1) {

					//buttons &= ~IN_USE;
					return Plugin_Continue;
				}
				//if (StrContains(EName, "radio", false) != -1) return Plugin_Handled;
			}
			buttons &= ~IN_USE;
			return Plugin_Changed;
		}
	}
	if (ReadyUpGameMode == 3 && !b_IsCheckpointDoorStartOpened && IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR) {

		if (buttons & IN_SPEED && (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT) && (GetEntityFlags(client) & FL_ONGROUND)) {

			MovementSpeed[client] = fSprintSpeed;
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", MovementSpeed[client]);
			buttons &= ~IN_SPEED;
			return Plugin_Changed;
		}
		else {

			MovementSpeed[client] = 1.0;
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", MovementSpeed[client]);
		}
	}

	if (IsLegitimateClientAlive(client) && b_IsActiveRound) {

		if (!IsFakeClient(client) && GetClientTeam(client) == TEAM_SURVIVOR) {

			if (MyBirthday[client] == 0) MyBirthday[client] = GetTime();
			if (iRushingModuleEnabled == 1) {
				if (bRushingNotified[client] && IsPlayerRushing(client, 2048.0)) {

					//IncapacitateOrKill(client, _, _, true, true);
					FindRandomSurvivorClient(client, _, false);
					//bRushingNotified[client] = false;
				}
				else if (!bRushingNotified[client] && IsPlayerRushing(client, 1536.0)) {

					//FindRandomSurvivorClient(client);
					bRushingNotified[client] = true;
					PrintToChat(client, "%T", "Rushing Return To Team", client, orange, blue, orange);
				}
			}
		}

		if (GetClientTeam(client) == TEAM_INFECTED && FindZombieClass(client) == ZOMBIECLASS_TANK) {

			if (!IsAirborne[client] && !(GetEntityFlags(client) & FL_ONGROUND)) {

				IsAirborne[client] = true;	// when the tank lands, aoe explosion!
			}
			else if (IsAirborne[client] && (GetEntityFlags(client) & FL_ONGROUND)) {

				IsAirborne[client] = false;	// the tank has landed; explosion;
				CreateExplosion(client, _, client, true);
			}
			new MyLifetime = GetTime() - MyBirthday[client];
			if (MyBirthday[client] > 0 && NearbySurvivors(client, 1536.0) < 1 && MyLifetime >= 30) {	// by this design, all tanks should ping-pong to the rushers.

				if (MyLifetime >= 90) {

					DeleteMeFromExistence(client);
				}
				else SetSpeedMultiplierBase(client, 2.0);
			}
		}

		if (GetClientTeam(client) == TEAM_SURVIVOR) {

			CheckIfItemPickup(client);
			//CheckBombs(client);
			if (IsFakeClient(client) && !bIsInCheckpoint[client]) {

				if (SurvivorsSaferoomWaiting() || !SurvivorsInRange(client, 1536.0, true)) SurvivorBotsRegroup(client);
			}
		}

		if (buttons & IN_JUMP) bJumpTime[client] = true;
		else {

			bJumpTime[client] = false;
			JumpTime[client] = 0.0;
		}
		new MyAttacker = L4D2_GetInfectedAttacker(client);
		if (!IsLegitimateClientAlive(MyAttacker)) StrugglePower[client] = 0;
		new bool:EnrageActivity = IsEnrageActive();

		if (CombatTime[client] <= TheTime && bIsInCombat[client] && !EnrageActivity && (iPlayersLeaveCombatDuringFinales == 1 || !b_IsFinaleActive)) {

			bIsInCombat[client] = false;
			iThreatLevel[client] = 0;
			LastAttackTime[client] = 0.0;
			if (!IsSurvivalMode) AwardExperience(client);
		}
		else if (CombatTime[client] > TheTime || EnrageActivity || b_IsFinaleActive) {

			bIsInCombat[client] = true;
			if (!bIsHandicapLocked[client]) bIsHandicapLocked[client] = true;
		}
		//if (GetClientTeam(client) == TEAM_INFECTED) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		if (GetClientTeam(client) == TEAM_SURVIVOR) {
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", MovementSpeed[client]);
		}

		if (ISDAZED[client] > TheTime) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue") * fDazedDebuffEffect);
		else if (ISDAZED[client] <= TheTime && ISDAZED[client] != 0.0) {

			BlindPlayer(client, _, 0);	// wipe the dazed effect.
			ISDAZED[client] = 0.0;
		}

		if (IsPlayerAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR) {

			if (!(GetEntityFlags(client) & FL_ONGROUND) && !b_IsFloating[client]) {

				b_IsFloating[client] = true;
				GetClientAbsOrigin(client, JumpPosition[client][0]);
			}
			if (GetEntityFlags(client) & FL_ONGROUND) {

				if (b_IsFloating[client]) {

					GetClientAbsOrigin(client, JumpPosition[client][1]);
					//new Float:Z1 = JumpPosition[client][0][2];
					//new Float:Z2 = JumpPosition[client][1][2];

					//if (Z1 > Z2 && Z1 - Z2 >= StringToFloat(GetConfigValue("fall damage critical?"))) IncapacitateOrKill(client, _, _, true);
					//if (Z1 > Z2) {

						//Z1 -= Z2;
						//IsClientActiveBuff(client, 'Q', Z1);
					//}
				}
				b_IsFloating[client] = false;	// in case it was bugged or something (just for safe reason)
			}

			new CurrentEntity			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

			decl String:EntityName[64];

			Format(EntityName, sizeof(EntityName), "}");
			if (IsValidEntity(CurrentEntity)) GetEdictClassname(CurrentEntity, EntityName, sizeof(EntityName));

			if (StrContains(EntityName, "chainsaw", false) != -1 && (buttons & IN_RELOAD) && GetEntProp(CurrentEntity, Prop_Data, "m_iClip1") < 30 && HasCommandAccess(client, "z")) {

				//SetEntProp(CurrentEntity, Prop_Data, "m_iClip1", 30);
				buttons &= ~IN_RELOAD;
			}

			if (ActiveProgressBar(client) &&
				CurrentEntity != ProgressEntity[client] ||
				(!(GetEntityFlags(client) & FL_ONGROUND) && !IsIncapacitated(client)) ||
				L4D2_GetInfectedAttacker(client) != -1 ||
				!IsValidEntity(CurrentEntity) && !IsIncapacitated(client) ||
				((StrContains(EntityName, "pain_pills", false) == -1 &&
				StrContains(EntityName, "adrenaline", false) == -1  &&
				StrContains(EntityName, "first_aid", false) == -1 &&
				StrContains(EntityName, "defib", false) == -1) && !IsIncapacitated(client))) {

				CreateProgressBar(client, 0.0, true);
				UseItemTime[client] = 0.0;
				if (GetEntPropEnt(client, Prop_Send, "m_reviveOwner") == client) {

					SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
					SetEntPropEnt(client, Prop_Send, "m_reviveTarget", -1);
				}
			}

			if (IsIncapacitated(client) && L4D2_GetInfectedAttacker(client) == -1 || (L4D2_GetInfectedAttacker(client) == -1 && IsValidEntity(CurrentEntity) &&
				(StrContains(EntityName, "pain_pills", false) != -1 ||
				StrContains(EntityName, "adrenaline", false) != -1  ||
				StrContains(EntityName, "first_aid", false) != -1 ||
				StrContains(EntityName, "defib", false) != -1))) {

				//blocks the use of meds on people. will add an option in the menu later for now allowing.
				/*if ((buttons & IN_ATTACK2) && !IsIncapacitated(client)) {

					if (StrContains(EntityName, "first_aid", false) != -1) {

						buttons &= ~IN_ATTACK2;
						return Plugin_Changed;
					}
				}*/
				new reviveOwner = -1;
				if ((!(buttons & IN_ATTACK) && ActiveProgressBar(client) && !IsIncapacitated(client)) || (!(buttons & IN_USE) && ActiveProgressBar(client) && IsIncapacitated(client))) {

					CreateProgressBar(client, 0.0, true);
					UseItemTime[client] = 0.0;
					reviveOwner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
					if (reviveOwner == client) {

						SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
						SetEntPropEnt(client, Prop_Send, "m_reviveTarget", -1);
					}
					/*
					if (IsLegitimateClientAlive(reviveOwner) && GetClientTeam(reviveOwner) == TEAM_SURVIVOR) {

						SetEntPropEnt(reviveOwner, Prop_Send, "m_reviveTarget", -1);
						SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
					}*/
				}
				if (((buttons & IN_ATTACK) && !IsIncapacitated(client)) || ((buttons & IN_USE) && IsIncapacitated(client))) {

					if (!IsIncapacitated(client)) buttons &= ~IN_ATTACK;
					else buttons &= ~IN_USE;

					if (UseItemTime[client] < TheTime) {

						if (ActiveProgressBar(client)) {

							UseItemTime[client] = 0.0;
							CreateProgressBar(client, 0.0, true);
							if (!IsIncapacitated(client)) {

								if (StrContains(EntityName, "pain_pills", false) != -1) {

									HealPlayer(client, client, GetTempHealth(client) + (GetMaximumHealth(client) * 0.3), 'h', true);//SetTempHealth(client, client, GetTempHealth(client) + (GetMaximumHealth(client) * 0.3), false);		// pills add 10% of your total health in temporary health.
									AcceptEntityInput(CurrentEntity, "Kill");
								}
								else if (StrContains(EntityName, "adrenaline", false) != -1) {

									SetAdrenalineState(client);
									new StaminaBonus = RoundToCeil(GetPlayerStamina(client) * 0.25);
									if (SurvivorStamina[client] + StaminaBonus >= GetPlayerStamina(client)) {

										SurvivorStamina[client] = GetPlayerStamina(client);
										bIsSurvivorFatigue[client] = false;
									}
									else SurvivorStamina[client] += StaminaBonus;
									AcceptEntityInput(CurrentEntity, "Kill");
								}
								else if (StrContains(EntityName, "defib", false) != -1) {

									Defibrillator(client);
									AcceptEntityInput(CurrentEntity, "Kill");
								}
								else if (StrContains(EntityName, "first_aid", false) != -1) {

									GiveMaximumHealth(client);
									RefreshSurvivor(client);
									AcceptEntityInput(CurrentEntity, "Kill");
								}
								/*else if (IsIncapacitated(client)) {// && !IsLedged(client)) {

									//if (bAutoRevive[client]) bAutoRevive[client] = false;

									ReviveDownedSurvivor(client);
									OnPlayerRevived(client, client);
									reviveOwner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
									if (IsLegitimateClientAlive(reviveOwner)) SetEntPropEnt(reviveOwner, Prop_Send, "m_reviveTarget", -1);
									SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
								}*/
							}
							else {

								ReviveDownedSurvivor(client);
								OnPlayerRevived(client, client);
								reviveOwner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
								if (IsLegitimateClientAlive(reviveOwner)) SetEntPropEnt(reviveOwner, Prop_Send, "m_reviveTarget", -1);
								SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
							}
						}
						else {

							if (IsIncapacitated(client) && UseItemTime[client] < TheTime) {

								//if (!IsLedged(client)) {

								reviveOwner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
								if (!IsLegitimateClientAlive(reviveOwner)) {

									SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
									ProgressEntity[client]			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
									CreateProgressBar(client, 5.0);	// you can pick yourself up for free but it takes a bit.
								}
								//}
							}
							if (StrContains(EntityName, "pain_pills", false) != -1 && UseItemTime[client] < TheTime && !IsIncapacitated(client)) {

								ProgressEntity[client]			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
								CreateProgressBar(client, 2.0);
								//UseItemTime[client] = TheTime + 2;
							}
							else if (StrContains(EntityName, "adrenaline", false) != -1 && UseItemTime[client] < TheTime && !IsIncapacitated(client)) {

								ProgressEntity[client]			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
								CreateProgressBar(client, 1.0);
								//UseItemTime[client] = TheTime + 1;
							}
							else if (StrContains(EntityName, "first_aid", false) != -1 && UseItemTime[client] < TheTime) {

								ProgressEntity[client]			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
								CreateProgressBar(client, 5.0);
								//UseItemTime[client] = TheTime + 5;
							}
							else if (!IsIncapacitated(client) && (StrContains(EntityName, "defib", false) != -1 || StrContains(EntityName, "first_aid", false) != -1) && UseItemTime[client] < TheTime) {

								ProgressEntity[client]			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
								CreateProgressBar(client, 5.0);
								//UseItemTime[client] = TheTime + 10;
							}
							if (ActiveProgressBar(client)) SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
						}
					}
					return Plugin_Changed;
				}
			}
			// For drawing special ammo.
			if (bIsSurvivorFatigue[client]) {

				IsSpecialAmmoEnabled[client][0] = 0.0;
				Format(ActiveSpecialAmmo[client], sizeof(ActiveSpecialAmmo[]), "none");
			}
			/*if (IsSpecialAmmoEnabled[client][2] <= TheTime || GetClientAimTarget(client, false) != IsSpecialAmmoEnabled[client][3] * 1.0) {

				if (IsSpecialAmmoEnabled[client][0] == 1.0 && DrawSpecialAmmoTarget(client) == 0 && IsPlayerDebugMode[client] == 1) DrawSpecialAmmoTarget(client, true);
				IsSpecialAmmoEnabled[client][2] = TheTime + fAmmoHighlightTime;
			} deprecated */

			if (!IsFakeClient(client)) {

				//new ConsumptionInt = iStamConsumptionInt;

				if ((ReadyUp_GetGameMode() != 3 || !b_IsSurvivalIntermission) && iRPGMode >= 1) {

					new bool:IsJetpackBroken = IsCoveredInBile(client);
					if (!IsJetpackBroken) IsJetpackBroken = AnyTanksNearby(client);

					/*
						Add or remove conditions from the following line to determine when the jetpack automatically disables.
						When adding new conditions, consider a switch so server operators can choose which of them they want to use.
					*/
					if (bJetpack[client] && (iCanJetpackWhenInCombat == 1 || !bIsInCombat[client]) && (!(buttons & IN_JUMP) || IsJetpackBroken || L4D2_GetInfectedAttacker(client) != -1)) ToggleJetpack(client, true);
					//else if (!(GetEntityFlags(client) & FL_ONGROUND) && !bIsSurvivorFatigue[client] && !bJetpack[client] && (buttons & IN_JUMP)) ToggleJetpack(client);

					if ((bJetpack[client] || !bJetpack[client] && !(GetEntityFlags(client) & FL_ONGROUND)) ||
						((buttons & IN_JUMP) || ((buttons & IN_SPEED) && (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT))) &&
						SurvivorStamina[client] >= ConsumptionInt && !bIsSurvivorFatigue[client] && ISSLOW[client] == INVALID_HANDLE && ISFROZEN[client] == INVALID_HANDLE) {

						if (L4D2_GetInfectedAttacker(client) == -1 && ISSLOW[client] == INVALID_HANDLE && ISFROZEN[client] == INVALID_HANDLE) {

							if (SurvivorConsumptionTime[client] <= TheTime && (buttons & IN_JUMP || buttons & IN_SPEED)) {
								if (bJetpack[client]) {
									new Float:nextSprintInterval = GetAbilityStrengthByTrigger(client, client, "jetpack", _, 0, _, _, "flightcost", _, _, 2);
									if (nextSprintInterval > 0.0) {
										SurvivorConsumptionTime[client] = TheTime + fStamSprintInterval + (fStamSprintInterval * nextSprintInterval);
									}
									else SurvivorConsumptionTime[client] = TheTime + fStamSprintInterval;
								}
								else SurvivorConsumptionTime[client] = TheTime + fStamSprintInterval;
								SurvivorStamina[client] -= ConsumptionInt;
								//AddTalentExperience(client, "endurance", ConsumptionInt);
								if (SurvivorStamina[client] <= 0) {

									bIsSurvivorFatigue[client] = true;
									IsSpecialAmmoEnabled[client][0] = 0.0;
									SurvivorStamina[client] = 0;
									if (bJetpack[client]) ToggleJetpack(client, true);
								}
							}
							if (!bIsSurvivorFatigue[client] && !bJetpack[client] && ((buttons & IN_JUMP) && (JumpTime[client] >= 0.2)) && (iCanJetpackWhenInCombat == 1 || !bIsInCombat[client]) && !IsJetpackBroken && JetpackRecoveryTime[client] <= GetEngineTime() && L4D2_GetInfectedAttacker(client) == -1) ToggleJetpack(client);
							if (!bJetpack[client]) MovementSpeed[client] = fSprintSpeed;
						}
						buttons &= ~IN_SPEED;
						return Plugin_Changed;
					}
					if (!(buttons & IN_SPEED) && !bJetpack[client]) {

						new PlayerMaxStamina = GetPlayerStamina(client);

						if (SurvivorStaminaTime[client] < TheTime && SurvivorStamina[client] < PlayerMaxStamina) {

							if (!HasAdrenaline(client)) SurvivorStaminaTime[client] = TheTime + fStamRegenTime;
							else SurvivorStaminaTime[client] = TheTime + fStamRegenTimeAdren;
							SurvivorStamina[client]++;
						}
						//if (GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue") != StringToFloat(GetConfigValue("base movement speed?"))) {

						if (!bIsSurvivorFatigue[client]) MovementSpeed[client] = fBaseMovementSpeed;
						else MovementSpeed[client] = fFatigueMovementSpeed;
						if (ISSLOW[client] != INVALID_HANDLE) MovementSpeed[client] *= fSlowSpeed[client];
						//}
						if (SurvivorStamina[client] >= PlayerMaxStamina) {

							bIsSurvivorFatigue[client] = false;
							SurvivorStamina[client] = PlayerMaxStamina;
						}
					}
				}
			}

			/*if (buttons & IN_JUMP) {

				if (L4D2_GetInfectedAttacker(client) == -1 && L4D2_GetSurvivorVictim(client) == -1 && (GetEntityFlags(client) & FL_ONGROUND)) {

					GetAbilityStrengthByTrigger(client, 0, 'j', FindZombieClass(client), 0);
				}
				if (L4D2_GetSurvivorVictim(client) != -1) {

					new victim = L4D2_GetSurvivorVictim(client);
					if ((GetEntityFlags(victim) & FL_ONGROUND)) GetAbilityStrengthByTrigger(client, victim, 'J', FindZombieClass(client), 0);
				}
			}
			else if (!(buttons & IN_JUMP) && b_IsJumping[client]) ModifyGravity(client);*/
		}
	}
	return Plugin_Continue;
}

stock ToggleJetpack(client, DisableJetpack = false) {

	new Float:ClientPos[3];
	GetClientAbsOrigin(client, ClientPos);
	if (!DisableJetpack && !bJetpack[client]) {

		EmitSoundToAll(JETPACK_AUDIO, client, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, SNDPITCH_NORMAL, -1, ClientPos, NULL_VECTOR, true, 0.0);
		SetEntityMoveType(client, MOVETYPE_FLY);
		bJetpack[client] = true;
	}
	else if (DisableJetpack && bJetpack[client]) {

		StopSound(client, SNDCHAN_WEAPON, JETPACK_AUDIO);
		//EmitSoundToAll(JETPACK_AUDIO, client, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, ClientPos, NULL_VECTOR, true, 0.0);
		SetEntityMoveType(client, MOVETYPE_WALK);
		bJetpack[client] = false;
	}
}

stock bool:IsEveryoneBoosterTime() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR && !HasBoosterTime(i)) return false;
	}
	return true;
}

stock CreateDamageStatusEffect(client, type = 0, target = 0, damage = 0, owner = 0, Float:RangeOverride = 0.0) {

	if (!IsSpecialCommon(client)) return;
	new Float:AfxRange = GetCommonValueFloat(client, "range player level?");
	new Float:AfxStrengthLevel = GetCommonValueFloat(client, "level strength?");
	new Float:AfxRangeMax = GetCommonValueFloat(client, "range max?");
	new AfxMultiplication = GetCommonValueInt(client, "enemy multiplication?");
	new AfxStrength = GetCommonValueInt(client, "aura strength?");
	new Float:AfxStrengthTarget = GetCommonValueFloat(client, "strength target?");
	new Float:AfxRangeBase = GetCommonValueFloat(client, "range minimum?");
	new Float:OnFireBase = GetCommonValueFloat(client, "onfire base time?");
	new Float:OnFireLevel = GetCommonValueFloat(client, "onfire level?");
	new Float:OnFireMax = GetCommonValueFloat(client, "onfire max time?");
	new Float:OnFireInterval = GetCommonValueFloat(client, "onfire interval?");
	new AfxLevelReq = GetCommonValueInt(client, "level required?");

	new Float:ClientPosition[3];
	new Float:TargetPosition[3];

	new t_Strength = 0;
	new Float:t_Range = 0.0;
	//new ent = -1;

	new Float:t_OnFireRange = 0.0;

	if (damage > 0) AfxStrength = damage;	// if we want to base the damage on a specific value, we can override here.

	GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPosition);
	new NumLivingEntities = LivingEntitiesInRange(client, ClientPosition, AfxRangeMax);
	if (NumLivingEntities > 1) damage = (damage / NumLivingEntities);
	if (target == 0 || IsLegitimateClient(target)) {

		for (new i = 1; i <= MaxClients; i++) {

			if (!IsLegitimateClientAlive(i) || (target != 0 && i != target) || PlayerLevel[i] < AfxLevelReq) continue;		// if type is 1 and target is 0 acid is spread to all players nearby. but if target is not 0 it is spread to only the player the acid zombie hits. or whatever type uses it.
			GetClientAbsOrigin(i, TargetPosition);

			if (RangeOverride == 0.0) {

				if (AfxRange > 0.0) t_Range = AfxRange * (PlayerLevel[i] - AfxLevelReq);
				else t_Range = AfxRangeMax;
				if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
				else t_Range += AfxRangeBase;
			}
			else t_Range = RangeOverride;
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

			if (IsSpecialCommonInRange(client, 'b')) {

				t_Strength = GetSpecialCommonDamage(t_Strength, client, 'b', i);
			}

			//PrintToChatAll("Setting %N on fire for %d damage over %3.2f seconds", i, t_Strength, t_OnFireRange);
			if (type == 0) CreateAndAttachFlame(i, t_Strength, t_OnFireRange, OnFireInterval, _, "burn");		// Static time for now.
			else if (type == 4) {

				CreateAndAttachFlame(i, t_Strength, t_OnFireRange, OnFireInterval, _, "acid");
				break;	// to prevent buffer overflow only allow it on one client.
			}
		}
	}
	if (target == 0 || IsCommonInfected(target)) {

		new ent = -1;
		for (new i = 0; i < GetArraySize(Handle:CommonInfected); i++) {
			ent = GetArrayCell(Handle:CommonInfected, i);
			if (!IsCommonInfected(ent)) continue;
			if (ent == client) continue;
			if (target != 0 && ent != target) continue;
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TargetPosition);
			if (GetVectorDistance(ClientPosition, TargetPosition) > (AfxRangeMax / 2)) continue;
			if (!IsSpecialCommon(ent)) OnCommonInfectedCreated(ent, true, _, true); // will calculate xp rewards, unhook, and set on fire.
			else if (IsLegitimateClient(owner) && GetClientTeam(owner) == TEAM_SURVIVOR && IsSpecialCommon(ent)) AddSpecialCommonDamage(owner, ent, damage);
		}
	}
	//ClearSpecialCommon(client);
}

stock ExplosiveAmmo(client, damage, TalentClient) {

	if (IsWitch(client)) AddWitchDamage(TalentClient, client, damage);
	else if (IsSpecialCommon(client)) AddSpecialCommonDamage(TalentClient, client, damage);
	else if (IsLegitimateClientAlive(client)) {

		if (GetClientTeam(client) == TEAM_INFECTED) AddSpecialInfectedDamage(TalentClient, client, damage);
		else SetClientTotalHealth(client, damage);	// survivor teammates don't reward players with experience or damage bonus, but they'll take damage from it.
	}
	/*if (client != TalentClient && (!IsCommonInfected(client) || IsSpecialCommon(client)) && (IsLegitimateClientAlive(client) && GetClientTeam(client) != TEAM_SURVIVOR)) {
		AddTalentExperience(TalentClient, "agility", damage);
	} */
}

stock HealingAmmo(client, healing, TalentClient, bool:IsCritical=false) {

	if (!IsLegitimateClientAlive(client) || !IsLegitimateClientAlive(TalentClient)) return;
	HealPlayer(client, TalentClient, healing * 1.0, 'h', true);
}

stock LeechAmmo(client, damage, TalentClient) {

	if (IsWitch(client)) AddWitchDamage(TalentClient, client, damage);
	else if (IsSpecialCommon(client)) AddSpecialCommonDamage(TalentClient, client, damage);
	else if (IsLegitimateClientAlive(client)) {

		if (GetClientTeam(client) == TEAM_INFECTED) AddSpecialInfectedDamage(TalentClient, client, damage);
		else SetClientTotalHealth(client, damage);
	}
	if (IsLegitimateClientAlive(TalentClient) && GetClientTeam(TalentClient) == TEAM_SURVIVOR) {

		//if (IsCritical || !IsCriticalHit(client, healing, TalentClient))	// maybe add this to leech? that would be cool.!
		HealPlayer(TalentClient, TalentClient, damage * 1.0, 'h', true);
	}
}

stock Float:CreateBomberExplosion(client, target, String:Effects[], basedamage = 0) {

	//if (IsLegitimateClient(target) && !IsPlayerAlive(target)) return;
	if (!IsLegitimateClientAlive(target)) return;

	/*

		When a bomber dies, it explodes.
	*/
	new Float:AfxRange = GetCommonValueFloat(client, "range player level?");
	new Float:AfxStrengthLevel = GetCommonValueFloat(client, "level strength?");
	new Float:AfxRangeMax = GetCommonValueFloat(client, "range max?");
	new AfxMultiplication = GetCommonValueInt(client, "enemy multiplication?");
	new AfxStrength = GetCommonValueInt(client, "aura strength?");
	new AfxChain = GetCommonValueInt(client, "chain reaction?");
	new Float:AfxStrengthTarget = GetCommonValueFloat(client, "strength target?");
	new Float:AfxRangeBase = GetCommonValueFloat(client, "range minimum?");
	new AfxLevelReq = GetCommonValueInt(client, "level required?");
	new isRaw = GetCommonValueInt(client, "raw strength?");
	new rawCommon = GetCommonValueInt(client, "raw common strength?");
	new rawPlayer = GetCommonValueInt(client, "raw player strength?");


	if (IsSpecialCommon(client) && IsLegitimateClient(target) && GetClientTeam(target) == TEAM_SURVIVOR && PlayerLevel[target] < AfxLevelReq) return;

	new Float:SourcLoc[3];
	new Float:TargetPosition[3];
	new t_Strength = 0;
	new Float:t_Range = 0.0;

	if (target > 0) {

		if (IsLegitimateClient(target)) GetClientAbsOrigin(target, SourcLoc);
		else GetEntPropVector(target, Prop_Send, "m_vecOrigin", SourcLoc);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", TargetPosition);

		if (AfxRange > 0.0 && IsLegitimateClientAlive(target)) t_Range = AfxRange * (PlayerLevel[target] - AfxLevelReq);
		else t_Range = AfxRangeMax;
		if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
		else t_Range += AfxRangeBase;

		if (IsLegitimateClientAlive(target) && GetClientTeam(target) == TEAM_SURVIVOR && target != client) {

			if (PlayerLevel[target] < AfxLevelReq) return;
			if (GetVectorDistance(SourcLoc, TargetPosition) > (t_Range / 2)) return;
		}

		new NumLivingEntities = 0;
		new rawStrength = 0;
		new abilityStrength = 0;
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

		for (new i = 1; i <= MaxClients; i++) {

			if (!IsLegitimateClientAlive(i) || PlayerLevel[i] < AfxLevelReq) continue;
			GetClientAbsOrigin(i, TargetPosition);

			if (AfxRange > 0.0) t_Range = AfxRange * (PlayerLevel[i] - AfxLevelReq);
			else t_Range = AfxRangeMax;
			if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
			else t_Range += AfxRangeBase;
			if (GetVectorDistance(SourcLoc, TargetPosition) > (t_Range / 2) || StrContains(clientStatusEffectDisplay[i], "[Fl]", false) != -1) continue;		// player not within blast radius, takes no damage. Or playing is floating.

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
			if (abilityStrength > 0) SetClientTotalHealth(i, abilityStrength);

			if (client == target) {

				// To prevent a never-ending chain reaction, we don't allow it to target the bomber that caused it.

				if (GetClientTeam(i) == TEAM_SURVIVOR && AfxChain == 1) CreateBomberExplosion(client, i, Effects);
			}
		}
		if (StrContains(Effects, "e", true) != -1 || StrContains(Effects, "x", true) != -1) {

			CreateExplosion(target);	// boom boom audio and effect on the location.
			if (IsLegitimateClientAlive(target) && !IsFakeClient(target)) ScreenShake(target);
		}
		if (StrContains(Effects, "B", true) != -1) {

			if (IsLegitimateClientAlive(target) && !ISBILED[target]) {

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
		/*if (client == target) {

			for (new i = 0; i < GetArraySize(Handle:CommonInfected); i++) {

				ent = GetArrayCell(Handle:CommonInfected, i);
				if (IsCommonInfected(ent)) {

					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TargetPosition);
					if (GetVectorDistance(SourcLoc, TargetPosition) <= (t_Range / 2)) {

						CreateBomberExplosion(client, ent, Effects);
					}
				}
			}
			CreateBomberExplosion(client, 0, Effects);
		}*/
	}
	/*else {

		GetEntPropVector(client, Prop_Send, "m_vecOrigin", SourcLoc);

		

		//	The bomber target is 0, so we eliminate any common infected within range.
		//	Don't worry - this function will have called and executed for all players in range before it gets here
		//	thanks to the magic of single-threaded language.
		
		ent = -1;
		for (new i = 0; i < GetArraySize(Handle:CommonInfected); i++) {

			ent = GetArrayCell(Handle:CommonInfected, i);

			if (IsCommonInfected(ent)) {

				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TargetPosition);
				if (GetVectorDistance(SourcLoc, TargetPosition) <= (AfxRangeMax / 2)) {

					//AcceptEntityInput(ent, "Kill");
					
					//ent = FindListPositionByEntity(ent, Handle:CommonInfected);
					//if (ent >= 0) RemoveFromArray(Handle:CommonInfected, ent);
					//CalculateInfectedDamageAward(ent);
					if ((StrContains(Effects, "e", true) != -1 || StrContains(Effects, "x", true) != -1) && !IsSpecialCommon(ent)) {

						OnCommonInfectedCreated(ent, true);
						if (i > 0) i--;
					}
					//if (StrContains(Effects, "B", true) != -1) SDKCall(g_hCallVomitOnPlayer, ent, client, true);
				}
			}
		}
	}*/
}

stock CheckMinimumRate(client) {

	if (Rating[client] < 0) Rating[client] = 0;
}

stock CalculateInfectedDamageAward(client, killerblow = 0, entityPos = -1) {

	if (!IsCommonInfected(client) && IsLegitimateClient(killerblow) && GetClientTeam(killerblow) == TEAM_SURVIVOR) {
		if (isQuickscopeKill(killerblow)) {
			// If the user met the server operators standards for a quickscope kill, we do something.
			GetAbilityStrengthByTrigger(killerblow, client, "quickscope");
		}
	}

	new ClientType = -1;
	if (IsLegitimateClient(client) && GetClientTeam(client) == TEAM_INFECTED) {

		ClientType = 0;
		ReadyUp_NtvStatistics(killerblow, 6, 1);
		if (FindZombieClass(client) != ZOMBIECLASS_TANK) SetArrayCell(Handle:RoundStatistics, 3, GetArrayCell(RoundStatistics, 3) + 1);
		else SetArrayCell(Handle:RoundStatistics, 4, GetArrayCell(RoundStatistics, 4) + 1);
	}
	else if (IsWitch(client)) {

		ClientType = 1;
		SetArrayCell(Handle:RoundStatistics, 2, GetArrayCell(RoundStatistics, 2) + 1);
	}
	else if (IsSpecialCommon(client)) {
		ReadyUp_NtvStatistics(killerblow, 2, 1);
		ClientType = 2;
		SetArrayCell(Handle:RoundStatistics, 1, GetArrayCell(RoundStatistics, 1) + 1);
	}

	CreateItemRoll(client, killerblow);	// all infected types can generate an item roll

	new Float:SurvivorPoints = 0.0;
	new SurvivorExperience = 0;
	new Float:PointsMultiplier = fPointsMultiplier;
	new Float:ExperienceMultiplier = SurvivorExperienceMult;
	new Float:TankingMultiplier = SurvivorExperienceMultTank;
	new Float:HealingMultiplier = SurvivorExperienceMultHeal;
	//new Float:RatingReductionMult = 0.0;
	new t_Contribution = 0;
	new h_Contribution = 0;
	new SurvivorDamage = 0;

	new Float:TheAbilityMultiplier = 0.0;

	if (IsLegitimateClientAlive(killerblow) && ClientType == 0 && GetClientTeam(killerblow) == TEAM_SURVIVOR) {

		TheAbilityMultiplier = GetAbilityMultiplier(killerblow, "I");
		if (TheAbilityMultiplier > 0.0) { // heal because you dealt the killing blow

			HealPlayer(killerblow, killerblow, TheAbilityMultiplier * GetMaximumHealth(killerblow), 'h', true);
		}
		TheAbilityMultiplier = GetAbilityMultiplier(killerblow, "l");
		if (TheAbilityMultiplier > 0.0) {

			// Creates fire on the target and deals AOE explosion.
			CreateExplosion(client, RoundToCeil(DataScreenWeaponDamage(killerblow) * TheAbilityMultiplier), killerblow, true);
			CreateFireEx(client);
		}
	}
	//new owner = 0;
	//if (IsLegitimateClientAlive(commonkiller) && GetClientTeam(commonkiller) == TEAM_SURVIVOR) owner = commonkiller;
	if (ClientType == 0) SpecialsKilled++;
	new Float:i_DamageContribution = 0.0000;

	// If it's a special common, we activate its death abilities.
	if (ClientType == 2) {

		decl String:TheEffect[10];
		GetCommonValue(TheEffect, sizeof(TheEffect), client, "aura effect?");
		CreateBomberExplosion(client, client, TheEffect);	// bomber aoe
	}

	new pos = -1;
	new RatingBonus = 0;
	new RatingTeamBonus = 0;
	new iLivingSurvivors = LivingSurvivors() - 1;
	//decl String:MyName[64];
	decl String:killerName[64];
	decl String:killedName[64];
	if (IsWitch(client) || IsSpecialCommon(client) || IsLegitimateClient(client)) {
		if (IsLegitimateClient(client)) GetClientName(client, killedName, sizeof(killedName));
		else {
			if (IsWitch(client)) Format(killedName, sizeof(killedName), "Witch");
			else {
				GetCommonValue(killedName, sizeof(killedName), client, "name?");
				Format(killedName, sizeof(killedName), "Common %s", killedName);
			}
		}
		if (IsLegitimateClient(killerblow)) {
			GetClientName(killerblow, killerName, sizeof(killerName));
			PrintToChatAll("%t", "player killed special infected", blue, killerName, white, orange, killedName);
		}
		else {
			PrintToChatAll("%t", "killed special infected", orange, killedName, white);
		}
	}
	decl String:ratingBonusText[64];
	decl String:ratingTeamBonusText[64];
	for (new i = 1; i <= MaxClients; i++) {

		RatingBonus = 0;
		SurvivorExperience = 0;
		SurvivorPoints = 0.0;
		i_DamageContribution = 0.0000;

		if (!IsLegitimateClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;

		if (ClientType == 0) pos = FindListPositionByEntity(client, Handle:InfectedHealth[i]);
		else if (ClientType == 1) pos = FindListPositionByEntity(client, Handle:WitchDamage[i]);
		else if (ClientType == 2) pos = FindListPositionByEntity(client, Handle:SpecialCommon[i]);

		if (pos < 0) continue;

		if (LastAttackedUser[i] == client) LastAttackedUser[i] = -1;

		if (ClientType == 0) SurvivorDamage = GetArrayCell(Handle:InfectedHealth[i], pos, 2);
		else if (ClientType == 1) SurvivorDamage = GetArrayCell(Handle:WitchDamage[i], pos, 2);
		else if (ClientType == 2) SurvivorDamage = GetArrayCell(Handle:SpecialCommon[i], pos, 2);

		RatingBonus = GetRatingReward(i, client);

		if (RatingBonus > 0) {

			if (!IsFakeClient(i) && (IsSpecialCommon(client) || !IsCommonInfected(client))) {
				AddCommasToString(RatingBonus, ratingBonusText, sizeof(ratingBonusText));
				if (iLivingSurvivors <= iTeamRatingRequired) {
					PrintToChat(i, "%T", "rating increase", i, white, blue, ratingBonusText, orange);
				}
				else {
					AddCommasToString(RatingTeamBonus, ratingTeamBonusText, sizeof(ratingTeamBonusText));
					RatingTeamBonus = RoundToCeil(RatingBonus * ((iLivingSurvivors - iTeamRatingRequired) * fTeamRatingBonus));
					Rating[i] += RatingTeamBonus;
					PrintToChat(i, "%T", "team rating increase", i, white, blue, ratingBonusText, orange, white, green, blue, ratingTeamBonusText, orange, white);
				}
			}
			CheckMinimumRate(i);
			Rating[i] += RatingBonus;

			TheAbilityMultiplier = GetAbilityMultiplier(i, "R");
			if (TheAbilityMultiplier > 0.0) { // heal because you dealt the killing blow

				HealPlayer(i, i, TheAbilityMultiplier * RatingBonus, 'h', true);
			}
		}

		if (SurvivorDamage > 0) {

			SurvivorExperience = RoundToFloor(SurvivorDamage * ExperienceMultiplier);
			SurvivorPoints = SurvivorDamage * PointsMultiplier;
		}

		i_DamageContribution = CheckTeammateDamages(client, i, true);

		if (i_DamageContribution > 0.0) {

			SurvivorExperience = RoundToFloor(SurvivorDamage * ExperienceMultiplier);
			SurvivorPoints = SurvivorDamage * PointsMultiplier;
		}

		t_Contribution = CheckTankingDamage(client, i);
		if (t_Contribution > 0) {

			t_Contribution = RoundToCeil(t_Contribution * TankingMultiplier);
			SurvivorPoints += (t_Contribution * (PointsMultiplier * TankingMultiplier));
		}
		//h_Contribution = HealingContribution[i];
		//HealingContribution[i] = 0;
		//CreateLootItem(i, i_DamageContribution, CheckTankingDamage(client, i), RoundToCeil(h_Contribution * HealingMultiplier));
		if (h_Contribution > 0) {

			h_Contribution = RoundToCeil(h_Contribution * HealingMultiplier);
			SurvivorPoints += (h_Contribution * (PointsMultiplier * HealingMultiplier));
		}
		//if (!bIsInCombat[i]) ReceiveInfectedDamageAward(i, client, SurvivorExperience, SurvivorPoints, t_Contribution, h_Contribution, Bu_Contribution, He_Contribution);
		
		
		HealingContribution[i] += h_Contribution;
		TankingContribution[i] += t_Contribution;
		PointsContribution[i] += SurvivorPoints;
		DamageContribution[i] += SurvivorExperience;
		
		if (ClientType == 0) RemoveFromArray(Handle:InfectedHealth[i], pos);
		else if (ClientType == 1) RemoveFromArray(Handle:WitchDamage[i], pos);
		else if (ClientType == 2) RemoveFromArray(Handle:SpecialCommon[i], pos);
	}
	if (IsWitch(client)) {
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		AcceptEntityInput(client, "Kill");
		if (entityPos >= 0) RemoveFromArray(Handle:WitchList, entityPos);		// Delete the witch. Forever.
	}
	if (IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_INFECTED) {

		if (FindZombieClass(client) == ZOMBIECLASS_TANK) bIsDefenderTank[client] = false;

		if (iTankRush != 1 && FindZombieClass(client) == ZOMBIECLASS_TANK && DirectorTankCooldown > 0.0 && f_TankCooldown == -1.0) {

			f_TankCooldown				=	DirectorTankCooldown;

			CreateTimer(1.0, Timer_TankCooldown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		ClearArray(TankState_Array[client]);
		MyBirthday[client] = 0;
		CreateMyHealthPool(client, true);
		ChangeHook(client);
		ForcePlayerSuicide(client);

		if (b_IsFinaleActive && GetInfectedCount(ZOMBIECLASS_TANK) < 1) {

			b_IsFinaleTanks = true;	// next time the event tank spawns, it will allow it to spawn multiple tanks.
		}
	}
}

stock ReceiveInfectedDamageAward(client, infected, e_reward, Float:p_reward, t_reward, h_reward , bu_reward, he_reward, bool:TheRoundHasEnded = false) {

	new RPGMode									= iRPGMode;

	if (RPGMode < 0) return;
	//new RPGBroadcast							= StringToInt(GetConfigValue("award broadcast?"));
	decl String:InfectedName[64];
	//decl String:InfectedTeam[64];

	if (infected > 0) {

		if (IsLegitimateClient(infected)) GetClientName(infected, InfectedName, sizeof(InfectedName));
		else if (IsWitch(infected)) Format(InfectedName, sizeof(InfectedName), "Witch");
		else if (IsSpecialCommon(infected)) GetCommonValue(InfectedName, sizeof(InfectedName), infected, "name?");
		else if (IsCommonInfected(infected)) Format(InfectedName, sizeof(InfectedName), "Common");
		Format(InfectedName, sizeof(InfectedName), "%s %s", sDirectorTeam, InfectedName);
	}

	new Float:fRoundMultiplier = 1.0;
	if (RoundExperienceMultiplier[client] > 0.0) {

		fRoundMultiplier += RoundExperienceMultiplier[client];
		e_reward = RoundToCeil(e_reward * fRoundMultiplier);
		h_reward += RoundToCeil(h_reward * fRoundMultiplier);
		t_reward += RoundToCeil(t_reward * fRoundMultiplier);
		bu_reward += RoundToCeil(bu_reward * fRoundMultiplier);
		he_reward += RoundToCeil(he_reward * fRoundMultiplier);
	}

	new RestedAwardBonus = RoundToFloor(e_reward * fRestedExpMult);
	if (RestedAwardBonus >= RestedExperience[client]) {

		RestedAwardBonus = RestedExperience[client];
		RestedExperience[client] = 0;
	}
	else if (RestedAwardBonus < RestedExperience[client]) {

		RestedExperience[client] -= RestedAwardBonus;
	}
	new ExperienceBooster = RoundToFloor(e_reward * CheckExperienceBooster(client, e_reward));
	if (ExperienceBooster < 1) ExperienceBooster = 0;

	//new Float:TeammateBonus = 0.0;//(LivingSurvivors() - 1) * fSurvivorExpMult;
	new theCount = LivingSurvivorCount();
	if (theCount >= iSurvivorModifierRequired) {

		new Float:TeammateBonus = (theCount - (iSurvivorModifierRequired - 1)) * fSurvivorExpMult;
	
		e_reward += RoundToCeil(TeammateBonus * e_reward);
		h_reward += RoundToCeil(TeammateBonus * h_reward);
		t_reward += RoundToCeil(TeammateBonus * t_reward);
		bu_reward += RoundToCeil(TeammateBonus * bu_reward);
		he_reward += RoundToCeil(TeammateBonus * he_reward);
	}

	if (IsGroupMember[client]) {

		e_reward += RoundToCeil(GroupMemberBonus * e_reward);
		h_reward += RoundToCeil(GroupMemberBonus * h_reward);
		t_reward += RoundToCeil(GroupMemberBonus * t_reward);
		bu_reward += RoundToCeil(GroupMemberBonus * bu_reward);
		he_reward += RoundToCeil(GroupMemberBonus * he_reward);
	}
	if (!BotsOnSurvivorTeam() && TotalHumanSurvivors() <= iSurvivorBotsBonusLimit) {
		e_reward += RoundToCeil(fSurvivorBotsNoneBonus * e_reward);
		h_reward += RoundToCeil(fSurvivorBotsNoneBonus * h_reward);
		t_reward += RoundToCeil(fSurvivorBotsNoneBonus * t_reward);
		bu_reward += RoundToCeil(fSurvivorBotsNoneBonus * bu_reward);
		he_reward += RoundToCeil(fSurvivorBotsNoneBonus * he_reward);
	}

	if (e_reward < 1) e_reward = 0;
	if (h_reward < 1) h_reward = 0;
	if (t_reward < 1) t_reward = 0;
	if (bu_reward < 1) bu_reward = 0;
	if (he_reward < 1) he_reward = 0;

	//h_reward = RoundToCeil(GetClassMultiplier(client, h_reward * 1.0, "hXP"));
	//t_reward = RoundToCeil(GetClassMultiplier(client, t_reward * 1.0, "tXP"));

	//if (!TheRoundHasEnded) {
	// Previously, if a player completed a round without ever leaving combat, they would receive no bonus container.

	if (iIsLevelingPaused[client] == 0) {
		// players who pause their levels don't earn bonus containers.

		BonusContainer[client]	+= e_reward;
		BonusContainer[client]	+= h_reward;
		BonusContainer[client]	+= t_reward;
		BonusContainer[client]	+= bu_reward;
		BonusContainer[client]	+= he_reward;
	}
	else BonusContainer[client] = 0;	// if the player enables it mid-match, this ensures the bonus container is always 0 for paused levelers.
	//}

	
	//	0 = Points Only
	//	1 = RPG Only
	//	2 - RPG + Points
	
	if (RPGMode > 0) {

		if (DisplayType > 0 && (infected == 0 || (IsSpecialCommon(infected) || IsWitch(infected) || IsLegitimateClient(infected)))) {								// \x04Jockey \x01killed: \x04 \x03experience

			decl String:rewardText[64];
			if (e_reward > 0) {
				AddCommasToString(e_reward, rewardText, sizeof(rewardText));
				if (infected > 0) PrintToChat(client, "%T", "base experience reward", client, orange, InfectedName, white, green, rewardText, blue);
				else if (infected == 0) PrintToChat(client, "%T", "damage experience reward", client, orange, green, white, green, rewardText, blue);
			}
			if (DisplayType == 2) {

				if (RestedAwardBonus > 0) {
					AddCommasToString(RestedAwardBonus, rewardText, sizeof(rewardText));
					PrintToChat(client, "%T", "rested experience reward", client, green, white, green, rewardText, blue);
				}
				if (ExperienceBooster > 0) {
					AddCommasToString(ExperienceBooster, rewardText, sizeof(rewardText));
					PrintToChat(client, "%T", "booster experience reward", client, green, white, green, rewardText, blue);
				}
			}
			if (t_reward > 0) {
				AddCommasToString(t_reward, rewardText, sizeof(rewardText));
				PrintToChat(client, "%T", "tanking experience reward", client, green, white, green, rewardText, blue);
			}
			if (h_reward > 0) {
				AddCommasToString(h_reward, rewardText, sizeof(rewardText));
				PrintToChat(client, "%T", "healing experience reward", client, green, white, green, rewardText, blue);
			}
			if (bu_reward > 0) {
				AddCommasToString(bu_reward, rewardText, sizeof(rewardText));
				PrintToChat(client, "%T", "buffing experience reward", client, green, white, green, rewardText, blue);
			}
			if (he_reward > 0) {
				AddCommasToString(he_reward, rewardText, sizeof(rewardText));
				PrintToChat(client, "%T", "hexing experience reward", client, green, white, green, rewardText, blue);
			}
		}
		new TotalExperienceEarned = (e_reward + RestedAwardBonus + ExperienceBooster + t_reward + h_reward + bu_reward + he_reward);

 		ExperienceLevel[client] += TotalExperienceEarned;
		ExperienceOverall[client] += TotalExperienceEarned;
		//GetProficiencyData(client, GetWeaponProficiencyType(client), TotalExperienceEarned);

		ConfirmExperienceAction(client, TheRoundHasEnded);
	}
	if (RPGMode >= 0 && RPGMode != 1 && p_reward > 0.0) {

		Points[client] += p_reward;

		if (DisplayType > 0 && (infected == 0 || (IsSpecialCommon(infected) || IsWitch(infected) || IsLegitimateClient(infected)))) PrintToChat(client, "%T", "points from damage reward", client, green, white, green, p_reward, blue);
	}
	if (!TheRoundHasEnded) CheckKillPositions(client, true);
}

// Curious RPG System option?
// Points earned from hurting players used to unlock abilities, while experienced earned to increase level determines which abilities a player has access to.
// This way, even if the level is different, everyone starts with the same footing.
// Optional RPG System. Maybe call it "buy rpg mode?"

stock bool:SameTeam_OnTakeDamage(healer, target, iHealerAmount, bool:IsDamageTalent = false, damagetype = -1) {
	if (!AllowShotgunToTriggerNodes(healer)) return false;
	if (HealImmunity[target]) return true;
	new bool:TheBool = IsMeleeAttacker(healer);
	if (TheBool && bIsMeleeCooldown[healer]) return true;
	//https://pastebin.com/tLLK9kZM
	if (!TheBool) {
		iHealerAmount = RoundToCeil(GetAbilityStrengthByTrigger(healer, target, "hB", _, iHealerAmount, _, _, "d", 2, true));
		iHealerAmount += RoundToCeil(GetAbilityStrengthByTrigger(healer, target, "hB", _, iHealerAmount, _, _, "healshot", 2, true));
	}
	else {
		iHealerAmount = RoundToCeil(GetAbilityStrengthByTrigger(healer, target, "hM", _, iHealerAmount, _, _, "d", 2, true));
		iHealerAmount += RoundToCeil(GetAbilityStrengthByTrigger(healer, target, "hM", _, iHealerAmount, _, _, "healmelee", 2, true));
	}
	if (iHealerAmount < 1) return true;
	if (iHealingPlayerInCombatPutInCombat == 1 && bIsInCombat[target]) {
		CombatTime[healer] = GetEngineTime() + fOutOfCombatTime;
		bIsInCombat[healer] = true;
	}
	if (TheBool) {
		bIsMeleeCooldown[healer] = true;				
		CreateTimer(0.5, Timer_IsMeleeCooldown, healer, TIMER_FLAG_NO_MAPCHANGE);
	}
	HealImmunity[target] = true;
	CreateTimer(0.05, Timer_HealImmunity, target, TIMER_FLAG_NO_MAPCHANGE);
	HealPlayer(target, healer, iHealerAmount * 1.0, 'h', true);
	GetAbilityStrengthByTrigger(healer, target, "didHeals", _, iHealerAmount);
	GetAbilityStrengthByTrigger(target, healer, "wasHealed", _, iHealerAmount);
	// To prevent endless loops, we only call damage talents when the function is called directly from OnTakeDamage()
	if (IsDamageTalent) {
		GetAbilityStrengthByTrigger(healer, target, "d", FindZombieClass(healer), iHealerAmount);
		if (damagetype & DMG_CLUB) GetAbilityStrengthByTrigger(healer, target, "U", _, iHealerAmount);
		if (damagetype & DMG_SLASH) GetAbilityStrengthByTrigger(healer, target, "u", _, iHealerAmount);
	}
	if (LastAttackedUser[healer] == target) ConsecutiveHits[healer]++;
	else {
		LastAttackedUser[healer] = target;
		ConsecutiveHits[healer] = 0;
	}
	return true;
}