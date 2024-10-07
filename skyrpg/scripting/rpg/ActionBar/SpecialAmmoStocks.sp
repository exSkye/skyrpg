stock CreateGravityAmmo(client, float Force, Range, bool UseTheForceLuke=false) {

	int entity		= CreateEntityByName("point_push");
	if (!IsValidEntity(entity)) return -1;
	char value[64];

	float Origin[3];
	float Angles[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
	GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
	Angles[0] += -90.0;

	DispatchKeyValueVector(entity, "origin", Origin);
	DispatchKeyValueVector(entity, "angles", Angles);
	Format(value, sizeof(value), "%d", Range / 2);
	DispatchKeyValue(entity, "radius", value);
	if (!UseTheForceLuke) DispatchKeyValueFloat(entity, "magnitude", Force * -1.0);
	else DispatchKeyValueFloat(entity, "magnitude", Force);
	DispatchKeyValue(entity, "spawnflags", "8");
	AcceptEntityInput(entity, "Enable");
	return entity;
}

stock BeanBagAmmo(client, float force, TalentClient) {
	if (!IsCommonInfected(client) && !IsLegitimateClientAlive(client)) return;
	if (!IsLegitimateClientAlive(TalentClient)) return;
	float Velocity[3];
	Velocity[0]	=	GetEntPropFloat(TalentClient, Prop_Send, "m_vecVelocity[0]");
	Velocity[1]	=	GetEntPropFloat(TalentClient, Prop_Send, "m_vecVelocity[1]");
	Velocity[2]	=	GetEntPropFloat(TalentClient, Prop_Send, "m_vecVelocity[2]");
	float Vec_Pull;
	float Vec_Lunge;
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

stock ExplosiveAmmo(client, damage, TalentClient) {
	if (IsWitch(client)) AddWitchDamage(TalentClient, client, damage);
	else if (IsSpecialCommon(client)) AddSpecialCommonDamage(TalentClient, client, damage);
	else if (IsLegitimateClientAlive(client)) {
		if (myCurrentTeam[client] == TEAM_INFECTED) AddSpecialInfectedDamage(TalentClient, client, damage);
		else SetClientTotalHealth(TalentClient, client, damage);	// survivor teammates don't reward players with experience or damage bonus, but they'll take damage from it.
	}
}

stock HealingAmmo(client, healing, TalentClient, bool IsCritical=false) {
	if (!IsLegitimateClientAlive(client) || !IsLegitimateClientAlive(TalentClient)) return;
	HealPlayer(client, TalentClient, healing * 1.0, 'h', true);
}

stock LeechAmmo(client, damage, TalentClient) {
	if (IsWitch(client)) AddWitchDamage(TalentClient, client, damage);
	else if (IsSpecialCommon(client)) AddSpecialCommonDamage(TalentClient, client, damage);
	else if (IsLegitimateClientAlive(client)) {
		if (myCurrentTeam[client] == TEAM_INFECTED) AddSpecialInfectedDamage(TalentClient, client, damage);
		else SetClientTotalHealth(TalentClient, client, damage);
	}
	if (IsLegitimateClientAlive(TalentClient) && myCurrentTeam[TalentClient] == TEAM_SURVIVOR) {
		//if (IsCritical || !IsCriticalHit(client, healing, TalentClient))	// maybe add this to leech? that would be cool.!
		HealPlayer(TalentClient, TalentClient, damage * 1.0, 'h', true);
	}
}

/*

	When a client who has special ammo enabled has an eligible target highlighted, we want to draw an aura around that target (just for the client)
	This aura will cycle appropriately as a player cycles their active ammo.

	I have consciously made the decision (ahead of time, having this foresight) to design it so special ammos cannot be used on self. If a client
	wants to use a defensive ammo, for example, on themselves, they would need to shoot an applicable target (enemy, teammate, vehicle... lol) and then step
	into the range.
*/

// no one sees my special ammo because it should be drawing it based on MY size not theirs but it's drawing it based on theirs and if they have zero points in the talent then they can't see it.
stock DrawSpecialAmmoTarget(int TargetClient, int CurrentPos,
							float PosX=0.0, float PosY=0.0, float PosZ=0.0,
							float f_ActiveTime=0.0, int owner=0, char[] TalentName = "none", int Target = -1) {		// If we aren't actually drawing..? Stoned idea lost in thought but expanded somewhat not on the original path
	int client = TargetClient;
	if (owner != 0) client = owner;
	if (iRPGMode <= 0) return -1;
	//int CurrentPos	= GetMenuPosition(client, TalentName);
	DrawSpecialAmmoValues[client]	= GetArrayCell(a_Menu_Talents, CurrentPos, 1);

	float AfxRange			= GetSpecialAmmoStrength(client, TalentName, 3, _, _, CurrentPos);
	float AfxRangeBonus = GetAbilityStrengthByTrigger(client, TargetClient, TRIGGER_aamRNG, _, 0, _, _, RESULT_d, 1, true);
	if (AfxRangeBonus > 0.0) AfxRangeBonus *= (1.0 + AfxRangeBonus);
	char AfxDrawPos[64];
	char AfxDrawColour[64];
	int drawpos = TALENT_FIRST_RANDOM_KEY_POSITION;
	int drawcolor = TALENT_FIRST_RANDOM_KEY_POSITION;
	DrawSpecialAmmoKeys[client]		= GetArrayCell(a_Menu_Talents, CurrentPos, 0);
	while (drawpos >= 0 && drawcolor >= 0) {
		drawpos = FormatKeyValue(AfxDrawPos, sizeof(AfxDrawPos), DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "draw pos?", _, _, drawpos, false);
		drawcolor = FormatKeyValue(AfxDrawColour, sizeof(AfxDrawColour), DrawSpecialAmmoKeys[client], DrawSpecialAmmoValues[client], "draw colour?", _, _, drawcolor, false);
		if (drawpos < 0 || drawcolor < 0) return -1;
		//if (StrEqual(AfxDrawColour, "-1", false)) return -1;		// if there's no colour, we return otherwise you'll get errors like this: TE_Send Exception reported: No TempEntity call is in progress (return 0 here would cause endless loop set to -1 as it is ignored i broke the golden rule lul)
		CreateRingSoloEx(-1, AfxRange, AfxDrawColour, AfxDrawPos, false, f_ActiveTime, TargetClient, PosX, PosY, PosZ);
		drawpos++;
		drawcolor++;
	}
	return 2;
}

/*

	We need to get the talent name of the active special ammo.
	This way when an ammo activate triggers it only goes through if that ammo is the type the player currently has selected.
*/
stock bool GetActiveSpecialAmmo(client, char[] TalentName) {

	if (!StrEqual(TalentName, ActiveSpecialAmmo[client], false)) return false;
	// So if the talent is the one equipped...
	return true;
}

stock bool IsAmmoEffectActive(client, char[] TalentName) {
	float fCooldown = GetAmmoCooldownTime(client, TalentName);
	if (fCooldown == -1.0) return false;
	float fAmmoCooldownTime = fCooldown;
	int menuPos = GetMenuPosition(client, TalentName);
	fCooldown = GetSpecialAmmoStrength(client, TalentName, _, _, _, menuPos);

	float fAmmoCooldown = fCooldown + GetSpecialAmmoStrength(client, TalentName, 1, _, _, menuPos);
	fCooldown = fCooldown - (fAmmoCooldown - fAmmoCooldownTime);
	if (fCooldown > 0.0) return true;
	return false;
}

stock CheckActiveAmmoCooldown(client, char[] TalentName, bool bActivateCooldown=false, int pos = -1) {

	/*

		The original function is below. Rewritten after adding new functionality to function as originally intended.
	*/
	if (!IsLegitimateClient(client)) return -1;
	if (IsAmmoActive(client, TalentName)) return 2;	// even if bActivateCooldown, if it is on cooldown already, we don't create another cooldown.
	else if (bActivateCooldown) {
		IsAmmoActive(client, TalentName, GetSpecialAmmoStrength(client, TalentName, 1, _, _, pos));
	}
	else return 1;
	return 0;
}

stock bool IsAmmoActive(client, char[] TalentName, float f_Delay=0.0, bool IsActiveAbility = false) {
	char result[2][64];
	int pos = -1;
	int size = -1;
	if (f_Delay == 0.0) {
		size = GetArraySize(PlayerActiveAmmo[client]);
		if (IsActiveAbility) size = GetArraySize(PlayActiveAbilities[client]);
		for (int i = 0; i < size; i++) {
			if (!IsActiveAbility) {
				GetArrayString(a_Database_Talents, GetArrayCell(PlayerActiveAmmo[client], i, 0), result[0], sizeof(result[]));
				//GetTalentNameAtMenuPosition(client, GetArrayCell(PlayerActiveAmmo[client], i, 0), result[0], sizeof(result[]));
			}
			else {
				GetArrayString(a_Database_Talents, GetArrayCell(PlayActiveAbilities[client], i, 0), result[0], sizeof(result[]));
			}
			if (StrEqual(result[0], TalentName, false)) return true;

		}
		return false;
	}
	else {
		pos = GetMenuPosition(client, TalentName);
		if (!IsActiveAbility) {
			size = GetArraySize(PlayerActiveAmmo[client]);
			//ResizeArray(PlayerActiveAmmo[client], size + 1);
			PushArrayCell(PlayerActiveAmmo[client], pos);	// storing the position of the talent instead of the talent so we don't have to store a string.
			SetArrayCell(PlayerActiveAmmo[client], size, f_Delay, 1);
		}
		else {
			size = GetArraySize(PlayActiveAbilities[client]);
			//ResizeArray(PlayActiveAbilities[client], size + 1);
			PushArrayCell(PlayActiveAbilities[client], pos);
			SetArrayCell(PlayActiveAbilities[client], size, f_Delay, 1);
			SetArrayCell(PlayActiveAbilities[client], size, GetIfTriggerRequirementsMetAlways(client, TalentName), 2);
			SetArrayCell(PlayActiveAbilities[client], size, 0.0, 3);	// so that all abilities active/passive visual effects show on the first tick.
		}
	}
	return false;
}

stock float GetAmmoCooldownTime(client, char[] TalentName, bool IsActiveTimeInstead = false) {

	//Push to an array.
	char result[3][64];
	int size = GetArraySize(PlayerActiveAmmo[client]);
	float timeRemaining = 0.0;
	if (IsActiveTimeInstead) size = GetArraySize(PlayActiveAbilities[client]);
	for (int i = 0; i < size; i++) {

		if (!IsActiveTimeInstead) {
			GetArrayString(a_Database_Talents, GetArrayCell(PlayerActiveAmmo[client], i, 0), result[0], sizeof(result[]));
			timeRemaining = GetArrayCell(PlayerActiveAmmo[client], i, 1);
		}
		else {
			GetArrayString(a_Database_Talents, GetArrayCell(PlayActiveAbilities[client], i, 0), result[0], sizeof(result[]));
			timeRemaining = GetArrayCell(PlayActiveAbilities[client], i, 1);
		}
		if (StrEqual(result[0], TalentName, false)) return timeRemaining;
	}
	return -1.0;
}

/*

	Return different types of results about the special ammo. 0, the default, returns its active time
	0	Ability Time
	1	Cooldown Time
	2	Stamina Cost
	3	Range
	4	Interval Time
	5	Effect Strength
*/
stock float GetSpecialAmmoStrength(client, char[] TalentName, resulttype=0, bool bGetNextUpgrade=false, TalentStrengthOverride = 0, int menupos = -1) {

	int pos							=	(menupos == -1) ? GetMenuPosition(client, TalentName) : menupos;
	if (pos == -1) return -1.0;		// no ammo is selected.
	int TheStrength = GetArrayCell(MyTalentStrength[client], pos);
	float f_Str					=	TheStrength * 1.0;
	float i_FirstPoint			= 0.0;
	float i_FirstPoint_Temp		= 0.0;
	float i_CooldownStart		= 0.0;
	if (TalentStrengthOverride != 0) f_Str = TalentStrengthOverride * 1.0;
	else if (bGetNextUpgrade) f_Str++;		// We add 1 point if we're showing the next upgrade value.

	//SpecialAmmoStrengthKeys[client]			= GetArrayCell(a_Menu_Talents, pos, 0);
	SpecialAmmoStrengthValues[client]		= GetArrayCell(a_Menu_Talents, pos, 1);

	char governingAttribute[64];
	GetGoverningAttribute(client, TalentName, governingAttribute, sizeof(governingAttribute), pos);
	float attributeMult = 0.0;
	if (!StrEqual(governingAttribute, "-1")) attributeMult = GetAttributeMultiplier(client, governingAttribute);
	float TheAbilityMultiplier = 0.0;

	if (f_Str > 0.0) {

		if (resulttype == 0) {		// Ability Time
			i_FirstPoint		=	GetArrayCell(SpecialAmmoStrengthValues[client], SPELL_ACTIVE_TIME_FIRST_POINT);
			i_FirstPoint_Temp	=	(i_FirstPoint * attributeMult);	// Constitution increases the first point value of spells.
			i_FirstPoint		+= i_FirstPoint_Temp;
			f_Str			=	i_FirstPoint;
			f_Str += GetAbilityStrengthByTrigger(client, _, TRIGGER_spellbuff, _, _, _, _, RESULT_activetime, 0, true);
		}
		else if (resulttype == 1) {		// Cooldown Time
			i_CooldownStart			=	GetArrayCell(SpecialAmmoStrengthValues[client], SPELL_COOLDOWN_START);
			i_FirstPoint			=	GetArrayCell(SpecialAmmoStrengthValues[client], SPELL_COOLDOWN_FIRST_POINT);
			i_FirstPoint_Temp	=	(i_FirstPoint * attributeMult);
			i_FirstPoint		+= i_FirstPoint_Temp;
			TheAbilityMultiplier = GetAbilityMultiplier(client, "L");
			if (TheAbilityMultiplier != -1.0) {
				if (TheAbilityMultiplier < 0.0) TheAbilityMultiplier = 0.1;
				else if (TheAbilityMultiplier > 0.0) { //cooldowns are reduced
					i_FirstPoint		*= TheAbilityMultiplier;
				}
			}
			f_Str			=	i_FirstPoint;
			f_Str			+=	i_CooldownStart;
			f_Str -= GetAbilityStrengthByTrigger(client, _, TRIGGER_spellbuff, _, _, _, _, RESULT_cooldown, 0, true);
			//float minimumCooldown = GetSpecialAmmoStrength(client, TalentName, _, _, _, pos);
			// If talents reduce the cooldown time, we need to make sure the cooldown is never less than the active time - or they could have multiple of the same spell active at one time.
			//if (f_Str < minimumCooldown) f_Str = minimumCooldown;//f_Str = GetSpecialAmmoStrength(client, TalentName, _, bGetNextUpgrade, TalentStrengthOverride);
		}
		else if (resulttype == 2) {		// Stamina Cost
			int baseStamReq = GetArrayCell(SpecialAmmoStrengthValues[client], SPELL_BASE_STAMINA_REQ);
			i_FirstPoint						=	baseStamReq * 1.0;
			i_FirstPoint_Temp					=	(i_FirstPoint * attributeMult);
			if (i_FirstPoint_Temp > 0.0) i_FirstPoint += i_FirstPoint_Temp;
			f_Str								=	i_FirstPoint;
			f_Str -= GetAbilityStrengthByTrigger(client, _, TRIGGER_spellbuff, _, _, _, _, RESULT_staminacost, 0, true);
			//if (f_Str < baseStamReq) f_Str = baseStamReq * 1.0;
			// we do class multiplier after because we want to allow classes to modify the restrictions
		}
		else if (resulttype == 3) {		// Range
			i_FirstPoint						=	GetArrayCell(SpecialAmmoStrengthValues[client], SPELL_RANGE_FIRST_POINT);
			i_FirstPoint_Temp					=	(i_FirstPoint * attributeMult);
			i_FirstPoint						+=	i_FirstPoint_Temp;
			f_Str			=	i_FirstPoint;
			f_Str += GetAbilityStrengthByTrigger(client, _, TRIGGER_spellbuff, _, _, _, _, RESULT_range, 0, true);
		}
	}
	//if (resulttype == 3) return (f_Str / 2);	// we always measure from the center-point.
	return f_Str;
}

stock bool IsActiveAmmoCooldown(client, effect = '0', char[] activeTalentSearchKey = "none") {
	char result[2][64];
	char EffectT[4];
	Format(EffectT, sizeof(EffectT), "%c", effect);
	int size = GetArraySize(PlayerActiveAmmo[client]);
	int pos = -1;
	char text[64];
	for (int i = 0; i < size; i++) {
		pos = GetArrayCell(PlayerActiveAmmo[client], i);
		GetArrayString(a_Database_Talents, pos, result[0], sizeof(result[]));
		if (pos < 0) continue;	// wtf?
		//ActiveAmmoCooldownKeys[client]				= GetArrayCell(a_Menu_Talents, pos, 0);
		ActiveAmmoCooldownValues[client]			= GetArrayCell(a_Menu_Talents, pos, 1);
		if (StrEqual(activeTalentSearchKey, "none")) {
			GetArrayString(ActiveAmmoCooldownValues[client], SPELL_AMMO_EFFECT, text, sizeof(text));
			if (StrContains(text, EffectT, true) == -1) continue;
		}
		else {
			GetArrayString(ActiveAmmoCooldownValues[client], ABILITY_ACTIVE_EFFECT, text, sizeof(text));
			if (!StrEqual(text, activeTalentSearchKey, true)) continue;	// case sensitive
		}
		if (CheckActiveAmmoCooldown(client, result[0], _, pos) == 2) return true;
	}
	return false;
}

stock GetSpecialAmmoEffect(char[] TheValue, TheSize, client, char[] TalentName) {
	int pos			= GetMenuPosition(client, TalentName);
	if (pos >= 0) {
		SpecialAmmoEffectValues[client]			= GetArrayCell(a_Menu_Talents, pos, 1);

		GetArrayString(SpecialAmmoEffectValues[client], SPELL_AMMO_EFFECT, TheValue, TheSize);
	}
}