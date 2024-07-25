import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vacantes/api_service.dart';
import 'package:vacantes/models/job_offer.dart';

class JobDetailScreen extends StatelessWidget {
  final int jobId;

  const JobDetailScreen({super.key, required this.jobId});

  Future<JobDetail> _fetchJobDetail() async {
    return await ApiService().fetchJobDetail(jobId);
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
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobDetail.titulo,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(jobDetail.descripcion),
                    const SizedBox(height: 16),
                    if (jobDetail.imagen.isNotEmpty)
                      Image.memory(base64Decode(jobDetail.imagen)),
                    const SizedBox(height: 16),
                    const Text('Estados:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...jobDetail.estados.map((estado) => Text(estado)),
                    const SizedBox(height: 16),
                    const Text('Municipios:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...jobDetail.municipios.map((municipio) => Text(municipio)),
                    const SizedBox(height: 16),
                    const Text('Publicado por:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(jobDetail.usuario),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
