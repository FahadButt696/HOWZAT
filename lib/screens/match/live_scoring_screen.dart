// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../models/match_model.dart';
// import '../../services/match_service.dart';
//
// class LiveScoringScreen extends StatefulWidget {
//   final MatchModel match;
//   const LiveScoringScreen({required this.match, super.key});
//
//   @override
//   State<LiveScoringScreen> createState() => _LiveScoringScreenState();
// }
//
// class _LiveScoringScreenState extends State<LiveScoringScreen> {
//   int currentOver = 1, currentBall = 1;
//   final matchRef = FirebaseFirestore.instance.collection('matches');
//
//   Future<void> onBall({required int runs, bool isWicket = false}) async {
//     final snap = await matchRef.doc(widget.match.id).get();
//     final data = snap.data()!;
//     final isTeamA = data['electedTo'] == 'bat' && data['tossWinnerId'] == data['teamAId'] ||
//         data['electedTo'] == 'bowl' && data['tossWinnerId'] == data['teamBId'];
//     final field = isTeamA ? 'teamAScore' : 'teamBScore';
//     final wicketField = isTeamA ? 'teamAWickets' : 'teamBWickets';
//
//     await matchRef.doc(widget.match.id).update({
//       field: data[field] + runs,
//       if (isWicket) wicketField: data[wicketField] + 1,
//     });
//
//     setState(() {
//       if (currentBall < 6) currentBall++;
//       else {
//         currentOver++; currentBall = 1;
//       }
//     });
//
//     if (currentOver > widget.match.overs) {
//       await MatchService().saveCompletedMatch(
//         teamA: data['teamAId'], teamB: data['teamBId'],
//         teamAScore: data['teamAScore'], teamAWickets: data['teamAWickets'],
//         teamBScore: data['teamBScore'], teamBWickets: data['teamBWickets'],
//         overs: widget.match.overs,
//         winner: data['teamAScore'] > data['teamBScore'] ? data['teamAId'] : data['teamBId'],
//       );
//       Navigator.pop(context);
//     }
//   }
//
//   @override
//   Widget build(BuildContext c) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Live Scoring – Over $currentOver.$currentBall"),
//       ),
//       body: Column(
//         children: [
//           StreamBuilder<DocumentSnapshot>(
//             stream: matchRef.doc(widget.match.id).snapshots(),
//             builder: (c, snap) {
//               if (!snap.hasData) return CircularProgressIndicator();
//               final d = snap.data!.data()! as Map<String, dynamic>;
//               return Column(children: [
//                 Text("Team A: ${d['teamAScore']} / ${d['teamAWickets']}"),
//                 Text("Team B: ${d['teamBScore']} / ${d['teamBWickets']}"),
//               ]);
//             },
//           ),
//           Wrap(
//               spacing: 10,
//               children: [0,1,2,3,4,6]
//                   .map((r) => ElevatedButton(onPressed: () => onBall(runs: r), child: Text("$r")))
//                   .toList()
//           ),
//           ElevatedButton(onPressed: () => onBall(runs:0, isWicket: true), child: Text("Wicket")),
//         ],
//       ),
//     );
//   }
// }
