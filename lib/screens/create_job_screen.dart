import 'package:flutter/material.dart';


class CreateJobScreen extends StatelessWidget {
  const CreateJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Empleo'),
      ),
      body: const Center(
        child: Text('Formulario para crear un empleo disponible'),
      ),
    );
  }
}
