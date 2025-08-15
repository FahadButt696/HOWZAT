class BowlingStats {
  int matches, wickets, maidens, dotBalls, runs, wides, noBalls, fourWickets, fiveWickets;
  int ballsBowled; // New: Total legal balls bowled (0-5 per over)
  int innings; // Added: Number of innings the bowler has bowled in

  BowlingStats({
    this.matches = 0,
    this.wickets = 0,
    this.maidens = 0,
    this.dotBalls = 0,
    this.runs = 0, // Total runs conceded by bowler (including extras from their bowling)
    this.wides = 0,
    this.noBalls = 0,
    this.fourWickets = 0,
    this.fiveWickets = 0,
    this.ballsBowled = 0, // Initialize new field
    this.innings = 0, // Initialize new field
  });

  // Getter for Economy Rate
  double get economyRateValue {
    if (ballsBowled == 0) return 0.0;
    // Economy rate is runs conceded per over (6 balls)
    return (runs / ballsBowled) * 6;
  }

  // Getter for Average (simplified: assuming average is runs / wickets)
  double get averageValue => wickets == 0 ? 0.0 : runs / wickets;

  // Getter for displaying overs in X.Y format (e.g., 1.3 for 1 over and 3 balls)
  double get displayOvers {
    int wholeOvers = ballsBowled ~/ 6; // Integer division for full overs
    int balls = ballsBowled % 6; // Remainder for balls in current over
    // Combine as a double for display (e.g., 1.3 for 1 over and 3 balls)
    return double.parse("$wholeOvers.$balls");
  }


  factory BowlingStats.fromMap(Map<String, dynamic> map) => BowlingStats(
    matches: map['matches'] ?? 0,
    wickets: map['wickets'] ?? 0,
    maidens: map['maidens'] ?? 0,
    dotBalls: map['dotBalls'] ?? 0,
    runs: map['runs'] ?? 0,
    wides: map['wides'] ?? 0,
    noBalls: map['noBalls'] ?? 0,
    fourWickets: map['fourWickets'] ?? 0,
    fiveWickets: map['fiveWickets'] ?? 0,
    ballsBowled: map['ballsBowled'] ?? 0, // Retrieve ballsBowled
    innings: map['innings'] ?? 0, // Retrieve innings
  );

  Map<String, dynamic> toMap() => {
    'matches': matches,
    'wickets': wickets,
    'maidens': maidens,
    'dotBalls': dotBalls,
    'runs': runs,
    'wides': wides,
    'noBalls': noBalls,
    'fourWickets': fourWickets,
    'fiveWickets': fiveWickets,
    'ballsBowled': ballsBowled, // Save ballsBowled
    'innings': innings, // Save innings
    // economyRate and average are calculated, so no need to save them directly
    // unless you want to cache their values for performance
  };
}
