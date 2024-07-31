import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vacantes/api_service.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();

  bool _experiencia = false;
  int? _selectedEstado;
  int? _selectedMunicipio;
  bool _passwordVisible = false;

  List<dynamic> _estados = [];
  List<dynamic> _municipios = [];

  bool _isLoading = false;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadEstados();
  }

  Future<void> _loadEstados() async {
    try {
      final estados = await ApiService().getEstados();
      if (!mounted) return;
      setState(() {
        _estados = estados;
      });
    } catch (e) {
      logger.e('Failed to load estados: $e');
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        throw Exception('Id de usuario no encontrado');
      }

      final parsedUserId = int.tryParse(userId) ?? -1;
      if (parsedUserId == -1) {
        throw Exception('Id de usuario no válido');
      }

      final userData = await ApiService().getUserData(parsedUserId);
      if (!mounted) return;

      setState(() {
        _userData = userData;
        _nombreController.text = utf8.decode(userData['nombre'].runes.toList());
        _telefonoController.text = userData['telefono'] ?? '';
        _experiencia = userData['experiencia'] ?? false;
        _fechaNacimientoController.text = userData['fechaNacimiento'] ?? '';
        _selectedEstado = userData['estado']?['id'];
        _selectedMunicipio = userData['municipio']?['id'];
      });

      if (_selectedEstado != null) {
        _loadMunicipios(_selectedEstado!);
      }
    } catch (e) {
      logger.e('Failed to load user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos del usuario: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMunicipios(int estadoId) async {
    try {
      final municipios = await ApiService().getMunicipios(estadoId);
      if (!mounted) return;
      setState(() {
        _municipios = municipios;
      });
    } catch (e) {
      logger.e('Failed to load municipios: $e');
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId');
        final parsedUserId = int.tryParse(userId!) ?? -1;
        if (parsedUserId == -1) {
          throw Exception('Usuario no encontrado');
        }

        final userData = {
          "nombre": _nombreController.text,
          "contrasena": _contrasenaController.text.isNotEmpty ? _contrasenaController.text : null,
          "telefono": _telefonoController.text,
          "experiencia": _experiencia,
          "fechaNacimiento": _fechaNacimientoController.text,
          "estado": {"id": _selectedEstado},
          "municipio": {"id": _selectedMunicipio},
          "correo": _userData['correo'],
          "correoVerificado": _userData['correoVerificado'],
          "codigoVerificacionCorreo": _userData['codigoVerificacionCorreo'],
          "fechaCreacionCodigoVerificacion": _userData['fechaCreacionCodigoVerificacion'],
          "codigoVerificacionContrasena": _userData['codigoVerificacionContrasena'],
          "fechaCreacionCodigoVerificacionContrasena": _userData['fechaCreacionCodigoVerificacionContrasena'],
          "estatus": _userData['estatus'],
          "rol": {"id": _userData['rol']['id']},
          "infoDivulgacion": {"id": _userData['infoDivulgacion']['id']},
        };

        await ApiService().updateUserData(parsedUserId, userData);
        
        await prefs.setString('userName', _nombreController.text.split(' ')[0]);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado con éxito')),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el perfil: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _contrasenaController.dispose();
    _telefonoController.dispose();
    _fechaNacimientoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Colors.greenAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.white,
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
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contrasenaController,
                        decoration: InputDecoration(
                          labelText: 'Contraseña (dejar en blanco si no deseas cambiarla)',
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
                          if (value != null && value.isNotEmpty && value.length < 8) {
                            return 'La contraseña debe tener al menos 8 caracteres';
                          }
                          return null;
                        },
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
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 68, 202, 255),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Actualizar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _fechaNacimientoController.text = picked.toString().split(' ')[0];
      });
    }
  }
}
