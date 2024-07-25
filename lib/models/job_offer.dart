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