// router

import 'package:flutter/material.dart';

import '../login/login_view.dart';

var customRoutes = <String, WidgetBuilder>{
  /// vista login
  LoginView.id: (_) => const LoginView(),

};