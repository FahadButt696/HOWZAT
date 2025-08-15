import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';

class MatchService {
  final FirebaseFirestore _firestore;
  final String _appId;
  final String _userId; // userId from LiveScoreScreen's constructor

  MatchService(this._firestore, this._appId, this._userId);

  // Reference to the user's specific matches collection
  CollectionReference get _userMatchesCollection => _firestore
      .collection('artifacts') // Top-level collection for app data
      .doc(_appId)              // Document for this specific app instance
      .collection('users')      // Subcollection for user data
      .doc(_userId)             // Document for the current authenticated user
      .collection('matches');   // Collection for the user's matches

  /// Saves a new match or updates an existing one in Firestore.
  /// If match.id is empty, Firestore generates an ID.
  /// If match.id is provided, it attempts to set/update that specific document.
  /// This preserves the original `saveMatch` intent.
  Future<String> saveMatch(MatchModel match) async {
    final docRef = _userMatchesCollection.doc(match.id.isEmpty ? null : match.id);
    await docRef.set(match.toMap(), SetOptions(merge: true)); // Use merge to avoid overwriting existing fields
    return docRef.id;
  }

  /// Updates the status and result of a specific match after it's completed.
  Future<void> updateMatchResult(String matchId, String status, String result) async {
    await _userMatchesCollection.doc(matchId).update({
      'status': status,
      'result': result,
      'endTime': DateTime.now().toIso8601String(), // Update end time
    });
  }

  Future<List<MatchModel>> getAllMatches() async {
    try {
      final querySnapshot = await _userMatchesCollection.get();
      return querySnapshot.docs
          .map((doc) => MatchModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting all matches: $e');
      rethrow;
    }
  }
  Future<void> deleteMatch(String matchId) async {
    try {
      await _userMatchesCollection.doc(matchId).delete();
      print('Match deleted successfully: $matchId');
    } catch (e) {
      print('Error deleting match: $e');
      rethrow;
    }
  }

  /// Retrieves a specific match by its ID.
  Future<MatchModel?> getMatch(String matchId) async {
    final doc = await _userMatchesCollection.doc(matchId).get();
    if (doc.exists) {
      final data = doc.data(); // Assign to a local variable
      if (data != null) { // Check nullability of local variable
        // Explicitly cast the data to Map<String, dynamic>
        return MatchModel.fromMap(data as Map<String, dynamic>); // Use the non-nullable local variable
      }
    }
    return null;
  }
}
