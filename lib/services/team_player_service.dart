import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';
import '../models/player_stats_model.dart';
import '../models/batting_stats.dart';
import '../models/bowling_stats.dart';
import '../models/fielding_stats.dart';

class TeamPlayerService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final CollectionReference _teamsRef = _db.collection('teams');

  /// ------------------------ TEAMS ------------------------

  /// 1. Get all teams with matches, wins, losses, and name
  static Future<List<Map<String, dynamic>>> getAllTeamsMeta() async {
    final snapshot = await _teamsRef.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'name': data['name'],
        'matches': data['matches'],
        'wins': data['wins'],
        'losses': data['losses'],
      };
    }).toList();
  }

  /// 2. Delete a team by ID
  static Future<void> deleteTeam(String teamId) async {
    await _teamsRef.doc(teamId).delete();
  }

  /// 3. Update team name
  static Future<void> updateTeamName(String teamId, String newName) async {
    await _teamsRef.doc(teamId).update({'name': newName});
  }

  /// ------------------------ PLAYERS ------------------------

  /// 4. Get all players of a team
  static Future<List<Map<String, dynamic>>> getAllPlayersOfTeam(String teamId) async {
    final doc = await _teamsRef.doc(teamId).get();
    final data = doc.data() as Map<String, dynamic>;

    final playersMap = data['players'] as Map<String, dynamic>;
    return playersMap.entries.map((entry) {
      final playerData = entry.value as Map<String, dynamic>;
      return {
        'id': entry.key,
        'name': playerData['name'],
      };
    }).toList();
  }

  /// 5. Delete a player by ID
  static Future<void> deletePlayer(String teamId, String playerId) async {
    await _teamsRef.doc(teamId).update({
      'players.$playerId': FieldValue.delete(),
    });
  }

  /// 6. Update player name
  static Future<void> updatePlayerName(String teamId, String playerId, String newName) async {
    await _teamsRef.doc(teamId).update({
      'players.$playerId.name': newName,
    });
  }

  /// ------------------------ PLAYER STATS ------------------------

  /// 7. Get Batting Stats of a Player
  static Future<BattingStats?> getBattingStats(String teamId, String playerId) async {
    final doc = await _teamsRef.doc(teamId).get();
    final data = doc.data() as Map<String, dynamic>;

    final battingMap = data['players'][playerId]['batting'] as Map<String, dynamic>;
    return BattingStats.fromMap(battingMap);
  }

  /// 8. Get Bowling Stats of a Player
  static Future<BowlingStats?> getBowlingStats(String teamId, String playerId) async {
    final doc = await _teamsRef.doc(teamId).get();
    final data = doc.data() as Map<String, dynamic>;

    final bowlingMap = data['players'][playerId]['bowling'] as Map<String, dynamic>;
    return BowlingStats.fromMap(bowlingMap);
  }

  /// 9. Get Fielding Stats of a Player
  static Future<FieldingStats?> getFieldingStats(String teamId, String playerId) async {
    final doc = await _teamsRef.doc(teamId).get();
    final data = doc.data() as Map<String, dynamic>;

    final fieldingMap = data['players'][playerId]['fielding'] as Map<String, dynamic>;
    return FieldingStats.fromMap(fieldingMap);
  }


  /// Starts a new match with provided data under the logged-in user.
  /// Sets status to 'ongoing' initially and saves start date/time.
  // Future<String> startMatch({
  //   required String userId,
  //   required Map<String, dynamic> matchData,
  // }) async {
  //   final matchRef = _firestore
  //       .collection('users')
  //       .doc(userId)
  //       .collection('matches')
  //       .doc(); // auto-generated matchId
  //
  //   await matchRef.set({
  //     ...matchData,
  //     'status': 'ongoing', // ongoing | completed | no_result
  //     'createdAt': FieldValue.serverTimestamp(),
  //   });
  //
  //   return matchRef.id;
  // }

  /// Updates a match's information such as result, score, or end time.
  // Future<void> updateMatch({
  //   required String userId,
  //   required String matchId,
  //   required Map<String, dynamic> data,
  // }) async {
  //   final matchRef = _firestore.collection('users').doc(userId).collection('matches').doc(matchId);
  //   await matchRef.update(data);
  // }
  //
  // /// Gets the history of all matches played by the user (ordered by date).
  // Future<List<Map<String, dynamic>>> getMatchHistory(String userId) async {
  //   final snapshot = await _firestore
  //       .collection('users')
  //       .doc(userId)
  //       .collection('matches')
  //       .orderBy('createdAt', descending: true)
  //       .get();
  //   return snapshot.docs.map((doc) => doc.data()).toList();
  // }
  //
  // /// Deletes a match record.
  // Future<void> deleteMatch({
  //   required String userId,
  //   required String matchId,
  // }) async {
  //   await _firestore.collection('users').doc(userId).collection('matches').doc(matchId).delete();
  // }

}
