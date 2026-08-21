import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/analysis_history_entity.dart';
import '../cubit/wardrobe_cubit.dart';
import '../cubit/wardrobe_state.dart';

class AnalysisHistoryScreen extends StatelessWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D0061), Color(0xFF5B21B6), Color(0xFF7C3AED)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F0FF),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: BlocBuilder<WardrobeCubit, WardrobeState>(
                    buildWhen: (p, c) => p.history != c.history,
                    builder: (context, state) {
                      if (state.history.isEmpty) {
                        return _buildEmpty();
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        itemCount: state.history.length,
                        itemBuilder: (ctx, i) =>
                            _HistoryCard(entry: state.history[i]),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Historique IA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Toutes vos analyses de vêtements',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.history_rounded,
                size: 40, color: Color(0xFF6D28D9)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune analyse pour le moment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analysez un vêtement avec l\'IA\npour voir l\'historique ici.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Carte d'entrée historique ─────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final AnalysisHistoryEntity entry;

  const _HistoryCard({required this.entry});

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Robes':        return const Color(0xFFEC4899);
      case 'Pantalons':    return const Color(0xFF3B82F6);
      case 'Chemises':     return const Color(0xFF0D9488);
      case 'Vestes':       return const Color(0xFF8B5CF6);
      case 'T-shirts':     return const Color(0xFFF97316);
      case 'Pulls':        return const Color(0xFF6366F1);
      case 'Jupes':        return const Color(0xFFF43F5E);
      case 'Chaussures':   return const Color(0xFF64748B);
      case 'Accessoires':  return const Color(0xFFD97706);
      default:             return const Color(0xFF6D28D9);
    }
  }

  Color _confidenceColor(double c) {
    if (c >= 0.80) return Colors.green.shade600;
    if (c >= 0.60) return Colors.orange.shade600;
    return Colors.red.shade400;
  }

  String _confidenceLabel(double c) {
    if (c == 0) return 'OpenCV';
    return '${(c * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(entry.categorie);
    final confColor = _confidenceColor(entry.confidence);
    final d = entry.analyzedAt.toLocal();
    const months = ['', 'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
        'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
    final dateStr =
        '${d.day.toString().padLeft(2, '0')} ${months[d.month]} ${d.year} · '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: catColor.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Bande colorée supérieure ────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                  bottom: BorderSide(
                      color: catColor.withValues(alpha: 0.12))),
            ),
            child: Row(
              children: [
                // Cercle couleur vêtement
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: catColor.withValues(alpha: 0.25)),
                  ),
                  child: Icon(_categoryIcon(entry.categorie),
                      size: 22, color: catColor),
                ),
                const SizedBox(width: 12),

                // Catégorie + couleur
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: catColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              entry.categorie,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (entry.couleur.isNotEmpty)
                            Text(
                              entry.couleur,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),

                // Statut sauvegardé
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: entry.savedToWardrobe
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: entry.savedToWardrobe
                              ? Colors.green.shade200
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            entry.savedToWardrobe
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 12,
                            color: entry.savedToWardrobe
                                ? Colors.green.shade600
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.savedToWardrobe ? 'Sauvegardé' : 'Non sauvegardé',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: entry.savedToWardrobe
                                  ? Colors.green.shade600
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Confiance
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: confColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _confidenceLabel(entry.confidence),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: confColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Description ─────────────────────────────────────────────────
          if (entry.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Text(
                entry.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Chaussures':  return Icons.directions_walk_rounded;
      case 'Accessoires': return Icons.watch_rounded;
      default:            return Icons.checkroom_rounded;
    }
  }
}
