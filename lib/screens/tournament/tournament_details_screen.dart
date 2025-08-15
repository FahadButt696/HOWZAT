import 'package:flutter/material.dart';
import '../../models/tournament_model.dart';

class TournamentDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TournamentModel tournament =
    ModalRoute.of(context)!.settings.arguments as TournamentModel;

    return Scaffold(
      appBar: AppBar(title: Text(tournament.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Location: ${tournament.location}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Start Date: ${tournament.startDate.toLocal().toString().split(' ')[0]}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            Text('Matches:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Expanded(
              child: tournament.matchIds.isEmpty
                  ? Center(child: Text('No matches added yet.'))
                  : ListView.builder(
                itemCount: tournament.matchIds.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Match ID: ${tournament.matchIds[index]}'),
                    // Replace with actual match fetching later
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
