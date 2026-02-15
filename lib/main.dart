import 'package:flutter/material.dart';
import 'screens/loading_screen.dart';
import 'services/settings_service.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.init(); // KAILANGAN awaited bago runApp!
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Card Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurple,
          surface: const Color(0xFF1A1A2E),
        ),
      ),
      navigatorObservers: [routeObserver],
      home: const LoadingScreen(),
    );
  }
}
