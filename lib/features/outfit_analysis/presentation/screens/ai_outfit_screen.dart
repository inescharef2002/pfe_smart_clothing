import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../cubit/outfit_analysis_cubit.dart';
import '../cubit/outfit_analysis_state.dart';
import '../../../wardrobe/presentation/cubit/wardrobe_cubit.dart';
import '../../../wardrobe/presentation/cubit/wardrobe_state.dart';
import '../../domain/entities/outfit_suggestion_entity.dart';

class _K {
  static const primary = Color(0xFF6D28D9);
  static const primaryLight = Color(0xFF7C3AED);
  static const primarySurface = Color(0xFFF5F0FF);
  static const border = Color(0xFFE9D5FF);
  static const textMain = Color(0xFF1A1A2E);
  static const textMuted = Color(0xFF9CA3AF);
}

class AiOutfitScreen extends StatefulWidget {
  const AiOutfitScreen({super.key});

  @override
  State<AiOutfitScreen> createState() => _AiOutfitScreenState();
}

class _AiOutfitScreenState extends State<AiOutfitScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedOccasion = 'Quotidienne';
  String? _persistedError;

  final List<String> _occasions = [
    'Quotidienne', 'Travail', 'Soirée',
    'Sport', 'Rendez-vous', 'Weekend', 'Mariage',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWeatherWithGPS();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWeatherWithGPS() async {
    double? lat;
    double? lon;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 8),
          ),
        );
        lat = pos.latitude;
        lon = pos.longitude;
      }
    } catch (_) {}
    if (mounted) {
      context.read<OutfitAnalysisCubit>().loadWeather(lat: lat, lon: lon);
    }
  }

  List<Map<String, dynamic>> _toMapList(WardrobeState ws) {
    return ws.items.map((i) => {
      'id': i.id,
      'nom': i.nom,
      'categorie': i.categorie,
      'couleur': i.couleur,
      'couleur_hex': '',
      'taille': i.taille,
      'marque': i.marque,
      'imageUrl': i.imageUrl,
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OutfitAnalysisCubit, OutfitAnalysisState>(
      listenWhen: (prev, curr) =>
          curr.errorMessage != null &&
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          setState(() => _persistedError = state.errorMessage);
          context.read<OutfitAnalysisCubit>().clearMessages();
        }
      },
      builder: (context, state) {
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
                  _buildHeader(state),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Column(
                        children: [
                          _buildTabBar(state),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildWeatherTab(state),
                                _buildOccasionTab(state),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Header with weather card (home style) ─────────────────────────────────
  Widget _buildHeader(OutfitAnalysisState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 11),
                            SizedBox(width: 4),
                            Text('IA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Suggestions de tenues',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  Text('Tenues personnalisées par l\'IA',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildWeatherCardHeader(state),
        ],
      ),
    );
  }

  // ── Weather card — same glass style as home screen ────────────────────────
  Widget _buildWeatherCardHeader(OutfitAnalysisState state) {
    if (state.isLoadingWeather) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Chargement météo…',
                style: TextStyle(fontSize: 13, color: Colors.white)),
          ],
        ),
      );
    }

    if (state.weather == null) {
      return GestureDetector(
        onTap: _loadWeatherWithGPS,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Text('🌐', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Météo indisponible — Appuyez pour réessayer',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
              ),
              Icon(Icons.refresh, size: 16, color: Colors.white.withValues(alpha: 0.7)),
            ],
          ),
        ),
      );
    }

    final w = state.weather!;
    final emoji = _weatherEmoji(w.description);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('${w.temperature}°C',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(width: 8),
                  Text(w.city,
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
                ]),
                Text(_capitalize(w.description),
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.water_drop_outlined, size: 12, color: Colors.white.withValues(alpha: 0.9)),
                const SizedBox(width: 3),
                Text('${w.humidity}%',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _loadWeatherWithGPS,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.refresh, size: 14, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar(OutfitAnalysisState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) {
          setState(() => _persistedError = null);
          context.read<OutfitAnalysisCubit>().resetSuggestions();
        },
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade500,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [_K.primary, _K.primaryLight]),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.wb_sunny_outlined, size: 15), SizedBox(width: 6), Text('Selon météo'),
          ])),
          Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.event_outlined, size: 15), SizedBox(width: 6), Text('Par occasion'),
          ])),
        ],
      ),
    );
  }

  // ── Tab Météo ─────────────────────────────────────────────────────────────
  Widget _buildWeatherTab(OutfitAnalysisState state) {
    return BlocBuilder<WardrobeCubit, WardrobeState>(
      builder: (context, wardrobeState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: Column(
            children: [
              if (_persistedError != null) ...[
                _buildErrorBanner(_persistedError!, onRetry: () {
                  setState(() => _persistedError = null);
                  context.read<OutfitAnalysisCubit>()
                      .suggestWeatherOutfits(_toMapList(wardrobeState));
                }),
                const SizedBox(height: 14),
              ],
              if (wardrobeState.isLoading)
                _buildLoadingState('Chargement de votre garde-robe…')
              else if (wardrobeState.items.isEmpty)
                _buildEmptyWardrobeState()
              else if (state.isLoadingSuggestions)
                _buildLoadingState('Analyse de votre garde-robe et de la météo…')
              else if (state.suggestions.isEmpty)
                _buildGenerateButton(
                  label: 'Générer mes tenues du jour',
                  icon: Icons.wb_sunny_outlined,
                  wardrobeCount: wardrobeState.items.length,
                  weatherSummary: state.weather != null
                      ? '${state.weather!.temperature}°C · ${_capitalize(state.weather!.description)}'
                      : null,
                  onTap: state.weather != null && !state.isLoadingWeather
                      ? () {
                          setState(() => _persistedError = null);
                          context.read<OutfitAnalysisCubit>()
                              .suggestWeatherOutfits(_toMapList(wardrobeState));
                        }
                      : null,
                )
              else ...[
                if (state.conseilGeneral.isNotEmpty) ...[
                  _buildConseilGeneral(state.conseilGeneral),
                  const SizedBox(height: 14),
                ],
                ...state.suggestions.map(_buildSuggestionCard),
                const SizedBox(height: 12),
                _buildRegenerateButton(() {
                  setState(() => _persistedError = null);
                  context.read<OutfitAnalysisCubit>()
                      .suggestWeatherOutfits(_toMapList(wardrobeState));
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Tab Occasion ──────────────────────────────────────────────────────────
  Widget _buildOccasionTab(OutfitAnalysisState state) {
    return BlocBuilder<WardrobeCubit, WardrobeState>(
      builder: (context, wardrobeState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _K.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pour quelle occasion ?',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _K.textMain)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _occasions.map((o) {
                        final sel = _selectedOccasion == o;
                        return GestureDetector(
                          onTap: () {
                            setState(() { _selectedOccasion = o; _persistedError = null; });
                            context.read<OutfitAnalysisCubit>().resetSuggestions();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? _K.primary : _K.primarySurface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(o,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: sel ? Colors.white : _K.primaryLight)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_persistedError != null) ...[
                _buildErrorBanner(_persistedError!, onRetry: () {
                  setState(() => _persistedError = null);
                  context.read<OutfitAnalysisCubit>().suggestOccasionOutfits(
                      _toMapList(wardrobeState), _selectedOccasion);
                }),
                const SizedBox(height: 14),
              ],
              if (wardrobeState.isLoading)
                _buildLoadingState('Chargement de votre garde-robe…')
              else if (wardrobeState.items.isEmpty)
                _buildEmptyWardrobeState()
              else if (state.isLoadingSuggestions)
                _buildLoadingState('Sélection des meilleures tenues pour $_selectedOccasion…')
              else if (state.suggestions.isEmpty)
                _buildGenerateButton(
                  label: 'Générer des tenues pour "$_selectedOccasion"',
                  icon: Icons.style_outlined,
                  wardrobeCount: wardrobeState.items.length,
                  onTap: () {
                    setState(() => _persistedError = null);
                    context.read<OutfitAnalysisCubit>().suggestOccasionOutfits(
                        _toMapList(wardrobeState), _selectedOccasion);
                  },
                )
              else ...[
                ...state.suggestions.map(_buildSuggestionCard),
                const SizedBox(height: 12),
                _buildRegenerateButton(() {
                  setState(() => _persistedError = null);
                  context.read<OutfitAnalysisCubit>().suggestOccasionOutfits(
                      _toMapList(wardrobeState), _selectedOccasion);
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────
  Widget _buildGenerateButton({
    required String label,
    required IconData icon,
    required int wardrobeCount,
    String? weatherSummary,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: enabled ? _K.primary : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: enabled
                    ? const LinearGradient(colors: [_K.primary, _K.primaryLight])
                    : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300]),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: enabled ? _K.primary : Colors.grey.shade400)),
            const SizedBox(height: 6),
            if (weatherSummary != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wb_sunny_outlined, size: 11, color: Colors.blue.shade400),
                    const SizedBox(width: 4),
                    Text(weatherSummary,
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade600)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: enabled ? _K.primarySurface : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                enabled
                    ? '$wardrobeCount vêtement${wardrobeCount > 1 ? 's' : ''} disponible${wardrobeCount > 1 ? 's' : ''}'
                    : 'Météo non disponible',
                style: TextStyle(
                    fontSize: 11,
                    color: enabled ? _K.primaryLight : Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWardrobeState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _K.primarySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _K.border),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 60, height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(color: _K.border, shape: BoxShape.circle),
              child: Icon(Icons.checkroom_outlined, size: 28, color: _K.primary),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Garde-robe vide',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _K.textMain)),
          const SizedBox(height: 6),
          Text(
            'Ajoutez des vêtements à votre garde-robe\npour obtenir des suggestions personnalisées.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_K.primary, _K.primaryLight]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Aller à ma garde-robe',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message, {required VoidCallback onRetry}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: Colors.red.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Erreur lors de la génération',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red.shade700)),
                const SizedBox(height: 3),
                Text(message,
                    style: TextStyle(fontSize: 12, color: Colors.red.shade600, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text('Réessayer',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red.shade700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(OutfitSuggestionEntity s) {
    final scoreColor = s.score >= 0.8
        ? Colors.green.shade600
        : s.score >= 0.5
            ? Colors.orange.shade600
            : Colors.red.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _K.border),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _K.primary.withValues(alpha: 0.07),
                _K.primaryLight.withValues(alpha: 0.04),
              ]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: const Border(bottom: BorderSide(color: _K.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Text(s.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.nom,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _K.primary)),
                      Text(s.occasion,
                          style: const TextStyle(fontSize: 11, color: _K.textMuted)),
                    ],
                  ),
                ),
                if (s.score > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                    ),
                    child: Text('${(s.score * 100).round()}%',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: scoreColor)),
                  ),
              ],
            ),
          ),
          // Images
          if (s.images.any((url) => url.isNotEmpty))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: s.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final url = s.images[idx];
                    if (url.isEmpty) return const SizedBox.shrink();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(url, width: 70, height: 80, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 70, height: 80,
                            decoration: BoxDecoration(color: _K.primarySurface, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.checkroom_outlined, size: 28, color: _K.primary),
                          )),
                    );
                  },
                ),
              ),
            ),
          // Composition
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Composition',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                ...s.pieces.map<Widget>((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    const SizedBox(width: 6, height: 6,
                        child: DecoratedBox(decoration: BoxDecoration(color: _K.primary, shape: BoxShape.circle))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p, style: const TextStyle(fontSize: 13, color: _K.textMain))),
                  ]),
                )),
              ],
            ),
          ),
          // Conseil
          if (s.conseil.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates_outlined, size: 14, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.conseil,
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade800, height: 1.4))),
                ],
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildConseilGeneral(String conseil) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _K.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _K.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wb_sunny_outlined, size: 16, color: _K.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(conseil, style: const TextStyle(fontSize: 13, color: _K.primary, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildRegenerateButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
            color: _K.primarySurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _K.border)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh, color: _K.primary, size: 16),
            SizedBox(width: 8),
            Text('Générer d\'autres suggestions',
                style: TextStyle(color: _K.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const SizedBox(
            width: 48, height: 48,
            child: CircularProgressIndicator(
                strokeWidth: 3, color: _K.primary, backgroundColor: _K.primarySurface),
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4)),
        ],
      ),
    );
  }

  String _weatherEmoji(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('soleil') || d.contains('clair') || d.contains('ensoleillé') || d.contains('dégagé')) return '☀️';
    if (d.contains('nuage') || d.contains('couvert') || d.contains('cloud')) return '⛅';
    if (d.contains('pluie') || d.contains('averse') || d.contains('rain')) return '🌧️';
    if (d.contains('orage') || d.contains('thunder')) return '⛈️';
    if (d.contains('neige') || d.contains('snow')) return '❄️';
    if (d.contains('brouillard') || d.contains('brume') || d.contains('fog') || d.contains('mist')) return '🌫️';
    return '🌤️';
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
