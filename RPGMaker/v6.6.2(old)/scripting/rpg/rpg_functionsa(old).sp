/*
 *	Provides a shortcut method to calling ANY value from keys found in CONFIGS/READYUP/RPG/CONFIG.CFG
 *	@return		-1		if the requested key could not be found.
 *	@return		value	if the requested key is found.
 */
stock String:GetConfigValue(String:KeyName[]) {
	
	decl String:text[512];

	new a_Size			= GetArraySize(MainKeys);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:MainKeys, i, text, sizeof(text));

		if (StrEqual(text, KeyName)) {

			GetArrayString(Handle:MainValues, i, text, sizeof(text));
			return text;
		}
	}

	Format(text, sizeof(text), "-1");

	return text;
}

/*
 *	Checks if any non-bot survivors are incapacitated.
 *	@return		true/false		depending on the result.
 */
stock bool:AnySurvivorsIncapacitated() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsIncapacitated(i)) return true;
	}
	return false;
}

/*
 *	Checks if there are any non-bot, non-spectator players in the game.
 *	@return		true/false		depending on the result.
 */
stock bool:IsPlayersParticipating() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR) return true;
	}
	return false;
}

/*
 *	Finds a random, non-bot client in-game.
 *	@return		client index if found.
 *	@return		-1 if not found.
 */
stock FindAnyRandomClient() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i)) return i;
	}
	return -1;
}

stock bool:IsMeleeWeaponParameter(String:parameter[]) {

	if (StrEqual(parameter, "fireaxe", false) ||
		StrEqual(parameter, "cricket_bat", false) ||
		StrEqual(parameter, "tonfa", false) ||
		StrEqual(parameter, "frying_pan", false) ||
		StrEqual(parameter, "golfclub", false) ||
		StrEqual(parameter, "electric_guitar", false) ||
		StrEqual(parameter, "katana", false) ||
		StrEqual(parameter, "machete", false) ||
		StrEqual(parameter, "crowbar", false)) return true;
	return false;
}

stock GetMeleeWeaponDamage(attacker, victim, String:weapon[]) {

	new zombieclass				= FindZombieClass(victim);
	new size					= GetArraySize(a_Melee_Damage);
	new healthvalue				= 0;

	decl String:s_zombieclass[4];

	for (new i = 0; i < size; i++) {

		MeleeKeys[attacker]		= GetArrayCell(a_Melee_Damage, i, 0);
		MeleeValues[attacker]	= GetArrayCell(a_Melee_Damage, i, 1);
		MeleeSection[attacker]	= GetArrayCell(a_Melee_Damage, i, 2);

		GetArrayString(Handle:MeleeSection[attacker], 0, s_zombieclass, sizeof(s_zombieclass));
		if (StringToInt(s_zombieclass) == zombieclass) {

			healthvalue			= RoundToCeil(StringToFloat(GetKeyValue(MeleeKeys[attacker], MeleeValues[attacker], weapon)) * GetMaximumHealth(victim));
			if (healthvalue > GetClientTotalHealth(victim)) healthvalue		= GetClientTotalHealth(victim);
			return healthvalue;
		}
	}
	return 0;
}

/*
 *	Checks to see if the client has an active experience booster.
 *	If the client does, ExperienceValue is multiplied against the booster value and returned.
 *	@return (ExperienceValue * Multiplier)		where Multiplier is modified based on the result of AddMultiplier(client, i)
 */
stock Float:CheckExperienceBooster(client, ExperienceValue) {

	// Return ExperienceValue as it is if the client doesn't have a booster active.
	decl String:key[64];
	decl String:value[64];

	new Float:Multiplier					= 1.0;	// 1.0 is the DEFAULT (Meaning NO CHANGE)

	new size								= GetArraySize(a_Store);
	new size2								= 0;
	for (new i = 0; i < size; i++) {

		StoreKeys[client]					= GetArrayCell(a_Store, i, 0);
		StoreValues[client]					= GetArrayCell(a_Store, i, 1);

		size2								= GetArraySize(StoreKeys[client]);
		for (new ii = 0; ii < size2; ii++) {

			GetArrayString(StoreKeys[client], ii, key, sizeof(key));
			GetArrayString(StoreValues[client], ii, value, sizeof(value));

			if (StrEqual(key, "item effect?") && StrEqual(value, "x")) {

				Multiplier += AddMultiplier(client, i);		// If the client has no time in it, it just adds 0.0.
			}
		}
	}

	return (ExperienceValue * Multiplier);
}

/*
 *	Checks to see whether:
 *	a.) The position in the store is an experience booster
 *	b.) If it is, if the client has time remaining in it.
 *	@return		Float:value			time remaining on experience booster. 0.0 if it could not be found.
 */
stock Float:AddMultiplier(client, pos) {

	decl String:ClientValue[64];
	GetArrayString(a_Store_Player[client], pos, ClientValue, sizeof(ClientValue));

	decl String:key[64];
	decl String:value[64];

	if (StringToInt(ClientValue) > 0) {

		StoreMultiplierKeys[client]			= GetArrayCell(a_Store, pos, 0);
		StoreMultiplierValues[client]		= GetArrayCell(a_Store, pos, 1);

		new size							= GetArraySize(StoreMultiplierKeys[client]);
		for (new i = 0; i < size; i++) {

			GetArrayString(StoreMultiplierKeys[client], i, key, sizeof(key));
			GetArrayString(StoreMultiplierValues[client], i, value, sizeof(value));

			if (StrEqual(key, "item strength?")) return StringToFloat(value);
		}
	}

	return 0.0;		// It wasn't found, so no multiplier is added.
}

