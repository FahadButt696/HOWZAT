import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_stats_model.dart';
import '../models/batting_stats.dart';
import '../models/bowling_stats.dart';
import '../models/fielding_stats.dart';

class PlayerService {
  final FirebaseFirestore _firestore;
  final String _appId;
  final String _userId;

  PlayerService(this._firestore, this._appId, this._userId);

  // Reference for player profiles (career stats)
  CollectionReference get _playerProfilesCollection => _firestore
      .collection('artifacts')
      .doc(_appId)
      .collection('users')
      .doc(_userId)
      .collection('player_profiles');

  // Reference for match-specific player stats (to preserve original initializeStats intent)
  CollectionReference _matchPlayerStatsCollection(String matchId) => _firestore
      .collection('artifacts')
      .doc(_appId)
      .collection('users')
      .doc(_userId)
      .collection('matches')
      .doc(matchId)
      .collection('player_stats');

  /// Initializes player stats for a specific match.
  /// This will store a snapshot of players' stats at the start of a match
  /// under the match's subcollection.
  Future<void> initializeMatchPlayerStats({
    required String matchId,
    required List<PlayerModel> players,
  }) async {
    for (final player in players) {
      await _matchPlayerStatsCollection(matchId)
          .doc(player.id) // Use player.id for consistent reference
          .set(player.toMap(), SetOptions(merge: true)); // Set initial values (0 runs, 0 wickets, etc.)
    }
  }

  /// Updates a player's overall career statistics based on their performance in a single match.
  /// This method aggregates the match-specific stats into the player's career totals.
  Future<void> updatePlayerStats(PlayerModel playerInMatch) async {
    final playerRef = _playerProfilesCollection.doc(playerInMatch.id);

    await _firestore.runTransaction((transaction) async {
      final playerSnapshot = await transaction.get(playerRef);

      PlayerModel currentCareerPlayer;

      if (playerSnapshot.exists && playerSnapshot.data() != null) {
        currentCareerPlayer = PlayerModel.fromMap(playerSnapshot.data()! as Map<String,dynamic>);
      } else {
        // If player profile doesn't exist, initialize it with base stats.
        // The playerInMatch provides the ID and Name.
        currentCareerPlayer = PlayerModel(
          id: playerInMatch.id,
          name: playerInMatch.name,
          batting: BattingStats(), // Initialize with empty stats for career
          bowling: BowlingStats(),
          fielding: FieldingStats(),
        );
      }

      // --- Aggregate Batting Stats ---
      // Only increment matches/innings played if the player actually participated (batted/bowled)
      // This logic will be handled by the LiveScoreScreen passing appropriate `playerInMatch` data.
      if (playerInMatch.batting.balls > 0 || playerInMatch.batting.runs > 0 || playerInMatch.batting.ducks > 0) {
        currentCareerPlayer.batting.matches++; // Assuming a match counts if they face a ball
        currentCareerPlayer.batting.innings++; // Assuming an innings counts if they face a ball

        currentCareerPlayer.batting.runs += playerInMatch.batting.runs;
        currentCareerPlayer.batting.balls += playerInMatch.batting.balls;
        currentCareerPlayer.batting.fours += playerInMatch.batting.fours;
        currentCareerPlayer.batting.sixes += playerInMatch.batting.sixes;

        if (playerInMatch.batting.runs > currentCareerPlayer.batting.bestScore) {
          currentCareerPlayer.batting.bestScore = playerInMatch.batting.runs;
        }

        if (playerInMatch.batting.runs >= 50 && playerInMatch.batting.runs < 100 && playerInMatch.batting.fifties > 0) {
          currentCareerPlayer.batting.fifties++;
        }
        if (playerInMatch.batting.runs >= 100 && playerInMatch.batting.hundreds > 0) {
          currentCareerPlayer.batting.hundreds++;
        }

        if (playerInMatch.batting.ducks > 0) {
          currentCareerPlayer.batting.ducks++;
        }
        // playerInMatch.batting.notOuts will be 1 if they finished the inning not out
        currentCareerPlayer.batting.notOuts += playerInMatch.batting.notOuts;
      }


      // --- Aggregate Bowling Stats ---
      if (playerInMatch.bowling.ballsBowled > 0 || playerInMatch.bowling.wickets > 0) {
        if(playerInMatch.batting.balls == 0 && playerInMatch.batting.runs == 0) { // Only increment match count if they bowled but didn't bat
          currentCareerPlayer.bowling.matches++; // Assuming a match counts if they bowl
        }
        currentCareerPlayer.bowling.innings++; // Assuming an innings counts if they bowl

        currentCareerPlayer.bowling.ballsBowled += playerInMatch.bowling.ballsBowled;
        currentCareerPlayer.bowling.runs += playerInMatch.bowling.runs;
        currentCareerPlayer.bowling.wickets += playerInMatch.bowling.wickets;
        currentCareerPlayer.bowling.maidens += playerInMatch.bowling.maidens;
        currentCareerPlayer.bowling.dotBalls += playerInMatch.bowling.dotBalls;
        currentCareerPlayer.bowling.wides += playerInMatch.bowling.wides;
        currentCareerPlayer.bowling.noBalls += playerInMatch.bowling.noBalls;

        if (playerInMatch.bowling.wickets >= 4 && playerInMatch.bowling.wickets < 5) {
          currentCareerPlayer.bowling.fourWickets++;
        } else if (playerInMatch.bowling.wickets >= 5) {
          currentCareerPlayer.bowling.fiveWickets++;
        }
      }

      // --- Aggregate Fielding Stats --- (simple addition for all instances)
      currentCareerPlayer.fielding.catches += playerInMatch.fielding.catches;
      currentCareerPlayer.fielding.runOuts += playerInMatch.fielding.runOuts;
      currentCareerPlayer.fielding.stumpings += playerInMatch.fielding.stumpings;

      transaction.set(playerRef, currentCareerPlayer.toMap());
    });
  }

  /// Retrieves a player's career profile by ID.
  Future<PlayerModel?> getPlayerProfile(String playerId) async {
    final doc = await _playerProfilesCollection.doc(playerId).get();
    if (doc.exists && doc.data() != null) {
      return PlayerModel.fromMap(doc.data()! as Map<String,dynamic>);
    }
    return null;
  }
}
