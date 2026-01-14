import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vpnprowithjava/View/Widgets/recommended_server_screen.dart';
import 'package:vpnprowithjava/utils/app_theme.dart'; // ✅ IMPORTED THEME

import '../../providers/servers_provider.dart';
import 'Widgets/servers_screen.dart';

class ServerTabs extends StatefulWidget {
  final bool isConnected;
  const ServerTabs({super.key, required this.isConnected});

  @override
  State<ServerTabs> createState() => _ServerTabsState();
}

class _ServerTabsState extends State<ServerTabs> {
  @override
  void initState() {
    super.initState();
    // Ensure provider is initialized when this screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ServersProvider>(context, listen: false);
      if (!provider.isInitialized) {
        provider.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServersProvider>(
      builder: (context, value, child) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppTheme.getBackgroundColor(context),
            leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
            title: Text(
              'Select Country',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
            bottom: TabBar(
              indicatorColor: widget.isConnected
                  ? AppTheme.connected
                  : AppTheme.getPrimaryColor(context),
              labelColor: widget.isConnected
                  ? AppTheme.connected
                  : AppTheme.getPrimaryColor(context),
              unselectedLabelColor: AppTheme.getTextSecondaryColor(context),
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  text: 'ALL LOCATIONS',
                ),
                Tab(
                  text: 'RECOMMENDED',
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              ServersScreen(
                servers: value.freeServers,
                tab: "All Locations",
                isConnected: widget.isConnected,
              ),
              RecommendedServer(
                servers: value.freeServers,
                isConnected: widget.isConnected,
                tab: "Recommended",
              ),
            ],
          ),
        ),
      ),
    );
  }
}