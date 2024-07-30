import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vacantes/api_service.dart';
import 'package:vacantes/screens/auth_screen.dart';
import 'package:vacantes/screens/edit_profile_screen.dart';
import 'package:vacantes/screens/nosotros_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  String? _firstName;
  bool _correoVerificado = false;
  bool _isLoadingUserData = true;
  int _endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 180;
  final _codigoVerificacionController = TextEditingController();
  String? _verificationError;
  bool _isButtonDisabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchUserData();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName') ?? 'Usuario';
    if (mounted) {
      setState(() {
        _firstName = userName;
      });
    }
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      try {
        final userData = await ApiService().getUserData(int.parse(userId));
        setState(() {
          _correoVerificado = userData['correoVerificado'];
          _isLoadingUserData = false;  // Data has been fetched
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al obtener datos del usuario: $e')),
          );
        }
        setState(() {
          _isLoadingUserData = false;  // Data fetching failed
        });
      }
    } else {
      setState(() {
        _isLoadingUserData = false;  // No userId found
      });
    }
  }

  void _startTimer(int endTime) {
    setState(() {
      _endTime = endTime;
      _isButtonDisabled = true;
    });
  }

  void _showVerificationDialog(int userId) {
    _resendVerificationCode(userId, setState);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Verificación de correo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ingrese el código de verificación que recibió por correo.'),
                  TextField(
                    controller: _codigoVerificacionController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    onChanged: (value) {
                      if (value.length == 6) {
                        _verifyEmail(userId, value, setState);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_verificationError != null)
                    Text(
                      _verificationError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isButtonDisabled ? null : () => _resendVerificationCode(userId, setState),
                    child: const Text('Enviar código de nuevo'),
                  ),
                  const SizedBox(height: 8),
                  CountdownTimer(
                    endTime: _endTime,
                    onEnd: () {
                      setState(() {
                        _isButtonDisabled = false;
                      });
                    },
                    widgetBuilder: (_, time) {
                      if (time == null) {
                        return const Text('Puede enviar un nuevo código');
                      } else {
                        final minutes = time.min ?? 0;
                        final seconds = time.sec ?? 0;
                        return Text(
                          'Espera ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} para reenviar el código',
                          style: const TextStyle(fontSize: 12),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _verifyEmail(int userId, String codigo, StateSetter setState) {
    ApiService().verifyEmail(userId, codigo).then((_) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo verificado con éxito')),
      );
      setState(() {
        _correoVerificado = true;
      });
      Navigator.pushReplacementNamed(context, '/');
    }).catchError((error) {
      setState(() {
        _verificationError = 'Código incorrecto o caducado';
      });
    });
  }

  void _resendVerificationCode(int userId, StateSetter setState) {
    setState(() {
    });

    ApiService().resendVerificationCode(userId).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código reenviado con éxito')),
      );
      _startTimer(DateTime.now().millisecondsSinceEpoch + 1000 * 180);
      setState(() {
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fallo al reenviar código: $error')),
      );
      setState(() {
      });
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token != null) {
      try {
        await ApiService().logout(token);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cerrar sesión: $e')),
          );
        }
      }
    }

    await prefs.remove('authToken');
    await prefs.remove('userId');
    await prefs.remove('userName');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  void _copyDownloadLink() {
    Clipboard.setData(const ClipboardData(text: "Aquí va el futuro link de descarga!"));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Link de descarga copiado!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUserData) {
      // Show loading indicator while fetching user data
      return Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¡Hola $_firstName!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 7,
                          offset: const Offset(4, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                        _loadUserName(); // Reload the name after editing profile
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Mis datos',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 7,
                          offset: const Offset(4, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Cerrar sesión',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!_correoVerificado)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 7,
                            offset: const Offset(4, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final userId = prefs.getString('userId');
                          if (userId != null) {
                            _showVerificationDialog(int.parse(userId));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Verificar correo',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NosotrosScreen()),
                    );
                  },
                  child: const Icon(Icons.help_outline),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: _copyDownloadLink,
                  child: const Icon(Icons.share),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
