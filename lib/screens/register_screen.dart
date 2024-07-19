import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:vacantes/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _codigoVerificacionController = TextEditingController();

  bool _experiencia = false;
  int? _selectedRol;
  int? _selectedEstado;
  int? _selectedMunicipio;
  int? _selectedInfoDivulgacion;
  bool _passwordVisible = false;
  bool _isButtonDisabled = true;
  Timer? _timer;
  int _endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 180;

  List<dynamic> _roles = [];
  List<dynamic> _estados = [];
  List<dynamic> _municipios = [];
  List<dynamic> _infoDivulgacion = [];
  String? _verificationError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final roles = await ApiService().getRoles();
      final estados = await ApiService().getEstados();
      final infoDivulgacion = await ApiService().getInfoDivulgacion();

      setState(() {
        _roles = roles;
        _estados = estados;
        _infoDivulgacion = infoDivulgacion;
      });
    } catch (e) {
      logger.e('Failed to load data: $e');
    }
  }

  void _loadMunicipios(int estadoId) async {
    try {
      final municipios = await ApiService().getMunicipios(estadoId);
      setState(() {
        _municipios = municipios;
      });
    } catch (e) {
      logger.e('Failed to load municipios: $e');
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaNacimientoController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final userData = {
        "nombre": _nombreController.text,
        "correo": _correoController.text,
        "contrasena": _contrasenaController.text,
        "telefono": _telefonoController.text,
        "experiencia": _experiencia,
        "fechaNacimiento": _fechaNacimientoController.text,
        "rol": {"id": _selectedRol},
        "estado": {"id": _selectedEstado},
        "municipio": {"id": _selectedMunicipio},
        "infoDivulgacion": {"id": _selectedInfoDivulgacion},
      };

      ApiService().registerUser(userData).then((response) {
        final userId = response['id'];
        _showVerificationDialog(userId);
      }).catchError((error) {
        if (error.toString().contains('400')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Este correo electrónico ya se encuentra registrado en la aplicación!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fallo al registrar usuario: $error')),
          );
        }
      });
    }
  }

  void _showVerificationDialog(int userId) {
    _startTimer();
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

  void _startTimer() {
    setState(() {
      _endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 180;
      _isButtonDisabled = true;
    });
  }

  void _verifyEmail(int userId, String codigo, StateSetter setState) {
    ApiService().verifyEmail(userId, codigo).then((_) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo verificado con éxito')),
      );
      _loginUser(_correoController.text, _contrasenaController.text);
    }).catchError((error) {
      setState(() {
        _verificationError = 'Código incorrecto o caducado';
      });
    });
  }

  void _resendVerificationCode(int userId, StateSetter setState) {
    ApiService().resendVerificationCode(userId).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código reenviado con éxito')),
      );
      setState(() {
        _startTimer();
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fallo al reenviar código: $error')),
      );
    });
  }

  Future<void> _loginUser(String correo, String contrasena) async {
    try {
      final token = await ApiService().loginUser(correo, contrasena);
      await _storeToken(token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful')),
      );
      Navigator.pushReplacementNamed(context, '/');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to login: $error')),
      );
    }
  }

  Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  bool _isFormValid() {
    return _nombreController.text.isNotEmpty &&
        _correoController.text.isNotEmpty &&
        _contrasenaController.text.isNotEmpty &&
        _telefonoController.text.isNotEmpty &&
        _fechaNacimientoController.text.isNotEmpty &&
        _selectedRol != null &&
        _selectedEstado != null &&
        _selectedMunicipio != null &&
        _selectedInfoDivulgacion != null;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    _telefonoController.dispose();
    _fechaNacimientoController.dispose();
    _codigoVerificacionController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrarse'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su nombre';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _correoController,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su correo';
                    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Por favor ingrese un correo válido';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contrasenaController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_passwordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su contraseña';
                    } else if (value.length < 8) {
                      return 'La contraseña debe tener al menos 8 caracteres';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese su teléfono';
                    } else if (value.length != 10) {
                      return 'El teléfono debe tener 10 dígitos';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fechaNacimientoController,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Nacimiento (YYYY-MM-DD)',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese su fecha de nacimiento';
                          } else if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
                            return 'Ingresa tu fecha de nacimiento con el formato YYYY-MM-DD';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedRol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: _roles.map<DropdownMenuItem<int>>((role) {
                    return DropdownMenuItem<int>(
                      value: role['id'],
                      child: Text(role['nombre']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRol = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor seleccione un rol';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedEstado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: _estados.map<DropdownMenuItem<int>>((estado) {
                    return DropdownMenuItem<int>(
                      value: estado['id'],
                      child: Text(estado['nombre']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedEstado = value;
                      _municipios = [];
                      _selectedMunicipio = null;
                      _loadMunicipios(value!);
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor seleccione un estado';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedMunicipio,
                  decoration: const InputDecoration(labelText: 'Municipio'),
                  items: _municipios.map<DropdownMenuItem<int>>((municipio) {
                    return DropdownMenuItem<int>(
                      value: municipio['id'],
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                        child: Text(
                          municipio['nombre'],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMunicipio = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor seleccione un municipio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedInfoDivulgacion,
                  decoration: const InputDecoration(labelText: 'Info Divulgación'),
                  items: _infoDivulgacion.map<DropdownMenuItem<int>>((info) {
                    return DropdownMenuItem<int>(
                      value: info['id'],
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                        child: Text(
                          info['nombre'],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedInfoDivulgacion = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor seleccione una opción de info divulgación';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Experiencia: '),
                    Expanded(
                      child: ListTile(
                        title: const Text('Sí'),
                        leading: Radio<bool>(
                          value: true,
                          groupValue: _experiencia,
                          onChanged: (bool? value) {
                            setState(() {
                              _experiencia = value!;
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('No'),
                        leading: Radio<bool>(
                          value: false,
                          groupValue: _experiencia,
                          onChanged: (bool? value) {
                            setState(() {
                              _experiencia = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isFormValid() ? _submitForm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid() ? Colors.blue : Colors.grey,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    'Registrarse',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
