import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Model/application_model.dart';
import '../providers/apps_provider.dart';
import '../utils/colors.dart';


class AllowedAppsScreen extends StatelessWidget {
  AllowedAppsScreen({super.key});

  final AppsController appsController = Get.find();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: UIColors.darkBg,
        appBar: AppBar(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(7),
              bottomLeft: Radius.circular(7),
            ),
          ),
          backgroundColor: UIColors.cardBg,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          title: Text(
            'App Filter',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(
                child: Text(
                  'Installed',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Tab(
                child: Text(
                  'System',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Obx(() {
          if (appsController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              _appsList(appsController.installedApps),
              _appsList(appsController.systemApps),
            ],
          );
        }),
      ),
    );
  }

  Widget _appsList(List<ApplicationModel> apps) {
    if (apps.isEmpty) {
      return Center(
        child: Text(
          'No apps found',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: appsController.loadApps,
      child: ListView.builder(
        itemCount: apps.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, index) {
          final app = apps[index];
          return Container(
            margin: EdgeInsets.symmetric(
              vertical: 5,
              horizontal: 10,
            ),
            decoration: BoxDecoration(
              color: UIColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: UIColors.lightPurple.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: UIColors.primaryPurple.withValues(alpha: 0.1),
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: app.app.icon != null
                  ? Image.memory(app.app.icon!, width: 35)
                  : const Icon(Icons.apps),
              title: Text(
                app.app.name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Switch(
                activeThumbColor: UIColors.connectGreen,
                inactiveThumbColor: Colors.grey.shade600,
                inactiveTrackColor: Colors.grey.shade800,
                value: app.isSelected,
                onChanged: (value) {
                  appsController.updateAppsList(app.app.packageName, value);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

