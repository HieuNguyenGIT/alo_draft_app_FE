import 'package:alo_draft_app/screens/forgot_pwd_screen.dart';
import 'package:alo_draft_app/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alo_draft_app/blocs/auth/auth_bloc.dart';
import 'package:alo_draft_app/blocs/auth/auth_event.dart';
import 'package:alo_draft_app/blocs/auth/auth_state.dart';
import 'package:alo_draft_app/blocs/todo/todo_bloc.dart';
import 'package:alo_draft_app/blocs/message/message_bloc.dart';
import 'package:alo_draft_app/repositories/auth_repository.dart';
import 'package:alo_draft_app/repositories/todo_repository.dart';
import 'package:alo_draft_app/screens/intro_screen.dart';
import 'package:alo_draft_app/screens/splash_screen.dart';
import 'package:alo_draft_app/screens/login_screen.dart';
import 'package:alo_draft_app/screens/register_screen.dart';
import 'package:alo_draft_app/screens/home_screen.dart';
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:alo_draft_app/services/socket_io_service.dart';

void main() {
  // Initialize logger
  AppLogger.init(
      env); // Set to 'local' for development, 'production' for release

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository = AuthRepository();
  final TodoRepository todoRepository = TodoRepository();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: authRepository,
          )..add(AppStarted()),
        ),
        BlocProvider<TodoBloc>(
          create: (context) => TodoBloc(
            todoRepository: todoRepository,
          ),
        ),
        // Add MessageBloc provider
        BlocProvider<MessageBloc>(
          create: (context) => MessageBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'AloDraft App',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          primaryColor: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black87),
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            AppLogger.log(
                "🏠 Main BlocBuilder - Auth state: ${state.runtimeType}");

            if (state is AuthInitial || state is AuthLoading) {
              return const SplashScreen();
            }
            if (state is AuthAuthenticated) {
              return const HomeScreen();
            }
            if (state is AuthUnauthenticated) {
              // 🔥 CRITICAL: Disconnect Socket.IO when user is unauthenticated
              WidgetsBinding.instance.addPostFrameCallback((_) {
                SocketIOService.instance.disconnect();
              });
              return const IntroScreen();
            }
            return const SplashScreen();
          },
        ),
        routes: {
          '/intro': (context) => const IntroScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
