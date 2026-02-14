import 'package:flutter/material.dart';
import '../main.dart'; // rootNavigatorKey

void showLogoToast(
    String message, {
      Color? color,
      Duration duration = const Duration(milliseconds: 2500),
    }) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final navigatorState = rootNavigatorKey.currentState;

    if (navigatorState == null) {
      debugPrint('⚠️ Toast skipped - navigatorState null: $message');
      return;
    }

    final overlay = navigatorState.overlay;

    if (overlay == null) {
      debugPrint('⚠️ Toast skipped - overlay null: $message');
      return;
    }

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.08,
          ),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 280,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9), // BLACK BACKGROUND
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(duration, () {
      try {
        entry.remove();
      } catch (e) {
        debugPrint('⚠️ Toast removal error: $e');
      }
    });
  });
}