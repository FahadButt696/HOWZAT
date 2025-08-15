import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../models/match_model.dart';
import '../../services/match_service.dart';
import '../../services/scorecard_service.dart';
import '../../routes/app_routes.dart'; // For navigation to LiveScore (for Scoreboard/Resume)

// Replicating PlayerStatsModel, BattingStats, BowlingStats, FieldingStats
// If these are already globally defined in your 'models' folder, you can import them instead.
// Assuming for self-containment that these are the simple versions.
import '../../models/player_stats_model.dart'; // Your PlayerModel
import '../../models/batting_stats.dart';
import '../../models/bowling_stats.dart';
import '../../models/fielding_stats.dart';


// --- Helper classes replicated from LiveScoreScreen for Scorecard display ---

// Class to represent a single ball event
class BallEvent {
  final int runs;
  final bool isWicket;
  final bool isWide;
  final bool isNoBall;
  final bool isBye;
  final bool isLegBye;
  final String? wicketReason;
  final String? outBatsmanName;
  final String? fielderName;
  final String? bowlerCreditedName;
  final int? scoreAtWicketFall;

  BallEvent({
    required this.runs,
    this.isWicket = false,
    this.isWide = false,
    this.isNoBall = false,
    this.isBye = false,
    this.isLegBye = false,
    this.wicketReason,
    this.outBatsmanName,
    this.fielderName,
    this.bowlerCreditedName,
    this.scoreAtWicketFall,
  });

  String get detailedDisplayChar {
    if (isWicket) return 'W ${runs}';
    if (isWide) return 'Wd ${runs + 1}';
    if (isNoBall) return 'Nb ${runs + 1}';
    if (isBye) return 'B ${runs}';
    if (isLegBye) return 'LB ${runs}';
    return runs.toString();
  }

  factory BallEvent.fromMap(Map<String, dynamic> map) {
    return BallEvent(
      runs: map['runs'],
      isWicket: map['isWicket'] ?? false,
      isWide: map['isWide'] ?? false,
      isNoBall: map['isNoBall'] ?? false,
      isBye: map['isBye'] ?? false,
      isLegBye: map['isLegBye'] ?? false,
      wicketReason: map['wicketReason'],
      outBatsmanName: map['outBatsmanName'],
      fielderName: map['fielderName'],
      bowlerCreditedName: map['bowlerCreditedName'],
      scoreAtWicketFall: map['scoreAtWicketFall'],
    );
  }

  // NEW: toMap method for BallEvent
  Map<String, dynamic> toMap() {
    return {
      'runs': runs,
      'isWicket': isWicket,
      'isWide': isWide,
      'isNoBall': isNoBall,
      'isBye': isBye,
      'isLegBye': isLegBye,
      'wicketReason': wicketReason,
      'outBatsmanName': outBatsmanName,
      'fielderName': fielderName,
      'bowlerCreditedName': bowlerCreditedName,
      'scoreAtWicketFall': scoreAtWicketFall,
    };
  }
}

// Class to represent an over summary
class Over {
  final int overNumber;
  final String bowlerName;
  final List<BallEvent> balls;
  final int runsConceded;
  final int wicketsTaken;

  Over({
    required this.overNumber,
    required this.bowlerName,
    required this.balls,
    required this.runsConceded,
    required this.wicketsTaken,
  });

  factory Over.fromMap(Map<String, dynamic> map) {
    return Over(
      overNumber: map['overNumber'],
      bowlerName: map['bowlerName'],
      balls: (map['balls'] as List).map((e) => BallEvent.fromMap(e)).toList(),
      runsConceded: map['runsConceded'],
      wicketsTaken: map['wicketsTaken'],
    );
  }

  // NEW: toMap method for Over
  Map<String, dynamic> toMap() {
    return {
      'overNumber': overNumber,
      'bowlerName': bowlerName,
      'balls': balls.map((e) => e.toMap()).toList(),
      'runsConceded': runsConceded,
      'wicketsTaken': wicketsTaken,
    };
  }
}

// Helper class to store player stats specifically for the scorecard display
class _ScorecardPlayerStats {
  final String name;
  BattingStats? battingStats;
  BowlingStats? bowlingStats;
  FieldingStats? fieldingStats;

  _ScorecardPlayerStats({
    required this.name,
    this.battingStats,
    this.bowlingStats,
    this.fieldingStats,
  });

