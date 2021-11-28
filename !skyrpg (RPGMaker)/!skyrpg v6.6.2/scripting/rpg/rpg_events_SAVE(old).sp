// Every single event in the events.cfg is called by this function, and then sent off to a specific function.
// This way a separate template isn't required for events that have different event names.
public Action:Event_Occurred(Handle:event, String:event_name[], bool:dontBroadcast) {

	if (b_IsSurvivalIntermission) return Plugin_Handled;

	new a_Size						= 0;
	a_Size							= GetArraySize(a_Events);

	decl String:EventName[PLATFORM_MAX_PATH];

	for (new i = 0; i < a_Size; i++) {

		EventSection						= GetArrayCell(a_Events, i, 2);
		GetArrayString(Handle:EventSection, 0, EventName, sizeof(EventName));

		if (StrEqual(EventName, event_name)) {

			if (Call_Event(event, event_name, dontBroadcast, i) == -1) {

				/*if (StrEqual(EventName, "infected_hurt") || StrEqual(EventName, "player_hurt")) {

					

					//	Returns -1 when infected_hurt or player_hurt and the cause of the damage is not a common infected or a player
					//	or if the damage is "inferno" which can be discerned through the player_hurt event only; we have to resort to
					//	the prior for infected_hurt
					

					return Plugin_Handled;
				}*/
			}
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
	if (StrEqual(event_name, "revive_success")) {

		GetAbilityStrengthByTrigger(victim, attacker, 'R', FindZombieClass(victim), 0);
		GetAbilityStrengthByTrigger(attacker, victim, 'r', FindZombieClass(attacker), 0);
	}
	new damagetype = GetEventInt(event, GetKeyValue(CallKeys, CallValues, "damage type?"));

	decl String:weapon[64];
	//decl String:key[64];
	if (StrEqual(event_name, "player_hurt")) {

		GetEventString(event, "weapon", weapon, sizeof(weapon));
		return 0;
		//if (StrEqual(weapon, "inferno") || damagetype == 8 || damagetype == 2056 || damagetype == 268435464) return -1;
	}
	if (StrEqual(event_name, "infected_hurt")) {

		return 0;

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

		//PrintToChatAll("%t", "Experience Gains Disabled", orange, white, orange, white, blue);
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
	//new tagability = StringToInt(GetKeyValue(CallKeys, CallValues, "tag ability?"));
	//new tagexperience = StringToInt(GetKeyValue(CallKeys, CallValues, "tag experience?"));
	//new Float:tagpoints = StringToFloat(GetKeyValue(CallKeys, CallValues, "tag points?"));
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

			GetAbilityStrengthByTrigger(victim, attacker, TargetAbility[i], FindZombieClass(victim), 0);
		}
	}
	if (IsLegitimateClient(attacker) && !StrEqual(ActivatorAbility, "-1", false)) {

		for (new i = 0; i <= strlen(ActivatorAbility); i++) {

			GetAbilityStrengthByTrigger(attacker, victim, ActivatorAbility[i], FindZombieClass(attacker), 0);
		}
	}
	if (IsLegitimateClient(victim) && IsFakeClient(victim) && GetClientTeam(victim) == TEAM_INFECTED) {

		//LogToFile(LogPathDirectory, "%N health set to 40000", victim);
		//if (FindZombieClass(victim) == ZOMBIECLASS_TANK) ExtinguishEntity(victim);
		SetEntityHealth(victim, 400000);
	}
	if (isdamageaward == 1) {

		if (StrEqual(weapon, "spitter_projectile")) LogToFile(LogPathDirectory, "Spitter projectile!");
		if (IsLegitimateClient(attacker) && IsLegitimateClient(victim) && GetClientTeam(attacker) == GetClientTeam(victim)) {

			if (!(damagetype & DMG_BURN) && !StrEqual(weapon, "inferno")) {

				new FFIncrease			= StringToInt(GetConfigValue("survivor friendly fire increase?")) * LivingSurvivors();
				if (!IsIncapacitated(victim) && GetClientHealth(victim) <= FFIncrease) FFIncrease			= GetClientHealth(victim);

				//ReadyUp_NtvFriendlyFire(attacker, victim, (StringToInt(GetConfigValue("survivor friendly fire increase?")) * LivingHumanSurvivors()) + healthvalue, GetClientHealth(victim), 0);
				ReadyUp_NtvFriendlyFire(attacker, victim, healthvalue, GetClientHealth(victim), 0, FFIncrease);

				// damage-based triggers now only occur under the circumstances in the code above. No longer do we have triggers for same-team damaging. Maybe at a later date, but it will not be the same ability trigger.
				GetAbilityStrengthByTrigger(attacker, victim, 'd', FindZombieClass(attacker), healthvalue);
				GetAbilityStrengthByTrigger(victim, attacker, 'l', FindZombieClass(victim), healthvalue);
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
			//LogToFile(LogPathDirectory, "%N health set to 40000", victim);
			//if (FindZombieClass(victim) == ZOMBIECLASS_TANK) ExtinguishEntity(victim);
			SetEntityHealth(victim, 400000);
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

			/*if (IsLegitimateClientAlive(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && IsIncapacitated(attacker)) {

				GetAbilityStrengthByTrigger(attacker, attacker, 'k', FindZombieClass(attacker), 0);
			}*/
			if (IsFakeClient(victim)) b_IsImmune[victim] = false;
			if (ReadyUp_GetGameMode() == 2) {

				// Versus, do tanks have a cooldown?
				if (FindZombieClass(victim) == ZOMBIECLASS_TANK && StringToFloat(GetConfigValue("versus tank cooldown?")) > 0.0 && f_TankCooldown == -1.0) {

					f_TankCooldown				=	StringToFloat(GetConfigValue("versus tank cooldown?"));

					CreateTimer(1.0, Timer_TankCooldown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			else {

				if (FindZombieClass(victim) == ZOMBIECLASS_TANK && StringToFloat(GetConfigValue("director tank cooldown?")) > 0.0 && f_TankCooldown == -1.0) {

					f_TankCooldown				=	StringToFloat(GetConfigValue("director tank cooldown?"));

					CreateTimer(1.0, Timer_TankCooldown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			CalculateInfectedDamageAward(victim);
		}
	}
	if (isshoved == 1 && IsLegitimateClientAlive(victim) && IsLegitimateClientAlive(attacker) && GetClientTeam(victim) != GetClientTeam(attacker)) {

		if (GetClientTeam(victim) == TEAM_INFECTED) SetEntityHealth(victim, GetClientHealth(victim) + healthvalue);

		GetAbilityStrengthByTrigger(victim, attacker, 'H', FindZombieClass(victim), 0);
	}
	if (bulletimpact == 1) {

		if (IsLegitimateClientAlive(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR) {

			new Float:Coords[3];
			Coords[0] = GetEventFloat(event, "x");
			Coords[1] = GetEventFloat(event, "y");
			Coords[2] = GetEventFloat(event, "z");

			if (StringToInt(GetConfigValue("special ammo requires target?")) == 0 && HasSpecialAmmo(attacker) && IsSpecialAmmoEnabled[attacker][0] == 1.0) {

 				new StaminaCost = RoundToCeil(GetSpecialAmmoStrength(attacker, ActiveSpecialAmmo[attacker], 2));
 				if (SurvivorStamina[attacker] >= StaminaCost) {

 					//if (CheckActiveAmmoCooldown(attacker, ActiveSpecialAmmo[attacker]) == 1) {
 					if (!IsAmmoActive(attacker, ActiveSpecialAmmo[attacker])) {
	 				//if (CreateActiveTime(attacker, ActiveSpecialAmmo[attacker], GetSpecialAmmoStrength(attacker, ActiveSpecialAmmo[attacker])) == 1) {

	 					if (TriggerSpecialAmmo(attacker, -1, LastWeaponDamage[attacker], GetSpecialAmmoStrength(attacker, ActiveSpecialAmmo[attacker]), GetSpecialAmmoStrength(attacker, ActiveSpecialAmmo[attacker], 4), Coords[0], Coords[1], Coords[2])) {
	 					
		 					SurvivorStamina[attacker] -= StaminaCost;
							if (SurvivorStamina[attacker] <= 0) {

								bIsSurvivorFatigue[attacker] = true;
								IsSpecialAmmoEnabled[attacker][0] = 0.0;
							}
						}
	 				}
	 			}
 			}

			if (StringToInt(GetConfigValue("trails enabled?")) == 1) {

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
	}
	/*if (StrEqual(EventName, "player_team")) {

		if (IsLegitimateClient(attacker) && !IsFakeClient(attacker)) CreateTimer(1.0, Timer_SwitchTeams, attacker, TIMER_FLAG_NO_MAPCHANGE);
	}*/
	if (StrEqual(EventName, "player_spawn")) {

		if (IsLegitimateClient(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR) {

			RefreshSurvivor(attacker);
			//SDKHook(attacker, SDKHook_OnTakeDamage, OnTakeDamage);
		}
		if (IsLegitimateClient(attacker) && !IsFakeClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED) {

			PlayerSpawnAbilityTrigger(attacker);
		}
		if (IsLegitimateClient(attacker) && GetClientTeam(attacker) == TEAM_INFECTED && IsFakeClient(attacker)) {

			//new TheLiving = LivingSurvivors();
			//new TheDead = LivingInfected();

			if (StringToInt(GetConfigValue("no handicap no specials mode?")) == 1 && LivingSurvivors() < StringToInt(GetConfigValue("no specials survivors required?")) && !SurvivorsHaveHandicap()) {

				if (LivingInfected() > 0) LivingInfected(true);
			}

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
			if (FindZombieClass(attacker) == ZOMBIECLASS_TANK) t_InfectedHealth = 10000;
			else if (FindZombieClass(attacker) == ZOMBIECLASS_HUNTER || FindZombieClass(attacker) == ZOMBIECLASS_SMOKER) t_InfectedHealth = 200;
			else if (FindZombieClass(attacker) == ZOMBIECLASS_BOOMER) t_InfectedHealth = 50;
			else if (FindZombieClass(attacker) == ZOMBIECLASS_SPITTER) t_InfectedHealth = 100;
			else if (FindZombieClass(attacker) == ZOMBIECLASS_CHARGER) t_InfectedHealth = 600;
			else if (FindZombieClass(attacker) == ZOMBIECLASS_JOCKEY) t_InfectedHealth = 300;

			Format(s_InfectedHealth, sizeof(s_InfectedHealth), "(%d) infected health bonus", FindZombieClass(attacker));
			for (new i = 1; i <= MaxClients; i++) {

				if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

					//t_InfectedHealth = GetClientHealth(attacker);

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
				//GetAbilityStrengthByTrigger(attacker, 0, 'A', FindZombieClass(attacker), healthvalue);
				GetAbilityStrengthByTrigger(attacker, _, 'A', FindZombieClass(attacker), healthvalue);	// activator, target, trigger ability, effects, zombieclass, damage
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

			/*//ReadyUp_NtvFriendlyFire(attacker, victim, 0 - GetReviveHealth(), GetClientHealth(victim), 0, 0);

			// The SetTempHealth will call the revive talent triggers, which will then set a different temporary health if necessary.
			// However we set the initial, and I believe by default the plugin will run with 30% (Valve default) true = onRevive.
			SetTempHealth(attacker, victim, GetMaximumHealth(victim) * StringToFloat(GetConfigValue("survivor revive health?")), true);

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
			}*/
		}
	}
	if (StrEqual(EventName, "player_incapacitated") && IsLegitimateClient(victim)) {

		if (GetClientTeam(victim) == TEAM_SURVIVOR) {

			RoundIncaps[victim]++;

			if (L4D2_GetInfectedAttacker(victim) == -1) GetAbilityStrengthByTrigger(victim, attacker, 'n', FindZombieClass(victim), healthvalue);
			else {							
				
				//CreateTimer(1.0, Timer_IsIncapacitated, victim, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				GetAbilityStrengthByTrigger(victim, attacker, 'N', FindZombieClass(victim), healthvalue);
				if (L4D2_GetInfectedAttacker(victim) == attacker) GetAbilityStrengthByTrigger(attacker, victim, 'm', FindZombieClass(attacker), healthvalue);
				else GetAbilityStrengthByTrigger(victim, L4D2_GetInfectedAttacker(victim), 'm', FindZombieClass(victim), healthvalue);
			}
		}
	}
	/*	DEPRECATED v0.9 events hooks not used anymore.
	//if (IsLegitimateClient(attacker)) {

		if (tagability == 1 && IsLegitimateClientAlive(victim) && !IsCoveredInVomit(victim, attacker)) {

			if (IsLegitimateClient(attacker) && attacker > 0) GetAbilityStrengthByTrigger(attacker, victim, 'i', FindZombieClass(attacker), 0);
			if (IsLegitimateClient(victim) && victim > 0) GetAbilityStrengthByTrigger(victim, attacker, 'I', FindZombieClass(victim), 0);
		}
		if (tagability == 2 && IsLegitimateClientAlive(attacker) && IsCoveredInVomit(attacker)) {

			if (IsLegitimateClient(attacker) && attacker > 0) GetAbilityStrengthByTrigger(attacker, attacker, 'b', FindZombieClass(attacker), 0);
		}
	}*/
	return 0;
}

stock bool:IsCoveredInVomit(client, owner=0) {

	new size = GetArraySize(Handle:CoveredInVomit);
	decl String:text[512];
	decl String:result[2][64];
	decl String:key[64];
	GetClientAuthString(client, key, sizeof(key));
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:CoveredInVomit, i, text, sizeof(text));
		ExplodeString(text, "}", result, 2, 64);
		if (StrEqual(result[0], key, false)) {

			if (owner > 0) return true;
			RemoveFromArray(Handle:CoveredInVomit, i);
			if (i > 0) i--;
			continue;
		}
	}
	if (owner > 0) {

		/*

			If we just want to find out whether the player is biled on, say for status effects
			then we don't want to push if the owner IS the client.
			This way, if the client exists, it'll return true, but if they don't, it'll return false
			without adding them.
		*/
		if (owner != client) {

			Format(text, sizeof(text), "%s}%d", key, owner);
			PushArrayString(Handle:CoveredInVomit, text);
		}
	}
	return false;		// this ONLY occurs if no owner is specified, ie it clears the client everywhere in the array.
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

			GetAbilityStrengthByTrigger(client, victim, 'v', FindZombieClass(client), 0);
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
stock bool:HasSpecialAmmo(client) {

	decl String:TalentName[64];
	new ArraySize = GetArraySize(a_Menu_Talents);
	for (new i = 0; i < ArraySize; i++) {

		SpecialAmmoKeys[client]		= GetArrayCell(a_Menu_Talents, i, 0);
		SpecialAmmoValues[client]	= GetArrayCell(a_Menu_Talents, i, 1);
		SpecialAmmoSection[client]	= GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(Handle:SpecialAmmoSection[client], 0, TalentName, sizeof(TalentName));

		if (StringToInt(GetKeyValue(SpecialAmmoKeys[client], SpecialAmmoValues[client], "special ammo?")) == 0) continue;
		if ((GetTalentStrength(client, TalentName) * 1.0) <= 0.0) continue;

		return true;
	}
	return false;
}

stock bool:GetActiveSpecialAmmoType(client, effect) {

	decl String:EffectT[4];
	Format(EffectT, sizeof(EffectT), "%c", effect);

	if (StrContains(GetSpecialAmmoEffect(client, ActiveSpecialAmmo[client]), EffectT, true) != -1) return true;
	return false;
}

/*

	Checks whether a player is within range of a special ammo, and if they are, how affected they are.
	GetStatusOnly is so we know whether to start the revive bar for revive ammo, without triggering the actual effect, we just want to know IF they're affected, for example.
	If ammoposition is >= 0 AND GetStatus is enabled, it will return only for the ammo in question.
*/

stock Float:IsClientInRangeSpecialAmmo(client, effect, bool:GetStatusOnly=true, AmmoPosition=-1, Float:baseeffectvalue=0.0, realowner=0) {

	decl String:text[512];
	decl String:result[6][512];
	decl String:t_pos[3][64];
	new Float:EntityPos[3];
	decl String:TalentInfo[4][512];
	new owner = 0;
	new pos = -1;
	//decl String:newvalue[10];

	decl String:value[64];
	//new Float:f_Strength = 0.0;
	//decl String:t_effect[4];

	new Float:EffectStrength = 0.0;
	new Float:EffectStrengthBonus = 0.0;

	new Float:ClientPos[3];
	decl String:EffectT[4];
	if (IsLegitimateClient(client)) GetClientAbsOrigin(client, ClientPos);
	else if (IsCommonInfected(client) || IsWitch(client)) GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);

	new Float:t_Range	= 0.0;

	new size = GetArraySize(SpecialAmmoData);
	if (size < 1) return 0.0;
	Format(EffectT, sizeof(EffectT), "%c", effect);
	for (new i = AmmoPosition; i < size; i++) {

		if (i < 0) i = 0;
		if (AmmoPosition != -1 && i != AmmoPosition) return 0.0;

		GetArrayString(Handle:SpecialAmmoData, i, text, sizeof(text));
		ExplodeString(text, "}", result, 6, 512);

		ExplodeString(result[0], " ", t_pos, 5, 512);
		EntityPos[0] = StringToFloat(t_pos[0]);
		EntityPos[1] = StringToFloat(t_pos[1]);
		EntityPos[2] = StringToFloat(t_pos[2]);
		ExplodeString(result[1], "{", TalentInfo, 4, 512);
		// TalentInfo[0] = TalentName of ammo.
		// TalentInfo[1] = Talent Strength (so use StringToInt)
		// TalentInfo[2] = Talent Damage
		// TalentInfo[3] = Talent Interval
		owner = FindClientWithAuthString(result[2]);
		//if (AmmoPosition == -1 && StringToFloat(TalentInfo[3]) > 0.0) continue;
		//if (StringToFloat(TalentInfo[3]) > 0.0) continue;
		if (!IsLegitimateClientAlive(owner) || GetClientTeam(owner) != TEAM_SURVIVOR || StringToFloat(TalentInfo[3]) <= 0.0) continue;
		if (GetSpecialAmmoStrength(owner, TalentInfo[0], 3) == -1.0) continue;
		t_Range		= GetSpecialAmmoStrength(owner, TalentInfo[0], 3);
		if (GetVectorDistance(ClientPos, EntityPos) > (t_Range / 2)) continue;
		pos			= GetMenuPosition(owner, TalentInfo[0]);
		IsClientInRangeSAKeys[owner]				= GetArrayCell(a_Menu_Talents, pos, 0);
		IsClientInRangeSAValues[owner]				= GetArrayCell(a_Menu_Talents, pos, 1);
		Format(value, sizeof(value), "%s", GetKeyValue(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "ammo effect?"));
		if (StrContains(value, EffectT, true) == -1) continue;
		if (!IsCommonInfected(client) && !IsLegitimateClientAlive(client) && StringToInt(GetKeyValue(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "humanoid only?")) == 1) continue;
		if ((IsCommonInfected(client) || IsLegitimateClientAlive(client)) && StringToInt(GetKeyValue(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "inanimate only?")) == 1) continue;
		if (StringToInt(GetKeyValue(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "allow commons?")) == 0 && IsCommonInfected(client) ||
			StringToInt(GetKeyValue(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "allow specials?")) == 0 && IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_INFECTED ||
			StringToInt(GetKeyValue(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "allow survivors?")) == 0 && IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR) continue;
		if (GetStatusOnly) {

			//LogMessage("Entity %d in range of ammo %c", client, effect);
			return -2.0;		// -2.0 is a special designation.
		}

		if (realowner == 0 || realowner == owner) {

			if (EffectStrengthBonus == 0.0) {

				EffectStrength += StringToFloat(GetKeyValue(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "effect strength?"));
				EffectStrengthBonus = StringToFloat(GetKeyValue(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "effect multiplier?"));
			}
			else {

				EffectStrength += (StringToFloat(GetKeyValue(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "effect strength?")) * EffectStrengthBonus);
				EffectStrengthBonus *= StringToFloat(GetKeyValue(IsClientInRangeSAKeys[owner], IsClientInRangeSAValues[owner], "effect multiplier?"));
			}
		}
		if (AmmoPosition != -1) break;
		size = GetArraySize(SpecialAmmoData);
	}
	if (baseeffectvalue > 0.0) {

		/*

			Award the user who has buffed a player.
		*/
		if (StrContains(EffectT, "d", true) != -1 ||
			StrContains(EffectT, "D", true) != -1 ||
			StrContains(EffectT, "R", true) != -1) AwardExperience(owner, 2, RoundToCeil(baseeffectvalue * EffectStrength));//reflective ammo.
		if (StrContains(EffectT, "F", true) != -1) AwardExperience(owner, 3, RoundToCeil(baseeffectvalue * EffectStrength));
	}
	return EffectStrength;
}

public Action:Timer_AmmoTriggerCooldown(Handle:timer, any:client) {

	if (IsLegitimateClient(client)) AmmoTriggerCooldown[client] = false;
	return Plugin_Stop;
}

/*

	When special ammo conditions are met, call the trigger.
*/
stock bool:TriggerSpecialAmmo(client, target, TotalDamage, Float:f_ActiveTime, Float:f_Interval, Float:PosX=0.0, Float:PosY=0.0, Float:PosZ=0.0) {

	if (!b_IsActiveRound) return false;
	//if (f_Interval < 0.0) return false;
	if (IsAmmoActive(client, ActiveSpecialAmmo[client])) return false;
	if (AmmoTriggerCooldown[client]) return false;
	//if (IsPlayerUsingShotgun(client)) {

	AmmoTriggerCooldown[client] = true;
	decl String:Name[MAX_NAME_LENGTH];
	CreateTimer(0.1, Timer_AmmoTriggerCooldown, client, TIMER_FLAG_NO_MAPCHANGE);
	//}

	//	For special ammos that have an active time, create a new position in dynamic array, insert the targets position and the active time.
	//	When the engine time is >= the active time, we remove the item from the list and players are no longer affected by it.
	//	This seems better than creating actual entities. Remember we only got here if the ammo wasn't on cooldown and it was a legitimate target so we make it here.
	new Float:TargetPos[3];
	new targetClientId = -1;
	if (!IsLegitimateClientAlive(target) && !IsCommonInfected(target) && !IsWitch(target)) target = -1;
	else {	// If the target exists (only when a talent calls it) we want to spawn it on their position.

		if (IsCommonInfected(target) || IsWitch(target)) GetEntPropVector(target, Prop_Send, "m_vecOrigin", TargetPos);
		else GetClientAbsOrigin(target, TargetPos);

		PosX = TargetPos[0];
		PosY = TargetPos[1];
		PosZ = TargetPos[2];
		if (IsLegitimateClientAlive(target) && !IsFakeClient(target)) {

			GetClientName(target, Name, sizeof(Name));
			PrintToChat(client, "%T", "special ammo target selected", client, orange, green, Name);
			GetClientName(client, Name, sizeof(Name));
			PrintToChat(target, "%T", "special ammo targeted", target, orange, green, Name);
		}
	}

	if (IsLegitimateClientAlive(LastTarget[client])) targetClientId = LastTarget[client];

	if (!IsAmmoActive(client, ActiveSpecialAmmo[client])) IsAmmoActive(client, ActiveSpecialAmmo[client], f_ActiveTime);

	new WorldEnt = -1;

	if (StrContains(GetSpecialAmmoEffect(client, ActiveSpecialAmmo[client]), "g", true) != -1) {

		/*

			Some ammos, like gravity ammo, create actual entities. as such, we create them here.
		*/
		WorldEnt = CreateGravityAmmo(client, GetSpecialAmmoStrength(client, ActiveSpecialAmmo[client], 5), GetSpecialAmmoStrength(client, ActiveSpecialAmmo[client], 3));
	}

	// Because client ids change, we store steamid of owner.
	decl String:key[64];
	GetClientAuthString(client, key, sizeof(key));
	//LogMessage(SpecialAmmoData_s);
	//CheckActiveAmmoCooldown(client, ActiveSpecialAmmo[client], true);
	//LogMessage("Storing ammo point info : %s", SpecialAmmoData_s);

	decl String:TalentName[64];
	Format(TalentName, sizeof(TalentName), "%s", ActiveSpecialAmmo[client]);
	new ClientMenuPosition = GetMenuPosition(client, TalentName);

	DrawSpecialAmmoTarget(client, _, _, ClientMenuPosition, PosX, PosY, PosZ, f_Interval, client, ActiveSpecialAmmo[client]);
	if (IsLegitimateClientAlive(targetClientId) && !IsFakeClient(targetClientId)) DrawSpecialAmmoTarget(client, _, _, ClientMenuPosition, PosX, PosY, PosZ, f_Interval, client, ActiveSpecialAmmo[client]);

	decl String:SpecialAmmoData_s[512];
	Format(SpecialAmmoData_s, sizeof(SpecialAmmoData_s), "%3.3f %3.3f %3.3f}%s{%d{%d{%3.2f}%s}%3.2f}%d}%3.2f}%d", PosX, PosY, PosZ, ActiveSpecialAmmo[client], GetTalentStrength(client, ActiveSpecialAmmo[client]), TotalDamage, GetSpecialAmmoStrength(client, ActiveSpecialAmmo[client], 4), key, GetSpecialAmmoStrength(client, ActiveSpecialAmmo[client]), WorldEnt, GetSpecialAmmoStrength(client, ActiveSpecialAmmo[client], 1), targetClientId);
	PushArrayString(Handle:SpecialAmmoData, SpecialAmmoData_s);
	return true;
}

public Action:Timer_SpecialAmmoData(Handle:timer) {

	if (!b_IsActiveRound || b_IsSurvivalIntermission) {

		ClearArray(Handle:SpecialAmmoData);
		return Plugin_Stop;
	}

	decl String:text[512];
	decl String:result[7][512];
	decl String:t_pos[3][512];
	new Float:EntityPos[3];
	//new Float:TargetPos[3];
	decl String:TalentInfo[4][512];
	new client = 0;
	new Float:f_TimeRemaining = 0.0;
	new Float:f_Interval = 0.0;
	new Float:f_Cooldown = 0.0;
	new size = GetArraySize(SpecialAmmoData);
	new WorldEnt = -1;
	new ent = -1;
	decl String:SpecialAmmoEffect[55];
	new drawtarget = -1;
	new ammotarget = -1;
	new Float:RangeRequired = 0.0;
	new Float:TheOrigin[3];
	decl String:Name[64];
	new ii = -1;
	new nextpos = -1;
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:SpecialAmmoData, i, text, sizeof(text));
		//LogMessage("Original: %s", text);
		ExplodeString(text, "}", result, 7, 512);

		ExplodeString(result[0], " ", t_pos, 3, 512);
		EntityPos[0] = StringToFloat(t_pos[0]);
		EntityPos[1] = StringToFloat(t_pos[1]);
		EntityPos[2] = StringToFloat(t_pos[2]);

		ExplodeString(result[1], "{", TalentInfo, 4, 512);
		// TalentInfo[0] = TalentName of ammo.
		// TalentInfo[1] = Talent Strength (so use StringToInt)
		// TalentInfo[2] = Talent Damage
		// TalentInfo[3] = Talent Interval
		f_Interval = StringToFloat(TalentInfo[3]);

		client = FindClientWithAuthString(result[2]);
		//f_Interval -= 0.01;

		f_TimeRemaining = StringToFloat(result[3]);
		//f_TimeRemaining -= 0.01;

		WorldEnt = StringToInt(result[4]);
		f_Cooldown = StringToFloat(result[5]);
		drawtarget = StringToInt(result[6]);

		if (!IsLegitimateClientAlive(client) || GetClientTeam(client) != TEAM_SURVIVOR) {

			RemoveFromArray(Handle:SpecialAmmoData, i);
			//if (i > 0) i--;
			size = GetArraySize(SpecialAmmoData);
			//if (IsLegitimateClientAlive(client) && GetClientTeam(client) == TEAM_SURVIVOR) CheckActiveAmmoCooldown(client, TalentInfo[0], true);// should the cooldown start when the first bullet expires, or when the first bullets first cooldown(interval) occurs? need to calculate. is it too spammy?
			if (IsValidEntity(WorldEnt)) AcceptEntityInput(WorldEnt, "Kill");
			continue;
		}
		if (f_Interval > 0.00) {

			f_Interval -= 0.25;
			Format(SpecialAmmoEffect, sizeof(SpecialAmmoEffect), "%s", GetSpecialAmmoEffect(client, TalentInfo[0]));

			if (IsClientInRangeSpecialAmmo(client, 'b', _, i) == -2.0) {// && (GetEntityFlags(i) & FL_ONGROUND)) {

				BeanBagAmmo(client, IsClientInRangeSpecialAmmo(client, 'b', false), i);
			}
			if (IsClientInRangeSpecialAmmo(client, 'a', _, i) == -2.0 && !HasAdrenaline(client)) {

				SetAdrenalineState(client, f_Interval);
			}
			if (IsClientInRangeSpecialAmmo(client, 'x', _, i) == -2.0) {

				ExplosiveAmmo(client, RoundToCeil((IsClientInRangeSpecialAmmo(client, 'x', false, i)) * StringToInt(TalentInfo[2])), client);
			}
			if (IsClientInRangeSpecialAmmo(client, 'H', _, i) == -2.0) {

				HealingAmmo(client, RoundToCeil((IsClientInRangeSpecialAmmo(client, 'H', false, i)) * StringToInt(TalentInfo[2])), client);
			}
			if (IsClientInRangeSpecialAmmo(client, 'F', _, i) == -2.0) {

				if (ISEXPLODE[client] == INVALID_HANDLE) CreateAndAttachFlame(client, RoundToCeil((IsClientInRangeSpecialAmmo(client, 'F', false, i)) * StringToInt(TalentInfo[2])), f_TimeRemaining, f_Interval);
 				else if (ISEXPLODE[client] != INVALID_HANDLE) CreateAndAttachFlame(client, RoundToCeil(((IsClientInRangeSpecialAmmo(client, 'F', false, i)) * StringToInt(TalentInfo[2])) * StringToFloat(GetConfigValue("scorch multiplier?"))), f_TimeRemaining, f_Interval);
			}
			if (IsClientInRangeSpecialAmmo(client, 'B', _, i) == -2.0 && !IsCoveredInVomit(client, client)) {

				SDKCall(g_hCallVomitOnPlayer, client, client, true);
			}
			if (IsLegitimateClientAlive(drawtarget)) {

				if (IsClientInRangeSpecialAmmo(drawtarget, 'b', _, i) == -2.0) {// && (GetEntityFlags(i) & FL_ONGROUND)) {

					BeanBagAmmo(drawtarget, IsClientInRangeSpecialAmmo(drawtarget, 'b', false, i), i);
				}
				if (IsClientInRangeSpecialAmmo(drawtarget, 'a', _, i) == -2.0 && !HasAdrenaline(drawtarget)) {

					SetAdrenalineState(drawtarget, f_Interval);
				}
				if (IsClientInRangeSpecialAmmo(drawtarget, 'x', _, i) == -2.0) {

					ExplosiveAmmo(drawtarget, RoundToCeil((IsClientInRangeSpecialAmmo(drawtarget, 'x', false, i)) * StringToInt(TalentInfo[2])), client);
				}
				if (IsClientInRangeSpecialAmmo(drawtarget, 'H', _, i) == -2.0 && GetClientTeam(drawtarget) == GetClientTeam(client)) {

					HealingAmmo(drawtarget, RoundToCeil((IsClientInRangeSpecialAmmo(drawtarget, 'H', false, i)) * StringToInt(TalentInfo[2])), client);
				}
				if (IsClientInRangeSpecialAmmo(drawtarget, 'h', _, i) == -2.0 && drawtarget != client) {

					LeechAmmo(drawtarget, RoundToCeil((IsClientInRangeSpecialAmmo(drawtarget, 'h', false, i)) * StringToInt(TalentInfo[2])), client);	// if teammates enter leech ammo, they lose health and their teammate that owns the ammo takes it from them. combine with healing ammo!
				}
				if (IsClientInRangeSpecialAmmo(drawtarget, 'F', _, i) == -2.0) {

					if (ISEXPLODE[drawtarget] == INVALID_HANDLE) CreateAndAttachFlame(drawtarget, RoundToCeil((IsClientInRangeSpecialAmmo(drawtarget, 'F', false, i)) * StringToInt(TalentInfo[2])), f_TimeRemaining, f_Interval);
	 				else if (ISEXPLODE[drawtarget] != INVALID_HANDLE) CreateAndAttachFlame(drawtarget, RoundToCeil(((IsClientInRangeSpecialAmmo(drawtarget, 'F', false, i)) * StringToInt(TalentInfo[2])) * StringToFloat(GetConfigValue("scorch multiplier?"))), f_TimeRemaining, f_Interval);
				}
				if (IsClientInRangeSpecialAmmo(drawtarget, 'B', _, i) == -2.0 && !IsCoveredInVomit(drawtarget, client)) {

					SDKCall(g_hCallVomitOnPlayer, drawtarget, client, true);
				}
				if (IsClientInRangeSpecialAmmo(drawtarget, 'C', _, i) == -2.0 && !IsPlayerFeeble(drawtarget) && IsClientInRangeSpecialAmmo(drawtarget, 'W', false, i) != -2.0 && drawtarget != client) {
	
					//	the player is inside cleansing ammo, but they're not inside darkness ammo and don't have the feeble debuff.
					//	Since they're not in the darkness ammo, they don't have holy.
					//	We need to find out if they have weakness; if they don't, we cleanse a debuff if they have any.
					
					if (IsClientStatusEffect(drawtarget, Handle:EntityOnFire)) {

						TransferStatusEffect(drawtarget, Handle:EntityOnFire, client);
					}
				}
			}
			if (StrContains(SpecialAmmoEffect, "x", true) != -1) {

				/*

					Explosive ammo. Boom!
				*/
				CreateAmmoExplosion(client, EntityPos[0], EntityPos[1], EntityPos[2]);
				continue;
			}
			/*if (StrContains(SpecialAmmoEffect, "x", true) != -1 ||
				StrContains(SpecialAmmoEffect, "h", true) != -1 ||
				StrContains(SpecialAmmoEffect, "F", true) != -1) {

				for (new iii = 0; iii < GetArraySize(Handle:CommonInfected) && IsLegitimateClientAlive(client); iii++) {

					ent = GetArrayCell(Handle:CommonInfected, iii);
					if (!IsSpecialCommon(ent)) continue;

					if (IsClientInRangeSpecialAmmo(ent, 'x', _, i) == -2.0) {

						ExplosiveAmmo(ent, RoundToCeil((IsClientInRangeSpecialAmmo(ent, 'x', false)) * StringToInt(TalentInfo[2])), client);
						break;
					}
					if (IsClientInRangeSpecialAmmo(ent, 'h', _, i) == -2.0) {

						LeechAmmo(ent, RoundToCeil((IsClientInRangeSpecialAmmo(ent, 'h', false)) * StringToInt(TalentInfo[2])), client);
						break;
					}
					if (IsClientInRangeSpecialAmmo(ent, 'F', _, i) == -2.0) {

						CreateAndAttachFlame(ent, RoundToCeil((IsClientInRangeSpecialAmmo(ent, 'F', false)) * StringToInt(TalentInfo[2])), f_TimeRemaining, f_Interval);
						break;
					}
				}
			}*/
		}
		else if (f_Cooldown <= 0.00) {

			f_Interval = GetSpecialAmmoStrength(client, TalentInfo[0], 4);
			f_Cooldown = GetSpecialAmmoStrength(client, TalentInfo[0], 1);
			//if (!IsAmmoActive(client, TalentInfo[0])) IsAmmoActive(client, TalentInfo[0], f_TimeRemaining);
			if (IsLegitimateClientAlive(client)) DrawSpecialAmmoTarget(client, _, _, GetMenuPosition(client, TalentInfo[0]), EntityPos[0], EntityPos[1], EntityPos[2], f_Interval, client, TalentInfo[0]);
			if (IsLegitimateClientAlive(drawtarget)) DrawSpecialAmmoTarget(drawtarget, _, _, GetMenuPosition(client, TalentInfo[0]), EntityPos[0], EntityPos[1], EntityPos[2], f_Interval, client, TalentInfo[0]);
		}
		else f_Cooldown -= 0.25;

		if (f_TimeRemaining <= 0.00) {

			RemoveFromArray(Handle:SpecialAmmoData, i);
			//if (i > 0) i--;
			size = GetArraySize(SpecialAmmoData);
			if (IsValidEntity(WorldEnt)) AcceptEntityInput(WorldEnt, "Kill");
			continue;
		}
		f_TimeRemaining -= 0.25;
		Format(text, sizeof(text), "%3.3f %3.3f %3.3f}%s{%d{%d{%3.2f}%s}%3.2f}%d}%3.2f}%d", EntityPos[0], EntityPos[1], EntityPos[2], TalentInfo[0], GetTalentStrength(client, TalentInfo[0]), StringToInt(TalentInfo[2]), f_Interval, result[2], f_TimeRemaining, WorldEnt, f_Cooldown, drawtarget);
		SetArrayString(Handle:SpecialAmmoData, i, text);
		//LogMessage(text);
		size = GetArraySize(Handle:SpecialAmmoData);
	}
	return Plugin_Continue;
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
stock DrawSpecialAmmoTarget(TargetClient, bool:IsDebugMode=false, bool:IsValidTarget=false, CurrentPosEx=-1, Float:PosX=0.0, Float:PosY=0.0, Float:PosZ=0.0, Float:f_ActiveTime=0.0, owner=0, String:TalentName[]="none") {		// If we aren't actually drawing..? Stoned idea lost in thought but expanded somewhat not on the original path

	new client = TargetClient;
	if (owner != 0) client = owner;

	new CurrentPos	= -1;//CycleSpecialAmmo(client, _, true);			// This multi-purposes the function and the middle argument is irrelevent.
	new Target		= GetClientAimTarget(client, false);

	if (CurrentPosEx == -1) CurrentPos = CycleSpecialAmmo(client, _, true);
	if (CurrentPosEx >= 0) CurrentPos = CurrentPosEx;
	else if (Target == -1) return -1;
	if (CurrentPos == -1) {

		//LogMessage("Can't draw special ammo target, index is -1");
		return -1;
	}
	new bool:i_IsDebugMode = false;

	if (CurrentPosEx == -1) {

		DrawSpecialAmmoKeys[client]		= GetArrayCell(a_Menu_Talents, CurrentPos, 0);
		DrawSpecialAmmoValues[client]	= GetArrayCell(a_Menu_Talents, CurrentPos, 1);

		if (StringToInt(GetKeyValue(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "humanoid only?")) == 1) {

			

			//Humanoid Only could apply to a wide-range so we break it down here.
			if (!IsCommonInfected(Target) && !IsLegitimateClientAlive(Target)) i_IsDebugMode = true;
		}
		if (StringToInt(GetKeyValue(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "inanimate only?")) == 1) {

			//This is things like vehicles, dumpsters, and other objects that can one-shot your teammates.
			if (IsCommonInfected(Target) || IsLegitimateClientAlive(Target)) i_IsDebugMode = true;
		}
		if (StringToInt(GetKeyValue(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "allow commons?")) == 0 && IsCommonInfected(Target) ||
			StringToInt(GetKeyValue(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "allow specials?")) == 0 && IsLegitimateClientAlive(Target) && GetClientTeam(Target) == TEAM_INFECTED ||
			StringToInt(GetKeyValue(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "allow survivors?")) == 0 && IsLegitimateClientAlive(Target) && GetClientTeam(Target) == TEAM_SURVIVOR) i_IsDebugMode = true;

		if (i_IsDebugMode && !IsDebugMode) return 0;		// ie if an invalid target is highlighted and debug mode is disabled we don't draw and we don't tell the player anything.
		if (IsValidTarget) {

			if (i_IsDebugMode) return 0;
			else return 1;
		}
	}
	new TalentStrength		= 0;
	if (owner == 0) TalentStrength = GetTalentStrength(client, ActiveSpecialAmmo[client]);
	else TalentStrength = GetTalentStrength(client, TalentName);

	new Float:AfxRange		= StringToFloat(GetKeyValue(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "range first point value?"));
	new Float:AfxRangeInc	= StringToFloat(GetKeyValue(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "range per point?")) * (TalentStrength - 1);

	decl String:AfxDrawPos[64];
	decl String:AfxDrawColour[64];
	Format(AfxDrawPos, sizeof(AfxDrawPos), "%s", GetKeyValue(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "draw pos?"));
	if (IsDebugMode) Format(AfxDrawColour, sizeof(AfxDrawColour), "%s", GetKeyValue(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "invalid target colour?"));
	else Format(AfxDrawColour, sizeof(AfxDrawColour), "%s", GetKeyValue(DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "valid target colour?"));
	// If the above two fields return -1 (meaning they are omitted) we assume it is a single-target-only ability.

	if (StrEqual(AfxDrawColour, "-1", false)) return -1;		// if there's no colour, we return otherwise you'll get errors like this: TE_Send Exception reported: No TempEntity call is in progress (return 0 here would cause endless loop set to -1 as it is ignored i broke the golden rule lul)
	if (CurrentPosEx != -1) {

		CreateRingSolo(-1, AfxRange + AfxRangeInc, AfxDrawColour, AfxDrawPos, false, f_ActiveTime, TargetClient, PosX, PosY, PosZ);
	}
	else {

		CreateRingSolo(Target, AfxRange + AfxRangeInc, AfxDrawColour, AfxDrawPos, false, StringToFloat(GetConfigValue("special ammo highlight time?")), TargetClient);
		IsSpecialAmmoEnabled[client][3] = Target * 1.0;
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
		if (StringToInt(GetKeyValue(SpecialAmmoKeys[client], SpecialAmmoValues[client], "special ammo?")) != 1) continue;
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
		if (StringToInt(GetKeyValue(SpecialAmmoKeys[client], SpecialAmmoValues[client], "special ammo?")) != 1) continue;
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

	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	if (NahDestroyItInstead) SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	else {

		new Float:TheRealTime = TheTime;
		if (!NoAdrenaline && HasAdrenaline(client)) TheRealTime *= StringToFloat(GetConfigValue("adrenaline progress multiplier?"));

		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", TheRealTime);
		UseItemTime[client] = TheRealTime + GetEngineTime();
	}
}

stock AdjustProgressBar(client, Float:TheTime) { SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", TheTime); }

stock bool:ActiveProgressBar(client) {

	if (GetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration") <= 0.0) return false;
	return true;
}

stock Defibrillator(client, target=0) {

	// respawn people near the player.
	new Float:Origin[3];
	if (client > 0) GetClientAbsOrigin(client, Origin);
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && !IsPlayerAlive(i) && i != client && i != target) {

			if (target > 0 && i != target) continue;

			if (target == 0 && b_HasDeathLocation[i] && GetVectorDistance(Origin, DeathLocation[i]) < 256.0) {

				PrintToChatAll("%t", "rise again", white, orange, white);
				CreateTimer(1.0, Timer_TeleportRespawn, i, TIMER_FLAG_NO_MAPCHANGE);
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

stock bool:IsOverDrive(client) {

	if (HasAdrenaline(client) && IsClientInRangeSpecialAmmo(client, 'd') == -2.0 && IsClientInRangeSpecialAmmo(client, 'E') == -2.0) return true;
	return false;
}

//stock bool:IsClientActiveBuff(client, effect, Float:Power=0.0)

public Action:OnPlayerRunCmd(client, &buttons) {

	if (IsLegitimateClient(client)) {

		if (IsPlayerAlive(client) && !b_IsHooked[client]) {

			b_IsHooked[client] = true;
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			//if (IsFakeClient(attacker)) SetEntityHealth(attacker, 100000);
		}
	}
	if ((buttons & IN_USE) && b_IsRoundIsOver) {

		if (ReadyUp_GetGameMode() == 3) {

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
	if (ReadyUp_GetGameMode() == 3 && b_IsSurvivalIntermission && IsLegitimateClientAlive(client) && !IsFakeClient(client)) {

		if (buttons & IN_SPEED && (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT) && (GetEntityFlags(client) & FL_ONGROUND)) {

			MovementSpeed[client] = StringToFloat(GetConfigValue("sprint speed?"));
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", MovementSpeed[client]);
			buttons &= ~IN_SPEED;
			return Plugin_Changed;
		}
		else {

			MovementSpeed[client] = 1.0;
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		}
	}

	if (IsLegitimateClientAlive(client) && !IsFakeClient(client) && b_IsActiveRound) {

		if (CombatTime[client] <= GetEngineTime() && bIsInCombat[client]) {

			bIsInCombat[client] = false;
			AwardExperience(client);
		}
		else if (CombatTime[client] > GetEngineTime()) {

			bIsInCombat[client] = true;
			if (!bIsHandicapLocked[client]) {

				PrintToChat(client, "%T", "combat handicap restricted", client, orange, blue);
				bIsHandicapLocked[client] = true;
			}
		}

		if (IsClientInRangeSpecialAmmo(client, 's') == -2.0) {

			if (GetClientTeam(client) == TEAM_INFECTED) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0 - IsClientInRangeSpecialAmmo(client, 's', false));
			else if (GetClientTeam(client) == TEAM_SURVIVOR) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", MovementSpeed[client] - IsClientInRangeSpecialAmmo(client, 's', false));
		}
		else {

			if (GetClientTeam(client) == TEAM_INFECTED) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
			else if (GetClientTeam(client) == TEAM_SURVIVOR) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", MovementSpeed[client]);
		}
		if (ISDAZED[client] > GetEngineTime()) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue") * StringToFloat(GetConfigValue("dazed debuff effect?")));
		else if (ISDAZED[client] <= GetEngineTime() && ISDAZED[client] != 0.0) {

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
					new Float:Z1 = JumpPosition[client][0][2];
					new Float:Z2 = JumpPosition[client][1][2];

					//if (Z1 > Z2 && Z1 - Z2 >= StringToFloat(GetConfigValue("fall damage critical?"))) IncapacitateOrKill(client, _, _, true);
					if (Z1 > Z2) {

						Z1 -= Z2;
						//IsClientActiveBuff(client, 'Q', Z1);
					}
				}
				b_IsFloating[client] = false;	// in case it was bugged or something (just for safe reason)
			}
			if (!(buttons & IN_USE) && ActiveProgressBar(client)) {

				CreateProgressBar(client, 0.0, true);
				UseItemTime[client] = 0.0;
			}

			new CurrentEntity			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
			new MedkitName			=	-1;

			decl String:EntityName[64];
			decl String:MedkitEntity[64];

			Format(EntityName, sizeof(EntityName), "}");
			Format(MedkitEntity, sizeof(MedkitEntity), "}");
			if (IsValidEntity(CurrentEntity)) GetEdictClassname(CurrentEntity, EntityName, sizeof(EntityName));
			if (IsValidEntity(MedkitName)) GetEdictClassname(MedkitName, MedkitEntity, sizeof(MedkitEntity));

			if (ActiveProgressBar(client) &&
				(!(GetEntityFlags(client) & FL_ONGROUND) && !IsIncapacitated(client)) ||
				L4D2_GetInfectedAttacker(client) != -1 ||
				!IsValidEntity(CurrentEntity) && !IsIncapacitated(client) ||
				((StrContains(EntityName, "pain_pills", false) == -1 &&
				StrContains(EntityName, "adrenaline", false) == -1  &&
				StrContains(EntityName, "first_aid", false) == -1 &&
				StrContains(EntityName, "defib", false) == -1 &&
				StrContains(MedkitEntity, "first_aid", false) == -1) && !IsIncapacitated(client))) {

				CreateProgressBar(client, 0.0, true);
				UseItemTime[client] = 0.0;
			}

			if (IsIncapacitated(client) && L4D2_GetInfectedAttacker(client) == -1 || (L4D2_GetInfectedAttacker(client) == -1 && IsValidEntity(CurrentEntity) &&
				(StrContains(EntityName, "pain_pills", false) != -1 ||
				StrContains(EntityName, "adrenaline", false) != -1  ||
				StrContains(EntityName, "first_aid", false) != -1 ||
				StrContains(EntityName, "defib", false) != -1 ||
				StrContains(MedkitEntity, "first_aid", false) != -1))) {

				/*

					Prevent players from using these items in their traditional way.
				*/
				if ((buttons & IN_ATTACK || buttons & IN_ATTACK2) && !IsIncapacitated(client)) {

					if (buttons & IN_ATTACK) buttons &= ~IN_ATTACK;
					if (buttons & IN_ATTACK2) buttons &= ~IN_ATTACK2;
					return Plugin_Changed;
				}
				if ((buttons & IN_USE) && UseItemTime[client] < GetEngineTime()) {

					if (ActiveProgressBar(client)) {

						UseItemTime[client] = 0.0;
						CreateProgressBar(client, 0.0, true);
						if (StrContains(EntityName, "pain_pills", false) != -1 && !IsIncapacitated(client)) {

							HealPlayer(client, client, GetTempHealth(client) + (GetMaximumHealth(client) * 0.3), 'h', true);//SetTempHealth(client, client, GetTempHealth(client) + (GetMaximumHealth(client) * 0.3), false);		// pills add 10% of your total health in temporary health.
							AcceptEntityInput(CurrentEntity, "Kill");
						}
						else if (StrContains(EntityName, "adrenaline", false) != -1 && !IsIncapacitated(client)) {

							SetAdrenalineState(client);
							new StaminaBonus = RoundToCeil(GetPlayerStamina(client) * 0.25);
							if (SurvivorStamina[client] + StaminaBonus >= GetPlayerStamina(client)) {

								SurvivorStamina[client] = GetPlayerStamina(client);
								bIsSurvivorFatigue[client] = false;
							}
							else SurvivorStamina[client] += StaminaBonus;
							AcceptEntityInput(CurrentEntity, "Kill");
						}
						else if ((StrContains(EntityName, "first_aid", false) != -1 || StrContains(MedkitEntity, "first_aid", false) != -1) && !IsIncapacitated(client)) {

							GiveMaximumHealth(client);
							RefreshSurvivor(client);
							AcceptEntityInput(CurrentEntity, "Kill");
						}
						else if (IsIncapacitated(client)) {

							ReviveDownedSurvivor(client);
							OnPlayerRevived(client, client);
						}
						else if (StrContains(EntityName, "defib", false) != -1 && !IsIncapacitated(client)) {

							Defibrillator(client);
							AcceptEntityInput(CurrentEntity, "Kill");
						}
					}
					else {

						if (IsIncapacitated(client) && UseItemTime[client] < GetEngineTime()) {

							if (!IsLedged(client)) CreateProgressBar(client, 10.0);	// you can pick yourself up for free but it takes a bit.
							else CreateProgressBar(client, 20.0);
						}
						else if (StrContains(EntityName, "pain_pills", false) != -1 && UseItemTime[client] < GetEngineTime() && !IsIncapacitated(client)) {

							CreateProgressBar(client, 2.0);
							//UseItemTime[client] = GetEngineTime() + 2;
						}
						else if (StrContains(EntityName, "adrenaline", false) != -1 && UseItemTime[client] < GetEngineTime() && !IsIncapacitated(client)) {

							CreateProgressBar(client, 1.0);
							//UseItemTime[client] = GetEngineTime() + 1;
						}
						else if ((StrContains(EntityName, "first_aid", false) != -1 || StrContains(MedkitEntity, "first_aid", false) != -1) && UseItemTime[client] < GetEngineTime()) {

							CreateProgressBar(client, 5.0);
							//UseItemTime[client] = GetEngineTime() + 5;
						}
						else if (StrContains(EntityName, "defib", false) != -1 && UseItemTime[client] < GetEngineTime() && !IsIncapacitated(client)) {

							CreateProgressBar(client, 10.0);
							//UseItemTime[client] = GetEngineTime() + 10;
						}
					}
				}
			}
			// For drawing special ammo.
			if (IsSpecialAmmoEnabled[client][2] <= GetEngineTime() || GetClientAimTarget(client, false) != IsSpecialAmmoEnabled[client][3] * 1.0) {

				if (IsSpecialAmmoEnabled[client][0] == 1.0 && DrawSpecialAmmoTarget(client) == 0 && IsPlayerDebugMode[client] == 1) DrawSpecialAmmoTarget(client, true);
				IsSpecialAmmoEnabled[client][2] = GetEngineTime() + StringToFloat(GetConfigValue("special ammo highlight time?"));
			}

			if (IsSpecialAmmoEnabled[client][1] <= GetEngineTime()) {

				if (!(buttons & IN_DUCK) && ((buttons & IN_RELOAD) && (buttons & IN_ZOOM))) {

					//	Toggles on/off special ammo.
					//	[1] is to prevent the player from toggling too quickly.
					
					if (HasSpecialAmmo(client) && !bIsSurvivorFatigue[client]) {

						if (IsSpecialAmmoEnabled[client][0] == 1.0) {

							IsSpecialAmmoEnabled[client][0] = 0.0;
							//LastTarget[client] = -1;
							PrintToChat(client, "%T", "Special Ammo Disabled", client, white, orange);
						}
						else {

							IsSpecialAmmoEnabled[client][0] = 1.0;
							PrintToChat(client, "%T", "Special Ammo Enabled", client, white, green);
						}
					}
					else {

						//	If the user doesn't have special ammo...
						PrintToChat(client, "%T", "No Special Ammo", client, white, orange, white);
						IsSpecialAmmoEnabled[client][0] = 0.0;
					}
					IsSpecialAmmoEnabled[client][1] = GetEngineTime() + 0.5;
				}
				if ((buttons & IN_DUCK) && IsSpecialAmmoEnabled[client][0] == 1.0) {

					
					//	If you have special ammo enabled, press the reload key but NOT the zoom key, then we toggle between
					//	the different special ammo states.
					//	However, to let players rotate forward and backwards in the available ammos, we use the IN_SPEED (walk) key.
					
					if (buttons & IN_SPEED) CycleSpecialAmmo(client, true);
					else if (buttons & IN_ZOOM) CycleSpecialAmmo(client, false);
					IsSpecialAmmoEnabled[client][1] = GetEngineTime() + 0.25;
				}
			}

			if (ReadyUp_GetGameMode() != 3 || !b_IsSurvivalIntermission) {

				if (buttons & IN_SPEED && (buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT) && (GetEntityFlags(client) & FL_ONGROUND) && SurvivorStamina[client] >= StringToInt(GetConfigValue("stamina consumption interval?")) && !bIsSurvivorFatigue[client] && ISSLOW[client] == INVALID_HANDLE && ISFROZEN[client] == INVALID_HANDLE) {

					if (L4D2_GetInfectedAttacker(client) == -1 && ISSLOW[client] == INVALID_HANDLE && ISFROZEN[client] == INVALID_HANDLE) {

						if (SurvivorConsumptionTime[client] <= GetEngineTime()) {

							SurvivorConsumptionTime[client] = GetEngineTime() + StringToFloat(GetConfigValue("stamina sprint interval?"));
							SurvivorStamina[client] -= StringToInt(GetConfigValue("stamina consumption interval?"));
							if (SurvivorStamina[client] <= 0) {

								bIsSurvivorFatigue[client] = true;
								IsSpecialAmmoEnabled[client][0] = 0.0;
							}
						}
						//SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", StringToFloat(GetConfigValue("sprint speed?")));
						MovementSpeed[client] = StringToFloat(GetConfigValue("sprint speed?"));
					}
					buttons &= ~IN_SPEED;
					return Plugin_Changed;
				}
				else {

					if (SurvivorStaminaTime[client] <= GetEngineTime() && SurvivorStamina[client] < GetPlayerStamina(client)) {

						if (!HasAdrenaline(client)) SurvivorStaminaTime[client] = GetEngineTime() + StringToFloat(GetConfigValue("stamina regeneration time?"));
						else SurvivorStaminaTime[client] = GetEngineTime() + StringToFloat(GetConfigValue("stamina regeneration time adren?"));
						SurvivorStamina[client]++;
					}
					//if (GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue") != StringToFloat(GetConfigValue("base movement speed?"))) {

					if (!bIsSurvivorFatigue[client]) MovementSpeed[client] = StringToFloat(GetConfigValue("base movement speed?"));
					else MovementSpeed[client] = StringToFloat(GetConfigValue("fatigue movement speed?"));
					//}
					if (SurvivorStamina[client] >= GetPlayerStamina(client)) {

						bIsSurvivorFatigue[client] = false;
						if (!b_IsActiveRound) SurvivorStamina[client] = 0;
					}
				}
			}

			if (buttons & IN_JUMP) {

				/*if (GetClientTeam(client) == TEAM_SURVIVOR) {

					if (GetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue") < 1.0 && ISSLOW[client] == INVALID_HANDLE && ISFROZEN[client] == INVALID_HANDLE) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", StringToFloat(GetConfigValue("base movement speed?")));
				}*/

				if (L4D2_GetInfectedAttacker(client) == -1 && L4D2_GetSurvivorVictim(client) == -1 && (GetEntityFlags(client) & FL_ONGROUND)) {

					GetAbilityStrengthByTrigger(client, 0, 'j', FindZombieClass(client), 0);
				}
				if (L4D2_GetSurvivorVictim(client) != -1) {

					new victim = L4D2_GetSurvivorVictim(client);
					if ((GetEntityFlags(victim) & FL_ONGROUND)) GetAbilityStrengthByTrigger(client, victim, 'J', FindZombieClass(client), 0);
				}
			}
			else if (!(buttons & IN_JUMP) && b_IsJumping[client]) ModifyGravity(client);
		}
	}
	return Plugin_Continue;
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
	new AfxLevelReq = StringToInt(GetCommonValue(client, "level required?"));

	new Float:ClientPosition[3];
	new Float:TargetPosition[3];

	new t_Strength = 0;
	new Float:t_Range = 0.0;
	//new ent = -1;

	new Float:t_OnFireRange = 0.0;

	if (damage > 0) AfxStrength = damage;	// if we want to base the damage on a specific value, we can override here.

	GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPosition);
	new NumLivingEntities = LivingEntitiesInRange(client, ClientPosition, AfxRangeMax);
	for (new i = 1; i <= MaxClients; i++) {

		if (!IsLegitimateClientAlive(i) || (target != 0 && i != target) || PlayerLevel[i] < AfxLevelReq) continue;		// if type is 1 and target is 0 acid is spread to all players nearby. but if target is not 0 it is spread to only the player the acid zombie hits. or whatever type uses it.
		GetClientAbsOrigin(i, TargetPosition);

		if (AfxRange > 0.0) t_Range = AfxRange * (PlayerLevel[i] - AfxLevelReq);
		else t_Range = AfxRangeMax;
		if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
		else t_Range += AfxRangeBase;
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
		else if (type == 4) CreateAndAttachFlame(i, t_Strength, t_OnFireRange, OnFireInterval, _, "acid");
	}
	new ent = -1;
	for (new i = 0; i < GetArraySize(Handle:CommonInfected); i++) {

		ent = GetArrayCell(Handle:CommonInfected, i);
		if (IsCommonInfected(ent)) {

			if (ent != client) {

				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", TargetPosition);
				if (GetVectorDistance(ClientPosition, TargetPosition) <= (AfxRangeMax / 2)) {

					if (type == 0) CreateAndAttachFlame(ent, t_Strength, OnFireBase, OnFireInterval, _, "burn");
					else if (type == 4) CreateAndAttachFlame(ent, t_Strength, OnFireBase, OnFireInterval, _, "acid");
				}
			}
		}
	}
	//ClearSpecialCommon(client);
}

stock ExplosiveAmmo(client, damage, TalentClient) {

	if (IsWitch(client)) AddWitchDamage(TalentClient, client, damage);
	else if (IsSpecialCommon(client)) AddSpecialCommonDamage(TalentClient, client, damage);
	else if (IsCommonInfected(client)) AddCommonInfectedDamage(TalentClient, client, damage);
	else if (IsLegitimateClientAlive(client)) {

		if (GetClientTeam(client) == TEAM_INFECTED) AddSpecialInfectedDamage(TalentClient, client, damage);
		else SetClientTotalHealth(client, damage);	// survivor teammates don't reward players with experience or damage bonus, but they'll take damage from it.
	}
}

stock HealingAmmo(client, healing, TalentClient, bool:IsCritical=false) {

	if (!IsLegitimateClientAlive(client) || !IsLegitimateClientAlive(TalentClient)) return;
	if (IsCritical || !IsCriticalHit(client, healing, TalentClient)) HealPlayer(client, TalentClient, healing * 1.0, 'h', true);
	//SetTempHealth(TalentClient, client, healing * 1.0, false);
}

stock bool:IsCriticalHit(client, healing, TalentClient) {

	new Float:WeaknessMultiplier = StringToFloat(GetConfigValue("weakness multiplier?"));
	if (!PlayerHasWeakness(TalentClient)) WeaknessMultiplier = 1.0;

	if (GetRandomInt(1, RoundToCeil(1.0 / (((CARTEL_Luck[TalentClient] * StringToFloat(GetConfigValue("luck ab multiplier?"))) / WeaknessMultiplier) / healing))) == 1) {

		// Critical Hit!
		HealingAmmo(client, RoundToCeil((CARTEL_Luck[TalentClient] * StringToFloat(GetConfigValue("luck ab multiplier?"))) * healing) + healing, TalentClient, true);
		return true;
	}
	return false;
}

stock LeechAmmo(client, damage, TalentClient) {

	if (IsWitch(client)) AddWitchDamage(TalentClient, client, damage);
	else if (IsSpecialCommon(client)) AddSpecialCommonDamage(TalentClient, client, damage);
	else if (IsCommonInfected(client)) AddCommonInfectedDamage(TalentClient, client, damage);
	else if (IsLegitimateClientAlive(client)) {

		if (GetClientTeam(client) == TEAM_INFECTED) AddSpecialInfectedDamage(TalentClient, client, damage);
		else SetClientTotalHealth(client, damage);
	}
	if (IsLegitimateClientAlive(TalentClient) && GetClientTeam(TalentClient) == TEAM_SURVIVOR) {

		//if (IsCritical || !IsCriticalHit(client, healing, TalentClient))	// maybe add this to leech? that would be cool.!
		HealPlayer(TalentClient, TalentClient, damage * 1.0, 'h', true);
	}
}

stock Float:CreateBomberExplosion(client, target, String:Effects[]) {

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
	new AfxLevelReq = StringToInt(GetCommonValue(client, "level required?"));


	if (IsLegitimateClient(client) && GetClientTeam(client) == TEAM_SURVIVOR && PlayerLevel[client] < AfxLevelReq) return;

	new Float:SourcLoc[3];
	new Float:TargetPosition[3];
	new t_Strength = 0;
	new Float:t_Range = 0.0;
	new ent = -1;

	if (target > 0) {

		if (IsLegitimateClientAlive(target)) GetClientAbsOrigin(target, SourcLoc);
		else if (IsCommonInfected(target) || IsWitch(target)) GetEntPropVector(target, Prop_Send, "m_vecOrigin", SourcLoc);
		new NumLivingEntities = LivingEntitiesInRange(client, SourcLoc, AfxRangeMax);
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", TargetPosition);

		if (AfxRange > 0.0 && IsLegitimateClientAlive(target)) t_Range = AfxRange * (PlayerLevel[target] - AfxLevelReq);
		else t_Range = AfxRangeMax;
		if (t_Range + AfxRangeBase > AfxRangeMax) t_Range = AfxRangeMax;
		else t_Range += AfxRangeBase;

		if (IsLegitimateClientAlive(target) && GetClientTeam(target) == TEAM_SURVIVOR && target != client) {

			if (PlayerLevel[target] < AfxLevelReq) return;
			if (GetVectorDistance(SourcLoc, TargetPosition) > (t_Range / 2)) return;
		}

		for (new i = 1; i <= MaxClients; i++) {

			if (!IsLegitimateClientAlive(i) || PlayerLevel[i] < AfxLevelReq) continue;
			GetClientAbsOrigin(i, TargetPosition);

			if (AfxRange > 0.0) t_Range = AfxRange * (PlayerLevel[i] - AfxLevelReq);
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
			if (AfxStrengthLevel > 0.0) t_Strength += RoundToCeil(t_Strength * ((PlayerLevel[i] - AfxLevelReq) * AfxStrengthLevel));

			//if (t_Strength > GetClientHealth(i)) IncapacitateOrKill(i);
			//else SetEntityHealth(i, GetClientHealth(i) - t_Strength);
			if (t_Strength > 0.0) SetClientTotalHealth(i, t_Strength);

			if (client == target) {

				// To prevent a never-ending chain reaction, we don't allow it to target the bomber that caused it.

				if (!IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && AfxChain == 1) CreateBomberExplosion(client, i, Effects);
			}
		}
		if (StrContains(Effects, "e", true) != -1) {

			CreateExplosion(target);	// boom boom audio and effect on the location.
			if (IsLegitimateClientAlive(target) && !IsFakeClient(target)) ScreenShake(target);
		}
		if (StrContains(Effects, "B", true) != -1) {

			if (IsLegitimateClientAlive(target)) {

				SDKCall(g_hCallVomitOnPlayer, target, client, true);
				L4D_StaggerPlayer(target, client, NULL_VECTOR);
			}
		}

		ent = -1;
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
	else {

		GetEntPropVector(client, Prop_Send, "m_vecOrigin", SourcLoc);

		/*

			The bomber target is 0, so we eliminate any common infected within range.
			Don't worry - this function will have called and executed for all players in range before it gets here
			thanks to the magic of single-threaded language.
		*/
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
					if (StrContains(Effects, "e", true) != -1 && !IsSpecialCommon(ent)) OnCommonInfectedCreated(ent, true);
					//if (StrContains(Effects, "B", true) != -1) SDKCall(g_hCallVomitOnPlayer, ent, client, true);
				}
			}
		}
	}
}

stock CalculateInfectedDamageAward(client, commonkiller = 0) {

	new Float:SurvivorPoints = 0.0;
	new SurvivorExperience = 0;
	new Float:PointsMultiplier = StringToFloat(GetConfigValue("points multiplier survivor?"));
	new Float:ExperienceMultiplier = StringToFloat(GetConfigValue("experience multiplier survivor?"));
	new Float:TankingMultiplier = StringToFloat(GetConfigValue("experience multiplier tanking?"));
	new Float:HealingMultiplier = StringToFloat(GetConfigValue("experience multiplier healing?"));
	new t_Contribution = 0;
	new h_Contribution = 0;

	new SurvivorDamage = 0;
	new owner = 0;
	if (IsLegitimateClientAlive(commonkiller) && GetClientTeam(commonkiller) == TEAM_SURVIVOR) owner = commonkiller;
	if (!IsWitch(client) && !IsSpecialCommon(client) && !IsCommonInfected(client)) SpecialsKilled++;
	new Float:i_DamageContribution = 0.0000;
	new Float:DamageContributionRequirement = (1.0 / LivingSurvivorCount());
	//LogMessage("Damage comtribution requirement: %3.3f", DamageContributionRequirement);
	if (DamageContributionRequirement > StringToFloat(GetConfigValue("damage contribution?"))) {

		DamageContributionRequirement = StringToFloat(GetConfigValue("damage contribution?"));
	}

	// If it's a special common, we activate its death abilities.
	if (IsSpecialCommon(client)) {

		CreateBomberExplosion(client, client, GetCommonValue(client, "aura effect?"));	// bomber aoe
	}

	new pos = -1;
	if (!IsSpecialCommon(client) && IsCommonInfected(client)) {

		pos = FindListPositionByEntity(client, Handle:CommonInfectedDamage);
		if (pos < 0 || owner == 0 || !IsLegitimateClientAlive(owner) || GetClientTeam(owner) != TEAM_SURVIVOR) {

			if (pos >= 0) RemoveFromArray(Handle:CommonInfectedDamage, pos);
			return;		// common infected cannot be found.
		}

		SurvivorDamage		= GetArrayCell(Handle:CommonInfectedDamage, pos, 2);

		if (SurvivorDamage > 0) {

			SurvivorExperience = RoundToFloor(SurvivorDamage * ExperienceMultiplier);
			SurvivorPoints = SurvivorDamage * PointsMultiplier;
		}

		i_DamageContribution = CheckTeammateDamages(client, owner, true);

		if (i_DamageContribution > 0.0) {

			SurvivorExperience = RoundToFloor(SurvivorDamage * ExperienceMultiplier);
			SurvivorPoints = SurvivorDamage * PointsMultiplier;
		}
		//}


		t_Contribution = CheckTankingDamage(client, owner);
		if (t_Contribution > 0) {

			t_Contribution = RoundToCeil(t_Contribution * TankingMultiplier);
			SurvivorPoints += (t_Contribution * (PointsMultiplier * TankingMultiplier));
		}
		h_Contribution = HealingContribution[owner];
		HealingContribution[owner] = 0;
		if (h_Contribution > 0) {

			h_Contribution = RoundToCeil(h_Contribution * HealingMultiplier);
			SurvivorPoints += (h_Contribution * (PointsMultiplier * HealingMultiplier));
		}
		//if (!bIsInCombat[i]) ReceiveInfectedDamageAward(i, client, SurvivorExperience, SurvivorPoints, t_Contribution, h_Contribution, Bu_Contribution, He_Contribution);
		HealingContribution[owner] += h_Contribution;
		TankingContribution[owner] += t_Contribution;
		PointsContribution[owner] += SurvivorPoints;
		DamageContribution[owner] += SurvivorExperience;
		
		RemoveFromArray(Handle:CommonInfectedDamage, pos);
		return;
	}
	for (new i = 1; i <= MaxClients; i++) {
		
		SurvivorExperience = 0;
		SurvivorPoints = 0.0;
		i_DamageContribution = 0.0000;

		if (!IsLegitimateClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) continue;

		if (!IsWitch(client) && !IsSpecialCommon(client) && !IsCommonInfected(client)) pos = FindListPositionByEntity(client, Handle:InfectedHealth[i]);
		else if (IsWitch(client)) pos = FindListPositionByEntity(client, Handle:WitchDamage[i]);
		else if (IsSpecialCommon(client)) pos = FindListPositionByEntity(client, Handle:SpecialCommon[i]);

		if (pos < 0) continue;

		if (!IsWitch(client) && !IsSpecialCommon(client) && !IsCommonInfected(client)) SurvivorDamage = GetArrayCell(Handle:InfectedHealth[i], pos, 2);
		else if (IsWitch(client)) SurvivorDamage = GetArrayCell(Handle:WitchDamage[i], pos, 2);
		else if (IsSpecialCommon(client)) SurvivorDamage = GetArrayCell(Handle:SpecialCommon[i], pos, 2);

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
		h_Contribution = HealingContribution[i];
		HealingContribution[i] = 0;
		if (h_Contribution > 0) {

			h_Contribution = RoundToCeil(h_Contribution * HealingMultiplier);
			SurvivorPoints += (h_Contribution * (PointsMultiplier * HealingMultiplier));
		}
		//if (!bIsInCombat[i]) ReceiveInfectedDamageAward(i, client, SurvivorExperience, SurvivorPoints, t_Contribution, h_Contribution, Bu_Contribution, He_Contribution);
		HealingContribution[i] += h_Contribution;
		TankingContribution[i] += t_Contribution;
		PointsContribution[i] += SurvivorPoints;
		DamageContribution[i] += SurvivorExperience;
		if (!IsWitch(client) && !IsSpecialCommon(client) && !IsCommonInfected(client)) RemoveFromArray(Handle:InfectedHealth[i], pos);
		else if (IsWitch(client)) RemoveFromArray(Handle:WitchDamage[i], pos);
		else if (IsSpecialCommon(client)) RemoveFromArray(Handle:SpecialCommon[i], pos);
	}
	if (!IsWitch(client) && !IsSpecialCommon(client) && !IsCommonInfected(client) && IsLegitimateClient(client) && GetClientTeam(client) != TEAM_SURVIVOR) {

		b_IsHooked[client] = false;
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);

		ForcePlayerSuicide(client);
	}
}

stock ReceiveInfectedDamageAward(client, infected, e_reward, Float:p_reward, t_reward, h_reward , bu_reward, he_reward) {

	new RPGMode									= StringToInt(GetConfigValue("rpg mode?"));
	//new RPGBroadcast							= StringToInt(GetConfigValue("award broadcast?"));
	new DisplayType								= StringToInt(GetConfigValue("survivor reward display?"));
	decl String:InfectedName[64];

	if (infected > 0) {

		if (!IsWitch(infected) && !IsSpecialCommon(infected) && !IsCommonInfected(infected)) GetClientName(infected, InfectedName, sizeof(InfectedName));
		else if (IsWitch(infected)) Format(InfectedName, sizeof(InfectedName), "Witch");
		else if (IsSpecialCommon(infected)) Format(InfectedName, sizeof(InfectedName), "%s", GetCommonValue(infected, "name?"));
		else if (IsCommonInfected(infected)) Format(InfectedName, sizeof(InfectedName), "Common");
		Format(InfectedName, sizeof(InfectedName), "%s %s", GetConfigValue("director team name?"), InfectedName);
	}

	new Float:PlayerHandicapBonus				= GetHandicapStrength("new handicap experience?", HandicapLevel[client]);
	if (HandicapLevel[client] >= 1) {

		e_reward = RoundToCeil(PlayerHandicapBonus * e_reward);
		h_reward = RoundToCeil(PlayerHandicapBonus * h_reward);
		t_reward = RoundToCeil(PlayerHandicapBonus * t_reward);
	}
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

		if (DisplayType > 0 && (infected == 0 || (IsSpecialCommon(infected) || IsWitch(infected) || IsLegitimateClient(infected)))) {								// \x04Jockey \x01killed: \x04 \x03experience

			if (e_reward > 0 && infected > 0) PrintToChat(client, "%T", "base experience reward", client, orange, InfectedName, white, green, AddCommasToString(e_reward), blue);
			else if (e_reward > 0 && infected == 0) {

				PrintToChat(client, "%T", "damage experience reward", client, orange, green, white, green, AddCommasToString(e_reward), blue);
			}
			if (DisplayType == 2) {

				//if (PlayerHandicapBonus > 0) PrintToChat(client, "%T", "handicap experience reward", client, green, white, green, AddCommasToString(PlayerHandicapBonus), blue);
				if (RestedAwardBonus > 0) PrintToChat(client, "%T", "rested experience reward", client, green, white, green, AddCommasToString(RestedAwardBonus), blue);
				if (ExperienceBooster > 0) PrintToChat(client, "%T", "booster experience reward", client, green, white, green, AddCommasToString(ExperienceBooster), blue);
			}
			if (t_reward > 0) PrintToChat(client, "%T", "tanking experience reward", client, green, white, green, AddCommasToString(t_reward), blue);
			if (h_reward > 0) PrintToChat(client, "%T", "healing experience reward", client, green, white, green, AddCommasToString(h_reward), blue);
			if (bu_reward > 0) PrintToChat(client, "%T", "buffing experience reward", client, green, white, green, AddCommasToString(bu_reward), blue);
			if (he_reward > 0) PrintToChat(client, "%T", "hexing experience reward", client, green, white, green, AddCommasToString(he_reward), blue);
		}
		new TotalExperienceEarned = e_reward + RestedAwardBonus + ExperienceBooster + t_reward + h_reward + bu_reward + he_reward;
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

		if (DisplayType > 0 && (infected == 0 || (IsSpecialCommon(infected) || IsWitch(infected) || IsLegitimateClient(infected)))) PrintToChat(client, "%T", "points from damage reward", client, green, white, green, p_reward, blue);
	}
	CheckKillPositions(client, true);
}

// Curious RPG System option?
// Points earned from hurting players used to unlock abilities, while experienced earned to increase level determines which abilities a player has access to.
// This way, even if the level is different, everyone starts with the same footing.
// Optional RPG System. Maybe call it "buy rpg mode?"

