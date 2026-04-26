import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tramites_mobile/core/models/tramite_model.dart';
import 'package:tramites_mobile/core/services/api_service.dart';
import 'package:tramites_mobile/core/services/auth_service.dart';
import 'package:tramites_mobile/core/services/fcm_service.dart';
import 'package:tramites_mobile/core/services/session_service.dart';
import 'package:tramites_mobile/features/auth/login_screen.dart';
import 'package:tramites_mobile/features/cliente/cliente_dashboard.dart';
import 'package:tramites_mobile/features/cliente/iniciar_tramite_screen.dart';
import 'package:tramites_mobile/features/cliente/seguimiento_screen.dart';
import 'package:tramites_mobile/shared/widgets/loading_widget.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const storage = FlutterSecureStorage();
  late final SessionService sessionService;

  final apiService = ApiService(
    storage: storage,
    onUnauthorized: () => sessionService.handleUnauthorized(),
  );
  final authService = AuthService(apiService: apiService, storage: storage);
  sessionService = SessionService(
    authService: authService,
    apiService: apiService,
  );
  sessionService.init();
  await FcmService.initialize(apiService, navigatorKey);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider<SessionService>.value(value: sessionService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/loading',
      refreshListenable: session,
      routes: [
        GoRoute(
          path: '/loading',
          builder: (context, state) => const LoadingWidget(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/no-autorizado',
          builder: (context, state) => const _SoloClientesScreen(),
        ),
        GoRoute(
          path: '/cliente',
          builder: (context, state) => const ClienteDashboard(),
        ),
        GoRoute(
          path: '/cliente/iniciar',
          builder: (context, state) => const IniciarTramiteScreen(),
        ),
        GoRoute(
          path: '/cliente/seguimiento',
          builder: (context, state) {
            final tramite = state.extra;
            return SeguimientoScreen(
              tramite: tramite is TramiteModel ? tramite : null,
            );
          },
        ),
      ],
      redirect: (context, state) {
        if (session.isInitializing) {
          return state.matchedLocation == '/loading' ? null : '/loading';
        }

        if (!session.isAuthenticated) {
          return state.matchedLocation == '/login' ? null : '/login';
        }

        if (state.matchedLocation == '/loading' ||
            state.matchedLocation == '/login') {
          return session.role == 'CLIENTE' ? '/cliente' : '/no-autorizado';
        }

        if (session.role != 'CLIENTE' &&
            state.matchedLocation != '/no-autorizado') {
          return '/no-autorizado';
        }

        return null;
      },
    );

    return MaterialApp.router(
      title: 'Tramites Empresariales',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          primary: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
    );
  }
}

class _SoloClientesScreen extends StatelessWidget {
  const _SoloClientesScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Esta app es solo para clientes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.read<SessionService>().logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
