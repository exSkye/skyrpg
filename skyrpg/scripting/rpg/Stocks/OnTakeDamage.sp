/*
 *	SDKHooks function.
 *	We're using it to prevent any melee damage, due to the bizarre way that melee damage is handled, it's hit or miss whether it is changed.
 *	@return Plugin_Changed		if a melee weapon was used.
 *	@return Plugin_Continue		if a melee weapon was not used.
 */
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage_ignore, int &damagetype) {
	if (!b_IsActiveRound || b_IsSurvivalIntermission || damage_ignore <= 0.0) {

		damage_ignore = 0.0;
		return Plugin_Handled;
	}
	/*if (IsCommonInfected(victim) && !IsSpecialCommon(victim)) {
		damage_ignore = 9999.0;
		return Plugin_Changed;
	}*/
	int survivorIncomingDamage = 0;
	float ammoStr = 0.0;
	int baseWeaponDamage = 0;
	int loadtarget = -1;
	float TheAbilityMultiplier = 0.0;
	int cTank = -1;
	bool IsSurvivorBotVictim = IsLegitimateClient(victim) && IsFakeClient(victim) && myCurrentTeam[victim] == TEAM_SURVIVOR;
	bool IsSurvivorBotAttacker = IsLegitimateClient(attacker) && IsFakeClient(attacker) && myCurrentTeam[attacker] == TEAM_SURVIVOR;

 	int ReflectIncomingDamage = 0;
	int theCount = LivingSurvivorCount();
	/*
		Code for LEGITIMATE attackers goes here.
		This only handles survivors and special infected attackers; witches, commons, and super attackers are at the bottom of this method.
	*/
	bool IsLegitimateClientVictim = IsLegitimateClient(victim);
	bool IsFakeClientVictim;
	if (IsLegitimateClientVictim) {
		IsFakeClientVictim = IsFakeClient(victim);
		if (ImmuneToAllDamage[victim]) {
			damage_ignore = 0.0;
			return Plugin_Handled;
		}
	}
	bool IsLegitimateClientAttacker = IsLegitimateClient(attacker);
	//if (IsLegitimateClientAttacker && myCurrentTeam[attacker] == TEAM_SURVIVOR) PrintToChatAll("%N attacked!", attacker);
	bool IsFakeClientAttacker;
	int victimType = -1;
	if (IsLegitimateClientAttacker) {
		IsFakeClientAttacker = IsFakeClient(attacker);
		myCurrentTeam[attacker] = GetClientTeam(attacker);
		if (myCurrentTeam[attacker] == TEAM_INFECTED && IsLegitimateClientVictim && myCurrentTeam[attacker] == myCurrentTeam[victim]) {
			damage_ignore = 0.0;
			return Plugin_Handled;
		}
		if (myCurrentTeam[attacker] == TEAM_SURVIVOR || !IsFakeClientAttacker) {
			if (b_IsLoading[attacker]) {	// infected bots shouldn't hold up here anymore.
				damage_ignore = 0.0;
				return Plugin_Handled;
			}
			else if (!IsFakeClientAttacker && PlayerLevel[attacker] < iPlayerStartingLevel) {
				loadtarget = attacker;
				ForceLoadDefaultProfiles(loadtarget);
			}
			else if ((IsFakeClientAttacker || IsSurvivorBotAttacker) && PlayerLevel[attacker] < iBotPlayerStartingLevel) {
				PlayerLevel[attacker] = iBotPlayerStartingLevel;
				ForceLoadDefaultProfiles(attacker);
				damage_ignore = 0.0;
				return Plugin_Handled;
			}
		}
		b_IsDead[attacker] = false;
		if (!HasSeenCombat[attacker]) HasSeenCombat[attacker] = true;
		bool isExplosionDamage = ((damagetype & DMG_BLAST) || (damagetype & DMG_BLAST_SURFACE));
		if (myCurrentTeam[attacker] == TEAM_SURVIVOR) {
			if (inflictor > MaxClients && (isExplosionDamage || (damagetype & DMG_NERVEGAS))) {
				char classname[64];
				GetEdictClassname(inflictor, classname, sizeof(classname));
				if (!StrEqualAtPos(classname, "pipe_bomb", 7)) baseWeaponDamage = iExplosionBaseDamage;
				else {
					baseWeaponDamage = iExplosionBaseDamagePipe;
				}
				baseWeaponDamage += RoundToCeil(GetAbilityStrengthByTrigger(attacker, victim, TRIGGER_S, _, baseWeaponDamage, _, _, RESULT_d, 1, true, _, _, _, damagetype));
				GetAbilityStrengthByTrigger(attacker, victim, TRIGGER_explosion, _, baseWeaponDamage, _, _, _, _, _, _, _, _, damagetype, _, _, takeDamageEvent[attacker][1]);
			}
			else baseWeaponDamage = GetBaseWeaponDamage(attacker, victim, _, _, _, damagetype, _, _, takeDamageEvent[attacker][1]);

			if (bAutoRevive[attacker] && !IsIncapacitated(attacker)) bAutoRevive[attacker] = false;
			victimType = (IsSpecialCommon(victim)) ? 0 :
						(IsCommonInfected(victim)) ? 1 :
						(IsWitch(victim)) ? 2 :
						(IsLegitimateClientVictim && myCurrentTeam[victim] == TEAM_INFECTED) ? 3 : 4;

			bool defenderInRange = (IsSpecialCommonInRange(victim, 't') || DrawSpecialInfectedAffixes(victim, victim) == 1) ? true : false;
			if (defenderInRange) {
				damage_ignore = 0.0;
				return Plugin_Handled;
			}
			CallTriggerByHitgroup(attacker, victim, takeDamageEvent[attacker][1], takeDamageEvent[attacker][0], baseWeaponDamage);
			int survivorResult = IfSurvivorIsAttackerDoStuff(attacker, victim, baseWeaponDamage, damagetype, victimType, takeDamageEvent[attacker][0], takeDamageEvent[attacker][1], inflictor);
			LastAttackTime[attacker] = GetEngineTime();
			if (survivorResult == -1) {
				damage_ignore = 0.0;
				return Plugin_Handled;
			}
			ReadyUp_NtvStatistics(attacker, 0, baseWeaponDamage);
			ReadyUp_NtvStatistics(victim, 8, baseWeaponDamage);
			if (survivorResult == -2) {
				damage_ignore = (baseWeaponDamage * 1.0);
				CheckTeammateDamagesEx(attacker, victim, baseWeaponDamage, takeDamageEvent[attacker][1], true);
				return Plugin_Changed;
			}
		}
		else if (myCurrentTeam[attacker] == TEAM_INFECTED && FindZombieClass(attacker) == ZOMBIECLASS_TANK) cTank = attacker;
	}
	// else if (IsLegitimateClientVictim && myCurrentTeam[victim] == TEAM_INFECTED) {
	// 	// common infected or witch attacker.
	// 	int infectedAttackerType =	(IsSpecialCommon(attacker)) ? 0 :
	// 								(IsCommonInfected(attacker)) ? 1 :
	// 								(IsWitch(attacker)) ? 2 : -1;
	// 	if (infectedAttackerType >= 0) {
	// 		int bileAttacker = PlayerWhoBiledMe[victim];
	// 		// if (IsLegitimateClient(bileAttacker) && myCurrentTeam[bileAttacker] == TEAM_SURVIVOR) {
	// 		// 	if (infectedAttackerType == 2) {
	// 		// 		char sRef[64];
	// 		// 		int i_WitchDamage = GetCharacterSheetData(bileAttacker, sRef, 64, 4, _, attacker);
	// 		// 		int i_WitchDamageIncreaseFromBuffer = getDamageIncreaseFromBuffer(attacker, i_WitchDamage);
	// 		// 		if (i_WitchDamageIncreaseFromBuffer > 0) i_WitchDamage += i_WitchDamageIncreaseFromBuffer;

	// 		// 		GetAbilityStrengthByTrigger(victim, bileAttacker, TRIGGER_L, _, i_WitchDamage);
	// 		// 		if (i_WitchDamage > maxIncomingDamageAllowed) i_WitchDamage = maxIncomingDamageAllowed;
	// 		// 		SetClientTotalHealth(attacker, victim, i_WitchDamage);
	// 		// 		//ReceiveWitchDamage(victim, attacker, i_WitchDamage);
					
	// 		// 		float fdpa = (fWitchDirectorPoints * i_WitchDamage);
	// 		// 		if (!IsSurvivalMode && iEnrageTime > 0 && RPGRoundTime() >= iEnrageTime) fdpa *= fEnrageDirectorPoints;
	// 		// 		if (fdpa > 0.0) Points_Director += fdpa;
	// 		// 		// Reflect damage.
	// 		// 		int bileReflect = 0;
	// 		// 		float survivorAmmoStr = IsClientInRangeSpecialAmmo(victim, "R", _, _, i_WitchDamage);
	// 		// 		if (survivorAmmoStr > 0.0) bileReflect = RoundToCeil(i_WitchDamage * survivorAmmoStr);
	// 		// 		if (bileReflect > 0) {
	// 		// 			AddWitchDamage(victim, attacker, bileReflect);
	// 		// 		}
	// 		// 	}
	// 		// 	else {
	// 		// 		survivorIncomingDamage = IfCommonInfectedIsAttackerDoStuff(attacker, victim, damagetype, theCount);
	// 		// 		if (survivorIncomingDamage == -1) {
	// 		// 			damage_ignore = 0.0;
	// 		// 			return Plugin_Handled;
	// 		// 		}
	// 		// 	}
	// 		// }
	// 	}
	// }
	if (IsLegitimateClientVictim) {
		if (b_IsLoading[victim]) {
			damage_ignore = 0.0;
			return Plugin_Handled;
		}
		else if (!IsFakeClientVictim && PlayerLevel[victim] < iPlayerStartingLevel || (IsFakeClientVictim || IsSurvivorBotVictim) && PlayerLevel[victim] < iBotPlayerStartingLevel) {
			loadtarget = victim;
			ForceLoadDefaultProfiles(loadtarget);
		}
		b_IsDead[victim] = false;
		if (RespawnImmunity[victim]) {
			damage_ignore = 0.0;
			return Plugin_Handled;
		}
		if (!HasSeenCombat[victim]) HasSeenCombat[victim] = true;
		if ((damagetype & DMG_CRUSH)) {
			// conscious decision to block bots from crush damage - they aren't programmed to understand it.
			if (bIsCrushCooldown[victim] || myCurrentTeam[victim] == TEAM_SURVIVOR && IsFakeClientVictim) {
				damage_ignore = 0.0;
				return Plugin_Handled;
			}
			else {
				bIsCrushCooldown[victim] = true;
				CreateTimer(1.0, Timer_ResetCrushImmunity, victim, TIMER_FLAG_NO_MAPCHANGE);

				char crushedName[64];
				GetClientName(victim, crushedName, sizeof(crushedName));

				int crushDamage = RoundToCeil(damage_ignore);
				TheAbilityMultiplier = GetAbilityMultiplier(victim, "F");
				if (TheAbilityMultiplier > 0.0) crushDamage -= RoundToCeil(crushDamage * TheAbilityMultiplier);
				SetClientTotalHealth(attacker, victim, crushDamage);
				damage_ignore = 0.0;
				return Plugin_Handled;
			}
		}
		if (myCurrentTeam[victim] == TEAM_SURVIVOR) {
			int maxIncomingDamageAllowed = GetMaximumHealth(victim);
			/*	==============================================================================================
				A quick check to see if survivor bots are immune to fire damage, since bots are dumb
				==============================================================================================*/
			if (IsSurvivorBotVictim && iSurvivorBotsAreImmuneToFireDamage == 1 && (damagetype & DMG_BURN)) {
				damage_ignore = 0.0;
				return Plugin_Handled;
			}
			/*	==============================================================================================
				We need to calculate the attackers damage before we calculate the victims damage taken.
				==============================================================================================*/
			bool isCommonInfectedAttacker = IsCommonInfected(attacker);
			int attackerType = (isCommonInfectedAttacker) ? 1 :
							   (IsWitch(attacker)) ? 2 :
							   (IsLegitimateClientAttacker && myCurrentTeam[attacker] == TEAM_INFECTED) ? 3 :
							   (IsLegitimateClientAttacker && myCurrentTeam[attacker] == TEAM_SURVIVOR) ? 4 : 5;
			if (attackerType <= 3) {
				// If a common infected or a non-teammate hits someone, lets shake their screen a little bit.
				ScreenShake(victim, "1.2", "0.13", "0.5", false);
				CombatTime[victim] = GetEngineTime();
				JetpackRecoveryTime[victim] = CombatTime[victim] + 1.0;
				CombatTime[victim] += fOutOfCombatTime;
				ToggleJetpack(victim, true);
				if (attackerType == 3) {
					survivorIncomingDamage = IfInfectedIsAttackerDoStuff(attacker, victim);
					ReadyUp_NtvStatistics(attacker, 1, survivorIncomingDamage);
					ReadyUp_NtvStatistics(victim, 8, survivorIncomingDamage);
					if (survivorIncomingDamage == -1) {
						damage_ignore = 0.0;
						return Plugin_Handled;
					}
				}
				else if (attackerType == 2) {
					char stringRef[64];
					int i_WitchDamage = GetCharacterSheetData(victim, stringRef, 64, 4, _, attacker);
					int i_WitchDamageIncreaseFromBuffer = getDamageIncreaseFromBuffer(attacker, i_WitchDamage);
					if (i_WitchDamageIncreaseFromBuffer > 0) i_WitchDamage += i_WitchDamageIncreaseFromBuffer;

					GetAbilityStrengthByTrigger(victim, attacker, TRIGGER_L, _, i_WitchDamage);
					if (i_WitchDamage > maxIncomingDamageAllowed) i_WitchDamage = maxIncomingDamageAllowed;
					SetClientTotalHealth(attacker, victim, i_WitchDamage);
					ReceiveWitchDamage(victim, attacker, i_WitchDamage);
					float fDirectorPointAward = (fWitchDirectorPoints * i_WitchDamage);
					if (!IsSurvivalMode && iEnrageTime > 0 && RPGRoundTime() >= iEnrageTime) fDirectorPointAward *= fEnrageDirectorPoints;
					if (fDirectorPointAward > 0.0) Points_Director += fDirectorPointAward;
					// Reflect damage.
					ammoStr = IsClientInRangeSpecialAmmo(victim, "R", _, _, i_WitchDamage);
					if (ammoStr > 0.0) ReflectIncomingDamage = RoundToCeil(i_WitchDamage * ammoStr);
					if (ReflectIncomingDamage > 0) AddWitchDamage(victim, attacker, ReflectIncomingDamage);
					survivorIncomingDamage = i_WitchDamage;
				}
				else if (isCommonInfectedAttacker) {
					survivorIncomingDamage = IfCommonInfectedIsAttackerDoStuff(attacker, victim, damagetype, theCount);
					if (survivorIncomingDamage == -1) {
						damage_ignore = 0.0;
						return Plugin_Handled;
					}
				}
			}
			/*	============================================================
				We can now calculate the damage the victim will take.
				============================================================*/
			if (!IsSurvivorBotVictim || iCanSurvivorBotsBurn == 1) {
				int effectToCreate = -1;
				int effectType = -1;
				if (IsFireDamage(damagetype)) {
					effectToCreate = STATUS_EFFECT_BURN;
					survivorIncomingDamage = iFireBaseDamage;
					effectType = 0;
				}
				else if ((damagetype & DMG_SPITTERACID1 || damagetype & DMG_SPITTERACID2)) {
					effectToCreate = STATUS_EFFECT_ACID;
					survivorIncomingDamage = 1;
					effectType = 1;
				}

				if (effectType >= 0) {
					int iBurnCounter = GetClientStatusEffect(victim, effectToCreate);
					float currentEngineTime = GetEngineTime();
					if (iBurnCounter < iDebuffLimit && fOnFireDebuff[victim] < currentEngineTime) {
						fOnFireDebuff[victim] = currentEngineTime + fOnFireDebuffDelay;
						if (iRPGMode >= 1) {
							float fAcidDamage = (attackerType == 1) ? fAcidDamageSupersPlayerLevel : fAcidDamagePlayerLevel;
							if (iBotLevelType == 1) {
								if (effectType == 1) survivorIncomingDamage += RoundToFloor(survivorIncomingDamage * (SurvivorLevels() * fAcidDamage));
								else survivorIncomingDamage += RoundToFloor(survivorIncomingDamage * (SurvivorLevels() * fBurnPercentage));
							}
							else {
								if (effectType == 1) survivorIncomingDamage += RoundToFloor(survivorIncomingDamage * (GetDifficultyRating(victim) * fAcidDamage));
								else survivorIncomingDamage += RoundToFloor(survivorIncomingDamage * (GetDifficultyRating(victim) * fBurnPercentage));
							}
						}
						//PrintToChatAll("DoT Damage: %d %d", survivorIncomingDamage, survivorIncomingDamage * (iBurnCounter + 1));
						CreateAndAttachFlame(victim, survivorIncomingDamage, fDoTMaxTime, fDoTInterval, FindInfectedClient(true), effectToCreate);
					}
					damage_ignore = 0.0;
					return Plugin_Handled;
				}
			}
			if (IsLegitimateClientAttacker && myCurrentTeam[attacker] == TEAM_SURVIVOR) {
				if (SameTeam_OnTakeDamage(attacker, victim, baseWeaponDamage, _, damagetype, takeDamageEvent[attacker][1])) {
					damage_ignore = 0.0;
					return Plugin_Handled;
				}
			}
			if (damagetype & DMG_FALL) {
				int DMGFallDamage = RoundToCeil(damage_ignore);
				int MyInfectedAttacker = L4D2_GetInfectedAttacker(victim);
				if (MyInfectedAttacker != -1) DMGFallDamage = RoundToCeil(DMGFallDamage * 0.4);
				TheAbilityMultiplier = GetAbilityMultiplier(victim, "F");
				if (TheAbilityMultiplier > 0.0) DMGFallDamage -= RoundToCeil(DMGFallDamage * TheAbilityMultiplier);
				if (DMGFallDamage < 100) {
					DMGFallDamage = RoundToCeil((damage_ignore * 0.01) * GetMaximumHealth(victim));
					SetClientTotalHealth(_, victim, DMGFallDamage);
				}
				else if (DMGFallDamage >= 100 && DMGFallDamage < 200) SetClientTotalHealth(_, victim, GetClientTotalHealth(victim));
				else IncapacitateOrKill(victim, _, _, true);
				damage_ignore = 0.0;
				return Plugin_Handled;
			}
			if (damagetype & DMG_DROWN) {
				if (!IsIncapacitated(victim)) SetClientTotalHealth(_, victim, GetClientTotalHealth(victim));
				else IncapacitateOrKill(victim, _, _, true);
				damage_ignore = 0.0;
				return Plugin_Handled;
			}
		}
		else {	// special infected victim.
			if (FindZombieClass(victim) == ZOMBIECLASS_TANK) cTank = victim;

		}
	}
	if (cTank > 0) {
		if (!bIsDefenderTank[cTank] && IsSpecialCommonInRange(cTank, 't')) {
			// tank copies nearby defender abilities, permanently.
			bIsDefenderTank[cTank] = true;
			SetEntityRenderMode(cTank, RENDER_TRANSCOLOR);
			SetEntityRenderColor(cTank, 0, 0, 255, 200);
		}
	}
	
 	//new StaminaCost = 0;
 	//new baseWeaponTemp = 0;
	// IgnoreTeam = 1 when the attacker is survivor.
	// IgnoreTeam = 2 when the attacker is infected.
	// IgnoreTeam = 3 when the victim is infected.
	// IgnoreTeam = 4 when the victim is common/witch
	// IgnoreTeam = 5 when the attacker is common/witch
	//damage_ignore = 0.0;
	//return Plugin_Handled;

	damage_ignore = baseWeaponDamage * 1.0;
	/*if (victimType == 3 && victimTeam == TEAM_INFECTED ||
		victimType == 1 && FindListPositionByEntity(victim, Handle:CommonInfected) >= 0 ||
		victimType == 2 && FindListPositionByEntity(victim, Handle:WitchList) >= 0) {*/
	if (victimType <= 2) {
		if (victimType == 1 && IsFireDamage(damagetype)) {
			// infected commons auto-die if they touch fire.
			CalculateInfectedDamageAward(victim);
			RemoveCommonInfected(victim, true);
		}
		if (victimType == 2) {
			int pos		= FindListPositionByEntity(victim, WitchList);
			if (pos >= 0) {
				if (GetArrayCell(WitchList, pos, 1) == WITCH_NOT_ACTIVATED) {
					SetArrayCell(WitchList, pos, WITCH_ATTACKING, 1);
					SetEntProp(victim, Prop_Send, "m_mobRush", 1);
					damage_ignore = 1.0;
					return Plugin_Changed;
				}
			}
		}
		return Plugin_Handled;
	}
	if (victimType == 3) {
		//if (victimType != 1 || IsSpecialCommon(victim) || !IsCommonInfectedDead(victim)) SetInfectedHealth(victim, 50000);	// we don't want NPC zombies to die prematurely.
		return Plugin_Changed;
	}
	if (IsLegitimateClientVictim && myCurrentTeam[victim] == TEAM_SURVIVOR) {
		damage_ignore = survivorIncomingDamage * 1.0;
		return Plugin_Changed;
	}
	return Plugin_Changed;
}