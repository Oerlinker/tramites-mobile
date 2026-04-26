import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tramites_mobile/core/models/tramite_model.dart';
import 'package:tramites_mobile/core/services/api_service.dart';
import 'package:tramites_mobile/core/services/auth_service.dart';

class SeguimientoScreen extends StatefulWidget {
  const SeguimientoScreen({super.key, this.tramite});

  final TramiteModel? tramite;

  @override
  State<SeguimientoScreen> createState() => _SeguimientoScreenState();
}

class _SeguimientoScreenState extends State<SeguimientoScreen> {
  bool _isLoading = true;
  String? _error;
  TramiteModel? _tramiteActual;

  @override
  void initState() {
    super.initState();
    _tramiteActual = widget.tramite;
    if (_tramiteActual == null) {
      _cargarUltimoTramite();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _cargarUltimoTramite() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await context.read<ApiService>().dio.get<List<dynamic>>(
        '/tramites/mis-tramites',
      );
      final listado =
          (response.data ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(TramiteModel.fromJson)
              .toList();

      setState(() {
        _tramiteActual = listado.isNotEmpty ? listado.first : null;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shadowColor: Colors.black12,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Text(_error!, style: const TextStyle(color: Colors.red))
                    : _tramiteActual == null
                    ? const Text('No se encontro informacion del tramite.')
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _tramiteActual!.nombre ??
                              _tramiteActual!.politica ??
                              'Tramite',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        Text('ID: ${_tramiteActual!.id}'),
                        Text('Estado actual: ${_tramiteActual!.estado}'),
                        if (_tramiteActual!.fechaCreacion != null)
                          Text(
                            'Creado: ${_tramiteActual!.fechaCreacion!.toLocal()}',
                          ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
