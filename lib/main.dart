import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alo_draft_app/blocs/auth/auth_bloc.dart';
import 'package:alo_draft_app/blocs/auth/auth_event.dart';
import 'package:alo_draft_app/blocs/auth/auth_state.dart';
import 'package:alo_draft_app/blocs/todo/todo_bloc.dart';
import 'package:alo_draft_app/blocs/message/message_bloc.dart';
import 'package:alo_draft_app/repositories/auth_repository.dart';
import 'package:alo_draft_app/repositories/todo_repository.dart';
import 'package:alo_draft_app/screens/splash_screen.dart';
import 'package:alo_draft_app/screens/login_screen.dart';
import 'package:alo_draft_app/screens/register_screen.dart';
import 'package:alo_draft_app/screens/home_screen.dart';
import 'package:alo_draft_app/util/custom_logger.dart';

void main() {
  // Initialize logger
  AppLogger.init(
      'local'); // Set to 'local' for development, 'production' for release

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
        title: 'Todo App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthInitial) {
              return const SplashScreen();
            }
            if (state is AuthAuthenticated) {
              return const HomeScreen();
            }
            if (state is AuthUnauthenticated) {
              return const LoginScreen();
            }
            return const SplashScreen();
          },
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
