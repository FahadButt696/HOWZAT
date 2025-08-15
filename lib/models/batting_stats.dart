class BattingStats {
  int matches, innings, runs, notOuts, bestScore, fours, sixes, fifties, hundreds, ducks;
  int balls; // Added 'balls' field

  BattingStats({
    this.matches = 0,
    this.innings = 0,
    this.runs = 0,
    this.notOuts = 0,
    this.bestScore = 0,
    this.balls = 0, // Initialize balls to 0
    this.fours = 0,
    this.sixes = 0,
    this.fifties = 0,
    this.hundreds = 0,
    this.ducks = 0,
  });

  // Getter for Strike Rate
  double get strikeRateValue => balls == 0 ? 0.0 : (runs / balls) * 100;

  // Getter for Average (simplified: assuming average is runs / (innings - notOuts))
  double get averageValue {
    final int outs = innings - notOuts;
    return outs == 0 ? 0.0 : runs / outs;
  }

  factory BattingStats.fromMap(Map<String, dynamic> map) => BattingStats(
    matches: map['matches'] ?? 0,
    innings: map['innings'] ?? 0,
    runs: map['runs'] ?? 0,
    notOuts: map['notOuts'] ?? 0,
    bestScore: map['bestScore'] ?? 0,
    balls: map['balls'] ?? 0, // Retrieve balls from map
    fours: map['fours'] ?? 0,
    sixes: map['sixes'] ?? 0,
    fifties: map['fifties'] ?? 0,
    hundreds: map['hundreds'] ?? 0,
    ducks: map['ducks'] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'matches': matches,
    'innings': innings,
    'runs': runs,
    'notOuts': notOuts,
    'bestScore': bestScore,
    'balls': balls, // Save balls to map
    'fours': fours,
    'sixes': sixes,
    'fifties': fifties,
    'hundreds': hundreds,
    'ducks': ducks,
    // strikeRate and average are calculated, so no need to save them directly
    // unless you want to cache their values for performance
  };
}
