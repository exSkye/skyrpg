int ConvertEffectToInt(char[] resultEffects) {
	if (!StrEqual(resultEffects, "-1")) {
		if (StrEqual(resultEffects, "vampire")) return 0;
		if (StrEqual(resultEffects, "createmine")) return 1;
		if (StrEqual(resultEffects, "aoeheal")) return 2;
		if (StrEqual(resultEffects, "ffexplode")) return 3;
		if (StrEqual(resultEffects, "poisonclaw")) return 4;
		if (StrEqual(resultEffects, "burnclaw")) return 5;
		if (StrEqual(resultEffects, "maghalfempty")) return 6;
		if (StrEqual(resultEffects, "parry")) return 7;
		if (StrEqual(resultEffects, "a")) return 8;
		if (StrEqual(resultEffects, "A")) return 9;
		if (StrEqual(resultEffects, "b")) return 10;
		if (StrEqual(resultEffects, "c")) return 11;
		if (StrEqual(resultEffects, "acidburn")) return 12;
		if (StrEqual(resultEffects, "f")) return 13;
		if (StrEqual(resultEffects, "E")) return 14;
		if (StrEqual(resultEffects, "e")) return 15;
		if (StrEqual(resultEffects, "g")) return 16;
		if (StrEqual(resultEffects, "h")) return 17;
		if (StrEqual(resultEffects, "u")) return 18;
		if (StrEqual(resultEffects, "U")) return 19;
		if (StrEqual(resultEffects, "i")) return 20;
		if (StrEqual(resultEffects, "j")) return 21;
		if (StrEqual(resultEffects, "l")) return 22;
		if (StrEqual(resultEffects, "m")) return 23;
		if (StrEqual(resultEffects, "r1bullet")) return 24;	// refund a single bullet. great for heal bullet proficiency.
		if (StrEqual(resultEffects, "rrbullet")) return 25; // refund a raw amount, not based on magazine size.
		if (StrEqual(resultEffects, "rrbulletaoe")) return 26;
		if (StrEqual(resultEffects, "rpbullet")) return 27;
		if (StrEqual(resultEffects, "rpbulletaoe")) return 28;
		if (StrEqual(resultEffects, "aoedamage")) return 29;
		if (StrEqual(resultEffects, "R")) return 30;
		if (StrEqual(resultEffects, "s")) return 31;
		if (StrEqual(resultEffects, "speed")) return 32;
		if (StrEqual(resultEffects, "S")) return 33;
		if (StrEqual(resultEffects, "t")) return 34;
		if (StrEqual(resultEffects, "T")) return 35;
		if (StrEqual(resultEffects, "z")) return 36;
		if (StrEqual(resultEffects, "revive")) return 37;
		if (StrEqual(resultEffects, "giveitem")) return 38;
		if (StrEqual(resultEffects, "activetime")) return 39;
		if (StrEqual(resultEffects, "cooldown")) return 40;
		if (StrEqual(resultEffects, "staminacost")) return 41;
		if (StrEqual(resultEffects, "range")) return 42;
		if (StrEqual(resultEffects, "strengthup")) return 43;
		if (StrEqual(resultEffects, "flightcost")) return 44;
		if (StrEqual(resultEffects, "stamina")) return 45;
		if (StrEqual(resultEffects, "ammoreserve")) return 46;
		if (StrEqual(resultEffects, "d")) return 47;
		if (StrEqual(resultEffects, "o")) return 48;
		if (StrEqual(resultEffects, "H")) return 49;
		if (StrEqual(resultEffects, "amplify")) return 50;
	}
	return -1;
}

int ConvertStringRewardToInt(char[] s) {
	if (StrEqual(s, "materials", false)) return 0;
	if (StrEqual(s, "xpbooster", false)) return 1;
	if (StrEqual(s, "itemgive", false)) return 2;
	return -1;
}

int ConvertStringToColorCode(char[] s) {
	if (StrEqual(s, "green", false)) return 0;
	if (StrEqual(s, "red", false)) return 1;
	if (StrEqual(s, "blue", false)) return 2;
	if (StrEqual(s, "purple", false)) return 3;
	if (StrEqual(s, "yellow", false)) return 4;
	if (StrEqual(s, "orange", false)) return 5;
	if (StrEqual(s, "black", false)) return 6;
	if (StrEqual(s, "brightblue", false)) return 7;
	if (StrEqual(s, "darkgreen", false)) return 8;
	if (StrEqual(s, "white", false)) return 9;
	return 0;
}

