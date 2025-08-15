import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';
import '../models/player_stats_model.dart'; // Needed if saving players within team

class TeamService {
  final FirebaseFirestore _firestore;
  final String _appId;
  final String _userId;

  TeamService(this._firestore, this._appId, this._userId);

  // Reference to the user's specific teams collection
  CollectionReference get _userTeamsCollection => _firestore
      .collection('artifacts')
      .doc(_appId)
      .collection('users')
      .doc(_userId)
      .collection('teams');

  /// Saves a new team or updates an existing one in Firestore.
  /// This version tries to replicate the user's original `saveTeam` behavior
  /// which suggests players are also saved as subcollections of the team.
  Future<void> saveTeam(TeamModel team) async {
    final teamRef = _userTeamsCollection.doc(team.id);



    // Save team data (excluding players array, as players are subcollection)
    // Using team.toMap() directly from your model, which correctly omits players.
    await teamRef.set(team.toMap(), SetOptions(merge: true));

    // Save each player inside the "players" subcollection of the team
    for (final player in team.players) {
      final playerRef = teamRef.collection('players').doc(player.id);
      await playerRef.set(player.toMap(), SetOptions(merge: true)); // Merge existing player data
    }
  }

  /// Updates the match statistics (matches played, wins, losses) for a given team.
  /// Uses a transaction to ensure atomic updates.
  Future<void> updateTeamStats(String teamId, bool won, bool isTied) async {
    final teamRef = _userTeamsCollection.doc(teamId);

    await _firestore.runTransaction((transaction) async {
      final teamSnapshot = await transaction.get(teamRef);
      if (teamSnapshot.exists && teamSnapshot.data() != null) {
        Map<String, dynamic> data = teamSnapshot.data()! as Map<String,dynamic>;
        int matchesPlayed = (data['matchesPlayed'] ?? 0) + 1;
        int wins = data['wins'] ?? 0;
        int losses = data['losses'] ?? 0;

        if (won) {
          wins++;
        } else if (!isTied) { // If not won and not tied, it's a loss
          losses++;
        }
        // If tied, wins and losses remain unchanged.

        transaction.update(teamRef, {
          'matchesPlayed': matchesPlayed,
          'wins': wins,
          'losses': losses,
        });
      }
    });
  }

  /// Retrieves a specific team by its ID.
  /// Note: This will not fetch the nested players by default.
  Future<TeamModel?> getTeam(String teamId) async {
    final teamDoc = await _userTeamsCollection.doc(teamId).get();
    if (teamDoc.exists && teamDoc.data() != null) {
      // To get players associated with the team, you would need
      // to fetch them from the 'players' subcollection using PlayerService.
      // For now, we return TeamModel with an empty players list as per original structure
      return TeamModel.fromMap(teamDoc.data()! as Map<String,dynamic>, []);
    }
    return null;
  }

  // --- New API methods for Teams Screen ---

  /// Retrieves all teams for the current user, including their players.
  Future<List<TeamModel>> getAllTeams() async {
    try {
      final querySnapshot = await _userTeamsCollection.get();
      List<TeamModel> teams = [];
      for (var doc in querySnapshot.docs) {
        final teamData = doc.data() as Map<String, dynamic>;

        // Fetch players from the subcollection for each team
        final playersSnapshot = await doc.reference.collection('players').get();
        final List<PlayerModel> players = playersSnapshot.docs
            .map((playerDoc) => PlayerModel.fromMap(playerDoc.data()))
            .toList();

        // Corrected call to fromMap to pass players as a positional argument
        teams.add(TeamModel.fromMap(teamData, players));
      }
      return teams;
    } catch (e) {
      print('Error getting all teams: $e');
      rethrow;
    }
  }

  /// Deletes a specific team and all its associated players from Firestore.
  Future<void> deleteTeam(String teamId) async {
    try {
      final teamRef = _userTeamsCollection.doc(teamId);

      // Delete all players in the subcollection first
      final playersSnapshot = await teamRef.collection('players').get();
      for (final playerDoc in playersSnapshot.docs) {
        await playerDoc.reference.delete();
      }

      // Then delete the team document itself
      await teamRef.delete();
      print('Team and its players deleted successfully: $teamId');
    } catch (e) {
      print('Error deleting team: $e');
      rethrow;
    }
  }
}
