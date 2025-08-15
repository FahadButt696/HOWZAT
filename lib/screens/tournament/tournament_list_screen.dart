import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tournament_model.dart';
import '../../routes/app_routes.dart';

class TournamentListScreen extends StatelessWidget {
  const TournamentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tournaments')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tournaments').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return Center(child: Text('No tournaments found'));

          final tournaments = snapshot.data!.docs.map((doc) {
            return TournamentModel.fromJson(doc.data()! as Map<String, dynamic>);
          }).toList();

          return ListView.builder(
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final tournament = tournaments[index];
              return ListTile(
                title: Text(tournament.name),
                subtitle: Text('${tournament.location} • ${tournament.startDate.toLocal().toString().split(' ')[0]}'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.tournamentDetails,
                    arguments: tournament,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
