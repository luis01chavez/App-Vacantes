import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vacantes/api_service.dart';
import 'package:vacantes/models/job_offer.dart';
import 'package:photo_view/photo_view.dart';

class JobDetailScreen extends StatelessWidget {
  final int jobId;

  const JobDetailScreen({super.key, required this.jobId});

  Future<JobDetail> _fetchJobDetail() async {
    return await ApiService().fetchJobDetail(jobId);
  }

  Future<String> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole') ?? '';
  }

  Future<void> _postularme(int empleoId, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      await ApiService().postularme(empleoId, int.parse(userId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te has postulado exitosamente')),
      );
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    }
  }

  Future<void> _noMeInteresa(int empleoId, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      await ApiService().interactWithJob(empleoId, int.parse(userId), 'NO_ME_INTERESA');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interacción registrada')),
      );
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    }
  }

  Future<void> _retirarPublicacion(int empleoId, BuildContext context) async {
    try {
      await ApiService().retirarPublicacion(empleoId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicación retirada exitosamente')),
      );
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al retirar publicación: $e')),
      );
    }
  }

  void _showFullScreenImage(BuildContext context, String imageBase64) {
    showDialog(
      context: context,
      barrierDismissible: true, // Permitir que se cierre al hacer clic fuera del diálogo
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
              Center(
                child: PhotoView(
                  imageProvider: MemoryImage(base64Decode(imageBase64)),
                  backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Empleo'),
      ),
      body: FutureBuilder<JobDetail>(
        future: _fetchJobDetail(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No se encontraron datos'));
          } else {
            final jobDetail = snapshot.data!;
            return FutureBuilder<String>(
              future: _getUserRole(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (roleSnapshot.hasError) {
                  return Center(child: Text('Error: ${roleSnapshot.error}'));
                } else if (!roleSnapshot.hasData) {
                  return const Center(child: Text('No se encontró el rol del usuario'));
                } else {
                  final userRole = roleSnapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              jobDetail.titulo,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            jobDetail.descripcion,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          if (jobDetail.imagen.isNotEmpty)
                            GestureDetector(
                              onTap: () => _showFullScreenImage(context, jobDetail.imagen),
                              child: Container(
                                color: Colors.transparent, // Fondo transparente detrás de la imagen
                                child: Image.memory(
                                  base64Decode(jobDetail.imagen),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          if (userRole == 'admin')
                            Center(
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await _retirarPublicacion(jobDetail.id, context);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error al retirar publicación: $e')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retirar publicación'),
                              ),
                            ),
                          const SizedBox(height: 16),
                          if (userRole == 'usuario')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await _postularme(jobDetail.id, context);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error al postularse: $e')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Postularme'),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await _noMeInteresa(jobDetail.id, context);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error al registrar interacción: $e')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('No me interesa'),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          const Text('Publicado por:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(jobDetail.usuario),
                          if (userRole == 'admin') ...[
                            const SizedBox(height: 16),
                            const Text('Estados:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...jobDetail.estados.map((estado) => Text(estado)),
                            const SizedBox(height: 16),
                            const Text('Municipios:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...jobDetail.municipios.map((municipio) => Text(municipio)),
                          ],
                        ],
                      ),
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}
