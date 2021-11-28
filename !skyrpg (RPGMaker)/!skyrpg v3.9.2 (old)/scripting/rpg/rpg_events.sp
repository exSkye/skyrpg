// Every single event in the events.cfg is called by this function, and then sent off to a specific function.
// This way a separate template isn't required for events that have different event names.
public Action:Event_Occurred(Handle:event, String:event_name[], bool:dontBroadcast) {

	new a_Size						= 0;
	a_Size							= GetArraySize(a_Events);

	decl String:EventName[PLATFORM_MAX_PATH];

	for (new i = 0; i < a_Size; i++) {

		EventSection						= GetArrayCell(a_Events, i, 2);
		GetArrayString(Handle:EventSection, 0, EventName, sizeof(EventName));

		if (StrEqual(EventName, event_name)) {

			/*if (Call_Event(event, event_name, dontBroadcast, i) == -1) {

				if (StrEqual(EventName, "infected_hurt") || StrEqual(EventName, "player_hurt")) {

					

					//	Returns -1 when infected_hurt or player_hurt and the cause of the damage is not a common infected or a player
					//	or if the damage is "inferno" which can be discerned through the player_hurt event only; we have to resort to
					//	the prior for infected_hurt
					

					return Plugin_Handled;
				}
			}*/
			Call_Event(event, event_name, dontBroadcast, i);
			break;
		}
	}
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
		if (StrEqual(text, "player_hurt", false) || StrEqual(text, "infected_hurt")) {

			if (value == 0) UnhookEvent(text, Event_Occurred, EventHookMode_Pre);
			else HookEvent(text, Event_Occurred, EventHookMode_Pre);
		}
		else {

			if (value == 0) UnhookEvent(text, Event_Occurred);
			else HookEvent(text, Event_Occurred);
		}
	}
}

stock String:FindPlayerWeapon(client) {

	decl String:weapon[64];
	Format(weapon, sizeof(weapon), "-1");

	new g_iActiveWeaponOffset = FindSendPropInfo("CTerrorPlayer", "m_hActiveWeapon");
	new iWeapon = GetEntDataEnt2(client, g_iActiveWeaponOffset);
	if (IsValidEdict(iWeapon)) GetEdictClassname(iWeapon, weapon, sizeof(weapon));

	return weapon;
}

