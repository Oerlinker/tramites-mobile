import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tramites_mobile/core/models/actividad_model.dart';
import 'package:tramites_mobile/core/services/api_service.dart';
import 'package:tramites_mobile/core/services/auth_service.dart';
import 'package:tramites_mobile/core/services/session_service.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  bool _isLoading = true;
  String? _error;
  List<ActividadModel> _actividades = const [];

  @override
  void initState() {
    super.initState();
    _cargarActividades();
  }

  Future<void> _cargarActividades() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await context.read<ApiService>().dio.get<dynamic>(
        '/monitor/mis-actividades',
      );

      final raw = response.data;
      // ignore: avoid_print
      print('MONITOR RESPONSE: $raw');
      final List<dynamic> lista = raw is List ? raw : ((raw as Map<String, dynamic>)['content'] ?? []);

      if (lista.isNotEmpty) {
        // ignore: avoid_print
        print('ACTIVIDAD JSON: ${lista[0]}');
      }

      final actividades =
          lista
              .whereType<Map<String, dynamic>>()
              .map(ActividadModel.fromJson)
              .toList();

      setState(() {
        _actividades = actividades;
      });
    } catch (error) {
      // ignore: avoid_print
      print('MONITOR ERROR: $error');
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await context.read<SessionService>().logout();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Monitor: ${session.user?.nombreMostrado ?? 'Funcionario'}',
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarActividades,
        child:
            _isLoading
                ? ListView(
                  children: [
                    const SizedBox(height: 220),
                    const Center(child: CircularProgressIndicator()),
                  ],
                )
                : _error != null
                ? ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                )
                : _actividades.isEmpty
                ? ListView(
                  children: [
                    const SizedBox(height: 220),
                    const Center(child: Text('No hay actividades asignadas.')),
                  ],
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _actividades.length,
                  itemBuilder: (context, index) {
                    final actividad = _actividades[index];
                    final colorEstado = _colorPorEstado(actividad.estado);

                    return Card(
                      elevation: 2,
                      shadowColor: Colors.black12,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorEstado.withValues(alpha: 0.15),
                          child: Icon(Icons.assignment, color: colorEstado),
                        ),
                        title: Text(
                          actividad.nombre ?? 'Actividad sin nombre',
                        ),
                        subtitle: Text(
                          actividad.nombreDepartamento != null
                              ? '${actividad.nombreDepartamento} · ${actividad.estado}'
                              : actividad.estado,
                        ),
                        trailing: FilledButton(
                          onPressed: () async {
                            final updated = await context.push<bool>(
                              '/funcionario/completar',
                              extra: actividad,
                            );
                            if (updated == true && mounted) {
                              _cargarActividades();
                            }
                          },
                          child: const Text('Atender'),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Color _colorPorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'COMPLETADO':
        return Colors.green;
      case 'EN_PROCESO':
        return Colors.amber.shade700;
      case 'PENDIENTE':
      default:
        return Colors.red;
    }
  }
}
