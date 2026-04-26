class ActividadModel {
  const ActividadModel({
    required this.id,
    required this.estado,
    this.nombre,
    this.nombreDepartamento,
    this.tramiteId,
    this.campos = const [],
  });

  final String id;
  final String estado;
  final String? nombre;
  final String? nombreDepartamento;
  final String? tramiteId;
  final List<Map<String, dynamic>> campos;

  factory ActividadModel.fromJson(Map<String, dynamic> json) {
    final rawCampos = json['formularioDefinicion'];
    final campos =
        rawCampos is List
            ? rawCampos.whereType<Map<String, dynamic>>().toList()
            : const <Map<String, dynamic>>[];

    return ActividadModel(
      id: (json['id'] ?? '').toString(),
      estado: (json['estado'] ?? 'PENDIENTE').toString(),
      nombre: json['nombre']?.toString(),
      nombreDepartamento: json['nombreDepartamento']?.toString(),
      tramiteId: json['tramiteId']?.toString(),
      campos: campos,
    );
  }
}
