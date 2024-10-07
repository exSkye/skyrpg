stock float GetAbilityStrengthByTrigger(activator, targetPlayer = 0, int AbilityT, zombieclass = 0, damagevalue = 0,
										bool IsOverdriveStacks = false, bool IsCleanse = false, int ResultEffects = -1,
										ResultType = 0, bool bDontActuallyActivateSwitch = false, typeOfValuesToRetrieve = 1,
										hitgroup = -1, char[] abilityTrigger = "none", damagetype = -1, countAllTalentsRegardlessOfState = 0,
										bool bCooldownAlwaysActivates = false, entityIdToPassThrough = -1, int allowRecursiveSelf = 0) {// activator, target, trigger ability, survivor effects, infected effects, 
														//common effects, zombieclass, damage typeofvalues: 0 (all) 1 (NO RAW) 2(raw values only)

	// Don't run this method if non-player activator or if the RPG module is disabled.
	if (iRPGMode <= 0) return 0.0;




	// Redirect to infected talents
	if (myCurrentTeam[activator] == TEAM_INFECTED || !b_IsLoaded[activator]) return 0.0;//GetInfectedAbilityStrengthByTrigger(activator, targetPlayer, AbilityT, zombieclass, damagevalue, IsOverdriveStacks, IsCleanse, ResultEffects,
																					//ResultType, bDontActuallyActivateSwitch, typeOfValuesToRetrieve, hitgroup, abilityTrigger, damagetype, countAllTalentsRegardlessOfState,
																					//bCooldownAlwaysActivates, entityIdToPassThrough, allowRecursiveSelf);




	// This check serves as a redundancy to ensure that player arrays have been properly resized.
	// I don't think it's necessary; will need to test this in a future update.
	int ASize = GetArraySize(a_Menu_Talents);
	if (GetArraySize(MyTalentStrengths[activator]) != ASize) {
		SetClientTalentStrength(activator);
		return 0.0;
	}
	if (GetArraySize(MyTalentStrength[activator]) != ASize) return 0.0;




	// Some talents call this method directly, with overrides to force a different outcome relative to the triggers/active events currently active.
	if (targetPlayer == -2) targetPlayer = FindAnyRandomClient();



	bool isTargetLegitimate = IsLegitimateClient(targetPlayer);
	bool isWitch = (isTargetLegitimate) ? false : IsWitch(targetPlayer);
	bool isCommon = (isTargetLegitimate || isWitch) ? false : IsCommonInfected(targetPlayer);

	// If the target of the ability is not a valid common infected or player entity, the target of the ability MUST always be the activator.
	if (targetPlayer < 1 || !isTargetLegitimate && !isCommon && !isWitch) targetPlayer = activator;


	

	// There are numerous talents that require different types of infected, so I'm storing as much as I can ahead of looping.
	int targetTeam = (isTargetLegitimate) ? myCurrentTeam[targetPlayer] : -1;




	// Classes in L4D2 only count Special Infected + Tank
	// This module fills in the blank spots; 0 is survivor, 1 - 6 are specials, 7 is the witch, 8 is the tank, 9 is common infected, -1 on error.
	// Bit shifting is used here because some talents allow multiple classes, but not all, and it's the fastest method I know of that can check that.
	int targetClass = 	(isTargetLegitimate) ? (targetTeam == TEAM_SURVIVOR) ? 0 : FindZombieClass(targetPlayer) : (isWitch) ? 7 : (isCommon) ? 9 : -1;
	if (targetClass == 0) targetClass = 1;
	else if (targetClass == 1) targetClass = 2;
	else if (targetClass == 2) targetClass = 4;
	else if (targetClass == 3) targetClass = 8;
	else if (targetClass == 4) targetClass = 16;
	else if (targetClass == 5) targetClass = 32;
	else if (targetClass == 6) targetClass = 64;
	else if (targetClass == 7) targetClass = 128;
	else if (targetClass == 8) targetClass = 256;
	else if (targetClass == 9) targetClass = 512;




	// Some talents require the player to be currently selected on a specific weapon, across any weapon category.
	int theItemActivatorIsHolding = GetEntPropEnt(activator, Prop_Data, "m_hActiveWeapon");
	char theItemActivatorIsHoldingName[64];
	if (theItemActivatorIsHolding != -1) GetEdictClassname(theItemActivatorIsHolding, theItemActivatorIsHoldingName, sizeof(theItemActivatorIsHoldingName));




	// In this method, the activator is always a survivor, as infected players are redirected at the top of the method.
	int activatorClass = 1;
	float p_Strength			= 0.0;
	float t_Strength			= 0.0;
	float p_Time				= 0.0;




	// Some talents stack their effects, and some don't.
	bool bIsCompounding = (ResultEffects != -1) ? true : false;
	bool bIsResultEffectsNone = (!bIsCompounding) ? true : false;




	// if we're not firing off the talents, it's because we're trying to collect their total value; it's the only reason!
	// However, some talents, like proficiencies, don't care about a specific result type and just want to collect all the results for the trigger.
	// This is where this check comes in; we check if (bIsCompounding && bIsResultEffectsNone) and if this statement is true, we know to collect all unlocked talents for that trigger, regardless of their result effect.
	if (bDontActuallyActivateSwitch) bIsCompounding = true;





	// Player stagger status is now updated every fStaggerTickrate instead of every time this func is called.
	// Should reduce overhead.
	bool targetIsStaggered = false;
	if (activator == targetPlayer) targetIsStaggered = bIsClientCurrentlyStaggered[activator];
	else if (isTargetLegitimate) targetIsStaggered = bIsClientCurrentlyStaggered[targetPlayer];// : IsCommonStaggered(targetPlayer);




	//if (hitgroup >= 4 && hitgroup <= 7) return HITGROUP_LIMB;	// limb
	//if (hitgroup == 1) return HITGROUP_HEAD;					// headshot
	//return HITGROUP_OTHER;									// not a limb
	int hitgroupType = GetHitgroupType(hitgroup);




	// Some talents require the survivor to be at a higher elevation than their target.
	float activatorPos[3];
	GetEntPropVector(activator, Prop_Send, "m_vecOrigin", activatorPos);
	int activatorHighGroundResult = DoesClientHaveTheHighGround(activatorPos, targetPlayer);




	// Some talents require the survivor to be scoped.
	// However, some talents require there to be a certain amount of time (or less) scoped, and this will measure that result.
	bool isScoped = false;
	float playerZoomTime = 0.0;
	isScoped = IsPlayerZoomed(activator);
	if (isScoped) playerZoomTime = GetActiveZoomTime(activator);




	// Some talents require a player to have been firing their weapon for a certain period of time.
	float playerHoldingFireTime = 0.0;
	playerHoldingFireTime = GetHoldingFireTime(activator);




	//bool IsAFakeClient = IsFakeClient(activator);
	//bool isTargetInTheAir = (targetFlags != -1 && !(targetFlags & FL_ONGROUND)) ? true : false;
	//bool activatorIsDucking = (activatorButtons & IN_DUCK) ? true : false;
	int activatorCombatState = (bIsInCombat[activator]) ? 1 : 0;
	int infectedAttacker = L4D2_GetInfectedAttacker(activator);
	bool incapState = IsIncapacitated(activator);
	bool ledgeState = (incapState) ? IsLedged(activator) : false;
	float fPercentageHealthRemaining = ((GetClientHealth(activator) * 1.0) / (GetMaximumHealth(activator) * 1.0));
	//float fPercentageHealthMissing = 1.0 - fPercentageHealthRemaining;
	float fPercentageHealthTargetRemaining = GetClientHealthPercentage(activator, targetPlayer, true);
	//float fPercentageHealthTargetMissing = 1.0 - fPercentageHealthTargetRemaining;

	bool activatorIsNotTargetPlayer = (activator != targetPlayer) ? true : false;
	float fTargetRange = (activatorIsNotTargetPlayer) ? GetTargetRange(activator, targetPlayer) : -1.0;
	int activatorCurrentWeaponSlot = GetWeaponSlot(lastEntityDropped[activator]);
	int targetEnsnaredSurvivor = (targetTeam == TEAM_INFECTED) ? L4D2_GetSurvivorVictim(targetPlayer) : -1;
	bool targetIsInfectedAndHasSurvivorEnsnared = (targetEnsnaredSurvivor != -1) ? true : false;
	float fCurrentEngineTime = GetEngineTime();
	bool lastHitboxMatches = (myLastHitbox[activator] == takeDamageEvent[activator][1]) ? true : false;

	int size = GetArraySize(MyUnlockedTalents[activator]);

	for (int pos = 0; pos < size; pos++) {
		// If a talent that doesn't actually activate gets called and bDontActuallyActivate defaults to false in the call, it'll toggle the state of bDontActuallyActivate to true
		// So when this event occurs, we want to reset the value of bDontActuallyActivate back to the specific calls requested value and repeat the scenario described as necessary.
		bool bDontActuallyActivate = bDontActuallyActivateSwitch;
		int i = GetArrayCell(MyUnlockedTalents[activator], pos);
		TriggerValues[activator]	= GetArrayCell(a_Menu_Talents, i, 1);

		// We need to check if this is an effect over time first because active effects have to skip the trigger check to be always active.
		bool bIsEffectOverTime = (GetArrayCell(TriggerValues[activator], TALENT_IS_EFFECT_OVER_TIME) == 1) ? true : false;
		bool isEffectOverTimeActive = (!bIsEffectOverTime || !EffectOverTimeActive(activator, i)) ? false : true;
		
		int posTrigger = (!isEffectOverTimeActive) ? GetArrayCell(TriggerValues[activator], TALENT_ABILITY_TRIGGER) : GetArrayCell(TriggerValues[activator], TALENT_ACTIVE_ABILITY_TRIGGER);
		if (posTrigger != AbilityT) continue;

		if (countAllTalentsRegardlessOfState == 0) {
			if (!isEffectOverTimeActive) {
				if (IsAbilityCooldown(activator, i)) continue;
			}
			else if (IsActiveAbilityCooldown(activator, i)) continue;
		}

		if (bIsCompounding && !bIsResultEffectsNone) {
			int isThisTalentACompoundingTalent = GetArrayCell(TriggerValues[activator], COMPOUNDING_TALENT);
			if (isThisTalentACompoundingTalent != 1) continue;
		}
		int activatorEffectsInt = GetArrayCell(MyUnlockedTalents[activator], pos, 1);
		int targetEffectsInt = GetArrayCell(MyUnlockedTalents[activator], pos, 2);

		if (targetEffectsInt >= 0 && targetPlayer != activator) ResultType = 1;
		else if (activatorEffectsInt >= 0) ResultType = 0;
		else if (!bIsCompounding) continue;	// if both targeteffects and activatoreffects are empty or activatoreffects is empty but the activator is the target, continue
		if (bIsCompounding && !bIsResultEffectsNone) {
			if (ResultType == 0 && ResultEffects != activatorEffectsInt) continue;
			if (ResultType >= 1 && ResultEffects != targetEffectsInt) continue;
		}

		int activatorClassesAllowed = GetArrayCell(TriggerValues[activator], ACTIVATOR_CLASS_REQ);
		if (activatorClassesAllowed != -1 && !clientClassIsAllowed(activatorClassesAllowed, activatorClass)) continue;

		bool bIsEffectOverTimeIgnoresClass = (!isEffectOverTimeActive || GetArrayCell(TriggerValues[activator], IF_EOT_ACTIVE_ALLOW_ALL_ENEMIES) != 1) ? false : true;
		int targetClassesAllowed = GetArrayCell(TriggerValues[activator], TARGET_CLASS_REQ);
		if (targetClassesAllowed != -1 && !bIsEffectOverTimeIgnoresClass && (!isTargetLegitimate || !clientClassIsAllowed(targetClassesAllowed, targetClass))) continue;
		int isRawType = (GetArrayCell(TriggerValues[activator], ABILITY_TYPE) == 3) ? 1 : 0;
		// overriding typeOfValuesToRetrieve in header skips this next statement
		if (bIsCompounding && (typeOfValuesToRetrieve == 1 && isRawType == 1 || typeOfValuesToRetrieve == 2 && isRawType == 0)) continue;
		float fTimeSinceAttackerLastAttack = GetArrayCell(TriggerValues[activator], TIME_SINCE_LAST_ACTIVATOR_ATTACK);
		if (fTimeSinceAttackerLastAttack > 0.0 && fCurrentEngineTime - LastAttackTime[activator] < fTimeSinceAttackerLastAttack) continue;

		char playerRequiredToBeInSpecialAmmo[10];
		GetArrayString(TriggerValues[activator], ACTIVATOR_MUST_BE_IN_AMMO, playerRequiredToBeInSpecialAmmo, sizeof(playerRequiredToBeInSpecialAmmo));
		if (!StrEqual(playerRequiredToBeInSpecialAmmo, "-1") && !IsClientInRangeSpecialAmmoBoolean(activator, playerRequiredToBeInSpecialAmmo)) continue;

		char TargetRequiredToBeInSpecialAmmo[10];
		GetArrayString(TriggerValues[activator], TARGET_MUST_BE_IN_AMMO, TargetRequiredToBeInSpecialAmmo, sizeof(TargetRequiredToBeInSpecialAmmo));
		if (!StrEqual(TargetRequiredToBeInSpecialAmmo, "-1") && !IsClientInRangeSpecialAmmoBoolean(targetPlayer, TargetRequiredToBeInSpecialAmmo)) continue;
		
		// We can now make sure ability triggers are only required if the talent is not an effect over time, or if it is that it is false.
		int combatStateReq = GetArrayCell(TriggerValues[activator], COMBAT_STATE_REQ);
		if (combatStateReq >= 0 && combatStateReq != activatorCombatState) continue;

		int requireSameHitbox = GetArrayCell(TriggerValues[activator], REQUIRE_SAME_HITBOX);
		if (requireSameHitbox == 1 && !lastHitboxMatches) continue;

		char coherencyTalentNearbyRequired[64];
		GetArrayString(TriggerValues[activator], COHERENCY_TALENT_NEARBY_REQUIRED, coherencyTalentNearbyRequired, sizeof(coherencyTalentNearbyRequired));
		if (!StrEqual(coherencyTalentNearbyRequired, "-1") && !IsPlayerWithinBuffRange(activator, coherencyTalentNearbyRequired)) continue;

		float fCoherencyRange = GetArrayCell(TriggerValues[activator], COHERENCY_RANGE);
		int requireAllyWithAdren = GetArrayCell(TriggerValues[activator], REQUIRE_ALLY_WITH_ADRENALINE);
		if (requireAllyWithAdren == 1 && !alliesInRangeWithAdrenaline(activator, fCoherencyRange)) continue;

		int requireAllyOnFire = GetArrayCell(TriggerValues[activator], REQUIRE_ALLY_ON_FIRE);
		if (requireAllyOnFire == 1 && !alliesInRangeOnFire(activator, fCoherencyRange)) continue;

		int targetMustHaveAllyEnsnared = GetArrayCell(TriggerValues[activator], REQUIRE_TARGET_HAS_ENSNARED_ALLY);
		if (targetMustHaveAllyEnsnared == 1) {
			if (!targetIsInfectedAndHasSurvivorEnsnared || !ClientsWithinRange(activator, targetPlayer, fCoherencyRange)) continue;
		}

		float requireAllyBelowHealthPercentage = GetArrayCell(TriggerValues[activator], REQUIRE_ALLY_BELOW_HEALTH_PERCENTAGE);
		if (requireAllyBelowHealthPercentage > 0.0 && !anyNearbyAlliesBelowHealthPercentage(activator, requireAllyBelowHealthPercentage, fCoherencyRange)) continue;

		int iMustNotBeHurtBySpecialInfectedOrWitch = GetArrayCell(TriggerValues[activator], UNHURT_BY_SPECIALINFECTED_OR_WITCH);
		if (iMustNotBeHurtBySpecialInfectedOrWitch == 1) {
			if (!isTargetLegitimate && !isWitch) continue;	// talents with this flag only work on special infected and witches as common infected/super common infected don't track tanking damage
			if (hasTargetHurtClient(activator, targetPlayer, isTargetLegitimate ? 0 : 1)) continue;
		}
		int iContributionTypeCategory = GetArrayCell(TriggerValues[activator], CONTRIBUTION_TYPE_CATEGORY);
		if (iContributionTypeCategory >= 0 && GetArrayCell(playerContributionTracker[activator], iContributionTypeCategory) < GetArrayCell(TriggerValues[activator], CONTRIBUTION_COST)) continue;
		int iWeaponSlotRequired = GetArrayCell(TriggerValues[activator], TALENT_WEAPON_SLOT_REQUIRED);
		if (iWeaponSlotRequired >= 0 && activatorCurrentWeaponSlot != iWeaponSlotRequired) continue;
		if (!LastHitWasHeadshot[activator] && GetArrayCell(TriggerValues[activator], LAST_KILL_MUST_BE_HEADSHOT) == 1) continue;
		if (GetArrayCell(TriggerValues[activator], TARGET_AND_LAST_TARGET_CLASS_MATCH) == 1 && targetClass != LastTargetClass[activator]) continue;
		if (activatorIsNotTargetPlayer) {
			float fTargetRangeRequired = GetArrayCell(TriggerValues[activator], TARGET_RANGE_REQUIRED);
			if (fTargetRangeRequired > 0.0) {
				if (activator == targetPlayer) continue;	// talents requiring a target range can't trigger if the activator is the target.
				bool bTargetMustBeWithinRange = (GetArrayCell(TriggerValues[activator], TARGET_RANGE_REQUIRED_OUTSIDE) != 1) ? true : false;
				if (bTargetMustBeWithinRange && fTargetRange > fTargetRangeRequired) continue;
				if (!bTargetMustBeWithinRange && fTargetRange <= fTargetRangeRequired) continue;
			}
		}
		int iLastTargetResult = GetArrayCell(TriggerValues[activator], TARGET_MUST_BE_LAST_TARGET);
		if (targetPlayer != lastTarget[activator] && iLastTargetResult == 1 || targetPlayer == lastTarget[activator] && iLastTargetResult == 0) continue;

		if (GetArrayCell(TriggerValues[activator], TARGET_IS_SELF) == 1) targetPlayer = activator;
		if (activatorIsNotTargetPlayer) {
			if (activatorHighGroundResult != 1 && GetArrayCell(TriggerValues[activator], ACTIVATOR_MUST_HAVE_HIGH_GROUND) == 1) continue;
			if (activatorHighGroundResult != -1 && GetArrayCell(TriggerValues[activator], TARGET_MUST_HAVE_HIGH_GROUND) == 1) continue;
			if (activatorHighGroundResult != 0 && GetArrayCell(TriggerValues[activator], ACTIVATOR_TARGET_MUST_EVEN_GROUND) == 1) continue;
		}

		int effectStatesAllowed = GetArrayCell(TriggerValues[activator], ACTIVATOR_STATUS_EFFECT_REQUIRED);
		if (effectStatesAllowed > 0 && !clientHasEffectStateRequired(activator, effectStatesAllowed)) continue;
		if (isTargetLegitimate && targetPlayer != activator) {
			int effectStatesAllowedTarget = GetArrayCell(TriggerValues[activator], TARGET_STATUS_EFFECT_REQUIRED);
			if (effectStatesAllowedTarget > 0 && !clientHasEffectStateRequired(targetPlayer, effectStatesAllowedTarget)) continue;
		}
		//if (!IsStatusEffectFound(activator, TriggerKeys[activator], TriggerValues[activator])) continue;

		float f_Strength	=	1.0;
		//iStrengthOverride = 0;
		//bIsCompounding = false;
		int iSurvivorsInRange = 0;

		// if bcompounding is enabled we need to make sure talents that are not compounding talents don't get calculated. right now they do.

		/*if (GetKeyValueIntAtPos(TriggerValues[activator], COMPOUNDING_TALENT) == 1) {
			bIsCompounding = true;
			if (StrEqual(ResultEffects, "none", false)) GetArrayString(TriggerValues[activator], COMPOUND_WITH, ResultEffects, sizeof(ResultEffects[]));
			if (StrEqual(ResultEffects, "-1", false)) continue;
		}*/
		int secondaryEffectInt = GetArrayCell(MyUnlockedTalents[activator], pos, 3);
		char nameOfItemToGivePlayer[64];
		GetArrayString(TriggerValues[activator], ITEM_NAME_TO_GIVE_PLAYER, nameOfItemToGivePlayer, sizeof(nameOfItemToGivePlayer));
		int activatorCallAbilityTrigger = GetArrayCell(MyUnlockedTalents[activator], pos, 7);
		int targetCallAbilityTrigger = GetArrayCell(MyUnlockedTalents[activator], pos, 8);

		float fPercentageHealthRequired = GetArrayCell(TriggerValues[activator], HEALTH_PERCENTAGE_REQ_ACT_REMAINING);
		if (fPercentageHealthRequired > 0.0 && fPercentageHealthRemaining < fPercentageHealthRequired) continue;

		float fPercentageHealthActivationCost = GetArrayCell(TriggerValues[activator], HEALTH_PERCENTAGE_ACTIVATION_COST);
		if (fPercentageHealthActivationCost > 0.0 && fPercentageHealthActivationCost >= fPercentageHealthRemaining) continue;
		/*
			This statement must come after the bIsCompounding check as we force a result type based on whether
			targeteffects or activatoreffects field is filled out in the talent.
		*/
		// if (target != activator && ResultType >= 1) {
		// 	if (targetEntityType == -1) continue;
		// 	if (StrEqual(targeteffects, "0")) continue;
		// }
		bool bIsEffectOverTimeIgnoresWeapon = (isEffectOverTimeActive && GetArrayCell(TriggerValues[activator], IF_EOT_ACTIVE_ALLOW_ALL_WEAPONS) == 1) ? true : false;
		if (!bIsEffectOverTimeIgnoresWeapon) {
			int iWeaponsPermitted = GetArrayCell(TriggerValues[activator], WEAPONS_PERMITTED);
			if (iWeaponsPermitted > 0 && !clientWeaponCategoryIsAllowed(activator, iWeaponsPermitted)) continue;
			
			char specificWeaponRequired[64];
			GetArrayString(TriggerValues[activator], WEAPON_NAME_REQUIRED, specificWeaponRequired, sizeof(specificWeaponRequired));
			if (!StrEqual(specificWeaponRequired, "-1") && StrContains(theItemActivatorIsHoldingName, specificWeaponRequired) == -1) continue;
		}

		fPercentageHealthRequired = GetArrayCell(TriggerValues[activator], HEALTH_PERCENTAGE_REQ);
		if (fPercentageHealthRequired > 0.0 && fPercentageHealthRemaining > fPercentageHealthRequired) continue;
		if (fCoherencyRange > 0.0) {
			iSurvivorsInRange = NumSurvivorsInRange(activator, fCoherencyRange);
			int iCoherencyMax = GetArrayCell(TriggerValues[activator], COHERENCY_MAX);
			if (iCoherencyMax > 0 && iSurvivorsInRange > iCoherencyMax) iSurvivorsInRange = iCoherencyMax;
			if (iSurvivorsInRange < 1 && GetArrayCell(TriggerValues[activator], COHERENCY_REQ) == 1) continue;
		}
		if (targetClass >= 0 && activatorIsNotTargetPlayer) {	// target exists and is not the activator.
			fPercentageHealthRequired = GetArrayCell(TriggerValues[activator], HEALTH_PERCENTAGE_REQ_TAR_REMAINING);
			if (fPercentageHealthRequired > 0.0 && fPercentageHealthTargetRemaining < fPercentageHealthRequired) continue;
			fPercentageHealthRequired = GetArrayCell(TriggerValues[activator], HEALTH_PERCENTAGE_REQ_TAR_MISSING);
			if (fPercentageHealthRequired > 0.0 && 1.0 - fPercentageHealthTargetRemaining < fPercentageHealthRequired) continue;
		}
		if (!isScoped && GetArrayCell(TriggerValues[activator], REQUIRES_ZOOM) == 1) continue;

		char TheString[10];
		GetArrayString(TriggerValues[activator], PLAYER_STATE_REQ, TheString, sizeof(TheString));
		if (!ComparePlayerState(activator, TheString, incapState, ledgeState, infectedAttacker)) continue;

		if (!isEffectOverTimeActive || GetArrayCell(TriggerValues[activator], IF_EOT_ACTIVE_ALLOW_ALL_HITGROUPS) != 1) {
			if (GetArrayCell(TriggerValues[activator], REQUIRES_HEADSHOT) == 1 && hitgroupType != HITGROUP_HEAD) continue;
			if (GetArrayCell(TriggerValues[activator], REQUIRES_LIMBSHOT) == 1 && hitgroupType != HITGROUP_LIMB) continue;
		}
		if (!bIsClientCurrentlyStaggered[activator] && GetArrayCell(TriggerValues[activator], ACTIVATOR_STAGGER_REQ) == 1) continue;
		if (!targetIsStaggered && GetArrayCell(TriggerValues[activator], TARGET_STAGGER_REQ) == 1) continue;
		if (!activatorIsNotTargetPlayer && GetArrayCell(TriggerValues[activator], CANNOT_TARGET_SELF) == 1) continue;
		// with this key, we can fire off nodes every x consecutive hits.
		int consecutiveHitsRequired = GetArrayCell(TriggerValues[activator], REQ_CONSECUTIVE_HITS);
		if (consecutiveHitsRequired > 0 && (ConsecutiveHits[activator] < 1 || ConsecutiveHits[activator] % consecutiveHitsRequired != 0)) continue;

		int consecutiveHeadshotsRequired = GetArrayCell(TriggerValues[activator], REQ_CONSECUTIVE_HEADSHOTS);
		if (consecutiveHeadshotsRequired > 0 && (ConsecutiveHeadshots[activator] < 1 || ConsecutiveHeadshots[activator] % consecutiveHeadshotsRequired != 0)) continue;
		// no need to calculate each time. Only run these calculations when a player puts a point in or removes a point from a talent.
		float f_EachPoint				= GetArrayCell(MyTalentStrengths[activator], i);
		float f_Time					= GetArrayCell(MyTalentStrengths[activator], i, 1);
		float f_Cooldown				= GetArrayCell(MyTalentStrengths[activator], i, 2);
		f_Strength				= f_EachPoint;
		// More Multiplying talents by a certain number of things...

		int numOfIncapacitatedAlliesInRange = 0;
		int numOfEnsnaredAlliesInRange = 0;
		int numOfHealthyAlliesInRange = 0;
		GetClientsInRangeByState(activator, fCoherencyRange, numOfIncapacitatedAlliesInRange, numOfEnsnaredAlliesInRange, numOfHealthyAlliesInRange);
		
		if (numOfIncapacitatedAlliesInRange > 0) {
			float multStrengthByNearbyAllies = GetArrayCell(TriggerValues[activator], MULT_STR_NEARBY_DOWN_ALLIES);
			if (multStrengthByNearbyAllies > 0.0) f_Strength += f_Strength * (numOfIncapacitatedAlliesInRange * multStrengthByNearbyAllies);
		}

		if (numOfEnsnaredAlliesInRange < 1 && GetArrayCell(TriggerValues[activator], REQUIRE_ENSNARED_ALLY) == 1) continue;

		int requireEnemyInCoherencyRange = GetArrayCell(TriggerValues[activator], REQUIRE_ENEMY_IN_COHERENCY_RANGE);
		int enemyInCoherencyRangeIsTarget = GetArrayCell(TriggerValues[activator], ENEMY_IN_COHERENCY_IS_TARGET);
		int enemyPlayerInRange = -1;
		if (requireEnemyInCoherencyRange == 1) {
			enemyPlayerInRange = enemyInRange(activator, fCoherencyRange);
			if (enemyPlayerInRange == -1) continue;
			if (enemyInCoherencyRangeIsTarget == 1) targetPlayer = enemyPlayerInRange;
		}

		float multStrengthByNearbyEnsnaredAllies = GetArrayCell(TriggerValues[activator], MULT_STR_NEARBY_ENSNARED_ALLIES);
		if (multStrengthByNearbyEnsnaredAllies > 0.0 && numOfEnsnaredAlliesInRange > 0) f_Strength += f_Strength * (numOfEnsnaredAlliesInRange * multStrengthByNearbyEnsnaredAllies);

		int maxConsecutiveHitsToCount = 0;
		int maxConsecutiveHitsDivide = 0;
		int maxConsecutiveHeadshotsToCount = 0;
		int maxConsecutiveHeadshotsDivide = 0;

		if (GetArrayCell(TriggerValues[activator], MULT_STR_CONSECUTIVE_HITS) == 1) {
			maxConsecutiveHitsToCount = GetArrayCell(TriggerValues[activator], MULT_STR_CONSECUTIVE_MAX);
			if (maxConsecutiveHitsToCount > ConsecutiveHits[activator]) maxConsecutiveHitsToCount = ConsecutiveHits[activator];
			if (maxConsecutiveHitsToCount < 1) maxConsecutiveHitsToCount = 0;
			maxConsecutiveHitsDivide = GetArrayCell(TriggerValues[activator], MULT_STR_CONSECUTIVE_DIV);
			if (maxConsecutiveHitsDivide > 0 && maxConsecutiveHitsToCount > 0) maxConsecutiveHitsToCount = RoundToCeil((maxConsecutiveHitsToCount * 1.0) / (maxConsecutiveHitsDivide * 1.0));
			//f_Strength			*= maxConsecutiveHitsToCount;
		}
		if (GetArrayCell(TriggerValues[activator], MULT_STR_CONSECUTIVE_HEADSHOTS) == 1) {
			maxConsecutiveHeadshotsToCount = GetArrayCell(TriggerValues[activator], MULT_STR_CONSECUTIVE_HEADSHOTS_MAX);
			if (maxConsecutiveHeadshotsToCount > ConsecutiveHeadshots[activator]) maxConsecutiveHeadshotsToCount = ConsecutiveHeadshots[activator];
			if (maxConsecutiveHeadshotsToCount < 1) maxConsecutiveHeadshotsToCount = 0;
			maxConsecutiveHeadshotsDivide = GetArrayCell(TriggerValues[activator], MULT_STR_CONSECUTIVE_HEADSHOTS_DIV);
			if (maxConsecutiveHeadshotsDivide > 0 && maxConsecutiveHeadshotsToCount > 0) maxConsecutiveHeadshotsToCount = RoundToCeil((maxConsecutiveHeadshotsToCount * 1.0) / (maxConsecutiveHeadshotsDivide * 1.0));
			//f_Strength			*= maxConsecutiveHeadshotsToCount;
		}
		if (maxConsecutiveHitsToCount > 0 || maxConsecutiveHeadshotsToCount > 0) {
			f_Strength			*= (maxConsecutiveHitsToCount + maxConsecutiveHeadshotsToCount);
		}
		// we don't put the node on cooldown if we're not activating it.
		//if (!bDontActuallyActivate
		// we call the dontActuallyActivate functionality in actual damage calculations for certain events for better time complexity
		// so we're now using countAllTalentsRegardlessOfState which is yet... another new argument for this call.
		p_Strength = f_Strength;
		p_Time += f_Time;
		// background talents toggle bDontActuallyActivate here, because we do still want them to go on cooldown, and if we set it before the CreateCooldown method is called, they will not go on cooldown.
		// bDontActuallyActivate can be forcefully-called elsewhere, which is why it's ordered this way.
		if (GetArrayCell(TriggerValues[activator], BACKGROUND_TALENT) == 1) bDontActuallyActivate = true;
		// if (activator == target) Format(MultiplierText, sizeof(MultiplierText), "tS_%s", activatoreffects);
		// else Format(MultiplierText, sizeof(MultiplierText), "tS_%s", targeteffects);
		bool bIsStatusEffects = (GetArrayCell(TriggerValues[activator], STATUS_EFFECT_MULTIPLIER) == 1) ? true : false;
		
		float fMultiplyRange = GetArrayCell(TriggerValues[activator], MULTIPLY_RANGE);
		if (fMultiplyRange > 0.0) { // this talent multiplies its strength by the # of a certain type of entities in range.
			int iMultiplyCount = 0;
			int typeOfTargetToMultiply = GetArrayCell(TriggerValues[activator], MULTIPLY_TYPE);
			if (doWeMultiplyThisTargetType(typeOfTargetToMultiply, MULTIPLY_COMMON)) {
				iMultiplyCount += LivingEntitiesInRangeByType(activator, fMultiplyRange, 0);
			}
			if (doWeMultiplyThisTargetType(typeOfTargetToMultiply, MULTIPLY_SUPER)) {
				iMultiplyCount += LivingEntitiesInRangeByType(activator, fMultiplyRange, 1);
			}
			if (doWeMultiplyThisTargetType(typeOfTargetToMultiply, MULTIPLY_WITCH)) {
				iMultiplyCount += LivingEntitiesInRangeByType(activator, fMultiplyRange, 2);
			}
			if (doWeMultiplyThisTargetType(typeOfTargetToMultiply, MULTIPLY_SURVIVOR)) {
				iMultiplyCount += LivingEntitiesInRangeByType(activator, fMultiplyRange, 3);
			}
			if (doWeMultiplyThisTargetType(typeOfTargetToMultiply, MULTIPLY_SPECIAL)) {
				iMultiplyCount += LivingEntitiesInRangeByType(activator, fMultiplyRange, 4);
			}
			if (iMultiplyCount > 0) p_Strength *= iMultiplyCount;
		}
		fMultiplyRange = GetArrayCell(TriggerValues[activator], STRENGTH_INCREASE_ZOOMED);
		if (fMultiplyRange > 0.0) {
			// If we want a cap on when staying zoomed in stops increasing the strength...
			float fPlayerMaxZoomTime = GetArrayCell(TriggerValues[activator], STRENGTH_INCREASE_TIME_CAP);
			if (fPlayerMaxZoomTime > 0.0 && playerZoomTime > fPlayerMaxZoomTime) playerZoomTime = fPlayerMaxZoomTime;
			// If we only want the bonus to be applied when a minimum amount of time has passed...
			fPlayerMaxZoomTime = GetArrayCell(TriggerValues[activator], STRENGTH_INCREASE_TIME_REQ);
			// no minimum time is required	or	player meets or exceeds time requirement.
			if (fPlayerMaxZoomTime <= 0.0 || playerZoomTime >= fPlayerMaxZoomTime) p_Strength += (f_Strength * (playerZoomTime / fMultiplyRange));
			else {
				// If the player doesn't meet the time requirement for this perk to give a bonus, we need to check if this is an x-increase over time perk, and don't fire if it is.
				if (GetArrayCell(TriggerValues[activator], ZOOM_TIME_HAS_MINIMUM_REQ) == 1) continue;
			}
		}
		fMultiplyRange = GetArrayCell(TriggerValues[activator], HOLDING_FIRE_STRENGTH_INCREASE);
		if (fMultiplyRange > 0.0) {
			// If we want a cap on when staying zoomed in stops increasing the strength...
			float fPlayerMaxHoldingFireTime = GetArrayCell(TriggerValues[activator], STRENGTH_INCREASE_TIME_CAP);
			if (fPlayerMaxHoldingFireTime > 0.0 && playerHoldingFireTime > fPlayerMaxHoldingFireTime) playerHoldingFireTime = fPlayerMaxHoldingFireTime;
			// If we only want the bonus to be applied when a minimum amount of time has passed...
			fPlayerMaxHoldingFireTime = GetArrayCell(TriggerValues[activator], STRENGTH_INCREASE_TIME_REQ);
			// no minimum time is required	or	player meets or exceeds time requirement.
			if (fPlayerMaxHoldingFireTime <= 0.0 || playerHoldingFireTime >= fPlayerMaxHoldingFireTime) p_Strength += (f_Strength * (playerHoldingFireTime / fMultiplyRange));
			else {
				// If the player doesn't meet the time requirement for this perk to give a bonus, we need to check if this is an x-increase over time perk, and don't fire if it is.
				if (GetArrayCell(TriggerValues[activator], DAMAGE_TIME_HAS_MINIMUM_REQ) == 1) continue;
			}
		}
		fPercentageHealthRequired = GetArrayCell(TriggerValues[activator], HEALTH_PERCENTAGE_REQ_MISSING);
		if (fPercentageHealthRequired > 0.0 && 1.0 - fPercentageHealthRemaining >= fPercentageHealthRequired) {	// maximum bonus (eg: 0.4 (40%) missing) we require 0.2 (20%) to be missing. 40% > 20%, so:
			float fPercentageHealthRequiredMax = GetArrayCell(TriggerValues[activator], HEALTH_PERCENTAGE_REQ_MISSING_MAX);	// say we only want to allow the buff once at 20%, and not twice at 40%:
			fPercentageHealthRequired = (fPercentageHealthRequiredMax > 0.0 && ((1.0 - fPercentageHealthRemaining) / fPercentageHealthRequired) > fPercentageHealthRequiredMax) ?	// 40% / 20% = 2.0 , if we set the max to 1.0 (to allow the buff just once:
										fPercentageHealthRequiredMax :							// true (so we set the max to 1.0 as in our sample scenario)
										((1.0 - fPercentageHealthRemaining) / fPercentageHealthRequired);	// false (but doesn't happen in our example scenario)
			p_Strength += (f_Strength * fPercentageHealthRequired);
		}
		if (iSurvivorsInRange > 0) p_Strength += (f_Strength * iSurvivorsInRange);
		if (!isEffectOverTimeActive && bIsEffectOverTime) {
			float fEffectActiveTime = GetArrayCell(TriggerValues[activator], TALENT_ACTIVE_STRENGTH_VALUE);
			EffectOverTimeActive(activator, i, fEffectActiveTime);
		}
		if (bIsCompounding) {
			if (!bIsStatusEffects) t_Strength += p_Strength;
			else t_Strength += (p_Strength * MyStatusEffects[activator]);
		}
		else {
			if (!IsOverdriveStacks) {
				int secondaryTrigger = GetArrayCell(MyUnlockedTalents[activator], pos, 6);
				if (bIsStatusEffects) p_Strength = (p_Strength * MyStatusEffects[activator]);
				if (ResultType >= 1) {
					if (!bDontActuallyActivate) {
						if (iContributionTypeCategory >= 0) SetArrayCell(playerContributionTracker[activator], iContributionTypeCategory, GetArrayCell(playerContributionTracker[activator], iContributionTypeCategory) - GetArrayCell(TriggerValues[activator], CONTRIBUTION_COST));
						ActivateAbilityEx(activator, targetPlayer, damagevalue, targetEffectsInt, p_Strength, p_Time, targetPlayer, _, isRawType,
											GetArrayCell(TriggerValues[activator], PRIMARY_AOE), secondaryEffectInt,
											GetArrayCell(TriggerValues[activator], SECONDARY_AOE), hitgroup, secondaryTrigger,
											abilityTrigger, damagetype, nameOfItemToGivePlayer, activatorCallAbilityTrigger, entityIdToPassThrough, fPercentageHealthActivationCost, targetCallAbilityTrigger);
					}
				}
				else {
					if (!bDontActuallyActivate) {
						if (iContributionTypeCategory >= 0) SetArrayCell(playerContributionTracker[activator], iContributionTypeCategory, GetArrayCell(playerContributionTracker[activator], iContributionTypeCategory) - GetArrayCell(TriggerValues[activator], CONTRIBUTION_COST));
						ActivateAbilityEx(activator, activator, damagevalue, activatorEffectsInt, p_Strength, p_Time, targetPlayer, _, isRawType,
																	GetArrayCell(TriggerValues[activator], PRIMARY_AOE), secondaryEffectInt,
																	GetArrayCell(TriggerValues[activator], SECONDARY_AOE), hitgroup, secondaryTrigger,
																	abilityTrigger, damagetype, nameOfItemToGivePlayer, activatorCallAbilityTrigger, entityIdToPassThrough, fPercentageHealthActivationCost, targetCallAbilityTrigger);
					}
				}
			}
			else {
				if (!bIsStatusEffects) t_Strength += p_Strength;
				else t_Strength += (p_Strength * MyStatusEffects[activator]);
			}
		}
		if (!bDontActuallyActivate || bCooldownAlwaysActivates) {
			// certain ammos need to reward buffing/hexing experience at this time.
			if (!isEffectOverTimeActive) {
				if (f_Cooldown > 0.0) CreateCooldown(activator, i, f_Cooldown);
			}
			else {
				float f_ActiveCooldown = GetArrayCell(TriggerValues[activator], ACTIVE_EFFECT_INTERVAL);
				if (f_ActiveCooldown > 0.0) CreateActiveCooldown(activator, i, f_ActiveCooldown);
			}
		}
		p_Strength = 0.0;
		p_Time = 0.0;
	}
	//if (StrEqual(ResultEffects, "o", true)) PrintToChat(activator, "damage reduction: %3.3f", t_Strength);
	if (targetPlayer != activator) LastTargetClass[activator] = targetClass;
	if (damagevalue > 0 && t_Strength > 0.0) {

		if (ResultType == 0 || ResultType == 2) return (t_Strength * damagevalue);
		if (ResultType == 1) return (damagevalue + (t_Strength * damagevalue));
	}
	if (t_Strength < 0.0) t_Strength = 0.0;
	return t_Strength;
}