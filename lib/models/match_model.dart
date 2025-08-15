class MatchModel {
  final String id;
  final String teamA;
  final String teamB;
  final List<String> teamAPlayers;
  final List<String> teamBPlayers;
  final String tossWonBy;
  final String optedTo;
  final String striker;
  final String nonStriker;
  final String bowler;
  final DateTime startTime;
  final DateTime endTime;
  final int overs;
  final String status; // ongoing, completed, no_result
  final String result; // e.g.,"Team B Won" "Team A won", "Match Drawn", "NO result"

  MatchModel({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.teamAPlayers,
    required this.teamBPlayers,
    required this.tossWonBy,
    required this.optedTo,
    required this.striker,
    required this.nonStriker,
    required this.bowler,
    required this.startTime,
    required this.endTime,
    required this.overs,
    required this.status,
    required this.result,
  });

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      id: map['id'],
      teamA: map['teamA'],
      teamB: map['teamB'],
      teamAPlayers: List<String>.from(map['teamAPlayers']),
      teamBPlayers: List<String>.from(map['teamBPlayers']),
      tossWonBy: map['tossWonBy'],
      optedTo: map['optedTo'],
      striker: map['striker'],
      nonStriker: map['nonStriker'],
      bowler: map['bowler'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      overs: map['overs'],
      status: map['status'],
      result: map['result'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamA': teamA,
      'teamB': teamB,
      'teamAPlayers': teamAPlayers,
      'teamBPlayers': teamBPlayers,
      'tossWonBy': tossWonBy,
      'optedTo': optedTo,
      'striker': striker,
      'nonStriker': nonStriker,
      'bowler': bowler,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'overs': overs,
      'status': status,
      'result': result,
    };
  }
}