int ConvertTriggerToInt(char[] abilityTrigger) {
	if (StrEqual(abilityTrigger, "R")) return 0;
	if (StrEqual(abilityTrigger, "r")) return 1;
	if (StrEqual(abilityTrigger, "d")) return 2;
	if (StrEqual(abilityTrigger, "l")) return 3;
	if (StrEqual(abilityTrigger, "H")) return 4;
	if (StrEqual(abilityTrigger, "infected_abilityuse")) return 5;
	if (StrEqual(abilityTrigger, "Q")) return 6;
	if (StrEqual(abilityTrigger, "A")) return 7;
	if (StrEqual(abilityTrigger, "q")) return 8;
	if (StrEqual(abilityTrigger, "pounced")) return 9;
	if (StrEqual(abilityTrigger, "distance")) return 10;
	if (StrEqual(abilityTrigger, "v")) return 11;
	if (StrEqual(abilityTrigger, "spellbuff")) return 12;
	if (StrEqual(abilityTrigger, "aamRNG")) return 13;
	if (StrEqual(abilityTrigger, "progbarspeed")) return 14;
	if (StrEqual(abilityTrigger, "didStagger")) return 15;
	if (StrEqual(abilityTrigger, "wasStagger")) return 16;
	if (StrEqual(abilityTrigger, "usepainpills")) return 17;
	if (StrEqual(abilityTrigger, "healsuccess")) return 18;
	if (StrEqual(abilityTrigger, "usefirstaid")) return 19;
	if (StrEqual(abilityTrigger, "jetpack")) return 20;
	if (StrEqual(abilityTrigger, "specialkill")) return 21;
	if (StrEqual(abilityTrigger, "assist")) return 22;
	if (StrEqual(abilityTrigger, "U")) return 23;
	if (StrEqual(abilityTrigger, "u")) return 24;
	if (StrEqual(abilityTrigger, "L")) return 25;
	if (StrEqual(abilityTrigger, "p")) return 26;
	if (StrEqual(abilityTrigger, "lessTankyMoreDamage")) return 27;
	if (StrEqual(abilityTrigger, "lessDamageMoreTanky")) return 28;
	if (StrEqual(abilityTrigger, "lessHealsMoreTanky")) return 29;
	if (StrEqual(abilityTrigger, "lessDamageMoreHeals")) return 30;
	if (StrEqual(abilityTrigger, "lessTankyMoreHeals")) return 31;
	if (StrEqual(abilityTrigger, "lessHealsMoreDamage")) return 32;
	if (StrEqual(abilityTrigger, "dropitem")) return 33;
	if (StrEqual(abilityTrigger, "h")) return 34;
	if (StrEqual(abilityTrigger, "pacifist")) return 35;
	if (StrEqual(abilityTrigger, "D")) return 36;
	if (StrEqual(abilityTrigger, "hB")) return 37;
	if (StrEqual(abilityTrigger, "hM")) return 38;
	if (StrEqual(abilityTrigger, "S")) return 39;
	if (StrEqual(abilityTrigger, "explosion")) return 40;
	if (StrEqual(abilityTrigger, "Y")) return 41;
	if (StrEqual(abilityTrigger, "T")) return 42;
	if (StrEqual(abilityTrigger, "claw")) return 43;
	if (StrEqual(abilityTrigger, "s")) return 44;
	if (StrEqual(abilityTrigger, "V")) return 45;
	if (StrEqual(abilityTrigger, "t")) return 46;
	if (StrEqual(abilityTrigger, "a")) return 47;
	if (StrEqual(abilityTrigger, "ammoreserve")) return 48;
	if (StrEqual(abilityTrigger, "e")) return 49;
	if (StrEqual(abilityTrigger, "E")) return 50;
	if (StrEqual(abilityTrigger, "witchkill")) return 51;
	if (StrEqual(abilityTrigger, "superkill")) return 52;
	if (StrEqual(abilityTrigger, "C")) return 53;
	if (StrEqual(abilityTrigger, "enterammo")) return 54;
	if (StrEqual(abilityTrigger, "exitammo")) return 55;
	if (StrEqual(abilityTrigger, "getstam")) return 56;
	if (StrEqual(abilityTrigger, "N")) return 57;
	if (StrEqual(abilityTrigger, "n")) return 58;
	if (StrEqual(abilityTrigger, "m")) return 59;
	if (StrEqual(abilityTrigger, "limbshot")) return 60;
	if (StrEqual(abilityTrigger, "headshot")) return 61;
	if (StrEqual(abilityTrigger, "wasHealed")) return 62;
	if (StrEqual(abilityTrigger, "healself")) return 63;
	if (StrEqual(abilityTrigger, "coveredInBile")) return 64;
	if (StrEqual(abilityTrigger, "biledTarget")) return 65;
	if (StrEqual(abilityTrigger, "biledOnEnds")) return 66;
	if (StrEqual(abilityTrigger, "defibUsed")) return 67;
	if (StrEqual(abilityTrigger, "wasDefibbed")) return 68;
	if (StrEqual(abilityTrigger, "P")) return 69;
	if (StrEqual(abilityTrigger, "impacthit")) return 70;
	if (StrEqual(abilityTrigger, "didRevive")) return 71;
	if (StrEqual(abilityTrigger, "wasRevive")) return 72;
	if (StrEqual(abilityTrigger, "amplify")) return 73;
	return -1;	// shouldn't happen unless a trigger is added that doesn't exist.
}