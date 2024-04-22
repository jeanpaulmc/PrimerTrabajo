import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class NetworkController extends GetxController {
  final Connectivity _connectivity = Connectivity();


  @override
  void onInit() {
    super.onInit();
    _connectivity.onConnectivityChanged.listen((connectivityResults) {
    for (var connectivityResult in connectivityResults) {
      _updateConnectionStatus(connectivityResult);
    }
    });
  }


  void _updateConnectionStatus(ConnectivityResult connectivityResult) {
    print('Connection Status: $connectivityResult');
    if (connectivityResult == ConnectivityResult.none) {
      Get.snackbar(
        'Sin conexión a internet',
        '',
        isDismissible: false,
        duration: Duration(hours: 3),
        backgroundColor: Colors.red,
      );
    } else {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
    }
  }
}

