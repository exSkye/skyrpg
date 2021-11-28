if (iRPGMode <= 0 || IsLegitimateClient(activator) && (GetClientTeam(activator) == TEAM_SURVIVOR || IsSurvivorBot(activator)) && StrEqual(ActiveClass[activator], "none", false)) return 0.0;
	// ResultType:
	// 0 Activator
	// 1 Target
	//ResultEffects are so when compounding talents we know which type to pull from.
	//This is an alternative to GetAbilityStrengthByTrigger for talents that need it, and maybe eventually the whole system.
	if (target == -2) target = FindAnyRandomClient();
	if (target < 1) target = activator;
	if (!IsLegitimateClient(activator)) return 0.0;
	//if (IsCommonInfected(target)) return 0.0;	// test for lag
	//new Float:EffectValue = 0.0;

	decl String:AbilityT[4];
	Format(AbilityT, sizeof(AbilityT), "%c", Ability);

	new Effect = 0;

	decl String:EffectLoop[55];
	Format(EffectLoop, sizeof(EffectLoop), "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz");

	decl String:activatorteam[10];
	decl String:targetteam[10];

	decl String:activatoreffects[64];
	decl String:targeteffects[64];

	decl String:t_Effect[4];
	Format(t_Effect, sizeof(t_Effect), "%c", Effect);

	//decl String:ActivatorClassRequired[32];
	decl String:TargetClassRequired[32];

	decl String:ActivatorClass[32];
	decl String:TargetClass[32];
	if (IsWitch(target)) Format(TargetClass, sizeof(TargetClass), "7");
	else if (IsSpecialCommon(target)) Format(TargetClass, sizeof(TargetClass), "9");
	else if (IsCommonInfected(target)) Format(TargetClass, sizeof(TargetClass), "a");
	else if (IsLegitimateClient(target)) {

		if (GetClientTeam(target) == TEAM_INFECTED) Format(TargetClass, sizeof(TargetClass), "%d", FindZombieClass(target));
		else Format(TargetClass, sizeof(TargetClass), "0");
	}
	if (GetClientTeam(activator) == TEAM_INFECTED) Format(ActivatorClass, sizeof(ActivatorClass), "%d", FindZombieClass(activator));
	else Format(ActivatorClass, sizeof(ActivatorClass), "0");

	Format(activatorteam, sizeof(activatorteam), "%d", GetClientTeam(activator));
	Format(targetteam, sizeof(targetteam), "0");

	decl String:WeaponsPermitted[512];
	//decl String:WeaponsPermittedStrict[64];
	decl String:PlayerWeapon[64];
	if (GetClientTeam(activator) == TEAM_SURVIVOR || IsSurvivorBot(activator)) GetClientWeapon(activator, PlayerWeapon, sizeof(PlayerWeapon));
	else Format(PlayerWeapon, sizeof(PlayerWeapon), "ignore");


	new Float:f_Strength			= 0.0;
	//new i_Strength = 0;
	new Float:f_FirstPoint			= 0.0;

	new Float:f_EachPoint			= 0.0;

	new Float:f_Time				= 0.0;

	new Float:f_Cooldown			= 0.0;

	new Float:p_Strength			= 0.0;
	new Float:t_Strength			= 0.0;
	//new Float:p_FirstPoint			= 0.0;
	//new Float:p_EachPoint			= 0.0;
	new Float:p_Time				= 0.0;
	//new Float:p_Cooldown			= 0.0;
	new bool:bIsCompounding = false;

	new ASize = GetArraySize(a_Menu_Talents);
	decl String:TalentName[64];
	//decl String:EffectT[5];
	//while (strlen(EffectLoop) > 1) {

	/*
		The idea is all talents can combine with their respective siblings.
	*/
	//Effect = EffectLoop[strlen(EffectLoop) - 1];
	//EffectLoop[strlen(EffectLoop) - 1] = ' ';
	//TrimString(EffectLoop);
	//Format(EffectT, sizeof(EffectT), "%c", Effect);


	new bool:iHasWeakness = PlayerHasWeakness(activator);
	decl String:TheString[64];
	decl String:MultiplierText[64];
	new Float:ExplosiveAmmoRange = 0.0;
	new TheTalentStrength = 0;

	new CombatStateRequired = 0;
	new Float:healregenrange = -1.0;
	new Float:healerpos[3], Float:targetpos[3];

	for (new i = 0; i < ASize; i++) {

		bIsCompounding = false;

		TriggerKeys[activator]		= GetArrayCell(a_Menu_Talents, i, 0);
		TriggerValues[activator]	= GetArrayCell(a_Menu_Talents, i, 1);

		if (GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "is ability?") == 1) continue;
		if (GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "special ammo?") == 1) continue;

		TriggerSection[activator]	= GetArrayCell(a_Menu_Talents, i, 2);

		GetArrayString(Handle:TriggerSection[activator], 0, TalentName, sizeof(TalentName));
		if (GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "is survivor class role?") == 1) continue;	// class roles aren't talents.
		FormatKeyValue(TheString, sizeof(TheString), TriggerKeys[activator], TriggerValues[activator], "ability trigger?");
		if (StrContains(TheString, AbilityT, true) == -1) continue;

		TheTalentStrength = GetTalentStrength(activator, TalentName);
		if (TheTalentStrength < 1) continue;
		f_Strength	=	TheTalentStrength * 1.0;
		//if (f_Strength <= 0.000) continue;
		if (IsAbilityCooldown(activator, TalentName)) continue;

		CombatStateRequired = GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "combat state required?");

		if (CombatStateRequired == 1 && !bIsInCombat[activator] ||
			CombatStateRequired == 0 && bIsInCombat[activator]) continue;
		if (!ComparePlayerState(activator, GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "player state required?"))) continue;
		if (!ISBILED[activator] && GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "vomit state required?") == 1) continue;
		if (!HasAdrenaline(activator) && GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "require adrenaline effect?") == 1) continue;
		if (!GetActiveSpecialAmmo(activator, TalentName) && GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "special ammo?") == 1) continue;
		if (iHasWeakness && GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "disabled if weakness?") == 1) continue;
		if (!iHasWeakness && GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "require weakness?") == 1) continue;
		FormatKeyValue(TargetClassRequired, sizeof(TargetClassRequired), TriggerKeys[activator], TriggerValues[activator], "target class required?");
		if (StrContains(TargetClassRequired, TargetClass, false) == -1 && (IsPvP[activator] == 0 || !StrEqual(TargetClass, "0"))) continue;

		if (GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "compounding talent?") == 1) bIsCompounding = true;

		if (StrEqual(ResultEffects, "none", false) && bIsCompounding) continue;

		if (IsCleanse && GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "cleanse trigger?") != 1) continue;

		FormatKeyValue(targeteffects, sizeof(targeteffects), TriggerKeys[activator], TriggerValues[activator], "target ability effects?");
		FormatKeyValue(activatoreffects, sizeof(activatoreffects), TriggerKeys[activator], TriggerValues[activator], "activator ability effects?");

		if (target != activator) {

			if (IsWitch(target)) {

				if (StrContains(targeteffects, "0", false) != -1) continue;
				Format(targetteam, sizeof(targetteam), "6");
			}

			if (IsCommonInfected(target)) {

				if (StrContains(targeteffects, "0", false) != -1) continue;
				if (IsSpecialCommon(target)) Format(targetteam, sizeof(targetteam), "4");
				else Format(targetteam, sizeof(targetteam), "5");
			}
			if (!IsLegitimateClient(target) && !IsWitch(target) && !IsCommonInfected(target)) continue;
			//if (IsLegitimateClient(target) && GetClientTeam(target) == TEAM_SURVIVOR && StrContains(survivoreffects, EffectT, true) == -1) continue;
			//if (IsLegitimateClient(target) && GetClientTeam(target) == TEAM_INFECTED && StrContains(infectedeffects, EffectT, true) == -1) continue;
			if (IsLegitimateClient(target)) {

				if ((GetClientTeam(target) == TEAM_SURVIVOR || IsSurvivorBot(target)) && StrContains(targeteffects, "0", false) != -1) continue;
				if (GetClientTeam(target) == TEAM_INFECTED && StrContains(targeteffects, "0", false) != -1) continue;
				Format(targetteam, sizeof(targetteam), "%d", GetClientTeam(target));
			}
		}
		else if (StrContains(activatoreffects, "0", false) != -1) continue;

		if (bIsCompounding || ResultType == 1) {

			if (ResultType == 0 && StrContains(ResultEffects, activatoreffects, true) == -1) continue;
			if (ResultType == 1) {

				if (IsWitch(target) && StrContains(ResultEffects, targeteffects, true) == -1) continue;
				else if (IsCommonInfected(target) && StrContains(ResultEffects, targeteffects, true) == -1) continue;
				else if (IsLegitimateClient(target) && (GetClientTeam(target) == TEAM_SURVIVOR || IsSurvivorBot(target)) && StrContains(ResultEffects, targeteffects, true) == -1) continue;
				else if (IsLegitimateClient(target) && GetClientTeam(target) == TEAM_INFECTED && StrContains(ResultEffects, targeteffects, true) == -1) continue;
			}
		}
		/*if (IsLegitimateClient(target)) {
			PrintToChat(activator, "survivoreffects: %s Effect: %s", GetKeyValue(TriggerKeys[activator], TriggerValues[activator], "survivor ability effects?"), EffectT);
		}*/
					
		else if (IsLegitimateClient(target)) Format(targetteam, sizeof(targetteam), "%d", GetClientTeam(target));

		if (StrContains(GetKeyValue(TriggerKeys[activator], TriggerValues[activator], "target team required?"), targetteam, false) == -1 && (IsPvP[activator] == 0 || !StrEqual(TargetClass, "0"))) continue;

		if (!StrEqual(PlayerWeapon, "ignore", false)) {

			FormatKeyValue(WeaponsPermitted, sizeof(WeaponsPermitted), TriggerKeys[activator], TriggerValues[activator], "weapons permitted?");
			if (!StrEqual(WeaponsPermitted, "-1", false) && !StrEqual(WeaponsPermitted, "ignore", false) && !StrEqual(WeaponsPermitted, "all", false) && StrContains(WeaponsPermitted, PlayerWeapon, false) == -1) continue;
		}

		//Format(EffectT, sizeof(EffectT), "%c", Effect);

		if (GetTalentStrength(activator, TalentName) < 1) continue;

		f_FirstPoint			= GetTalentInfo(activator, TriggerKeys[activator], TriggerValues[activator], _, _, TalentName);
		f_EachPoint				= GetTalentInfo(activator, TriggerKeys[activator], TriggerValues[activator], 1, _, TalentName);
		f_Time					= GetTalentInfo(activator, TriggerKeys[activator], TriggerValues[activator], 2, _, TalentName);
		f_Cooldown				= GetTalentInfo(activator, TriggerKeys[activator], TriggerValues[activator], 3, _, TalentName);

		f_Strength			=	f_FirstPoint + f_EachPoint;

		if (f_Cooldown > 0.00) {

			if (IsLegitimateClient(activator)) CreateCooldown(activator, GetTalentPosition(activator, TalentName), f_Cooldown);
			//if (IsLegitimateClient(target)) CreateImmune(activator, target, GetTalentPosition(target, TalentName), f_Cooldown);
		}
		p_Strength += f_Strength;
		p_Time += f_Time;
		/*
			If an effect was specified, only talents that have that effect will have added talents strength and time.
			The talents that contribute to this combined value each go on their respective cooldowns, so that if they
			come off cooldown at different times, that the player must manage this or experiment with the different outcomes.
		*/
		if (p_Strength > 0.000) {

			/*if (activator == target) Format(MultiplierText, sizeof(MultiplierText), "tS_%s", activatoreffects);
			else if (IsCommonInfected(target)) Format(MultiplierText, sizeof(MultiplierText), "tS_%s", commoneffects);
			else if (IsWitch(target)) Format(MultiplierText, sizeof(MultiplierText), "tS_%s", witcheffects);
			else if (IsLegitimateClientAlive(target)) {
				if (GetClientTeam(target) == TEAM_SURVIVOR || IsSurvivorBot(target)) Format(MultiplierText, sizeof(MultiplierText), "tS_%s", survivoreffects);
				else if (GetClientTeam(target) == TEAM_INFECTED) Format(MultiplierText, sizeof(MultiplierText), "tS_%s", infectedeffects);
			}*/
			if (activator == target) Format(MultiplierText, sizeof(MultiplierText), "tS_%s", activatoreffects);
			else Format(MultiplierText, sizeof(MultiplierText), "tS_%s", targeteffects);
			
			p_Strength = GetClassMultiplier(activator, p_Strength, MultiplierText);

			if (bIsCompounding || ResultType == 1) {

				t_Strength += p_Strength;
			}
			else {

				if (!IsOverdriveStacks) {

					if (GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "cleanse trigger?") == 1) {

						p_Strength = (CleanseStack[activator] * p_Strength);
					}
					if (!IsCleanse || GetKeyValueInt(TriggerKeys[activator], TriggerValues[activator], "is own talent?") == 1) {

						if (target != activator) {

							//AddTalentExperience(activator, "resilience", RoundToCeil(GetClassMultiplier(activator, p_Strength * 100.0, "reX", true, true)));
							//AddTalentExperience(activator, "technique", RoundToCeil(GetClassMultiplier(activator, p_Strength * 100.0, "teX", true, true)));
							AddTalentExperience(activator, "resilience", RoundToCeil(p_Strength * 100.0));
							AddTalentExperience(activator, "technique", RoundToCeil(p_Strength * 100.0));

							/*if (IsCommonInfected(target)) ActivateAbilityEx(activator, target, damagevalue, targeteffects, p_Strength, p_Time, target);
							if (IsWitch(target)) ActivateAbilityEx(activator, target, damagevalue, targeteffects, p_Strength, p_Time, target);
							if (IsLegitimateClient(target) && GetClientTeam(target) == TEAM_INFECTED) ActivateAbilityEx(activator, target, damagevalue, targeteffects, p_Strength, p_Time, target);
							if (IsLegitimateClient(target) && (GetClientTeam(target) == TEAM_SURVIVOR || IsSurvivorBot(target))) ActivateAbilityEx(activator, target, damagevalue, targeteffects, p_Strength, p_Time, target);*/
							
							ActivateAbilityEx(activator, target, damagevalue, targeteffects, p_Strength, p_Time, target);
						}
						else {

							if (StrContains(TalentName, "regen", false) != -1) {

								if (StrContains(ActiveClass[activator], "shaman", false) != -1) {

									ExplosiveAmmoRange = GetSpecialAmmoStrength(activator, "explosive ammo", 3, _, TheTalentStrength);
									if (!EnemiesWithinExplosionRange(activator, ExplosiveAmmoRange, p_Strength)) ActivateAbilityEx(activator, activator, damagevalue, activatoreffects, p_Strength, p_Time, target);
								}
								if (StrContains(ActiveClass[activator], "healer", false) != -1 && GetTalentStrength(activator, "healing ammo") > 0) {	// when a healers health regen tics, it heals all teammates nearby, too.

									healregenrange = GetSpecialAmmoStrength(activator, "healing ammo", 3) * 2.0;
									CreateRing(activator, healregenrange, "green:ignore", "20.0:30.0", false, 0.5);	// healer aura is always present on classes that support it.
									GetClientAbsOrigin(activator, healerpos);
									for (new y = 1; y <= MaxClients; y++) {

										if (y == activator) continue;	// client doesn't get double heal.
										if (IsLegitimateClientAlive(y) && (GetClientTeam(y) == TEAM_SURVIVOR || IsSurvivorBot(y)) && bIsInCombat[y]) {

											GetClientAbsOrigin(y, targetpos);
											if (GetVectorDistance(healerpos, targetpos) > healregenrange / 2) continue;

											HealPlayer(y, activator, p_Strength, 'h', true);
										}
									}
								}
							}
							ActivateAbilityEx(activator, activator, damagevalue, activatoreffects, p_Strength, p_Time, target);
						}
					}
					else t_Strength += (CleanseStack[activator] * p_Strength);
				}
				else t_Strength += p_Strength;
			}
			p_Strength = 0.0;
			p_Time = 0.0;
		}
	}
	if (damagevalue > 0) {

		if (ResultType == 0) return (t_Strength * damagevalue);
		if (ResultType == 1) return (damagevalue + (t_Strength * damagevalue));
	}
	return t_Strength;