/*
 *	SDKHooks function.
 *	We're using it to prevent any melee damage, due to the bizarre way that melee damage is handled, it's hit or miss whether it is changed.
 *	@return Plugin_Changed		if a melee weapon was used.
 *	@return Plugin_Continue		if a melee weapon was not used.
 */
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {

	if (IsClientActual(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR && IsClientActual(victim) && GetClientTeam(victim) == TEAM_INFECTED) {

		decl String:weapon[64];
		GetClientWeapon(attacker, weapon, sizeof(weapon));
		if (StrEqual(weapon, "weapon_melee", false)) {

			//PrintToChat(attacker, "Damage: %3.3f, Target Max Health: %d", damage, GetMaximumHealth(victim));
			damage = 1.0;
			//PrintHintText(attacker, "%T", "melee against special", attacker);
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

/*
 *	Cycles through all given talents in the CONFIG/READYUP/RPG/SURVIVORMENU.CFG or CONFIG/READYUP/RPG/INFECTEDMENU.CFG
 *	file, respective to the activator's team, searching for any talent that has the ability char in its "ability trigger?" key
 *	and then activates it. If it can't be found in ANY of the talents, however, a logmessage, NOT A FAILSTATE, is returned.
 *	Prototype: void FindAbilityByTrigger(activator, int target = 0, char ability, int zombieclass = 0, int d_Damage)
 */
stock FindAbilityByTrigger(activator, target = 0, ability, zombieclass = 0, d_Damage) {

	if (IsLegitimateClient(activator) && ((IsFakeClient(activator) && GetClientTeam(activator) == TEAM_INFECTED) || !IsFakeClient(activator))) {

		new a_Size			=	0;

		// Zombieclass is either ignored or passed as 0 If the player is a survivor. See stock FindZombieClass(client)
		a_Size				= GetArraySize(a_Menu_Talents);	// All talents share the same array, now. No more splitting based on team.

		decl String:TalentName[64];
		for (new i = 0; i < a_Size; i++) {

			TriggerKeys[activator]				= GetArrayCell(a_Menu_Talents, i, 0);
			TriggerValues[activator]			= GetArrayCell(a_Menu_Talents, i, 1);
			TriggerSection[activator]			= GetArrayCell(a_Menu_Talents, i, 2);

			// We get the name of the talent. It's not actually used for anything when it's passed through the ActivateAbility function, but I wanted to
			// keep it in case I find a use for it, whether of debugging nature, or something else, later on.

			//PrintToChatAll("SIZE: %d", GetArraySize(TriggerSection[activator]));
			GetArrayString(Handle:TriggerSection[activator], 0, TalentName, sizeof(TalentName));

			// If the talent in question has an ability trigger that matches the ability trigger passed through, we call ActivateAbility.
			// Note that GetKeyValue(Handle:Keys, Handle:Values, String:KeyString) is similar to GetConfigValue, except it lets you pull values from ANY set of handles, so we aren't restricted
			// by any specific config file. In this case, we use the Handles pulled from the respective array, above.
			if (FindCharInString(GetKeyValue(TriggerKeys[activator], TriggerValues[activator], "ability trigger?"), ability) != -1) {

				ActivateAbility(activator, target, i, d_Damage, FindZombieClass(activator), TriggerKeys[activator], TriggerValues[activator], TalentName, ability);
			}
		}
	}
}

/*
 *	This function checks to make sure the activator and target, along with other variables like zombieclass are eligible.
 *	If they are, it calculates strength of effect, cooldowns, and other timers, and then rolls the TriggerAbility function.
 *	TriggerAbility essentially returns true if chance rolls aren't required for the talent, or has a chance to return true or false if they are, depending on its outcome.
 *	ActivateAbilityEx is called on a successful roll, given there are effects to cast on the respective player(s).
 *	void ActivateAbility(activator, target, int pos, int damage, int zombieclass, Handle:Keys, Handle:Values, String:TalentName[], char ability)
 */
stock ActivateAbility(activator, target, pos, damage, zombieclass, Handle:Keys, Handle:Values, String:TalentName[], ability) {

	if (IsLegitimateClientAlive(activator) && (target == 0 || (target > 0 && IsLegitimateClientAlive(target)))) {

		decl String:survivoreffects[64];
		decl String:infectedeffects[64];

		new Float:i_Strength			=	0.0;
		new Float:i_FirstPoint			=	0.0;
		new Float:i_EachPoint			=	0.0;
		new Float:i_Time				=	0.0;
		new Float:i_Cooldown			=	0.0;
		decl String:ClientZombieClass[64];
		decl String:VictimZombieClass[64];
		decl String:ClientZombieClassRequired[64];
		decl String:VictimZombieClassRequired[64];
		decl String:ClientModelRequired[64];
		decl String:ClientModel[64];

		if (GetClientTeam(activator) == TEAM_SURVIVOR) GetClientModel(activator, ClientModel, sizeof(ClientModel));
		else if (GetClientTeam(target) == TEAM_SURVIVOR) GetClientModel(target, ClientModel, sizeof(ClientModel));

		Format(ClientModelRequired, sizeof(ClientModelRequired), "-1");
		if (GetClientTeam(activator) == TEAM_SURVIVOR ||
			GetClientTeam(target) == TEAM_SURVIVOR) Format(ClientModelRequired, sizeof(ClientModelRequired), "%s", GetKeyValue(Keys, Values, "survivor required?"));

		Format(ClientZombieClassRequired, sizeof(ClientZombieClassRequired), "%s", GetKeyValue(Keys, Values, "activator class required?"));
		Format(VictimZombieClassRequired, sizeof(VictimZombieClassRequired), "%s", GetKeyValue(Keys, Values, "target class required?"));

		decl String:WeaponsPermitted[512];
		Format(WeaponsPermitted, sizeof(WeaponsPermitted), "ignore");

		decl String:WeaponsPermittedStrict[512];
		Format(WeaponsPermittedStrict, sizeof(WeaponsPermittedStrict), "ignore");

		Format(WeaponsPermitted, sizeof(WeaponsPermitted), "%s", GetKeyValue(Keys, Values, "weapons permitted?"));
		Format(WeaponsPermittedStrict, sizeof(WeaponsPermittedStrict), "%s", GetKeyValue(Keys, Values, "weapons permitted strict?"));
		decl String:PlayerWeapon[64];
		if (GetClientTeam(activator) == TEAM_INFECTED) Format(PlayerWeapon, sizeof(PlayerWeapon), "ignore");
		else GetClientWeapon(activator, PlayerWeapon, sizeof(PlayerWeapon));
		if (StrEqual(ClientModelRequired, "-1", false) || StrEqual(ClientModel, ClientModelRequired, false)) {

			if (StrEqual(WeaponsPermitted, "ignore", false) || StrEqual(WeaponsPermitted, "all", false) || StrContains(WeaponsPermitted, PlayerWeapon, false) != -1) {

				if (StrEqual(WeaponsPermittedStrict, "-1", false) || StrEqual(WeaponsPermittedStrict, "ignore", false) ||
					StrEqual(WeaponsPermittedStrict, "all", false) || StrEqual(WeaponsPermittedStrict, PlayerWeapon, false)) {

					if (target == 0) Format(VictimZombieClass, sizeof(VictimZombieClass), "-1");
					else {

						if (GetClientTeam(target) == TEAM_INFECTED) Format(VictimZombieClass, sizeof(VictimZombieClass), "%d", FindZombieClass(target));
						else Format(VictimZombieClass, sizeof(VictimZombieClass), "0");
					}
					if (GetClientTeam(activator) == TEAM_INFECTED) Format(ClientZombieClass, sizeof(ClientZombieClass), "%d", FindZombieClass(activator));
					else Format(ClientZombieClass, sizeof(ClientZombieClass), "0");

					if (IsLegitimateClient(activator) && (StrContains(ClientZombieClassRequired, "0", false) != -1 && GetClientTeam(activator) == TEAM_SURVIVOR ||
						StrContains(ClientZombieClassRequired, ClientZombieClass, false) != -1 && GetClientTeam(activator) == TEAM_INFECTED) &&
						(target == 0 || (IsLegitimateClient(target) && (StrContains(VictimZombieClassRequired, "0", false) != -1 && GetClientTeam(target) == TEAM_SURVIVOR ||
						StrContains(VictimZombieClassRequired, VictimZombieClass, false) != -1 && GetClientTeam(target) == TEAM_INFECTED)))) {

						//if (StrEqual(key, "class required?") && (StringToInt(value) == zombieclass || (StringToInt(value) == 0 && GetClientTeam(client) == TEAM_SURVIVOR) || zombieclass == 9)) {

						//if (!IsAbilityCooldown(client, TalentName) && !b_IsImmune[victim]) {

						if (!IsAbilityCooldown(activator, TalentName) && !IsAbilityImmune(target, TalentName)) {

							survivoreffects		=	FindAbilityEffects(activator, Keys, Values, 2, 0);
							infectedeffects		=	FindAbilityEffects(activator, Keys, Values, 3, 0);

							if (!IsFakeClient(activator)) i_Strength			=	GetTalentStrength(activator, TalentName) * 1.0;
							else i_Strength									=	GetTalentStrength(-1, TalentName) * 1.0;

							//i_Strength			=	1.0;
							if (i_Strength <= 0.0) return;	// Locked talents will appear as LESS THAN 0.0 (they will be -1.0)
								
							i_FirstPoint		=	StringToFloat(GetKeyValue(Keys, Values, "first point value?"));
							i_EachPoint			=	StringToFloat(GetKeyValue(Keys, Values, "increase per point?"));
							i_Strength			=	i_FirstPoint + (i_EachPoint * i_Strength);

							if (!IsFakeClient(activator)) i_Time				=	GetTalentStrength(activator, TalentName) * 1.0;
							else i_Time										=	GetTalentStrength(-1, TalentName) * 1.0;
							//i_Time					=	1.0;
							if (i_Time > 0.0) i_Time	*=	StringToFloat(GetKeyValue(Keys, Values, "ability time per point?"));

							if (!IsFakeClient(activator)) i_Cooldown			=	GetTalentStrength(activator, TalentName) * 1.0;
							else i_Cooldown									=	GetTalentStrength(-1, TalentName) * 1.0;

							i_Cooldown				=	StringToFloat(GetKeyValue(Keys, Values, "cooldown start?")) + (StringToFloat(GetKeyValue(Keys, Values, "cooldown per point?")) * i_Cooldown);
							//i_Cooldown				=	1.0;

							if (TriggerAbility(activator, target, ability, pos, Keys, Values, TalentName)) {	//	Don't need to check if the player has ability points since the roll is 0 if they don't.

								if (i_Cooldown > 0.0) {

									//if (IsFakeClient(client)) LogMessage("Creating Cooldown for %N by attacker %N for %3.3f seconds", victim, client, i_Cooldown);

									/*if (IsClientActual(victim)) {
										
										b_IsImmune[victim] = true;
										CreateTimer(i_Cooldown, Timer_IsNotImmune, victim, TIMER_FLAG_NO_MAPCHANGE);
									}*/
									if (IsClientActual(target)) CreateImmune(target, GetTalentPosition(target, TalentName), i_Cooldown);		// Immunities to individual talents so multiple talents can trigger!
									if (IsClientActual(activator)) CreateCooldown(activator, GetTalentPosition(activator, TalentName), i_Cooldown);	// Infected Bots don't have cooldowns between abilities! Mwahahahaha
								}

								if (!StrEqual(infectedeffects, "0")) {

									if (IsLegitimateClientAlive(activator) && GetClientTeam(activator) == TEAM_INFECTED) ActivateAbilityEx(activator, activator, damage, infectedeffects, i_Strength, i_Time);
									else if (IsLegitimateClientAlive(target) && GetClientTeam(target) == TEAM_INFECTED) ActivateAbilityEx(target, activator, damage, infectedeffects, i_Strength, i_Time);
								}
								if (!StrEqual(survivoreffects, "0")) {

									if (IsLegitimateClientAlive(activator) && GetClientTeam(activator) == TEAM_SURVIVOR) ActivateAbilityEx(activator, activator, damage, survivoreffects, i_Strength, i_Time);
									else if (IsLegitimateClientAlive(target) && GetClientTeam(target) == TEAM_SURVIVOR) ActivateAbilityEx(target, activator, damage, survivoreffects, i_Strength, i_Time);
								}
							}
						}
					}
				}
			}
		}
	}
}

stock bool:TriggerAbility(client, victim, ability, pos, Handle:Keys, Handle:Values, String:TalentName[]) {

	if (IsLegitimateClientAlive(client) && (victim == 0 || (victim > 0 && IsLegitimateClientAlive(victim)))) {

		decl String:key[64];
		decl String:value[64];

		new size = GetArraySize(Keys);
		for (new i = 0; i < size; i++) {

			GetArrayString(Handle:Keys, i, key, sizeof(key));
			GetArrayString(Handle:Values, i, value, sizeof(value));

			if (StrEqual(key, "ability trigger?")) {	// Chance roll is in survivor ability effects etc. not ability trigger. SHIT.

				//if (FindCharInString(value, ability) == -1) continue;
				if (FindCharInString(value, 'c') == -1) {				// No chance roll required to execute this ability.

					if (!IsClientActual(victim)) return true;			// Common infected, always returns true if there's no chance roll.
					if (HandicapDifference(client, victim) > 0 && !AbilityChanceSuccess(victim) || HandicapDifference(client, victim) == 0) return true;
				}
				else {													// Chance roll required to execute this ability.

					if (!IsClientActual(victim) && AbilityChanceSuccess(client) || IsClientActual(victim) && AbilityChanceSuccess(client) && !AbilityChanceSuccess(victim)) {

						if (FindCharInString(value, 'h') == -1 || AbilityChanceSuccess(client)) return true;
					}
				}
			}
		}
	}
	return false;
}

stock String:FindAbilityEffects(client, Handle:Keys, Handle:Values, team = 0, type) {

	decl String:value[64];
	//Format(value, sizeof(value), "-1");
	//if (IsLegitimateClient(client)) {

	decl String:key[64];

	new size = GetArraySize(Keys);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		GetArrayString(Handle:Values, i, value, sizeof(value));

		if (type == 0 && (StrEqual(key, "survivor ability effects?") && team == 2 || StrEqual(key, "infected ability effects?") && team == 3)) return value;
		else if (type == 1 && StrEqual(key, "team affected?")) return value;
	}
	//}
	return value;
}

stock bool:AbilityChanceSuccess(client) {

	if (IsLegitimateClientAlive(client)) {

		new pos				=	FindChanceRollAbility(client);

		if (pos == -1) SetFailState("Ability Requires \'C\' but no ability with effect \'C\' could be found.");

		decl String:talentname[64];

		new Float:i_FirstPoint	=	0.0;
		new Float:i_EachPoint	=	0.0;
		new i_Strength		=	0;
		new range			=	0;

		AbilityKeys[client]			= GetArrayCell(a_Menu_Talents, pos, 0);
		AbilityValues[client]		= GetArrayCell(a_Menu_Talents, pos, 1);
		AbilitySection[client]		= GetArrayCell(a_Menu_Talents, pos, 2);

		GetArrayString(Handle:AbilitySection[client], 0, talentname, sizeof(talentname));

		if (!IsFakeClient(client)) {

			i_Strength			=	GetTalentStrength(client, talentname);
			i_FirstPoint		=	(StringToFloat(GetKeyValue(AbilityKeys[client], AbilityValues[client], "first point value?")) * 100.0) + (Technique[client] * 0.1);
			i_EachPoint			=	StringToFloat(GetKeyValue(AbilityKeys[client], AbilityValues[client], "increase per point?")) + (Agility[client] * 0.1);
			range				=	RoundToCeil(1.0 / i_EachPoint - (Luck[client] * 0.1));
			i_EachPoint			*=	100.0;

			if (i_Strength == 0) return false;
			//i_Strength = 1;
			i_Strength			=	RoundToCeil(i_FirstPoint + (i_EachPoint * i_Strength) + (Strength[client] * 0.1));
		}
		else {

			i_Strength			=	GetTalentStrength(-1, talentname);
			i_FirstPoint		=	(StringToFloat(GetKeyValue(AbilityKeys[client], AbilityValues[client], "first point value?")) * 100.0) + (Technique_Bots * 0.1);
			i_EachPoint			=	StringToFloat(GetKeyValue(AbilityKeys[client], AbilityValues[client], "increase per point?")) + (Agility_Bots * 0.1);
			range				=	RoundToCeil(1.0 / i_EachPoint - (Luck_Bots * 0.1));
			i_EachPoint			*=	100.0;

			if (i_Strength == 0) i_FirstPoint = 0.0;
			i_Strength			=	RoundToCeil(i_FirstPoint + (i_EachPoint * i_Strength) + (Strength_Bots * 0.1));
		}

		range				=	GetRandomInt(1, range);

		if (range <= i_Strength) return true;
	}
	return false;
}

stock GetTalentStrength(client, String:TalentName[]) {

	decl String:text[64];
	//Format(text, sizeof(text), "-1");
	//if (IsLegitimateClient(client)) {

	new size				=	0;
	if (client != -1) size	=	GetArraySize(a_Database_PlayerTalents[client]);
	else size				=	GetArraySize(a_Database_PlayerTalents_Bots);

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:a_Database_Talents, i, text, sizeof(text));
		if (StrEqual(TalentName, text)) {

			if (client != -1) GetArrayString(Handle:a_Database_PlayerTalents[client], i, text, sizeof(text));
			else GetArrayString(Handle:a_Database_PlayerTalents_Bots, i, text, sizeof(text));
			break;
		}
	}
	return StringToInt(text);
}

stock String:GetKeyValue(Handle:Keys, Handle:Values, String:SearchKey[], String:DefaultValue[] = "none") {

	decl String:key[1024];
	decl String:value[1024];
	if (StrEqual(DefaultValue, "none", false)) Format(value, sizeof(value), "-1");
	else Format(value, sizeof(value), "%s", DefaultValue);

	new size = GetArraySize(Keys);
	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, key, sizeof(key));
		if (StrEqual(key, SearchKey)) {

			GetArrayString(Handle:Values, i, value, sizeof(value));
			break;
		}
	}
	return value;
}

stock FindChanceRollAbility(client) {

	if (IsLegitimateClientAlive(client)) {

		new a_Size			=	0;

		a_Size		= GetArraySize(a_Menu_Talents);

		decl String:TalentName[64];

		for (new i = 0; i < a_Size; i++) {

			ChanceKeys[client]			= GetArrayCell(a_Menu_Talents, i, 0);
			ChanceValues[client]		= GetArrayCell(a_Menu_Talents, i, 1);
			ChanceSection[client]		= GetArrayCell(a_Menu_Talents, i, 2);

			GetArrayString(Handle:ChanceSection[client], 0, TalentName, sizeof(TalentName));

			if (GetClientTeam(client) == TEAM_SURVIVOR && FindCharInString(GetKeyValue(ChanceKeys[client], ChanceValues[client], "survivor ability effects?"), 'C') != -1 ||
				GetClientTeam(client) == TEAM_INFECTED && FindCharInString(GetKeyValue(ChanceKeys[client], ChanceValues[client], "infected ability effects?"), 'C') != -1) {

				return i;
			}
		}
	}
	return -1;
}

stock GetWeaponSlot(entity) {

	if (IsValidEntity(entity)) {

		decl String:Classname[64];
		GetEdictClassname(entity, Classname, sizeof(Classname));

		if (StrContains(Classname, "pistol", false) != -1 || StrContains(Classname, "chainsaw", false) != -1) return 1;
		if (StrContains(Classname, "molotov", false) != -1 || StrContains(Classname, "pipe_bomb", false) != -1 || StrContains(Classname, "vomitjar", false) != -1) return 2;
		if (StrContains(Classname, "defib", false) != -1 || StrContains(Classname, "first_aid", false) != -1) return 3;
		if (StrContains(Classname, "adren", false) != -1 || StrContains(Classname, "pills", false) != -1) return 4;
		return 0;
	}
	return -1;
}

stock BeanBag(client, Float:force) {

	if (IsLegitimateClientAlive(client)) {

		if (L4D2_GetSurvivorVictim(client) != -1 || (GetEntityFlags(client) & FL_ONGROUND)) {

			new Float:Velocity[3];

			Velocity[0]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
			Velocity[1]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
			Velocity[2]	=	GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");

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
			new victim = L4D2_GetSurvivorVictim(client);
			if (victim != -1) TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, Velocity);
		}
	}
}

stock CreateCombustion(client, Float:g_Strength, Float:f_Time)
{
	new entity				= CreateEntityByName("env_fire");
	new Float:loc[3];
	GetClientAbsOrigin(client, loc);

	decl String:s_Strength[64];
	Format(s_Strength, sizeof(s_Strength), "%3.3f", g_Strength);

	DispatchKeyValue(entity, "StartDisabled", "0");
	DispatchKeyValue(entity, "damagescale", s_Strength);

	DispatchKeyValue(entity, "fireattack", "2");
	DispatchKeyValue(entity, "firesize", "128");
	DispatchKeyValue(entity, "health", "10");
	DispatchKeyValue(entity, "ignitionpoint", "1");
	DispatchSpawn(entity);

	TeleportEntity(entity, Float:loc, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "Enable");
	AcceptEntityInput(entity, "StartFire");
	
	CreateTimer(f_Time, Timer_DestroyCombustion, entity, TIMER_FLAG_NO_MAPCHANGE);
}

