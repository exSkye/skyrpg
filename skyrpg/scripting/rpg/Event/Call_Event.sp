// Every single event in the events.cfg is called by this function, and then sent off to a specific function.
// This way a separate template isn't required for events that have different event names.
public Action Event_Occurred(Handle event, char[] event_name, bool dontBroadcast) {

	//if (b_IsSurvivalIntermission) return Plugin_Handled;

	int a_Size						= 0;
	a_Size							= GetArraySize(a_Events);

	char EventName[PLATFORM_MAX_PATH];
	int eventresult = 0;


	char CurrMap[64];
	GetCurrentMap(CurrMap, sizeof(CurrMap));

	for (int i = 0; i < a_Size; i++) {

		EventSection						= GetArrayCell(a_Events, i, 2);
		GetArrayString(EventSection, 0, EventName, sizeof(EventName));

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

	int size = GetArraySize(a_Events);
	char text[64];

	for (int i = 0; i < size; i++) {

		HookSection = GetArrayCell(a_Events, i, 2);
		GetArrayString(HookSection, 0, text, sizeof(text));
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

public Call_Event(Handle event, char[] event_name, bool dontBroadcast, pos) {
	//CallKeys							= GetArrayCell(a_Events, pos, 0);
	CallValues							= GetArrayCell(a_Events, pos, 1);
	char ThePerp[64];
	GetArrayString(CallValues, EVENT_PERPETRATOR, ThePerp, sizeof(ThePerp));
	int attacker = GetClientOfUserId(GetEventInt(event, ThePerp));
	GetArrayString(CallValues, EVENT_VICTIM, ThePerp, sizeof(ThePerp));
	int victim = GetClientOfUserId(GetEventInt(event, ThePerp));
	bool IsLegitimateClientAttacker = IsLegitimateClient(attacker);
	int attackerTeam = -1;
	int attackerZombieClass = -1;
	bool IsFakeClientAttacker = false;
	bool IsFakeClientVictim = false;
	if (IsLegitimateClientAttacker) {
		attackerTeam = myCurrentTeam[attacker];
		IsFakeClientAttacker = IsFakeClient(attacker);
		attackerZombieClass = FindZombieClass(attacker);
	}
	int victimType = -1;
	int victimTeam = -1;
	//new bool:IsFakeClientVictim = false;
	if (IsCommonInfected(victim)) victimType = 0;
	else if (IsWitch(victim)) victimType = 1;
	else if (IsLegitimateClient(victim)) {
		victimType = 2;
		victimTeam = myCurrentTeam[victim];
		IsFakeClientVictim = IsFakeClient(victim);

		int targetTriggerInt = GetArrayCell(CallValues, EVENT_VICTIM_ABILITY_TRIGGER);
		if (targetTriggerInt != -1) {
			GetAbilityStrengthByTrigger(victim, attacker, targetTriggerInt);
		}
	}
	if (IsLegitimateClientAttacker) {
		if (victimType == 1 && FindListPositionByEntity(victim, WitchList) < 0) OnWitchCreated(victim);

		int activatorTriggerInt = GetArrayCell(CallValues, EVENT_PERPETRATOR_ABILITY_TRIGGER);
		if (activatorTriggerInt != -1) {
			GetAbilityStrengthByTrigger(attacker, victim, activatorTriggerInt);
		}
		if (IsFakeClientVictim && victimTeam == TEAM_SURVIVOR) {
			if (StrEqual(event_name, "heal_success")) {
				GiveMaximumHealth(victim);
				RefreshSurvivor(victim);
			}
			else if (StrEqual(event_name, "pills_used")) {
				float fPainPillsHeal = GetTempHealth(victim) + (GetMaximumHealth(victim) * fPainPillsHealAmount);
				HealPlayer(victim, attacker, fPainPillsHeal, 'h', true);
			}
		}
		if (StrEqual(event_name, "defibrillator_used")) {
			int oldrating = GetArrayCell(tempStorage, victim, 0);
			int oldhandicap = GetArrayCell(tempStorage, victim, 1);
			float oldmultiplier = GetArrayCell(tempStorage, victim, 2);
			Rating[victim] = oldrating;
			handicapLevel[victim] = oldhandicap;
			RoundExperienceMultiplier[victim] = oldmultiplier;
			PrintToChatAll("%t", "rise again", white, orange, white);
		}
		if (StrEqual(event_name, "ammo_pickup")) {
			GetWeaponResult(attacker, 5, maximumReserves[attacker]);
		}
	}
	char weapon[64];
	if (StrEqual(event_name, "player_left_start_area") && IsLegitimateClientAttacker) {
		if (attackerTeam == TEAM_SURVIVOR) {
			//if (IsFakeClientAttacker && attackerTeam == TEAM_SURVIVOR && !b_IsLoaded[attacker]) IsClientLoadedEx(attacker);
			if (b_IsInSaferoom[attacker]) {
				b_IsInSaferoom[attacker] = false;
			}
		}
	}
	if (b_IsActiveRound && IsLegitimateClientAttacker) {
		char[] messageToSendToClient = new char[MAX_CHAT_LENGTH];
		if (StrEqual(event_name, "player_entered_checkpoint")) {
			if (!IsFakeClient(attacker) && !bIsInCheckpoint[attacker]) {
				Format(messageToSendToClient, MAX_CHAT_LENGTH, "{B} Your damage/experience is {O}DISABLED {B}while in the safe room.");
				Client_PrintToChat(attacker, true, messageToSendToClient);
			}
			bIsInCheckpoint[attacker] = true;
		}
		if (StrEqual(event_name, "player_left_checkpoint")) {
			if (!IsFakeClient(attacker) && bIsInCheckpoint[attacker]) {
				Format(messageToSendToClient, MAX_CHAT_LENGTH, "{B}You have left the safe area. {O}Your damage/experience is {B}ENABLED.");
				Client_PrintToChat(attacker, true, messageToSendToClient);
			}
			bIsInCheckpoint[attacker] = false;
		}
	}
	if (StrEqual(event_name, "player_incapacitated")) {
		IncapacitateOrKill(victim, attacker);
	}
	if (StrEqual(event_name, "player_spawn")) {
		if (IsLegitimateClientAttacker) {
			myCurrentTeam[attacker] = GetClientTeam(attacker);
			if (myCurrentTeam[attacker] != TEAM_SPECTATOR && !b_IsHooked[attacker]) ChangeHook(attacker, true);
			if (attackerTeam == TEAM_SURVIVOR) {
				ClearArray(ActiveStatuses[attacker]);
				RefreshSurvivor(attacker);
				RaidInfectedBotLimit();
				ResetContributionTracker(attacker);
			}
			else {
				//if (IsFakeClientAttacker) BuildArraysOnClientFirstLoad(attacker);
				int damagePos = FindListPositionByEntity(attacker, damageOfSpecialInfected);
				if (damagePos == -1) {
					damagePos = GetArraySize(damageOfSpecialInfected);
					//ResizeArray(damageOfSpecialInfected, damagePos+1);
					PushArrayCell(damageOfSpecialInfected, attacker);
				}
				SetArrayCell(damageOfSpecialInfected, damagePos, 0, 1);
				DamageContribution[attacker] = 0;
				//SetInfectedHealth(attacker, 99999);
				if (!IsFakeClientAttacker) PlayerSpawnAbilityTrigger(attacker);
				ClearArray(PlayerAbilitiesCooldown[attacker]);
				ClearArray(PlayerActiveAbilitiesCooldown[attacker]);
				ClearArray(InfectedHealth[attacker]);
				ResizeArray(InfectedHealth[attacker], 1);	// infected player stores their actual health (from talents, abilities, etc.) locally...
				bHealthIsSet[attacker] = false;
				//if (!b_IsHooked[attacker]) {
				//CreateMyHealthPool(attacker);
				//}
				if (attackerZombieClass == ZOMBIECLASS_TANK) {
					ClearArray(TankState_Array[attacker]);
					bHasTeleported[attacker] = false;
					if (iTanksPreset == 1) {
						int iRand = GetRandomInt(1, 3);
						if (iRand == 1) ChangeTankState(attacker, "hulk");
						else if (iRand == 2) ChangeTankState(attacker, "death");
						else if (iRand == 3) ChangeTankState(attacker, "burn");
					}
				}
				//InitInfectedHealthForSurvivors(attacker);
			}
		}
	}
	if (!b_IsActiveRound || IsLegitimateClientAttacker && attackerTeam == TEAM_SURVIVOR && !b_IsLoaded[attacker]) return 0;		// don't track ANYTHING when it's not an active round.
	char curEquippedWeapon[64];
	if (StrEqual(event_name, "weapon_reload") || StrEqual(event_name, "bullet_impact")) {
		int WeaponId =	GetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon");
		if (IsValidEntity(WeaponId)) GetEntityClassname(WeaponId, curEquippedWeapon, sizeof(curEquippedWeapon));
		else Format(curEquippedWeapon, sizeof(curEquippedWeapon), "-1");
	}
	if (victimTeam == TEAM_SURVIVOR) {
		if (StrEqual(event_name, "revive_success")) {
			if (attacker != victim) {
				GetAbilityStrengthByTrigger(victim, attacker, TRIGGER_R, _, 0);
				GetAbilityStrengthByTrigger(attacker, victim, TRIGGER_r, _, 0);
			}
			SetEntPropEnt(victim, Prop_Send, "m_reviveOwner", -1);
			SetEntPropEnt(attacker, Prop_Send, "m_reviveTarget", -1);
			int reviveOwner = GetEntPropEnt(victim, Prop_Send, "m_reviveOwner");
			if (IsLegitimateClient(reviveOwner)) SetEntPropEnt(reviveOwner, Prop_Send, "m_reviveTarget", -1);
			GiveMaximumHealth(victim);
		}
	}
	GetArrayString(CallValues, EVENT_DAMAGE_TYPE, ThePerp, sizeof(ThePerp));
	int damagetype = GetEventInt(event, ThePerp);
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
			b_IsRescueVehicleArrived = true;
		}
		//PrintToChatAll("%t", "Experience Gains Disabled", orange, white, orange, white, blue);
	}
	// Declare the values that can be defined by the event config, so we know whether to consider them.
	//new RPGMode						= iRPGMode;	// 1 experience 2 experience & points
	char AbilityUsed[PLATFORM_MAX_PATH];
	char abilities[PLATFORM_MAX_PATH];
	GetArrayString(CallValues, EVENT_GET_HEALTH, ThePerp, sizeof(ThePerp));
	int healthvalue = GetEventInt(event, ThePerp);
	int isdamageaward = GetArrayCell(CallValues, EVENT_DAMAGE_AWARD);
	GetArrayString(CallValues, EVENT_GET_ABILITIES, abilities, sizeof(abilities));
	int tagability = GetArrayCell(CallValues, EVENT_IS_PLAYER_NOW_IT);
	int originvalue = GetArrayCell(CallValues, EVENT_IS_ORIGIN);
	int distancevalue = GetArrayCell(CallValues, EVENT_IS_DISTANCE);
	float multiplierpts = GetArrayCell(CallValues, EVENT_MULTIPLIER_POINTS);
	float multiplierexp = GetArrayCell(CallValues, EVENT_MULTIPLIER_EXPERIENCE);
	int isshoved = GetArrayCell(CallValues, EVENT_IS_SHOVED);
	int bulletimpact = GetArrayCell(CallValues, EVENT_IS_BULLET_IMPACT);
	int isinsaferoom = GetArrayCell(CallValues, EVENT_ENTERED_SAFEROOM);
	if (bulletimpact == 1) {
		if (attackerTeam == TEAM_SURVIVOR) {
			int bulletsFired = 0;
			if (!StrEqual(curEquippedWeapon, "-1")) {
				GetTrieValue(currentEquippedWeapon[attacker], curEquippedWeapon, bulletsFired);
				SetTrieValue(currentEquippedWeapon[attacker], curEquippedWeapon, bulletsFired + 1);
			}
			float Coords[3];
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
				float EyeCoords[3];
				GetClientEyePosition(attacker, EyeCoords);
				// Adjust the coords so they line up with the gun
				EyeCoords[2] -= 10.0;
				int TrailsColours[4];
				TrailsColours[3] = 200;
				char ClientModel[64];
				char TargetModel[64];
				GetClientModel(attacker, ClientModel, sizeof(ClientModel));
				int bulletsize		= GetArraySize(a_Trails);
				for (int i = 0; i < bulletsize; i++) {
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
				for (int i = 1; i <= MaxClients; i++) {
					if (IsLegitimateClient(i) && !IsFakeClient(i)) {
						TE_SetupBeamPoints(EyeCoords, Coords, g_iSprite, 0, 0, 0, 0.06, 0.09, 0.09, 1, 0.0, TrailsColours, 0);
						TE_SendToClient(i);
					}
				}
			}
		}
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
				GetAbilityStrengthByTrigger(attacker, victim, TRIGGER_d, _, healthvalue);
				GetAbilityStrengthByTrigger(victim, attacker, TRIGGER_l, _, healthvalue);
			}
			else ReadyUp_NtvFriendlyFire(attacker, victim, healthvalue, GetClientHealth(victim), 1, 0);
		}
		//if (victimType == 2 && victimTeam == TEAM_INFECTED) SetEntityHealth(victim, 40000);
		if (IsLegitimateClientAttacker && attackerTeam == TEAM_SURVIVOR && isinsaferoom == 1) bIsInCheckpoint[attacker] = true;
	}
	if (isshoved == 1 && victimType == 2 && IsLegitimateClientAttacker && victimTeam != attackerTeam) {
		if (victimTeam == TEAM_INFECTED) SetEntityHealth(victim, GetClientHealth(victim) + healthvalue);
		GetAbilityStrengthByTrigger(victim, attacker, TRIGGER_H, _, 0);
	}
	if (isshoved == 2 && IsLegitimateClientAttacker && victimType == 0 && !IsCommonStaggered(victim)) {
		int staggeredSize = GetArraySize(StaggeredTargets);
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
			int changeClassId = 0;
			if (iSpecialsAllowed == 0 && attackerZombieClass != ZOMBIECLASS_TANK) {
				ForcePlayerSuicide(attacker);
			}
			else SetClientTalentStrength(attacker, true);
			if (iSpecialsAllowed == 1 && !StrEqual(sSpecialsAllowed, "-1")) {
				char myClass[5];
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
			int iTankCount = GetInfectedCount(ZOMBIECLASS_TANK);
			int iTankLimit = DirectorTankLimit();
			int theClient = FindAnyRandomClient();
			int iSurvivors = TotalHumanSurvivors();
			int iSurvivorBots = TotalSurvivors() - iSurvivors;
			int iLivSurvs = LivingSurvivorCount();
			if (iSurvivorBots >= 2) iSurvivorBots /= 2;
			int requiredTankCount = GetAlwaysTanks(iSurvivors);
			if (attackerZombieClass == ZOMBIECLASS_TANK) {
				if (b_IsFinaleActive && b_IsFinaleTanks) {
					b_IsFinaleTanks = false;
					int numTanksToSpawnOnFinale = LivingHumanSurvivors()/2;
					if (numTanksToSpawnOnFinale > 4) numTanksToSpawnOnFinale = 4;
					else if (numTanksToSpawnOnFinale < 1) numTanksToSpawnOnFinale = 1;
					for (int i = 0; i + iTankCount < numTanksToSpawnOnFinale; i++) {
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
				int iEnsnaredCount = EnsnaredInfected();
				int livingSurvivors = LivingHumanSurvivors();
				int ensnareBonus = (livingSurvivors > 1) ? livingSurvivors - 1 : 0;
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
			GetAbilityStrengthByTrigger(attacker, victim, TRIGGER_infected_abilityuse);
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
		float Distance = 0.0;
		float fTalentStrength = 0.0;
		if (originvalue > 0 || distancevalue > 0) {
			if (originvalue == 1 || distancevalue == 1) {
				GetClientAbsOrigin(attacker, f_OriginStart[attacker]);
				if (attackerZombieClass != ZOMBIECLASS_HUNTER &&
					attackerZombieClass != ZOMBIECLASS_SPITTER) {
					fTalentStrength = GetAbilityStrengthByTrigger(attacker, _, TRIGGER_Q, _, 0);
				}
				if (attackerZombieClass == ZOMBIECLASS_HUNTER) {
					// check for any abilities that are based on abilityused.
					GetClientAbsOrigin(attacker, f_OriginStart[attacker]);
					//GetAbilityStrengthByTrigger(attacker, 0, 'A', FindZombieClass(attacker), healthvalue);
					GetAbilityStrengthByTrigger(attacker, _, TRIGGER_A, _, healthvalue);
				}
				if (attackerZombieClass == ZOMBIECLASS_CHARGER) {
					CreateTimer(0.1, Timer_ChargerJumpCheck, attacker, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			if (originvalue == 2 || distancevalue == 2) {
				int ensnareVictim = L4D2_GetSurvivorVictim(attacker);
				fTalentStrength = GetAbilityStrengthByTrigger(attacker, _, TRIGGER_q, _, 0);
				if (CheckActiveStatuses(attacker, "lunge", false, true) == 0) {
					SetEntityRenderMode(attacker, RENDER_NORMAL);
					SetEntityRenderColor(attacker, 255, 255, 255, 255);
					fTalentStrength += GetAbilityStrengthByTrigger(attacker, _, TRIGGER_A, _, 0);
					if (ensnareVictim != -1) GetAbilityStrengthByTrigger(attacker, ensnareVictim, TRIGGER_pounced, _, lastHealthDamage[ensnareVictim][attacker]);
				}
				GetClientAbsOrigin(attacker, f_OriginEnd[attacker]);
				if (victimType == 2 && victimTeam == TEAM_SURVIVOR) {
					Distance = GetVectorDistance(f_OriginStart[attacker], f_OriginEnd[attacker]);
					if (fTalentStrength > 0.0) Distance += (Distance * fTalentStrength);
					//SetClientTotalHealth(victim, RoundToCeil(Distance), _, true);
					if (ensnareVictim != -1) GetAbilityStrengthByTrigger(attacker, ensnareVictim, TRIGGER_distance, _, RoundToCeil(Distance));
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
				if (distancevalue == 3 && victimType == 2) GetClientAbsOrigin(victim, f_OriginStart[attacker]);
				if (distancevalue == 2 || originvalue == 2 || distancevalue == 4 && victimType == 2) {
					if (distancevalue == 4) GetClientAbsOrigin(victim, f_OriginEnd[attacker]);
					//new Float:Distance = GetVectorDistance(f_OriginStart[attacker], f_OriginEnd[attacker]);
					multiplierexp *= Distance;
					multiplierpts *= Distance;
				}
			}
			if (originvalue == 2 || distancevalue == 2 || distancevalue == 4) {
				if (iRPGMode >= 1 && multiplierexp > 0.0 && PlayerLevel[attacker] < iMaxLevel) {
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