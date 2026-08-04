import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prediction_model.dart';
import 'auth_provider.dart';

// Catégorie actuellement sélectionnée (ALL, MONTANTE, COTE_5, COTE_10, COTE_50)
final selectedCategoryProvider = StateProvider<String>((ref) => 'ALL');

// Filtres de recherche
class SearchFilterState {
  final String championship;
  final String team;
  final String matchDate;
  final String status;

  SearchFilterState({
    this.championship = '',
    this.team = '',
    this.matchDate = '',
    this.status = '',
  });

  SearchFilterState copyWith({
    String? championship,
    String? team,
    String? matchDate,
    String? status,
  }) {
    return SearchFilterState(
      championship: championship ?? this.championship,
      team: team ?? this.team,
      matchDate: matchDate ?? this.matchDate,
      status: status ?? this.status,
    );
  }

  bool get isEmpty =>
      championship.isEmpty && team.isEmpty && matchDate.isEmpty && status.isEmpty;
}

final searchFilterProvider = StateProvider<SearchFilterState>((ref) {
  return SearchFilterState();
});

// Liste des pronostics selon la catégorie et les filtres
final predictionsProvider = FutureProvider<List<PredictionModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final category = ref.watch(selectedCategoryProvider);
  final filters = ref.watch(searchFilterProvider);

  try {
    return await api.getPredictions(
      type: category == 'ALL' ? null : category,
      championship: filters.championship.isEmpty ? null : filters.championship,
      team: filters.team.isEmpty ? null : filters.team,
      matchDate: filters.matchDate.isEmpty ? null : filters.matchDate,
      status: filters.status.isEmpty ? null : filters.status,
    );
  } catch (e) {
    return [];
  }
});

// Historique des pronostics terminés (WON, LOST, VOID)
final historyPredictionsProvider = FutureProvider<List<PredictionModel>>((ref) async {
  final api = ref.read(apiServiceProvider);
  try {
    return await api.getHistoryPredictions();
  } catch (e) {
    return [];
  }
});
