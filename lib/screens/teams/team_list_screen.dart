// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../models/team_model.dart';
//
// class TeamListScreen extends StatelessWidget {
//   const TeamListScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Teams')),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('teams').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting)
//             return Center(child: CircularProgressIndicator());
//
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
//             return Center(child: Text('No teams found'));
//
//           final teams = snapshot.data!.docs.map((doc) {
//             return TeamModel.fromJson(doc.data()! as Map<String, dynamic>);
//           }).toList();
//
//           return ListView.builder(
//             itemCount: teams.length,
//             itemBuilder: (context, index) {
//               final team = teams[index];
//               return ListTile(
//                 title: Text(team.name),
//                 subtitle: Text('Players: ${team.playerNames.length}'),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