stock ZeroGravity(client, victim, Float:g_TalentStrength, Float:g_TalentTime) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(victim)) {

		if (L4D2_GetSurvivorVictim(victim) != -1 || ((GetEntityFlags(victim) & FL_ONGROUND) || !b_GroundRequired[victim])) {


		//if (GetEntityFlags(victim) & FL_ONGROUND || !b_GroundRequired[victim]) {

			//if (ZeroGravityTimer[victim] == INVALID_HANDLE) {

			new Float:vel[3];
			vel[0] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[0]");
			vel[1] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[1]");
			vel[2] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[2]");
			//ZeroGravityTimer[victim] = 
			CreateTimer(g_TalentTime, Timer_ZeroGravity, victim, TIMER_FLAG_NO_MAPCHANGE);
			SetEntityGravity(victim, GravityBase[victim] - g_TalentStrength);
			TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vel);

			new survivor = L4D2_GetSurvivorVictim(victim);
			if (survivor != -1) {

				//ZeroGravityTimer[survivor] = 
				CreateTimer(g_TalentTime, Timer_ZeroGravity, survivor, TIMER_FLAG_NO_MAPCHANGE);
				SetEntityGravity(survivor, GravityBase[survivor] - g_TalentStrength);
				TeleportEntity(survivor, NULL_VECTOR, NULL_VECTOR, vel);
			}
			//}
		}
	}
}

stock SpeedIncrease(client, Float:effectTime = 0.0, Float:amount = -1.0, bool:IsTeamAffected = false) {

	if (IsLegitimateClientAlive(client)) {

		//if (amount == -1.0) amount = SpeedMultiplierBase[client];

		/*if (effectTime == 0.0) {

			if (!IsFakeClient(client)) SpeedMultiplier[client] = SpeedMultiplierBase[client] + (Agility[client] * 0.01) + amount;
			else SpeedMultiplier[client] = SpeedMultiplierBase[client] + (Agility_Bots * 0.01) + amount;
		}
		else {*/

		if (amount >= 0.0) {

			SpeedMultiplier[client] = SpeedMultiplierBase[client] + amount;
			/*if (SpeedMultiplierTimer[client] != INVALID_HANDLE) {

				KillTimer(SpeedMultiplierTimer[client]);
				SpeedMultiplierTimer[client] = INVALID_HANDLE;
			}
			SpeedMultiplierTimer[client] = */
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[client]);
			CreateTimer(effectTime, Timer_SpeedIncrease, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else {

			SetSpeedMultiplierBase(client);
			//SpeedMultiplier[client] = SpeedMultiplierBase[client];
		}
		//LogMessage("%N Base: %3.3f amount: %3.3f Current: %3.3f", client, SpeedMultiplierBase[client], amount, SpeedMultiplier[client]);

		if (IsTeamAffected) {

			for (new i = 1; i <= MaxClients; i++) {

				if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == GetClientTeam(client) && client != i) {

					if (effectTime == 0.0) SpeedMultiplier[i] = SpeedMultiplierBase[i] + (Agility[i] * 0.01) + amount;
					else {

						SpeedMultiplier[i] = SpeedMultiplierBase[i] + amount;
						/*if (SpeedMultiplierTimer[i] != INVALID_HANDLE) {

							KillTimer(SpeedMultiplierTimer[i]);
							SpeedMultiplierTimer[i] = INVALID_HANDLE;
						}*/
						//SpeedMultiplierTimer[i] = 
						CreateTimer(effectTime, Timer_SpeedIncrease, i, TIMER_FLAG_NO_MAPCHANGE);
					}
					SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[i]);
				}
			}
		}
	}
}

stock SlowPlayer(client, Float:g_TalentStrength, Float:g_TalentTime) {

	if (IsLegitimateClientAlive(client)) {

		//if (SlowMultiplierTimer[client] != INVALID_HANDLE) {

		//	KillTimer(SlowMultiplierTimer[client]);
		//	SlowMultiplierTimer[client] = INVALID_HANDLE;
		//}
		SpeedMultiplier[client] = 1.0;
		//SlowMultiplierTimer[client] = 
		CreateTimer(g_TalentTime, Timer_SlowPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
		if (g_TalentStrength > 1.0 && g_TalentStrength < 100.0) g_TalentStrength *= 0.01;
		else if (g_TalentStrength > 1.0 && g_TalentStrength < 1000.0) g_TalentStrength *= 0.001;
		else if (g_TalentStrength > 1.0 && g_TalentStrength < 10000.0) g_TalentStrength *= 0.0001;
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[client] - g_TalentStrength);
	}
}

stock DamageIncrease(client, Float:effectTime = 0.0, Float:amount = 1.0, bool:IsTeamAffected) {

	if (IsLegitimateClientAlive(client)) {

		if (DamageMultiplierBase[client] == 0.0) BaseDamageMultiplier(client);
		DamageMultiplier[client] = DamageMultiplierBase[client];
		DamageMultiplier[client] += amount;
		if (effectTime > 0.0) {

			//if (DamageMultiplierTimer[client] != INVALID_HANDLE) {

				//KillTimer(DamageMultiplierTimer[client]);
				//DamageMultiplierTimer[client] = INVALID_HANDLE;
			//}
			//DamageMultiplierTimer[client] = 
			CreateTimer(effectTime, Timer_DamageIncrease, client, TIMER_FLAG_NO_MAPCHANGE);
		}

		if (IsTeamAffected) {

			for (new i = 1; i <= MaxClients; i++) {

				if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == GetClientTeam(client) && client != i) {

					if (DamageMultiplierBase[i] == 0.0) BaseDamageMultiplier(i);
					DamageMultiplier[i] = DamageMultiplierBase[i];
					DamageMultiplier[i] += amount;
					if (effectTime > 0.0) {

						//if (DamageMultiplierTimer[i] != INVALID_HANDLE) {

						//	KillTimer(DamageMultiplierTimer[i]);
						//	DamageMultiplierTimer[i] = INVALID_HANDLE;
						//}
						//DamageMultiplierTimer[i] = 
						CreateTimer(effectTime, Timer_DamageIncrease, i, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
}

stock CreateBeacons(client, Float:Distance) {

	new Float:Pos[3];
	new Float:Pos2[3];

	GetClientAbsOrigin(client, Pos);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsLegitimateClientAlive(i) && i != client && GetClientTeam(i) != GetClientTeam(client) && (GetClientTeam(i) == TEAM_SURVIVOR || (GetClientTeam(i) == TEAM_INFECTED && IsGhost(i)))) {

			GetClientAbsOrigin(i, Pos2);
			if (GetVectorDistance(Pos, Pos2) > Distance) continue;

			Pos2[2] += 20.0;
			TE_SetupBeamRingPoint(Pos2, 32.0, 128.0, g_iSprite, g_BeaconSprite, 0, 15, 0.5, 2.0, 0.5, {20, 20, 150, 150}, 50, 0);
			TE_SendToClient(client);
		}
	}
}

stock BlindPlayer(client, Float:effectTime = 3.0, amount = 0) {

	if (IsLegitimateClient(client) && !IsFakeClient(client) && !b_IsBlind[client]) {

		new clients[2];
		clients[0] = client;
		new UserMsg:BlindMsgID = GetUserMessageId("Fade");
		new Handle:message = StartMessageEx(BlindMsgID, clients, 1);
		BfWriteShort(message, 1536);
		BfWriteShort(message, 1536);
		
		if (amount == 0)
		{
			BfWriteShort(message, (0x0001 | 0x0010));
		}
		else
		{
			BfWriteShort(message, (0x0002 | 0x0008));
		}

		BfWriteByte(message, 255);
		BfWriteByte(message, 255);
		BfWriteByte(message, 255);
		
		if (!b_IsBlind[client] && amount > 0) {

			b_IsBlind[client] = true;
			CreateTimer(effectTime, Timer_BlindPlayer, client, TIMER_FLAG_NO_MAPCHANGE);
			BfWriteByte(message, amount);
		}
		else if (b_IsBlind[client] || amount <= 0) {

			b_IsBlind[client] = false;
			BfWriteByte(message, 0);
		}
		EndMessage();
	}
}

stock CreateFireEx(client)
{
	if (IsLegitimateClient(client)) {

		decl Float:pos[3];
		GetClientAbsOrigin(client, pos);
		CreateFire(pos);
	}
}

static const String:MODEL_GASCAN[] = "models/props_junk/gascan001a.mdl";
stock CreateFire(const Float:BombOrigin[3])
{
	new entity = CreateEntityByName("prop_physics");
	DispatchKeyValue(entity, "physdamagescale", "0.0");
	if (!IsModelPrecached(MODEL_GASCAN))
	{
		PrecacheModel(MODEL_GASCAN);
	}
	DispatchKeyValue(entity, "model", MODEL_GASCAN);
	DispatchSpawn(entity);
	TeleportEntity(entity, BombOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
	AcceptEntityInput(entity, "Break");
}

stock bool:IsTanksActive() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && GetClientTeam(i) == TEAM_INFECTED && FindZombieClass(i) == ZOMBIECLASS_TANK) return true;
	}
	return false;
}

stock bool:IsCoveredInBile(client) {

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsClientInGame(i)) continue;
		if (CoveredInBile[client][i] >= 0) return true;
	}
	return false;
}