public Call_Event(Handle:event, String:event_name[], bool:dontBroadcast, pos) {

	CallKeys							= GetArrayCell(a_Events, pos, 0);
	CallValues							= GetArrayCell(a_Events, pos, 1);

	new attacker = GetClientOfUserId(GetEventInt(event, GetKeyValue(CallKeys, CallValues, "perpetrator?")));
	new victim = GetEventInt(event, GetKeyValue(CallKeys, CallValues, "victim?"));
	if (!IsWitch(victim) && !IsCommonInfected(victim)) victim = GetClientOfUserId(victim);

	if (IsLegitimateClient(attacker) && IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR) return 0;
	if (IsLegitimateClient(victim) && IsFakeClient(victim) && GetClientTeam(victim) == TEAM_SURVIVOR) return 0;
	if (IsLegitimateClient(attacker) && !b_IsHooked[attacker]) {

		b_IsHooked[attacker] = true;
		SDKHook(attacker, SDKHook_OnTakeDamage, OnTakeDamage);
		//if (IsFakeClient(attacker)) SetEntityHealth(attacker, 100000);
	}
	if (IsLegitimateClient(victim) && !b_IsHooked[victim]) {

		b_IsHooked[victim] = true;
		SDKHook(victim, SDKHook_OnTakeDamage, OnTakeDamage);
		//if (IsFakeClient(victim)) SetEntityHealth(victim, 100000);
	}

	if (StrEqual(event_name, "round_end")) {

		//LogToFile(LogPathDirectory, "[ROUND OVER] Removing SDK Hooks from players.");

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i) && b_IsHooked[i]) {

				b_IsHooked[i] = false;
				SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}

	if (!b_IsActiveRound) return 0;		// don't track ANYTHING when it's not an active round.
	new damagetype = GetEventInt(event, GetKeyValue(CallKeys, CallValues, "damage type?"));

	decl String:weapon[64];
	//decl String:key[64];
	if (StrEqual(event_name, "player_hurt")) {

		GetEventString(event, "weapon", weapon, sizeof(weapon));
		//if (StrEqual(weapon, "inferno") || damagetype == 8 || damagetype == 2056 || damagetype == 268435464) return -1;
	}
	if (StrEqual(event_name, "infected_hurt")) {

		//if (damagetype == 8 || damagetype == 2056 || damagetype == 268435464) return -1;
	}

	if (StrEqual(event_name, "finale_radio_start")) {

		// When the finale is active, players can earn experience whilst camping (not moving from a spot, re: farming)
		b_IsFinaleActive = true;

		//PrintToChatAll("%t", "Farming Prevention Disabled", white, orange, white, orange, white, blue);
	}
	if (StrEqual(event_name, "finale_vehicle_ready")) {

		// When the vehicle arrives, the finale is no longer active, but no experience can be earned. This stops farming.
		b_IsFinaleActive = false;

		PrintToChatAll("%t", "Experience Gains Disabled", orange, white, orange, white, blue);
	}

	// Declare the values that can be defined by the event config, so we know whether to consider them.

	new RPGMode						= StringToInt(GetConfigValue("rpg mode?"));	// 1 experience 2 experience & points

	decl String:EventName[PLATFORM_MAX_PATH];
	decl String:AbilityUsed[PLATFORM_MAX_PATH];
	decl String:abilities[PLATFORM_MAX_PATH];
	decl String:ActivatorAbility[PLATFORM_MAX_PATH];
	decl String:TargetAbility[PLATFORM_MAX_PATH];

	Format(EventName, sizeof(EventName), "%s", GetKeyValue(CallKeys, CallValues, "event name?"));

	//new attacker = GetClientOfUserId(GetEventInt(event, GetKeyValue(CallKeys, CallValues, "perpetrator?")));
	//if (IsWitch(victim)) PrintToChatAll("Wiotch!!");
	if (!IsWitch(victim) && !IsCommonInfected(victim) && IsLegitimateClient(victim) && IsFakeClient(victim) && GetClientTeam(victim) == TEAM_SURVIVOR) return 0;

	new healthvalue = GetEventInt(event, GetKeyValue(CallKeys, CallValues, "health?"));
	new isdamageaward = StringToInt(GetKeyValue(CallKeys, CallValues, "damage award?"));
	new healing = StringToInt(GetKeyValue(CallKeys, CallValues, "healing?"));

	new deathaward = StringToInt(GetKeyValue(CallKeys, CallValues, "death award?"));
	Format(abilities, sizeof(abilities), "%s", GetKeyValue(CallKeys, CallValues, "abilities?"));
	new tagability = StringToInt(GetKeyValue(CallKeys, CallValues, "tag ability?"));
	new tagexperience = StringToInt(GetKeyValue(CallKeys, CallValues, "tag experience?"));
	new Float:tagpoints = StringToFloat(GetKeyValue(CallKeys, CallValues, "tag points?"));
	new originvalue = StringToInt(GetKeyValue(CallKeys, CallValues, "origin?"));
	new distancevalue = StringToInt(GetKeyValue(CallKeys, CallValues, "distance?"));
	new Float:multiplierpts = StringToFloat(GetKeyValue(CallKeys, CallValues, "multiplier points?"));
	new Float:multiplierexp = StringToFloat(GetKeyValue(CallKeys, CallValues, "multiplier exp?"));
	new isshoved = StringToInt(GetKeyValue(CallKeys, CallValues, "shoved?"));
	new bulletimpact = StringToInt(GetKeyValue(CallKeys, CallValues, "bulletimpact?"));
	new isinsaferoom = StringToInt(GetKeyValue(CallKeys, CallValues, "entered saferoom?"));
	new isEntityPos = -1;
	new isArraySize = -1;

	Format(ActivatorAbility, sizeof(ActivatorAbility), "%s", GetKeyValue(CallKeys, CallValues, "activator ability?"));
	Format(TargetAbility, sizeof(TargetAbility), "%s", GetKeyValue(CallKeys, CallValues, "target ability?"));

	//if ((IsLegitimateClient(attacker) && !IsFakeClient(attacker) && b_IsLoading[attacker]) || (IsLegitimateClient(victim) && !IsFakeClient(victim) && b_IsLoading[victim])) return;
	/*if (attacker > 0 && IsLegitimateClient(attacker) && !IsFakeClient(attacker) && PlayerLevel[attacker] == 0 && !b_IsLoading[attacker]) {

		GetClientAuthString(attacker, key, sizeof(key));
		b_IsLoading[attacker] = true;
		ResetData(attacker);
		ClearAndLoad(key);
		return;
	}
	if (victim > 0 && IsLegitimateClient(victim) && !IsFakeClient(victim) && PlayerLevel[victim] == 0 && !b_IsLoading[victim]) {

		GetClientAuthString(victim, key, sizeof(key));
		b_IsLoading[victim] = true;
		ResetData(victim);
		ClearAndLoad(key);
		return;
	}*/
	if (IsLegitimateClient(victim) && !StrEqual(TargetAbility, "-1", false)) {

		for (new i = 0; i <= strlen(TargetAbility); i++) {

			FindAbilityByTrigger(victim, attacker, TargetAbility[i], FindZombieClass(victim), 0);
		}
	}
	if (IsLegitimateClient(attacker) && !StrEqual(ActivatorAbility, "-1", false)) {

		for (new i = 0; i <= strlen(ActivatorAbility); i++) {

			FindAbilityByTrigger(attacker, victim, ActivatorAbility[i], FindZombieClass(attacker), 0);
		}
	}
	if (IsLegitimateClient(victim) && IsFakeClient(victim) && GetClientTeam(victim) == TEAM_INFECTED) {

		LogToFile(LogPathDirectory, "%N health set to 40000", victim);
		if (FindZombieClass(victim) == ZOMBIECLASS_TANK) ExtinguishEntity(victim);
		SetEntityHealth(victim, 40000);
	}
	if (isdamageaward == 1) {

		if (IsLegitimateClientAlive(victim) && !IsFakeClient(victim) && GetClientTeam(victim) == TEAM_SURVIVOR) {

			if (IsLegitimateClient(victim) && !b_IsHooked[victim]) {

				b_IsHooked[victim] = true;
				SDKHook(victim, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
		if (StrEqual(weapon, "spitter_projectile")) LogToFile(LogPathDirectory, "Spitter projectile!");
		if (IsLegitimateClient(attacker) && IsLegitimateClient(victim) && GetClientTeam(attacker) == GetClientTeam(victim)) {

			if (!(damagetype & DMG_BURN) && !StrEqual(weapon, "inferno")) {

				new FFIncrease			= StringToInt(GetConfigValue("survivor friendly fire increase?")) * LivingSurvivors();
				if (!IsIncapacitated(victim) && GetClientHealth(victim) <= FFIncrease) FFIncrease			= GetClientHealth(victim);

				//ReadyUp_NtvFriendlyFire(attacker, victim, (StringToInt(GetConfigValue("survivor friendly fire increase?")) * LivingHumanSurvivors()) + healthvalue, GetClientHealth(victim), 0);
				ReadyUp_NtvFriendlyFire(attacker, victim, healthvalue, GetClientHealth(victim), 0, FFIncrease);

				// damage-based triggers now only occur under the circumstances in the code above. No longer do we have triggers for same-team damaging. Maybe at a later date, but it will not be the same ability trigger.
				FindAbilityByTrigger(attacker, victim, 'd', FindZombieClass(attacker), healthvalue);
				FindAbilityByTrigger(victim, attacker, 'l', FindZombieClass(victim), healthvalue);
			}
			else {

				ReadyUp_NtvFriendlyFire(attacker, victim, healthvalue, GetClientHealth(victim), 1, 0);
			}
		}
		if (IsLegitimateClient(attacker) && IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED) {

			if (!b_IsHooked[attacker]) {

				//LogToFile(LogPathDirectory, "[INFECTED PLAYER] %N Has been hooked to SDKHooks.", attacker);

				b_IsHooked[attacker] = true;
				SDKHook(attacker, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
		if (IsLegitimateClient(victim) && IsFakeClient(victim) && GetClientTeam(victim) == TEAM_INFECTED) {

			/*

				Because all health pools are instanced, actual health pools should never decrease, so we keep them always topped-off.
			*/
			LogToFile(LogPathDirectory, "%N health set to 40000", victim);
			if (FindZombieClass(victim) == ZOMBIECLASS_TANK) ExtinguishEntity(victim);
			SetEntityHealth(victim, 40000);
		}
		/*if (IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR) {

			if (IsWitch(victim)) {
				
				Format(weapon, sizeof(weapon), "%s", FindPlayerWeapon(attacker));
				if (StrEqual(weapon, "melee", false) || !bIsMeleeCooldown[attacker]) {

					if (StrContains(weapon, "shotgun", false) != -1) {

						bIsMeleeCooldown[attacker] = true;				
						CreateTimer(0.3, Timer_IsMeleeCooldown, attacker, TIMER_FLAG_NO_MAPCHANGE);
					}
					AddWitchDamage(attacker, victim, healthvalue);


					if (StringToInt(GetConfigValue("display health bars?")) == 1) {

						if (damagetype != 8 && damagetype != 268435464 && !StrEqual(weapon, "inferno")) {

							DisplayInfectedHealthBars(attacker, victim);
						}
					}
					if (CheckTeammateDamages(victim, attacker) >= 1.0 ||
						CheckTeammateDamages(victim, attacker, true) >= 1.0 ||
						CheckTeammateDamages(victim, attacker) < 0.0 ||
						CheckTeammateDamages(victim, attacker, true) < 0.0) {

						OnWitchCreated(victim, true);
					}
				}
			}
		}*/
		if (attacker > 0 && IsLegitimateClient(attacker)) {

			if (!IsFakeClient(attacker)) {

				if (!b_HandicapLocked[attacker]) {

					b_HandicapLocked[attacker] = true;
					PrintToChat(attacker, "%T", "handicap locked until end of round", attacker, white, green, white, orange);
					SetClientMovementSpeed(attacker);
				}
				if (b_IsMissionFailed && HandicapLevel[attacker] != -1) {

					PrintToChat(attacker, "%T", "handicap disabled for map", attacker, orange);
					HandicapLevel[attacker] = -1;
					SetClientMovementSpeed(attacker);
				}
				if (GetClientTeam(attacker) == TEAM_SURVIVOR && isinsaferoom == 1) b_IsInSaferoom[attacker] = true;
			}
		}
		if (!IsLegitimateClient(attacker) && StrEqual(EventName, "player_hurt")) {


		}
	}
	if (deathaward == 1) {

		if (IsLegitimateClient(victim) && GetClientTeam(victim) == TEAM_INFECTED) {

			if (IsLegitimateClientAlive(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && IsIncapacitated(attacker)) {

				FindAbilityByTrigger(attacker, attacker, 'k', FindZombieClass(attacker), 0);
			}
			if (IsFakeClient(victim)) b_IsImmune[victim] = false;
			if (ReadyUp_GetGameMode() == 2) {

				// Versus, do tanks have a cooldown?
				if (FindZombieClass(victim) == ZOMBIECLASS_TANK && StringToFloat(GetConfigValue("versus tank cooldown?")) > 0.0 && f_TankCooldown == -1.0) {

					f_TankCooldown				=	StringToFloat(GetConfigValue("versus tank cooldown?"));

					CreateTimer(1.0, Timer_TankCooldown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			else if (ReadyUp_GetGameMode() == 1) {

				if (FindZombieClass(victim) == ZOMBIECLASS_TANK && StringToFloat(GetConfigValue("director tank cooldown?")) > 0.0 && f_TankCooldown == -1.0) {

					f_TankCooldown				=	StringToFloat(GetConfigValue("versus tank cooldown?"));

					CreateTimer(1.0, Timer_TankCooldown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			CalculateInfectedDamageAward(victim);
		}
	}
	if (isshoved == 1 && IsLegitimateClientAlive(victim) && IsLegitimateClientAlive(attacker) && GetClientTeam(victim) != GetClientTeam(attacker)) {

		if (GetClientTeam(victim) == TEAM_INFECTED) SetEntityHealth(victim, GetClientHealth(victim) + healthvalue);

		FindAbilityByTrigger(victim, attacker, 'H', FindZombieClass(victim), 0);
	}
	if (bulletimpact == 1) {

		if (IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && StringToInt(GetConfigValue("trails enabled?")) == 1) {

			new Float:Coords[3];
			Coords[0] = GetEventFloat(event, "x");
			Coords[1] = GetEventFloat(event, "y");
			Coords[2] = GetEventFloat(event, "z");

			new Float:EyeCoords[3];
			GetClientEyePosition(attacker, EyeCoords);
			// Adjust the coords so they line up with the gun
			EyeCoords[2] += -5.0;

			new TrailsColours[4];
			TrailsColours[3] = 200;

			decl String:ClientModel[64];
			GetClientModel(attacker, ClientModel, sizeof(ClientModel));

			new bulletsize		= GetArraySize(a_Trails);
			for (new i = 0; i < bulletsize; i++) {

				TrailsKeys[attacker] = GetArrayCell(a_Trails, i, 0);
				TrailsValues[attacker] = GetArrayCell(a_Trails, i, 1);

				if (StrEqual(GetKeyValue(TrailsKeys[attacker], TrailsValues[attacker], "model affected?"), ClientModel)) {

					TrailsColours[0]		= StringToInt(GetKeyValue(TrailsKeys[attacker], TrailsValues[attacker], "red?"));
					TrailsColours[1]		= StringToInt(GetKeyValue(TrailsKeys[attacker], TrailsValues[attacker], "green?"));
					TrailsColours[2]		= StringToInt(GetKeyValue(TrailsKeys[attacker], TrailsValues[attacker], "blue?"));
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
	if (StrEqual(EventName, "player_team")) {

		if (IsLegitimateClient(attacker) && !IsFakeClient(attacker)) CreateTimer(1.0, Timer_SwitchTeams, attacker, TIMER_FLAG_NO_MAPCHANGE);
	}
	if (StrEqual(EventName, "player_spawn")) {

		if (IsLegitimateClient(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR) {

			RefreshSurvivor(attacker);
			//SDKHook(attacker, SDKHook_OnTakeDamage, OnTakeDamage);
		}
		if (IsLegitimateClient(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED) {

			PlayerSpawnAbilityTrigger(attacker);
		}
		if (IsLegitimateClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED) {

			SDKHook(attacker, SDKHook_OnTakeDamage, OnTakeDamage);
			decl String:InfecttedSpeedBonusType[64];
			Format(InfecttedSpeedBonusType, sizeof(InfecttedSpeedBonusType), "(%d) infected speed bonus", FindZombieClass(attacker));
			new Float:SpeedBonus = StringToFloat(GetConfigValue(InfecttedSpeedBonusType)) * (LivingSurvivorLevels() * 1.0);
			SpeedMultiplierBase[attacker] = 1.0;
			SpeedMultiplier[attacker] = 1.0;
			SetSpeedMultiplierBase(attacker, 1.0 + SpeedBonus);
			b_IsImmune[attacker] = false;
			WipeDamageAward(attacker);

			// If it's a fake bot, give it a ton of life! Because... the plugin ignores health pools but weapons do not if the damage exceeds the infected special health pool.
			//if (IsFakeClient(attacker)) SetEntityHealth(attacker, 100000);
			decl String:s_InfectedHealth[64];
			new t_InfectedHealth = 0;
			if (FindZombieClass(attacker) == ZOMBIECLASS_TANK) t_InfectedHealth = 4000;
			else if (FindZombieClass(attacker) == ZOMBIECLASS_HUNTER || FindZombieClass(attacker) == ZOMBIECLASS_SMOKER) t_InfectedHealth = 250;
			else if (FindZombieClass(attacker) == ZOMBIECLASS_BOOMER) t_InfectedHealth = 50;
			else if (FindZombieClass(attacker) == ZOMBIECLASS_SPITTER) t_InfectedHealth = 100;
			else if (FindZombieClass(attacker) == ZOMBIECLASS_CHARGER) t_InfectedHealth = 600;
			else if (FindZombieClass(attacker) == ZOMBIECLASS_JOCKEY) t_InfectedHealth = 325;

			Format(s_InfectedHealth, sizeof(s_InfectedHealth), "(%d) infected health bonus", FindZombieClass(attacker));
			for (new i = 1; i <= MaxClients; i++) {

				if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

					t_InfectedHealth = GetClientHealth(attacker);

					DamageAward[i][attacker] = 0;
					DamageAward[attacker][i] = 0;

					isEntityPos = FindListPositionByEntity(attacker, Handle:InfectedHealth[i]);
					if (isEntityPos >= 0) {

						//PrintToChatAll("Infected player found, removing.");

						/*

								Infected bot special infected exists in the list, even though he is
								respawning. So we remove him from everyone's list.
						*/
						RemoveFromArray(Handle:InfectedHealth[i], isEntityPos);
					}
					/*

						Whether or not the entity was found, it will not be there now. So we resize the array.
					*/
					isArraySize = GetArraySize(Handle:InfectedHealth[i]);

					/*

						In order to provide a balanced experience so players of any level can play together,
						the special infected health pools are now tailored individually to each player.
						When the combined efforts of multiple players see their contributions pass the
						infected total health, the infected is killed and damages are awarded.
					*/

					new mlevel = PlayerLevel[i];
					
					if (StringToInt(GetConfigValue("infected bot level type?")) == 1) {

						t_InfectedHealth += RoundToCeil(t_InfectedHealth * (LivingSurvivorLevels() * StringToFloat(GetConfigValue(s_InfectedHealth))));
					}
					else t_InfectedHealth += RoundToCeil(t_InfectedHealth * (mlevel * StringToFloat(GetConfigValue(s_InfectedHealth))));
					if (HandicapLevel[i] > 0) t_InfectedHealth += RoundToCeil(HandicapLevel[i] * StringToFloat(GetConfigValue("handicap health increase?")));

					ResizeArray(Handle:InfectedHealth[i], isArraySize + 1);
					SetArrayCell(Handle:InfectedHealth[i], isArraySize, attacker, 0);
					SetArrayCell(Handle:InfectedHealth[i], isArraySize, t_InfectedHealth, 1);
					SetArrayCell(Handle:InfectedHealth[i], isArraySize, 0, 2);	// damage dealt
					SetArrayCell(Handle:InfectedHealth[i], isArraySize, 0, 3);	// damage received
					SetArrayCell(Handle:InfectedHealth[i], isArraySize, 0, 4);	// healing dealt
					//PrintToChatAll("Infected placed into array!");
				}
			}
			if (IsFakeClient(attacker)) {

				InfectedBotSpawn(attacker);
			}
		}
	}
	if (StrEqual(EventName, "ability_use")) {

		if (IsLegitimateClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED) {

			GetEventString(event, "ability", AbilityUsed, sizeof(AbilityUsed));
			if (StrContains(AbilityUsed, abilities, false) != -1) {

				// check for any abilities that are based on abilityused.
				GetClientAbsOrigin(attacker, Float:f_OriginStart[attacker]);
				FindAbilityByTrigger(attacker, 0, 'A', FindZombieClass(attacker), healthvalue);
			}
		}
	}
	if (IsLegitimateClient(attacker) && (originvalue > 0 || distancevalue > 0)) {

		if (originvalue == 1) {

			GetClientAbsOrigin(attacker, Float:f_OriginStart[attacker]);
		}
		if (originvalue == 2) {

			GetClientAbsOrigin(attacker, Float:f_OriginEnd[attacker]);
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

				new Float:Distance = GetVectorDistance(f_OriginStart[attacker], f_OriginEnd[attacker]);
				multiplierexp *= Distance;
				multiplierpts *= Distance;
			}
		}
		if (originvalue == 2 || distancevalue == 2 || distancevalue == 4) {

			if (RPGMode >= 1 && multiplierexp > 0.0) {

				ExperienceLevel[attacker] += RoundToCeil(multiplierexp);
				ExperienceOverall[attacker] += RoundToCeil(multiplierexp);

				if (ExperienceLevel[attacker] > CheckExperienceRequirement(attacker)) {

					ExperienceOverall[attacker] -= (ExperienceLevel[attacker] - CheckExperienceRequirement(attacker));
					ExperienceLevel[attacker] = CheckExperienceRequirement(attacker);
				}
				ConfirmExperienceAction(attacker);
				if (StringToInt(GetConfigValue("award broadcast?")) > 0) PrintToChat(attacker, "%T", "distance experience", attacker, white, green, RoundToCeil(multiplierexp), white);
			}
			if (RPGMode != 1 && multiplierpts > 0.0) {

				Points[attacker] += multiplierpts;
				if (StringToInt(GetConfigValue("award broadcast?")) > 0) PrintToChat(attacker, "%T", "distance points", attacker, white, green, multiplierpts, white);
			}
		}
	}
	if (healing > 0 && IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR) {

		if (healing == 1) t_Healing[attacker] = GetClientTotalHealth(victim);
		if (healing == 2) {

			LoadHealthMaximum(victim);
			GiveMaximumHealth(victim);
			t_Healing[attacker] = GetMaximumHealth(victim) - t_Healing[attacker];
			ReadyUp_NtvFriendlyFire(attacker, victim, 0 - t_Healing[attacker], GetClientTotalHealth(victim), 0, 0);

			if (attacker != victim) {

				multiplierpts += (0.01 * PlayerLevel[victim]);
				multiplierexp += (0.01 * PlayerLevel[victim]);
				multiplierexp *= t_Healing[attacker];
				if (RPGMode >= 1 && multiplierexp > 0.0) {

					ExperienceLevel[victim] += RoundToCeil(multiplierexp);
					ExperienceOverall[victim] += RoundToCeil(multiplierexp);

					if (ExperienceLevel[victim] > CheckExperienceRequirement(victim)) {

						ExperienceOverall[victim] -= (ExperienceLevel[victim] - CheckExperienceRequirement(victim));
						ExperienceLevel[victim] = CheckExperienceRequirement(victim);
					}
					ExperienceLevel[attacker] += RoundToCeil(multiplierexp);
					ExperienceOverall[attacker] += RoundToCeil(multiplierexp);
					if (ExperienceLevel[attacker] > CheckExperienceRequirement(attacker)) {

						ExperienceOverall[attacker] -= (ExperienceLevel[attacker] - CheckExperienceRequirement(attacker));
						ExperienceLevel[attacker] = CheckExperienceRequirement(attacker);
					}
					ConfirmExperienceAction(attacker);
					PrintToChat(victim, "%T", "healing experience", victim, white, green, RoundToCeil(multiplierexp), white);
					PrintToChat(attacker, "%T", "healing experience", attacker, white, green, RoundToCeil(multiplierexp), white);
				}
				if (RPGMode != 1 && multiplierpts > 0.0) {

					multiplierpts *= t_Healing[attacker];
					Points[victim] += multiplierpts;
					Points[attacker] += multiplierpts;
					PrintToChat(victim, "%T", "healing points", victim, white, green, multiplierpts, white);
					PrintToChat(attacker, "%T", "healing points", attacker, white, green, multiplierpts, white);
				}
			}
		}
		if (healing == 3 && attacker != victim) {

			ReadyUp_NtvFriendlyFire(attacker, victim, 0 - GetReviveHealth(), GetClientHealth(victim), 0, 0);

			FindAbilityByTrigger(attacker, victim, 'r', FindZombieClass(attacker), healthvalue);
			FindAbilityByTrigger(victim, attacker, 'R', FindZombieClass(victim), 0);

			multiplierexp += (0.01 * PlayerLevel[victim]);
			multiplierpts += (0.01 * PlayerLevel[victim]);

			if (RPGMode >= 1 && multiplierexp > 0.0) {

				ExperienceLevel[victim] += RoundToCeil(multiplierexp);
				ExperienceOverall[victim] += RoundToCeil(multiplierexp);
				if (ExperienceLevel[victim] > CheckExperienceRequirement(victim)) {

					ExperienceOverall[victim] -= (ExperienceLevel[victim] - CheckExperienceRequirement(victim));
					ExperienceLevel[victim] = CheckExperienceRequirement(victim);
				}
				ConfirmExperienceAction(victim);
				PrintToChat(victim, "%T", "assisting experience", victim, white, green, RoundToCeil(multiplierexp), white);
			}
			if (RPGMode != 1 && multiplierpts > 0.0) {

				Points[victim] += multiplierpts;
				PrintToChat(victim, "%T", "assisting points", victim, white, green, multiplierpts, white);
			}
		}
	}
	if (StrEqual(EventName, "player_incapacitated") && IsLegitimateClient(victim)) {

		if (GetClientTeam(victim) == TEAM_SURVIVOR) {

			RoundIncaps[victim]++;

			if (L4D2_GetInfectedAttacker(victim) == -1) FindAbilityByTrigger(victim, attacker, 'n', FindZombieClass(victim), healthvalue);
			else {							
				
				//CreateTimer(1.0, Timer_IsIncapacitated, victim, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				FindAbilityByTrigger(victim, attacker, 'N', FindZombieClass(victim), healthvalue);
				if (L4D2_GetInfectedAttacker(victim) == attacker) FindAbilityByTrigger(attacker, victim, 'm', FindZombieClass(attacker), healthvalue);
				else FindAbilityByTrigger(victim, L4D2_GetInfectedAttacker(victim), 'm', FindZombieClass(victim), healthvalue);
			}
		}
	}
	if (IsLegitimateClient(attacker) && tagability == 1) {

		if (IsFakeClient(attacker)) ExperienceLevel_Bots += tagexperience;
		else {

			ExperienceLevel[attacker] += (tagexperience * PlayerLevel[attacker]);
			ExperienceOverall[attacker] += (tagexperience * PlayerLevel[attacker]);
			if (ExperienceLevel[attacker] > CheckExperienceRequirement(attacker)) {

				ExperienceOverall[attacker] -= (ExperienceLevel[attacker] - CheckExperienceRequirement(attacker));
				ExperienceLevel[attacker] = CheckExperienceRequirement(attacker);
			}
			ConfirmExperienceAction(attacker);
		}
		if (!IsFakeClient(attacker) && StringToInt(GetConfigValue("award broadcast?")) > 0) PrintToChat(attacker, "%T", "Tag Experience", attacker, white, green, white, tagexperience * PlayerLevel[attacker]);
		if (!IsFakeClient(attacker)) Points[attacker] += tagpoints;
		else Points_Director += tagpoints;
		if (!IsFakeClient(attacker) && StringToInt(GetConfigValue("award broadcast?")) > 0) PrintToChat(attacker, "%T", "Tag Points", attacker, white, green, white, tagpoints);

		if (!IsFakeClient(attacker) && CoveredInBile[victim][attacker] < 0) {

			CoveredInBile[victim][attacker] = 0;

			new Handle:pack;
			CreateDataTimer(StringToFloat(GetConfigValue("default bile points time?")), Timer_CoveredInBile, pack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(pack, attacker);
			WritePackCell(pack, victim);
		}
		if (StringToInt(GetConfigValue("display tag text?")) == 1 && !IsFakeClient(attacker) && StringToInt(GetConfigValue("award broadcast?")) > 0) PrintToChat(attacker, "%T", "tag player", attacker, white, green, tagexperience, white);

		if (IsLegitimateClient(attacker) && attacker > 0) FindAbilityByTrigger(attacker, victim, 'i', FindZombieClass(attacker), healthvalue);
		if (IsLegitimateClient(victim) && victim > 0) FindAbilityByTrigger(victim, attacker, 'I', FindZombieClass(victim), healthvalue);
	}
	return 0;
}

stock String:StoreItemName(client, pos) {

	decl String:Name[64];
	StoreItemNameSection[client]					= GetArrayCell(a_Store, pos, 2);

	GetArrayString(StoreItemNameSection[client], 0, Name, sizeof(Name));

	return Name;
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
		if ((GetEntityFlags(victim) & FL_ONGROUND)) {

			FindAbilityByTrigger(client, victim, 'v', FindZombieClass(client), 0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}

public Action:OnPlayerRunCmd(client, &buttons)
{
	if (IsLegitimateClientAlive(client) && !IsFakeClient(client)) {

		if (IsPlayerAlive(client)) {

			if (buttons & IN_JUMP) {

				if (L4D2_GetInfectedAttacker(client) == -1 && L4D2_GetSurvivorVictim(client) == -1 && (GetEntityFlags(client) & FL_ONGROUND)) {

					FindAbilityByTrigger(client, 0, 'j', FindZombieClass(client), 0);
				}
				if (L4D2_GetSurvivorVictim(client) != -1) {

					new victim = L4D2_GetSurvivorVictim(client);
					if ((GetEntityFlags(victim) & FL_ONGROUND)) FindAbilityByTrigger(client, victim, 'J', FindZombieClass(client), 0);
				}
			}
			else if (!(buttons & IN_JUMP) && b_IsJumping[client]) ModifyGravity(client);
		}
		if (IsPlayerAlive(client) && ((GetClientTeam(client) == TEAM_SURVIVOR && !AnySurvivorsIncapacitated()) || (!IsGhost(client) && GetClientTeam(client) == TEAM_INFECTED))) {

			if (buttons & IN_USE) {

				decl String:Name[MAX_NAME_LENGTH];
				GetClientName(client, Name, sizeof(Name));
				decl String:EName[64];

				new entity = GetClientAimTarget(client, false);

				if (entity != -1) {

					GetEntPropString(entity, Prop_Data, "m_iName", EName, sizeof(EName));

					if (!b_IsActiveRound) {

						// Don't let them pick up melee weapons, but allow everything else.
						decl String:Model[64];
						GetEntityClassname(entity, Model, sizeof(Model));
						if (StrEqual(Model, "weapon_melee_spawn")) return Plugin_Handled;
					}

					new Float:PPos[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", PPos);
					new Float:EPos[3];
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", EPos);
					new Float:Distance = GetVectorDistance(PPos, EPos);

					if (Distance <= StringToFloat(GetConfigValue("item distance?"))) {

						//AcceptEntityInput(entity, "Kill");
					}
					else return Plugin_Continue;
				}
			}
		}
	}
	return Plugin_Continue;
}

stock FindSlatePoints(bool:b_FindMinimum = true) {

	new value = 0;
	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR) {

			count		= Strength[i] + Luck[i] + Agility[i] + Technique[i] + Endurance[i] + SlatePoints[i];

			if (b_FindMinimum && count < value) value = count;
			else if (!b_FindMinimum && count > value) value = count;
		}
	}
	return value;
}

stock GetTotalSlatePoints(client) {

	new count = Strength[client] + Luck[client] + Agility[client] + Technique[client] + Endurance[client] + SlatePoints[client];
	return count;
}

stock bool:IsEveryoneBoosterTime() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR && !HasBoosterTime(i)) return false;
	}
	return true;
}

stock CreateDamageStatusEffect(client, type = 0, target = 0, damage = 0) {

	if (!IsSpecialCommon(client)) return;
	new Float:AfxRange = StringToFloat(GetCommonValue(client, "range player level?"));
	new Float:AfxStrengthLevel = StringToFloat(GetCommonValue(client, "level strength?"));
	new Float:AfxRangeMax = StringToFloat(GetCommonValue(client, "range max?"));
	new AfxMultiplication = StringToInt(GetCommonValue(client, "enemy multiplication?"));
	new AfxStrength = StringToInt(GetCommonValue(client, "aura strength?"));
	new Float:AfxStrengthTarget = StringToFloat(GetCommonValue(client, "strength target?"));
	new Float:AfxRangeBase = StringToFloat(GetCommonValue(client, "range minimum?"));
	new Float:OnFireBase = StringToFloat(GetCommonValue(client, "onfire base time?"));
	new Float:OnFireLevel = StringToFloat(GetCommonValue(client, "onfire level?"));
	new Float:OnFireMax = StringToFloat(GetCommonValue(client, "onfire max time?"));
	new Float:OnFireInterval = StringToFloat(GetCommonValue(client, "onfire interval?"));

	new Float:ClientPosition[3];
	new Float:TargetPosition[3];

	new t_Strength = 0;
	new Float:t_Range = 0.0;
	new ent = -1;

	new Float:t_OnFireRange = 0.0;

	if (damage > 0) AfxStrength = damage;	// if we want to base the damage on a specific value, we can override here.

	GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPosition);
	new NumLivingEntities = LivingEntitiesInRange(client, ClientPosition, AfxRangeMax);
	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || (target != 0 && i != target)) continue;		// if type is 1 and target is 0 acid is spread to all players nearby. but if target is not 0 it is spread to only the player the acid zombie hits. or whatever type uses it.
		GetClientAbsOrigin(i, TargetPosition);

		if (AfxRange > 0.0) t_Range = AfxRange * PlayerLevel[i];
		else t_Range = AfxRangeMax;
		if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
		else t_Range += AfxRangeBase;
		if (GetVectorDistance(ClientPosition, TargetPosition) > (t_Range / 2)) continue;

		if (AfxMultiplication == 1) {

			if (AfxStrengthTarget < 0.0) t_Strength = AfxStrength * NumLivingEntities;
			else t_Strength = RoundToCeil(AfxStrength * (NumLivingEntities * AfxStrengthTarget));
		}
		else t_Strength = AfxStrength;
		if (AfxStrengthLevel > 0.0) t_Strength += RoundToCeil(t_Strength * (PlayerLevel[i] * AfxStrengthLevel));

		t_OnFireRange = OnFireLevel * PlayerLevel[i];
		t_OnFireRange += OnFireBase;
		if (t_OnFireRange > OnFireMax) t_OnFireRange = OnFireMax;

		if (IsSpecialCommonInRange(client, 'b')) {

			t_Strength = GetSpecialCommonDamage(t_Strength, client, 'b', i);
		}

		//PrintToChatAll("Setting %N on fire for %d damage over %3.2f seconds", i, t_Strength, t_OnFireRange);
		if (type == 0) CreateAndAttachFlame(i, t_Strength, t_OnFireRange, OnFireInterval);		// Static time for now.
		else if (type == 3) ReflectionDamage(client, i, target, t_Strength, t_OnFireRange, OnFireInterval);
	}
	while ((ent = FindEntityByClassname(ent, "infected")) != -1) {

		if (IsValidEntity(ent) && ent != client) {

			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TargetPosition);
			if (GetVectorDistance(ClientPosition, TargetPosition) <= (AfxRangeMax / 2)) {

				if (type == 0) CreateAndAttachFlame(ent, t_Strength, OnFireBase, OnFireInterval);
				else if (type == 3) ReflectionDamage(client, ent, target, t_Strength, t_OnFireRange, OnFireInterval);
			}
		}
	}
	//ClearSpecialCommon(client);
}

stock CreateBomberExplosion(client, target) {

	//if (IsLegitimateClient(target) && !IsPlayerAlive(target)) return;
	if (!IsCommonInfected(target) && !IsLegitimateClientAlive(target)) return;

	/*

		When a bomber dies, it explodes.
	*/
	new Float:AfxRange = StringToFloat(GetCommonValue(client, "range player level?"));
	new Float:AfxStrengthLevel = StringToFloat(GetCommonValue(client, "level strength?"));
	new Float:AfxRangeMax = StringToFloat(GetCommonValue(client, "range max?"));
	new AfxMultiplication = StringToInt(GetCommonValue(client, "enemy multiplication?"));
	new AfxStrength = StringToInt(GetCommonValue(client, "aura strength?"));
	new AfxChain = StringToInt(GetCommonValue(client, "chain reaction?"));
	new Float:AfxStrengthTarget = StringToFloat(GetCommonValue(client, "strength target?"));
	new Float:AfxRangeBase = StringToFloat(GetCommonValue(client, "range minimum?"));

	new Float:SourcLoc[3];

	new Float:TargetPosition[3];

	new t_Strength = 0;

	new Float:t_Range = 0.0;

	new ent = -1;

	if (target > 0) {

		if (IsLegitimateClientAlive(target)) GetClientAbsOrigin(target, SourcLoc);
		else if (IsCommonInfected(target) || IsWitch(target)) GetEntPropVector(target, Prop_Send, "m_vecOrigin", SourcLoc);
		new NumLivingEntities = LivingEntitiesInRange(client, SourcLoc, AfxRangeMax);


		for (new i = 1; i <= MaxClients; i++) {

			if (!IsLegitimateClientAlive(i)) continue;
			GetClientAbsOrigin(i, TargetPosition);

			if (AfxRange > 0.0) t_Range = AfxRange * PlayerLevel[i];
			else t_Range = AfxRangeMax;
			if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
			else t_Range += AfxRangeBase;
			if (GetVectorDistance(SourcLoc, TargetPosition) > (t_Range / 2) || StrContains(GetStatusEffects(i), "[Fl]", false) != -1) continue;		// player not within blast radius, takes no damage. Or playing is floating.

			// Because range can fluctuate, we want to get the # of entities within range for EACH player individually.
			if (AfxMultiplication == 1) {

				if (AfxStrengthTarget < 0.0) t_Strength = AfxStrength * NumLivingEntities;
				else t_Strength = RoundToCeil(AfxStrength * (NumLivingEntities * AfxStrengthTarget));
			}
			else t_Strength = AfxStrength;
			if (AfxStrengthLevel > 0.0) t_Strength += RoundToCeil(t_Strength * (PlayerLevel[i] * AfxStrengthLevel));

			if (t_Strength > GetClientHealth(i)) IncapacitateOrKill(i);
			else SetEntityHealth(i, GetClientHealth(i) - t_Strength);

			if (client == target) {

				// To prevent a never-ending chain reaction, we don't allow it to target the bomber that caused it.

				if (!IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && AfxChain == 1) CreateBomberExplosion(client, i);
			}
		}
		CreateExplosion(target);	// boom boom audio and effect on the location.
		if (IsLegitimateClientAlive(target) && !IsFakeClient(target)) ScreenShake(target);

		ent = -1;
		if (client == target) {

			while ((ent = FindEntityByClassname(ent, "infected")) != -1) {

				if (IsValidEntity(ent) && ent != client) {

					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TargetPosition);
					if (GetVectorDistance(SourcLoc, TargetPosition) <= (AfxRangeMax / 2)) {

						CreateBomberExplosion(client, ent);
					}
				}
			}
			CreateBomberExplosion(client, 0);
		}
	}
	else {

		GetEntPropVector(client, Prop_Send, "m_vecOrigin", SourcLoc);

		/*

			The bomber target is 0, so we eliminate any common infected within range.
			Don't worry - this function will have called and executed for all players in range before it gets here
			thanks to the magic of single-threaded language.
		*/
		ent = -1;
		while ((ent = FindEntityByClassname(ent, "infected")) != -1) {

			if (ent != client && !IsSpecialCommon(ent)) {

				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TargetPosition);
				if (GetVectorDistance(SourcLoc, TargetPosition) <= (AfxRangeMax / 2)) {

					//AcceptEntityInput(ent, "Kill");
					
					//ent = FindListPositionByEntity(ent, Handle:CommonInfected);
					//if (ent >= 0) RemoveFromArray(Handle:CommonInfected, ent);
					//CalculateInfectedDamageAward(ent);
					OnCommonInfectedCreated(ent, true);
				}
			}
		}
	}
}

public CalculateInfectedDamageAward(client) {

	new Float:SurvivorPoints = 0.0;
	new SurvivorExperience = 0;
	new Float:PointsMultiplier = StringToFloat(GetConfigValue("points multiplier survivor?"));
	new Float:ExperienceMultiplier = StringToFloat(GetConfigValue("experience multiplier survivor?"));
	new Float:TankingMultiplier = StringToFloat(GetConfigValue("experience multiplier tanking?"));
	new Float:HealingMultiplier = StringToFloat(GetConfigValue("experience multiplier healing?"));
	new t_Contribution = 0;
	new h_Contribution = 0;

	new SurvivorDamage = 0;
	if (!IsWitch(client) && !IsSpecialCommon(client) && !IsCommonInfected(client)) SpecialsKilled++;
	new Float:i_DamageContribution = 0.0000;
	new Float:DamageContributionRequirement = (1.0 / LivingSurvivorCount());
	//LogMessage("Damage comtribution requirement: %3.3f", DamageContributionRequirement);
	if (DamageContributionRequirement > StringToFloat(GetConfigValue("damage contribution?"))) {

		DamageContributionRequirement = StringToFloat(GetConfigValue("damage contribution?"));
	}

	// If it's a special common, we activate its death abilities.
	if (IsSpecialCommon(client)) {

		// The bomber explosion initially targets itself so that the chain-reaction (if enabled) doesn't go indefinitely.
		if (FindCharInString(GetCommonValue(client, "aura effect?"), 'e') != -1) CreateBomberExplosion(client, client);
	}

	new pos = -1;
	for (new i = 1; i <= MaxClients; i++) {
		
		SurvivorExperience = 0;
		SurvivorPoints = 0.0;
		i_DamageContribution = 0.0000;

		if (!IsLegitimateClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;

		if (!IsWitch(client) && !IsSpecialCommon(client) && !IsCommonInfected(client)) pos = FindListPositionByEntity(client, Handle:InfectedHealth[i]);
		else if (IsWitch(client)) pos = FindListPositionByEntity(client, Handle:WitchDamage[i]);
		else if (IsSpecialCommon(client)) pos = FindListPositionByEntity(client, Handle:SpecialCommon[i]);
		else if (IsCommonInfected(client)) pos = FindListPositionByEntity(client, Handle:CommonInfectedDamage[i]);

		if (pos < 0) continue;

		if (!IsWitch(client) && !IsSpecialCommon(client) && !IsCommonInfected(client)) SurvivorDamage = GetArrayCell(Handle:InfectedHealth[i], pos, 2);
		else if (IsWitch(client)) SurvivorDamage = GetArrayCell(Handle:WitchDamage[i], pos, 2);
		else if (IsSpecialCommon(client)) SurvivorDamage = GetArrayCell(Handle:SpecialCommon[i], pos, 2);
		else if (IsCommonInfected(client)) SurvivorDamage = GetArrayCell(Handle:CommonInfectedDamage[i], pos, 2);

		if (SurvivorDamage > 0) {

			SurvivorExperience = RoundToFloor(SurvivorDamage * ExperienceMultiplier);
			SurvivorPoints = SurvivorDamage * PointsMultiplier;
		}

		i_DamageContribution = CheckTeammateDamages(client, i, true);
		if (i_DamageContribution < DamageContributionRequirement && (HandicapLevel[i] != -1 || StringToInt(GetConfigValue("infected bot level type?")) == 1)) {

			SurvivorExperience = 0;
			SurvivorPoints = 0.0;
		}
		else {

			SurvivorExperience = RoundToFloor(SurvivorDamage * ExperienceMultiplier);
			SurvivorPoints = SurvivorDamage * PointsMultiplier;
		}


		t_Contribution = CheckTankingDamage(client, i);
		if (t_Contribution > 0) {

			t_Contribution = RoundToCeil(t_Contribution * TankingMultiplier);
			SurvivorPoints += (t_Contribution * (PointsMultiplier * TankingMultiplier));
		}
		h_Contribution = CheckHealingAward(client, i);
		if (h_Contribution > 0) {

			h_Contribution = RoundToCeil(h_Contribution * HealingMultiplier);
			SurvivorPoints += (h_Contribution * (PointsMultiplier * HealingMultiplier));
		}
		ReceiveInfectedDamageAward(i, client, SurvivorExperience, SurvivorPoints, t_Contribution, h_Contribution);
		if (!IsWitch(client) && !IsSpecialCommon(client) && !IsCommonInfected(client)) RemoveFromArray(Handle:InfectedHealth[i], pos);
		else if (IsWitch(client)) RemoveFromArray(Handle:WitchDamage[i], pos);
		else if (IsSpecialCommon(client)) RemoveFromArray(Handle:SpecialCommon[i], pos);
		else if (IsCommonInfected(client)) RemoveFromArray(Handle:CommonInfectedDamage[i], pos);
	}
	if (!IsWitch(client) && !IsSpecialCommon(client) && !IsCommonInfected(client)) {

		b_IsHooked[client] = false;
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);

		ForcePlayerSuicide(client);
	}
}

stock ReceiveInfectedDamageAward(client, infected, e_reward, Float:p_reward, t_reward, h_reward) {

	new RPGMode									= StringToInt(GetConfigValue("rpg mode?"));
	//new RPGBroadcast							= StringToInt(GetConfigValue("award broadcast?"));
	new DisplayType								= StringToInt(GetConfigValue("survivor reward display?"));
	decl String:InfectedName[64];
	if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) GetClientName(infected, InfectedName, sizeof(InfectedName));
	else if (IsWitch(infected)) Format(InfectedName, sizeof(InfectedName), "Witch");
	else if (IsSpecialCommon(infected)) Format(InfectedName, sizeof(InfectedName), "%s", GetCommonValue(infected, "name?"));
	else if (IsCommonInfected(infected)) Format(InfectedName, sizeof(InfectedName), "Common");
	Format(InfectedName, sizeof(InfectedName), "%s %s", GetConfigValue("director team name?"), InfectedName);

	new PlayerHandicapBonus				= RoundToFloor(e_reward * (HandicapLevel[client] * StringToFloat(GetConfigValue("handicap experience bonus?"))));
	if (HandicapLevel[client] < 1) PlayerHandicapBonus = 0;
	new RestedAwardBonus = RoundToFloor(e_reward * StringToFloat(GetConfigValue("rested experience multiplier?")));
	if (RestedAwardBonus >= RestedExperience[client]) {

		RestedAwardBonus = RestedExperience[client];
		RestedExperience[client] = 0;
	}
	else if (RestedAwardBonus < RestedExperience[client]) {

		RestedExperience[client] -= RestedAwardBonus;
	}
	new ExperienceBooster = RoundToFloor(e_reward * CheckExperienceBooster(client, e_reward));
	if (ExperienceBooster < 1) ExperienceBooster = 0;

	
	//	0 = Points Only
	//	1 = RPG Only
	//	2 - RPG + Points
	
	if (RPGMode > 0) {

		if (DisplayType > 0 && (IsSpecialCommon(infected) || IsWitch(infected) || IsLegitimateClient(infected))) {								// \x04Jockey \x01killed: \x04 \x03experience

			if (e_reward > 0) PrintToChat(client, "%T", "base experience reward", client, orange, InfectedName, white, green, e_reward, blue);
			if (DisplayType == 2) {

				if (PlayerHandicapBonus > 0) PrintToChat(client, "%T", "handicap experience reward", client, green, white, green, PlayerHandicapBonus, blue);
				if (RestedAwardBonus > 0) PrintToChat(client, "%T", "rested experience reward", client, green, white, green, RestedAwardBonus, blue);
				if (ExperienceBooster > 0) PrintToChat(client, "%T", "booster experience reward", client, green, white, green, ExperienceBooster, blue);
				if (t_reward > 0) PrintToChat(client, "%T", "tanking experience reward", client, green, white, green, t_reward, blue);
				if (h_reward > 0) PrintToChat(client, "%T", "healing experience reward", client, green, white, green, h_reward, blue);
			}
		}
		new TotalExperienceEarned = e_reward + PlayerHandicapBonus + RestedAwardBonus + ExperienceBooster + t_reward + h_reward;
		new Float:ExperienceDebtPenalty = StringToFloat(GetConfigValue("experience debt penalty?"));
		new Float:LowLevelExperience = StringToFloat(GetConfigValue("low level experience bonus?"));

		new LowLevelHandicap = StringToInt(GetConfigValue("low level handicap?"));
 		if (PlayerLevel[client] < LowLevelHandicap) TotalExperienceEarned = RoundToCeil(TotalExperienceEarned * LowLevelExperience);

 		if (ExperienceDebt[client] == 0) {

			ExperienceLevel[client] += TotalExperienceEarned;
			ExperienceOverall[client] += TotalExperienceEarned;
		}
		else {

			ExperienceLevel[client] += RoundToCeil(TotalExperienceEarned * ExperienceDebtPenalty);
			ExperienceOverall[client] += RoundToCeil(TotalExperienceEarned * ExperienceDebtPenalty);
		}

		if (ExperienceDebt[client] > 0) {

			ExperienceDebt[client] -= RoundToCeil(TotalExperienceEarned * ExperienceDebtPenalty);
			if (ExperienceDebt[client] < 0) ExperienceDebt[client] = 0;
		}
		if (ExperienceLevel[client] > CheckExperienceRequirement(client)) {

			ExperienceOverall[client] -= (ExperienceLevel[client] - CheckExperienceRequirement(client));
			ExperienceLevel[client] = CheckExperienceRequirement(client);
		}
		ConfirmExperienceAction(client);
	}
	if (RPGMode != 1 && p_reward > 0.0) {

		Points[client] += p_reward;

		if (DisplayType > 0 && (IsSpecialCommon(infected) || IsWitch(infected) || IsLegitimateClient(infected))) PrintToChat(client, "%T", "points from damage reward", client, green, white, green, p_reward, blue);
	}
	CheckKillPositions(client, true);
}

// Curious RPG System option?
// Points earned from hurting players used to unlock abilities, while experienced earned to increase level determines which abilities a player has access to.
// This way, even if the level is different, everyone starts with the same footing.
// Optional RPG System. Maybe call it "buy rpg mode?"

