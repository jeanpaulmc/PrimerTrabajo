import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:conduent/dependency_injection.dart';
import 'package:flutter/services.dart';
import 'package:conduent/login/VistaLogin.dart';
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
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: AnimatedSplashScreen(
        splash: Image.asset('assets/conduent.jpg'),
        nextScreen: const LoginView(),
        splashTransition: SplashTransition.slideTransition,
        backgroundColor: Colors.white,
        duration: 3000,
      ),
      routes: customRoutes,
    );
  }
}
