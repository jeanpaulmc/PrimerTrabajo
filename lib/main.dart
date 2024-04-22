  import 'package:conduent/dependency_injection.dart';
  import 'package:flutter/material.dart';
  import 'package:get/get.dart';
  import 'package:flutter/services.dart';

  import 'package:conduent/login/login_view.dart';
  import 'package:conduent/router/router.dart';

  void main() {
    runApp(const MyApp());
    DependencyInjection.init();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }


  class MyApp extends StatelessWidget {
    const MyApp({Key? key});

    @override
    Widget build(BuildContext context) {
      return GetMaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
          useMaterial3: true,
        ),
        initialRoute: LoginView.id,
        routes: customRoutes,
      );
    }
  }
