public Action OnPlayerRunCmd(client, &buttons) {
	int clientFlags = GetEntityFlags(client);
	bool clientIsSurvivor = (myCurrentTeam[client] == TEAM_SURVIVOR) ? true : false;
	bool IsClientIncapacitated = IsIncapacitated(client);
	bool IsClientAlive = IsLegitimateClientAlive(client);
	bool IsBiledOn = ISBILED[client];
	float TheTime = GetEngineTime();
	int MyAttacker = L4D2_GetInfectedAttacker(client);
	bool isHoldingShift = (buttons & IN_SPEED) ? true : false;
	clientIsWalking[client] = isHoldingShift;
	bool isMoving = (buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT)) ? true : false;
	if (iExperimentalMode == 1 && clientIsSurvivor && !IsFakeClient(client)) {
		if (isHoldingShift && !bIsSurvivorFatigue[client]) {
			buttons &= ~IN_SPEED;
			clientIsWalking[client] = false;
		}
		else if (isMoving) {
			buttons |= IN_SPEED;
			clientIsWalking[client] = true;
		}
	}

	bool IsHoldingPrimaryFire = (buttons & IN_ATTACK) ? true : false;
	bool isClientOnSolidGround = (clientFlags & FL_ONGROUND) ? true : false;
	bool isClientOnFire = (clientFlags & FL_ONFIRE) ? true : false;
	bool isClientInWater = (clientFlags & FL_INWATER) ? true : false;
	int weaponEntity = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	bool weaponIsValid = (weaponEntity > 0 && IsValidEntity(weaponEntity));
	// call the stagger ability triggers only when a fresh stagger occurs (and not if multiple staggers happen too-often within each other (2.0 seconds is slightly-longer than one stagger.))
	if (!staggerCooldownOnTriggers[client] && SDKCall(g_hIsStaggering, client)) {
		staggerCooldownOnTriggers[client] = true;
		CreateTimer(2.0, Timer_ResetStaggerCooldownOnTriggers, client, TIMER_FLAG_NO_MAPCHANGE);
		EntityWasStaggered(client);
	}
	if (clientIsSurvivor) {
		if (isClientOnFire && (isClientInWater || IsBiledOn)) {
			RemoveAllDebuffs(client, STATUS_EFFECT_BURN);
			ExtinguishEntity(client);
		}
		if (isClientInWater) {
			RemoveAllDebuffs(client, STATUS_EFFECT_ACID);
		}
		if (shadowKnightTimeCheck[client] < TheTime) {
			shadowKnightTimeCheck[client] = TheTime + 1.0;
			if (iCurrentIncapCount[client] < iMaxIncap && IsSpecialCommonInRange(client, 'w') && IsClientInRangeSpecialAmmo(client, "W")) {
				iCurrentIncapCount[client] = iMaxIncap;
			}
		}
	}
	if ((buttons & IN_ZOOM) && ZoomcheckDelayer[client] == INVALID_HANDLE) ZoomcheckDelayer[client] = CreateTimer(0.1, Timer_ZoomcheckDelayer, client, TIMER_FLAG_NO_MAPCHANGE);
	if (IsHoldingPrimaryFire && medItem[client] == 0) {
		if (!clientIsSurvivor && FindZombieClass(client) == ZOMBIECLASS_SMOKER) {
			int victim = L4D2_GetSurvivorVictim(client);
			if (victim != -1) GetAbilityStrengthByTrigger(client, victim, TRIGGER_v, _, 0);
		}
		int bulletsRemaining = 0;
		if (weaponIsValid) {
			bulletsRemaining = GetEntProp(weaponEntity, Prop_Send, "m_iClip1");
			if (bulletsRemaining == LastBulletCheck[client]) bulletsRemaining = 0;
			else LastBulletCheck[client] = bulletsRemaining;
		}
		if (bulletsRemaining > 0 && GetEntProp(weaponEntity, Prop_Data, "m_bInReload") != 1 && MyAttacker == -1) {
			holdingFireCheckToggle(client, true);
		}
	}
	else holdingFireCheckToggle(client);
	bool isHoldingUseKey = (buttons & IN_USE) ? true : false;
	if (isHoldingUseKey) {
		if (lootPickupCooldownTime[client] < TheTime) {
			lootPickupCooldownTime[client] = TheTime + fBagPickupDelay;
			IsPlayerTryingToPickupLoot(client);
		}
		if (b_IsRoundIsOver && (ReadyUpGameMode == 3 || StrContains(TheCurrentMap, "zerowarn", false) != -1)) {
			int entity = GetClientAimTarget(client, false);
			if (entity != -1) {
				char EName[64];
				GetEntityClassname(entity, EName, sizeof(EName));
				if (StrContains(EName, "weapon", false) != -1 || StrContains(EName, "physics", false) != -1) return Plugin_Continue;
				buttons &= ~IN_USE;
				return Plugin_Changed;
			}
		}
	}
	if (IsClientAlive && b_IsActiveRound) {
		if (myCurrentTeam[client] == TEAM_INFECTED && FindZombieClass(client) == ZOMBIECLASS_TANK) {
			if (!IsAirborne[client] && !isClientOnSolidGround) IsAirborne[client] = true;	// when the tank lands, aoe explosion!
			else if (IsAirborne[client] && isClientOnSolidGround) {
				IsAirborne[client] = false;	// the tank has landed; explosion;
				CreateExplosion(client, _, client, true);
			}
			int myLifetime = GetTime() - MyBirthday[client];
			if (MyBirthday[client] > 0) {
				int numSurvivorsNear = NearbySurvivors(client, 2056.0);
				//if there are no nearby survivors (tank spawned ahead or people are rushing)
				if (numSurvivorsNear < 1) {
					// if we've been around for a while, kill the tank
					if (myLifetime > 120) DeleteMeFromExistence(client);
					else SetSpeedMultiplierBase(client, 2.0);	// otherwise make him super fast so he can catch the survivors.
				}	// but if survivors are nearby, reset the tanks speed based on his current mutation.
				else CheckTankSubroutine(client);
			}
		}

		/*if (clientTeam == TEAM_SURVIVOR) {

			//CheckIfItemPickup(client);
			//CheckBombs(client);
			if (IsFakeClient(client) && !bIsInCheckpoint[client]) {

				if (SurvivorsSaferoomWaiting()) SurvivorBotsRegroup(client);
			}
		}*/
		bool isClientHoldingJetpackKeys = ((buttons & IN_JUMP) && (buttons & IN_DUCK)) ? true : false;
		if (!IsLegitimateClientAlive(MyAttacker)) StrugglePower[client] = 0;

		if (CombatTime[client] <= TheTime && bIsInCombat[client] && (iPlayersLeaveCombatDuringFinales == 1 || !b_IsFinaleActive)) {

			bIsInCombat[client] = false;
			iThreatLevel[client] = 0;
			ResetContributionTracker(client);
			if (!IsSurvivalMode) AwardExperience(client);
		}
		else if (CombatTime[client] > TheTime || b_IsFinaleActive && iPlayersLeaveCombatDuringFinales == 0) {
			bIsInCombat[client] = true;
		}
		//if (GetClientTeam(client) == TEAM_INFECTED) SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		// if (clientTeam == TEAM_SURVIVOR) {
		// 	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", MovementSpeed[client]);
		// }
		if (freezerCheck[client] < TheTime && freezerTime[client] < TheTime) {
			freezerCheck[client] = TheTime + 1.0;
			if (IsSpecialCommonInRange(client, 'r')) {
				freezerTime[client] = TheTime + 1.0;
				FreezerInRange[client] = true;
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 0.5);
			}
			else {
				FreezerInRange[client] = false;
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
			}
		}
		if (clientIsSurvivor) {
			bool theClientHasAnActiveProgressBar = ActiveProgressBar(client);
			bool theClientHasPainPills = (medItem[client] != 1) ? false : true;
			bool theClientHasAdrenaline = (medItem[client] != 2) ? false : true;
			bool theClientHasFirstAid = (medItem[client] != 3) ? false : true;
			//new CurrentEntity			=	GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

			//Format(EntityName, sizeof(EntityName), "}");
			int PlayerMaxStamina = GetPlayerStamina(client);

			if (MyAttacker == -1 && (IsClientIncapacitated || medItem[client] > 0)) {

				//blocks the use of meds on people. will add an option in the menu later for now allowing.
				/*if ((buttons & IN_ATTACK2) && !IsIncapacitated(client)) {

					if (StrContains(EntityName, "first_aid", false) != -1) {

						buttons &= ~IN_ATTACK2;
						return Plugin_Changed;
					}
				}*/
				int reviveOwner = -1;
				if (theClientHasAnActiveProgressBar && (!IsClientAlive || !isClientOnSolidGround || !IsHoldingPrimaryFire && !IsClientIncapacitated || !isHoldingUseKey && IsClientIncapacitated)) {

					CreateProgressBar(client, 0.0, true);
					UseItemTime[client] = 0.0;
					theClientHasAnActiveProgressBar = false;
					reviveOwner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
					if (reviveOwner == client) {

						SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
						SetEntPropEnt(client, Prop_Send, "m_reviveTarget", -1);
					}
					/*
					if (IsLegitimateClientAlive(reviveOwner) && GetClientTeam(reviveOwner) == TEAM_SURVIVOR) {

						SetEntPropEnt(reviveOwner, Prop_Send, "m_reviveTarget", -1);
						SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
					}*/
				}
				bool playerOnLedge = IsLedged(client);
				if (IsClientAlive && (medItem[client] > 0 && IsHoldingPrimaryFire && !IsClientIncapacitated || isHoldingUseKey && IsClientIncapacitated && !playerOnLedge)) {
					if (!IsClientIncapacitated) buttons &= ~IN_ATTACK;
					else buttons &= ~IN_USE;
					if (UseItemTime[client] < TheTime) {
						if (theClientHasAnActiveProgressBar) {
							UseItemTime[client] = 0.0;
							CreateProgressBar(client, 0.0, true);
							if (!IsClientIncapacitated) {
								int healTarget = GetClientAimTarget(client);
								if (!IsLegitimateClientAlive(healTarget) || myCurrentTeam[healTarget] != myCurrentTeam[client] || !ClientsWithinRange(client, healTarget, 96.0)) healTarget = client;
								if (theClientHasPainPills) {
									float fPainPillsHeal = GetTempHealth(healTarget) + (GetMaximumHealth(healTarget) * fPainPillsHealAmount);
									HealPlayer(client, healTarget, fPainPillsHeal, 'h', true);//SetTempHealth(client, client, GetTempHealth(client) + (GetMaximumHealth(client) * 0.3), false);		// pills add 10% of your total health in temporary health.
									medItem[client] = 0;
									if (IsValidEntity(weaponEntity)) AcceptEntityInput(weaponEntity, "Kill");
									GetAbilityStrengthByTrigger(client, healTarget, TRIGGER_usepainpills, _, RoundToCeil(fPainPillsHeal));
									GetAbilityStrengthByTrigger(client, healTarget, TRIGGER_healsuccess, _, RoundToCeil(fPainPillsHeal));
								}
								else if (theClientHasAdrenaline) {
									SetAdrenalineState(client);
									int StaminaBonus = RoundToCeil(PlayerMaxStamina * 0.25);
									if (SurvivorStamina[client] + StaminaBonus >= PlayerMaxStamina) {
										SurvivorStamina[client] = PlayerMaxStamina;
										bIsSurvivorFatigue[client] = false;
									}
									else SurvivorStamina[client] += StaminaBonus;
									medItem[client] = 0;
									if (IsValidEntity(weaponEntity)) AcceptEntityInput(weaponEntity, "Kill");
								}
								else if (theClientHasFirstAid) {
									int iFirstAidHealAmount = GetMaximumHealth(healTarget) - GetClientHealth(healTarget);
									GiveMaximumHealth(healTarget);
									RefreshSurvivor(healTarget);
									medItem[client] = 0;
									if (IsValidEntity(weaponEntity)) AcceptEntityInput(weaponEntity, "Kill");
									GetAbilityStrengthByTrigger(client, healTarget, TRIGGER_usefirstaid, _, iFirstAidHealAmount);
									GetAbilityStrengthByTrigger(client, healTarget, TRIGGER_healsuccess, _, iFirstAidHealAmount);
								}
							}
							else {
								ReviveDownedSurvivor(client);
								OnPlayerRevived(client, client);
							}
						}
						else {	// create a progress bar
							if (IsClientIncapacitated && UseItemTime[client] < TheTime) {
								reviveOwner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
								if (!IsLegitimateClientAlive(reviveOwner)) {
									SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
									ProgressEntity[client]			=	weaponEntity;
									CreateProgressBar(client, 5.0);	// you can pick yourself up for free but it takes a bit.
								}
							}
							if (!IsClientIncapacitated && medItem[client] > 0 && UseItemTime[client] < TheTime) {
								float fProgressBarCompletionTime = -1.0;
								if (theClientHasPainPills) fProgressBarCompletionTime = 2.0;
								else if (theClientHasAdrenaline) fProgressBarCompletionTime = 1.0;
								else if (theClientHasFirstAid) fProgressBarCompletionTime = 5.0;
								if (fProgressBarCompletionTime != -1.0) {
									ProgressEntity[client]			=	weaponEntity;
									CreateProgressBar(client, fProgressBarCompletionTime);
								}
							}
						}
					}
					return Plugin_Changed;
				}
			}
			// For drawing special ammo.
			if (bIsSurvivorFatigue[client]) {
				IsSpecialAmmoEnabled[client][0] = 0.0;
				Format(ActiveSpecialAmmo[client], sizeof(ActiveSpecialAmmo[]), "none");
			}
			if ((ReadyUp_GetGameMode() != 3 || !b_IsSurvivalIntermission) && iRPGMode >= 1) {
				bool IsJetpackBroken = (isClientOnFire || IsBiledOn);
				if (!IsJetpackBroken) IsJetpackBroken = AnyTanksNearby(client);
				/*
					Add or remove conditions from the following line to determine when the jetpack automatically disables.
					When adding new conditions, consider a switch so server operators can choose which of them they want to use.
				*/
				if (bJetpack[client] && (iCanJetpackWhenInCombat == 1 || !bIsInCombat[client]) && (!isClientHoldingJetpackKeys || IsJetpackBroken || MyAttacker != -1)) {
					ToggleJetpack(client, true);
				}
				bool isSprinting = (iExperimentalMode == 1 && isHoldingShift && isMoving) ? true : false;
				if ((bJetpack[client] || !bJetpack[client] && !isClientOnSolidGround) ||
					isClientHoldingJetpackKeys && SurvivorStamina[client] >= ConsumptionInt && !bIsSurvivorFatigue[client] ||
					isSprinting) {
					if (MyAttacker == -1) {
						if (SurvivorConsumptionTime[client] <= TheTime && (isClientHoldingJetpackKeys || isSprinting)) {
							if (SurvivorStamina[client] <= 0) {
								bIsSurvivorFatigue[client] = true;
								IsSpecialAmmoEnabled[client][0] = 0.0;
								SurvivorStamina[client] = 0;
								if (bJetpack[client]) ToggleJetpack(client, true);
							}
							else if (IsJetpackBroken && bJetpack[client]) ToggleJetpack(client, true);
							else if (bJetpack[client]) {
								float nextSprintInterval = GetAbilityStrengthByTrigger(client, client, TRIGGER_jetpack, _, 0, _, _, RESULT_flightcost, _, _, 2);
								if (nextSprintInterval > 0.0) SurvivorConsumptionTime[client] = TheTime + fStamJetpackInterval + (fStamJetpackInterval * nextSprintInterval);
								else SurvivorConsumptionTime[client] = TheTime + fStamJetpackInterval;
							}
							else SurvivorConsumptionTime[client] = TheTime + fStamSprintInterval;
							if (!bIsSurvivorFatigue[client]) SurvivorStamina[client] -= ConsumptionInt;
						}
						if (!bIsSurvivorFatigue[client] && !bJetpack[client] && isClientHoldingJetpackKeys && (iCanJetpackWhenInCombat == 1 || !bIsInCombat[client]) && !IsJetpackBroken && JetpackRecoveryTime[client] <= TheTime && MyAttacker == -1) ToggleJetpack(client);
						if (!bJetpack[client]) MovementSpeed[client] = fSprintSpeed;
					}
					buttons &= ~IN_SPEED;
					return Plugin_Changed;
				}
				if (!bJetpack[client]) {
					if (SurvivorStaminaTime[client] < TheTime && SurvivorStamina[client] < PlayerMaxStamina) {
						if (!HasAdrenaline(client)) SurvivorStaminaTime[client] = TheTime + fStamRegenTime;
						else SurvivorStaminaTime[client] = TheTime + fStamRegenTimeAdren;
						SurvivorStamina[client]++;
					}
					// if (!bIsSurvivorFatigue[client]) MovementSpeed[client] = fBaseMovementSpeed;
					// else MovementSpeed[client] = fFatigueMovementSpeed;
					if (ISSLOW[client]) MovementSpeed[client] *= fSlowSpeed[client];
					if (SurvivorStamina[client] >= PlayerMaxStamina) {
						bIsSurvivorFatigue[client] = false;
						SurvivorStamina[client] = PlayerMaxStamina;
					}
				}
			}
		}
	}
	return Plugin_Changed;
}