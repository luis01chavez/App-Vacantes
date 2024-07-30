import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vacantes/screens/nosotros_screen.dart';
import 'job_offers_screen.dart';
import 'create_job_screen.dart';
import 'register_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _getUserRole();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    if (!mounted) return;

    if (authToken == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const NosotrosScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole');
    setState(() {
      userRole = role;
    });
  }

  List<Widget> _getWidgetOptions() {
    if (userRole == 'admin') {
      return const [
        JobOffersScreen(),
        CreateJobScreen(),
        RegisterScreen(),
        ProfileScreen(),
      ];
    } else {
      return const [
        JobOffersScreen(),
        ProfileScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getBottomNavigationBarItems() {
    if (userRole == 'admin') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.work),
          label: 'Empleos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.create),
          label: 'Crear Empleo',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Registrarse',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Perfil',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.work),
          label: 'Empleos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Perfil',
        ),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final widgetOptions = _getWidgetOptions();
    final bottomNavigationBarItems = _getBottomNavigationBarItems();

    return Scaffold(
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: bottomNavigationBarItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}