  factory _ScorecardPlayerStats.fromMap(Map<String, dynamic> map) {
    return _ScorecardPlayerStats(
      name: map['name'],
      battingStats: map['battingStats'] != null ? BattingStats.fromMap(map['battingStats']) : null,
      bowlingStats: map['bowlingStats'] != null ? BowlingStats.fromMap(map['bowlingStats']) : null,
      fieldingStats: map['fieldingStats'] != null ? FieldingStats.fromMap(map['fieldingStats']) : null,
    );
  }

  // NEW: toMap method for _ScorecardPlayerStats
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'battingStats': battingStats?.toMap(),
      'bowlingStats': bowlingStats?.toMap(),
      'fieldingStats': fieldingStats?.toMap(),
    };
  }
}

// Class to summarize a completed inning for scorecard display
class _InningSummary {
  final String battingTeamName;
  final String bowlingTeamName;
  final int totalRuns;
  final int totalWickets;
  final double totalOvers;
  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;
  final List<_ScorecardPlayerStats> playerStats;
  final List<Over> oversDetails;
  final List<Map<String, dynamic>> fallOfWickets;

  _InningSummary({
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.totalRuns,
    required this.totalWickets,
    required this.totalOvers,
    required this.wides,
    required this.noBalls,
    required this.byes,
    required this.legByes,
    required this.playerStats,
    required this.oversDetails,
    required this.fallOfWickets,
  });

  factory _InningSummary.fromMap(Map<String, dynamic> map) {
    return _InningSummary(
      battingTeamName: map['battingTeamName'],
      bowlingTeamName: map['bowlingTeamName'],
      totalRuns: map['totalRuns'],
      totalWickets: map['totalWickets'],
      totalOvers: map['totalOvers'],
      wides: map['wides'],
      noBalls: map['noBalls'],
      byes: map['byes'],
      legByes: map['legByes'],
      playerStats: (map['playerStats'] as List).map((e) => _ScorecardPlayerStats.fromMap(e)).toList(),
      oversDetails: (map['oversDetails'] as List).map((e) => Over.fromMap(e)).toList(),
      fallOfWickets: List<Map<String, dynamic>>.from(map['fallOfWickets'] ?? []),
    );
  }

  // NEW: toMap method for _InningSummary
  Map<String, dynamic> toMap() {
    return {
      'battingTeamName': battingTeamName,
      'bowlingTeamName': bowlingTeamName,
      'totalRuns': totalRuns,
      'totalWickets': totalWickets,
      'totalOvers': totalOvers,
      'wides': wides,
      'noBalls': noBalls,
      'byes': byes,
      'legByes': legByes,
      'playerStats': playerStats.map((e) => e.toMap()).toList(),
      'oversDetails': oversDetails.map((e) => e.toMap()).toList(),
      'fallOfWickets': fallOfWickets, // fallOfWickets is already List<Map<String, dynamic>>
    };
  }
}

