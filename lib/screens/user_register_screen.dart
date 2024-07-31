import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:vacantes/api_service.dart';

class UserRegisterScreen extends StatefulWidget {
  const UserRegisterScreen({super.key});

  @override
  UserRegisterScreenState createState() => UserRegisterScreenState();
}

class UserRegisterScreenState extends State<UserRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _confirmCorreoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmContrasenaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _codigoVerificacionController = TextEditingController();

  bool _experiencia = false;
  int? _selectedEstado;
  int? _selectedMunicipio;
  int? _selectedInfoDivulgacion;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isButtonDisabled = true;
  bool _isLoading = false;
  bool _acceptedPrivacyTerms = false;
  bool _confirmCorreoTouched = false;
  bool _confirmContrasenaTouched = false;
  Timer? _timer;
  int _endTime = DateTime.now().millisecondsSinceEpoch + 1000 * 180;

  List<dynamic> _estados = [];
  List<dynamic> _municipios = [];
  List<dynamic> _infoDivulgacion = [];
  String? _verificationError;
  String? _correoError;
  String? _contrasenaError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      final estados = await ApiService().getEstados();
      final infoDivulgacion = await ApiService().getInfoDivulgacion();

      setState(() {
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
      setState(() {
        _isLoading = true;
      });

      final userData = {
        "nombre": _nombreController.text,
        "correo": _correoController.text,
        "contrasena": _contrasenaController.text,
        "telefono": _telefonoController.text,
        "experiencia": _experiencia,
        "fechaNacimiento": _fechaNacimientoController.text,
        "rol": {"id": 2}, // Asignar rol id 2 (usuario)
        "estado": {"id": _selectedEstado},
        "municipio": {"id": _selectedMunicipio},
        "infoDivulgacion": {"id": _selectedInfoDivulgacion},
      };

      ApiService().registerUser(userData).then((response) {
        final userId = response['id'];
        _showVerificationDialog(userId);
      }).catchError((error) {
        setState(() {
          _isLoading = false;
        });

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
    ).then((_) {
      setState(() {
        _isLoading = false;
        _formKey.currentState!.reset();
        _nombreController.clear();
        _correoController.clear();
        _confirmCorreoController.clear();
        _contrasenaController.clear();
        _confirmContrasenaController.clear();
        _telefonoController.clear();
        _fechaNacimientoController.clear();
        _codigoVerificacionController.clear();
        _experiencia = false;
        _selectedEstado = null;
        _selectedMunicipio = null;
        _selectedInfoDivulgacion = null;
        _acceptedPrivacyTerms = false;
      });
    });
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
      Navigator.pushReplacementNamed(context, '/login');
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

  bool _isFormValid() {
    return _nombreController.text.isNotEmpty &&
        _correoController.text.isNotEmpty &&
        _confirmCorreoController.text.isNotEmpty &&
        _correoController.text == _confirmCorreoController.text &&
        _contrasenaController.text.isNotEmpty &&
        _confirmContrasenaController.text.isNotEmpty &&
        _contrasenaController.text == _confirmContrasenaController.text &&
        _telefonoController.text.isNotEmpty &&
        _fechaNacimientoController.text.isNotEmpty &&
        _selectedEstado != null &&
        _selectedMunicipio != null &&
        _selectedInfoDivulgacion != null &&
        _acceptedPrivacyTerms;
  }

  void _checkCorreoMatch() {
    setState(() {
      if (_correoController.text != _confirmCorreoController.text) {
        _correoError = 'Los correos no coinciden';
      } else {
        _correoError = null;
      }
    });
  }

  void _checkContrasenaMatch() {
    setState(() {
      if (_contrasenaController.text != _confirmContrasenaController.text) {
        _contrasenaError = 'Las contraseñas no coinciden';
      } else {
        _contrasenaError = null;
      }
    });
  }

  void _showPrivacyTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Términos de privacidad'),
          content: const SingleChildScrollView(
            child: Text(
              'Estos son los términos de privacidad genéricos. '
              'Por favor, revise estos términos cuidadosamente antes de aceptar.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _confirmCorreoController.dispose();
    _contrasenaController.dispose();
    _confirmContrasenaController.dispose();
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
        backgroundColor: Colors.greenAccent,
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.greenAccent, width: 2.0),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color.fromARGB(255, 68, 202, 255), width: 2.0),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
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
                    decoration: InputDecoration(
                      labelText: 'Correo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.greenAccent, width: 2.0),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color.fromARGB(255, 68, 202, 255), width: 2.0),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su correo';
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Por favor ingrese un correo válido';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _checkCorreoMatch();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        setState(() {
                          _confirmCorreoTouched = true;
                          _checkCorreoMatch();
                        });
                      }
                    },
                    child: TextFormField(
                      controller: _confirmCorreoController,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Correo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.greenAccent, width: 2.0),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color.fromARGB(255, 68, 202, 255), width: 2.0),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor confirme su correo';
                        } else if (value != _correoController.text) {
                          return 'Los correos no coinciden';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _checkCorreoMatch();
                        });
                      },
                    ),
                  ),
                  if (_confirmCorreoTouched && _correoError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _correoError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contrasenaController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.greenAccent, width: 2.0),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color.fromARGB(255, 68, 202, 255), width: 2.0),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      prefixIcon: const Icon(Icons.lock),
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
                    onChanged: (value) {
                      setState(() {
                        _checkContrasenaMatch();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        setState(() {
                          _confirmContrasenaTouched = true;
                          _checkContrasenaMatch();
                        });
                      }
                    },
                    child: TextFormField(
                      controller: _confirmContrasenaController,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.greenAccent, width: 2.0),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color.fromARGB(255, 68, 202, 255), width: 2.0),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _confirmPasswordVisible = !_confirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_confirmPasswordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor confirme su contraseña';
                        } else if (value != _contrasenaController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _checkContrasenaMatch();
                        });
                      },
                    ),
                  ),
                  if (_confirmContrasenaTouched && _contrasenaError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _contrasenaError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telefonoController,
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.greenAccent, width: 2.0),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color.fromARGB(255, 68, 202, 255), width: 2.0),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
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
                          decoration: InputDecoration(
                            labelText: 'Fecha de Nacimiento (Año-mes-día)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.greenAccent, width: 2.0),
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color.fromARGB(255, 68, 202, 255), width: 2.0),
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese su fecha de nacimiento';
                            } else if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
                              return 'Ingresa tu fecha de nacimiento con el formato Año-mes-día';
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
                    value: _selectedEstado,
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.greenAccent, width: 2.0),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color.fromARGB(255, 68, 202, 255), width: 2.0),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
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
                    decoration: InputDecoration(
                      labelText: 'Municipio',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.greenAccent, width: 2.0),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color.fromARGB(255, 68, 202, 255), width: 2.0),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    items: _municipios.map<DropdownMenuItem<int>>((municipio) {
                      return DropdownMenuItem<int>(
                        value: municipio['id'],
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                          child: Text(
                            municipio['nombre'],
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
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
                    decoration: InputDecoration(
                      labelText: '¿Cómo conociste la aplicación?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.greenAccent, width: 2.0),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color.fromARGB(255, 68, 202, 255), width: 2.0),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
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
                  const Text('¿Tienes experiencia trabajando en tiendas departamentales? Como Palacio de Hierro, Liverpool, Coppel, Sears, etc'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
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
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: _acceptedPrivacyTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptedPrivacyTerms = value!;
                      });
                    },
                    title: GestureDetector(
                      onTap: () => _showPrivacyTerms(context),
                      child: const Text(
                        'Aceptar términos de privacidad',
                        style: TextStyle(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isFormValid() ? _submitForm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid() ? const Color.fromARGB(255, 68, 202, 255) : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text('Registrarse'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
