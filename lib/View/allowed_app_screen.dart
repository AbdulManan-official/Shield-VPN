import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Model/application_model.dart';
import '../providers/apps_provider.dart';
import '../utils/app_theme.dart'; // ✅ IMPORTED THEME


class AllowedAppsScreen extends StatelessWidget {
  AllowedAppsScreen({super.key});

  final AppsController appsController = Get.find();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        appBar: AppBar(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(7),
              bottomLeft: Radius.circular(7),
            ),
          ),
          backgroundColor: AppTheme.getCardColor(context),
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          title: Text(
            'App Filter',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          bottom: TabBar(
            indicatorColor: AppTheme.getPrimaryColor(context),
            labelColor: AppTheme.getPrimaryColor(context),
            unselectedLabelColor: AppTheme.getTextSecondaryColor(context),
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
            return Center(
              child: CircularProgressIndicator(
                color: AppTheme.getPrimaryColor(context),
              ),
            );
          }

          return TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              _appsList(context, appsController.installedApps),
              _appsList(context, appsController.systemApps),
            ],
          );
        }),
      ),
    );
  }

  Widget _appsList(BuildContext context, List<ApplicationModel> apps) {
    if (apps.isEmpty) {
      return Center(
        child: Text(
          'No apps found',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.getPrimaryColor(context),
      onRefresh: appsController.loadApps,
      child: ListView.builder(
        itemCount: apps.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, index) {
          final app = apps[index];
          return Container(
            margin: const EdgeInsets.symmetric(
              vertical: 5,
              horizontal: 10,
            ),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.isDarkMode(context)
                    ? AppTheme.borderDark
                    : AppTheme.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.isDarkMode(context)
                      ? AppTheme.shadowDark
                      : AppTheme.shadowLight,
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: app.app.icon != null
                  ? Image.memory(app.app.icon!, width: 35)
                  : Icon(
                Icons.apps,
                color: AppTheme.getPrimaryColor(context),
              ),
              title: Text(
                app.app.name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
              trailing: Switch(
                activeColor: AppTheme.success,
                activeTrackColor: AppTheme.success.withValues(alpha: 0.5),
                inactiveThumbColor: AppTheme.getTextSecondaryColor(context),
                inactiveTrackColor: AppTheme.isDarkMode(context)
                    ? AppTheme.surfaceDark
                    : AppTheme.surfaceLight,
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