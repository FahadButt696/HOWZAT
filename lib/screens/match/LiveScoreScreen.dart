import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Assuming these are correctly imported from your project structure
import '../../models/match_model.dart';
import '../../models/team_model.dart';
import '../../models/player_stats_model.dart'; // Your PlayerModel
import '../../models/batting_stats.dart';
import '../../models/bowling_stats.dart';
import '../../models/fielding_stats.dart';

// Import services
import '../../services/match_service.dart';
import '../../services/team_service.dart';
import '../../services/player_service.dart';
import '../../services/scorecard_service.dart';
import '../../routes/app_routes.dart'; // Import AppRoutes for navigation

// IMPORTANT: BallEvent, Over, _ScorecardPlayerStats, _InningSummary are kept here as requested.

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
  final int? scoreAtWicketFall; // Added to store score when wicket fell

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
    this.scoreAtWicketFall, // Initialize here
  });

  String get displayChar {
    if (isWicket) return 'W';
    if (isWide) return 'Wd';
    if (isNoBall) return 'Nb';
    if (isBye) return 'B';
    if (isLegBye) return 'LB';
    return runs.toString();
  }

  String get detailedDisplayChar {
    if (isWicket) return 'W ${runs}';
    if (isWide) return 'Wd ${runs + 1}';
    if (isNoBall) return 'Nb ${runs + 1}';
    if (isBye) return 'B ${runs}';
    if (isLegBye) return 'LB ${runs}';
    return runs.toString();
  }

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
      'scoreAtWicketFall': scoreAtWicketFall, // Added to map
    };
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
      scoreAtWicketFall: map['scoreAtWicketFall'], // Added from map
    );
  }
}

// Class to represent an over summary
class Over {
  final int overNumber;
  final String bowlerName;
  final List<BallEvent> balls;
  int runsConceded;
  int wicketsTaken;

  Over({
    required this.overNumber,
    required this.bowlerName,
    required this.balls,
    this.runsConceded = 0,
    this.wicketsTaken = 0,
  }) {
    // Recalculate runsConceded and wicketsTaken from balls list if not provided
    if (runsConceded == 0 && wicketsTaken == 0) {
      for (var ball in balls) {
        runsConceded += ball.runs;
        if (ball.isWide) runsConceded += 1;
        if (ball.isNoBall) runsConceded += 1;
        if (ball.isWicket) wicketsTaken += 1;
      }
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'overNumber': overNumber,
      'bowlerName': bowlerName,
      'balls': balls.map((e) => e.toMap()).toList(),
      'runsConceded': runsConceded,
      'wicketsTaken': wicketsTaken,
    };
  }

  factory Over.fromMap(Map<String, dynamic> map) {
    return Over(
      overNumber: map['overNumber'],
      bowlerName: map['bowlerName'],
      balls: (map['balls'] as List).map((e) => BallEvent.fromMap(e)).toList(),
      runsConceded: map['runsConceded'],
      wicketsTaken: map['wicketsTaken'],
    );
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'battingStats': battingStats?.toMap(),
      'bowlingStats': bowlingStats?.toMap(),
      'fieldingStats': fieldingStats?.toMap(),
    };
  }

  factory _ScorecardPlayerStats.fromMap(Map<String, dynamic> map) {
    return _ScorecardPlayerStats(
      name: map['name'],
      battingStats: map['battingStats'] != null ? BattingStats.fromMap(map['battingStats']) : null,
      bowlingStats: map['bowlingStats'] != null ? BowlingStats.fromMap(map['bowlingStats']) : null,
      fieldingStats: map['fieldingStats'] != null ? FieldingStats.fromMap(map['fieldingStats']) : null,
    );
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
  final List<Map<String, dynamic>> fallOfWickets; // Changed to store details

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
    required this.fallOfWickets, // Updated constructor
  });

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
      'fallOfWickets': fallOfWickets, // Storing directly
    };
  }

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
      fallOfWickets: List<Map<String, dynamic>>.from(map['fallOfWickets'] ?? []), // Retrieve
    );
  }
}


class LiveScoreScreen extends StatefulWidget {
  final String userId;
  final MatchModel match;
  final TeamModel teamA; // Team A, which contains PlayerModels
  final TeamModel teamB; // Team B, which contains PlayerModels

  const LiveScoreScreen({
    super.key,
    required this.userId,
    required this.match,
    required this.teamA,
    required this.teamB,
  });

  @override
  State<LiveScoreScreen> createState() => _LiveScoreScreenState();
}

class _LiveScoreScreenState extends State<LiveScoreScreen> {
  // --- Game State ---
  int _currentInning = 1;
  int _totalRuns = 0;
  int _totalWickets = 0;
  double _totalOvers = 0.0; // E.g., 1.3 means 1 over and 3 balls (display format)
  int _currentBallInOver = 0; // 0-5 for a normal over
  int _currentOverCount = 0;

  // Innings Scores
  int _innings1TotalRuns = 0;
  int _innings1TotalWickets = 0;
  String _matchResult = "Ongoing"; // Stores the final match result

  // Target for 2nd inning
  int _targetRuns = 0;

  // Player objects for the current inning
  late TeamModel _currentBattingTeam;
  late TeamModel _currentBowlingTeam;
  // Use a map to quickly access player objects by name for live updates
  late Map<String, PlayerModel> _battingPlayersMap;
  late Map<String, PlayerModel> _bowlingPlayersMap;

  late PlayerModel _striker;
  late PlayerModel _nonStriker;
  late PlayerModel _bowler;

  // Players who are currently dismissed (stored by name to prevent re-instantiation issues)
  late List<String> _dismissedBatsmenNames;
  // Details of each wicket as it falls
  List<Map<String, dynamic>> _fallOfWicketsDetails = []; // NEW: Stores score, wicket number etc.

  // Index for getting next batsman from _battingOrderPlayers
  int _nextBatsmanIndex = 2; // Assuming striker and non-striker are first two

  // Wicket Details (captured right before wicket is processed)
  String? _wicketReason;
  String? _fielderName; // If caught/run out
  String? _outBowlerName; // The bowler who took the wicket (might be different from current if run out)

  // In-inning extras
  int _currentInningWides = 0;
  int _currentInningNoBalls = 0;
  int _currentInningByes = 0;
  int _currentInningLegByes = 0;

  // For Two-Step Delivery Input
  String? _selectedDeliveryType; // 'normal', 'wide', 'noBall', 'wicket', 'bye', 'legBye'

  // Ball-by-ball and Over tracking for scorecards
  List<Over> _currentInningsOvers = []; // Stores completed overs for current inning
  List<BallEvent> _currentOverBalls = []; // Stores balls in the current uncompleted over

  // Stores summaries of completed innings for final scorecard
  List<_InningSummary> _completedInningsSummaries = [];

  // For Undo functionality: store a deep copy of the relevant state
  Map<String, dynamic>? _lastAction;

  // Control visibility of "Go to Home" button
  bool _showGoToHomeButton = false; // New state variable

  // Firebase instances and services
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;
  late MatchService _matchService;
  late TeamService _teamService;
  late PlayerService _playerService;
  late ScorecardService _scorecardService;

  @override
  void initState() {
    super.initState();
    _initFirebase();
    _initializeInning(1);
    _initializeMatchPlayerStatsInFirestore(); // Call the new initialization for match-specific player stats
  }

