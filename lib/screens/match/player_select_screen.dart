import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:howzat/routes/app_routes.dart';
import '../../models/match_model.dart';

class PlayerSelectScreen extends StatefulWidget {
  final Map<String, dynamic> matchData;

  const PlayerSelectScreen({super.key, required this.matchData});

  @override
  State<PlayerSelectScreen> createState() => _PlayerSelectScreenState();
}

class _PlayerSelectScreenState extends State<PlayerSelectScreen> {
  final TextEditingController _teamAPlayerController = TextEditingController();
  final TextEditingController _teamBPlayerController = TextEditingController();

  final List<String> _teamAPlayers = [];
  final List<String> _teamBPlayers = [];

  void _showCustomSnackbar(String message, {bool isError = true}) {
    final background = isError ? Colors.redAccent.shade200 : Colors.greenAccent.shade200;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.warning_amber_rounded : Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _addPlayer(String value, List<String> list, TextEditingController controller, String teamName) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    if (list.length >= 11) {
      _showCustomSnackbar("$teamName can have a maximum of 11 players");
      return;
    }

    setState(() {
      list.add(trimmed);
      controller.clear();
    });
  }

  void _removePlayer(String player, List<String> list) {
    setState(() {
      list.remove(player);
    });
  }

  void _onNext() {
    if (_teamAPlayers.length < 4 || _teamBPlayers.length < 4) {
      _showCustomSnackbar("Each team must have at least 4 players");
      return;
    }

    final updatedMatchData = {
      ...widget.matchData,
      'teamAPlayers': _teamAPlayers,
      'teamBPlayers': _teamBPlayers,
    };

    Navigator.pushNamed(
      context,
      AppRoutes.StartMatch,
      arguments: updatedMatchData,
    );

    // Navigate or pass data as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Center(
                child: Text(
                  "Add Players",
                  style: GoogleFonts.balooBhai2(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildPlayerInputSection(
                        teamName: widget.matchData['teamA'] ?? 'Team A',
                        controller: _teamAPlayerController,
                        playerList: _teamAPlayers,
                      ),
                      _buildPlayerInputSection(
                        teamName: widget.matchData['teamB'] ?? 'Team B',
                        controller: _teamBPlayerController,
                        playerList: _teamBPlayers,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF64DD17)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      "Next",
                      style: GoogleFonts.balooBhai2(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInputSection({
    required String teamName,
    required TextEditingController controller,
    required List<String> playerList,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teamName,
          style: GoogleFonts.balooBhai2(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _gradientBox(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Enter player name",
              labelStyle: GoogleFonts.balooBhai2(color: Colors.white70),
              border: InputBorder.none,
            ),
            onSubmitted: (value) => _addPlayer(value, playerList, controller, teamName),
          ),
        ),
        const SizedBox(height: 10),
        if (playerList.isNotEmpty)
          _gradientBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Added Players:",
                  style: GoogleFonts.balooBhai2(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: playerList
                      .map((player) => Chip(
                    label: Text(player, style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green.shade700,
                    deleteIcon: const Icon(Icons.close, color: Colors.white),
                    onDeleted: () => _removePlayer(player, playerList),
                  ))
                      .toList(),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _gradientBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.black12, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
