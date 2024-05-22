// router

import 'package:flutter/material.dart';

import '../login/VistaLogin.dart';

var customRoutes = <String, WidgetBuilder>{
  /// vista login
  LoginView.id: (_) => const LoginView(),
};
