import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Model/application_model.dart';
import '../providers/apps_provider.dart';
import '../utils/app_theme.dart';

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
          backgroundColor: AppTheme.getBackgroundColor(context),
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          title: Text(
            'App Filter',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          bottom: TabBar(
            indicatorColor: AppTheme.getPrimaryColor(context),
            indicatorWeight: 3,
            labelColor: AppTheme.getPrimaryColor(context),
            unselectedLabelColor: AppTheme.getTextSecondaryColor(context),
            labelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'INSTALLED'),
              Tab(text: 'SYSTEM'),
            ],
          ),
        ),
        body: Obx(() {
          if (appsController.isLoading.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.getPrimaryColor(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading apps...',
                    style: GoogleFonts.poppins(
                      color: AppTheme.getTextSecondaryColor(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              _appsList(context, appsController.installedApps, 'Installed'),
              _appsList(context, appsController.systemApps, 'System'),
            ],
          );
        }),
      ),
    );
  }

  void _enableAllApps(List<ApplicationModel> apps) {
    for (var app in apps) {
      if (!app.isSelected) {
        appsController.updateAppsList(app.app.packageName, true);
      }
    }
  }

  void _disableAllApps(List<ApplicationModel> apps) {
    for (var app in apps) {
      if (app.isSelected) {
        appsController.updateAppsList(app.app.packageName, false);
      }
    }
  }

  Widget _appsList(BuildContext context, List<ApplicationModel> apps, String type) {
    if (apps.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context).withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.getPrimaryColor(context).withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.getPrimaryColor(context).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.apps_outlined,
                  color: AppTheme.getPrimaryColor(context),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No Apps Found',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppTheme.getTextPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No $type apps available',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.getTextSecondaryColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header Stats with Enable/Disable All
        Container(
          margin: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.getCardColor(context).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.getPrimaryColor(context).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    // Stats Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.getPrimaryColor(context).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.apps_rounded,
                            color: AppTheme.getPrimaryColor(context),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${type.toUpperCase()} APPS',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.getTextSecondaryColor(context),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${apps.length} Applications',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.getTextPrimaryColor(context),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.success.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.success,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${apps.where((a) => a.isSelected).length} Active',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Divider
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.getPrimaryColor(context).withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Single Toggle All Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Check if all are selected
                          final allSelected = apps.every((app) => app.isSelected);
                          if (allSelected) {
                            _disableAllApps(apps);
                          } else {
                            _enableAllApps(apps);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        splashColor: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                        highlightColor: AppTheme.getPrimaryColor(context).withOpacity(0.05),
                        child: Obx(() {
                          // Rebuild when any app changes
                          final allSelected = apps.every((app) => app.isSelected);
                          final someSelected = apps.any((app) => app.isSelected);

                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: allSelected
                                  ? AppTheme.success.withOpacity(0.1)
                                  : AppTheme.getPrimaryColor(context).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: allSelected
                                    ? AppTheme.success.withOpacity(0.4)
                                    : AppTheme.getPrimaryColor(context).withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  allSelected ? 'Disable All Apps' : 'Enable All Apps',
                                  style: GoogleFonts.poppins(
                                    color: allSelected
                                        ? AppTheme.success
                                        : AppTheme.getPrimaryColor(context),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Icon(
                                  allSelected
                                      ? Icons.check_box_rounded
                                      : (someSelected
                                      ? Icons.indeterminate_check_box_rounded
                                      : Icons.check_box_outline_blank_rounded),
                                  color: allSelected
                                      ? AppTheme.success
                                      : AppTheme.getPrimaryColor(context),
                                  size: 20,
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Apps List
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.getPrimaryColor(context),
            onRefresh: appsController.loadApps,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: apps.length,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemBuilder: (_, index) {
                final app = apps[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        appsController.updateAppsList(
                          app.app.packageName,
                          !app.isSelected,
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      splashColor: AppTheme.getPrimaryColor(context).withOpacity(0.1),
                      highlightColor: AppTheme.getPrimaryColor(context).withOpacity(0.05),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: app.isSelected
                              ? AppTheme.success.withOpacity(0.08)
                              : AppTheme.getCardColor(context).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: app.isSelected
                                ? AppTheme.success.withOpacity(0.5)
                                : AppTheme.getPrimaryColor(context).withOpacity(0.2),
                            width: app.isSelected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // App Icon
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: app.isSelected
                                            ? AppTheme.success.withOpacity(0.6)
                                            : AppTheme.getPrimaryColor(context).withOpacity(0.3),
                                        width: 2.5,
                                      ),
                                      boxShadow: app.isSelected
                                          ? [
                                        BoxShadow(
                                          color: AppTheme.success.withOpacity(0.3),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                          : null,
                                    ),
                                    child: ClipOval(
                                      child: app.app.icon != null
                                          ? Image.memory(
                                        app.app.icon!,
                                        fit: BoxFit.cover,
                                      )
                                          : Container(
                                        color: AppTheme.getPrimaryColor(context).withOpacity(0.15),
                                        child: Icon(
                                          Icons.apps,
                                          color: AppTheme.getPrimaryColor(context),
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // App Name
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          app.app.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: AppTheme.getTextPrimaryColor(context),
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: app.isSelected
                                                    ? AppTheme.success
                                                    : AppTheme.getTextSecondaryColor(context),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              app.isSelected ? 'VPN Enabled' : 'VPN Disabled',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: app.isSelected
                                                    ? AppTheme.success
                                                    : AppTheme.getTextSecondaryColor(context),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Check Indicator
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: app.isSelected
                                          ? AppTheme.success.withOpacity(0.2)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      app.isSelected
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      color: app.isSelected
                                          ? AppTheme.success
                                          : AppTheme.getTextSecondaryColor(context),
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}