stock ModifyGravity(client, Float:g_Gravity = 1.0, Float:g_Time = 0.0, bool:b_Jumping = false) {

	if (IsLegitimateClientAlive(client)) {

		//if (b_IsJumping[client]) return;	// survivors only, for the moon jump ability
		if (b_Jumping) {

			b_IsJumping[client] = true;
			CreateTimer(0.1, Timer_DetectGroundTouch, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		if (g_Gravity == 1.0) SetEntityGravity(client, g_Gravity);
		else {

			if (g_Gravity > 1.0 && g_Gravity < 100.0) g_Gravity *= 0.01;
			else if (g_Gravity > 1.0 && g_Gravity < 1000.0) g_Gravity *= 0.001;
			else if (g_Gravity > 1.0 && g_Gravity < 10000.0) g_Gravity *= 0.0001;
			SetEntityGravity(client, 1.0 - g_Gravity);
		}
		if (g_Gravity < 1.0 && !b_Jumping) CreateTimer(g_Time, Timer_ResetGravity, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock GetReviveHealth() {

	return RoundToCeil(GetConVarFloat(FindConVar("survivor_revive_health")));
}

stock SetTempHealth(activator, target, Float:s_Strength) {

	if (IsLegitimateClientAlive(target)) {

		new Float:TempHealth	= GetMaximumHealth(activator) * s_Strength;

		SetEntPropFloat(target, Prop_Send, "m_healthBuffer", GetConVarFloat(FindConVar("survivor_revive_health")) + TempHealth);
	}
}

stock SetMaximumHealth(client, bool:b_HealthModifier = false, Float:s_Strength = 0.0) {

	if (IsLegitimateClientAlive(client) && IsFakeClient(client) || IsLegitimateClient(client) && !IsFakeClient(client)) {

		if (b_HealthModifier) SetEntProp(client, Prop_Send, "m_iMaxHealth", RoundToFloor(DefaultHealth[client] + s_Strength));
		else {

			//if (GetClientTeam(client) == TEAM_INFECTED) DefaultHealth[client] = GetMaximumHealth(client);DefaultHealth[client]	=	100;

			//SetEntProp(client, Prop_Send, "m_iMaxHealth", RoundToFloor(GetMaximumHealth(client) + (s_Strength * GetMaximumHealth(client))));
			if (IsFakeClient(client)) SetEntProp(client, Prop_Send, "m_iMaxHealth", RoundToFloor(s_Strength));
			else if (GetClientTeam(client) == TEAM_SURVIVOR) SetEntProp(client, Prop_Send, "m_iMaxHealth", 100 + RoundToFloor(s_Strength * 100));
			else if (GetClientTeam(client) == TEAM_INFECTED) SetEntProp(client, Prop_Send, "m_iMaxHealth", DefaultHealth[client]);
			//DefaultHealth[client]	=	GetMaximumHealth(client);
		}
	}
}

stock SetBaseHealth(client) {

	SetEntProp(client, Prop_Send, "m_iMaxHealth", OriginalHealth[client]);
}

stock GiveMaximumHealth(client)
{
	if (IsLegitimateClientAlive(client)) {

		if (!b_HardcoreMode[client]) {

			SetEntityHealth(client, GetMaximumHealth(client));
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
		}
		else {

			SetEntityHealth(client, 1);
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", (GetMaximumHealth(client) - 1) * 1.0);
		}
	}
}

stock GetMaximumHealth(client)
{
	if (IsLegitimateClient(client)) return GetEntProp(client, Prop_Send, "m_iMaxHealth");
	else return 0;
}

stock CloakingDevice(client, Float:s_Strength, Float:g_Time) {

	if (IsLegitimateClientAlive(client)) {

		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255 - RoundToCeil(s_Strength));
		CreateTimer(g_Time, Timer_CloakingDeviceBreakdown, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock AbsorbDamage(client, Float:s_Strength, damage) {

	if (IsLegitimateClientAlive(client)) {

		if (GetClientTeam(client) == TEAM_INFECTED || !IsIncapacitated(client)) {

			new absorb = RoundToFloor(s_Strength);
			if (absorb > damage) absorb = damage;

			SetEntityHealth(client, GetClientHealth(client) + absorb);
		}
	}
}

stock DamagePlayer(client, victim, Float:s_Strength) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(victim)) {

		new d_Damage = RoundToFloor(s_Strength);

		if (GetClientHealth(victim) > 1) {

			if (GetClientHealth(victim) + 1 < d_Damage) d_Damage = GetClientHealth(victim) - 1;
			if (d_Damage > 0) {

				DamageAward[client][victim] += d_Damage;
				SetEntityHealth(victim, GetClientHealth(victim) - d_Damage);
			}
		}
	}
}

stock ModifyHealth(client, Float:s_Strength, Float:g_Time) {

	if (IsLegitimateClientAlive(client)) {

		if (g_Time > 0.0) {

			SetMaximumHealth(client, true, s_Strength);
			CreateTimer(g_Time, Timer_ResetPlayerHealth, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else {

			if (GetClientTeam(client) == TEAM_INFECTED) {

				DefaultHealth[client] += RoundToCeil(OriginalHealth[client] * s_Strength);
				SetMaximumHealth(client, false, DefaultHealth[client] * 1.0);
			}
			else SetMaximumHealth(client, false, s_Strength);		// false means permanent.
		}
	}
}

stock ReflectDamage(client, victim, Float:g_TalentStrength, d_Damage) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(victim)) {

		new reflectHealth = RoundToFloor(g_TalentStrength);
		new reflectValue = 0;
		if (reflectHealth > d_Damage) reflectHealth = d_Damage;
		if (!IsIncapacitated(client) && IsPlayerAlive(client)) {

			if (GetClientHealth(client) > reflectHealth) reflectValue = reflectHealth;
			else reflectValue = GetClientHealth(client) - 1;
			SetEntityHealth(client, GetClientHealth(client) - reflectValue);
			DamageAward[client][victim] -= reflectValue;
			DamageAward[victim][client] += reflectValue;
		}
	}
}

stock SendPanelToClientAndClose(Handle:panel, client, MenuHandler:handler, time) {

	SendPanelToClient(panel, client, handler, time);
	CloseHandle(panel);
}

stock CreateAcid(client, victim, Float:radius = 128.0) {

	if (IsLegitimateClientAlive(client) && IsFakeClient(client) || IsLegitimateClient(client) && !IsFakeClient(client)) {

		if (IsLegitimateClientAlive(victim)) {

			decl Float:pos[3];
			GetClientAbsOrigin(victim, pos);
			pos[2] += 12.0;
			new acidball = CreateEntityByName("spitter_projectile");
			if (IsValidEntity(acidball)) {

				DispatchSpawn(acidball);
				SetEntPropEnt(acidball, Prop_Send, "m_hThrower", client);
				SetEntPropFloat(acidball, Prop_Send, "m_DmgRadius", radius);
				SetEntProp(acidball, Prop_Send, "m_bIsLive", 1);
				TeleportEntity(acidball, pos, NULL_VECTOR, NULL_VECTOR);
				SDKCall(g_hCreateAcid, acidball);
			}
		}
	}
}

stock ForceClientJump(client, victim, Float:g_TalentStrength) {

	if (IsLegitimateClientAlive(victim)) {

		if (GetEntityFlags(victim) & FL_ONGROUND || !b_GroundRequired[victim]) {

			new attacker = L4D2_GetInfectedAttacker(victim);
			if (attacker == -1 || !IsClientActual(attacker) || GetClientTeam(attacker) != TEAM_INFECTED || (FindZombieClass(attacker) != ZOMBIECLASS_JOCKEY && FindZombieClass(attacker) != ZOMBIECLASS_CHARGER)) attacker = -1;

			if (IsClientActual(victim)) {

				new Float:vel[3];
				vel[0] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[0]");
				vel[1] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[1]");
				vel[2] = GetEntPropFloat(victim, Prop_Send, "m_vecVelocity[2]");
				vel[2] += g_TalentStrength;
				TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vel);
				if (attacker != -1) TeleportEntity(attacker, NULL_VECTOR, NULL_VECTOR, vel);
			}
		}
	}
}

stock ActivateAbilityEx(target, activator, d_Damage, String:Effects[], Float:g_TalentStrength, Float:g_TalentTime) {

	// Activator is ALWAYS the person who holds the talent. The TARGET is who the ability ALWAYS activates on.

	if (g_TalentStrength > 0.0) {

		if (FindCharInString(Effects, 'a') != -1) SDKCall(g_hEffectAdrenaline, target, g_TalentTime);
		if (FindCharInString(Effects, 'A') != -1 && GetClientTeam(target) == TEAM_SURVIVOR) {

			SDKCall(hRoundRespawn, target);
			CreateTimer(0.2, Timer_TeleportRespawn, target, TIMER_FLAG_NO_MAPCHANGE);
		}
		if (FindCharInString(Effects, 'b') != -1) BeanBag(target, g_TalentStrength);
		if (FindCharInString(Effects, 'B') != -1) BlindPlayer(target, g_TalentTime, RoundToFloor((g_TalentStrength * 100.0) * 2.55));
		if (FindCharInString(Effects, 'c') != -1) CreateCombustion(target, g_TalentStrength, g_TalentTime);
		if (FindCharInString(Effects, 'd') != -1) DamageIncrease(target, g_TalentTime, g_TalentStrength, false);
		if (FindCharInString(Effects, 'D') != -1) DamageIncrease(target, g_TalentTime, g_TalentStrength, true);
		if (FindCharInString(Effects, 'f') != -1) CreateFireEx(target);
		if (FindCharInString(Effects, 'e') != -1) CreateBeacons(target, g_TalentStrength);
		if (FindCharInString(Effects, 'E') != -1) SetTempHealth(activator, target, g_TalentStrength);
		if (FindCharInString(Effects, 'g') != -1) ModifyGravity(target, g_TalentStrength, g_TalentTime, true);
		if (FindCharInString(Effects, 'h') != -1) HealPlayer(target, activator, g_TalentStrength, 'h');
		if (FindCharInString(Effects, 'H') != -1) ModifyHealth(target, g_TalentStrength, g_TalentTime);
		if (FindCharInString(Effects, 'i') != -1) {

			SDKCall(g_hCallVomitOnPlayer, activator, target, true);
			CoveredInBile[target][activator] = 0;
			new Handle:pack;
			CreateDataTimer(g_TalentTime, Timer_CoveredInBile, pack, TIMER_FLAG_NO_MAPCHANGE);
			WritePackCell(pack, activator);
			WritePackCell(pack, target);
		}
		if (FindCharInString(Effects, 'j') != -1) ForceClientJump(activator, target, g_TalentStrength);
		if (FindCharInString(Effects, 'k') != -1) {

			if (GetClientTeam(target) == TEAM_INFECTED) CalculateDamageAward(target);
			ForcePlayerSuicide(target);
		}
		if (FindCharInString(Effects, 'l') != -1) CloakingDevice(target, g_TalentStrength, g_TalentTime);
		if (FindCharInString(Effects, 'm') != -1) DamagePlayer(activator, target, g_TalentStrength);
		if (FindCharInString(Effects, 'o') != -1) AbsorbDamage(target, g_TalentStrength, d_Damage);
		if (FindCharInString(Effects, 'p') != -1) SpeedIncrease(target, g_TalentTime, g_TalentStrength, false);
		if (FindCharInString(Effects, 'P') != -1) SpeedIncrease(target, g_TalentTime, g_TalentStrength, true);
		if (FindCharInString(Effects, 'r') != -1) if (GetClientTeam(target) == TEAM_SURVIVOR && IsIncapacitated(target)) SDKCall(hRevive, target);
		if (FindCharInString(Effects, 'R') != -1) ReflectDamage(activator, target, g_TalentStrength, d_Damage);
		if (FindCharInString(Effects, 's') != -1) SlowPlayer(target, g_TalentStrength, g_TalentTime);
		if (FindCharInString(Effects, 'S') != -1) L4D_StaggerPlayer(target, activator, NULL_VECTOR);
		if (FindCharInString(Effects, 't') != -1) CreateAcid(activator, target, 512.0);
		if (FindCharInString(Effects, 'T') != -1) HealPlayer(target, activator, g_TalentStrength, 'T');
		if (FindCharInString(Effects, 'x') != -1) {

			if (IsPlayerAlive(target) && !IsGhost(target) && GetClientTeam(target) == TEAM_INFECTED && FindZombieClass(target) == ZOMBIECLASS_BOOMER) {

				SetEntityHealth(target, 1);
				IgniteEntity(target, 1.0);
			}
		}
		if (FindCharInString(Effects, 'z') != -1) ZeroGravity(activator, target, g_TalentStrength, g_TalentTime);
	}
}

stock bool:RestrictedWeaponList(String:WeaponName[]) {	// Some weapons might be insanely powerful, so we see if they're in this string and don't let them damage multiplier if they are.

	decl String:RestrictedWeapons[512];
	Format(RestrictedWeapons, sizeof(RestrictedWeapons), "%s", GetConfigValue("restricted weapons?"));
	if (StrContains(RestrictedWeapons, WeaponName, false) != -1) return true;
	return false;
}

stock CheckExperienceRequirement(client, bool:bot = false) {

	new experienceRequirement = 0;
	if (client == -1 || IsLegitimateClient(client)) {

		experienceRequirement			=	StringToInt(GetConfigValue("experience start?"));
		new Float:experienceMultiplier	=	0.0;

		if (client != -1) experienceMultiplier		=	StringToFloat(GetConfigValue("requirement multiplier?")) * (PlayerLevel[client] - 1);
		else experienceMultiplier					=	StringToFloat(GetConfigValue("requirement multiplier?")) * (PlayerLevel_Bots - 1);

		experienceRequirement			+=	RoundToCeil(experienceRequirement * experienceMultiplier);
	}

	return experienceRequirement;
}

stock BaseDamageMultiplier(client, const String:WeaponName[] = "none") {

	if (IsLegitimateClientAlive(client)) {

		if (!IsFakeClient(client)) DamageMultiplierBase[client] = StringToFloat(GetConfigValue("default damage multiplier?")) + (Strength[client] * 0.01);
		else DamageMultiplierBase[client] = StringToFloat(GetConfigValue("default damage multiplier?")) + (Strength_Bots * 0.01);
		if (DamageMultiplier[client] < DamageMultiplierBase[client]) DamageMultiplier[client] = DamageMultiplierBase[client];
	}
}

stock bool:IsAbilityImmune(client, String:TalentName[]) {

	if (IsClientActual(client)) {

		new a_Size				=	0;
		if (!IsFakeClient(client)) a_Size					=	GetArraySize(a_Database_PlayerTalents[client]);
		else a_Size											=	GetArraySize(a_Database_PlayerTalents_Bots);

		decl String:Name[PLATFORM_MAX_PATH];

		for (new i = 0; i < a_Size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {

				decl String:t_Cooldown[8];
				if (!IsFakeClient(client)) GetArrayString(Handle:PlayerAbilitiesImmune[client], i, t_Cooldown, sizeof(t_Cooldown));
				else GetArrayString(Handle:PlayerAbilitiesImmune_Bots, i, t_Cooldown, sizeof(t_Cooldown));
				if (StrEqual(t_Cooldown, "1")) return true;
				break;
			}
		}
	}
	return false;
}

stock bool:IsAbilityCooldown(client, String:TalentName[]) {

	if (IsClientActual(client)) {

		new a_Size				=	0;
		if (!IsFakeClient(client)) a_Size					=	GetArraySize(a_Database_PlayerTalents[client]);
		else a_Size											=	GetArraySize(a_Database_PlayerTalents_Bots);

		decl String:Name[PLATFORM_MAX_PATH];

		for (new i = 0; i < a_Size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {

				decl String:t_Cooldown[8];
				if (!IsFakeClient(client)) GetArrayString(Handle:PlayerAbilitiesCooldown[client], i, t_Cooldown, sizeof(t_Cooldown));
				else GetArrayString(Handle:PlayerAbilitiesCooldown_Bots, i, t_Cooldown, sizeof(t_Cooldown));
				if (StrEqual(t_Cooldown, "1")) return true;
				break;
			}
		}
	}
	return false;
}

stock GetTalentPosition(client, String:TalentName[]) {

	new pos = 0;
	if (IsClientActual(client)) {

		new a_Size				=	0;
		if (!IsFakeClient(client)) a_Size					=	GetArraySize(a_Database_PlayerTalents[client]);
		else a_Size											=	GetArraySize(a_Database_PlayerTalents_Bots);

		decl String:Name[PLATFORM_MAX_PATH];

		for (new i = 0; i < a_Size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {

				pos = i;
				break;
			}
		}
	}
	return pos;
}

stock RemoveImmunities(client) {

	// We remove all immunities when a round ends, otherwise they may not properly remove and then players become immune, forever.
	new size = 0;
	if (client == -1) {

		size = GetArraySize(PlayerAbilitiesImmune_Bots);
		for (new i = 0; i < size; i++) {

			SetArrayString(PlayerAbilitiesImmune_Bots, i, "0");
			SetArrayString(PlayerAbilitiesCooldown_Bots, i, "0");
		}
		for (new i = 1; i <= MAXPLAYERS; i++) {

			RemoveImmunities(i);
		}
	}
	else {

		size = GetArraySize(PlayerAbilitiesImmune[client]);
		for (new i = 0; i < size; i++) {

			SetArrayString(PlayerAbilitiesImmune[client], i, "0");
			SetArrayString(PlayerAbilitiesCooldown[client], i, "0");
		}
	}
}

stock CreateImmune(client, pos, Float:f_Cooldown) {

	if (IsLegitimateClient(client)) {

		if (!IsFakeClient(client)) SetArrayString(PlayerAbilitiesImmune[client], pos, "1");
		else SetArrayString(PlayerAbilitiesImmune_Bots, pos, "1");

		new Handle:pack;
		CreateDataTimer(f_Cooldown, Timer_RemoveImmune, pack, TIMER_FLAG_NO_MAPCHANGE);
		if (IsFakeClient(client)) client = -1;
		WritePackCell(pack, client);
		WritePackCell(pack, pos);
	}
}

stock CreateCooldown(client, pos, Float:f_Cooldown) {

	if (IsLegitimateClient(client)) {

		//if (GetArraySize(PlayerAbilitiesCooldown[client]) < pos) ResizeArray(PlayerAbilitiesCooldown[client], pos + 1);
		if (!IsFakeClient(client)) SetArrayString(PlayerAbilitiesCooldown[client], pos, "1");
		else SetArrayString(PlayerAbilitiesCooldown_Bots, pos, "1");

		new Handle:pack;
		CreateDataTimer(f_Cooldown, Timer_RemoveCooldown, pack, TIMER_FLAG_NO_MAPCHANGE);
		if (IsFakeClient(client)) client = -1;
		WritePackCell(pack, client);
		WritePackCell(pack, pos);
	}
}

stock bool:HasAbilityPoints(client, String:TalentName[]) {

	if (IsLegitimateClientAlive(client)) {

		// Check if the player has any ability points in the specified ability

		new a_Size				=	0;
		if (client != -1) a_Size		=	GetArraySize(a_Database_PlayerTalents[client]);
		else a_Size						=	GetArraySize(a_Database_PlayerTalents_Bots);

		decl String:Name[PLATFORM_MAX_PATH];

		for (new i = 0; i < a_Size; i++) {

			GetArrayString(Handle:a_Database_Talents, i, Name, sizeof(Name));
			if (StrEqual(Name, TalentName)) {

				if (client != -1) GetArrayString(Handle:a_Database_PlayerTalents[client], i, Name, sizeof(Name));
				else GetArrayString(Handle:a_Database_PlayerTalents_Bots, i, Name, sizeof(Name));
				if (StringToInt(Name) > 0) return true;
			}
		}
	}
	return false;
}

stock AwardSkyPoints(client, amount) {

	SkyPoints[client] += amount;
	decl String:Name[64];
	GetClientName(client, Name, sizeof(Name));
	PrintToChatAll("%t", "Sky Points Award", green, amount, orange, GetConfigValue("sky points menu name?"), white, green, Name, white);
}

stock String:GetTimePlayed(client) {

	decl String:text[64];
	new seconds				=	TimePlayed[client];
	new days				=	0;
	while (seconds >= 86400) {

		days++;
		seconds -= 86400;
	}
	new hours				=	0;
	while (seconds >= 3600) {

		hours++;
		seconds -= 3600;
	}
	new minutes				=	0;
	while (seconds >= 60) {

		minutes++;
		seconds -= 60;
	}
	decl String:Days_t[64];
	decl String:Hours_t[64];
	decl String:Minutes_t[64];
	decl String:Seconds_t[64];

	if (days > 0 && days < 10) Format(Days_t, sizeof(Days_t), "0%d", days);
	else if (days >= 10) Format(Days_t, sizeof(Days_t), "%d", days);
	else Format(Days_t, sizeof(Days_t), "0");
	if (hours > 0 && hours < 10) Format(Hours_t, sizeof(Hours_t), "0%d", hours);
	else if (hours >= 10) Format(Hours_t, sizeof(Hours_t), "%d", hours);
	else Format(Hours_t, sizeof(Hours_t), "0");
	if (minutes > 0 && minutes < 10) Format(Minutes_t, sizeof(Minutes_t), "0%d", minutes);
	else if (minutes >= 10) Format(Minutes_t, sizeof(Minutes_t), "%d", minutes);
	else Format(Minutes_t, sizeof(Minutes_t), "0");
	if (seconds > 0 && seconds < 10) Format(Seconds_t, sizeof(Seconds_t), "0%d", seconds);
	else if (seconds >= 10) Format(Seconds_t, sizeof(Seconds_t), "%d", seconds);
	else Format(Seconds_t, sizeof(Seconds_t), "0");

	Format(text, sizeof(text), "%T", "Time Played", client, Days_t, Hours_t, Minutes_t, Seconds_t);
	return text;
}

stock GetUpgradeExperienceCost(client, bool:b_IsLevelUp = false) {

	new experienceCost = 0;
	if (client == -1 || IsLegitimateClient(client)) {

		if (client == -1) return RoundToCeil(CheckExperienceRequirement(-1) * ((PlayerLevelUpgrades_Bots + 1) * StringToFloat(GetConfigValue("upgrade experience cost?"))));
		
		//new Float:Multiplier		= (PlayerUpgradesTotal[client] * 1.0) / (MaximumPlayerUpgrades(client) * 1.0);
		experienceCost		= RoundToCeil(CheckExperienceRequirement(client) * ((PlayerLevelUpgrades[client] + 1) * StringToFloat(GetConfigValue("upgrade experience cost?"))));
		//experienceCost				= RoundToCeil(CheckExperienceRequirement(client) * Multiplier);
	}
	return experienceCost;
}

stock PrintToSurvivors(RPGMode, String:SurvivorName[], String:InfectedName[], SurvExp, Float:SurvPoints) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) {

			if (RPGMode == 1) PrintToChat(i, "%T", "Experience Earned Total Team Survivor", i, white, blue, white, orange, white, green, white, SurvivorName, InfectedName, SurvExp);
			else if (RPGMode == 2) PrintToChat(i, "%T", "Experience Points Earned Total Team Survivor", i, white, blue, white, orange, white, green, white, green, white, SurvivorName, InfectedName, SurvExp, SurvPoints);
		}
	}
}

stock PrintToInfected(RPGMode, String:SurvivorName[], String:InfectedName[], InfTotalExp, Float:InfTotalPoints) {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED) {

			if (RPGMode == 1) PrintToChat(i, "%T", "Experience Earned Total Team", i, white, orange, white, green, white, InfectedName, InfTotalExp);
			else if (RPGMode == 2) PrintToChat(i, "%T", "Experience Points Earned Total Team", i, white, orange, white, green, white, green, white, InfectedName, InfTotalExp, InfTotalPoints);
		}
	}
}

