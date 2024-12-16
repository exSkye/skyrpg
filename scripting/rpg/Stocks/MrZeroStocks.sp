stock bool L4D2_SetEntGlow(int entity, L4D2GlowType:type, int range, int minRange, int redcolor, int bluecolor, int greencolor, bool flashing) {
	char netclass[128];
	GetEntityNetClass(entity, netclass, 128);

	int offset = FindSendPropInfo(netclass, "m_iGlowType");
	if (offset < 1) {
		return false;
	}
	L4D2_SetEntGlow_Type(entity, type);
	L4D2_SetEntGlow_Range(entity, range);
	L4D2_SetEntGlow_MinRange(entity, minRange);
	L4D2_SetEntGlow_ColorOverride(entity, redcolor, bluecolor, greencolor);
	L4D2_SetEntGlow_Flashing(entity, flashing);
	return true;
}

/**
 * Set entity glow type.
 *
 * @param entity		Entity index.
 * @parma type			Glow type.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
stock void L4D2_SetEntGlow_Type(int entity, L4D2GlowType:type) {
	SetEntProp(entity, Prop_Send, "m_iGlowType", _:type);
}

/**
 * Set entity glow range.
 *
 * @param entity		Entity index.
 * @parma range			Glow range.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_Range(int entity, int range) {
	SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
}

/**
 * Set entity glow min range.
 *
 * @param entity		Entity index.
 * @parma minRange		Glow min range.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_MinRange(int entity, int minRange) {
	SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", minRange);
}

/**
 * Set entity glow color.
 *
 * @param entity		Entity index.
 * @parma colorOverride	Glow color, RGB.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_ColorOverride(int entity, int redcolor, int bluecolor, int greencolor) {
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", redcolor + (bluecolor * 256) + (greencolor * 65536));
}

/**
 * Set entity glow flashing state.
 *
 * @param entity		Entity index.
 * @parma flashing		Whether glow will be flashing.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_Flashing(int entity, bool flashing) {
	SetEntProp(entity, Prop_Send, "m_bFlashing", _:flashing);
}