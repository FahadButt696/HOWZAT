import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchSummaryScreen extends StatelessWidget {
  final String matchId;
  const MatchSummaryScreen({required this.matchId, super.key});

  @override
  Widget build(BuildContext c) {
    final docRef = FirebaseFirestore.instance.collection('matches').doc(matchId);

    return Scaffold(
      appBar: AppBar(title: Text("Summary")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (c, s) {
          if (!s.hasData) return CircularProgressIndicator();
          final d = s.data!.data()! as Map<String, dynamic>;
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${d['teamAId']} – ${d['teamAScore']}/${d['teamAWickets']}"),
                Text("${d['teamBId']} – ${d['teamBScore']}/${d['teamBWickets']}"),
                SizedBox(height: 20),
                Text("Overs: ${d['overs']}"),
                Text("Winner: ${d['teamAScore'] > d['teamBScore'] ? d['teamAId'] : d['teamBId']}"),
              ],
            ),
          );
        },
      ),
    );
  }
}
