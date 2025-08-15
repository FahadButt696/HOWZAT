import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/team_model.dart';
import '../../services/team_service.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  late TeamService _teamService;
  final List<TeamModel> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initServicesAndFetchTeams();
  }

  Future<void> _initServicesAndFetchTeams() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;

    // Access global __app_id variable provided by the Canvas environment
    final String appId = const String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');

    // Ensure user is authenticated before fetching data
    User? currentUser = auth.currentUser;
    if (currentUser == null) {
      // If no user is logged in, attempt anonymous sign-in (as per previous logic)
      final initialAuthToken = const String.fromEnvironment('INITIAL_AUTH_TOKEN');
      if (initialAuthToken.isNotEmpty) {
        await auth.signInWithCustomToken(initialAuthToken);
      } else {
        await auth.signInAnonymously();
      }
      currentUser = auth.currentUser; // Update currentUser after sign-in attempt
    }

    if (currentUser != null) {
      _teamService = TeamService(firestore, appId, currentUser.uid);
      await _fetchTeams();
    } else {
      setState(() {
        _isLoading = false;
      });
      // Handle scenario where user still isn't available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to authenticate user for teams. Please restart.')),
      );
    }
  }

  Future<void> _fetchTeams() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetchedTeams = await _teamService.getAllTeams();
      setState(() {
        _teams.clear();
        _teams.addAll(fetchedTeams);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching teams: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading teams: $e'),
          duration: const Duration(seconds: 2), // Set duration
        ),
      );
    }
  }

  Future<void> _deleteTeam(TeamModel team) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Confirm Delete", style: GoogleFonts.balooBhai2(color: Colors.white)),
          content: Text("Are you sure you want to delete '${team.name}'?", style: GoogleFonts.balooBhai2(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel", style: GoogleFonts.balooBhai2(color: Colors.lightGreenAccent)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text("Delete", style: GoogleFonts.balooBhai2(color: Colors.redAccent)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _teamService.deleteTeam(team.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${team.name} deleted successfully!'),
            duration: const Duration(seconds: 2), // Set duration
          ),
        );
        _fetchTeams(); // Refresh the list
      } catch (e) {
        print("Error deleting team: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting ${team.name}: $e'),
            duration: const Duration(seconds: 2), // Set duration
          ),
        );
      }
    }
  }

  Future<void> _editTeam(TeamModel team) async {
    TextEditingController newNameController = TextEditingController(text: team.name);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Edit Team Name", style: GoogleFonts.balooBhai2(color: Colors.white)),
          content: TextField(
            controller: newNameController,
            style: GoogleFonts.balooBhai2(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter new team name",
              hintStyle: GoogleFonts.balooBhai2(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel", style: GoogleFonts.balooBhai2(color: Colors.redAccent)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text("Save", style: GoogleFonts.balooBhai2(color: Colors.lightGreenAccent)),
              onPressed: () {
                if (newNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Team name cannot be empty!'),
                      duration: const Duration(seconds: 2), // Set duration
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // Create a new TeamModel with the updated name, keeping other stats the same
        final updatedTeam = TeamModel(
          id: team.id,
          name: newNameController.text.trim(),
          matchesPlayed: team.matchesPlayed,
          wins: team.wins,
          losses: team.losses,
          players: team.players, // Keep existing players
        );
        await _teamService.saveTeam(updatedTeam); // saveTeam handles updates
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Team name updated to '${newNameController.text.trim()}'!"),
            duration: const Duration(seconds: 2), // Set duration
          ),
        );
        _fetchTeams(); // Refresh the list
      } catch (e) {
        print("Error updating team: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating team: $e'),
            duration: const Duration(seconds: 2), // Set duration
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B6623), Color(0xFF1E3C72)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "Teams",
                style: GoogleFonts.balooBhai2(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _teams.isEmpty
                  ? Center(
                child: Text(
                  "No teams found. Start a new match to create teams!",
                  style: GoogleFonts.balooBhai2(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _teams.length,
                itemBuilder: (context, index) {
                  final team = _teams[index];
                  return _buildTeamCard(team);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(TeamModel team) {
    // Generate initials for the circle avatar
    String initials = team.name.isNotEmpty ? team.name.substring(0, 1).toUpperCase() : '?';
    if (team.name.length > 1 && team.name.contains(' ')) {
      initials += team.name.split(' ')[1].substring(0, 1).toUpperCase();
    } else if (team.name.length > 1) {
      initials += team.name.substring(1, 2).toUpperCase();
    }


    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black45.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 25,
            child: Text(
              initials,
              style: GoogleFonts.balooBhai2(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Matches : ${team.matchesPlayed} Won : ${team.wins} Lost : ${team.losses}",
                  style: GoogleFonts.balooBhai2(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          // Edit Icon - Calls _editTeam
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent),
            onPressed: () => _editTeam(team), // Call the edit function
          ),
          // Delete Icon - Calls _deleteTeam
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _deleteTeam(team), // Call the delete function
          ),
        ],
      ),
    );
  }
}
