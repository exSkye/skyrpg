// Unused
stock FindEntityInArrayBinarySearch(Handle hArray, target) {
	int left = 0, right = GetArraySize(hArray);
	int middle;
	int ent;
	while (left < right) {
		middle = (left + right) / 2;
		ent = GetArrayCell(hArray, middle);
		if (ent == target) return middle;
		if (ent < target) left = middle + 1;
		else right = middle;
	}
	return -1;
}

stock InsertIntoArrayAscending(Handle hArray, entity) {
	int size = GetArraySize(hArray);
	int left = 0, right = size;
	if (right < 1) {	// if the array is empty, just push.
		PushArrayCell(hArray, entity);
		return 0;
	}
	else if (right < 2) {	// another outlier check to prevent array oob.
		if (entity > GetArrayCell(hArray, 0)) {
			PushArrayCell(hArray, entity);
			return 1;
		}
		else {
			ResizeArray(hArray, size+1);
			ShiftArrayUp(hArray, size);
			SetArrayCell(hArray, size, entity);
			return 0;
		}
	}
	else {
		int middle = (left + right) / 2;
		int middleEnt = GetArrayCell(hArray, middle);
		int leftEnt = GetArrayCell(hArray, middle - 1);
		while (entity < leftEnt || entity > middleEnt) {
			middle = (left + right) / 2;
			middleEnt = GetArrayCell(hArray, middle);
			leftEnt = GetArrayCell(hArray, middle - 1);
			if (entity < leftEnt) right--;
			else if (entity > middleEnt) left++;
			else break;
		}
		ResizeArray(hArray, size+1);
		ShiftArrayUp(hArray, middle);	// middle is now undefined.
		SetArrayCell(hArray, middle, entity);	// place new entity in middle.
		return middle;
	}
}