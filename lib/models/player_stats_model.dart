import 'batting_stats.dart';
import 'bowling_stats.dart';
import 'fielding_stats.dart';

class PlayerModel {
  final String id;
  final String name;
  late final BattingStats batting;
  late final BowlingStats bowling;
  final FieldingStats fielding;

  PlayerModel({
    required this.id,
    required this.name,
    required this.batting,
    required this.bowling,
    required this.fielding,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['id'],
      name: map['name'],
      batting: BattingStats.fromMap(map['batting']),
      bowling: BowlingStats.fromMap(map['bowling']),
      fielding: FieldingStats.fromMap(map['fielding']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'batting': batting.toMap(),
      'bowling': bowling.toMap(),
      'fielding': fielding.toMap(),
    };
  }
}
