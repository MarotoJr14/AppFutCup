import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/matches/calendar_screen.dart';
import 'screens/matches/match_detail_screen.dart';
import 'screens/matches/edit_match_screen.dart';
import 'screens/bracket/bracket_screen.dart';
import 'screens/teams/teams_list_screen.dart';
import 'screens/teams/team_detail_screen.dart';
import 'screens/teams/add_team_screen.dart';
import 'screens/players/player_detail_screen.dart';
import 'screens/players/add_player_screen.dart';
import 'screens/events/add_event_screen.dart';
import 'screens/lineups/add_lineup_screen.dart';
import 'screens/scorers/scorers_screen.dart';
import 'screens/tournaments/follow_tournaments_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoading = authState is AsyncLoading;
      if (isLoading) return null;

      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    refreshListenable: GoRouterRefreshStream(authNotifier),
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
      GoRoute(path: '/bracket', builder: (_, __) => const BracketScreen()),
      GoRoute(path: '/teams', builder: (_, __) => const TeamsListScreen()),
      GoRoute(path: '/scorers', builder: (_, __) => const ScorersScreen()),
      GoRoute(path: '/follow-tournaments', builder: (_, __) => const FollowTournamentsScreen()),
      GoRoute(
        path: '/match/:id',
        builder: (_, state) => MatchDetailScreen(matchId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/match/:id/edit',
        builder: (_, state) => EditMatchScreen(matchId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/match/:id/add-event',
        builder: (_, state) => AddEventScreen(matchId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/match/:id/add-lineup',
        builder: (_, state) => AddLineupScreen(matchId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/team/:id',
        builder: (_, state) => TeamDetailScreen(teamId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/add-team',
        builder: (_, state) => AddTeamScreen(tournamentId: state.extra as int),
      ),
      GoRoute(
        path: '/player/:id',
        builder: (_, state) => PlayerDetailScreen(
          playerId: int.parse(state.pathParameters['id']!),
          tournamentId: state.extra as int,
        ),
      ),
      GoRoute(
        path: '/team/:id/add-player',
        builder: (_, state) => AddPlayerScreen(teamId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});

// Needed to notify GoRouter when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(StateNotifier notifier) {
    notifier.addListener((state) => notifyListeners());
  }
}