stock ClearRelevantData() {

	for (new i = 1; i <= MaxClients; i++) {

		if (!IsClientActual(i) || !IsClientInGame(i)) continue;
		Points[i]					= 0.0;
		b_IsBlind[i]				= false;
		b_IsImmune[i]				= false;
		b_IsJumping[i]				= false;
		CommonKills[i]				= 0;
		CommonKillsHeadshot[i]		= 0;
		bIsMeleeCooldown[i]			= false;

		ResetOtherData(i);
	}
}

stock ResetOtherData(client) {

	if (IsLegitimateClient(client)) {

		for (new i = 1; i <= MAXPLAYERS; i++) {

			DamageAward[client][i]		=	0;
			DamageAward[i][client]		=	0;
			CoveredInBile[client][i]	=	-1;
			CoveredInBile[i][client]	=	-1;
		}
	}
}

stock LivingSurvivors() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) count++;
	}
	return count;
}

stock LivingHumanSurvivors() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) count++;
	}
	return count;
}

stock HumanPlayersInGame() {

	new count = 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SPECTATOR) count++;
	}
	return count;
}

public Action:Cmd_ResetTPL(client, args) { PlayerLevelUpgrades[client] = 0; }

stock ExperienceBuyLevel(client, bool:bot = false) {

	decl String:Name[64];
	if (!bot) {

		if (ExperienceLevel[client] == CheckExperienceRequirement(client)) {

			ExperienceLevel[client]		=	0;
			PlayerLevelUpgrades[client] = 0;
			PlayerLevel[client]++;

			GetClientName(client, Name, sizeof(Name));

			PrintToChatAll("%t", "player level up", green, white, green, Name, PlayerLevel[client]);
		}
	}
	else {

		if (ExperienceLevel_Bots == CheckExperienceRequirement(-1)) {

			ExperienceOverall_Bots += ExperienceLevel_Bots;
			ExperienceLevel_Bots		=	0;
			PlayerLevelUpgrades_Bots = 0;
			PlayerLevel_Bots++;

			Format(Name, sizeof(Name), "%s", GetConfigValue("director team name?"));
			PrintToChatAll("%t", "player level up", green, white, green, Name, PlayerLevel_Bots);
		}
	}

	BuildMenu(client);
}

stock String:FormatDatabase() {
	
	decl String:text[PLATFORM_MAX_PATH];

	new a_Size			=	GetArraySize(MainKeys);
}

stock bool:StringExistsArray(String:Name[], Handle:array) {

	decl String:text[PLATFORM_MAX_PATH];

	new a_Size			=	GetArraySize(array);

	for (new i = 0; i < a_Size; i++) {

		GetArrayString(Handle:array, i, text, sizeof(text));

		if (StrEqual(Name, text)) return true;
	}

	return false;
}

stock String:AddCommasToString(value) 
{
	new String:buffer[128];
	new String:separator[1];
	separator = ",";
	buffer[0] = '\0'; 
	new divisor = 1000; 
	
	while (value >= 1000 || value <= -1000)
	{
		new offcut = value % divisor;
		value = RoundToFloor(float(value) / float(divisor));
		Format(buffer, sizeof(buffer), "%s%03.d%s", separator, offcut, buffer); 
	}
	
	Format(buffer, sizeof(buffer), "%d%s", value, buffer);
	return buffer;
}

stock HandicapDifference(client, target) {

	if (IsLegitimateClientAlive(client) && IsLegitimateClientAlive(target)) {

		new clientLevel = 0;
		new targetLevel = 0;

		if (!IsFakeClient(client)) clientLevel = PlayerLevel[client];
		else clientLevel = PlayerLevel_Bots;

		if (!IsFakeClient(target)) targetLevel = PlayerLevel[target];
		else targetLevel = PlayerLevel_Bots;

		if (targetLevel < clientLevel) {
		
			new dif = clientLevel - targetLevel;
			new han = StringToInt(GetConfigValue("handicap level difference required?"));

			if (dif > han) return (dif - han);
		}
	}
	return 0;
}

public OnEntityCreated(entity, const String:classname[]) {

	if (b_IsActiveRound && StrEqual(classname, "infected", false)) {

		if (GetArraySize(CommonInfectedQueue) > 0) {

			decl String:Model[64];
			GetArrayString(Handle:CommonInfectedQueue, 0, Model, sizeof(Model));
			if (IsModelPrecached(Model)) SetEntityModel(entity, Model);
			RemoveFromArray(Handle:CommonInfectedQueue, 0);
		}
	}
	/*if (StrContains(classname, "defibrillator", false) != -1) {

		if (!AcceptEntityInput(entity, "Kill")) RemoveEdict(entity);
	}*/
	/*else if (StrContains(classname, "melee", false) != -1) {

		if (!AcceptEntityInput(entity, "Kill")) RemoveEdict(entity);
	}*/
}

stock ExperienceBarBroadcast(client) {

	new BroadcastType			=	StringToInt(GetConfigValue("hint text type?"));

	if (BroadcastType == 0) PrintHintText(client, "%T", "Hint Text Broadcast 0", client, ExperienceBar(client));
	if (BroadcastType == 1) PrintHintText(client, "%T", "Hint Text Broadcast 1", client, ExperienceBar(client), AddCommasToString(ExperienceLevel[client]), AddCommasToString(CheckExperienceRequirement(client)));
	if (BroadcastType == 2) PrintHintText(client, "%T", "Hint Text Broadcast 2", client, ExperienceBar(client), AddCommasToString(ExperienceLevel[client]), AddCommasToString(CheckExperienceRequirement(client)), Points[client]);
}

stock String:ExperienceBar(client) {

	decl String:eBar[128];
	new Float:ePct = 0.0;
	ePct = ((ExperienceLevel[client] * 1.0) / (CheckExperienceRequirement(client) * 1.0)) * 100.0;

	new Float:eCnt = 0.0;
	Format(eBar, sizeof(eBar), "[........................................]");

	for (new i = 1; i + 1 <= strlen(eBar); i++) {

		if (eCnt < ePct) {

			eBar[i] = '|';
			eCnt += 2.5;
		}
	}

	return eBar;
}

stock ChangeInfectedClass(client, zombieclass) {

	if (IsLegitimateClient(client) && !IsFakeClient(client) || IsLegitimateClientAlive(client) && IsFakeClient(client)) {

		if (GetClientTeam(client) == TEAM_INFECTED) {

			if (!IsGhost(client)) SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
			new wi;
			while ((wi = GetPlayerWeaponSlot(client, 0)) != -1) {

				RemovePlayerItem(client, wi);
				RemoveEdict(wi);
			}
			SDKCall(g_hSetClass, client, zombieclass);
			AcceptEntityInput(MakeCompatEntRef(GetEntProp(client, Prop_Send, "m_customAbility")), "Kill");
			if (IsPlayerAlive(client)) SetEntProp(client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_hCreateAbility, client), g_oAbility));
			if (!IsGhost(client))
			{
				SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);		// client can be killed again.
				SpeedMultiplier[client] = 1.0;		// defaulting the speed. It'll get modified in speed modifer spawn talents.
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplier[client]);

				FindAbilityByTrigger(client, _, 'a', FindZombieClass(client), 0);
			}
		}
	}
}

