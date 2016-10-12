stock String:GetConfigValue(client=0, Handle:Keys, Handle:Values, String:searchkey[], bool:bIsDetailedSearch=false) {
	
	decl String:text[512];
	decl String:value[512];
	Format(text, sizeof(text), "-1");

	new size			= GetArraySize(Keys);

	for (new i = 0; i < size; i++) {

		GetArrayString(Handle:Keys, i, value, sizeof(value));

		if (StrEqual(value, searchkey)) {

			GetArrayString(Handle:Values, i, value, sizeof(value));
			if (client > 0 && bIsDetailedSearch) {

				Format(value, sizeof(value), "%T", value, client);
				if (StrEqual(text, "-1", false)) Format(text, sizeof(text), "%s", value);
				else Format(text, sizeof(text), "%s\n\t%s", text, value);
				continue;
			}
			Format(text, sizeof(text), "%s", value);
			return text;
		}
	}
	//if (bIsDetailedSearch) PrintToChatAll("%s", text);
	return text;
}

bool IsEntityBiled(entity)
{
     return (GetEntProp(entity, Prop_Send, "m_glowColorOverride") == -4713783);
} 

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {

	new bool:bIsChanged = false;
	if (victim > 0 && IsClientInGame(victim)) {

		decl String:AbilityEffects[10];
		new zombieclass = 0;

		/*


				If the victim is on the infected team.


		*/
		if (GetClientTeam(victim) == 3) {

			zombieclass = GetEntProp(victim, Prop_Send, "m_zombieClass");

			/*


					If the infected player is a victim of incoming damage and currently has a survivor victim.
					(pounced, riding, charged, smoked)


			*/
			if (L4D2_GetSurvivorVictim(victim) != -1) {

				Format(AbilityEffects, sizeof(AbilityEffects), "%s", GetEffectsOfTrigger(victim, zombieclass, 'r'));
				if (FindCharInString(AbilityEffects, 'i') != -1) {

					/*


							trigger: 'r'	- the victim receives damage, while they have a survivor victim.
							effect:  'i'	- the victim is invulnerable to damage.


					*/
					bIsChanged = true;
					damage = 0.0;
				}
			}
			/*


					If the damage type is fire.


			*/
			if (damagetype == 8 || damagetype == 2056 || damagetype == 268435464) {

				Format(AbilityEffects, sizeof(AbilityEffects), "%s", GetEffectsOfTrigger(victim, zombieclass, 'f'));
				if (FindCharInString(AbilityEffects, 'i') != -1) {

					/*


							trigger: 'f'	- the victim receives damage with a fire origin.
							effect:  'i'	- the victim is invulnerable to damage.
					*/
					bIsChanged = true;
					damage = 0.0;
				}
			}
		}
		/*


				If the attacker is on the infected team.


		*/
		if (GetClientTeam(attacker) == 3) {

			zombieclass = GetEntProp(attacker, Prop_Send, "m_zombieClass");

			/*


					If the infected player is the one dealing damage and currently has a survivor victim.


			*/
			if (L4D2_GetSurvivorVictim(attacker) != -1) {

				Format(AbilityEffects, sizeof(AbilityEffects), "%s", GetEffectsOfTrigger(attacker, zombieclass, 'c'));
				if (FindCharInString(AbilityEffects, 'n') != -1) {

					/*


							trigger: 'c'	- the attacker caused damage while having a survivor victim.
							effect:  'n'	- the attacker deals no damage.


					*/
					bIsChanged = true;
					damage = 0.0;
				}
			}
		}
	}
	if (bIsChanged) return Plugin_Changed;
	return Plugin_Continue;
}

stock String:GetEffectsOfTrigger(client, zombieclass, ability) {

	decl String:AbilityTrigger[10];
	decl String:AllowedClasses[10];
	decl String:AbilityEffects[10];

	new size	= GetArraySize(a_AbilityConfig);
	for (new i = 0; i < size; i++) {

		a_Keys[client]		= GetArrayCell(a_AbilityConfig, i, 1);
		a_Values[client]	= GetArrayCell(a_AbilityConfig, i, 2);

		/*


				The only way an ability triggers is if the client zombieclass is found
				within the allowed classes value. Similarly, the ability that is trying
				to fire must be an ability where the zombieclass is allowed.
		*/
		Format(AllowedClasses, sizeof(AllowedClasses), "%s", GetConfigValue(client, a_Keys[client], a_Values[client], "classes?"));
		Format(AbilityTrigger, sizeof(AbilityTrigger), "%s", GetConfigValue(client, a_Keys[client], a_Values[client], "trigger?"));
		if (FindCharInString(AllowedClasses, zombieclass) != -1 && FindCharInString(AbilityTrigger, ability) != -1) {

			Format(AbilityEffects, sizeof(AbilityEffects), "%s", GetConfigValue(client, a_Keys[client], a_Values[client], "effects?"));
			return AbilityEffects;
		}
	}
	Format(AbilityEffects, sizeof(AbilityEffects), "-1");
	return AbilityEffects;
}

stock ActivateEffects(client, zombieclass, String:effects[]) {

	if (FindCharInString(effects, 'd') != -1) SDKCall(hOnPounceEnd, client);
}