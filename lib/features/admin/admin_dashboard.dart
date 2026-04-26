import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tramites_mobile/core/services/api_service.dart';
import 'package:tramites_mobile/core/services/auth_service.dart';
import 'package:tramites_mobile/core/services/session_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _politicas = const [];

  @override
  void initState() {
    super.initState();
    _cargarPoliticas();
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
      setState(() {
        _politicas = response.data ?? const [];
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
        title: Text('Admin: ${session.user?.nombreMostrado ?? 'Usuario'}'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarPoliticas,
        child:
            _isLoading
                ? ListView(
                  children: const [
                    SizedBox(height: 220),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
                : _error != null
                ? ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _cargarPoliticas,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _politicas.length,
                  itemBuilder: (context, index) {
                    final politica = _politicas[index];
                    final title = _politicaTitulo(politica, index);
                    final subtitle = _politicaSubtitulo(politica);

                    return Card(
                      elevation: 2,
                      shadowColor: Colors.black12,
                      child: ListTile(
                        leading: const Icon(Icons.policy_outlined),
                        title: Text(title),
                        subtitle: subtitle != null ? Text(subtitle) : null,
                      ),
                    );
                  },
                ),
      ),
    );
  }

  String _politicaTitulo(dynamic politica, int index) {
    if (politica is Map<String, dynamic>) {
      return (politica['nombre'] ??
              politica['titulo'] ??
              'Politica #${index + 1}')
          .toString();
    }
    return politica?.toString() ?? 'Politica #${index + 1}';
  }

  String? _politicaSubtitulo(dynamic politica) {
    if (politica is Map<String, dynamic>) {
      final descripcion = politica['descripcion']?.toString();
      if (descripcion != null && descripcion.trim().isNotEmpty) {
        return descripcion;
      }
      final id = politica['id']?.toString();
      if (id != null && id.isNotEmpty) {
        return 'ID: $id';
      }
    }
    return null;
  }
}
