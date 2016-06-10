part of achievements;

class AchievementCheckers {
	static Achievement getCompletistIdForhub(String hubId) {
		try {
			String hubName = MapData.hubs[hubId]['name'];
			hubName = hubName.toLowerCase().replaceAll(' ', '_');
			return Achievement.find('${hubName}_completist');
		} catch (e, st) {
			Log.error('Failed getting completist achv id for <hubId=$hubId>', e, st);
			return new Achievement();
		}
	}

	// Checks if the addedTsid completes a hub
	static bool hubCompletion(List<String> locationHistory, String email, String addedTsid) {
		bool _checkStreetsInHub(String hubId) {
			List<Map<String, dynamic>> streetsInHub = MapData.streets.values.where((
			  Map streetData) {
				if (streetData["hub_id"] == null) {
					if (streetData["tsid"] != null) {
						Log.warning('Missing hub id for street with TSID ${streetData['tsid']}');
					}
					return false;
				} else {
					return (streetData["hub_id"].toString() == hubId);
				}
			}).toList();

			for (Map<String, dynamic> data in streetsInHub) {
				String tsid = data["tsid"] ?? "";

				if (!(locationHistory.contains(tsidG(tsid)) || locationHistory.contains(tsidL(tsid)))) {
					// Neither TSID version visited
					return false;
				}
			}

			// Visited every street in hub
			return true;
		}

		String addedTsidHubId;
		try {
			addedTsidHubId = MapData.getStreetByTsid(addedTsid)['hub_id'].toString();
		} catch (e) {
			Log.warning('Cannot find hub id for $addedTsid');
			return false;
		}

		if (_checkStreetsInHub(addedTsidHubId)) {
			AchievementCheckers.getCompletistIdForhub(addedTsidHubId).awardTo(email);
			return true;
		} else {
			return false;
		}
	}
}