public Action:CMD_TeamChatCommand(client, args) {

	if (QuickCommandAccess(client, args, true)) {

		// Set colors for chat
		if (ChatTrigger(client, args, true)) return Plugin_Continue;
		else return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:CMD_ChatCommand(client, args) {

	if (QuickCommandAccess(client, args, false)) {

		// Set Colors for chat
		if (ChatTrigger(client, args, false)) return Plugin_Continue;
		else return Plugin_Handled;
	}
	return Plugin_Handled;
}

public bool:ChatTrigger(client, args, bool:teamOnly) {

	decl String:sBuffer[MAX_CHAT_LENGTH];
	decl String:Message[MAX_CHAT_LENGTH];
	decl String:Name[64];

	decl String:authString[64];
	GetClientAuthString(client, authString, sizeof(authString));

	GetClientName(client, Name, sizeof(Name));
	GetCmdArg(1, sBuffer, sizeof(sBuffer));
	StripQuotes(sBuffer);
	if (StrEqual(sBuffer, LastSpoken[client], false)) return false;
	Format(LastSpoken[client], sizeof(LastSpoken[]), "%s", sBuffer);
	//if (GetClientTeam(client) == TEAM_SPECTATOR) return true;

	decl String:TagColour[64];
	decl String:TagName[64];
	decl String:ChatColour[64];

	if (!IsReserve(client) && StringToInt(GetConfigValue("all players chat settings?")) == 0) {

		if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Message, sizeof(Message), "{N}({B}%d{N}) {B}%s", PlayerLevel[client], Name);
		else if (GetClientTeam(client) == TEAM_INFECTED) Format(Message, sizeof(Message), "{N}({R}%d{N}) {R}%s", PlayerLevel[client], Name);
		else if (GetClientTeam(client) == TEAM_SPECTATOR) Format(Message, sizeof(Message), "{N}({GRA}%d{N}) {GRA}%s", PlayerLevel[client], Name);
		Format(sBuffer, sizeof(sBuffer), ">> %s", sBuffer);
	}
	else {

		GetArrayString(Handle:ChatSettings[client], 0, TagColour, sizeof(TagColour));
		GetArrayString(Handle:ChatSettings[client], 1, TagName, sizeof(TagName));
		GetArrayString(Handle:ChatSettings[client], 2, ChatColour, sizeof(ChatColour));

		if (StrEqual(TagColour, "none", false)) {

			Format(TagColour, sizeof(TagColour), "N");
			SetArrayString(Handle:ChatSettings[client], 0, TagColour);
		}
		Format(Message, sizeof(Message), "{N}[{%s}%s{N}]", TagColour, TagName);
		if (StrEqual(ChatColour, "none", false)) {

			Format(ChatColour, sizeof(ChatColour), "N");
			SetArrayString(Handle:ChatSettings[client], 2, ChatColour);
		}
		if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Message, sizeof(Message), "%s {N}({B}%d{N}) {B}%s", Message, PlayerLevel[client], Name);
		else if (GetClientTeam(client) == TEAM_INFECTED) Format(Message, sizeof(Message), "%s {N}({R}%d{N}) {R}%s", Message, PlayerLevel[client], Name);
		else if (GetClientTeam(client) == TEAM_SPECTATOR) Format(Message, sizeof(Message), "%s {N}({GRA}%d{N}) {GRA}%s", Message, PlayerLevel[client], Name);
		Format(sBuffer, sizeof(sBuffer), "{N}>> {%s}%s", ChatColour, sBuffer);
	}

	if (GetClientTeam(client) == TEAM_SPECTATOR) Format(Message, sizeof(Message), "{GRA}*spec* %s", Message);
	else {

		if (IsGhost(client)) Format(Message, sizeof(Message), "{B}*ghost* %s", Message);
		else if (!IsPlayerAlive(client)) {

			if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Message, sizeof(Message), "{B}*dead* %s", Message);
			else Format(Message, sizeof(Message), "{R}*dead* %s", Message);
		}
		else if (IsIncapacitated(client)) Format(Message, sizeof(Message), "{B}*incap* %s", Message);
	}
	if (teamOnly) {

		if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Message, sizeof(Message), "{B}*team* %s", Message);
		else if (GetClientTeam(client) == TEAM_INFECTED) Format(Message, sizeof(Message), "{R}*team* %s", Message);
		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i) && GetClientTeam(i) == GetClientTeam(client)) {

				if (GetClientTeam(client) == TEAM_SPECTATOR && !StrEqual(Spectator_LastChatUser, authString, false) ||
					GetClientTeam(client) == TEAM_SURVIVOR && !StrEqual(Survivor_LastChatUser, authString, false) ||
					GetClientTeam(client) == TEAM_INFECTED && !StrEqual(Infected_LastChatUser, authString, false)) {

					Client_PrintToChat(i, true, Message);
				}
				Client_PrintToChat(i, true, sBuffer);
			}
		}
		if (GetClientTeam(client) == TEAM_SPECTATOR) Format(Spectator_LastChatUser, sizeof(Spectator_LastChatUser), "%s", authString);
		else if (GetClientTeam(client) == TEAM_SURVIVOR) Format(Survivor_LastChatUser, sizeof(Survivor_LastChatUser), "%s", authString);
		else if (GetClientTeam(client) == TEAM_INFECTED) Format(Infected_LastChatUser, sizeof(Infected_LastChatUser), "%s", authString);
	}
	else {

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i)) {

				//if (!StrEqual(Public_LastChatUser, authString, false)) {

					//Client_PrintToChat(i, true, Message);
				//}
				Client_PrintToChat(i, true, Message);
				Client_PrintToChat(i, true, sBuffer);
			}
		}
		Format(Public_LastChatUser, sizeof(Public_LastChatUser), "%s", authString);
	}
	return false;
}

stock GetTargetClient(client, String:TargetName[]) {

	decl String:Name[64];
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClient(i) && i != client && GetClientTeam(i) == GetClientTeam(client)) {

			GetClientName(i, Name, sizeof(Name));
			if (StrEqual(TargetName, Name, false)) {

				// The name the player entered has been found, is a member of their team.
				return i;
			}
		}
	}
	return -1;
}

