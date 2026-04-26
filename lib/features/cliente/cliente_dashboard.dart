import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tramites_mobile/core/models/tramite_model.dart';
import 'package:tramites_mobile/core/services/api_service.dart';
import 'package:tramites_mobile/core/services/auth_service.dart';
import 'package:tramites_mobile/core/services/session_service.dart';

class ClienteDashboard extends StatefulWidget {
  const ClienteDashboard({super.key});

  @override
  State<ClienteDashboard> createState() => _ClienteDashboardState();
}

class _ClienteDashboardState extends State<ClienteDashboard> {
  bool _isLoading = true;
  String? _error;
  List<TramiteModel> _tramites = const [];

  @override
  void initState() {
    super.initState();
    _cargarTramites();
  }

  Future<void> _cargarTramites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await context.read<ApiService>().dio.get<dynamic>(
        '/tramites/mis-tramites',
      );
      // ignore: avoid_print
      print('TRAMITES STATUS: ${response.statusCode}');
      // ignore: avoid_print
      print('TRAMITES RESPONSE: ${response.data}');
      final raw = response.data;
      final List<dynamic> lista = raw is List ? raw : ((raw as Map<String, dynamic>)['content'] ?? []);
      final tramites =
          lista
              .whereType<Map<String, dynamic>>()
              .map(TramiteModel.fromJson)
              .toList();
      setState(() {
        _tramites = tramites;
      });
    } catch (error) {
      // ignore: avoid_print
      print('TRAMITES ERROR: $error');
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
        title: Text('Cliente: ${session.user?.nombreMostrado ?? 'Usuario'}'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>('/cliente/iniciar');
          if (created == true && mounted) {
            _cargarTramites();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Iniciar tramite'),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarTramites,
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
                : _tramites.isEmpty
                ? ListView(
                  children: [
                    const SizedBox(height: 220),
                    const Center(child: Text('Aun no tienes tramites.')),
                  ],
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _tramites.length,
                  itemBuilder: (context, index) {
                    final tramite = _tramites[index];
                    return Card(
                      elevation: 2,
                      shadowColor: Colors.black12,
                      child: ListTile(
                        title: Text(
                          tramite.nombre ?? tramite.politica ?? 'Tramite',
                        ),
                        subtitle: Text('Estado: ${tramite.estado}'),
                        trailing: TextButton(
                          onPressed:
                              () => context.push(
                                '/cliente/seguimiento',
                                extra: tramite,
                              ),
                          child: const Text('Seguimiento'),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
