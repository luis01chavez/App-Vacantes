class JobOffer {
  final int id;
  final String titulo;
  final String descripcion;

  JobOffer({
    required this.id,
    required this.titulo,
    required this.descripcion,
  });

  factory JobOffer.fromJson(Map<String, dynamic> json) {
    return JobOffer(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
    );
  }
}

class JobDetail {
  final String titulo;
  final String descripcion;
  final String imagen;
  final List<String> estados;
  final List<String> municipios;
  final String usuario;

  JobDetail({
    required this.titulo,
    required this.descripcion,
    required this.imagen,
    required this.estados,
    required this.municipios,
    required this.usuario,
  });

  factory JobDetail.fromJson(Map<String, dynamic> json) {
    return JobDetail(
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      imagen: json['imagen'],
      estados: List<String>.from(json['estados'].map((estado) => estado['nombre'])),
      municipios: List<String>.from(json['municipios'].map((municipio) => municipio['nombre'])),
      usuario: json['usuario']['nombre'],
    );
  }
}