stock bool:QuickCommandAccess(client, args, bool:b_IsTeamOnly) {

	decl String:Command[64];
	GetCmdArg(1, Command, sizeof(Command));
	StripQuotes(Command);
	if (Command[0] != '/' && Command[0] != '!') return true;

	decl String:TargetName[64];
	GetCmdArg(2, TargetName, sizeof(TargetName));
	StripQuotes(TargetName);
	new TargetClient	 = GetTargetClient(client, TargetName);

	decl String:text[512];
	decl String:key[64];
	decl String:value[512];
	decl String:cost[64];
	decl String:bind[64];
	decl String:pointtext[64];
	decl String:description[512];
	decl String:team[64];
	decl String:CheatCommand[64];
	decl String:CheatParameter[64];
	decl String:Model[64];
	decl String:Count[64];
	decl String:CountHandicap[64];
	decl String:Drop[64];
	decl String:PointCostMinimum[64];
	new Float:PointCost		= 0.0;
	new Float:PointCostM	= 0.0;
	decl String:MenuName[64];

	new size					=	0;
	new size2					=	0;
	decl String:Description_Old[512];

	if (StrEqual(Command[1], GetConfigValue("quick bind help?"), false)) {

		size						=	GetArraySize(a_Points);

		for (new i = 0; i < size; i++) {

			MenuKeys[client]		=	GetArrayCell(a_Points, i, 0);
			MenuValues[client]		=	GetArrayCell(a_Points, i, 1);

			//size2					=	GetArraySize(MenuKeys[client]);

			PointCost				= StringToFloat(GetKeyValue(MenuKeys[client], MenuValues[client], "point cost?"));
			if (PointCost < 0.0) continue;

			PointCostM				= StringToFloat(GetKeyValue(MenuKeys[client], MenuValues[client], "point cost minimum?"));
			Format(bind, sizeof(bind), "!%s", GetKeyValue(MenuKeys[client], MenuValues[client], "quick bind?"));
			Format(description, sizeof(description), "%T", GetKeyValue(MenuKeys[client], MenuValues[client], "description?"), client);
			Format(team, sizeof(team), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "team?"));

			/*
					
					Determine the actual cost for the player.
			*/
			
			if (Points[client] == 0.0 || Points[client] > 0.0 && (Points[client] * PointCost) < PointCostM) PointCost = PointCostM;
			else {

				PointCost += (PointCost * StringToFloat(GetConfigValue("points cost increase per level?")));
				if (PointCost > 1.0) PointCost = 1.0;
				PointCost *= Points[client];
			}
			Format(cost, sizeof(cost), "%3.3f", PointCost);
			

			if (StringToInt(team) != GetClientTeam(client)) continue;
			Format(pointtext, sizeof(pointtext), "%T", "Points", client);
			Format(pointtext, sizeof(pointtext), "%s %s", cost, pointtext);

			Format(text, sizeof(text), "%T", "Command Information", client, orange, bind, white, green, pointtext, white, blue, description);
			if (StrEqual(Description_Old, bind, false)) continue;		// in case there are duplicates
			Format(Description_Old, sizeof(Description_Old), "%s", bind);
			PrintToConsole(client, text);
		}
		PrintToChat(client, "%T", "Commands Listed Console", client, orange, white, green);
	}
	else {

		size						=	GetArraySize(a_Points);

		for (new i = 0; i < size; i++) {

			MenuKeys[client]		=	GetArrayCell(a_Points, i, 0);
			MenuValues[client]		=	GetArrayCell(a_Points, i, 1);

			PointCost		= StringToFloat(GetKeyValue(MenuKeys[client], MenuValues[client], "point cost?"));
			PointCostM		= StringToFloat(GetKeyValue(MenuKeys[client], MenuValues[client], "point cost minimum?"));
			Format(bind, sizeof(bind), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "quick bind?"));
			Format(team, sizeof(team), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "team?"));
			Format(CheatCommand, sizeof(CheatCommand), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "command?"));
			Format(CheatParameter, sizeof(CheatParameter), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "parameter?"));
			Format(Model, sizeof(Model), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "model?"));
			Format(Count, sizeof(Count), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "count?"));
			Format(CountHandicap, sizeof(CountHandicap), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "count handicap?"));
			Format(Drop, sizeof(Drop), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "drop?"));
			Format(MenuName, sizeof(MenuName), "%s", GetKeyValue(MenuKeys[client], MenuValues[client], "part of menu named?"));

			if (StrEqual(Command[1], bind, false) && StringToInt(team) == GetClientTeam(client)) {		// we found the bind the player used, and the player is on the appropriate team.

				if (StrEqual(Command[1], "respawn", false) && (IsPlayerAlive(client) && TargetClient == -1 || IsPlayerAlive(TargetClient))) return false;


				PointCost			=	0.0;
				new ExperienceCost			=	0;

				new PointPurchaseType		=	StringToInt(GetConfigValue("points purchase type?"));
				new TargetClient_s			=	0;

				if (PointPurchaseType == 0) PointCost = StringToFloat(cost);
				else if (PointPurchaseType == 1) ExperienceCost = StringToInt(cost);


				if (FindCharInString(CheatCommand, ':') != -1) {

					BuildPointsMenu(client, CheatCommand[1], CONFIG_POINTS);		// Always CONFIG_POINTS for quick commands
				}
				else {

					if (GetClientTeam(client) == TEAM_INFECTED) {

						if (StringToInt(CheatParameter) == 8 && ActiveTanks() >= StringToInt(GetConfigValue("versus tank limit?"))) {

							PrintToChat(client, "%T", "Tank Limit Reached", client, orange, green, StringToInt(GetConfigValue("versus tank limit?")), white);
							return false;
						}
						else if (StringToInt(CheatParameter) == 8 && f_TankCooldown != -1.0) {

							PrintToChat(client, "%T", "Tank On Cooldown", client, orange, white);
							return false;
						}
					}

					if (Points[client] == 0.0 || Points[client] > 0.0 && (Points[client] * PointCost) < StringToFloat(PointCostMinimum)) PointCost = StringToFloat(PointCostMinimum);
					else PointCost *= Points[client];

					if ((PointPurchaseType == 0 && (Points[client] >= PointCost || PointCost == 0.0 ||
						(IsGhost(client) && TargetClient == -1 ||
						IsGhost(TargetClient)) && StrEqual(CheatCommand, "change class") && StringToInt(CheatParameter) != 8)) ||
						(PointPurchaseType == 1 && (ExperienceLevel[client] >= ExperienceCost ||
							ExperienceCost == 0 || (IsGhost(client) && TargetClient == -1 || IsGhost(TargetClient)) && StrEqual(CheatCommand, "change class") && StringToInt(CheatParameter) != 8))) {

						if (!StrEqual(CheatCommand, "change class") ||
							StrEqual(CheatCommand, "change class") && StrEqual(CheatParameter, "8") ||
							StrEqual(CheatCommand, "change class") && (IsPlayerAlive(client) && !IsGhost(client) && TargetClient == -1 || IsPlayerAlive(TargetClient) && !IsGhost(TargetClient))) {

							if (PointPurchaseType == 0 && (Points[client] >= PointCost || PointCost == 0.0)) Points[client] -= PointCost;
							else if (PointPurchaseType == 1 && (ExperienceLevel[client] >= ExperienceCost || ExperienceCost == 0)) ExperienceLevel[client] -= ExperienceCost;
						}

						if (StrEqual(CheatParameter, "common") && StrContains(Model, ".mdl", false) != -1) {

							Format(Count, sizeof(Count), "%d", StringToInt(Count) + (StringToInt(CountHandicap) * LivingSurvivorCount()));

							for (new iii = StringToInt(Count); iii > 0 && GetArraySize(CommonInfectedQueue) < StringToInt(GetConfigValue("common queue limit?")); iii--) {

								if (StringToInt(Drop) == 1) {

									ResizeArray(Handle:CommonInfectedQueue, GetArraySize(Handle:CommonInfectedQueue) + 1);
									ShiftArrayUp(Handle:CommonInfectedQueue, 0);
									SetArrayString(Handle:CommonInfectedQueue, 0, Model);
									TargetClient_s		=	FindLivingSurvivor();
									if (TargetClient_s > 0) ExecCheatCommand(TargetClient_s, CheatCommand, CheatParameter);
								}
								else PushArrayString(Handle:CommonInfectedQueue, Model);
							}
						}
						else if (StrEqual(CheatCommand, "change class")) {

							// We don't give them points back if ghost because we don't take points if ghost.
							//if (IsGhost(client) && PointPurchaseType == 0) Points[client] += PointCost;
							//else if (IsGhost(client) && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
							if ((!IsGhost(client) && FindZombieClass(client) == ZOMBIECLASS_TANK && TargetClient == -1 ||
								!IsGhost(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_TANK) && PointPurchaseType == 0) Points[client] += PointCost;
							else if ((!IsGhost(client) && FindZombieClass(client) == ZOMBIECLASS_TANK && TargetClient == -1 || !IsGhost(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_TANK) && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
							else if ((!IsGhost(client) && IsPlayerAlive(client) && FindZombieClass(client) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(client) != -1 && TargetClient == -1 ||
									  !IsGhost(TargetClient) && IsPlayerAlive(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(TargetClient) == -1) && PointPurchaseType == 0) Points[client] += PointCost;
							else if ((!IsGhost(client) && IsPlayerAlive(client) && FindZombieClass(client) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(client) != -1 && TargetClient == -1 ||
									  !IsGhost(TargetClient) && IsPlayerAlive(TargetClient) && FindZombieClass(TargetClient) == ZOMBIECLASS_CHARGER && L4D2_GetSurvivorVictim(TargetClient) == -1) && PointPurchaseType == 1) ExperienceLevel[client] += ExperienceCost;
							if (FindZombieClass(client) != ZOMBIECLASS_TANK && TargetClient == -1 || FindZombieClass(TargetClient) != ZOMBIECLASS_TANK) {

								if (TargetClient == -1) ChangeInfectedClass(client, StringToInt(CheatParameter));
								else ChangeInfectedClass(TargetClient, StringToInt(CheatParameter));
							}
						}
						else if (StrEqual(CheatCommand, "respawn")) {

							if (TargetClient == -1) {

								h_PreviousDeath[client] = -1;

								SDKCall(hRoundRespawn, client);
								CreateTimer(0.2, Timer_TeleportRespawn, client, TIMER_FLAG_NO_MAPCHANGE);
							}
							else {

								h_PreviousDeath[TargetClient] = client;		// we want to teleport the targeted player to the person who respawned them.

								SDKCall(hRoundRespawn, TargetClient);
								CreateTimer(0.2, Timer_TeleportRespawn, TargetClient, TIMER_FLAG_NO_MAPCHANGE);
							}
						}
						else {

							//CheckIfRemoveWeapon(client, CheatParameter);

							/*if (PointCost == 0.0 && GetClientTeam(client) == TEAM_SURVIVOR) {

								// there is no code here to give a player a FREE weapon forcefully because that would be fucked up. TargetClient just gets ignored here.
								if (StrContains(CheatParameter, "pistol", false) != -1) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
								else L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Primary);
							}*/
							if (IsMeleeWeaponParameter(CheatParameter)) {

								// Get rid of their old weapon
								//if (TargetClient == -1)	L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
								//else L4D_RemoveWeaponSlot(TargetClient, L4DWeaponSlot_Secondary);

								new ent			= CreateEntityByName("weapon_melee");

								DispatchKeyValue(ent, "melee_script_name", CheatParameter);
								DispatchSpawn(ent);

								if (TargetClient == -1) EquipPlayerWeapon(client, ent);
								else EquipPlayerWeapon(TargetClient, ent);
							}
							else {

								//if (StrContains(CheatParameter, "pistol", false) != -1) L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Secondary);
								//else L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Primary);

								if (TargetClient == -1) {

									ExecCheatCommand(client, CheatCommand, CheatParameter);
									if (StrEqual(CheatParameter, "health")) GiveMaximumHealth(client);		// So instant heal doesn't put a player above their maximum health pool.
								}
								else {

									ExecCheatCommand(TargetClient, CheatCommand, CheatParameter);
									if (StrEqual(CheatParameter, "health")) GiveMaximumHealth(TargetClient);
								}
							}
						}
					}
					else {

						if (PointPurchaseType == 0) PrintToChat(client, "%T", "Not Enough Points", client, orange, white, PointCost);
						else if (PointPurchaseType == 1) PrintToChat(client, "%T", "Not Enough Experience", client, orange, white, ExperienceCost);
					}
				}
				break;
			}
		}
	}
	if (Command[0] == '!') return true;
	return false;
}

stock LoadHealthMaximum(client) {

	if (GetClientTeam(client) == TEAM_INFECTED) DefaultHealth[client] = GetClientHealth(client);
	else DefaultHealth[client] = 100;	// 100 is the default. no reason to think otherwise.
	FindAbilityByTrigger(client, _, 'a', FindZombieClass(client), 0);
}

stock SetSpeedMultiplierBase(attacker, Float:amount = 1.0) {

	if (!IsFakeClient(attacker)) SpeedMultiplierBase[attacker] = amount + (Agility[attacker] * 0.01);
	else SpeedMultiplierBase[attacker] = amount + (Agility_Bots * 0.01);
	SpeedMultiplier[attacker] = SpeedMultiplierBase[attacker];
	//LogMessage("Base movement speed for %N: %3.3f", attacker, SpeedMultiplierBase[attacker]);
	SetEntPropFloat(attacker, Prop_Send, "m_flLaggedMovementValue", SpeedMultiplierBase[attacker]);
}

stock PlayerSpawnAbilityTrigger(attacker) {

	if (IsLegitimateClientAlive(attacker)) {

		SetSpeedMultiplierBase(attacker);

		SpeedMultiplier[attacker] = SpeedMultiplierBase[attacker];		// defaulting the speed. It'll get modified in speed modifer spawn talents.
		
		if (GetClientTeam(attacker) == TEAM_INFECTED) DefaultHealth[attacker] = GetClientHealth(attacker);
		else DefaultHealth[attacker] = 100;
		b_IsImmune[attacker] = false;

		FindAbilityByTrigger(attacker, _, 'a', FindZombieClass(attacker), 0);
		GiveMaximumHealth(attacker);
	}
}

stock bool:NoHumanInfected() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_INFECTED) return false;
	}

	return true;
}

stock InfectedBotSpawn(client) {

	if (IsClientInGame(client) && IsFakeClient(client)) {

		new Float:HealthBonus = 0.0;
		new Float:SpeedBonus = 0.0;

		if (FindZombieClass(client) == ZOMBIECLASS_HUNTER) {

			HealthBonus		= StringToFloat(GetConfigValue("bot hunter health bonus?")) * LivingSurvivors();
			SpeedBonus		= StringToFloat(GetConfigValue("bot hunter speed bonus?")) * LivingSurvivors();
		}
		else if (FindZombieClass(client) == ZOMBIECLASS_SMOKER) {

			HealthBonus		= StringToFloat(GetConfigValue("bot smoker health bonus?")) * LivingSurvivors();
			SpeedBonus		= StringToFloat(GetConfigValue("bot smoker speed bonus?")) * LivingSurvivors();
		}
		else if (FindZombieClass(client) == ZOMBIECLASS_BOOMER) {

			HealthBonus		= StringToFloat(GetConfigValue("bot boomer health bonus?")) * LivingSurvivors();
			SpeedBonus		= StringToFloat(GetConfigValue("bot boomer speed bonus?")) * LivingSurvivors();
		}
		else if (FindZombieClass(client) == ZOMBIECLASS_JOCKEY) {

			HealthBonus		= StringToFloat(GetConfigValue("bot jockey health bonus?")) * LivingSurvivors();
			SpeedBonus		= StringToFloat(GetConfigValue("bot jockey speed bonus?")) * LivingSurvivors();
		}
		else if (FindZombieClass(client) == ZOMBIECLASS_SPITTER) {

			HealthBonus		= StringToFloat(GetConfigValue("bot spitter health bonus?")) * LivingSurvivors();
			SpeedBonus		= StringToFloat(GetConfigValue("bot spitter speed bonus?")) * LivingSurvivors();
		}
		else if (FindZombieClass(client) == ZOMBIECLASS_CHARGER) {

			HealthBonus		= StringToFloat(GetConfigValue("bot charger health bonus?")) * LivingSurvivors();
			SpeedBonus		= StringToFloat(GetConfigValue("bot charger speed bonus?")) * LivingSurvivors();
		}
		else if (FindZombieClass(client) == ZOMBIECLASS_TANK) {

			HealthBonus		= StringToFloat(GetConfigValue("bot tank health bonus?")) * LivingSurvivors();
			SpeedBonus		= StringToFloat(GetConfigValue("bot tank speed bonus?")) * LivingSurvivors();
		}

		DefaultHealth[client] = RoundToCeil(OriginalHealth[client] + (OriginalHealth[client] * HealthBonus));
		SpeedMultiplierBase[client] = 1.0;
		SpeedMultiplier[client] = 1.0;

		SetMaximumHealth(client, false, DefaultHealth[client] * 1.0);
		//LogMessage("Movement speed bonus for %N is %3.3f (Health is %d)", client, SpeedBonus, DefaultHealth[client]);
		//SpeedIncrease(client, 0.0, SpeedBonus);
		SetSpeedMultiplierBase(client, 1.0 + SpeedBonus);
		GiveMaximumHealth(client);

		b_IsImmune[client] = false;
		//FindAbilityByTrigger(client, _, 'a', 0, 0);
	}
}

stock bool:IsLegitimateClient(client) {

	if (client < 1 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) return false;
	return true;
}

stock bool:IsLegitimateClientAlive(client) {

	if (IsLegitimateClient(client) && IsPlayerAlive(client)) return true;
	return false;
}

stock RefreshSurvivor(client) {

	SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
	StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
	SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
}

stock CheckMaxAllowedHandicap(client) {

	if (HandicapLevel[client] != -1 && HandicapLevel[client] > (StringToInt(GetConfigValue("handicap breadth?")) - MapRoundsPlayed)) {

		if (HandicapLevel[client] == 1 || StringToInt(GetConfigValue("handicap breadth?")) - MapRoundsPlayed <= 0) {

			HandicapLevel[client] = -1;
			PrintToChat(client, "%T", "handicap level disabled by force", client, white, green, white, orange);
		}
		else if (StringToInt(GetConfigValue("handicap breadth?")) - MapRoundsPlayed >= 1) {

			HandicapLevel[client] = (StringToInt(GetConfigValue("handicap breadth?")) - MapRoundsPlayed);
			PrintToChat(client, "%T", "handicap level reduced by force", client, white, green, white, orange, HandicapLevel[client]);
		}
	}
}

stock IncapacitateOrKill(client, attacker = 0) {

	if (IsLegitimateClient(client) && !IsFakeClient(client) && IsPlayerAlive(client)) {

		new IncapCounter	= GetEntProp(client, Prop_Send, "m_currentReviveCount");

		if (IncapCounter >= GetConVarInt(FindConVar("survivor_max_incapacitated_count"))) {

			b_HasDeathLocation[client] = true;
			GetClientAbsOrigin(client, Float:DeathLocation[client]);
			ForcePlayerSuicide(client);
			FindAbilityByTrigger(client, attacker, 'A', FindZombieClass(client), 0);
			HandicapReductionCheck(client);
		}
		else {

			SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
			SetEntityHealth(client, 300);
			RoundIncaps[client]++;
			//SetEntProp(client, Prop_Send, "m_currentReviveCount", IncapCounter + 1);
		}
	}
}

stock HandicapReductionCheck(client) {

	if (GetClientTeam(client) == TEAM_SURVIVOR) {

		RoundDeaths[client]++;

		if (HandicapLevel[client] > 1 && (StringToInt(GetConfigValue("handicap breadth?")) - RoundDeaths[client]) < HandicapLevel[client]) {

			HandicapLevel[client]--;
			PrintToChat(client, "%T", "handicap level reduced by force", client, white, green, white, orange, HandicapLevel[client]);
		}
		else if (HandicapLevel[client] != -1 && (StringToInt(GetConfigValue("handicap breadth?")) - RoundDeaths[client]) < 1) {

			HandicapLevel[client] = -1;
			PrintToChat(client, "%T", "handicap level disabled by force", client, white, green, white, orange);
		}
	}
}

