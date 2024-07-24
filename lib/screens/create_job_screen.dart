import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vacantes/api_service.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  CreateJobScreenState createState() => CreateJobScreenState();
}

class CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _fechaCaducidadController = TextEditingController();
  final List<int> _selectedEstados = [];
  final List<int> _selectedMunicipios = [];
  Uint8List? _imagenBytes;
  String _imagenBase64 = '';
  List<dynamic> _estados = [];
  bool _isLoading = false;
  int? _selectedEstadoTemp;
  int? _selectedMunicipioTemp;

  Map<int, List<dynamic>> _municipiosPorEstado = {};

  @override
  void initState() {
    super.initState();
    _loadEstados();
  }

  Future<void> _loadEstados() async {
    try {
      final estados = await ApiService().getEstados();
      if (mounted) {
        setState(() {
          _estados = estados;
        });
      }
    } catch (e) {
      logger.e('Error al cargar estados: $e');
    }
  }

  Future<void> _loadMunicipios(List<int> estadoIds) async {
    try {
      Map<int, List<dynamic>> municipiosPorEstado = {};
      for (var estadoId in estadoIds) {
        final municipios = await ApiService().getMunicipios(estadoId);
        municipiosPorEstado[estadoId] = municipios;
      }
      if (mounted) {
        setState(() {
          _municipiosPorEstado = municipiosPorEstado;
        });
      }
    } catch (e) {
      logger.e('Error al cargar municipios: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      if (mounted) {
        setState(() {
          _fechaCaducidadController.text = DateFormat('yyyy-MM-dd').format(picked);
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _imagenBytes = bytes;
          _imagenBase64 = base64Encode(bytes);
        });
      }
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedEstados.isNotEmpty && _imagenBase64.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      final jobData = {
        "titulo": _tituloController.text,
        "descripcion": _descripcionController.text,
        "imagen": _imagenBase64,
        "fechaCaducidad": _fechaCaducidadController.text,
        "estados": _selectedEstados.map((id) => {"id": id}).toList(),
        "municipios": _selectedMunicipios.map((id) => {"id": id}).toList(),
        "usuario": {"id": int.parse(userId!)}
      };

      try {
        await ApiService().createJob(jobData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El empleo ha sido publicado')),
          );
          _clearForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear empleo: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un estado y sube una imagen')),
      );
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _tituloController.clear();
    _descripcionController.clear();
    _fechaCaducidadController.clear();
    setState(() {
      _selectedEstados.clear();
      _selectedMunicipios.clear();
      _imagenBytes = null;
      _imagenBase64 = '';
      _selectedEstadoTemp = null;
      _selectedMunicipioTemp = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Empleo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLength: 300,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa la descripción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fechaCaducidadController,
                  decoration: const InputDecoration(
                    labelText: 'Fecha de caducidad',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor selecciona una fecha de caducidad';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Seleccionar Imagen'),
                ),
                if (_imagenBytes != null) ...[
                  const SizedBox(height: 16),
                  Center(child: Image.memory(_imagenBytes!, height: 200)),
                  const SizedBox(height: 8),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _imagenBytes = null;
                          _imagenBase64 = '';
                        });
                      },
                      child: const Text('Eliminar Imagen'),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Estados:'),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Selecciona un estado'),
                  value: _selectedEstadoTemp,
                  items: _estados.map<DropdownMenuItem<int>>((estado) {
                    return DropdownMenuItem<int>(
                      value: estado['id'],
                      child: Text(estado['nombre']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && !_selectedEstados.contains(value)) {
                      setState(() {
                        _selectedEstados.add(value);
                        _selectedEstadoTemp = null;
                      });
                      _formKey.currentState?.reset();
                      _loadMunicipios(_selectedEstados);
                    }
                  },
                  onTap: () {
                    _formKey.currentState?.reset();
                  },
                ),
                const SizedBox(height: 8), // Espacio adicional
                Wrap(
                  spacing: 8.0,
                  children: _selectedEstados.map((estadoId) {
                    final estado = _estados.firstWhere((estado) => estado['id'] == estadoId);
                    return Chip(
                      label: Text(estado['nombre']),
                      onDeleted: () {
                        setState(() {
                          _selectedEstados.remove(estadoId);
                          _selectedMunicipios.removeWhere((municipioId) {
                            final municipio = _municipiosPorEstado[estadoId]?.firstWhere((m) => m['id'] == municipioId, orElse: () => null);
                            return municipio != null;
                          });
                          _selectedMunicipioTemp = null;
                          _formKey.currentState?.reset();
                          _municipiosPorEstado.remove(estadoId);
                          _loadMunicipios(_selectedEstados);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Municipios:'),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Selecciona un municipio'),
                  value: _selectedMunicipioTemp,
                  items: _selectedEstados.expand((estadoId) {
                    final municipios = _municipiosPorEstado[estadoId] ?? [];
                    return municipios.map<DropdownMenuItem<int>>((municipio) {
                      return DropdownMenuItem<int>(
                        value: municipio['id'],
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                          child: Text(
                            "${_estados.firstWhere((e) => e['id'] == estadoId)['nombre']}: ${municipio['nombre']}",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                          ),
                        ),
                      );
                    }).toList();
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && !_selectedMunicipios.contains(value)) {
                      setState(() {
                        _selectedMunicipios.add(value);
                        _selectedMunicipioTemp = null;
                      });
                      _formKey.currentState?.reset();
                    }
                  },
                  onTap: () {
                    _formKey.currentState?.reset();
                  },
                ),
                const SizedBox(height: 8), // Espacio adicional
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _selectedEstados.expand((estadoId) {
                    final estado = _estados.firstWhere((estado) => estado['id'] == estadoId);
                    final municipios = _selectedMunicipios.where((municipioId) {
                      final municipio = _municipiosPorEstado[estadoId]?.firstWhere((m) => m['id'] == municipioId, orElse: () => null);
                      return municipio != null;
                    }).toList();
                    return [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(estado['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Wrap(
                        spacing: 8.0,
                        children: municipios.map((municipioId) {
                          final municipio = _municipiosPorEstado[estadoId]?.firstWhere((m) => m['id'] == municipioId);
                          return SizedBox(
                            child: Chip(
                              label: Text(
                                municipio['nombre'],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 3,
                              ),
                              onDeleted: () {
                                setState(() {
                                  _selectedMunicipios.remove(municipioId);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ];
                  }).toList(),
                ),

                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding adicional para que no toque los bordes
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0), // Aumenta el padding vertical para un botón más grande
                          child: Text(
                            'Crear Empleo',
                            style: TextStyle(fontSize: 18), // Ajusta el tamaño del texto
                          ),
                        ),
                      ),
                    ),
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
