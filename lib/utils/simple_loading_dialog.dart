import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showLoadingDialog() {
  if (Get.isDialogOpen == true) return;

  Get.dialog(
    Center(
      child: SizedBox(
        width: 70,
        height: 70,
        child: Card(
          color: Colors.black87,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Platform.isIOS
                ? const CircularProgressIndicator.adaptive(
                    strokeWidth: 3,
                    backgroundColor: Colors.white,
                  )
                : const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    ),
    barrierDismissible: false,
  );
}

void hideLoadingDialog() {
  if (Get.isDialogOpen == true) {
    Get.back();
  }
}
