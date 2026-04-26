import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tramites_mobile/core/models/actividad_model.dart';
import 'package:tramites_mobile/core/services/api_service.dart';
import 'package:tramites_mobile/core/services/auth_service.dart';

class CompletarFormularioScreen extends StatefulWidget {
  const CompletarFormularioScreen({super.key, required this.actividad});

  final ActividadModel actividad;

  @override
  State<CompletarFormularioScreen> createState() =>
      _CompletarFormularioScreenState();
}

class _CompletarFormularioScreenState
    extends State<CompletarFormularioScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String?> _dropdownValues = {};

  bool _isSaving = false;
  String? _error;
  Map<String, dynamic> _datosCliente = const {};
  Map<String, String> _etiquetas = {};

  @override
  void initState() {
    super.initState();
    _cargarDatosCliente();
    for (final campo in widget.actividad.campos) {
      final id = campo['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final tipo = campo['tipo']?.toString().toUpperCase() ?? 'TEXT';
      if (tipo == 'SELECT') {
        _dropdownValues[id] = null;
      } else {
        _textControllers[id] = TextEditingController();
      }
    }
  }

  Future<void> _cargarDatosCliente() async {
    final tramiteId = widget.actividad.tramiteId;
    if (tramiteId == null || tramiteId.isEmpty) return;
    try {
      final response = await context
          .read<ApiService>()
          .dio
          .get<Map<String, dynamic>>('/tramites/$tramiteId');
      final tramite = response.data as Map<String, dynamic>;
      // ignore: avoid_print
      print('TRAMITE DATOS CLIENTE: ${tramite['datos']}');
      final datos = tramite['datos'] as Map<String, dynamic>?
          ?? tramite['datosCliente'] as Map<String, dynamic>?
          ?? {};
      if (datos.isNotEmpty && mounted) {
        setState(() => _datosCliente = datos);
      }

      final politicaId = tramite['politicaId']?.toString();
      if (politicaId == null || politicaId.isEmpty || !mounted) return;
      final politicaResp = await context
          .read<ApiService>()
          .dio
          .get<Map<String, dynamic>>('/politicas/$politicaId');
      final politicaData = politicaResp.data as Map<String, dynamic>;
      final actividades = politicaData['actividades'];
      if (actividades is List && actividades.isNotEmpty) {
        final formularioDefinicion = actividades[0]['formularioDefinicion'];
        if (formularioDefinicion is List && mounted) {
          final etiquetas = <String, String>{};
          for (final campo in formularioDefinicion) {
            if (campo is Map<String, dynamic>) {
              final id = campo['id']?.toString() ?? '';
              final etiqueta = campo['etiqueta']?.toString() ?? '';
              if (id.isNotEmpty && etiqueta.isNotEmpty) {
                etiquetas[id] = etiqueta;
              }
            }
          }
          setState(() => _etiquetas = etiquetas);
        }
      }
    } catch (_) {
      // fallo silencioso — la card simplemente no se muestra
    }
  }

  @override
  void dispose() {
    for (final ctrl in _textControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final respuestas = <String, dynamic>{};
      for (final campo in widget.actividad.campos) {
        final id = campo['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final tipo = campo['tipo']?.toString().toUpperCase() ?? 'TEXT';
        if (tipo == 'SELECT') {
          respuestas[id] = _dropdownValues[id];
        } else {
          respuestas[id] = _textControllers[id]?.text.trim() ?? '';
        }
      }

      await context.read<ApiService>().dio.patch<void>(
        '/actividades/${widget.actividad.id}/formulario',
        data: {'respuestas': respuestas},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formulario guardado correctamente.')),
      );
      context.pop(true);
    } catch (error) {
      setState(() {
        _error = AuthService.mapError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.actividad.nombre ?? 'Completar formulario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_datosCliente.isNotEmpty)
              Card(
                color: const Color(0xFFE8F5E9),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📋 Datos del solicitante',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._datosCliente.entries
                          .where(
                            (e) =>
                                e.value != null &&
                                e.value.toString().isNotEmpty,
                          )
                          .map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 140,
                                    child: Text(
                                      '${_etiquetas[e.key] ?? e.key}:',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF555555),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(e.value.toString()),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            Card(
              elevation: 2,
              shadowColor: Colors.black12,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Estado: ${widget.actividad.estado}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (widget.actividad.campos.isEmpty)
                        const Text(
                          'Esta actividad no tiene campos configurados.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ...widget.actividad.campos.map(_buildCampo),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (widget.actividad.campos.isNotEmpty)
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _guardar,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: const Text('Guardar formulario'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampo(Map<String, dynamic> campo) {
    final id = campo['id']?.toString() ?? '';
    if (id.isEmpty) return const SizedBox.shrink();

    final tipo = campo['tipo']?.toString().toUpperCase() ?? 'TEXT';
    final requerido = campo['requerido'] == true;
    final label = campo['etiqueta']?.toString() ?? id;

    if (tipo == 'SELECT') {
      final opcionesRaw = campo['opciones'];
      final opciones = opcionesRaw is List
          ? opcionesRaw.map((e) => e.toString()).toList()
          : <String>[];

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          value: _dropdownValues[id],
          items: opciones
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: _isSaving
              ? null
              : (value) => setState(() => _dropdownValues[id] = value),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: requerido
              ? (value) => (value == null || value.isEmpty)
                  ? 'Este campo es obligatorio'
                  : null
              : null,
        ),
      );
    }

    final ctrl = _textControllers[id];
    if (ctrl == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType:
            tipo == 'NUMBER' ? TextInputType.number : TextInputType.text,
        maxLines: tipo == 'TEXTAREA' ? 4 : 1,
        enabled: !_isSaving,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: requerido
            ? (value) => (value == null || value.trim().isEmpty)
                ? 'Este campo es obligatorio'
                : null
            : null,
      ),
    );
  }

  String _toLabel(String nombre) {
    final spaced = nombre.replaceAll(RegExp(r'[_\-]'), ' ').trim();
    if (spaced.isEmpty) return nombre;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}
