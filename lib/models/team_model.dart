import 'package:howzat/models/player_stats_model.dart';

class TeamModel {
  final String id;
  final String name;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final List<PlayerModel> players;

  TeamModel({
    required this.id,
    required this.name,
    required this.matchesPlayed,
    required this.wins,
    required this.losses,
    required this.players,
  });

  factory TeamModel.fromMap(Map<String, dynamic> map, List<PlayerModel> players) {
    return TeamModel(
      id: map['id'],
      name: map['name'],
      matchesPlayed: map['matchesPlayed'],
      wins: map['wins'],
      losses: map['losses'],
      players: players,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'losses': losses,
    };
  }
}