// --- End of Helper classes from LiveScoreScreen ---


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late MatchService _matchService;
  late ScorecardService _scorecardService;
  List<MatchModel> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initServicesAndFetchMatches();
  }

  Future<void> _initServicesAndFetchMatches() async {
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
      _matchService = MatchService(firestore, appId, currentUser.uid);
      _scorecardService = ScorecardService(firestore, appId, currentUser.uid);
      await _fetchMatches();
    } else {
      setState(() {
        _isLoading = false;
      });
      // Handle scenario where user still isn't available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to authenticate user for history. Please restart.')),
      );
    }
  }

  Future<void> _fetchMatches() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fetchedMatches = await _matchService.getAllMatches();
      // Sort matches by start time descending (most recent first)
      fetchedMatches.sort((a, b) => b.startTime.compareTo(a.startTime));
      setState(() {
        _matches = fetchedMatches;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching matches: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading match history: $e'),
          duration: const Duration(seconds: 2), // Set duration
        ),
      );
    }
  }

  // Removed _deleteMatch method entirely as the button is removed.
  // Future<void> _deleteMatch(String matchId) async { ... }

  // Helper to format overs for display (e.g., 1.3 for 1 over, 3 balls)
  String _formatOversDisplay(double overs) {
    int wholeOvers = overs.floor();
    int balls = ((overs - wholeOvers) * 10).round(); // Assuming .1 increments for balls

    if (balls >= 6) { // Correct for cases like 0.6 -> 1.0, or 1.6 -> 2.0
      wholeOvers += (balls ~/ 6);
      balls = balls % 6;
    }
    return "$wholeOvers.$balls";
  }

  // --- NEW: Dummy Scorecard Data Generator ---
  Map<String, dynamic> _generateDummyScorecardData(String teamA, String teamB, String matchResult) {
    // Dummy batting stats
    final batsman1 = _ScorecardPlayerStats(name: "Batsman 1", battingStats: BattingStats(runs: 75, balls: 50, fours: 8, sixes: 3, innings: 1, notOuts: 0, ducks: 0));
    final batsman2 = _ScorecardPlayerStats(name: "Batsman 2", battingStats: BattingStats(runs: 42, balls: 30, fours: 5, sixes: 1, innings: 1, notOuts: 0, ducks: 0));
    final batsman3 = _ScorecardPlayerStats(name: "Batsman 3", battingStats: BattingStats(runs: 15, balls: 20, fours: 1, sixes: 0, innings: 1, notOuts: 0, ducks: 0));
    final batsman4 = _ScorecardPlayerStats(name: "Batsman 4", battingStats: BattingStats(runs: 0, balls: 1, fours: 0, sixes: 0, innings: 1, notOuts: 0, ducks: 1));
    final batsman5 = _ScorecardPlayerStats(name: "Batsman 5", battingStats: BattingStats(runs: 30, balls: 25, fours: 2, sixes: 1, innings: 1, notOuts: 1, ducks: 0));

    // Dummy bowling stats
    final bowler1 = _ScorecardPlayerStats(name: "Bowler A", bowlingStats: BowlingStats(matches: 1, maidens: 0, runs: 30, wickets: 2, ballsBowled: 24, dotBalls: 10, innings: 1));
    final bowler2 = _ScorecardPlayerStats(name: "Bowler B", bowlingStats: BowlingStats(matches: 1, maidens: 1, runs: 15, wickets: 1, ballsBowled: 18, dotBalls: 8, innings: 1));
    final bowler3 = _ScorecardPlayerStats(name: "Bowler C", bowlingStats: BowlingStats(matches: 1, maidens: 0, runs: 25, wickets: 0, ballsBowled: 12, dotBalls: 4, innings: 1));

    // Dummy fall of wickets
    final fallOfWickets1 = [
      {'batsmanName': batsman1.name, 'batsmanRuns': 75, 'batsmanBalls': 50, 'wicketNumber': 1, 'scoreAtFall': 100, 'oversAtFall': 10.2, 'wicketReason': 'Caught', 'fielderName': 'Fielder X', 'bowlerCreditedName': bowler1.name},
      {'batsmanName': batsman2.name, 'batsmanRuns': 42, 'batsmanBalls': 30, 'wicketNumber': 2, 'scoreAtFall': 145, 'oversAtFall': 15.5, 'wicketReason': 'Bowled', 'fielderName': null, 'bowlerCreditedName': bowler2.name},
      {'batsmanName': batsman3.name, 'batsmanRuns': 15, 'batsmanBalls': 20, 'wicketNumber': 3, 'scoreAtFall': 160, 'oversAtFall': 18.1, 'wicketReason': 'LBW', 'fielderName': null, 'bowlerCreditedName': bowler1.name},
      {'batsmanName': batsman4.name, 'batsmanBalls': 1, 'wicketNumber': 4, 'scoreAtFall': 160, 'oversAtFall': 18.2, 'wicketReason': 'Run Out', 'fielderName': 'Fielder Y', 'bowlerCreditedName': null},
    ];

    // Dummy ball-by-ball for an over (e.g., for oversDetails)
    final dummyOver1 = Over(
      overNumber: 1, bowlerName: bowler1.name!, runsConceded: 6, wicketsTaken: 0,
      balls: [
        BallEvent(runs: 1), BallEvent(runs: 0), BallEvent(runs: 4),
        BallEvent(runs: 0), BallEvent(runs: 1), BallEvent(runs: 0),
      ],
    );
    final dummyOver2 = Over(
      overNumber: 2, bowlerName: bowler2.name!, runsConceded: 3, wicketsTaken: 1,
      balls: [
        BallEvent(runs: 0), BallEvent(runs: 0, isWicket: true, wicketReason: 'Bowled'), BallEvent(runs: 1),
        BallEvent(runs: 0), BallEvent(runs: 1), BallEvent(runs: 0),
      ],
    );


    // Inning 1 Summary
    final inning1Summary = _InningSummary(
      battingTeamName: teamA,
      bowlingTeamName: teamB,
      totalRuns: 198,
      totalWickets: 4,
      totalOvers: 20.0,
      wides: 5,
      noBalls: 2,
      byes: 3,
      legByes: 1,
      playerStats: [batsman1, batsman2, batsman3, batsman4, batsman5, bowler1, bowler2, bowler3], // Include all relevant players
      oversDetails: [dummyOver1, dummyOver2], // Sample overs
      fallOfWickets: fallOfWickets1,
    );

    // Inning 2 Summary (chasing teamB)
    final inning2BattingPlayers = [
      _ScorecardPlayerStats(name: "Chaser 1", battingStats: BattingStats(runs: 90, balls: 60, fours: 10, sixes: 4, innings: 1, notOuts: 1, ducks: 0)),
      _ScorecardPlayerStats(name: "Chaser 2", battingStats: BattingStats(runs: 80, balls: 45, fours: 7, sixes: 5, innings: 1, notOuts: 1, ducks: 0)),
    ];
    final inning2BowlingPlayers = [
      _ScorecardPlayerStats(name: "Bowler X", bowlingStats: BowlingStats(matches: 1, maidens: 0, runs: 40, wickets: 0, ballsBowled: 30, dotBalls: 12, innings: 1)),
      _ScorecardPlayerStats(name: "Bowler Y", bowlingStats: BowlingStats(matches: 1, maidens: 0, runs: 35, wickets: 1, ballsBowled: 23, dotBalls: 7, innings: 1)),
    ];

    final inning2Summary = _InningSummary(
      battingTeamName: teamB,
      bowlingTeamName: teamA,
      totalRuns: 200,
      totalWickets: 1,
      totalOvers: 18.5,
      wides: 2,
      noBalls: 0,
      byes: 1,
      legByes: 0,
      playerStats: [...inning2BattingPlayers, ...inning2BowlingPlayers],
      oversDetails: [], // Can add more dummy overs if needed
      fallOfWickets: [], // No wickets in this dummy inning
    );

    return {
      'finalResult': matchResult,
      'innings': [inning1Summary.toMap(), inning2Summary.toMap()],
    };
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
                "Match History",
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
                  : _matches.isEmpty
                  ? Center(
                child: Text(
                  "No match history found. Play a match to see it here!",
                  style: GoogleFonts.balooBhai2(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  final match = _matches[index];
                  final String teamAInitials = match.teamA.isNotEmpty ? match.teamA.substring(0, 1).toUpperCase() : '?';
                  final String teamBInitials = match.teamB.isNotEmpty ? match.teamB.substring(0, 1).toUpperCase() : '?';

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            DateFormat('dd MMMMyyyy hh:mm a').format(match.startTime),
                            style: GoogleFonts.balooBhai2(color: Colors.white54, fontSize: 12),
                          ),
                        ),
                        Row(
                          children: [
                            _teamCircleAvatar(teamAInitials),
                            const SizedBox(width: 8),
                            Text(
                              match.teamA,
                              style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 18),
                            ),
                            const Spacer(),
                            // Display score/wickets if available from `result` field or fetch from scorecard if needed
                            Text(
                              match.result, // Display the stored result
                              style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _teamCircleAvatar(teamBInitials),
                            const SizedBox(width: 8),
                            Text(
                              match.teamB,
                              style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          match.tossWonBy == match.teamA || match.tossWonBy == match.teamB
                              ? "${match.tossWonBy} won the toss and opted to ${match.optedTo} first."
                              : "Toss: ${match.tossWonBy} opted to ${match.optedTo} first.",
                          style: GoogleFonts.balooBhai2(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (match.status == 'ongoing')
                              _historyActionButton("Resume", Icons.play_arrow, () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Resume functionality coming soon!')),
                                );
                                // TODO: Implement actual resume logic by fetching match/team/player data and navigating to LiveScoreScreen
                              }),
                            _historyActionButton("Scoreboard", Icons.score, () async {
                              // NEW: Generate dummy data instead of fetching from Firestore
                              final dummyScorecardData = _generateDummyScorecardData(
                                match.teamA,
                                match.teamB,
                                match.result, // Use the actual match result in the dummy scorecard
                              );
                              _showDetailedScorecardDialog(dummyScorecardData);
                            }),
                            // REMOVED: Delete Button
                            // _historyActionButton("Delete", Icons.delete, () => _deleteMatch(match.id), isDelete: true),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamCircleAvatar(String initials) {
    return CircleAvatar(
      backgroundColor: Colors.blueGrey.shade700,
      radius: 15,
      child: Text(
        initials,
        style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _historyActionButton(String label, IconData icon, VoidCallback onTap, {bool isDelete = false}) {
    // Note: isDelete parameter is now effectively unused since the delete button is removed.
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDelete ? Colors.redAccent : Colors.lightGreen, // Keeps color logic, though red won't be used now
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          icon: Icon(icon, color: Colors.white, size: 18),
          label: Text(
            label,
            style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  void _showDetailedScorecardDialog(Map<String, dynamic> scorecardData) {
    // Parse the innings summaries from the fetched scorecard data
    List<_InningSummary> inningsSummaries = (scorecardData['innings'] as List)
        .map((inningMap) => _InningSummary.fromMap(inningMap))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF0B6623)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Match Scorecard",
                  style: GoogleFonts.balooBhai2(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white30),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Display all completed innings
                      ...inningsSummaries.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final _InningSummary summary = entry.value;

                        // Separate players into batting and bowling for this summary
                        List<_ScorecardPlayerStats> battingPlayersInSummary = summary.playerStats.where((ps) => ps.battingStats != null).toList();
                        List<_ScorecardPlayerStats> bowlingPlayersInSummary = summary.playerStats.where((ps) => ps.bowlingStats != null).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                              child: Text(
                                "${summary.battingTeamName} - Inning ${index + 1}",
                                style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Batting Card for this team
                            _buildScorecardCard(
                              title: "Batting",
                              child: Column(
                                children: [
                                  _buildBatsmenScorecard(
                                    battingPlayersInSummary.where((ps) => ps.battingStats!.runs > 0 || ps.battingStats!.balls > 0 || summary.fallOfWickets.any((fw) => fw['batsmanName'] == ps.name)).toList(),
                                    isFullScorecard: true,
                                  ),
                                  _buildExtrasRow("Wides:", summary.wides),
                                  _buildExtrasRow("No Balls:", summary.noBalls),
                                  _buildExtrasRow("Byes:", summary.byes),
                                  _buildExtrasRow("Leg Byes:", summary.legByes),
                                  _buildExtrasRow("Total Extras:", summary.wides + summary.noBalls + summary.byes + summary.legByes, isTotal: true),
                                ],
                              ),
                            ),
                            // Bowling Card for the team that bowled to this batting team
                            _buildScorecardCard(
                              title: "Bowling",
                              child: _buildBowlersScorecard(
                                bowlingPlayersInSummary.where((ps) => ps.bowlingStats!.ballsBowled > 0).toList(),
                                isFullScorecard: true,
                              ),
                            ),
                            _buildScorecardSectionHeader("Fall of Wickets"),
                            _buildFallOfWickets(
                              summary.fallOfWickets,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                "Total: ${summary.totalRuns} - ${summary.totalWickets} (${_formatOversDisplay(summary.totalOvers)})",
                                style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Divider(color: Colors.white54, thickness: 2),
                          ],
                        );
                      }),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(
                          "Match Result: ${scorecardData['finalResult']}",
                          style: GoogleFonts.balooBhai2(color: Colors.yellowAccent, fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Helper Widgets from LiveScoreScreen, adapted for HistoryScreen ---

  Widget _buildScorecardCard({required String title, required Widget child}) {
    return Card(
      color: Colors.black.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                title,
                style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(color: Colors.white54),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildScorecardSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBatsmenScorecard(List<dynamic> batsmen, {bool isFullScorecard = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _RowHeader(
            headers: const ['Batsman', 'R', 'B', '4s', '6s', 'SR'],
            textStyle: GoogleFonts.balooBhai2(color: Colors.white60, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white24),
          ...batsmen.map((data) {
            BattingStats batting;
            String name;

            final _ScorecardPlayerStats ps = data as _ScorecardPlayerStats;
            name = ps.name;
            batting = ps.battingStats!;

            return _RowPlayer(
              name: name,
              runs: batting.runs,
              balls: batting.balls,
              fours: batting.fours,
              sixes: batting.sixes,
              sr: batting.strikeRateValue,
              isOnStrike: false, // For historical, no one is "on strike"
              textStyle: GoogleFonts.balooBhai2(color: Colors.white),
            );
          }),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBowlersScorecard(List<dynamic> bowlers, {bool isFullScorecard = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _RowHeader(
            headers: const ['Bowler', 'O', 'M', 'R', 'W', 'ER'],
            textStyle: GoogleFonts.balooBhai2(color: Colors.white60, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white24),
          ...bowlers.map((data) {
            BowlingStats bowling;
            String name;

            final _ScorecardPlayerStats ps = data as _ScorecardPlayerStats;
            name = ps.name;
            bowling = ps.bowlingStats!;

            return _RowPlayer(
              name: name,
              overs: bowling.displayOvers,
              maidens: bowling.maidens,
              runsGiven: bowling.runs,
              wickets: bowling.wickets,
              er: bowling.economyRateValue,
              textStyle: GoogleFonts.balooBhai2(color: Colors.white),
            );
          }),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildFallOfWickets(List<Map<String, dynamic>> fallOfWickets) {
    if (fallOfWickets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "No wickets have fallen yet.",
          style: GoogleFonts.balooBhai2(color: Colors.white70, fontSize: 14),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: fallOfWickets.asMap().entries.map((entry) {
          final Map<String, dynamic> wicketData = entry.value;
          final int displayWicketNumber = wicketData['wicketNumber'] as int;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "$displayWicketNumber. ${wicketData['batsmanName']} (${wicketData['batsmanRuns']} runs)",
                    style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 16),
                  ),
                ),
                Text(
                  "${wicketData['scoreAtFall']} - ${wicketData['wickets']} (${_formatOversDisplay(wicketData['oversAtFall'])})",
                  style: GoogleFonts.balooBhai2(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExtrasRow(String label, int count, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.balooBhai2(
              color: isTotal ? Colors.white : Colors.white70,
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '$count',
            style: GoogleFonts.balooBhai2(
              color: isTotal ? Colors.white : Colors.white70,
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// Replicating _RowHeader and _RowPlayer from LiveScoreScreen for consistent scorecard display
class _RowHeader extends StatelessWidget {
  final List<String> headers;
  final TextStyle textStyle;
  const _RowHeader({required this.headers, required this.textStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: headers.map((h) => Expanded(child: Text(h, style: textStyle))).toList(),
    );
  }
}

class _RowPlayer extends StatelessWidget {
  final String name;
  final int? runs, balls, fours, sixes;
  final bool isOnStrike;
  final double? sr;
  final double? overs;
  final double? er;
  final int? maidens, runsGiven, wickets;
  final TextStyle textStyle;

  const _RowPlayer({
    required this.name,
    this.runs,
    this.balls,
    this.fours,
    this.sixes,
    this.sr,
    this.isOnStrike = false,
    this.overs,
    this.er,
    this.maidens,
    this.runsGiven,
    this.wickets,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text("${name}${isOnStrike ? ' *' : ''}", style: textStyle)),
          if (runs != null) ...[ // This is a batsman row
            Expanded(child: Text("$runs", style: textStyle)),
            Expanded(child: Text("$balls", style: textStyle)),
            Expanded(child: Text("$fours", style: textStyle)),
            Expanded(child: Text("$sixes", style: textStyle)),
            Expanded(child: Text(sr!.toStringAsFixed(2), style: textStyle)),
          ] else if (overs != null) ...[ // This is a bowler row
            Expanded(child: Text(overs!.toStringAsFixed(1), style: textStyle)),
            Expanded(child: Text("$maidens", style: textStyle)),
            Expanded(child: Text("$runsGiven", style: textStyle)),
            Expanded(child: Text("$wickets", style: textStyle)),
            Expanded(child: Text(er!.toStringAsFixed(2), style: textStyle)),
          ] else ...[ // Fallback if neither batsman nor bowler
            Expanded(child: Text("N/A", style: textStyle)),
            Expanded(child: Text("N/A", style: textStyle)),
            Expanded(child: Text("N/A", style: textStyle)),
            Expanded(child: Text("N/A", style: textStyle)),
            Expanded(child: Text("N/A", style: textStyle)),
          ]
        ],
      ),
    );
  }
}
