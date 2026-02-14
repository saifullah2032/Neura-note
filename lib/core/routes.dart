// lib/core/routes.dart
import 'package:go_router/go_router.dart';
import '../screens/login/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/summarize/summarize_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/reminders/reminders_screen.dart';

final appRouter = GoRouter(
  debugLogDiagnostics: true, // helpful while debugging navigation
  initialLocation: '/',
  routes: [
    GoRoute(
      name: 'login',
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      name: 'home',
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      name: 'summary',
      path: '/summary',
      builder: (context, state) => const SummarizeScreen(),
    ),
    GoRoute(
      name: 'summarize',
      path: '/summarize',
      builder: (context, state) => const SummarizeScreen(),
    ),
    GoRoute(
      name: 'profile',
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      name: 'reminders',
      path: '/reminders',
      builder: (context, state) => const RemindersScreen(),
    ),
  ],
);