stock bool:IsAllSurvivorsDead() {

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && GetClientTeam(i) == TEAM_SURVIVOR) return false;
	}
	return true;
}

stock GetClientTotalHealth(client) {

	new SolidHealth			= GetClientHealth(client);
	new Float:TempHealth	= GetEntPropFloat(client, Prop_Send, "m_healthBuffer");

	return RoundToCeil(SolidHealth + TempHealth);
}

stock SetClientTotalHealth(client, damage) {

	new SolidHealth			= GetClientHealth(client);
	new Float:TempHealth	= GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	if (damage < RoundToFloor(TempHealth)) SetEntPropFloat(client, Prop_Send, "m_healthBuffer", TempHealth - damage);
	else if (damage > RoundToFloor(TempHealth)) {

		damage = damage - RoundToFloor(TempHealth);
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
		SetEntityHealth(client, SolidHealth - damage);
	}
}

stock RestoreClientTotalHealth(client, damage) {

	new SolidHealth			= GetClientHealth(client);
	new Float:TempHealth	= 0.0;
	if (GetClientTeam(client) == TEAM_SURVIVOR) GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	if (RoundToFloor(TempHealth) > 0) SetEntPropFloat(client, Prop_Send, "m_healthBuffer", TempHealth + damage);
	else SetEntityHealth(client, SolidHealth + damage);
}

stock SetClientTempHealth(client, health) {

	new Float:TempHealth	= GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", TempHealth + health);
}

stock SetClientMaximumTempHealth(client) {

	SetMaximumHealth(client);
	SetEntityHealth(client, 1);
	SetClientTempHealth(client, GetMaximumHealth(client) - 1);
}

stock HealPlayer(client, activator, Float:s_Strength, ability) {

	if (IsLegitimateClientAlive(client)) {

		new Float:HealAmount		= GetMaximumHealth(client) * s_Strength;
		if (GetClientTeam(client) == TEAM_SURVIVOR && !IsIncapacitated(client) || GetClientTeam(client) == TEAM_INFECTED) {

			if (!b_HardcoreMode[client] || GetClientTeam(client) != TEAM_SURVIVOR) {

				if (GetClientHealth(client) + RoundToFloor(HealAmount) > GetMaximumHealth(client)) GiveMaximumHealth(client);
				else SetEntityHealth(client, GetClientHealth(client) + RoundToFloor(HealAmount));
			}
			/*else {

				if (GetClientTotalHealth(client) > GetMaximumHealth(client)) SetClientMaximumTempHealth(client);
				else {

					SetEntityHealth(client, 1);
					SetClientTempHealth(client, RoundToFloor(HealAmount));
				}
			}*/
		}
		if (ability == 'T') ReadyUp_NtvFriendlyFire(activator, client, 0 - RoundToCeil(HealAmount), GetClientHealth(client), 1, 0);	// we "subtract" negative values from health.
	}
}

stock EnableHardcoreMode(client) {

	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 0, 0, 255);
	SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
	EmitSoundToClient(client, "player/heartbeatloop.wav");
	//SetClientMaximumTempHealth(client);
}

stock FindEligibleParticipants(client) {

	// How many players dealt the minimum percentage of damage required to receive the teamwork bonus?
	new Float:damagePercentageRequired		= StringToFloat(GetConfigValue("teamwork percent damage required?"));
	new clientMaximumHealth					= GetMaximumHealth(client);

	new eligibleParticipants				= 0;
	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && DamageAward[i][client] > 0 && DamageAward[i][client] / clientMaximumHealth >= damagePercentageRequired) {

			eligibleParticipants++;
		}
	}
	if (eligibleParticipants < StringToInt(GetConfigValue("teamwork eligible participants required?"))) return 0;
	return eligibleParticipants;
}

stock AwardEligibleParticipants(client) {

	new Float:damagePercentageRequired		= StringToFloat(GetConfigValue("teamwork percent damage required?"));
	new RPGBroadcast						= StringToInt(GetConfigValue("award broadcast?"));
	new clientMaximumHealth					= GetMaximumHealth(client);
	new playerExperienceBonus				= 0;
	new Float:playerPointsBonus				= 0.0;
	new clientMaximumAwardBonus				= RoundToFloor(GetMaximumHealth(client) * StringToFloat(GetConfigValue("teamwork percent damage maximum?")));
	new playerInflictedDamage				= 0;
	new Float:participantsExperienceBonus	= FindEligibleParticipants(client) * StringToFloat(GetConfigValue("teamwork participants experience bonus?"));
	new Float:participantsPointsBonus		= FindEligibleParticipants(client) * StringToFloat(GetConfigValue("teamwork participants points bonus?"));

	new Float:teamworkExperienceBonus		= StringToFloat(GetConfigValue("teamwork percentage experience bonus?")) + participantsExperienceBonus;
	new Float:teamworkPointsBonus			= StringToFloat(GetConfigValue("teamwork percentage points bonus?")) + participantsPointsBonus;
	decl String:InfectedName[64];
	GetClientName(client, InfectedName, sizeof(InfectedName));

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && DamageAward[i][client] > 0 && DamageAward[i][client] / clientMaximumHealth >= damagePercentageRequired) {

			if (DamageAward[i][client] > clientMaximumAwardBonus) playerInflictedDamage = clientMaximumAwardBonus;
			else playerInflictedDamage		= DamageAward[i][client];

			playerExperienceBonus			= RoundToFloor(playerInflictedDamage * teamworkExperienceBonus);
			if (playerExperienceBonus < 1) continue;

			if (playerExperienceBonus > clientMaximumAwardBonus) playerExperienceBonus = clientMaximumAwardBonus;
			if (RPGBroadcast == 1 && !IsFakeClient(client)) PrintToChat(i, "%T", "Experience Earned Teamwork Bonus Self", i, white, orange, white, green, white, InfectedName, playerExperienceBonus);
			ExperienceLevel[i]				+= playerExperienceBonus;
			ExperienceOverall[i]			+= playerExperienceBonus;
			if (ExperienceLevel[i] > CheckExperienceRequirement(i)) {

				ExperienceOverall[i] -= (ExperienceLevel[i] - CheckExperienceRequirement(i));
				ExperienceLevel[i] = CheckExperienceRequirement(i);
			}

			if (StringToFloat(GetConfigValue("teamwork percentage points bonus?")) <= 0.0) continue;

			playerPointsBonus			= playerInflictedDamage * teamworkPointsBonus;
			if (playerPointsBonus <= 0.0) continue;

			Points[i]				+= playerPointsBonus;
			if (RPGBroadcast == 1 && !IsFakeClient(client)) PrintToChat(i, "%T", "Points Earned Teamwork Bonus Self", i, white, orange, white, green, white, InfectedName, playerPointsBonus);
		}
	}
}

stock Float:TeamworkProximityMultiplier(client, bool:b_IsExperience) {

	new Float:proximityDistanceBonus		= 0.0;
	new Float:proximityDistancePenalty		= 0.0;
	new Float:proximityMultiplierMinimum	= 0.0;
	new Float:playerFlowDistance			= (L4D2Direct_GetFlowDistance(client) / g_MapFlowDistance);
	new Float:teammateFlowDistance			= 0.0;
	new Float:noMultiplierValue				= 0.0;

	if (b_IsExperience) {

		proximityDistanceBonus				= StringToFloat(GetConfigValue("teamwork proxy multiplier exp bonus?"));
		proximityDistancePenalty			= StringToFloat(GetConfigValue("teamwork proxy multiplier exp penalty?"));
		noMultiplierValue					= StringToFloat(GetConfigValue("experience multiplier survivor?"));
		proximityMultiplierMinimum			= StringToFloat(GetConfigValue("teamwork proxy minimum multiplier exp?"));
	}
	else {

		proximityDistanceBonus				= StringToFloat(GetConfigValue("teamwork proxy multiplier points bonus?"));
		proximityDistancePenalty			= StringToFloat(GetConfigValue("teamwork proxy multiplier points penalty?"));
		noMultiplierValue					= StringToFloat(GetConfigValue("points multiplier survivor?"));
		proximityMultiplierMinimum			= StringToFloat(GetConfigValue("teamwork proxy minimum multiplier points?"));
	}
	new Float:playerProximityMultiplier		= 0.0;
	new Float:playerProximityRadius			= StringToFloat(GetConfigValue("teamwork proxy radius?"));
	new playerPenalizeBehind				= StringToInt(GetConfigValue("teamwork proxy penalize behind?"));

	new Float:playerOrigin[3];
	new Float:teammateOrigin[3];

	GetClientAbsOrigin(client, playerOrigin);

	for (new i = 1; i <= MaxClients; i++) {

		if (IsLegitimateClientAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && i != client) {

			teammateFlowDistance			= (L4D2Direct_GetFlowDistance(i) / g_MapFlowDistance);
			if (playerPenalizeBehind == 1 || playerFlowDistance >= teammateFlowDistance) {

				GetClientAbsOrigin(i, teammateOrigin);
				if (GetVectorDistance(playerOrigin, teammateOrigin) <= playerProximityRadius) playerProximityMultiplier += proximityDistanceBonus;
				else playerProximityMultiplier -= proximityDistancePenalty;
			}
		}
	}

	// We want to add the base award to the multiplied value, since all calculations are done here, now.
	playerProximityMultiplier += noMultiplierValue;
	
	/*
	Obviously, the value isn't allowed to be less than 0.0, because that would actually take points / experience from the player.
	While I'm all for penalizing players, I think that's a little bit extreme, so we override the minimum setting from the config if its value is below 0.0;
	*/
	if (proximityMultiplierMinimum < 0.0) proximityMultiplierMinimum = 0.0;

	/*
	Now, we check to see if the total is below proximityMultiplierMinimum.
	If it is, the total is equal to whatever its value is.
	*/
	if (playerProximityMultiplier < proximityMultiplierMinimum) return proximityMultiplierMinimum;
	return playerProximityMultiplier;
}

stock LegacyItemRoll(victim, attacker, bool:b_IsCommon) {

	//DamageAward[i][client]
	if (HumanPlayersInGame() < StringToInt(GetConfigValue("required humans for item drops?"))) return;
	new clientid	= attacker;		// we set the default client to the attacker, since if it's a common killed, we don't determine a specific client from damage.
	new bestroll	= 0;
	new currroll	= 0;
	decl String:rollvalue[64];
	Format(rollvalue, sizeof(rollvalue), "n/a");		// default for common kills.
	decl String:Name[64];
	GetClientName(attacker, Name, sizeof(Name));
	decl String:itemname[64];
	decl String:translationname[64];

	if (!b_IsCommon) {

		// If a common infected is not the kill target (re: if it's special infected) we want to roll all eligible participants.
		// All this does is determine who gets a CHANCE to win an item. It doesn't guarantee that the item drop roll that follows will be successful.

		new Float:minimumDamage		= StringToFloat(GetConfigValue("required damage percent for legacy roll?"));
		if (minimumDamage > 0.0) minimumDamage *= GetMaximumHealth(victim);

		for (new i = 1; i <= MaxClients; i++) {

			if (IsLegitimateClient(i) && !IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR && DamageAward[i][victim] > 0) {

				if (minimumDamage == 0.0 || DamageAward[i][victim] >= RoundToFloor(minimumDamage)) {

					currroll	= GetRandomInt(1, 100);
					if (currroll > bestroll) {

						clientid	= i;
						bestroll	= currroll;
						Format(rollvalue, sizeof(rollvalue), "%d", bestroll);
						GetClientName(clientid, Name, sizeof(Name));
					}
				}
			}
		}
	}

	// now we roll the potential item awards for the player.
	if (IsSlateChance(victim)) {

		SlatePoints[clientid]++;
		PrintToChatAll("%t", "SLATE award legacy", blue, Name, white, orange, white, orange, rollvalue, white);
	}
	else {

		new pos = -1;
		pos			= IsStoreChance(victim, clientid);
		if (pos >= 0) {

			Format(itemname, sizeof(itemname), "%s", StoreItemName(clientid, pos));
			IsStoreItem(clientid, itemname, true);	// true because we want to give them the item, not just verify that it exists.
			for (new i = 1; i <= MaxClients; i++) {

				if (IsClientInGame(i) && !IsFakeClient(i)) {

					Format(translationname, sizeof(translationname), "%T", itemname, i);
					PrintToChat(i, "%T", "Store Item Award legacy", i, blue, Name, white, orange, translationname, white, orange, rollvalue, white);
				}
			}
		}
		else {

			pos = -1;
			pos		= IsLockedTalentChance(victim, false);
			if (pos >= 0) {

				GetArrayString(Handle:a_Database_Talents_Defaults_Name, pos, itemname, sizeof(itemname));
				if (IsTalentLocked(clientid, itemname)) {

					UnlockTalent(clientid, itemname, false, true);		// arg3 is bIsEndOfMapRoll, which defaults to false, arg4 is bIsLegacy, which defaults to false.
					for (new i = 1; i <= MaxClients; i++) {

						if (IsClientInGame(i) && !IsFakeClient(i)) {

							Format(translationname, sizeof(translationname), "%T", itemname, i);
							PrintToChat(i, "%T", "Locked Talent Award legacy", i, blue, Name, white, orange, itemname, white, orange, rollvalue, white);
						}
					}
				}
			}
		}
	}
}