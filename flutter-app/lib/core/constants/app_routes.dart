class AppRoutes {
  AppRoutes._();

  static const String login             = '/login';
  static const String register          = '/register';
  static const String home              = '/home';
  static const String calendar          = '/calendar';
  static const String bracket           = '/bracket';
  static const String matchDetail       = '/match/:id';
  static const String addEvent          = '/match/:id/add-event';
  static const String addLineup         = '/match/:id/add-lineup';
  static const String editMatch         = '/match/:id/edit';
  static const String teamsList         = '/teams';
  static const String teamDetail        = '/team/:id';
  static const String addTeam           = '/add-team';
  static const String playerDetail      = '/player/:id';
  static const String addPlayer         = '/team/:id/add-player';
  static const String scorers           = '/scorers';
  static const String followTournaments = '/follow-tournaments';
}
