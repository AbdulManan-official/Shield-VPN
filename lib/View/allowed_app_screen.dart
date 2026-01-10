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

// class AllowedAppsScreen extends StatefulWidget {
//   const AllowedAppsScreen({super.key});
//
//   @override
//   State<AllowedAppsScreen> createState() => _AllowedAppsScreenState();
// }
//
// class _AllowedAppsScreenState extends State<AllowedAppsScreen> {
//   MethodChannel platform = const MethodChannel("disallowList");
//
//   // Search
//   final TextEditingController _searchController = TextEditingController();
//   final FocusNode _searchFocusNode = FocusNode();
//   List<ApplicationModel> _filteredApps = [];
//   bool _isSearchActive = false;
//   String _searchQuery = '';
//   // var v5;
//   final AppsController apps = Get.find();
//
//   @override
//   void initState() {
//     super.initState();
//     // Schedule this after the first frame
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _getAllApps();
//     });
//     _searchController.addListener(_onSearchChanged);
//   }
//
//   @override
//   void dispose() {
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     _searchFocusNode.dispose();
//     super.dispose();
//   }
//
//   Future<void> _getAllApps() async {
//     final appsProvider = Provider.of<AppsProvider>(context, listen: false);
//
//     if (appsProvider.hasLoadedApps) {
//       // Already loaded from home page, just update filtered apps
//       setState(() {
//         _updateFilteredApps();
//       });
//       return;
//     }
//
//     // If not loaded yet, fallback to load here (optional)
//     appsProvider.updateLoader(true);
//     try {
//       await appsProvider.setDisallowList();
//
//       final results = await Future.wait([
//         GetApps.GetAllAppInfo(),
//         GetApps.GetSocialSystemApps(),
//       ]);
//
//       final userApps = results[0];
//       final socialSystemApps = results[1];
//
//       final allApps = [
//         ...userApps.map((app) => ApplicationModel(isSelected: true, app: app)),
//         ...socialSystemApps
//             .map((app) => ApplicationModel(isSelected: true, app: app)),
//       ];
//
//       allApps.sort((a, b) => (a.app.name)
//           .toLowerCase()
//           .compareTo((b.app.name).toLowerCase()));
//
//       appsProvider.setAllApps(allApps);
//       _updateFilteredApps();
//     } catch (e, stack) {
//       debugPrint("Error loading apps in allowed screen: $e\n$stack");
//     } finally {
//       appsProvider.updateLoader(false);
//     }
//   }
//
//   void _onSearchChanged() {
//     setState(() {
//       _searchQuery = _searchController.text;
//       _updateFilteredApps();
//     });
//   }
//
//   void _updateFilteredApps() {
//     final apps = Provider.of<AppsProvider>(context, listen: false).getAllApps;
//
//     if (_searchQuery.isEmpty) {
//       _filteredApps = List.from(apps);
//     } else {
//       final searchTerm = _searchQuery.toLowerCase();
//       // Only filter by app name, exclude package name from search
//       _filteredApps = apps.where((app) {
//         final appName = app.app.name.toLowerCase();
//         return appName.contains(searchTerm);
//       }).toList();
//
//       // Sort results: apps starting with search term first
//       _filteredApps.sort((a, b) {
//         final aName = a.app.name.toLowerCase();
//         final bName = b.app.name.toLowerCase();
//         if (aName.startsWith(searchTerm) && !bName.startsWith(searchTerm)) {
//           return -1;
//         }
//         if (!aName.startsWith(searchTerm) && bName.startsWith(searchTerm)) {
//           return 1;
//         }
//         return aName.compareTo(bName);
//       });
//     }
//   }
//
//   void _toggleSearch() {
//     setState(() {
//       _isSearchActive = !_isSearchActive;
//       if (_isSearchActive) {
//         _searchFocusNode.requestFocus();
//       } else {
//         _searchController.clear();
//         _searchQuery = '';
//         _searchFocusNode.unfocus();
//         _updateFilteredApps();
//       }
//     });
//   }
//
//   void _clearSearch() {
//     setState(() {
//       _searchController.clear();
//       _searchQuery = '';
//       _updateFilteredApps();
//     });
//   }
//
//   void _disallowApp(String packageName) async {
//     // await platform.invokeMethod("applyChanges", {"packageName": packageName});
//   }
//
//   Widget _buildEmptyState({bool isError = false}) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             isError ? Icons.error_outline : Icons.apps,
//             size: 64,
//             color: isError ? Colors.red : Colors.grey.shade600,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             isError
//                 ? "Could not load apps"
//                 : _searchQuery.isEmpty
//                     ? "No Apps Found!"
//                     : "No apps match '$_searchQuery'",
//             style: GoogleFonts.poppins(
//               color: Colors.grey.shade400,
//               fontSize: 16,
//             ),
//           ),
//           const SizedBox(height: 8),
//           if (isError || _searchQuery.isNotEmpty)
//             ElevatedButton(
//               onPressed: isError ? _getAllApps : _clearSearch,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//               ),
//               child: Text(
//                 isError ? "Retry" : "Clear search",
//                 style: GoogleFonts.poppins(color: Colors.white),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLoadingWidget() {
//     final screenSize = MediaQuery.of(context).size;
//     final screenWidth = screenSize.width;
//     final screenHeight = screenSize.height;
//
//     // Ultra-aggressive responsive sizing for small screens
//     final isUltraTinyScreen = screenWidth < 280;
//     final isVerySmallScreen = screenWidth < 320;
//     final isSmallScreen = screenWidth < 360;
//     final isMediumScreen = screenWidth < 600;
//
//     // Loading spinner size - ultra-compact for tiny screens
//     final loadingIconSize = isUltraTinyScreen
//         ? (screenWidth * 0.12).clamp(35.0, 45.0)
//         : isVerySmallScreen
//             ? (screenWidth * 0.13).clamp(40.0, 50.0)
//             : isSmallScreen
//                 ? (screenWidth * 0.14).clamp(45.0, 55.0)
//                 : isMediumScreen
//                     ? (screenWidth * 0.15).clamp(50.0, 70.0)
//                     : (screenWidth * 0.15).clamp(60.0, 80.0);
//
//     // Text sizes that scale appropriately for very small screens
//     final titleFontSize = isUltraTinyScreen
//         ? 12.0
//         : isVerySmallScreen
//             ? 14.0
//             : isSmallScreen
//                 ? 16.0
//                 : isMediumScreen
//                     ? 18.0
//                     : 20.0;
//
//     final subtitleFontSize = isUltraTinyScreen
//         ? 10.0
//         : isVerySmallScreen
//             ? 11.0
//             : isSmallScreen
//                 ? 12.0
//                 : isMediumScreen
//                     ? 14.0
//                     : 16.0;
//
//     // Compact padding for small screens
//     final containerPadding = isUltraTinyScreen
//         ? 8.0
//         : isVerySmallScreen
//             ? 10.0
//             : isSmallScreen
//                 ? 12.0
//                 : isMediumScreen
//                     ? 16.0
//                     : 20.0;
//
//     // Stroke width that's visible on small screens
//     final strokeWidth = isUltraTinyScreen
//         ? 2.0
//         : isVerySmallScreen
//             ? 2.5
//             : 3.0;
//
//     return Center(
//       child: SingleChildScrollView(
//         child: Container(
//           constraints: BoxConstraints(
//             maxHeight: screenHeight * 0.6,
//             maxWidth: screenWidth * 0.9,
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: EdgeInsets.all(containerPadding),
//                 margin: EdgeInsets.symmetric(horizontal: containerPadding),
//                 decoration: BoxDecoration(
//                   color: UIColors.cardBg,
//                   borderRadius: BorderRadius.circular(
//                     isUltraTinyScreen
//                         ? 12
//                         : isVerySmallScreen
//                             ? 15
//                             : 20,
//                   ),
//                   border: Border.all(
//                     color: UIColors.accentTeal.withValues(alpha: 0.3),
//                     width: isUltraTinyScreen ? 1 : 2,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: UIColors.accentTeal.withValues(alpha: 0.2),
//                       blurRadius: isUltraTinyScreen ? 10 : 20,
//                       spreadRadius: isUltraTinyScreen ? 2 : 5,
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     SizedBox(
//                       width: loadingIconSize,
//                       height: loadingIconSize,
//                       child: CircularProgressIndicator(
//                         strokeWidth: strokeWidth,
//                         valueColor: const AlwaysStoppedAnimation<Color>(
//                             UIColors.accentTeal),
//                       ),
//                     ),
//                     SizedBox(height: containerPadding * 0.6),
//                     Text(
//                       'Loading Apps...',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: titleFontSize,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(height: containerPadding * 0.3),
//                     Padding(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: isUltraTinyScreen ? 4.0 : 8.0,
//                       ),
//                       child: Text(
//                         'Please wait while we fetch your apps',
//                         textAlign: TextAlign.center,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: subtitleFontSize,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     final screenWidth = screenSize.width;
//     // final screenHeight = screenSize.height;
//     final isUltraTinyScreen = screenWidth < 280;
//     // final isVerySmallScreen = screenWidth < 320;
//     // final isSmallScreen = screenWidth < 360;
//     // final isMediumScreen = screenWidth < 600;
//     return Consumer<AppsProvider>(
//       builder: (context, appsProvider, child) {
//         final apps = appsProvider.getAllApps;
//         final isLoading = appsProvider.isLoading;
//
//         if (_filteredApps.isEmpty && apps.isNotEmpty) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             setState(() {
//               _updateFilteredApps();
//             });
//           });
//         }
//
//         return Scaffold(
//           backgroundColor: UIColors.darkBg,
//           appBar: AppBar(
//             shape: const RoundedRectangleBorder(
//               borderRadius: BorderRadius.only(
//                 bottomRight: Radius.circular(7),
//                 bottomLeft: Radius.circular(7),
//               ),
//             ),
//             backgroundColor: UIColors.cardBg,
//             elevation: 0,
//             leading: IconButton(
//               onPressed: () => Navigator.of(context).pop(),
//               icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//             ),
//             title: _isSearchActive
//                 ? TextField(
//                     controller: _searchController,
//                     focusNode: _searchFocusNode,
//                     style: GoogleFonts.poppins(color: Colors.white),
//                     decoration: InputDecoration(
//                       hintText: 'Search app names...',
//                       hintStyle:
//                           GoogleFonts.poppins(color: Colors.grey.shade400),
//                       border: InputBorder.none,
//                     ),
//                   )
//                 : Text(
//                     'Filter apps',
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.w800,
//                       color: Colors.white,
//                     ),
//                   ),
//             actions: [
//               IconButton(
//                 onPressed: _toggleSearch,
//                 icon: Icon(
//                   _isSearchActive ? Icons.close : Icons.search,
//                   color: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//           body: Column(
//             children: [
//               if (_isSearchActive && _searchQuery.isNotEmpty)
//                 Container(
//                   width: double.infinity,
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   color: Colors.grey.shade800,
//                   child: Text(
//                     '${_filteredApps.length} app${_filteredApps.length != 1 ? 's' : ''} found',
//                     style: GoogleFonts.poppins(
//                       color: Colors.grey.shade300,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               Expanded(
//                 child: isLoading
//                     ? _buildLoadingWidget()
//                     : _filteredApps.isEmpty
//                         ? _buildEmptyState(
//                             isError: apps.isEmpty && !_isSearchActive)
//                         : RefreshIndicator(
//                             onRefresh: _getAllApps,
//                             child: ListView.builder(
//                               padding: const EdgeInsets.all(8),
//                               itemCount: _filteredApps.length,
//                               itemBuilder: (context, index) {
//                                 final app = _filteredApps[index];
//                                 return Container(
//                                   margin: EdgeInsets.symmetric(
//                                     vertical: isUltraTinyScreen ? 4 : 8,
//                                     horizontal: isUltraTinyScreen ? 2 : 8,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: UIColors.cardBg,
//                                     borderRadius: BorderRadius.circular(12),
//                                     border: Border.all(
//                                       color: UIColors.lightPurple
//                                           .withValues(alpha: 0.2),
//                                       width: isUltraTinyScreen ? 0.5 : 1,
//                                     ),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: UIColors.primaryPurple
//                                             .withValues(alpha: 0.1),
//                                         blurRadius: isUltraTinyScreen ? 4 : 8,
//                                         spreadRadius:
//                                             isUltraTinyScreen ? 0.5 : 1,
//                                         offset: const Offset(0, 2),
//                                       ),
//                                     ],
//                                   ),
//                                   child: ListTile(
//                                     contentPadding: const EdgeInsets.symmetric(
//                                       horizontal: 16,
//                                       vertical: 8,
//                                     ),
//                                     leading: CircleAvatar(
//                                       backgroundImage:
//                                           MemoryImage(app.app.icon!),
//                                       backgroundColor: Colors.white,
//                                       radius: 25,
//                                     ),
//                                     title: Text(
//                                       app.app.name,
//                                       style: GoogleFonts.poppins(
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                     subtitle: Text(
//                                       app.app.packageName,
//                                       style: GoogleFonts.poppins(
//                                         color: Colors.grey.shade400,
//                                         fontSize: 12,
//                                       ),
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                     trailing: Switch(
//                                       activeThumbColor: UIColors.connectGreen,
//                                       inactiveThumbColor: Colors.grey.shade600,
//                                       inactiveTrackColor: Colors.grey.shade800,
//                                       value: app.isSelected,
//                                       onChanged: (bool val) {
//                                         setState(() {
//                                           app.isSelected = val;
//                                           appsProvider.updateAppsList(
//                                             app.app.packageName,
//                                             app.isSelected,
//                                           );
//                                         });
//                                         _disallowApp(app.app.packageName);
//                                       },
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
