part of entity;

class Shrine extends NPC {
	String description;
	int communeCount = 0;

	Shrine(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		actionTime = 0;

		actions.add (
			new Action.withName('Commune With')
				..timeRequired = actionTime
		);
	}

	@override
	void update({bool simulateTick: false}) {}

	void close({WebSocket userSocket, String email}) {
		communeCount -= 1;
		//if no one else has them open
		if (communeCount <= 0) {
			communeCount = 0;
			setState('close');
			int length = (currentState.numFrames / 30 * 1000).toInt();
			new Timer(new Duration(milliseconds: length), () => currentState = states['still']);
		}
	}

	communeWith({WebSocket userSocket, String email}) async {
		Metabolics m = await getMetabolics(email: email);

		String giantName = type.substring(0, 1).toUpperCase() + type.substring(1);
		InstanceMirror instanceMirror = reflect(m);
		int giantFavor = instanceMirror
			.getField(new Symbol(giantName.toLowerCase() + 'favor'))
			.reflectee;
		int maxAmt = instanceMirror
			.getField(new Symbol(giantName.toLowerCase() + 'favor_max'))
			.reflectee;

		Map map = {};
		map['giantName'] = giantName;
		map['favor'] = giantFavor;
		map['maxFavor'] = maxAmt;
		map['id'] = id;
		userSocket.add(JSON.encode(map));

		communeCount++;
		setState('open');
	}

	donate({WebSocket userSocket, String itemType, int qty, String email}) async {
		bool success = (await InventoryV2.takeAnyItemsFromUser(email, itemType, qty) == qty);
		if (success) {
			Item item = items[itemType];
			String giantName = type.substring(0, 1).toUpperCase() + type.substring(1);

			// Add favor
			int favAmt = (item.price * qty * .35) ~/ 1;
			Metabolics m = await trySetFavor(email, giantName, favAmt);

			// Add iMG
			int imgAmt = (favAmt ~/ 2).clamp(1, max(item.price, 1));
			await setMetabolics(m..addImg(imgAmt));

			InstanceMirror instanceMirror = reflect(m);

			Map addedFavorMap = {};
			addedFavorMap['favorUpdate'] = true;
			addedFavorMap['favor'] = instanceMirror
				.getField(new Symbol(giantName.toLowerCase() + 'favor'))
				.reflectee;
			addedFavorMap['maxFavor'] = instanceMirror
				.getField(new Symbol(giantName.toLowerCase() + 'favor_max'))
				.reflectee;
			userSocket.add(JSON.encode(addedFavorMap));

			//offer 'get an emblem with a giant' quest
			QuestEndpoint.questLogCache[email].offerQuest('Q3');
			//offer icon quest (only after you complete the emblem quest)
			QuestEndpoint.questLogCache[email].offerQuest('Q5');
		} else {
			Log.warning("Failed to donate $qty x $itemType to $type from <email=$email>");
		}
	}
}
