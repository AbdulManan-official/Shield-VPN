import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vpnprowithjava/View/Widgets/recommended_server_screen.dart';
import 'package:vpnprowithjava/utils/app_theme.dart';

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
              'Available Server',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
            bottom: TabBar(
              indicatorColor: widget.isConnected
                  ? AppTheme.connected
                  : AppTheme.getPrimaryColor(context),
              indicatorWeight: 3,
              labelColor: widget.isConnected
                  ? AppTheme.connected
                  : AppTheme.getPrimaryColor(context),
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
                Tab(text: 'LOCATIONS'),
                Tab(text: 'RECOMMENDED'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              ServersScreen(
                servers: value.freeServers,
                tab: "Locations",
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