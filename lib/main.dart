import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/mesh_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/pairing_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const RadioMeshApp());
}

class RadioMeshApp extends StatelessWidget {
  const RadioMeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MeshProvider(),
      child: Consumer<MeshProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: 'Radio-Mesh Maule',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            home: _buildCurrentScreen(provider.currentScreen),
          );
        },
      ),
    );
  }

  Widget _buildCurrentScreen(AppFlowScreen flowScreen) {
    switch (flowScreen) {
      case AppFlowScreen.splash:
        return const SplashScreen();
      case AppFlowScreen.pairing:
      case AppFlowScreen.pairedSuccess:
        return const PairingScreen();
      case AppFlowScreen.nameInput:
      case AppFlowScreen.mainNav:
        return const MainNavigationScreen();
    }
  }
}
