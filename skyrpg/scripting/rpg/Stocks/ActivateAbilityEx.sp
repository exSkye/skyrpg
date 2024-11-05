void ActivateAbilityEx(int activator, int target, int menuPos, int d_Damage, int effectInt, float g_TalentStrength, float g_TalentTime, int victim = 0,
						char[] Trigger = "0", int isRaw = 0, float AoERange = 0.0, int secondaryEffects = -1,
						float secondaryAoERange = 0.0, int hitgroup = -1, int secondaryTrigger = -1,
						int damagetype = -1, char[] nameOfItemToGivePlayer = "-1", int activatorCallAbilityTrigger = -1, int entityIdToPassThrough = -1, float healthActivationCost = 0.0, int targetCallAbilityTrigger = -1) {
	//return;

	//PrintToChat(activator, "damage %d Effects: %s Strength: %3.2f", d_Damage, Effects, g_TalentStrength);
	// Activator is ALWAYS the person who holds the talent. The TARGET is who the ability ALWAYS activates on.

	/*
		It lags a lot when it has to check the string for a specific substring every single time, so we need to call activateabilityex multiple times for each different effect, instead.
	*/
	//bool isInfected = (IsLegitimateClient(target) && myCurrentTeam[target] == TEAM_INFECTED || IsCommonInfected(target) || IsWitch(target)) ? true : false;
	//bool defenderInRange = (isInfected && (IsSpecialCommonInRange(target, 't') || DrawSpecialInfectedAffixes(target, target) == 1)) ? true : false;
	// If the target of the talent is an infected player that's currently shielded by a defender, we return.
	//if (defenderInRange) return;

	int healthCost = (healthActivationCost <= 0.0) ? 0 : RoundToCeil(healthActivationCost * GetMaximumHealth(activator));
	if (healthCost > 0) SetClientTotalHealth(activator, activator, healthCost);

	if (g_TalentStrength > 0.0) {
		float fAmplifyPower = GetAbilityStrengthByTrigger(activator, activator, TRIGGER_amplify, _, _, _, _, effectInt, _, true);
		fAmplifyPower *= g_TalentStrength;
		g_TalentStrength += fAmplifyPower;
		// When a node successfully fires, it can call custom ability triggers.
		if (secondaryTrigger != -1) GetAbilityStrengthByTrigger(activator, target, secondaryTrigger, _, RoundToCeil(g_TalentStrength), _, _, _, _, _, _, hitgroup, _, damagetype);

		int iDamage = (isRaw == 1 || d_Damage == 0) ? RoundToCeil(g_TalentStrength) : RoundToCeil(d_Damage * g_TalentStrength);
		int talentStr = RoundToCeil(g_TalentStrength);

		if (activator == target) AddAttributeExperience(activator, ATTRIBUTE_RESILIENCE, iDamage);
		else AddAttributeExperience(activator, ATTRIBUTE_TECHNIQUE, iDamage);

		char governingAttribute[64];
		GetGoverningAttribute(activator, governingAttribute, sizeof(governingAttribute), menuPos);
		int governingAttributePos = GetAttributePosition(activator, governingAttribute);
		int governingAttributeBonus = RoundToCeil(iDamage * fGoverningAttributeModifier);
		AddAttributeExperience(activator, governingAttributePos, governingAttributeBonus);

		float activatorPos[3];
		GetClientAbsOrigin(activator, activatorPos);

		switch (effectInt) {
			case 0: {
				HealPlayer(activator, activator, g_TalentStrength, 'h', true);
			}
			case 1: {
				int numOfEntities = GetArraySize(playerCustomEntitiesCreated);
				//ResizeArray(playerCustomEntitiesCreated, numOfEntities+1);
				// 0 - activator
				// 1 - damage
				// 2 - entity
				// 3 - size of mine proximity
				// 4 - how long until this mine auto-explodes?
				// 5 - visual interval, so we know when to show the proximity ring to players.
				PushArrayCell(playerCustomEntitiesCreated, activator);
				SetArrayCell(playerCustomEntitiesCreated, numOfEntities, RoundToCeil(g_TalentStrength), 1);
				SetArrayCell(playerCustomEntitiesCreated, numOfEntities, entityIdToPassThrough, 2);
				SetArrayCell(playerCustomEntitiesCreated, numOfEntities, AoERange, 3);
				SetArrayCell(playerCustomEntitiesCreated, numOfEntities, GetEngineTime() + 30.0, 4);
				SetArrayCell(playerCustomEntitiesCreated, numOfEntities, 0, 5);
				CreateTimer(0.5, Timer_TickingMine, entityIdToPassThrough, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			case 2: {
				CreateAoE(activator, menuPos, AoERange, (g_TalentStrength < 1.0) ? RoundToCeil(d_Damage * g_TalentStrength) : RoundToCeil(g_TalentStrength), _, _, hitgroup, damagetype, targetCallAbilityTrigger);
			}
			case 3: {
				CreatePlayerExplosion(activator, RoundToCeil(d_Damage * g_TalentStrength), false);
			}
			case 4: {
				int acid = RoundToFloor(iDamage * (GetDifficultyRating(victim) * fAcidDamagePlayerLevel));
				AwardExperience(activator, HEXING_CONTRIBUTION, acid);

				acid += acid * (GetClientStatusEffect(victim, STATUS_EFFECT_ACID) + 1);
				CreateAndAttachFlame(victim, acid, 10.0, 0.5, FindInfectedClient(true), STATUS_EFFECT_ACID);
			}
			case 5: {
				int burn = RoundToFloor(iDamage * (GetDifficultyRating(victim) * fBurnPercentage));
				AwardExperience(activator, HEXING_CONTRIBUTION, burn);

				burn += burn * (GetClientStatusEffect(victim, STATUS_EFFECT_BURN) + 1);
				CreateAndAttachFlame(victim, burn, 10.0, 0.5, FindInfectedClient(true), STATUS_EFFECT_BURN);
			}
			case 6: {
				// this goes up here and we're gonna recursively call for "d"
				char curEquippedWeapon[64];
				int bulletsFired = 0;
				int WeaponId =	GetEntPropEnt(activator, Prop_Data, "m_hActiveWeapon");
				if (IsValidEntity(WeaponId)) {
					int bulletsRemaining = GetEntProp(WeaponId, Prop_Send, "m_iClip1");
					GetEntityClassname(WeaponId, curEquippedWeapon, sizeof(curEquippedWeapon));
					GetTrieValue(currentEquippedWeapon[activator], curEquippedWeapon, bulletsFired);
					if (bulletsFired >= bulletsRemaining) {
						// we only do something if the mag is half or more empty.
						int totalMagSize = bulletsFired + bulletsRemaining;
						float fMagazineExhausted = ((bulletsFired * 1.0)/(totalMagSize * 1.0));

						ActivateAbilityEx(activator, target, menuPos, d_Damage, secondaryEffects, (fMagazineExhausted * g_TalentStrength), g_TalentTime, victim, Trigger, isRaw, secondaryAoERange, _, _, hitgroup, _, damagetype);
					}
				}
			}
			case 7: {
				if (IsLegitimateClientAlive(activator) && IsLegitimateClientAlive(target)) {
					L4D_StaggerPlayer(target, activator, activatorPos);
				}
			}
			case 8: {
				if (!HasAdrenaline(target)) SDKCall(g_hEffectAdrenaline, target, g_TalentTime);
			}
			case 9: {
				if (myCurrentTeam[target] == TEAM_SURVIVOR && b_HasDeathLocation[target]) {
					if (!IsPlayerAlive(target)) {

						SDKCall(hRoundRespawn, target);
						b_HasDeathLocation[target] = false;
						CreateTimer(1.0, Timer_TeleportRespawn, target, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
			case 10: {
				if (!IsLegitimateClient(target) || myCurrentTeam[target] == TEAM_SURVIVOR || L4D2_GetSurvivorVictim(target) == -1) BeanBag(target, g_TalentStrength);
			}
			case 11: {
				CreateAndAttachFlame(target, iDamage, g_TalentTime, 0.5, activator, STATUS_EFFECT_BURN);
			}
			case 12: {
				CreateAndAttachFlame(target, iDamage, g_TalentTime, 0.5, activator, STATUS_EFFECT_ACID);
			}
			case 13: {
				if (IsLegitimateClient(target)) CreateFireEx(target);
			}
			case 14: {
				HealPlayer(target, activator, (d_Damage * g_TalentStrength) * 1.0, 'h', true);
			}
			case 15: {
				CreateBeacons(target, g_TalentStrength);
			}
			case 16: {
				ModifyGravity(target, g_TalentStrength, g_TalentTime, true);
			}
			case 17: {
				HealPlayer(target, activator, g_TalentStrength, 'h', true);
			}
			case 18: {
				HealPlayer(target, activator, g_TalentStrength, 'h', true);
			}
			case 19: {
				if (target != activator && IsLegitimateClientAlive(activator)) {
					HealPlayer(target, activator, g_TalentStrength, 'h', true);
				}
			}
			case 20: {
				if (IsLegitimateClientAlive(target) && !ISBILED[target]) {
					SDKCall(g_hCallVomitOnPlayer, target, activator, true);
					CreateTimer(15.0, Timer_RemoveBileStatus, target, TIMER_FLAG_NO_MAPCHANGE);
					ISBILED[target] = true;
				}
			}
			case 21: {
				ForceClientJump(activator, g_TalentStrength, target);
			}
			case 22: {
				CloakingDevice(target);
			}
			case 23: {
				DamagePlayer(activator, target, g_TalentStrength);
			}
			case 24: {
				GiveAmmoBack(activator, 1 * talentStr, _, activator);
			}
			case 25: {
				GiveAmmoBack(activator, talentStr, _, activator);
			}
			case 26: {
				for (int i = 1; i <= MaxClients; i++) {
					if (i == activator || !IsLegitimateClientAlive(i) || myCurrentTeam[i] != myCurrentTeam[activator]) continue;
					GiveAmmoBack(i, talentStr, _, activator);
				}
			}
			case 27: {
				GiveAmmoBack(activator, _, g_TalentStrength, activator);
			}
			case 28: {
				for (int i = 1; i <= MaxClients; i++) {
					if (i == activator || !IsLegitimateClientAlive(i) || myCurrentTeam[i] != myCurrentTeam[activator]) continue;
					GiveAmmoBack(i, _, g_TalentStrength, activator);
				}
			}
			case 29: {
				//DealAOEDamage(target, g_TalentStrength, AoERange);
			}
			case 30: {
				ReflectDamage(activator, target, iDamage);
			}
			case 31: {
				SlowPlayer(target, g_TalentStrength, g_TalentTime);
			}
			case 32: {
				SlowPlayer(target, 1.0 + g_TalentStrength, g_TalentTime);
			}
			case 33: {
				L4D_StaggerPlayer(target, activator, activatorPos);
				EntityWasStaggered(target, activator);
			}
			case 34: {
				CreateAcid(activator, target, 512.0);
			}
			case 35: {
				HealPlayer(target, activator, iDamage * 1.0, 'T');
			}
			case 36: {
				ZeroGravity(activator, target, g_TalentStrength, g_TalentTime);
			}
			case 37: {
				ReviveDownedSurvivor(target, activator);
			}
			case 38: {
				if (!StrEqual(nameOfItemToGivePlayer, "-1")) {
					ExecCheatCommand(activator, "give", nameOfItemToGivePlayer);
				}
			}
		}
		if (activatorCallAbilityTrigger != -1) {
			GetAbilityStrengthByTrigger(activator, target, activatorCallAbilityTrigger, _, RoundToCeil(d_Damage * g_TalentStrength), _, _, _, _, _, _, hitgroup, _, damagetype);
		}
		if (activator != target && targetCallAbilityTrigger != -1) {
			GetAbilityStrengthByTrigger(target, activator, targetCallAbilityTrigger, _, RoundToCeil(d_Damage * g_TalentStrength), _, _, _, _, _, _, hitgroup, _, damagetype);
		}
	}
	return;
}