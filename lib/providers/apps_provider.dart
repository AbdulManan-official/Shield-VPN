import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:installed_apps/app_info.dart';
import '../Model/application_model.dart';

import '../utils/get_apps.dart';
import '../utils/prefs.dart';

class AppsController extends GetxController {
  // STATE
  final RxList<ApplicationModel> installedApps = <ApplicationModel>[].obs;
  final RxList<ApplicationModel> systemApps = <ApplicationModel>[].obs;

  final RxBool isLoading = true.obs;
  final RxList<String> disallowList = <String>[].obs;
  final RxBool isVpnConnected = false.obs;

  // LIFECYCLE
  @override
  void onInit() {
    super.onInit();
    loadApps();
  }

  // LOAD APPS
  Future<void> loadApps() async {
    isLoading.value = true;

    await setDisallowList();

    final user = await GetApps.getInstalledApps();
    final system = await GetApps.getSystemApps();

    installedApps.assignAll(
      _mapToApplicationModel(user),
    );

    systemApps.assignAll(
      _mapToApplicationModel(system),
    );

    isLoading.value = false;
  }

  // MAP TO APPLICATION MODEL
  List<ApplicationModel> _mapToApplicationModel(List<AppInfo> apps) {
    return apps.map((app) {
      final isBlocked = disallowList.contains(app.packageName);

      return ApplicationModel(
        app: app,
        isSelected: !isBlocked,
      );
    }).toList();
  }

  // DISALLOW LIST
  Future<void> setDisallowList() async {
    final list =
    await MySharedPreference.GetStringList("disallowedList");
    disallowList.assignAll(list);
  }

  // UPDATE APP
  void updateAppsList(String packageName, bool allow) async {
    if (!allow && !disallowList.contains(packageName)) {
      disallowList.add(packageName);
    } else if (allow && disallowList.contains(packageName)) {
      disallowList.remove(packageName);
    }

    await MySharedPreference.SaveStringList(
      "disallowedList",
      disallowList,
    );

    _syncSelection(installedApps, packageName, allow);
    _syncSelection(systemApps, packageName, allow);
    debugPrint(disallowList.toString());
  }

  void _syncSelection(
      RxList<ApplicationModel> list,
      String packageName,
      bool allow,
      ) {
    final index =
    list.indexWhere((e) => e.app.packageName == packageName);
    if (index != -1) {
      list[index].isSelected = allow;
      list.refresh();
    }
  }

  // VPN STATE
  void updateVpnConnectionState(bool value) {
    isVpnConnected.value = value;
  }
}
