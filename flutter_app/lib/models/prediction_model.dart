class PredictionSelection {
  final int index;
  final String match;
  final String championship;
  final String matchTime;
  final String tip;
  final double? odds;
  final String status;

  PredictionSelection({
    required this.index,
    required this.match,
    required this.championship,
    required this.matchTime,
    required this.tip,
    this.odds,
    required this.status,
  });

  factory PredictionSelection.fromJson(Map<String, dynamic> json) {
    return PredictionSelection(
      index: json['index'] ?? 1,
      match: json['match'] ?? '',
      championship: json['championship'] ?? '',
      matchTime: json['match_time'] ?? '',
      tip: json['tip'] ?? 'Victoire à Domicile',
      odds: (json['odds'] as num?)?.toDouble(),
      status: json['status'] ?? 'PENDING',
    );
  }
}

class PredictionModel {
  final int id;
  final String title;
  final String competition;
  final String country;
  final String championship;
  final String matchDate;
  final String matchTime;
  final String homeTeam;
  final String awayTeam;
  final String type; // MONTANTE, COTE_5, COTE_10, COTE_50
  final double odds;
  final int confidence; // 1 à 5
  final String status; // PENDING, WON, LOST, VOID
  final String imageUrl;
  final bool isLocked;
  final List<PredictionSelection> selections;
  final int matchesCount;
  final String analysis;

  PredictionModel({
    required this.id,
    required this.title,
    required this.competition,
    required this.country,
    required this.championship,
    required this.matchDate,
    required this.matchTime,
    required this.homeTeam,
    required this.awayTeam,
    required this.type,
    required this.odds,
    required this.confidence,
    required this.status,
    required this.imageUrl,
    required this.isLocked,
    required this.selections,
    required this.matchesCount,
    required this.analysis,
  });

  bool get isCombiné => selections.length > 1;

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    final rawSelections = json['selections'] as List<dynamic>? ?? [];
    final parsedSelections =
        rawSelections.map((e) => PredictionSelection.fromJson(e)).toList();

    return PredictionModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      competition: json['competition'] ?? '',
      country: json['country'] ?? '',
      championship: json['championship'] ?? '',
      matchDate: json['match_date'] ?? '',
      matchTime: json['match_time'] ?? '',
      homeTeam: json['home_team'] ?? '',
      awayTeam: json['away_team'] ?? '',
      type: json['type'] ?? 'COTE_5',
      odds: (json['odds'] as num?)?.toDouble() ?? 1.0,
      confidence: json['confidence'] ?? 4,
      status: json['status'] ?? 'PENDING',
      imageUrl: json['image_url'] ?? '',
      isLocked: json['is_locked'] ?? false,
      selections: parsedSelections,
      matchesCount: json['matches_count'] ?? parsedSelections.length,
      analysis: json['analysis'] ?? '',
    );
  }
}
