class TramiteModel {
  const TramiteModel({
    required this.id,
    required this.estado,
    this.nombre,
    this.politica,
    this.fechaCreacion,
  });

  final String id;
  final String estado;
  final String? nombre;
  final String? politica;
  final DateTime? fechaCreacion;

  factory TramiteModel.fromJson(Map<String, dynamic> json) {
    final fechaRaw = json['fechaCreacion'] ?? json['createdAt'];
    return TramiteModel(
      id: (json['id'] ?? '').toString(),
      estado: (json['estado'] ?? 'DESCONOCIDO').toString(),
      nombre: json['nombre']?.toString(),
      politica:
          (json['politicaNombre'] ?? json['politica'] ?? json['nombrePolitica'])
              ?.toString(),
      fechaCreacion:
          fechaRaw != null ? DateTime.tryParse(fechaRaw.toString()) : null,
    );
  }
}
