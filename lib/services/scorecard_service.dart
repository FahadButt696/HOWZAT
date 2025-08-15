import 'package:cloud_firestore/cloud_firestore.dart';

class ScorecardService {
  final FirebaseFirestore _firestore;
  final String _appId;
  final String _userId;

  ScorecardService(this._firestore, this._appId, this._userId);

  // Reference to the user's specific scorecards collection
  CollectionReference get _userScorecardsCollection => _firestore
      .collection('artifacts')
      .doc(_appId)
      .collection('users')
      .doc(_userId)
      .collection('scorecards'); // New collection for match scorecards

  /// Saves the complete scorecard details for a match.
  /// This includes all inning summaries and the final match result.
  /// It accepts List<Map<String, dynamic>> to avoid direct dependency on LiveScoreScreen's internal models.
  Future<void> saveMatchScorecard(String matchId, List<Map<String, dynamic>> inningsSummaries, String finalResult) async {
    final docRef = _userScorecardsCollection.doc(matchId);

    await docRef.set({
      'matchId': matchId,
      'innings': inningsSummaries, // Stores the detailed innings summaries (already toMap'd)
      'finalResult': finalResult,
      'savedAt': FieldValue.serverTimestamp(), // Timestamp for when the scorecard was saved
    });
  }

  /// Retrieves a complete match scorecard by its ID.
  Future<Object?> getMatchScorecard(String matchId) async {
    final doc = await _userScorecardsCollection.doc(matchId).get();
    if (doc.exists && doc.data() != null) {
      return doc.data();
    }
    return null;
  }

  Future<void> deleteMatchScorecard(String matchId) async {
    try {
      await _userScorecardsCollection.doc(matchId).delete();
      print('Scorecard deleted successfully: $matchId');
    } catch (e) {
      print('Error deleting scorecard: $e');
      rethrow;
    }
  }
}
