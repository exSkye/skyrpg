stock DisplayHUD(client, statusType) {

	if (iRPGMode >= 1) {
		GetStatusEffects(client, 0, negativeStatusEffects[client], sizeof(negativeStatusEffects[]));
		GetStatusEffects(client, 1, positiveStatusEffects[client], sizeof(positiveStatusEffects[]));

		if (IsLegitimateClientAlive(client) && myCurrentTeam[client] == TEAM_INFECTED && !IsFakeClient(client)) {

			int healthremaining = GetHumanInfectedHealth(client);
			if (healthremaining > 0) SetEntityHealth(client, GetHumanInfectedHealth(client));
		}

		char text[64];

		char targetHealthText[16];
		char targetMaxHealthText[16];
		bool legitimateTargetFound = false;
		if (bJetpack[client]) {
			Format(text, sizeof(text), "Stamina: %d\n%s\n%s", SurvivorStamina[client], positiveStatusEffects[client], negativeStatusEffects[client]);
		}
		else if (iShowDetailedDisplayAlways == 1) {
			int enemytype = -1;
			float TargetPos[3];
			char hitgroup[4];
			int enemycombatant = GetAimTargetPosition(client, TargetPos, hitgroup, 4);

			if (IsSpecialCommon(enemycombatant)) enemytype = CLIENT_SUPER_COMMON;
			else if (IsCommonInfected(enemycombatant)) enemytype = CLIENT_COMMON;
			else if (IsWitch(enemycombatant)) enemytype = CLIENT_WITCH;
			else if (IsLegitimateClientAlive(enemycombatant)) {
				if (myCurrentTeam[enemycombatant] == TEAM_INFECTED) enemytype = CLIENT_SPECIAL_INFECTED;
				else enemytype = 4; // no entry for survivor yet, will add.
			}

			if (enemytype >= 0) {
				int enemyHealth = GetTargetHealth(client, enemycombatant);
				if (enemyHealth > 0) {
					legitimateTargetFound = true;
					char EnemyName[64];

					if (enemytype == CLIENT_COMMON) Format(EnemyName, sizeof(EnemyName), "Common");
					else if (enemytype == CLIENT_SUPER_COMMON) {
						int superPos = FindListPositionByEntity(enemycombatant, CommonAffixes);
						// cell 1 stores the position in the common affixes array this type of super common is
						// so there is no looping through doing str checks on the super name vs the names in the list.
						superPos = GetArrayCell(CommonAffixes, superPos, 1);
						GetCommonValueAtPosEx(EnemyName, sizeof(EnemyName), superPos, SUPER_COMMON_NAME);
					}
					else if (enemytype == CLIENT_WITCH) Format(EnemyName, sizeof(EnemyName), "Witch");
					else GetClientName(enemycombatant, EnemyName, sizeof(EnemyName));
					if (iDisplayHealthBars == 1) DisplayInfectedHealthBars(client, enemycombatant, EnemyName);
					if (enemytype != 4) {
						AddCommasToString(enemyHealth, targetHealthText, sizeof(targetHealthText));
						int infectedHealthVal = GetInfectedHealthBar(client, enemycombatant, _, targetMaxHealthText, _, true);
						if (infectedHealthVal > 0) {
							AddCommasToString(infectedHealthVal, targetMaxHealthText, sizeof(targetMaxHealthText));
							Format(text, sizeof(text), "%s: %s/%sHP\n%s\n%s", EnemyName, targetHealthText, targetMaxHealthText, positiveStatusEffects[client], negativeStatusEffects[client]);
						}
						else Format(text, sizeof(text), "%s: %sHP\n%s\n%s", EnemyName, targetHealthText, positiveStatusEffects[client], negativeStatusEffects[client]);
					}
					else {
						AddCommasToString(GetTargetHealth(client, enemycombatant, true), targetHealthText, sizeof(targetHealthText));
						AddCommasToString(GetMaximumHealth(enemycombatant), targetMaxHealthText, sizeof(targetMaxHealthText));
						Format(text, sizeof(text), "%s: %s/%sHP\n%s\n%s", EnemyName, targetHealthText, targetMaxHealthText, positiveStatusEffects[client], negativeStatusEffects[client]);
					}
				}
			}
		}
		if (!bJetpack[client] && !legitimateTargetFound) {
			Format(text, sizeof(text), "%s\n%s", positiveStatusEffects[client], negativeStatusEffects[client]);
		}
		if (fStatusMessageDisplayTime[client] > GetEngineTime()) {
			Format(text, sizeof(text), "%s\n%s", statusMessageToDisplay[client], text);
		}
		if (strlen(text) > 1) PrintHintText(client, text);
	}
}