import 'package:flutter/material.dart';
import 'package:howzat/screens/auth/splash_screen.dart';
import '../models/match_model.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/match/LiveScoreScreen.dart';
import '../screens/match/player_select_screen.dart';
import '../screens/match/start_match_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/tournament/create_tournament_screen.dart';
import '../screens/tournament/tournament_list_screen.dart';
import '../screens/tournament/tournament_details_screen.dart';
import 'app_routes.dart';
import '../screens/teams/create_team_screen.dart';
import '../screens/teams/team_list_screen.dart';
import '../screens/match/create_match_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case AppRoutes.createMatch:
        return MaterialPageRoute(builder: (_) => CreateMatchScreen());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case AppRoutes.StartMatch:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => StartMatchScreen(
           matchData: args),
        );
      case AppRoutes.playerSelect:
        final match = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PlayerSelectScreen(matchData: match),
        );
      case AppRoutes.createTournament:
        return MaterialPageRoute(builder: (_) => CreateTournamentScreen());
      case AppRoutes.tournamentList:
        return MaterialPageRoute(builder: (_) => TournamentListScreen());
      case AppRoutes.tournamentDetails:
        return MaterialPageRoute(builder: (_) => TournamentDetailsScreen());
      // case AppRoutes.createTeam:
      //   return MaterialPageRoute(builder: (_) => CreateTeamScreen());
      // case AppRoutes.teamList:
      //   return MaterialPageRoute(builder: (_) => TeamListScreen());
      // case AppRoutes.history:
      //   return MaterialPageRoute(builder: (_) => HistoryScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => SettingsScreen());
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case AppRoutes.LiveScore:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => LiveScoreScreen(
            userId: args['userId'],
            match: args['match'],
            teamA: args['teamA'],
            teamB: args['teamB'],
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
