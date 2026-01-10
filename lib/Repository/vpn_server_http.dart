import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Model/vpn_server.dart';
import '../utils/environment.dart';

class VpnServerHttp {
  Future<List<VpnServer>> getServers(String type) async {
    final List<VpnServer> servers = [];
    final client = http.Client();

    try {
      final headers = {'auth_token': 'I3F5M5K9C'};
      final uri = Uri.parse("${api}servers/$type");

      // Add timeout (e.g., 10 seconds)
      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded['data'] ?? [];

        debugPrint("Fetched ${data.length} $type servers----------");

        for (final js in data) {
          servers.add(VpnServer.fromJson(js));
        }

        // Handle one-time shuffle
        final prefs = await SharedPreferences.getInstance();
        final bool shuffleDone = prefs.getBool('first_shuffle_done') ?? false;

        if (!shuffleDone) {
          servers.shuffle(Random());
          await prefs.setBool('first_shuffle_done', true);
        }
      } else {
        debugPrint("Server returned status ${response.statusCode}");
      }
    } on TimeoutException catch (_) {
      debugPrint("Request for $type servers timed out.");
    } catch (e, stack) {
      debugPrint("Error fetching $type servers: $e");
      debugPrint(stack.toString());
    } finally {
      client.close();
    }

    return servers;
  }

  // Future<VpnConfig?> getBestServer(BuildContext context) async {
  //   final client = http.Client();
  //   final vpn = VpnProvider.instance(context);
  //   VpnConfig? bestServer;

  //   try {
  //     final headers = {'auth_token': 'wQLAYr4pe4Bl'};
  //     final uri = Uri.parse("${api}servers/best");

  //     // Add timeout for safety (10 seconds)
  //     final response = await client
  //         .get(uri, headers: headers)
  //         .timeout(const Duration(seconds: 10));

  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> decoded = jsonDecode(response.body);
  //       final data = decoded['data'];

  //       if (data != null) {
  //         bestServer = VpnConfig.fromJson(data);
  //         vpn.vpnConfig = bestServer;
  //         debugPrint("✅ Best server fetched successfully");
  //       } else {
  //         debugPrint("⚠️ No 'data' field found in API response");
  //       }
  //     } else {
  //       debugPrint("❌ Failed to fetch best server: ${response.statusCode}");
  //     }
  //   } on TimeoutException catch (_) {
  //     debugPrint("⏰ Timeout: Best server request took too long.");
  //   } catch (e, stack) {
  //     debugPrint("🚨 Error while fetching best server: $e");
  //     debugPrint(stack.toString());
  //   } finally {
  //     client.close();
  //   }

  //   debugPrint("Best server result: ${bestServer != null ? 'Success' : 'None'}");
  //   return bestServer;
  // }
}
