import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tramites_mobile/core/services/api_service.dart';
import 'package:tramites_mobile/core/services/auth_service.dart';

class IniciarTramiteScreen extends StatefulWidget {
  const IniciarTramiteScreen({super.key});

  @override
  State<IniciarTramiteScreen> createState() => _IniciarTramiteScreenState();
}

class _IniciarTramiteScreenState extends State<IniciarTramiteScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isLoadingCampos = false;
  bool _isSaving = false;
  String? _error;

  List<dynamic> _politicas = const [];
  dynamic _selectedPolitica;

  // campos provenientes de actividades[0].formulario.campos
  List<Map<String, dynamic>> _campos = const [];
  // un controller por cada campo.nombre
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _cargarPoliticas();
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _resetControllers(List<Map<String, dynamic>> campos) {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    _controllers.clear();
    for (final campo in campos) {
      final nombre = campo['nombre']?.toString() ?? '';
      if (nombre.isNotEmpty) {
        _controllers[nombre] = TextEditingController();
      }
    }
  }

  Future<void> _cargarPoliticas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await context.read<ApiService>().dio.get<List<dynamic>>(
        '/politicas',
      );
      final politicas = response.data ?? const [];
      setState(() {
        _politicas = politicas;
      });
      if (politicas.isNotEmpty) {
        await _seleccionarPolitica(politicas.first);
      }
    } catch (error) {
      setState(() {
        _error = AuthService.mapError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _seleccionarPolitica(dynamic politica) async {
    final id = _idDe(politica);
    setState(() {
      _selectedPolitica = politica;
      _isLoadingCampos = true;
      _error = null;
      _campos = const [];
    });

    try {
      final response = await context
          .read<ApiService>()
          .dio
          .get<Map<String, dynamic>>('/politicas/$id');

      // ignore: avoid_print
      print('POLITICA DETALLE: ${response.data}');

      final data = response.data ?? {};
      List<Map<String, dynamic>> campos = _extraerCampos(data);

      _resetControllers(campos);
      setState(() {
        _campos = campos;
      });
    } catch (error) {
      setState(() {
        _error = AuthService.mapError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCampos = false;
        });
      }
    }
  }

  Future<void> _confirmar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final politicaId = _idDe(_selectedPolitica);
      final datosCliente = {
        for (final entry in _controllers.entries)
          entry.key: entry.value.text.trim(),
      };

      await context.read<ApiService>().dio.post<void>(
        '/tramites',
        data: {'politicaId': politicaId, 'datos': datosCliente},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trámite iniciado exitosamente')),
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
      appBar: AppBar(title: const Text('Iniciar trámite')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<dynamic>(
                            value: _selectedPolitica,
                            items:
                                _politicas
                                    .map(
                                      (p) => DropdownMenuItem<dynamic>(
                                        value: p,
                                        child: Text(_nombrePolitica(p)),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (_isSaving || _isLoadingCampos)
                                    ? null
                                    : (value) {
                                      if (value != null) {
                                        _seleccionarPolitica(value);
                                      }
                                    },
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Selecciona una política'
                                        : null,
                            decoration: const InputDecoration(
                              labelText: 'Política',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 8),
                          if (_isLoadingCampos)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_campos.isEmpty && _error == null)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Esta política no tiene campos configurados.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else ...[
                            Text(
                              'Datos del trámite',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            ..._campos.map((campo) => _buildCampo(campo)),
                          ],
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          if (!_isLoadingCampos && _campos.isNotEmpty)
                            FilledButton(
                              onPressed: _isSaving ? null : _confirmar,
                              child:
                                  _isSaving
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Text('Confirmar'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  static const List<Map<String, dynamic>> _camposPorDefecto = [
    {'nombre': 'Nombre Completo', 'tipo': 'TEXT', 'requerido': true},
    {'nombre': 'Numero de Celular', 'tipo': 'NUMBER', 'requerido': true},
    {'nombre': 'Cedula de Identidad', 'tipo': 'TEXT', 'requerido': true},
    {'nombre': 'Direccion de Domicilio', 'tipo': 'TEXT', 'requerido': true},
    {'nombre': 'Descripcion', 'tipo': 'TEXT', 'requerido': false},
  ];

  List<Map<String, dynamic>> _extraerCampos(Map<String, dynamic> data) {
    List<dynamic>? _listaDe(dynamic value) =>
        value is List && value.isNotEmpty ? value : null;

    final actividades = data['actividades'];
    final primerActividad =
        actividades is List && actividades.isNotEmpty
            ? actividades[0] as Map<String, dynamic>?
            : null;

    final candidatos = [
      primerActividad?['formulario'] is Map
          ? primerActividad!['formulario']['campos']
          : null,
      data['formularioInicial'] is Map
          ? data['formularioInicial']['campos']
          : null,
      data['campos'],
      primerActividad?['campos'],
    ];

    for (final candidato in candidatos) {
      final lista = _listaDe(candidato);
      if (lista != null) {
        return lista.whereType<Map<String, dynamic>>().toList();
      }
    }

    return _camposPorDefecto;
  }

  Widget _buildCampo(Map<String, dynamic> campo) {
    final nombre = campo['nombre']?.toString() ?? '';
    final tipo = campo['tipo']?.toString().toUpperCase() ?? 'TEXT';
    final requerido = campo['requerido'] == true;
    final ctrl = _controllers[nombre];

    if (ctrl == null) return const SizedBox.shrink();

    final keyboardType = switch (tipo) {
      'NUMBER' => TextInputType.number,
      'DATE' => TextInputType.datetime,
      _ => TextInputType.text,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        enabled: !_isSaving,
        decoration: InputDecoration(
          labelText: _toLabel(nombre),
          border: const OutlineInputBorder(),
          helperText: tipo == 'DATE' ? 'Formato: YYYY-MM-DD' : null,
        ),
        validator:
            requerido
                ? (value) =>
                    (value == null || value.trim().isEmpty)
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

  String _nombrePolitica(dynamic politica) {
    if (politica is Map<String, dynamic>) {
      return (politica['nombre'] ??
              politica['titulo'] ??
              politica['id'] ??
              'Política')
          .toString();
    }
    return politica.toString();
  }

  dynamic _idDe(dynamic politica) {
    if (politica is Map<String, dynamic>) return politica['id'];
    return politica;
  }
}
