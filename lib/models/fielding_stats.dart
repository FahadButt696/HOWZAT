class FieldingStats {
  int catches, runOuts, stumpings;

  FieldingStats({
    this.catches = 0,
    this.runOuts = 0,
    this.stumpings = 0,
  });

  factory FieldingStats.fromMap(Map<String, dynamic> map) => FieldingStats(
    catches: map['catches'],
    runOuts: map['runOuts'],
    stumpings: map['stumpings'],
  );

  Map<String, dynamic> toMap() => {
    'catches': catches,
    'runOuts': runOuts,
    'stumpings': stumpings,
  };
}
