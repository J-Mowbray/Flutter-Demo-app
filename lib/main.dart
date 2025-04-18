import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/weather_provider.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

/// Application entry point
void main() {
  runApp(const MyApp());
}

/// Root widget of the application
///
/// Sets up the provider architecture and theme configuration
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WeatherProvider(),
      child: MaterialApp(
        title: 'Weather App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
