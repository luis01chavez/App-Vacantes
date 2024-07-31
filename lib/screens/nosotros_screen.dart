import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NosotrosScreen extends StatefulWidget {
  const NosotrosScreen({super.key});

  @override
  NosotrosScreenState createState() => NosotrosScreenState();
}

class NosotrosScreenState extends State<NosotrosScreen> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    setState(() {
      _isLoggedIn = authToken != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nosotros'),
        backgroundColor: Colors.greenAccent,
        actions: [
          if (!_isLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: const Color.fromARGB(255, 68, 202, 255), // Texto blanco
                  textStyle: const TextStyle(fontSize: 18), // Texto más grande
                ),
                child: const Text('Continuar'),
              ),
            ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Aquí va la información sobre nosotros.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
