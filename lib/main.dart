import 'package:flutter/material.dart';
import 'package:vacantes/screens/edit_profile_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/create_job_screen.dart';
import 'screens/job_offers_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(const JobOffersApp());
}

class JobOffersApp extends StatelessWidget {
  const JobOffersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ay trabajo!',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/login': (context) => const AuthScreen(),
        '/register': (context) => const RegisterScreen(),
        '/jobs': (context) => const JobOffersScreen(),
        '/createJob': (context) => const CreateJobScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/editProfile': (context) => const EditProfileScreen(),
      },
    );
  }
}
