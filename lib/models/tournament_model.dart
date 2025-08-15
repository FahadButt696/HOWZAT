class TournamentModel {
  final String id;
  final String name;
  final String location;
  final DateTime startDate;
  final List<String> matchIds;

  TournamentModel({
    required this.id,
    required this.name,
    required this.location,
    required this.startDate,
    required this.matchIds,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'startDate': startDate.toIso8601String(),
    'matchIds': matchIds,
  };

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    return TournamentModel(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      startDate: DateTime.parse(json['startDate']),
      matchIds: List<String>.from(json['matchIds']),
    );
  }
}
