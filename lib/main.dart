import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_screen.dart';
import 'screens/create_job_screen.dart';
import 'screens/job_offers_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/forgot_password.dart';
import 'screens/user_register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await checkLoginStatus();
  runApp(JobOffersApp(isLoggedIn: isLoggedIn));
}

Future<bool> checkLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  final authToken = prefs.getString('authToken');
  return authToken != null;
}

class JobOffersApp extends StatelessWidget {
  final bool isLoggedIn;

  const JobOffersApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ay trabajo!',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: isLoggedIn ? '/' : '/login',
      routes: {
        '/': (context) => const MainScreen(),
        '/login': (context) => const AuthScreen(),
        '/register': (context) => const RegisterScreen(),
        '/user-register': (context) => const UserRegisterScreen(),
        '/jobs': (context) => const JobOffersScreen(),
        '/createJob': (context) => const CreateJobScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/editProfile': (context) => const EditProfileScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}