  void _initFirebase() {
    // Initialize Firebase if not already initialized
    if (Firebase.apps.isEmpty) {
      // Access global firebaseConfig variable provided by the Canvas environment
      final firebaseConfig = Map<String, dynamic>.from(const String.fromEnvironment('FIREBASE_CONFIG') == ''
          ? {}
          : Map<String, dynamic>.from(const String.fromEnvironment('FIREBASE_CONFIG') as dynamic));

      Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: firebaseConfig['apiKey'] ?? '',
          appId: firebaseConfig['appId'] ?? '',
          messagingSenderId: firebaseConfig['messagingSenderId'] ?? '',
          projectId: firebaseConfig['projectId'] ?? '',
          storageBucket: firebaseConfig['storageBucket'] ?? '',
        ),
      );
    }

    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;

    // Access global __app_id variable provided by the Canvas environment
    final appId = const String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');

    // Ensure user is signed in. Using a custom token for Canvas environment.
    // If __initial_auth_token is provided, sign in with it. Otherwise, sign in anonymously.
    final initialAuthToken = const String.fromEnvironment('INITIAL_AUTH_TOKEN');
    if (initialAuthToken.isNotEmpty) {
      _auth.signInWithCustomToken(initialAuthToken).then((_) {
        print("Signed in with custom token.");
      }).catchError((e) {
        print("Error signing in with custom token: $e");
        _auth.signInAnonymously().then((_) {
          print("Signed in anonymously as fallback.");
        }).catchError((e) {
          print("Error signing in anonymously: $e");
        });
      });
    } else {
      _auth.signInAnonymously().then((_) {
        print("Signed in anonymously as no custom token provided.");
      }).catchError((e) {
        print("Error signing in anonymously: $e");
      });
    }

    // Initialize services with the current user's ID and app ID
    // We assume _auth.currentUser.uid is available after sign-in.
    // For simplicity here, we use widget.userId, but in a real app,
    // you'd typically listen to onAuthStateChanged to ensure uid is ready.
    _matchService = MatchService(_firestore, appId, widget.userId);
    _teamService = TeamService(_firestore, appId, widget.userId);
    _playerService = PlayerService(_firestore, appId, widget.userId);
    _scorecardService = ScorecardService(_firestore, appId, widget.userId);
  }

  // New: Method to initialize match-specific player stats in Firestore
  void _initializeMatchPlayerStatsInFirestore() async {
    // Collect all players from both teams (IDs and names) for initial saving
    List<PlayerModel> allPlayers = [];
    allPlayers.addAll(widget.teamA.players);
    allPlayers.addAll(widget.teamB.players);

    // Filter for unique players if there's overlap (e.g., if a player exists in both lists)
    Set<String> playerIds = {};
    List<PlayerModel> uniquePlayers = [];
    for (var player in allPlayers) {
      if (!playerIds.contains(player.id)) {
        uniquePlayers.add(PlayerModel(
          id: player.id,
          name: player.name,
          batting: BattingStats(), // Initialize with zero stats for this match's record
          bowling: BowlingStats(),
          fielding: FieldingStats(),
        ));
        playerIds.add(player.id);
      }
    }

    // Save initial (zero) stats for all players for this specific match
    await _playerService.initializeMatchPlayerStats(
      matchId: widget.match.id,
      players: uniquePlayers,
    );
  }


  void _initializeInning(int inningNumber) {
    setState(() {
      _currentInning = inningNumber;
      _totalRuns = 0;
      _totalWickets = 0;
      _totalOvers = 0.0;
      _currentBallInOver = 0;
      _currentOverCount = 0;
      _dismissedBatsmenNames = [];
      _fallOfWicketsDetails = []; // Reset fall of wickets for new inning
      _nextBatsmanIndex = 2; // Reset for new inning
      _wicketReason = null;
      _fielderName = null;
      _outBowlerName = null;
      _currentInningWides = 0;
      _currentInningNoBalls = 0;
      _currentInningByes = 0;
      _currentInningLegByes = 0;
      _selectedDeliveryType = null; // Reset selected delivery type
      _currentInningsOvers = []; // Clear previous innings data
      _currentOverBalls = []; // Clear current over balls

      if (inningNumber == 1) {
        // Determine who bats first based on toss
        final String teamAname = widget.match.teamA;
        final String teamBname = widget.match.teamB;
        final String tossWinner = widget.match.tossWonBy;
        final String opted = widget.match.optedTo;

        if ((tossWinner == teamAname && opted == 'bat') ||
            (tossWinner == teamBname && opted == 'bowl')) {
          _currentBattingTeam = widget.teamA;
          _currentBowlingTeam = widget.teamB;
        } else {
          _currentBattingTeam = widget.teamB;
          _currentBowlingTeam = widget.teamA;
        }

        // Initialize PlayerModels with fresh stats for the match
        _battingPlayersMap = {
          for (var p in _currentBattingTeam.players)
            p.name: PlayerModel(
                id: p.id,
                name: p.name,
                batting: BattingStats(), // Fresh stats for this match/inning
                bowling: BowlingStats(),
                fielding: FieldingStats())
        };
        _bowlingPlayersMap = {
          for (var p in _currentBowlingTeam.players)
            p.name: PlayerModel(
                id: p.id,
                name: p.name,
                batting: BattingStats(),
                bowling: BowlingStats(), // Fresh stats for this match/inning
                fielding: FieldingStats())
        };
      } else {
        // Swap teams for 2nd inning
        final tempTeam = _currentBattingTeam;
        _currentBattingTeam = _currentBowlingTeam;
        _currentBowlingTeam = tempTeam;

        // For the 2nd inning, reuse the PlayerModel instances from the *initial* setup
        // so their stats are consistent across innings (though we're only tracking current inning for now)
        // More robust solution would involve deep cloning PlayerModels at match start.
        _battingPlayersMap = {
          for (var p in _currentBattingTeam.players) p.name: p // Reuse existing instances
        };
        _bowlingPlayersMap = {
          for (var p in _currentBowlingTeam.players) p.name: p // Reuse existing instances
        };

        _targetRuns = _innings1TotalRuns + 1; // Target is 1st inning score + 1
      }

      // Set initial striker, non-striker, and bowler for the inning
      if (_battingPlayersMap.keys.length >= 2) {
        _striker = _battingPlayersMap[widget.match.striker] ?? _battingPlayersMap.values.elementAt(0);
        _nonStriker = _battingPlayersMap[widget.match.nonStriker] ?? _battingPlayersMap.values.elementAt(1);
      } else if (_battingPlayersMap.keys.isNotEmpty) {
        _striker = _battingPlayersMap.values.elementAt(0);
        _nonStriker = _battingPlayersMap.values.elementAt(0); // Fallback if only one player
      } else {
        // Handle no players scenario (should not happen in a real match)
        _striker = PlayerModel(id: 'dummy1', name: 'N/A', batting: BattingStats(), bowling: BowlingStats(), fielding: FieldingStats());
        _nonStriker = PlayerModel(id: 'dummy2', name: 'N/A', batting: BattingStats(), bowling: BowlingStats(), fielding: FieldingStats());
      }

      _bowler = _bowlingPlayersMap[widget.match.bowler] ?? _bowlingPlayersMap.values.elementAt(0);

      // Increment innings played for players at the start of their batting/bowling
      // This logic should be carefully managed if players can bat/bowl in multiple innings.
      // For this app, assuming 1st inning starts with fresh stats for each player.
      _striker.batting.innings++;
      _nonStriker.batting.innings++;
      _bowler.bowling.innings++;
    });
  }

  // Helper to save current relevant state for undo - REMOVED from use, but keeping the method for now
  Map<String, dynamic> _saveCurrentState() {
    return {
      'currentInning': _currentInning,
      'totalRuns': _totalRuns,
      'totalWickets': _totalWickets,
      'totalOvers': _totalOvers,
      'currentBallInOver': _currentBallInOver,
      'currentOverCount': _currentOverCount,
      'innings1TotalRuns': _innings1TotalRuns,
      'innings1TotalWickets': _innings1TotalWickets,
      'targetRuns': _targetRuns,
      'strikerName': _striker.name,
      'nonStrikerName': _nonStriker.name,
      'bowlerName': _bowler.name,
      'strikerBatting': _striker.batting.toMap(), // Save full stats map
      'nonStrikerBatting': _nonStriker.batting.toMap(),
      'bowlerBowling': _bowler.bowling.toMap(),
      'dismissedBatsmenNames': List<String>.from(_dismissedBatsmenNames),
      'fallOfWicketsDetails': List<Map<String, dynamic>>.from(_fallOfWicketsDetails), // Save fall of wickets
      'nextBatsmanIndex': _nextBatsmanIndex,
      'wicketReason': _wicketReason,
      'fielderName': _fielderName,
      'outBowlerName': _outBowlerName,
      'currentInningWides': _currentInningWides,
      'currentInningNoBalls': _currentInningNoBalls,
      'currentInningByes': _currentInningByes,
      'currentInningLegByes': _currentInningLegByes,
      'selectedDeliveryType': _selectedDeliveryType,
      'currentInningsOvers': _currentInningsOvers.map((o) => o.toMap()).toList(),
      'currentOverBalls': _currentOverBalls.map((b) => b.toMap()).toList(),
      'completedInningsSummaries': _completedInningsSummaries.map((s) => s.toMap()).toList(), // Use toMap() for _InningSummary
    };
  }

  void _restoreState(Map<String, dynamic> state) {
    setState(() {
      _currentInning = state['currentInning'];
      _totalRuns = state['totalRuns'];
      _totalWickets = state['totalWickets'];
      _totalOvers = state['totalOvers'];
      _currentBallInOver = state['currentBallInOver'];
      _currentOverCount = state['currentOverCount'];
      _innings1TotalRuns = state['innings1TotalRuns'];
      _innings1TotalWickets = state['innings1TotalWickets'];
      _targetRuns = state['targetRuns'];
      _wicketReason = state['wicketReason'];
      _fielderName = state['fielderName'];
      _outBowlerName = state['outBowlerName'];
      _currentInningWides = state['currentInningWides'];
      _currentInningNoBalls = state['currentInningNoBalls'];
      _currentInningByes = state['currentInningByes'];
      _currentInningLegByes = state['currentInningLegByes'];
      _selectedDeliveryType = state['selectedDeliveryType'];

      // Restore player references and their stats by looking them up in the original team lists
      // Important: Re-assign the stats objects, don't just rely on name
      _striker = _battingPlayersMap[state['strikerName']]!
        ..batting = BattingStats.fromMap(state['strikerBatting']);
      _nonStriker = _battingPlayersMap[state['nonStrikerName']]!
        ..batting = BattingStats.fromMap(state['nonStrikerBatting']);
      _bowler = _bowlingPlayersMap[state['bowlerName']]!
        ..bowling = BowlingStats.fromMap(state['bowlerBowling']);

      _dismissedBatsmenNames = List<String>.from(state['dismissedBatsmenNames']);
      _fallOfWicketsDetails = List<Map<String, dynamic>>.from(state['fallOfWicketsDetails'] ?? []); // Restore fall of wickets
      _nextBatsmanIndex = state['nextBatsmanIndex'];

      _currentInningsOvers = (state['currentInningsOvers'] as List)
          .map((e) => Over.fromMap(e))
          .toList();
      _currentOverBalls = (state['currentOverBalls'] as List)
          .map((e) => BallEvent.fromMap(e))
          .toList();

      _completedInningsSummaries = (state['completedInningsSummaries'] as List).map((map) {
        return _InningSummary.fromMap(map); // Use fromMap() for _InningSummary
      }).toList();
    });
  }

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

  // --- Core Game Logic ---
  Future<void> _handleDelivery(int runsScored) async {
    // Prevent actions if match is over
    if (_matchResult != "Ongoing") return;

    // Save state before processing delivery (removed as undo is removed)
    // _lastAction = _saveCurrentState();

    bool isLegalDelivery = true; // Does this delivery count as a ball in the over?
    String? currentDeliveryType = _selectedDeliveryType; // Capture for processing

    // Allow 0 runs (dot ball) without requiring a special delivery type selection
    if (runsScored == 0 && currentDeliveryType == null) {
      currentDeliveryType = 'normal';
    } else if (runsScored > 0 && currentDeliveryType == null) {
      // For runs > 0, if no special type is selected, it's a normal delivery
      currentDeliveryType = 'normal';
    }


    // Ensure a delivery type is now determined
    if (currentDeliveryType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select a delivery type (Wide, No Ball, Wicket, Byes, Leg Byes) or tap 0 for a dot ball!"),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }


    // Reset wicket details for the new delivery unless it's a wicket
    if (currentDeliveryType != 'wicket') {
      _wicketReason = null;
      _fielderName = null;
      _outBowlerName = null;
    }

    // Prepare BallEvent details
    bool isWicketEvent = currentDeliveryType == 'wicket';
    bool isWideEvent = currentDeliveryType == 'wide';
    bool isNoBallEvent = currentDeliveryType == 'noBall';
    bool isByeEvent = currentDeliveryType == 'bye';
    bool isLegByeEvent = currentDeliveryType == 'legBye';

    // Handle Extras (Wide, No Ball, Bye, Leg Bye)
    if (isWideEvent) {
      _totalRuns += (runsScored + 1); // 1 extra for wide, plus any runs taken
      _bowler.bowling.runs += (runsScored + 1);
      _bowler.bowling.wides++;
      _currentInningWides += (runsScored + 1); // Track current inning wides
      isLegalDelivery = false; // Wide doesn't count as a legal ball
    } else if (isNoBallEvent) {
      _totalRuns += (runsScored + 1); // 1 extra for no ball, plus any runs taken
      _bowler.bowling.runs += (runsScored + 1);
      _bowler.bowling.noBalls++;
      _currentInningNoBalls += (runsScored + 1); // Track current inning no balls
      isLegalDelivery = false; // No ball doesn't count as a legal ball
    } else if (isByeEvent) {
      _totalRuns += runsScored; // Runs added to total, but not to batsman's runs
      _bowler.bowling.runs += runsScored; // Bowler still concedes these runs
      _striker.batting.balls++; // Striker faces a ball (even if byes)
      _currentInningByes += runsScored; // Track current inning byes
    } else if (isLegByeEvent) {
      _totalRuns += runsScored; // Runs added to total, but not to batsman's runs
      _bowler.bowling.runs += runsScored; // Bowler still concedes these runs
      _striker.batting.balls++; // Striker faces a ball (even if legbyes)
      _currentInningLegByes += runsScored; // Track current inning leg byes
    } else {
      // Normal delivery
      _totalRuns += runsScored;
      _striker.batting.runs += runsScored;
      _striker.batting.balls++;
      _bowler.bowling.runs += runsScored;

      if (runsScored == 0) {
        _bowler.bowling.dotBalls++;
      } else if (runsScored == 4) {
        _striker.batting.fours++;
      } else if (runsScored == 6) {
        _striker.batting.sixes++;
      }
    }

    // Increment ball count if it's a legal delivery (not wide/no-ball)
    if (isLegalDelivery) {
      _currentBallInOver++;
      _bowler.bowling.ballsBowled++; // Increment total balls bowled for this bowler
    }

    // --- Handle Wicket (if applicable) ---
    if (isWicketEvent) {
      await _showWicketDetailsDialog(); // This dialog sets _wicketReason, _fielderName, _outBowlerName
      _totalWickets++;

      // Only increment bowler's wicket count if it's a "bowler wicket" type
      if (_wicketReason != 'Run Out' && _wicketReason != 'Obstructing the Field') {
        _bowler.bowling.wickets++; // Credited to the current bowler
      }
      // If a fielder was involved, update their fielding stats (simplified)
      if (_fielderName != null) {
        final fielder = _bowlingPlayersMap[_fielderName]!;
        if (_wicketReason == 'Caught') {
          fielder.fielding.catches++;
        } else if (_wicketReason == 'Run Out') {
          fielder.fielding.runOuts++;
        } else if (_wicketReason == 'Stumped') {
          fielder.fielding.stumpings++;
        }
      }

      if (_striker.batting.runs == 0 && _striker.batting.balls > 0) {
        _striker.batting.ducks++;
      }
      _striker.batting.notOuts = 0; // A dismissed batsman is not out

      // Add to dismissed batsmen list
      _dismissedBatsmenNames.add(_striker.name);
      // Record fall of wicket details
      _fallOfWicketsDetails.add({
        'batsmanName': _striker.name,
        'batsmanRuns': _striker.batting.runs,
        'batsmanBalls': _striker.batting.balls,
        'wicketNumber': _totalWickets,
        'scoreAtFall': _totalRuns,
        'oversAtFall': _currentOverCount + (_currentBallInOver / 6.0),
        'wicketReason': _wicketReason,
        'fielderName': _fielderName,
        'bowlerCreditedName': _outBowlerName,
      });

      // Add this ball to current over's balls *before* finding next batsman
      _currentOverBalls.add(BallEvent(
        runs: runsScored,
        isWicket: isWicketEvent,
        isWide: isWideEvent,
        isNoBall: isNoBallEvent,
        isBye: isByeEvent,
        isLegBye: isLegByeEvent,
        wicketReason: _wicketReason,
        outBatsmanName: _striker.name,
        fielderName: _fielderName,
        bowlerCreditedName: _outBowlerName,
        scoreAtWicketFall: _totalRuns, // Store score at fall of wicket
      ));

      if (_totalWickets < _battingPlayersMap.length - 1) { // Not all out yet (at least 2 players remaining for last wicket)
        PlayerModel? newBatsman;
        // Iterate through all players to find the next one not yet dismissed
        for (int i = 0; i < (_currentBattingTeam.players.length); i++) { // Use currentBattingTeam for active players
          final candidateName = _currentBattingTeam.players[i].name;
          final candidate = _battingPlayersMap[candidateName]!;

          // Find a player who hasn't been dismissed AND is not the current non-striker
          if (!_dismissedBatsmenNames.contains(candidate.name) && candidate.name != _nonStriker.name) {
            newBatsman = candidate;
            break;
          }
        }

        if (newBatsman != null) {
          setState(() {
            _striker = newBatsman!;
            _striker.batting.innings++;
          });
        } else {
          _endInning(); // Should mean all out
          return;
        }
      } else {
        _endInning(); // All out
        return;
      }
    } else {
      // If not a wicket, add the ball event
      _currentOverBalls.add(BallEvent(
        runs: runsScored,
        isWide: isWideEvent,
        isNoBall: isNoBallEvent,
        isBye: isByeEvent,
        isLegBye: isLegByeEvent,
      ));
    }


    // Update state after handling events
    setState(() {
      _selectedDeliveryType = null; // Reset for next delivery

      // Check for over completion or innings end
      if (isLegalDelivery && _currentBallInOver == 6) { // Only complete over on legal deliveries
        _currentOverCount++;
        _totalOvers = _currentOverCount.toDouble(); // Full overs
        _currentBallInOver = 0; // Reset balls in over for new over

        // Add current over to innings history
        _currentInningsOvers.add(Over(
          overNumber: _currentOverCount,
          bowlerName: _bowler.name,
          balls: List.from(_currentOverBalls), // Deep copy current balls
        ));
        _currentOverBalls.clear(); // Clear for next over

        // End of over: swap strike if runs scored on this ball are odd and not a wicket
        if (runsScored % 2 != 0 && currentDeliveryType != 'wicket') {
          _swapStrike();
        }

        // Check if overs limit reached
        if (_currentOverCount == widget.match.overs) {
          _endInning();
          return;
        }

        // Prompt for new bowler
        _showNewBowlerDialog();
      } else if (isLegalDelivery) { // Not end of over, but a legal delivery
        // Update total overs as fraction (for display)
        // This makes 0.1, 0.2 ... 0.5 then 1.0, 1.1 etc.
        _totalOvers = _currentOverCount + (_currentBallInOver / 10.0);

        // Swap strike if odd runs on this ball (and not a wicket)
        if (runsScored % 2 != 0 && currentDeliveryType != 'wicket') {
          _swapStrike();
        }
      }
      // If not a legal delivery (wide/no-ball), currentBallInOver and _totalOvers are not updated.
      // Strike does not swap unless it's a "run" on an extra.

      // Check for match winning condition if in 2nd inning
      if (_currentInning == 2 && _totalRuns >= _targetRuns) {
        if (_totalRuns > _innings1TotalRuns) {
          _endMatch("${_currentBattingTeam.name} won by ${_currentBattingTeam.players.length - 1 - _totalWickets} wickets"); // Adjusted wicket count for display
        } else if (_totalRuns == _innings1TotalRuns) {
          _endMatch("Match Tied!");
        }
        return;
      }

      // Check for all out if in 2nd inning and target not met
      if (_currentInning == 2 && _totalWickets == (_currentBattingTeam.players.length - 1) && _totalRuns < _targetRuns) {
        _endMatch("${_currentBowlingTeam.name} won by ${(_targetRuns - _totalRuns) - 1} runs"); // Target difference - 1
        return;
      }
    });
  }

  void _swapStrike() {
    setState(() {
      PlayerModel temp = _striker;
      _striker = _nonStriker;
      _nonStriker = temp;
    });
  }

  // Removed _handleUndo as requested
  /*
  void _handleUndo() {
    if (_lastAction != null) {
      _restoreState(_lastAction!);
      _lastAction = null; // Clear last action after undo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Last action undone!"),
            behavior: SnackBarBehavior.floating),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No action to undo!"),
            behavior: SnackBarBehavior.floating),
      );
    }
  }
  */

  Future<void> _showWicketDetailsDialog() async {
    String? selectedReason;
    PlayerModel? selectedFielder;
    PlayerModel? selectedBowler; // The bowler who took the wicket (if applicable)

    // Pre-select bowler as current bowler if not a run out
    selectedBowler = _bowler;

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // User must select details
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.black.withOpacity(0.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Text("Wicket Details", style: GoogleFonts.balooBhai2(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildDropdown(
                      "Reason for Out",
                      selectedReason,
                      [
                        'Bowled',
                        'Caught',
                        'LBW',
                        'Run Out',
                        'Stumped',
                        'Hit Wicket',
                        'Obstructing the Field',
                      ],
                          (value) {
                        setDialogState(() {
                          selectedReason = value;
                          // If it's a bowler-credited wicket, default selectedBowler to current bowler
                          if (selectedReason == 'Bowled' ||
                              selectedReason == 'LBW' ||
                              selectedReason == 'Hit Wicket') {
                            selectedFielder = null; // No fielder for these
                            selectedBowler = _bowler;
                          } else if (selectedReason == 'Run Out' || selectedReason == 'Obstructing the Field') {
                            selectedBowler = null; // No bowler credited for run out
                          } else { // Caught, Stumped
                            selectedBowler = _bowler; // Bowler is credited for caught/stumped
                          }
                        });
                      },
                    ),
                    if (selectedReason == 'Caught' || selectedReason == 'Run Out' || selectedReason == 'Stumped')
                      _buildDropdown(
                        "Fielder (if any)",
                        selectedFielder?.name,
                        _currentBowlingTeam.players.map((p) => p.name).toList(),
                            (value) {
                          setDialogState(() {
                            selectedFielder = _bowlingPlayersMap[value]!;
                          });
                        },
                      ),
                    // Only show bowler dropdown if a bowler is credited for the wicket
                    if (selectedReason != 'Run Out' && selectedReason != 'Obstructing the Field')
                      _buildDropdown(
                        "Bowler Who Took Wicket",
                        selectedBowler?.name,
                        _bowlingPlayersMap.values.map((p) => p.name).toList(),
                            (value) {
                          setDialogState(() {
                            selectedBowler = _bowlingPlayersMap[value]!;
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text("Confirm", style: GoogleFonts.balooBhai2(color: Colors.lightGreenAccent)),
                  onPressed: () {
                    if (selectedReason == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a reason for out!"), behavior: SnackBarBehavior.floating),
                      );
                      return;
                    }
                    if ((selectedReason == 'Caught' || selectedReason == 'Stumped') && selectedFielder == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a fielder!"), behavior: SnackBarBehavior.floating),
                      );
                      return;
                    }
                    // For Run Out, fielder is mandatory. Bowler is optional (e.g. direct hit)
                    if (selectedReason == 'Run Out' && selectedFielder == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a fielder for Run Out!"), behavior: SnackBarBehavior.floating),
                      );
                      return;
                    }

                    setState(() {
                      _wicketReason = selectedReason;
                      _fielderName = selectedFielder?.name;
                      _outBowlerName = selectedBowler?.name; // Can be null for run out
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown(String label, String? currentValue, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.balooBhai2(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        value: currentValue,
        dropdownColor: Colors.black.withOpacity(0.9),
        style: GoogleFonts.balooBhai2(color: Colors.white),
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _showNewBowlerDialog() async {
    PlayerModel? newBowler;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.black.withOpacity(0.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Text("Select New Bowler", style: GoogleFonts.balooBhai2(color: Colors.white)),
              content: DropdownButtonFormField<PlayerModel>(
                decoration: InputDecoration(
                  labelText: "Bowler",
                  labelStyle: GoogleFonts.balooBhai2(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                value: newBowler,
                dropdownColor: Colors.black.withOpacity(0.9),
                style: GoogleFonts.balooBhai2(color: Colors.white),
                items: _bowlingPlayersMap.values.map((PlayerModel player) {
                  return DropdownMenuItem<PlayerModel>(
                    value: player,
                    child: Text(player.name),
                  );
                }).toList(),
                onChanged: (PlayerModel? newValue) {
                  setDialogState(() {
                    newBowler = newValue;
                  });
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: Text("Confirm", style: GoogleFonts.balooBhai2(color: Colors.lightGreenAccent)),
                  onPressed: () {
                    if (newBowler != null) {
                      setState(() {
                        _bowler = newBowler!;
                        // Increment bowler's innings if it's their first over in this match
                        // This logic relies on `innings` being 0 for a new player or a player not yet bowled this match
                        // Added a flag to BattingStats/BowlingStats to accurately track if they participated in this *specific* match.
                        if (_bowler.bowling.innings == 0) { // Assuming innings is incremented only once per match per role
                          _bowler.bowling.innings++;
                          // A simpler flag if not explicitly in BattingStats:
                          // _bowler.bowling.bowledInThisMatch = true;
                        }
                      });
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a bowler!"), behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _endInning() {
    setState(() {
      // If the current over is not complete, add it to innings overs before ending inning
      if (_currentOverBalls.isNotEmpty) {
        _currentInningsOvers.add(Over(
          overNumber: _currentOverCount + (_currentBallInOver > 0 ? 1 : 0),
          bowlerName: _bowler.name,
          balls: List.from(_currentOverBalls),
        ));
      }
      _currentOverBalls.clear(); // Clear for next inning/match end

      // Capture all current player stats for the scorecard for this inning
      List<_ScorecardPlayerStats> currentInningPlayerStats = [];
      for (var playerEntry in _battingPlayersMap.entries) {
        // Only include players who actually participated (batted or bowled) in this inning
        if (playerEntry.value.batting.runs > 0 || playerEntry.value.batting.balls > 0 || _dismissedBatsmenNames.contains(playerEntry.key)) {
          currentInningPlayerStats.add(_ScorecardPlayerStats(
            name: playerEntry.key,
            battingStats: playerEntry.value.batting,
          ));
        }
      }
      for (var playerEntry in _bowlingPlayersMap.entries) {
        if (playerEntry.value.bowling.ballsBowled > 0 || playerEntry.value.bowling.wickets > 0) {
          currentInningPlayerStats.add(_ScorecardPlayerStats(
            name: playerEntry.key,
            bowlingStats: playerEntry.value.bowling,
            fieldingStats: playerEntry.value.fielding, // Also include fielding stats
          ));
        }
      }

      // Create summary for the completed inning and add it to the list
      _completedInningsSummaries.add(_InningSummary(
        battingTeamName: _currentBattingTeam.name,
        bowlingTeamName: _currentBowlingTeam.name,
        totalRuns: _totalRuns,
        totalWickets: _totalWickets,
        totalOvers: _currentOverCount + (_currentBallInOver / 6.0), // Actual total overs
        wides: _currentInningWides,
        noBalls: _currentInningNoBalls,
        byes: _currentInningByes,
        legByes: _currentInningLegByes,
        playerStats: currentInningPlayerStats,
        oversDetails: List.from(_currentInningsOvers), // Deep copy
        fallOfWickets: List.from(_fallOfWicketsDetails), // Pass fall of wickets details
      ));


      if (_currentInning == 1) {
        _innings1TotalRuns = _totalRuns;
        _innings1TotalWickets = _totalWickets;
        _targetRuns = _innings1TotalRuns + 1; // Set target for 2nd inning
        _showInningsBreakDialog();
      } else {
        // 2nd inning ends due to overs or all out, and target not met
        // The _InningSummary for 2nd inning has already been added above.
        String finalResult;
        if (_totalRuns < _targetRuns - 1) { // If less than target
          finalResult = "${_currentBowlingTeam.name} won by ${(_targetRuns - 1) - _totalRuns} runs";
        } else if (_totalRuns == _targetRuns -1) { // If target matched exactly (tied)
          finalResult = "Match Tied!";
        } else { // This else should ideally be caught by _handleDelivery winning condition
          finalResult = "Match Resulted in Unexpected State"; // Fallback for unexpected state
        }
        _endMatch(finalResult);
      }
    });
  }

  void _showInningsBreakDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Innings Break", style: GoogleFonts.balooBhai2(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            "${_currentBattingTeam.name} finished with $_totalRuns - $_totalWickets in ${widget.match.overs} overs.\n"
                "${_currentBowlingTeam.name} needs $_targetRuns runs to win.",
            style: GoogleFonts.balooBhai2(color: Colors.white70, fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Start 2nd Innings", style: GoogleFonts.balooBhai2(color: Colors.lightGreenAccent)),
              onPressed: () {
                Navigator.of(context).pop();
                _initializeInning(2);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _endMatch(String result) async {
    setState(() {
      _matchResult = result;
    });

    // 1. Update MatchModel
    await _matchService.updateMatchResult(widget.match.id, 'completed', result);

    // 2. Update TeamModel stats
    final bool isTied = result.contains("Tied!");
    final String winningTeamName = result.contains("won by") ? result.split("won by")[0].trim() : '';

    // Update widget.teamA
    await _teamService.updateTeamStats(
        widget.teamA.id,
        winningTeamName == widget.teamA.name, // teamA won if its name is in the result string as winner
        isTied
    );
    // Update widget.teamB
    await _teamService.updateTeamStats(
        widget.teamB.id,
        winningTeamName == widget.teamB.name, // teamB won if its name is in the result string as winner
        isTied
    );


    // 3. Update PlayerModel career stats for all players involved in the match
    Set<String> processedPlayerIds = {};

    // Process batting team players
    for (var player in _battingPlayersMap.values) {
      await _playerService.updatePlayerStats(player);
      processedPlayerIds.add(player.id);
    }
    // Process bowling team players
    for (var player in _bowlingPlayersMap.values) {
      await _playerService.updatePlayerStats(player);
      processedPlayerIds.add(player.id);
    }

    // Ensure all players from initial match setup have a career profile, even if they didn't bat/bowl
    // This ensures every player who was part of the original teams has a profile created/updated.
    // The `updatePlayerStats` method handles cases where playerInMatch has zero stats,
    // ensuring `matches` and `innings` are not incremented if they didn't participate in this match.
    for (var player in widget.teamA.players) {
      if (!processedPlayerIds.contains(player.id)) {
        await _playerService.updatePlayerStats(PlayerModel(
          id: player.id,
          name: player.name,
          batting: BattingStats(), // Zero stats for this match
          bowling: BowlingStats(),
          fielding: FieldingStats(),
        ));
      }
    }
    for (var player in widget.teamB.players) {
      if (!processedPlayerIds.contains(player.id)) {
        await _playerService.updatePlayerStats(PlayerModel(
          id: player.id,
          name: player.name,
          batting: BattingStats(), // Zero stats for this match
          bowling: BowlingStats(),
          fielding: FieldingStats(),
        ));
      }
    }


    // 4. Save Scorecard Details
    // Convert _completedInningsSummaries to List<Map<String, dynamic>>
    List<Map<String, dynamic>> inningsSummariesAsMap = _completedInningsSummaries.map((s) => s.toMap()).toList();
    await _scorecardService.saveMatchScorecard(
        widget.match.id, inningsSummariesAsMap, result);

    // After all data is saved, show the dialog and then the "Go to Home" button
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Match Over!", style: GoogleFonts.balooBhai2(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            _matchResult,
            style: GoogleFonts.balooBhai2(color: Colors.white70, fontSize: 18),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("View Scorecard", style: GoogleFonts.balooBhai2(color: Colors.lightGreenAccent)),
              onPressed: () {
                Navigator.of(context).pop();
                _showTvStyleScorecardDialog();
              },
            ),
            // Removed "Close" button, will rely on "Go to Home" button on main screen
          ],
        );
      },
    ).then((_) {
      // After the dialog is dismissed (either by "View Scorecard" or by back button),
      // set the flag to show the "Go to Home" button on the main screen.
      setState(() {
        _showGoToHomeButton = true;
      });
    });
  }

  void _showPartnershipDetailsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Current Partnership",
                style: GoogleFonts.balooBhai2(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.white30),
              Text(
                "Runs by ${_striker.name}: ${_striker.batting.runs} runs (${_striker.batting.balls} balls)",
                style: GoogleFonts.balooBhai2(color: Colors.white70, fontSize: 16),
              ),
              Text(
                "Runs by ${_nonStriker.name}: ${_nonStriker.batting.runs} runs (${_nonStriker.batting.balls} balls)",
                style: GoogleFonts.balooBhai2(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                "Combined Runs: ${_striker.batting.runs + _nonStriker.batting.runs}",
                style: GoogleFonts.balooBhai2(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Total Balls Faced: ${_striker.batting.balls + _nonStriker.batting.balls}",
                style: GoogleFonts.balooBhai2(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20)
            ],
          ),
        );
      },
    );
  }

  void _showExtrasDetailsDialog() {
    int totalExtras = _currentInningWides + _currentInningNoBalls + _currentInningByes + _currentInningLegByes;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Extras (Current Inning)",
                style: GoogleFonts.balooBhai2(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.white30),
              _buildExtrasRow("Wides:", _currentInningWides),
              _buildExtrasRow("No Balls:", _currentInningNoBalls),
              _buildExtrasRow("Byes:", _currentInningByes),
              _buildExtrasRow("Leg Byes:", _currentInningLegByes),
              const Divider(color: Colors.white30),
              _buildExtrasRow("Total Extras:", totalExtras, isTotal: true),
            ],
          ),
        );
      },
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

  void _showScorecardOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Make background transparent to show gradient
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF0B6623)], // Reverse gradient for bottom sheet
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border.all(color: Colors.white24),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Scorecard Options",
                style: GoogleFonts.balooBhai2(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.white30),
              ListTile(
                leading: const Icon(Icons.list_alt, color: Colors.white70),
                title: Text(
                  "Every Over Detail",
                  style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 18),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEveryOverDetailsDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.tv, color: Colors.white70),
                title: Text(
                  "Scorecard ",
                  style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 18),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showTvStyleScorecardDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEveryOverDetailsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full screen scroll
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8, // Take 80% of screen height
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
                  "Every Over Detail",
                  style: GoogleFonts.balooBhai2(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white30),
              Expanded(
                child: ListView.builder(
                  // Show all completed innings' overs + current over if it has balls
                  itemCount: _completedInningsSummaries.length + (_currentOverBalls.isNotEmpty || _currentInningsOvers.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    _InningSummary? inningSummary;
                    List<Over> oversToDisplay;
                    String inningLabel;

                    if (index < _completedInningsSummaries.length) {
                      inningSummary = _completedInningsSummaries[index];
                      oversToDisplay = inningSummary.oversDetails;
                      inningLabel = "${inningSummary.battingTeamName} - Inning ${index + 1}";
                    } else { // Current inning
                      oversToDisplay = List.from(_currentInningsOvers); // All completed overs in current inning
                      if (_currentOverBalls.isNotEmpty) {
                        oversToDisplay.add( // Add the current, in-progress over
                          Over(
                            overNumber: _currentOverCount + 1,
                            bowlerName: _bowler.name,
                            balls: _currentOverBalls,
                            runsConceded: _currentOverBalls.fold(0, (sum, ball) => sum + ball.runs + (ball.isWide || ball.isNoBall ? 1 : 0)),
                            wicketsTaken: _currentOverBalls.where((ball) => ball.isWicket).length,
                          ),
                        );
                      }
                      inningLabel = "${_currentBattingTeam.name} - Inning $_currentInning (Current)";
                    }

                    if (oversToDisplay.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                          child: Text(
                            inningLabel,
                            style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...oversToDisplay.map((over) => Card(
                          color: Colors.black.withOpacity(0.3),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Over ${over.overNumber} by ${over.bowlerName}",
                                  style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Runs: ${over.runsConceded}, Wickets: ${over.wicketsTaken}",
                                  style: GoogleFonts.balooBhai2(color: Colors.white70, fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: over.balls.map((ball) {
                                    Color bgColor;
                                    if (ball.isWicket) {
                                      bgColor = Colors.red[700]!;
                                    } else if (ball.isWide || ball.isNoBall || ball.isBye || ball.isLegBye) {
                                      bgColor = Colors.orange[700]!;
                                    } else if (ball.runs == 0) {
                                      bgColor = Colors.grey[600]!;
                                    } else {
                                      bgColor = Colors.green[700]!;
                                    }
                                    return Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        ball.detailedDisplayChar, // Use detailedDisplayChar here for Every Over Detail
                                        style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTvStyleScorecardDialog() {
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
                      ..._completedInningsSummaries.asMap().entries.map((entry) {
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
                                    battingPlayersInSummary.where((ps) => ps.battingStats!.runs > 0 || ps.battingStats!.balls > 0 || summary.fallOfWickets.any((fw) => fw['batsmanName'] == ps.name)).toList(), // Corrected check for dismissed batsmen
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
                              summary.fallOfWickets, // Use the new fallOfWickets list
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

                      // Display Current Inning (if match is ongoing)
                      if (_matchResult == "Ongoing")
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                              child: Text(
                                "${_currentBattingTeam.name} - Inning $_currentInning (Current)",
                                style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            _buildScorecardCard(
                              title: "Batting",
                              child: Column(
                                children: [
                                  _buildBatsmenScorecard(
                                    _battingPlayersMap.values.where((p) => p.batting.runs > 0 || p.batting.balls > 0 || _dismissedBatsmenNames.contains(p.name)).toList(),
                                  ),
                                  _buildExtrasRow("Wides:", _currentInningWides),
                                  _buildExtrasRow("No Balls:", _currentInningNoBalls),
                                  _buildExtrasRow("Byes:", _currentInningByes),
                                  _buildExtrasRow("Leg Byes:", _currentInningLegByes),
                                  _buildExtrasRow("Total Extras:", _currentInningWides + _currentInningNoBalls + _currentInningByes + _currentInningLegByes, isTotal: true),
                                ],
                              ),
                            ),
                            _buildScorecardCard(
                              title: "Bowling",
                              child: _buildBowlersScorecard(
                                _bowlingPlayersMap.values.where((p) => p.bowling.ballsBowled > 0).toList(),
                              ),
                            ),
                            _buildScorecardSectionHeader("Fall of Wickets"),
                            _buildFallOfWickets(
                              _fallOfWicketsDetails, // Use the new fallOfWickets list
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                "Current Score: ${_totalRuns} - ${_totalWickets} (${_formatOversDisplay(_totalOvers)})",
                                style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      if (_matchResult != "Ongoing")
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(
                            "Match Result: $_matchResult",
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

  Widget _buildScorecardCard({required String title, required Widget child}) {
    return Card(
      color: Colors.black.withOpacity(0.3), // Darker transparent background for main cards
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
            bool isOnStrike = false;

            if (isFullScorecard) {
              final _ScorecardPlayerStats ps = data as _ScorecardPlayerStats;
              name = ps.name;
              batting = ps.battingStats!;
            } else {
              final PlayerModel player = data as PlayerModel;
              name = player.name;
              batting = player.batting;
              isOnStrike = player.name == _striker.name || player.name == _nonStriker.name;
            }

            return _RowPlayer(
              name: name,
              runs: batting.runs,
              balls: batting.balls,
              fours: batting.fours,
              sixes: batting.sixes,
              sr: batting.strikeRateValue,
              isOnStrike: isOnStrike,
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

            if (isFullScorecard) {
              final _ScorecardPlayerStats ps = data as _ScorecardPlayerStats;
              name = ps.name;
              bowling = ps.bowlingStats!;
            } else {
              final PlayerModel player = data as PlayerModel;
              name = player.name;
              bowling = player.bowling;
            }

            return _RowPlayer(
              name: name,
              overs: bowling.displayOvers, // Use displayOvers
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
          // Use wicketData['wicketNumber'] which is already 1-based index when stored
          // Or entry.key + 1 if you want to rely on the list index
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


  @override
  Widget build(BuildContext context) {
    // Determine the team names for display based on current batting team
    final String battingTeamDisplayName = _currentBattingTeam.name;
    final String bowlingTeamDisplayName = _currentBowlingTeam.name;

    return Scaffold(
      extendBodyBehindAppBar: true,
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                _header(battingTeamDisplayName, bowlingTeamDisplayName),
                const SizedBox(height: 10),
                _scoreDisplay(battingTeamDisplayName, bowlingTeamDisplayName),
                // Display current over's ball details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Current Over Balls:", style: GoogleFonts.balooBhai2(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 5),
                        _buildCurrentOverBallsDisplay(),
                      ],
                    ),
                  ),
                ),
                _batsmenTable(_striker, _nonStriker),
                _bowlerTable(_bowler),
                _deliveryTypeRow(),
                _actionButtons(),
                _runButtons(),
                if (_matchResult != "Ongoing") // Display result if match is over
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _matchResult,
                      style: GoogleFonts.balooBhai2(
                        fontSize: 24,
                        color: Colors.yellowAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // New: Go to Home button appears after match is finished
                if (_showGoToHomeButton) _buildGoToHomeButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoToHomeButton() {
    return Padding(
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
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(
            "Go to Home",
            style: GoogleFonts.balooBhai2(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildCurrentOverBallsDisplay() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _currentOverBalls.map((ball) {
        Color bgColor;
        if (ball.isWicket) {
          bgColor = Colors.red[700]!;
        } else if (ball.isWide || ball.isNoBall || ball.isBye || ball.isLegBye) {
          bgColor = Colors.orange[700]!;
        } else if (ball.runs == 0) {
          bgColor = Colors.grey[600]!;
        } else {
          bgColor = Colors.green[700]!;
        }

        return Container(
          width: 50, // Adjusted width to accommodate detailed text
          height: 35,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8), // Changed to rounded rectangle
            border: Border.all(color: Colors.white54),
          ),
          alignment: Alignment.center,
          child: Text(
            ball.detailedDisplayChar, // Use detailedDisplayChar
            style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  BoxDecoration _cardDecoration({Color? customColor}) {
    return BoxDecoration(
      color: customColor ?? Colors.black.withOpacity(0.4),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white24),
      boxShadow: [
        BoxShadow(
          color: Colors.black45.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(2, 4),
        ),
      ],
    );
  }

  Widget _header(String teamA, String teamB) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Text("HOWZAT",
              style: GoogleFonts.balooBhai2(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              )),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.score, color: Colors.white70),
            onPressed: _showScorecardOptions,
          ),
          // Removed Icons.sync and Icons.event as requested
        ],
      ),
    );
  }

  Widget _scoreDisplay(String battingTeam, String bowlingTeam) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _teamCard(battingTeam.substring(0, 2)),
              const Spacer(),
              Text("VS", style: GoogleFonts.balooBhai2(color: Colors.white70, fontSize: 18)),
              const Spacer(),
              _teamCard(bowlingTeam.substring(0, 2)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
              "$battingTeam - ${_currentInning == 1 ? "1st" : "2nd"} Inning",
              style: GoogleFonts.balooBhai2(
                color: Colors.white70,
                fontSize: 16,
              )),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$_totalRuns - $_totalWickets (${_formatOversDisplay(_totalOvers)})", // Use _formatOversDisplay
                style: GoogleFonts.balooBhai2(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_currentInning == 2)
                Text(
                  "Target: $_targetRuns",
                  style: GoogleFonts.balooBhai2(
                    color: Colors.yellowAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          Row(
            children: [
              const Spacer(),
              Text("CRR:", style: GoogleFonts.balooBhai2(color: Colors.white54)),
              const SizedBox(width: 6),
              Text(
                // CRR based on actual balls faced (total overs * 6)
                (_totalRuns / (_currentOverCount * 6 + _currentBallInOver == 0 ? 1 : (_currentOverCount * 6 + _currentBallInOver)) * 6)
                    .toStringAsFixed(2),
                style: GoogleFonts.balooBhai2(color: Colors.white),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _teamCard(String initials) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF64DD17)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black45.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.balooBhai2(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _batsmenTable(PlayerModel striker, PlayerModel nonStriker) {
    return _dataBox(
      children: [
        _RowHeader(
            headers: const ['Batsman', 'R', 'B', '4s', '6s', 'SR'],
            textStyle: GoogleFonts.balooBhai2(color: Colors.white60, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white24),
        _RowPlayer(
          name: striker.name,
          runs: striker.batting.runs,
          balls: striker.batting.balls,
          fours: striker.batting.fours,
          sixes: striker.batting.sixes,
          sr: striker.batting.strikeRateValue,
          isOnStrike: true,
          textStyle: GoogleFonts.balooBhai2(color: Colors.white),
        ),
        _RowPlayer(
          name: nonStriker.name,
          runs: nonStriker.batting.runs,
          balls: nonStriker.batting.balls,
          fours: nonStriker.batting.fours,
          sixes: nonStriker.batting.sixes,
          sr: nonStriker.batting.strikeRateValue,
          textStyle: GoogleFonts.balooBhai2(color: Colors.white),
        ),
      ],
    );
  }

  Widget _bowlerTable(PlayerModel bowler) {
    return _dataBox(
      children: [
        _RowHeader(
            headers: const ['Bowler', 'O', 'M', 'R', 'W', 'ER'],
            textStyle: GoogleFonts.balooBhai2(color: Colors.white60, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white24),
        _RowPlayer(
          name: bowler.name,
          overs: bowler.bowling.displayOvers, // Use displayOvers
          maidens: bowler.bowling.maidens,
          runsGiven: bowler.bowling.runs,
          wickets: bowler.bowling.wickets,
          er: bowler.bowling.economyRateValue,
          textStyle: GoogleFonts.balooBhai2(color: Colors.white),
        ),
      ],
    );
  }

  Widget _dataBox({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: _cardDecoration(),
      child: Column(children: children),
    );
  }

  Widget _deliveryTypeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          _optionBox("Wide",
              icon: Icons.sports_cricket,
              isSelected: _selectedDeliveryType == 'wide',
              onTap: () => setState(() => _selectedDeliveryType = 'wide')),
          _optionBox("No Ball",
              icon: Icons.sports_cricket,
              isSelected: _selectedDeliveryType == 'noBall',
              onTap: () => setState(() => _selectedDeliveryType = 'noBall')),
          _optionBox("Wicket",
              isWicket: true,
              icon: Icons.person_off,
              isSelected: _selectedDeliveryType == 'wicket',
              onTap: () => setState(() => _selectedDeliveryType = 'wicket')),
          _optionBox("Byes",
              icon: Icons.run_circle_outlined,
              isSelected: _selectedDeliveryType == 'bye',
              onTap: () => setState(() => _selectedDeliveryType = 'bye')),
          _optionBox("Leg Byes",
              icon: Icons.run_circle_outlined,
              isSelected: _selectedDeliveryType == 'legBye',
              onTap: () => setState(() => _selectedDeliveryType = 'legBye')),
          // Removed Undo button as requested
        ],
      ),
    );
  }

  Widget _runButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          _runCircle("0", onTap: () => _handleDelivery(0)),
          for (int i = 1; i <= 6; i++)
            _runCircle(i.toString(), onTap: () => _handleDelivery(i)),
          // Removed "Finish" button as requested.
        ],
      ),
    );
  }

  Widget _runCircle(String label, {bool isRetire = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isRetire
              ? null
              : const LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF64DD17)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          color: isRetire ? Colors.deepOrange : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black45.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: GoogleFonts.balooBhai2(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }

  Widget _actionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _bottomAction("Partnership", icon: Icons.people_alt, onTap: _showPartnershipDetailsDialog),
          _bottomAction("Extras", icon: Icons.add_box_outlined, onTap: _showExtrasDetailsDialog),
        ],
      ),
    );
  }

  Widget _bottomAction(String label, {IconData? icon, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF00C853), Color(0xFF64DD17)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black45.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, color: Colors.white, size: 20),
              if (icon != null) const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.balooBhai2(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionBox(String label, {bool isWicket = false, IconData? icon, VoidCallback? onTap, bool isSelected = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.lightGreen.withOpacity(0.6) // Highlight selected
              : isWicket ? Colors.red[700] : Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected
                  ? Colors.white // Stronger border for selected
                  : isWicket ? Colors.redAccent : Colors.white24),
          boxShadow: [
            BoxShadow(
              color: Colors.black45.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, color: Colors.white, size: 18),
            if (icon != null) const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

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
  final double? sr; // Renamed from overs to sr
  final double? overs; // Only used for bowlers
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
    this.overs, // For bowler
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
            // This case should ideally not be reached if usage is correct.
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
