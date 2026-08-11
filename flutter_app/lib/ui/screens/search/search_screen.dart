import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/prediction_provider.dart';
import '../../widgets/prediction_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _teamController = TextEditingController();
  final _championshipController = TextEditingController();
  final _dateController = TextEditingController();
  String _status = '';

  @override
  void dispose() {
    _teamController.dispose();
    _championshipController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _applySearch() {
    ref.read(searchFilterProvider.notifier).state = SearchFilterState(
      team: _teamController.text.trim(),
      championship: _championshipController.text.trim(),
      matchDate: _dateController.text.trim(),
      status: _status,
    );
    ref.refresh(predictionsProvider);
    context.pop();
  }

  void _resetSearch() {
    _teamController.clear();
    _championshipController.clear();
    _dateController.clear();
    setState(() => _status = '');
    ref.read(searchFilterProvider.notifier).state = SearchFilterState();
    ref.refresh(predictionsProvider);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RECHERCHER ET FILTRER'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _teamController,
              label: 'Équipe (Domicile ou Extérieure)',
              hint: 'Ex: Real Madrid, PSG, Liverpool...',
              prefixIcon: const Icon(Icons.sports_soccer, color: AppTheme.gold),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _championshipController,
              label: 'Championnat / Compétition',
              hint: 'Ex: Ligue 1, Premier League, La Liga...',
              prefixIcon: const Icon(Icons.emoji_events, color: AppTheme.gold),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _dateController,
              label: 'Date du match (YYYY-MM-DD)',
              hint: '2026-08-03',
              prefixIcon: const Icon(Icons.calendar_today, color: AppTheme.gold),
            ),
            const SizedBox(height: 20),

            const Text(
              'Statut du Pronostic',
              style: TextStyle(inherit: true, color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip('Tous', ''),
                _buildStatusChip('En cours', 'PENDING'),
                _buildStatusChip('Gagné', 'WON'),
                _buildStatusChip('Perdu', 'LOST'),
              ],
            ),
            const SizedBox(height: 36),

            CustomButton(
              text: 'APPLIQUER LES FILTRES',
              icon: Icons.search,
              onPressed: _applySearch,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'RÉINITIALISER',
              backgroundColor: AppTheme.darkCard,
              textColor: Colors.white,
              onPressed: _resetSearch,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String code) {
    final isSelected = _status == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppTheme.gold,
        backgroundColor: AppTheme.darkCard,
        labelStyle: TextStyle(inherit: true, 
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (val) {
          setState(() => _status = code);
        },
      ),
    );
  }
}
