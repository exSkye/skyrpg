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
	//CallKeys							= GetArrayCell(a_Events, pos, 0);
	CallValues							= GetArrayCell(a_Events, pos, 1);
	decl String:ThePerp[64];
	GetArrayString(CallValues, EVENT_PERPETRATOR, ThePerp, sizeof(ThePerp));
	new attacker = GetClientOfUserId(GetEventInt(event, ThePerp));
	GetArrayString(CallValues, EVENT_VICTIM, ThePerp, sizeof(ThePerp));
	new victim = GetClientOfUserId(GetEventInt(event, ThePerp));
	new bool:IsLegitimateClientAttacker = IsLegitimateClient(attacker);
	new attackerTeam = -1;
	new attackerZombieClass = -1;
	new bool:IsFakeClientAttacker = false;
	if (IsLegitimateClientAttacker) {
		attackerTeam = GetClientTeam(attacker);
		IsFakeClientAttacker = IsFakeClient(attacker);
		attackerZombieClass = FindZombieClass(attacker);
	}
	new victimType = -1;
	new victimTeam = -1;
	//new bool:IsFakeClientVictim = false;
	if (IsCommonInfected(victim)) victimType = 0;
	else if (IsWitch(victim)) victimType = 1;
	else if (IsLegitimateClient(victim)) {
		victimType = 2;
		victimTeam = GetClientTeam(victim);
		//IsFakeClientVictim = IsFakeClient(victim);
	}
	if (IsLegitimateClientAttacker) {
		if (victimType != -1) {
			if (victimType == 1 && FindListPositionByEntity(victim, Handle:WitchList) < 0) OnWitchCreated(victim);
			// These calls are specific to special infected and survivor events - does not handle common infected, super infected, or witches.
			// Talents/Nodes can be triggered when specific events occur.
			// They can be special calls, so that it looks for specific case-sens strings instead of characters.
			if (((victimType == 0 || victimType == 1) && attackerTeam == TEAM_SURVIVOR) ||
				victimType == 2 && (!IsLegitimateClientAttacker || attackerTeam != victimTeam || GetKeyValueIntAtPos(CallValues, EVENT_SAMETEAM_TRIGGER) == 1)) {
				decl String:abilityTriggerActivator[64];
				decl String:abilityTriggerTarget[64];
				GetArrayString(CallValues, EVENT_PERPETRATOR_TEAM_REQ, abilityTriggerActivator, sizeof(abilityTriggerActivator));
				if (!StrEqual(abilityTriggerActivator, "-1")) {
					Format(ThePerp, sizeof(ThePerp), "%d", attackerTeam);
					if (StrContains(abilityTriggerActivator, ThePerp) != -1) {
						GetArrayString(CallValues, EVENT_PERPETRATOR_ABILITY_TRIGGER, abilityTriggerActivator, sizeof(abilityTriggerActivator));
						if (!StrEqual(abilityTriggerActivator, "-1")) GetAbilityStrengthByTrigger(attacker, victim, abilityTriggerActivator);
					}
				}
				GetArrayString(CallValues, EVENT_VICTIM_TEAM_REQ, abilityTriggerTarget, sizeof(abilityTriggerTarget));
				if (!StrEqual(abilityTriggerTarget, "-1")) {
					Format(ThePerp, sizeof(ThePerp), "%d", victimTeam);
					if (StrContains(abilityTriggerTarget, ThePerp) != -1) {
						GetArrayString(CallValues, EVENT_VICTIM_ABILITY_TRIGGER, abilityTriggerTarget, sizeof(abilityTriggerTarget));
						if (!StrEqual(abilityTriggerTarget, "-1")) GetAbilityStrengthByTrigger(victim, attacker, abilityTriggerTarget);
					}
				}
			}
		}
		if (StrEqual(event_name, "ammo_pickup")) {
			GiveAmmoBack(attacker, 999);	// whenever a player picks up an ammo pile, we want to give them their full ammo reserves - vanilla + talents.
		}
		// if ((StrEqual(event_name, "player_shoved") || StrEqual(event_name, "entity_shoved")) && attackerTeam == TEAM_SURVIVOR) {
		// 	if (!IsInfectedTarget(victim)) {
		// 		SetEntProp(attacker, Prop_Send, "m_iShovePenalty", 0);
		// 		SetEntPropFloat(attacker, Prop_Send, "m_flNextShoveTime", 1.0);
		// 	}
		// 	else if (SurvivorStamina[attacker] > 0) {
		// 		SurvivorStamina[attacker] -= iShoveStaminaCost;
		// 		if (SurvivorStamina[attacker] <= 0) {
		// 			SurvivorStamina[attacker] = 0;
		// 			bIsSurvivorFatigue[attacker] = true;
		// 			SetEntProp(attacker, Prop_Send, "m_iShovePenalty", 10);
		// 			SetEntPropFloat(attacker, Prop_Send, "m_flNextShoveTime", 30.0);
		// 		}
		// 		else {
		// 			SetEntProp(attacker, Prop_Send, "m_iShovePenalty", 0);
		// 			SetEntPropFloat(attacker, Prop_Send, "m_flNextShoveTime", 1.0);
		// 		}
		// 	}
		// }
	}
	decl String:weapon[64];
	if (StrEqual(event_name, "player_left_start_area") && IsLegitimateClientAttacker) {
		if (attackerTeam == TEAM_SURVIVOR) {
			//if (IsFakeClientAttacker && attackerTeam == TEAM_SURVIVOR && !b_IsLoaded[attacker]) IsClientLoadedEx(attacker);
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
	if (b_IsActiveRound && IsLegitimateClientAttacker) {
		decl String:messageToSendToClient[MAX_CHAT_LENGTH];
		if (StrEqual(event_name, "player_entered_checkpoint")) {
			if (!IsFakeClient(attacker) && !bIsInCheckpoint[attacker]) {
				Format(messageToSendToClient, sizeof(messageToSendToClient), "{B} Your damage/experience is {O}DISABLED {B}while in the safe room.");
				Client_PrintToChat(attacker, true, messageToSendToClient);
			}
			bIsInCheckpoint[attacker] = true;
		}
		if (StrEqual(event_name, "player_left_checkpoint")) {
			if (!IsFakeClient(attacker) && bIsInCheckpoint[attacker]) {
				Format(messageToSendToClient, sizeof(messageToSendToClient), "{B}You have left the safe area. {O}Your damage/experience is {B}ENABLED.");
				Client_PrintToChat(attacker, true, messageToSendToClient);
			}
			bIsInCheckpoint[attacker] = false;
		}
	}
	if (StrEqual(event_name, "player_spawn")) {
		if (IsLegitimateClientAttacker) {
			ClearArray(Handle:ActiveStatuses[attacker]);
			if (attackerTeam == TEAM_SURVIVOR) {
				ChangeHook(attacker, true);
				RefreshSurvivor(attacker);
				RaidInfectedBotLimit();
			}
			else {
				SetInfectedHealth(attacker, 99999);
				if (!IsFakeClientAttacker) PlayerSpawnAbilityTrigger(attacker);
				DamageContribution[attacker] = 0;
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
						CreateMyHealthPool(attacker);
					}
					if (attackerZombieClass == ZOMBIECLASS_TANK) {
						ClearArray(TankState_Array[attacker]);
						bHasTeleported[attacker] = false;
						if (iTanksPreset == 1) {
							new iRand = GetRandomInt(1, 3);
							if (iRand == 1) ChangeTankState(attacker, "hulk");
							else if (iRand == 2) ChangeTankState(attacker, "death");
							else if (iRand == 3) ChangeTankState(attacker, "burn");
						}
					}
					InitInfectedHealthForSurvivors(attacker);
				}
			}
		}
	}
	if (!b_IsActiveRound || IsLegitimateClientAttacker && attackerTeam == TEAM_SURVIVOR && !b_IsLoaded[attacker]) return 0;		// don't track ANYTHING when it's not an active round.
	decl String:curEquippedWeapon[64];
	if (StrEqual(event_name, "weapon_reload") || StrEqual(event_name, "bullet_impact")) {
		new WeaponId =	GetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon");
		GetEntityClassname(WeaponId, curEquippedWeapon, sizeof(curEquippedWeapon));
	}
	if (victimTeam == TEAM_SURVIVOR) {
		if (StrEqual(event_name, "revive_success")) {
			if (attacker != victim) {
				GetAbilityStrengthByTrigger(victim, attacker, "R", _, 0);
				GetAbilityStrengthByTrigger(attacker, victim, "r", _, 0);
			}
			SetEntPropEnt(victim, Prop_Send, "m_reviveOwner", -1);
			SetEntPropEnt(attacker, Prop_Send, "m_reviveTarget", -1);
			new reviveOwner = GetEntPropEnt(victim, Prop_Send, "m_reviveOwner");
			if (IsLegitimateClient(reviveOwner)) SetEntPropEnt(reviveOwner, Prop_Send, "m_reviveTarget", -1);
			GiveMaximumHealth(victim);
		}
	}
	GetArrayString(CallValues, EVENT_DAMAGE_TYPE, ThePerp, sizeof(ThePerp));
	new damagetype = GetEventInt(event, ThePerp);
	if (StrEqual(event_name, "finale_radio_start") && !b_IsFinaleActive) {
		// When the finale is active, players can earn experience whilst camping (not moving from a spot, re: farming)
		b_IsFinaleActive = true;
		if (GetInfectedCount(ZOMBIECLASS_TANK) < 1) b_IsFinaleTanks = true;
		if (iTankRush == 1) {
			PrintToChatAll("%t", "the zombies are coming", blue, orange, blue);
			ExecCheatCommand(FindAnyRandomClient(), "director_force_panic_event");
		}
	}
	if (StrEqual(event_name, "finale_vehicle_ready")) {
		// When the vehicle arrives, the finale is no longer active, but no experience can be earned. This stops farming.
		if (b_IsFinaleActive) {
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
	GetArrayString(CallValues, EVENT_GET_HEALTH, ThePerp, sizeof(ThePerp));
	new healthvalue = GetEventInt(event, ThePerp);
	new isdamageaward = GetKeyValueIntAtPos(CallValues, EVENT_DAMAGE_AWARD);
	GetArrayString(CallValues, EVENT_GET_ABILITIES, abilities, sizeof(abilities));
	new tagability = GetKeyValueIntAtPos(CallValues, EVENT_IS_PLAYER_NOW_IT);
	new originvalue = GetKeyValueIntAtPos(CallValues, EVENT_IS_ORIGIN);
	new distancevalue = GetKeyValueIntAtPos(CallValues, EVENT_IS_DISTANCE);
	new Float:multiplierpts = GetKeyValueFloatAtPos(CallValues, EVENT_MULTIPLIER_POINTS);
	new Float:multiplierexp = GetKeyValueFloatAtPos(CallValues, EVENT_MULTIPLIER_EXPERIENCE);
	new isshoved = GetKeyValueIntAtPos(CallValues, EVENT_IS_SHOVED);
	new bulletimpact = GetKeyValueIntAtPos(CallValues, EVENT_IS_BULLET_IMPACT);
	new isinsaferoom = GetKeyValueIntAtPos(CallValues, EVENT_ENTERED_SAFEROOM);
	if (bulletimpact == 1) {
		if (attackerTeam == TEAM_SURVIVOR) {
			new bulletsFired = 0;
			GetTrieValue(currentEquippedWeapon[attacker], curEquippedWeapon, bulletsFired);
			SetTrieValue(currentEquippedWeapon[attacker], curEquippedWeapon, bulletsFired + 1);
			new Float:Coords[3];
			Coords[0] = GetEventFloat(event, "x");
			Coords[1] = GetEventFloat(event, "y");
			Coords[2] = GetEventFloat(event, "z");
			//new Float:TargetPos[3];
			//new target = GetAimTargetPosition(attacker, TargetPos);
			//if (AllowShotgunToTriggerNodes(attacker)) LastWeaponDamage[attacker] = GetBaseWeaponDamage(attacker, target, Coords[0], Coords[1], Coords[2], damagetype);
			//LastWeaponDamage[attacker] = GetBaseWeaponDamage(attacker, target, Coords[0], Coords[1], Coords[2], damagetype);	// expensive way
			// better way because events fire after ontakedamage, so lastBaseDamage[attacker] IS the above methods most-recent result.
			LastWeaponDamage[attacker] = lastBaseDamage[attacker];
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
		if (IsLegitimateClientAttacker) {
			CheckIfHeadshot(attacker, victim, event, healthvalue);
			CheckIfLimbDamage(attacker, victim, event, healthvalue);
			/*if (IsPlayerUsingShotgun(attacker)) {
				if (shotgunCooldown[attacker]) return 0;
				shotgunCooldown[attacker] = true;
				CreateTimer(0.1, Timer_ResetShotgunCooldown, attacker, TIMER_FLAG_NO_MAPCHANGE);
			}*/
		}
		if (victimType == 2 && !b_IsHooked[victim]) ChangeHook(victim, true);
		//if (IsLegitimateClientAlive(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && !b_IsHooked[victim]) ChangeHook(victim, true);
		//if (IsLegitimateClientAttacker && IsFakeClientAttacker && attackerTeam == TEAM_SURVIVOR && !b_IsLoaded[attacker]) IsClientLoadedEx(attacker);
		//if (victimTeam == TEAM_SURVIVOR && IsFakeClientVictim && !b_IsLoaded[victim]) IsClientLoadedEx(victim);
	}
	if (victimTeam == TEAM_INFECTED) {
		SetEntityHealth(victim, 400000);
	}
	if (tagability == 1 && victimType == 2) {
		if (!ISBILED[victim]) CreateTimer(15.0, Timer_RemoveBileStatus, victim, TIMER_FLAG_NO_MAPCHANGE);
		ISBILED[victim] = true;
	}
	if (tagability == 2 && IsLegitimateClientAttacker) ISBILED[attacker] = false;
	if (isdamageaward == 1) {
		if (IsLegitimateClientAttacker && victimType == 2 && attackerTeam == victimTeam) {
			if (!(damagetype & DMG_BURN) && !StrEqual(weapon, "inferno")) {
				// damage-based triggers now only occur under the circumstances in the code above. No longer do we have triggers for same-team damaging. Maybe at a later date, but it will not be the same ability trigger.
				GetAbilityStrengthByTrigger(attacker, victim, "d", _, healthvalue);
				GetAbilityStrengthByTrigger(victim, attacker, "l", _, healthvalue);
			}
			else ReadyUp_NtvFriendlyFire(attacker, victim, healthvalue, GetClientHealth(victim), 1, 0);
		}
		if (victimType == 2 && victimTeam == TEAM_INFECTED) SetEntityHealth(victim, 40000);
		if (IsLegitimateClientAttacker && attackerTeam == TEAM_SURVIVOR && isinsaferoom == 1) bIsInCheckpoint[attacker] = true;
	}
	if (isshoved == 1 && victimType == 2 && IsLegitimateClientAttacker && victimTeam != attackerTeam) {
		if (victimTeam == TEAM_INFECTED) SetEntityHealth(victim, GetClientHealth(victim) + healthvalue);
		GetAbilityStrengthByTrigger(victim, attacker, "H", _, 0);
	}
	if (isshoved == 2 && IsLegitimateClientAttacker && victimType == 0 && !IsCommonStaggered(victim)) {
		new staggeredSize = GetArraySize(StaggeredTargets);
		ResizeArray(StaggeredTargets, staggeredSize + 1);
		SetArrayCell(StaggeredTargets, staggeredSize, victim, 0);
		SetArrayCell(StaggeredTargets, staggeredSize, 2.0, 1);
	}
	if (StrEqual(event_name, "weapon_reload")) {
		if (IsLegitimateClientAttacker && attackerTeam == TEAM_SURVIVOR) {
			ConsecutiveHits[attacker] = 0;	// resets on reload.
			RemoveFromTrie(currentEquippedWeapon[attacker], curEquippedWeapon);
		}
	}
	if (StrEqual(event_name, "player_spawn") && IsLegitimateClientAttacker && attackerTeam == TEAM_INFECTED) {
		if (IsFakeClientAttacker) {
			new changeClassId = 0;
			if (iSpecialsAllowed == 0 && attackerZombieClass != ZOMBIECLASS_TANK) {
				ForcePlayerSuicide(attacker);
			}
			if (iSpecialsAllowed == 1 && !StrEqual(sSpecialsAllowed, "-1")) {
				decl String:myClass[5];
				Format(myClass, sizeof(myClass), "%d", attackerZombieClass);
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
			new requiredTankCount = GetAlwaysTanks(iSurvivors);
			if (attackerZombieClass == ZOMBIECLASS_TANK) {
				if (b_IsFinaleActive && b_IsFinaleTanks) {
					b_IsFinaleTanks = false;
					for (new i = 0; i + iTankCount < iTankLimit
					; i++) {
						ExecCheatCommand(theClient, "z_spawn_old", "tank auto");
					}
				}
				/*else {
					if (iTankCount > iTankLimit || f_TankCooldown != -1.0) {

						//PrintToChatAll("killing tank.");
						//ForcePlayerSuicide(attacker);
					}
				}*/
			}
			if (iNoSpecials == 1 || iTankRush == 1) {
				if (attackerZombieClass != ZOMBIECLASS_TANK) {
					//if (!IsEnrageActive())
					ForcePlayerSuicide(attacker);
					if (iSurvivors >= 1 && (iTankCount < requiredTankCount || !b_IsFinaleActive && iTankCount < iTankLimit)) {
						ExecCheatCommand(theClient, "z_spawn_old", "tank auto");
					}
				}
			}
			else if (iEnsnareRestrictions == 1 && attackerZombieClass != ZOMBIECLASS_TANK) {
				new iEnsnaredCount = EnsnaredInfected();
				new livingSurvivors = LivingHumanSurvivors();
				new ensnareBonus = (livingSurvivors > 1) ? livingSurvivors - 1 : 0;
				if (IsEnsnarer(attacker)) {
					if (iInfectedLimit == -2 && iEnsnaredCount > RaidCommonBoost(_, true) + ensnareBonus ||
					iInfectedLimit == -1 ||
					iInfectedLimit == 0 && iEnsnaredCount > livingSurvivors ||
					iInfectedLimit > 0 && iEnsnaredCount > iInfectedLimit ||
					iIsLifelink > 1 && iLivSurvs < iIsLifelink && iLivSurvs < iMinSurvivors) {
						while (IsEnsnarer(attacker, changeClassId)) {
							changeClassId = GetRandomInt(1,6);
						}
						ChangeInfectedClass(attacker, changeClassId);
					}
					else ChangeInfectedClass(attacker, _, true);	// doesn't change class but sets base health and speeds.
				}
				else ChangeInfectedClass(attacker, _, true);
			}
			else ChangeInfectedClass(attacker, _, true);
		}
		else SetSpecialInfectedHealth(attacker, attackerZombieClass);
	}
	if (StrEqual(event_name, "ability_use")) {
		if (attackerTeam == TEAM_INFECTED) {
			GetAbilityStrengthByTrigger(attacker, victim, "infected_abilityuse");
			GetEventString(event, "ability", AbilityUsed, sizeof(AbilityUsed));
			if (StrContains(AbilityUsed, "ability_throw") != -1) {
				if (!(GetEntityFlags(attacker) & FL_ONFIRE) && !SurvivorsInRange(attacker, 1024.0)) ChangeTankState(attacker, "burn");
				else {
					ChangeTankState(attacker, "hulk");
					if (!SurvivorsInRange(attacker, fForceTankJumpRange)) ForceClientJump(attacker, fForceTankJumpHeight);
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
	if (IsLegitimateClientAttacker && attackerTeam == TEAM_INFECTED) {
		new Float:Distance = 0.0;
		new Float:fTalentStrength = 0.0;
		if (originvalue > 0 || distancevalue > 0) {
			if (originvalue == 1 || distancevalue == 1) {
				GetClientAbsOrigin(attacker, Float:f_OriginStart[attacker]);
				if (attackerZombieClass != ZOMBIECLASS_HUNTER &&
					attackerZombieClass != ZOMBIECLASS_SPITTER) {
					fTalentStrength = GetAbilityStrengthByTrigger(attacker, _, "Q", _, 0);
				}
				if (attackerZombieClass == ZOMBIECLASS_HUNTER) {
					// check for any abilities that are based on abilityused.
					GetClientAbsOrigin(attacker, Float:f_OriginStart[attacker]);
					//GetAbilityStrengthByTrigger(attacker, 0, 'A', FindZombieClass(attacker), healthvalue);
					GetAbilityStrengthByTrigger(attacker, _, "A", _, healthvalue);
				}
				if (attackerZombieClass == ZOMBIECLASS_CHARGER) {
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
				if (victimType == 2 && victimTeam == TEAM_SURVIVOR) {
					Distance = GetVectorDistance(f_OriginStart[attacker], f_OriginEnd[attacker]);
					if (fTalentStrength > 0.0) Distance += (Distance * fTalentStrength);
					//SetClientTotalHealth(victim, RoundToCeil(Distance), _, true);
				}
			}
			if (attackerZombieClass == ZOMBIECLASS_JOCKEY || (distancevalue == 2 && t_Distance[attacker] > 0)) {
				if (distancevalue == 1) t_Distance[attacker] = GetTime();
				if (distancevalue == 2) {
					t_Distance[attacker] = GetTime() - t_Distance[attacker];
					multiplierexp *= t_Distance[attacker];
					multiplierpts *= t_Distance[attacker];
					t_Distance[attacker] = 0;
				}
			}
			else {
				if (distancevalue == 3 && victimType == 2) GetClientAbsOrigin(victim, Float:f_OriginStart[attacker]);
				if (distancevalue == 2 || originvalue == 2 || distancevalue == 4 && victimType == 2) {
					if (distancevalue == 4) GetClientAbsOrigin(victim, Float:f_OriginEnd[attacker]);
					//new Float:Distance = GetVectorDistance(f_OriginStart[attacker], f_OriginEnd[attacker]);
					multiplierexp *= Distance;
					multiplierpts *= Distance;
				}
			}
			if (originvalue == 2 || distancevalue == 2 || distancevalue == 4) {
				if (iRPGMode >= 1 && multiplierexp > 0.0 && (iExperienceLevelCap < 1 || PlayerLevel[attacker] < iExperienceLevelCap)) {
					ExperienceLevel[attacker] += RoundToCeil(multiplierexp);
					ExperienceOverall[attacker] += RoundToCeil(multiplierexp);
					ConfirmExperienceAction(attacker);
					if (iAwardBroadcast > 0 && !IsFakeClientAttacker) PrintToChat(attacker, "%T", "distance experience", attacker, white, green, RoundToCeil(multiplierexp), white);
				}
				if (iRPGMode != 1 && multiplierpts > 0.0) {

					Points[attacker] += multiplierpts;
					if (iAwardBroadcast > 0 && !IsFakeClientAttacker) PrintToChat(attacker, "%T", "distance points", attacker, white, green, multiplierpts, white);
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
	if (GetArraySize(SpecialAmmoData) < 1) return 0.0;
	new Float:EntityPos[3];
	decl String:TalentInfo[4][512];
	new owner = 0;
	new pos = -1;
	//decl String:newvalue[10];

	decl String:value[10];
	//new Float:f_Strength = 0.0;
	//decl String:t_effect[4];

	new Float:EffectStrength = 0.0;
	new Float:EffectStrengthBonus = 0.0;
	// new bool:IsInfected = false;
	// new bool:IsSameteam = false;

	new Float:ClientPos[3];
	new bool:clientIsLegitimate = IsLegitimateClient(client);
	//decl String:EffectT[4];
	if (!clientIsLegitimate || !IsPlayerAlive(client)) return EffectStrength;
	if (clientIsLegitimate) GetClientAbsOrigin(client, ClientPos);
	else {
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
		//IsInfected = true;
	}
	// new experienceAwardType = (StrEqual(EffectT, "H", true)) ? 1 : (StrEqual(EffectT, "d", true) ||
	// 						StrEqual(EffectT, "D", true) ||
	// 						StrEqual(EffectT, "R", true) ||
	// 						StrEqual(EffectT, "E", true) ||
	// 						StrEqual(EffectT, "W", true) ||
	// 						StrEqual(EffectT, "a", true)) ? 2 : 0;
	// new otherExperienceAwardType = (StrEqual(EffectT, "F", true) || StrEqual(EffectT, "W", true) || StrEqual(EffectT, "x", true)) ? 1 :	(StrEqual(EffectT, "F", true) || StrEqual(EffectT, "x", true)) ? 2 : 0;

	new Float:EffectStrengthValue = 0.0;
	new Float:EffectMultiplierValue = 0.0;

	new Float:t_Range	= 0.0;
	//new Float:fAmmoRangeTalentBonus = GetAbilityStrengthByTrigger(client, client, "aamRNG", FindZombieClass(client), 0, _, _, "d", 1, true);	// true at the end makes sure we don't actually fire off the ability or really check the "d" (resulteffects) here
	//if (fAmmoRangeTalentBonus < 1.0) fAmmoRangeTalentBonus = 1.0;

	//Format(EffectT, sizeof(EffectT), "%c", effect);
	for (new i = AmmoPosition; i < GetArraySize(SpecialAmmoData); i++) {
		if (i < 0) i = 0;
		if (AmmoPosition != -1 && i != AmmoPosition) continue;
		// TalentInfo[0] = TalentName of ammo.
		// TalentInfo[1] = Talent Strength (so use StringToInt)
		// TalentInfo[2] = Talent Damage
		// TalentInfo[3] = Talent Interval
		owner = FindClientByIdNumber(GetArrayCell(SpecialAmmoData, i, 7));
		if (!IsLegitimateClient(owner)) continue;// || GetArrayCell(SpecialAmmoData, i, 8) <= 0.0) continue;
		pos			= GetArrayCell(SpecialAmmoData, i, 3);
		IsClientInRangeSAValues[owner]				= GetArrayCell(a_Menu_Talents, pos, 1);
		GetArrayString(IsClientInRangeSAValues[owner], SPELL_AMMO_EFFECT, value, sizeof(value));
		if (!StrEqual(value, EffectT, true)) continue;	// if this ammo isn't the ammo type we're checking, skip.
		
		GetTalentNameAtMenuPosition(owner, pos, TalentInfo[0], sizeof(TalentInfo[]));
		if (IsPvP[owner] != 0 && client != owner) continue;

		t_Range		= GetSpecialAmmoStrength(owner, TalentInfo[0], 3);
		EntityPos[0] = GetArrayCell(SpecialAmmoData, i, 0);
		EntityPos[1] = GetArrayCell(SpecialAmmoData, i, 1);
		EntityPos[2] = GetArrayCell(SpecialAmmoData, i, 2);
		if (GetVectorDistance(ClientPos, EntityPos) > (t_Range / 2)) continue;
		if (GetStatusOnly) {
			return -2.0;		// -2.0 is a special designation.
		}

		if (realowner == 0 || realowner == owner) {

			EffectStrengthValue = GetKeyValueFloatAtPos(IsClientInRangeSAValues[owner], SPECIAL_AMMO_TALENT_STRENGTH);
			EffectMultiplierValue = GetKeyValueFloatAtPos(IsClientInRangeSAValues[owner], SPELL_EFFECT_MULTIPLIER);

			if (EffectStrength == 0.0) EffectStrength = EffectStrengthValue;
			else EffectStrengthBonus += EffectMultiplierValue;

			// if (baseeffectvalue > 0.0 && owner != client) {

			// 	/*

			// 		Award the user who has buffed a player.
			// 	*/

			// 	if (!IsInfected && GetClientTeam(client) == GetClientTeam(owner)) IsSameteam = true;





			// 	baseeffectbonus = RoundToCeil(baseeffectvalue + (baseeffectvalue * EffectStrengthValue));
			// 	baseeffectbonus += RoundToCeil(baseeffectbonus * SurvivorExperienceMult);
			// 	if (baseeffectbonus > 0) {

			// 		if (IsSameteam) {
			// 			if (experienceAwardType > 0) AwardExperience(owner, experienceAwardType, baseeffectbonus);
			// 			/*if (StrEqual(EffectT, "H", true)) AwardExperience(owner, 1, baseeffectbonus);
			// 			if (StrEqual(EffectT, "d", true) ||
			// 				StrEqual(EffectT, "D", true) ||
			// 				StrEqual(EffectT, "R", true) ||
			// 				StrEqual(EffectT, "E", true) ||
			// 				StrEqual(EffectT, "W", true) ||
			// 				StrEqual(EffectT, "a", true)) AwardExperience(owner, 2, baseeffectbonus);*/
			// 		}
			// 		else {

			// 			if (otherExperienceAwardType == 1 && clientIsLegitimate ||
			// 				otherExperienceAwardType == 2 && IsInfected) AwardExperience(owner, 3, baseeffectbonus);
			// 		}
			// 	}
			// }
		}
		if (AmmoPosition != -1) break;
	}
	if (EffectStrengthBonus > 0.0) EffectStrength += (EffectStrength * EffectStrengthBonus);
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

	new Float:SpellCooldown = GetAbilityValue(client, TalentName, ABILITY_COOLDOWN);
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
	new myAttacker = L4D2_GetInfectedAttacker(client);
	if (GetKeyValueIntAtPos(Values, ABILITY_REQ_NO_ENSNARE) == 1 && myAttacker != -1) return false;

	new Float:ClientPos[3];
	GetClientAbsOrigin(client, ClientPos);

	new MySecondary = GetPlayerWeaponSlot(client, 1);
	decl String:MyWeapon[64];

	decl String:Effects[64];
	new Float:SpellCooldown = GetSpellCooldown(client, TalentName);

	//new MyAttacker = L4D2_GetInfectedAttacker(client);
	new MyStamina = GetPlayerStamina(client);
	new MyBonus = 0;
	//new MyMaxHealth = GetMaximumHealth(client);
	if (iSkyLevelMax > 0) {
		new iSkyLevelRequirement = GetKeyValueIntAtPos(Values, ABILITY_SKY_LEVEL_REQ);
		if (iSkyLevelRequirement < 0) iSkyLevelRequirement = 0;

		if (SkyLevel[client] < iSkyLevelRequirement) return false;
	}
	GetArrayString(Values, ABILITY_TOGGLE_EFFECT, Effects, sizeof(Effects));
	if (!StrEqual(Effects, "-1")) {
		if (StrEqual(Effects, "stagger", true)) {
			if (myAttacker == -1 || IsIncapacitated(client)) return false;	// knife cannot trigger if you are not a victim.
			ReleasePlayer(client);
			//EmitSoundToClient(client, "player/heartbeatloop.wav");
			//StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
		}
		else if (StrEqual(Effects, "r", true)) {

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
		else if (StrEqual(Effects, "P", true)) {
			// Toggles between pistol / magnum
			if (IsValidEntity(MySecondary)) {
				GetEntityClassname(MySecondary, MyWeapon, sizeof(MyWeapon));
				RemovePlayerItem(client, MySecondary);
				AcceptEntityInput(MySecondary, "Kill");
			}
			if (StrContains(MyWeapon, "magnum", false) == -1 && StrContains(MyWeapon, "pistol", false) != -1) {

				// give them a magnum.
				ExecCheatCommand(client, "give", "pistol_magnum");
			}
			else {

				// make them dual wield.
				ExecCheatCommand(client, "give", "pistol");
				CreateTimer(0.5, Timer_GiveSecondPistol, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else if (StrEqual(Effects, "T", true)) {
			GetClientStance(client, GetAmmoCooldownTime(client, TalentName, true));
		}
	}
	/*if (StrContains(Effects, "S", true) != -1) {
		StaggerPlayer(client, client);
	}*/
	GetArrayString(Values, ABILITY_ACTIVE_EFFECT, Effects, sizeof(Effects));
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
	if (GetKeyValueIntAtPos(Values, ABILITY_IS_REACTIVE) == 2) {	// instant, one-time-use abilities that have a cast-bar and then fire immediately.
		if (GetAbilityMultiplier(client, Effects, 5) == -2.0) {
			new reactiveType = GetKeyValueIntAtPos(Values, ABILITY_REACTIVE_TYPE);
			if (reactiveType == 1) StaggerPlayer(client, GetAnyPlayerNotMe(client));
			else if (reactiveType == 2) {
				new Float:fActiveTime = GetKeyValueFloatAtPos(Values, ABILITY_ACTIVE_TIME);
				CreateProgressBar(client, fActiveTime);
				new Handle:datapack;
				CreateDataTimer(fActiveTime, Timer_ReactiveCast, datapack, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(datapack, client);
				WritePackCell(datapack, RoundToCeil(GetMaximumHealth(client) * GetKeyValueFloatAtPos(Values, ABILITY_ACTIVE_STRENGTH)));
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

	new bulletStrength = GetBaseWeaponDamage(client, target, TargetPos[0], TargetPos[1], TargetPos[2], DMG_BULLET);
	//bulletStrength = RoundToCeil(GetAbilityStrengthByTrigger(client, -2, "D", _, bulletStrength, _, _, "d", 1, true, _, _, _, DMG_BULLET));
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
	// only captures the #ID: STEAM_0:1:<--cuts off the front, only stores the numbers: 440606022 - is faster than parsing a string every time.
	SetArrayCell(SpecialAmmoData, sadsize, StringToInt(key[10]), 7);
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
	new bool:IsLegitimateClientVictim = IsLegitimateClientAlive(victim);
	if (IsLegitimateClientVictim) {
		bIsBurnCooldown[victim] = true;
		CreateTimer(1.0, Timer_ResetBurnImmunity, victim, TIMER_FLAG_NO_MAPCHANGE);
	}
 	new hAttacker = attacker;
 	if (!IsLegitimateClient(hAttacker)) hAttacker = -1;
	new bool:IsCommonInfectedVictim = IsCommonInfected(victim);
 	if (IsCommonInfectedVictim || IsWitch(victim) && !(GetEntityFlags(victim) & FL_ONFIRE)) {
		if (IsCommonInfectedVictim) {
			if (!IsSpecialCommon(victim)) OnCommonInfectedCreated(victim, true);
			else AddSpecialCommonDamage(attacker, victim, baseWeaponDamage, true);
		}
		else {
			IgniteEntity(victim, 10.0);
			AddWitchDamage(attacker, victim, baseWeaponDamage, true);
		}
	}
 	if (IsLegitimateClientVictim && GetClientStatusEffect(victim, "burn") < iDebuffLimit) {
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
	if (iRPGMode <= 0) return -1;
	new CurrentPos	= GetMenuPosition(client, TalentName);
	new bool:i_IsDebugMode = false;
	DrawSpecialAmmoValues[client]	= GetArrayCell(a_Menu_Talents, CurrentPos, 1);
	if (CurrentPosEx == -1) {
		new bool:IsTargetCommonInfected = IsCommonInfected(Target);
		new bool:IsLegitimateClientTarget = IsLegitimateClientAlive(Target);
		new targetTeam = -1;
		if (IsLegitimateClientTarget) targetTeam = GetClientTeam(Target);
		if (GetKeyValueIntAtPos(DrawSpecialAmmoValues[client], SPELL_HUMANOID_ONLY) == 1) {
			//Humanoid Only could apply to a wide-range so we break it down here.
			if (!IsTargetCommonInfected && !IsLegitimateClientTarget) i_IsDebugMode = true;
		}
		if (GetKeyValueIntAtPos(DrawSpecialAmmoValues[client], SPELL_INANIMATE_ONLY) == 1) {
			//This is things like vehicles, dumpsters, and other objects that can one-shot your teammates.
			if (IsTargetCommonInfected || IsLegitimateClientTarget) i_IsDebugMode = true;
		}
		if (GetKeyValueIntAtPos(DrawSpecialAmmoValues[client], SPELL_ALLOW_COMMONS) == 0 && IsTargetCommonInfected ||
		GetKeyValueIntAtPos(DrawSpecialAmmoValues[client], SPELL_ALLOW_SPECIALS) == 0 && IsLegitimateClientTarget && targetTeam == TEAM_INFECTED ||
		GetKeyValueIntAtPos(DrawSpecialAmmoValues[client], SPELL_ALLOW_SURVIVORS) == 0 && IsLegitimateClientTarget && targetTeam == TEAM_SURVIVOR) {
			i_IsDebugMode = true;
		}
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
	new drawpos = TALENT_FIRST_RANDOM_KEY_POSITION;
	new drawcolor = TALENT_FIRST_RANDOM_KEY_POSITION;
	DrawSpecialAmmoKeys[client]		= GetArrayCell(a_Menu_Talents, CurrentPos, 0);
	while (drawpos >= 0 && drawcolor >= 0) {
		drawpos = FormatKeyValue(AfxDrawPos, sizeof(AfxDrawPos), DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "draw pos?", _, _, drawpos, false);
		drawcolor = FormatKeyValue(AfxDrawColour, sizeof(AfxDrawColour), DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "draw colour?", _, _, drawcolor, false);
		if (drawpos < 0 || drawcolor < 0) return -1;
		//if (StrEqual(AfxDrawColour, "-1", false)) return -1;		// if there's no colour, we return otherwise you'll get errors like this: TE_Send Exception reported: No TempEntity call is in progress (return 0 here would cause endless loop set to -1 as it is ignored i broke the golden rule lul)
		if (CurrentPosEx != -1) {
			CreateRingSoloEx(-1, AfxRange, AfxDrawColour, AfxDrawPos, false, f_ActiveTime, TargetClient, PosX, PosY, PosZ);
		}
		else {

			CreateRingSoloEx(Target, AfxRange, AfxDrawColour, AfxDrawPos, false, HighlightTime, TargetClient);
			IsSpecialAmmoEnabled[client][3] = Target * 1.0;
		}
		drawpos++;
		drawcolor++;
	}
	return 2;
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

bool:AllLivingSurvivorsInCheckpoint() {
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClientAlive(i)) continue;
		if (GetClientTeam(i) != TEAM_SURVIVOR) continue;
		if (!bIsInCheckpoint[i]) return false;
	}
	return true;
}

public Action:OnPlayerRunCmd(client, &buttons) {
	new clientFlags = GetEntityFlags(client);
	new clientTeam = GetClientTeam(client);
	new bool:clientIsSurvivor = (clientTeam == TEAM_SURVIVOR) ? true : false;
	new bool:IsClientIncapacitated = IsIncapacitated(client);
	new bool:IsClientAlive = IsLegitimateClientAlive(client);
	new bool:IsBiledOn = ISBILED[client];
	new Float:TheTime = GetEngineTime();
	new MyAttacker = L4D2_GetInfectedAttacker(client);
	new bool:IsHoldingPrimaryFire = (buttons & IN_ATTACK) ? true : false;
	new bool:isClientOnSolidGround = (clientFlags & FL_ONGROUND) ? true : false;
	new bool:isClientOnFire = (clientFlags & FL_ONFIRE) ? true : false;
	new bool:isClientInWater = (clientFlags & FL_INWATER) ? true : false;
	new weaponEntity = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	new bool:weaponIsValid = IsValidEntity(weaponEntity);
	// call the stagger ability triggers only when a fresh stagger occurs (and not if multiple staggers happen too-often within each other (2.0 seconds is slightly-longer than one stagger.))
	if (!staggerCooldownOnTriggers[client] && SDKCall(g_hIsStaggering, client)) {
		staggerCooldownOnTriggers[client] = true;
		CreateTimer(2.0, Timer_ResetStaggerCooldownOnTriggers, client, TIMER_FLAG_NO_MAPCHANGE);
		EntityWasStaggered(client);
	}
	if (clientIsSurvivor) {
		if (isClientOnFire && (isClientInWater || IsBiledOn)) {
			RemoveAllDebuffs(client, "burn");
			ExtinguishEntity(client);
		}
		if (isClientInWater && GetClientStatusEffect(client, "acid") > 0) {
			RemoveAllDebuffs(client, "acid");
		}
	}
	if ((buttons & IN_ZOOM) && ZoomcheckDelayer[client] == INVALID_HANDLE) ZoomcheckDelayer[client] = CreateTimer(0.1, Timer_ZoomcheckDelayer, client, TIMER_FLAG_NO_MAPCHANGE);
	if (IsHoldingPrimaryFire) {
		new bulletsRemaining = 0;
		if (IsValidEntity(weaponEntity)) {
			bulletsRemaining = GetEntProp(weaponEntity, Prop_Send, "m_iClip1");
			if (bulletsRemaining == LastBulletCheck[client]) bulletsRemaining = 0;
			else LastBulletCheck[client] = bulletsRemaining;
		}
		if (bulletsRemaining > 0 && GetEntProp(weaponEntity, Prop_Data, "m_bInReload") != 1 && MyAttacker == -1) {
			holdingFireCheckToggle(client, true);
		}
	}
	else holdingFireCheckToggle(client);
	new bool:isHoldingUseKey = (buttons & IN_USE) ? true : false;
	if (isHoldingUseKey) {
			// if (b_IsActiveRound && ReadyUpGameMode != 3) {
			// 	if (StrContains(EName, "checkpoint", false) != -1) {
			// 		entity = GetEntProp(entity, Prop_Send, "m_eDoorState");
			// 		PrintToChat(client, "entity door state is %d", entity);
			// 		buttons &= ~IN_USE;
			// 		return Plugin_Changed;
			// 	}
			// }
		if (b_IsRoundIsOver && (ReadyUpGameMode == 3 || StrContains(TheCurrentMap, "zerowarn", false) != -1)) {
			decl String:EName[64];
			new entity = GetClientAimTarget(client, false);
			if (entity != -1) {
				GetEntityClassname(entity, EName, sizeof(EName));
				if (StrContains(EName, "weapon", false) != -1 || StrContains(EName, "physics", false) != -1) return Plugin_Continue;
				buttons &= ~IN_USE;
				return Plugin_Changed;
			}
		}
	}
	if (IsClientAlive && b_IsActiveRound) {
		if (clientTeam == TEAM_INFECTED && FindZombieClass(client) == ZOMBIECLASS_TANK) {
			if (!IsAirborne[client] && !isClientOnSolidGround) IsAirborne[client] = true;	// when the tank lands, aoe explosion!
			else if (IsAirborne[client] && isClientOnSolidGround) {
				IsAirborne[client] = false;	// the tank has landed; explosion;
				CreateExplosion(client, _, client, true);
			}
			new myLifetime = GetTime() - MyBirthday[client];
			if (MyBirthday[client] > 0) {
				new numSurvivorsNear = NearbySurvivors(client, 2056.0);
				//if there are no nearby survivors (tank spawned ahead or people are rushing)
				if (numSurvivorsNear < 1) {
					// if we've been around for a while, kill the tank
					if (myLifetime > 120) DeleteMeFromExistence(client);
					else SetSpeedMultiplierBase(client, 2.0);	// otherwise make him super fast so he can catch the survivors.
				}	// but if survivors are nearby, reset the tanks speed based on his current mutation.
				else CheckTankSubroutine(client);
			}
		}

		/*if (clientTeam == TEAM_SURVIVOR) {

			//CheckIfItemPickup(client);
			//CheckBombs(client);
			if (IsFakeClient(client) && !bIsInCheckpoint[client]) {

				if (SurvivorsSaferoomWaiting()) SurvivorBotsRegroup(client);
			}
		}*/
		new bool:isClientHoldingJump = (buttons & IN_JUMP) ? true : false;
		if (isClientHoldingJump) bJumpTime[client] = true;
		else {

			bJumpTime[client] = false;
			JumpTime[client] = 0.0;
		}
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
		// if (clientTeam == TEAM_SURVIVOR) {
		// 	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", MovementSpeed[client]);
		// }
		if (ISDAZED[client] > TheTime) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue") * fDazedDebuffEffect);
		else if (ISDAZED[client] <= TheTime && ISDAZED[client] != 0.0) {
			BlindPlayer(client, _, 0);	// wipe the dazed effect.
			ISDAZED[client] = 0.0;
		}
		if (clientIsSurvivor) {
			decl String:EntityName[64];
			if (weaponIsValid) GetEdictClassname(weaponEntity, EntityName, sizeof(EntityName));
			new bool:theClientHasAnActiveProgressBar = ActiveProgressBar(client);
			new bool:theClientHasPainPills = (!weaponIsValid || StrContains(EntityName, "pain_pills", false) == -1) ? false : true;
			new bool:theClientHasAdrenaline = (!weaponIsValid || StrContains(EntityName, "adrenaline", false) == -1) ? false : true;
			new bool:theClientHasFirstAid = (!weaponIsValid || StrContains(EntityName, "first_aid", false) == -1) ? false : true;
			new bool:theClientHasDefib = (!weaponIsValid || StrContains(EntityName, "defib", false) == -1) ? false : true;
			//new CurrentEntity			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

			//Format(EntityName, sizeof(EntityName), "}");
			if (weaponIsValid) {
				if (StrContains(EntityName, "chainsaw", false) != -1 && (buttons & IN_RELOAD) && GetEntProp(weaponEntity, Prop_Data, "m_iClip1") < 10) {
					SetEntProp(weaponEntity, Prop_Data, "m_iClip1", 30);
					buttons &= ~IN_RELOAD;
				}
				if (theClientHasAnActiveProgressBar &&
					weaponEntity != ProgressEntity[client] ||
					(!isClientOnSolidGround && !IsClientIncapacitated) ||
					MyAttacker != -1 ||
					!weaponIsValid && !IsClientIncapacitated ||
					!theClientHasPainPills && !theClientHasAdrenaline && !theClientHasFirstAid && !theClientHasDefib && !IsClientIncapacitated) {
					CreateProgressBar(client, 0.0, true);
					UseItemTime[client] = 0.0;
					theClientHasAnActiveProgressBar = false;
					if (GetEntPropEnt(client, Prop_Send, "m_reviveOwner") == client) {
						SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
						SetEntPropEnt(client, Prop_Send, "m_reviveTarget", -1);
					}
				}
			}
			new PlayerMaxStamina = GetPlayerStamina(client);

			if (MyAttacker == -1 && (IsClientIncapacitated || (weaponIsValid && (theClientHasPainPills || theClientHasAdrenaline || theClientHasFirstAid || theClientHasDefib)))) {

				//blocks the use of meds on people. will add an option in the menu later for now allowing.
				/*if ((buttons & IN_ATTACK2) && !IsIncapacitated(client)) {

					if (StrContains(EntityName, "first_aid", false) != -1) {

						buttons &= ~IN_ATTACK2;
						return Plugin_Changed;
					}
				}*/
				new reviveOwner = -1;
				if ((!IsHoldingPrimaryFire && theClientHasAnActiveProgressBar && !IsClientIncapacitated) || (!isHoldingUseKey && theClientHasAnActiveProgressBar && IsClientIncapacitated)) {

					CreateProgressBar(client, 0.0, true);
					UseItemTime[client] = 0.0;
					theClientHasAnActiveProgressBar = false;
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
				if ((IsHoldingPrimaryFire && !IsClientIncapacitated) || (isHoldingUseKey && IsClientIncapacitated)) {
					if (!IsClientIncapacitated) buttons &= ~IN_ATTACK;
					else buttons &= ~IN_USE;
					if (UseItemTime[client] < TheTime) {
						if (theClientHasAnActiveProgressBar) {
							UseItemTime[client] = 0.0;
							CreateProgressBar(client, 0.0, true);
							if (!IsClientIncapacitated) {
								if (theClientHasPainPills) {
									HealPlayer(client, client, GetTempHealth(client) + (GetMaximumHealth(client) * 0.3), 'h', true);//SetTempHealth(client, client, GetTempHealth(client) + (GetMaximumHealth(client) * 0.3), false);		// pills add 10% of your total health in temporary health.
									AcceptEntityInput(weaponEntity, "Kill");
								}
								else if (theClientHasAdrenaline) {
									SetAdrenalineState(client);
									new StaminaBonus = RoundToCeil(PlayerMaxStamina * 0.25);
									if (SurvivorStamina[client] + StaminaBonus >= PlayerMaxStamina) {
										SurvivorStamina[client] = PlayerMaxStamina;
										bIsSurvivorFatigue[client] = false;
									}
									else SurvivorStamina[client] += StaminaBonus;
									AcceptEntityInput(weaponEntity, "Kill");
								}
								else if (theClientHasDefib) {
									Defibrillator(client);
									AcceptEntityInput(weaponEntity, "Kill");
								}
								else if (theClientHasFirstAid) {
									GiveMaximumHealth(client);
									RefreshSurvivor(client);
									AcceptEntityInput(weaponEntity, "Kill");
								}
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
							if (IsClientIncapacitated && UseItemTime[client] < TheTime) {
								reviveOwner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
								if (!IsLegitimateClientAlive(reviveOwner)) {
									SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
									ProgressEntity[client]			=	weaponEntity;
									CreateProgressBar(client, 5.0);	// you can pick yourself up for free but it takes a bit.
								}
							}
							if (!IsClientIncapacitated && UseItemTime[client] < TheTime) {
								new Float:fProgressBarCompletionTime = -1.0;
								if (theClientHasPainPills) fProgressBarCompletionTime = 2.0;
								else if (theClientHasAdrenaline) fProgressBarCompletionTime = 1.0;
								else if (theClientHasFirstAid || theClientHasDefib) fProgressBarCompletionTime = 5.0;
								if (fProgressBarCompletionTime != -1.0) {
									ProgressEntity[client]			=	weaponEntity;
									CreateProgressBar(client, fProgressBarCompletionTime);
								}
							}
							if (theClientHasAnActiveProgressBar) SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
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
			if (clientIsSurvivor) {
				if ((ReadyUp_GetGameMode() != 3 || !b_IsSurvivalIntermission) && iRPGMode >= 1) {
					new bool:IsJetpackBroken = (isClientOnFire || IsBiledOn);
					if (!IsJetpackBroken) IsJetpackBroken = AnyTanksNearby(client);
					/*
						Add or remove conditions from the following line to determine when the jetpack automatically disables.
						When adding new conditions, consider a switch so server operators can choose which of them they want to use.
					*/
					if (bJetpack[client] && (iCanJetpackWhenInCombat == 1 || !bIsInCombat[client]) && (!isClientHoldingJump || IsJetpackBroken || MyAttacker != -1)) {
						ToggleJetpack(client, true);
					}
					if ((bJetpack[client] || !bJetpack[client] && !isClientOnSolidGround) || isClientHoldingJump &&
						SurvivorStamina[client] >= ConsumptionInt && !bIsSurvivorFatigue[client] && ISSLOW[client] == INVALID_HANDLE && ISFROZEN[client] == INVALID_HANDLE) {
						if (MyAttacker == -1 && ISSLOW[client] == INVALID_HANDLE && ISFROZEN[client] == INVALID_HANDLE) {
							if (SurvivorConsumptionTime[client] <= TheTime && isClientHoldingJump) {
								if (bJetpack[client]) {
									new Float:nextSprintInterval = GetAbilityStrengthByTrigger(client, client, "jetpack", _, 0, _, _, "flightcost", _, _, 2);
									if (nextSprintInterval > 0.0) SurvivorConsumptionTime[client] = TheTime + fStamSprintInterval + (fStamSprintInterval * nextSprintInterval);
									else SurvivorConsumptionTime[client] = TheTime + fStamSprintInterval;
								}
								else SurvivorConsumptionTime[client] = TheTime + fStamSprintInterval;
								if (!bIsSurvivorFatigue[client]) SurvivorStamina[client] -= ConsumptionInt;
								if (SurvivorStamina[client] <= 0) {
									bIsSurvivorFatigue[client] = true;
									IsSpecialAmmoEnabled[client][0] = 0.0;
									SurvivorStamina[client] = 0;
									if (bJetpack[client]) ToggleJetpack(client, true);
								}
							}
							if (!bIsSurvivorFatigue[client] && !bJetpack[client] && (isClientHoldingJump && (JumpTime[client] >= 0.2)) && (iCanJetpackWhenInCombat == 1 || !bIsInCombat[client]) && !IsJetpackBroken && JetpackRecoveryTime[client] <= GetEngineTime() && MyAttacker == -1) ToggleJetpack(client);
							if (!bJetpack[client]) MovementSpeed[client] = fSprintSpeed;
						}
						buttons &= ~IN_SPEED;
						return Plugin_Changed;
					}
					if (!bJetpack[client]) {
						if (SurvivorStaminaTime[client] < TheTime && SurvivorStamina[client] < PlayerMaxStamina) {
							if (!HasAdrenaline(client)) SurvivorStaminaTime[client] = TheTime + fStamRegenTime;
							else SurvivorStaminaTime[client] = TheTime + fStamRegenTimeAdren;
							SurvivorStamina[client]++;
						}
						// if (!bIsSurvivorFatigue[client]) MovementSpeed[client] = fBaseMovementSpeed;
						// else MovementSpeed[client] = fFatigueMovementSpeed;
						if (ISSLOW[client] != INVALID_HANDLE) MovementSpeed[client] *= fSlowSpeed[client];
						if (SurvivorStamina[client] >= PlayerMaxStamina) {
							bIsSurvivorFatigue[client] = false;
							SurvivorStamina[client] = PlayerMaxStamina;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

stock bool:AnyTanksInExistence() {
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i) || GetClientTeam(i) != TEAM_INFECTED) continue;
		if (FindZombieClass(i) == ZOMBIECLASS_TANK) return true;
	}
	return false;
}

stock bool:IsPlayerOnGroundOutsideOfTankZone(tank) {
	new Float:fTankPos[3], Float:fClientPos[3];
	GetClientAbsOrigin(tank, fTankPos);
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsLegitimateClient(i)) continue;	// only player clients allowed.
		if (GetClientTeam(i) != TEAM_SURVIVOR) continue;	// only survivors.
		if (!(GetEntityFlags(i) & FL_ONGROUND)) continue;	// only players with feet on the ground.
		GetClientAbsOrigin(i, fClientPos);
		if (HeightDifference(fClientPos[2], fTankPos[2]) >= fTeleportTankHeightDistance) {
			// teleport tank to survivor.
			TeleportEntity(tank, fClientPos, NULL_VECTOR, NULL_VECTOR);
			return true;
		}
	}
	return false;
}

stock Float:HeightDifference(Float:clientZ, Float:tankZ) {
	if (clientZ == tankZ) return 0.0;
	new Float:fDistance = clientZ - tankZ;
	if (fDistance < 0.0) fDistance *= 1.0;	// distance should not be able to reach negatives using this algorithm
	return fDistance;
}

stock ToggleJetpack(client, DisableJetpack = false) {

	new Float:ClientPos[3];
	GetClientAbsOrigin(client, ClientPos);
	if (!DisableJetpack && !bJetpack[client] && !AnyTanksInExistence()) {

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
	new Float:AfxRange = GetCommonValueFloatAtPos(client, SUPER_COMMON_RANGE_PLAYER_LEVEL);
	new Float:AfxStrengthLevel = GetCommonValueFloatAtPos(client, SUPER_COMMON_LEVEL_STRENGTH);
	new Float:AfxRangeMax = GetCommonValueFloatAtPos(client, SUPER_COMMON_RANGE_MAX);
	new AfxMultiplication = GetCommonValueIntAtPos(client, SUPER_COMMON_ENEMY_MULTIPLICATION);
	new AfxStrength = GetCommonValueIntAtPos(client, SUPER_COMMON_AURA_STRENGTH);
	new Float:AfxStrengthTarget = GetCommonValueFloatAtPos(client, SUPER_COMMON_STRENGTH_TARGET);
	new Float:AfxRangeBase = GetCommonValueFloatAtPos(client, SUPER_COMMON_RANGE_MIN);
	new Float:OnFireBase = GetCommonValueFloatAtPos(client, SUPER_COMMON_ONFIRE_BASE_TIME);
	new Float:OnFireLevel = GetCommonValueFloatAtPos(client, SUPER_COMMON_ONFIRE_LEVEL);
	new Float:OnFireMax = GetCommonValueFloatAtPos(client, SUPER_COMMON_ONFIRE_MAX_TIME);
	new Float:OnFireInterval = GetCommonValueFloatAtPos(client, SUPER_COMMON_ONFIRE_INTERVAL);
	new AfxLevelReq = GetCommonValueIntAtPos(client, SUPER_COMMON_LEVEL_REQ);
	new Float:ClientPosition[3];
	new Float:TargetPosition[3];
	new t_Strength = 0;
	new Float:t_Range = 0.0;
	new Float:t_OnFireRange = 0.0;
	if (damage > 0) {//AfxStrength = damage;	// if we want to base the damage on a specific value, we can override here.
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
				if (IsSpecialCommonInRange(client, 'b')) t_Strength *= 2;//t_Strength = GetSpecialCommonDamage(t_Strength, client, 'b', i);
				if (type == 0) CreateAndAttachFlame(i, t_Strength, t_OnFireRange, OnFireInterval, _, "burn");		// Static time for now.
				else if (type == 4) {
					CreateAndAttachFlame(i, t_Strength, t_OnFireRange, OnFireInterval, _, "acid");
					break;	// to prevent buffer overflow only allow it on one client.
				}
			}
		}
	}
	else CreateFireEx(client);
	//ClearSpecialCommon(client);
}

stock FindEntityInArrayBinarySearch(Handle:hArray, target) {
	new left = 0, right = GetArraySize(hArray);
	new middle;
	new ent;
	while (left < right) {
		middle = (left + right) / 2;
		ent = GetArrayCell(hArray, middle);
		if (ent == target) return middle;
		if (ent < target) left = middle + 1;
		else right = middle;
	}
	return -1;
}

// inserting entity into an arraylist in ascending order so it's compatible with binary search
stock InsertIntoArrayAscending(Handle:hArray, entity) {
	new size = GetArraySize(hArray);
	new left = 0, right = size;
	if (right < 1) {	// if the array is empty, just push.
		PushArrayCell(Handle:hArray, entity);
		return 0;
	}
	else if (right < 2) {	// another outlier check to prevent array oob.
		if (entity > GetArrayCell(hArray, 0)) {
			PushArrayCell(hArray, entity);
			return 1;
		}
		else {
			ResizeArray(hArray, size+1);
			ShiftArrayUp(hArray, size);
			SetArrayCell(hArray, size, entity);
			return 0;
		}
	}
	else {
		new middle = (left + right) / 2;
		new middleEnt = GetArrayCell(hArray, middle);
		new leftEnt = GetArrayCell(hArray, middle - 1);
		while (entity < leftEnt || entity > middleEnt) {
			middle = (left + right) / 2;
			middleEnt = GetArrayCell(hArray, middle);
			leftEnt = GetArrayCell(hArray, middle - 1);
			if (entity < leftEnt) right--;
			else if (entity > middleEnt) left++;
			else break;
		}
		ResizeArray(hArray, size+1);
		ShiftArrayUp(hArray, middle);	// middle is now undefined.
		SetArrayCell(hArray, middle, entity);	// place new entity in middle.
		return middle;
	}
}

stock FindListPositionByEntity(entity, Handle:h_SearchList, block = 0) {

	new size = GetArraySize(Handle:h_SearchList);
	if (size < 1) return -1;
	for (new i = 0; i < size; i++) {

		if (GetArrayCell(Handle:h_SearchList, i, block) == entity) return i;
	}
	return -1;	// returns false
}

stock FindCommonInfectedTargetInArray(Handle:hArray, target) {
	new size = GetArraySize(hArray);
	for (new i = 0; i < size; i++) {
		if (i >= size - 1 - i) break;
		if (GetArrayCell(hArray, i) == target) return i;
		if (GetArrayCell(hArray, size - 1 - i) == target) return size-1-i;
	}
	return -1;
}

stock ExplosiveAmmo(client, damage, TalentClient) {
	if (IsWitch(client)) AddWitchDamage(TalentClient, client, damage);
	else if (IsSpecialCommon(client)) AddSpecialCommonDamage(TalentClient, client, damage);
	else if (IsLegitimateClientAlive(client)) {
		if (GetClientTeam(client) == TEAM_INFECTED) AddSpecialInfectedDamage(TalentClient, client, damage);
		else SetClientTotalHealth(client, damage);	// survivor teammates don't reward players with experience or damage bonus, but they'll take damage from it.
	}
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
	new Float:AfxRange = GetCommonValueFloatAtPos(client, SUPER_COMMON_RANGE_PLAYER_LEVEL);
	new Float:AfxStrengthLevel = GetCommonValueFloatAtPos(client, SUPER_COMMON_LEVEL_STRENGTH);
	new Float:AfxRangeMax = GetCommonValueFloatAtPos(client, SUPER_COMMON_RANGE_MAX);
	new AfxMultiplication = GetCommonValueIntAtPos(client, SUPER_COMMON_ENEMY_MULTIPLICATION);
	new AfxStrength = GetCommonValueIntAtPos(client, SUPER_COMMON_AURA_STRENGTH);
	new AfxChain = GetCommonValueIntAtPos(client, SUPER_COMMON_CHAIN_REACTION);
	new Float:AfxStrengthTarget = GetCommonValueFloatAtPos(client, SUPER_COMMON_STRENGTH_TARGET);
	new Float:AfxRangeBase = GetCommonValueFloatAtPos(client, SUPER_COMMON_RANGE_MIN);
	new AfxLevelReq = GetCommonValueIntAtPos(client, SUPER_COMMON_LEVEL_REQ);
	new isRaw = GetCommonValueIntAtPos(client, SUPER_COMMON_RAW_STRENGTH);
	new rawCommon = GetCommonValueIntAtPos(client, SUPER_COMMON_RAW_COMMON_STRENGTH);
	new rawPlayer = GetCommonValueIntAtPos(client, SUPER_COMMON_RAW_PLAYER_STRENGTH);


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
	new bool:IsLegitimateClientClient = IsLegitimateClient(client);
	new clientTeam = -1;
	if (IsLegitimateClientClient) clientTeam = GetClientTeam(client);
	new clientZombieClass = -1;
	if (clientTeam != -1) clientZombieClass = FindZombieClass(client);
	new ClientType = (IsLegitimateClientClient && clientTeam == TEAM_INFECTED) ? 0 :
					 (IsWitch(client)) ? 1 :
					 (IsSpecialCommon(client)) ? 2 : -1;
	new bool:IsLegitimateClientKiller = IsLegitimateClient(killerblow);
	new killerClientTeam = -1;
	if (IsLegitimateClientKiller) killerClientTeam = GetClientTeam(killerblow);
	/*if (ClientType >= 0 && IsLegitimateClientKiller && killerClientTeam == TEAM_SURVIVOR) {
		if (isQuickscopeKill(killerblow)) {
			// If the user met the server operators standards for a quickscope kill, we do something.
			GetAbilityStrengthByTrigger(killerblow, client, "quickscope");
		}
	}*/
	//CreateItemRoll(client, killerblow);	// all infected types can generate an item roll
	new Float:SurvivorPoints = 0.0;
	new SurvivorExperience = 0;
	new Float:PointsMultiplier = fPointsMultiplier;
	new Float:ExperienceMultiplier = SurvivorExperienceMult;
	new Float:TankingMultiplier = SurvivorExperienceMultTank;
	//new Float:HealingMultiplier = SurvivorExperienceMultHeal;
	//new Float:RatingReductionMult = 0.0;
	new t_Contribution = 0;
	new SurvivorDamage = 0;
	new Float:TheAbilityMultiplier = 0.0;
	if (IsLegitimateClientKiller && ClientType == 0 && killerClientTeam == TEAM_SURVIVOR) {
		TheAbilityMultiplier = GetAbilityMultiplier(killerblow, "I");
		if (TheAbilityMultiplier > 0.0) { // heal because you dealt the killing blow
			HealPlayer(killerblow, killerblow, TheAbilityMultiplier * GetMaximumHealth(killerblow), 'h', true);
		}
		TheAbilityMultiplier = GetAbilityMultiplier(killerblow, "l");
		if (TheAbilityMultiplier > 0.0) {
			// Creates fire on the target and deals AOE explosion.
			CreateExplosion(client, RoundToCeil(lastBaseDamage[killerblow] * TheAbilityMultiplier), killerblow, true);
			CreateFireEx(client);
		}
	}
	//new owner = 0;
	//if (IsLegitimateClientAlive(commonkiller) && GetClientTeam(commonkiller) == TEAM_SURVIVOR) owner = commonkiller;
	new Float:i_DamageContribution = 0.0000;
	// If it's a special common, we activate its death abilities.
	if (ClientType == 2) {
		decl String:TheEffect[10];
		GetCommonValueAtPos(TheEffect, sizeof(TheEffect), client, SUPER_COMMON_AURA_EFFECT);
		CreateBomberExplosion(client, client, TheEffect);	// bomber aoe
	}
	new pos = -1;
	new RatingBonus = 0;
	new RatingTeamBonus = 0;
	new iLivingSurvivors = LivingSurvivors();
	//decl String:MyName[64];
	// decl String:killerName[64];
	decl String:killedName[64];
	if (ClientType > 0 || IsLegitimateClientClient) {
		if (IsLegitimateClientClient) GetClientName(client, killedName, sizeof(killedName));
		else {
			if (ClientType == 1) Format(killedName, sizeof(killedName), "Witch");
			else {
				GetCommonValueAtPos(killedName, sizeof(killedName), client, SUPER_COMMON_NAME);
				Format(killedName, sizeof(killedName), "Common %s", killedName);
			}
		}
		// if (IsLegitimateClientKiller) {
		// 	GetClientName(killerblow, killerName, sizeof(killerName));
		// 	PrintToChatAll("%t", "player killed special infected", blue, killerName, white, orange, killedName);
		// }
		// else if (ClientType != 2) {
		// 	PrintToChatAll("%t", "killed special infected", orange, killedName, white);
		// }
		if (!IsLegitimateClientKiller) PrintToChatAll("%t", "killed special infected", orange, killedName, white);
	}
	decl String:ratingBonusText[64];
	decl String:ratingTeamBonusText[64];
	new bool:survivorsRequiredForBonusRating = (iLivingSurvivors > iTeamRatingRequired) ? true : false;
	new bool:bSomeoneHurtThisInfected = false;
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
		// if (bIsInCheckpoint[i]) {
		// 	if (ClientType == 0) RemoveFromArray(Handle:InfectedHealth[i], pos);
		// 	else if (ClientType == 1) RemoveFromArray(Handle:WitchDamage[i], pos);
		// 	else if (ClientType == 2) RemoveFromArray(Handle:SpecialCommon[i], pos);
		// 	continue;
		// }
		if (LastAttackedUser[i] == client) LastAttackedUser[i] = -1;
		if (ClientType == 0) SurvivorDamage = GetArrayCell(Handle:InfectedHealth[i], pos, 2);
		else if (ClientType == 1) SurvivorDamage = GetArrayCell(Handle:WitchDamage[i], pos, 2);
		else if (ClientType == 2) SurvivorDamage = GetArrayCell(Handle:SpecialCommon[i], pos, 2);
		RatingBonus = GetRatingReward(i, client);
		if (RatingBonus > 0) {
			if (!bSomeoneHurtThisInfected) bSomeoneHurtThisInfected = true;
			if (!IsFakeClient(i) && ClientType >= 0) {
				if (!survivorsRequiredForBonusRating) {
					AddCommasToString(RatingBonus, ratingBonusText, sizeof(ratingBonusText));
					PrintToChat(i, "%T", "rating increase", i, white, blue, ratingBonusText, orange);
				}
				else {
					RatingTeamBonus = RoundToCeil(RatingBonus * ((iLivingSurvivors - iTeamRatingRequired) * fTeamRatingBonus));
					AddCommasToString(RatingBonus+RatingTeamBonus, ratingBonusText, sizeof(ratingBonusText));
					AddCommasToString(RatingTeamBonus, ratingTeamBonusText, sizeof(ratingTeamBonusText));
					Rating[i] += RatingTeamBonus;
					PrintToChat(i, "%T", "rating increase", i, white, blue, ratingBonusText, orange);
					//PrintToChat(i, "%T", "team rating increase", i, white, blue, ratingBonusText, orange, white, blue, ratingTeamBonusText, orange, white);
				}
			}
			CheckMinimumRate(i);
			Rating[i] += RatingBonus;
			bIsSettingsCheck = true;		// whenever rating is earned for anything other than common infected kills, we want to check the settings to see if a boost to commons is necessary.
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
		// if (h_Contribution > 0) {
		// 	h_Contribution = RoundToCeil(h_Contribution * HealingMultiplier);
		// 	SurvivorPoints += (h_Contribution * (PointsMultiplier * HealingMultiplier));
		// }
		//if (!bIsInCombat[i]) ReceiveInfectedDamageAward(i, client, SurvivorExperience, SurvivorPoints, t_Contribution, h_Contribution, Bu_Contribution, He_Contribution);
		//HealingContribution[i] += h_Contribution;
		TankingContribution[i] += t_Contribution;
		PointsContribution[i] += SurvivorPoints;
		DamageContribution[i] += SurvivorExperience;
		if (ClientType == 0) RemoveFromArray(Handle:InfectedHealth[i], pos);
		else if (ClientType == 1) RemoveFromArray(Handle:WitchDamage[i], pos);
		else if (ClientType == 2) RemoveFromArray(Handle:SpecialCommon[i], pos);
	}
	if (bSomeoneHurtThisInfected) {
		if (ClientType == 0) {
			SpecialsKilled++;
			ReadyUp_NtvStatistics(killerblow, 6, 1);
			if (clientZombieClass != ZOMBIECLASS_TANK) SetArrayCell(Handle:RoundStatistics, 3, GetArrayCell(RoundStatistics, 3) + 1);
			else SetArrayCell(Handle:RoundStatistics, 4, GetArrayCell(RoundStatistics, 4) + 1);

			if (IsFakeClient(client)) {
				new Float:fDirectorPointsEarned = (DamageContribution[client] * fPointsMultiplierInfected);
				if (!IsSurvivalMode && RPGRoundTime() >= iEnrageTime) fDirectorPointsEarned *= fEnrageDirectorPoints;
				if (fDirectorPointsEarned > 0.0) {
					Points_Director += fDirectorPointsEarned;
					// decl String:InfectedName[64];
					// GetClientName(client, InfectedName, sizeof(InfectedName));
					// PrintToChatAll("%t", "director points earned", orange, green, fDirectorPointsEarned, orange, InfectedName);
					DamageContribution[client] = 0;
				}
			}
		}
		else if (ClientType == 1) SetArrayCell(Handle:RoundStatistics, 2, GetArrayCell(RoundStatistics, 2) + 1);
		else if (ClientType == 2) {
			ReadyUp_NtvStatistics(killerblow, 2, 1);
			SetArrayCell(Handle:RoundStatistics, 1, GetArrayCell(RoundStatistics, 1) + 1);
		}
	}
	if (ClientType == 1) {
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		AcceptEntityInput(client, "Kill");
		if (entityPos >= 0) RemoveFromArray(Handle:WitchList, entityPos);		// Delete the witch. Forever.
	}
	if (IsLegitimateClientClient && clientTeam == TEAM_INFECTED) {

		if (clientZombieClass == ZOMBIECLASS_TANK) bIsDefenderTank[client] = false;

		if (iTankRush != 1 && clientZombieClass == ZOMBIECLASS_TANK && DirectorTankCooldown > 0.0 && f_TankCooldown == -1.0) {

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
	new enemytype = -1;
	if (infected > 0) {
		if (IsLegitimateClient(infected)) {
			GetClientName(infected, InfectedName, sizeof(InfectedName));
			enemytype = 3;
		}
		else if (IsWitch(infected)) {
			Format(InfectedName, sizeof(InfectedName), "Witch");
			enemytype = 2;
		}
		else if (IsSpecialCommon(infected)) {
			GetCommonValueAtPos(InfectedName, sizeof(InfectedName), infected, SUPER_COMMON_NAME);
			enemytype = 1;
		}
		else if (IsCommonInfected(infected)) {
			Format(InfectedName, sizeof(InfectedName), "Common");
			enemytype = 0;
		}
		Format(InfectedName, sizeof(InfectedName), "%s %s", sDirectorTeam, InfectedName);
	}
	//new Float:fRoundMultiplier = 1.0;
	if (RoundExperienceMultiplier[client] > 0.0) {
		//fRoundMultiplier += RoundExperienceMultiplier[client];
		if (e_reward > 0) e_reward += RoundToCeil(e_reward * RoundExperienceMultiplier[client]);
		if (h_reward > 0) h_reward += RoundToCeil(h_reward * RoundExperienceMultiplier[client]);
		if (t_reward > 0) t_reward += RoundToCeil(t_reward * RoundExperienceMultiplier[client]);
		if (bu_reward > 0) bu_reward += RoundToCeil(bu_reward * RoundExperienceMultiplier[client]);
		if (he_reward > 0) he_reward += RoundToCeil(he_reward * RoundExperienceMultiplier[client]);
	}
	new RestedAwardBonus = 0;
	if (RestedExperience[client] > 0) {
		if (e_reward > 0) RestedAwardBonus = RoundToFloor(e_reward * fRestedExpMult);
		if (h_reward > 0) RestedAwardBonus += RoundToFloor(h_reward * fRestedExpMult);
		if (t_reward > 0) RestedAwardBonus += RoundToFloor(t_reward * fRestedExpMult);
		if (bu_reward > 0) RestedAwardBonus += RoundToFloor(bu_reward * fRestedExpMult);
		if (he_reward > 0) RestedAwardBonus += RoundToFloor(he_reward * fRestedExpMult);

		if (RestedAwardBonus >= RestedExperience[client]) {
			RestedAwardBonus = RestedExperience[client];
			RestedExperience[client] = 0;
		}
		else if (RestedAwardBonus < RestedExperience[client]) {
			RestedExperience[client] -= RestedAwardBonus;
		}
	}
	new ExperienceBooster = (e_reward > 0) ? RoundToFloor(e_reward * CheckExperienceBooster(client, e_reward)) : 0;
	if (ExperienceBooster < 1) ExperienceBooster = 0;
	//new Float:TeammateBonus = 0.0;//(LivingSurvivors() - 1) * fSurvivorExpMult;
	new Float:multiplierBonus = 0.0;
	new theCount = LivingSurvivorCount();
	if (iSurvivorModifierRequired > 0 && fSurvivorExpMult > 0.0 && theCount >= iSurvivorModifierRequired) {
		new Float:TeammateBonus = (theCount - (iSurvivorModifierRequired - 1)) * fSurvivorExpMult;
		if (TeammateBonus > 0.0) multiplierBonus += TeammateBonus;
	}
	if (IsGroupMember[client] && GroupMemberBonus > 0.0) multiplierBonus += GroupMemberBonus;
	if (!BotsOnSurvivorTeam() && TotalHumanSurvivors() <= iSurvivorBotsBonusLimit && fSurvivorBotsNoneBonus > 0.0) multiplierBonus += fSurvivorBotsNoneBonus;

	if (multiplierBonus > 0.0) {
		if (e_reward > 0) e_reward += RoundToCeil(multiplierBonus * e_reward);
		if (h_reward > 0) h_reward += RoundToCeil(multiplierBonus * h_reward);
		if (t_reward > 0) t_reward += RoundToCeil(multiplierBonus * t_reward);
		if (bu_reward > 0) bu_reward += RoundToCeil(multiplierBonus * bu_reward);
		if (he_reward > 0) he_reward += RoundToCeil(multiplierBonus * he_reward);
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
	BonusContainer[client] = 0;	// if the player enables it mid-match, this ensures the bonus container is always 0 for paused levelers.
	//	0 = Points Only
	//	1 = RPG Only
	//	2 - RPG + Points
	if (RPGMode > 0 && (iExperienceLevelCap < 1 || PlayerLevel[client] < iExperienceLevelCap)) {
		if (DisplayType > 0 && (infected == 0 || enemytype > 0)) {								// \x04Jockey \x01killed: \x04 \x03experience
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
		if (DisplayType > 0 && (infected == 0 || enemytype > 0)) PrintToChat(client, "%T", "points from damage reward", client, green, white, green, p_reward, blue);
	}
	if (!TheRoundHasEnded) CheckKillPositions(client, true);
}

stock GetBulletOrMeleeHealAmount(healer, target, damage, damagetype, bool:isMelee) {
	new iHealerAmount = damage;
	if (damagetype & DMG_BULLET || damagetype & DMG_SLASH || damagetype & DMG_CLUB) {
		if (!isMelee) {
			iHealerAmount = RoundToCeil(GetAbilityStrengthByTrigger(healer, target, "hB", _, iHealerAmount, _, _, "d", 2, true, _, _, _, damagetype));
			iHealerAmount += RoundToCeil(GetAbilityStrengthByTrigger(healer, target, "hB", _, iHealerAmount, _, _, "healshot", 2, true, _, _, _, damagetype));
		}
		else {
			iHealerAmount = RoundToCeil(GetAbilityStrengthByTrigger(healer, target, "hM", _, iHealerAmount, _, _, "d", 2, true, _, _, _, damagetype));
			iHealerAmount += RoundToCeil(GetAbilityStrengthByTrigger(healer, target, "hM", _, iHealerAmount, _, _, "healmelee", 2, true, _, _, _, damagetype));
		}
		new Float:TheAbilityMultiplier = GetAbilityMultiplier(target, "expo");
		if (TheAbilityMultiplier > 0.0) iHealerAmount += RoundToCeil(iHealerAmount * TheAbilityMultiplier);
		TheAbilityMultiplier = GetAbilityStrengthByTrigger(healer, target, "lessDamageMoreHeals", _, iHealerAmount, _, _, "d", 2, true, _, _, _, damagetype);
		if (TheAbilityMultiplier > 0.0) iHealerAmount += RoundToCeil(iHealerAmount * TheAbilityMultiplier);
		TheAbilityMultiplier = GetAbilityStrengthByTrigger(healer, target, "lessTankyMoreHeals", _, iHealerAmount, _, _, "d", 2, true, _, _, _, damagetype);
		if (TheAbilityMultiplier > 0.0) iHealerAmount += RoundToCeil(iHealerAmount * TheAbilityMultiplier);
	}
	return iHealerAmount;
}

// Curious RPG System option?
// Points earned from hurting players used to unlock abilities, while experienced earned to increase level determines which abilities a player has access to.
// This way, even if the level is different, everyone starts with the same footing.
// Optional RPG System. Maybe call it "buy rpg mode?"
stock bool:SameTeam_OnTakeDamage(healer, target, damage, bool:IsDamageTalent = false, damagetype = -1) {
	//if (!AllowShotgunToTriggerNodes(healer)) return false;
	//if (HealImmunity[target] ||
	if (bIsInCheckpoint[target]) return true;
	new bool:TheBool = IsMeleeAttacker(healer);
	if (TheBool && bIsMeleeCooldown[healer]) return true;
	//https://pastebin.com/tLLK9kZM
	new iHealerAmount = GetBulletOrMeleeHealAmount(healer, target, damage, damagetype, TheBool);
	if (iHealerAmount < 1) return true;
	if (iHealingPlayerInCombatPutInCombat == 1 && bIsInCombat[target]) {
		CombatTime[healer] = GetEngineTime() + fOutOfCombatTime;
		bIsInCombat[healer] = true;
	}
	if (TheBool) {
		bIsMeleeCooldown[healer] = true;				
		CreateTimer(0.1, Timer_IsMeleeCooldown, healer, TIMER_FLAG_NO_MAPCHANGE);
	}
	else GiveAmmoBack(healer, 1);
	// if (!IsPlayerUsingShotgun(healer)) {
	// 	HealImmunity[target] = true;
	// 	CreateTimer(0.1, Timer_HealImmunity, target, TIMER_FLAG_NO_MAPCHANGE);
	// }
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