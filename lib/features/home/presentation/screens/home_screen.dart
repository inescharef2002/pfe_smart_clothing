import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe_smart_clothing/core/di/injection.dart';
import 'package:pfe_smart_clothing/features/marketplace/presentation/cubit/marketplace_cubit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pfe_smart_clothing/features/outfit_analysis/domain/entities/weather_entity.dart';
import 'package:pfe_smart_clothing/features/outfit_analysis/domain/usecases/get_weather_usecase.dart';
import 'package:pfe_smart_clothing/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pfe_smart_clothing/features/profile/presentation/cubit/profile_state.dart';
import 'package:pfe_smart_clothing/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:pfe_smart_clothing/features/wardrobe/presentation/screens/warderobe_screen.dart';
import 'package:pfe_smart_clothing/features/profile/presentation/screens/profile_screen.dart';
import 'package:pfe_smart_clothing/features/outfit_analysis/presentation/cubit/outfit_analysis_cubit.dart';
import 'package:pfe_smart_clothing/features/outfit_analysis/presentation/screens/ai_analysis_screen.dart';
import 'package:pfe_smart_clothing/features/outfit_analysis/presentation/screens/ai_outfit_screen.dart';
import 'package:pfe_smart_clothing/features/wardrobe/presentation/cubit/wardrobe_cubit.dart';
import 'package:pfe_smart_clothing/features/wardrobe/presentation/cubit/wardrobe_state.dart';
import 'package:pfe_smart_clothing/features/wardrobe/domain/entities/wardrobe_item_entity.dart';
import '../../../auth/presentation/screens/signin_screen.dart';

class _C {
  static const bg = Color(0xFFFAF7FF);
  static const primary = Color(0xFF6D28D9);
  static const primarySoft = Color(0xFFEDE9FE);
  static const ink = Color(0xFF1A0040);
  static const muted = Color(0xFF9CA3AF);
  static const fuchsia = Color(0xFFD946EF);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final MarketplaceCubit _marketplaceCubit;
  late final ProfileCubit _profileCubit;
  late final WardrobeCubit _wardrobeCubit;

  @override
  void initState() {
    super.initState();
    _marketplaceCubit = sl<MarketplaceCubit>()..loadData();
    _profileCubit = sl<ProfileCubit>()..loadProfile();
    _wardrobeCubit = sl<WardrobeCubit>()..loadWardrobe();
  }

  @override
  void dispose() {
    _marketplaceCubit.close();
    _profileCubit.close();
    _wardrobeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _marketplaceCubit),
        BlocProvider.value(value: _profileCubit),
        BlocProvider.value(value: _wardrobeCubit),
      ],
      child: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state.isLoggedOut) {
            // ✅ Annuler les streams AVANT de naviguer
            _marketplaceCubit.cancelStreams();
            _wardrobeCubit.cancelStreams();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SignInScreen()),
            );
          }
        },
        child: Scaffold(
          backgroundColor: _C.bg,
          body: IndexedStack(
            index: _selectedIndex,
            children: const [
              DashboardScreen(),
              WardrobeScreen(),
              MarketplaceScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return _FloatingNavBar(
      selectedIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
    );
  }
}

// ── Dashboard ─────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  WeatherEntity? _weather;
  bool _weatherLoading = true;
  bool _usingGps = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    double? lat, lon;
    try {
      final ok = await Geolocator.isLocationServiceEnabled();
      if (ok) {
        LocationPermission p = await Geolocator.checkPermission();
        if (p == LocationPermission.denied)
          p = await Geolocator.requestPermission();
        if (p == LocationPermission.whileInUse ||
            p == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 10)),
          );
          lat = pos.latitude;
          lon = pos.longitude;
          _usingGps = true;
        }
      }
    } catch (_) {}
    final result = await sl<GetWeatherUseCase>().call(lat: lat, lon: lon);
    if (mounted) {
      setState(() {
        _weatherLoading = false;
        result.fold((_) => null, (w) => _weather = w);
      });
    }
  }

  String _weatherEmoji(String d) {
    final s = d.toLowerCase();
    if (s.contains('soleil') || s.contains('clear') || s.contains('sunny'))
      return '☀️';
    if (s.contains('nuage') || s.contains('cloud') || s.contains('couvert'))
      return '⛅';
    if (s.contains('pluie') || s.contains('rain') || s.contains('drizzle'))
      return '🌧️';
    if (s.contains('orage') || s.contains('thunder')) return '⛈️';
    if (s.contains('neige') || s.contains('snow')) return '❄️';
    if (s.contains('brouillard') || s.contains('fog') || s.contains('mist'))
      return '🌫️';
    return '🌤️';
  }

  String _fashionTip(int temp) {
    if (temp < 10)
      return 'Superposez les couches — pull, veste & manteau au programme';
    if (temp < 18)
      return 'Une veste légère s\'impose pour cette journée fraîche';
    if (temp < 26)
      return 'Température idéale — c\'est le moment d\'oser le casual-chic';
    return 'Il fait chaud ! Misez sur les matières légères et aérées';
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _goToAiOutfit(BuildContext ctx) {
    Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<OutfitAnalysisCubit>()),
              BlocProvider.value(value: ctx.read<WardrobeCubit>()),
            ],
            child: const AiOutfitScreen(),
          ),
        ));
  }

  List<Map<String, dynamic>> _getDayOccasions() {
    final day = DateTime.now().weekday;
    final isWeekend = day >= 6;
    const dNames = [
      '',
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    final badge = dNames[day];
    if (isWeekend) {
      return [
        {
          'occasion': 'Weekend',
          'emoji': '🌿',
          'title': 'Week-end',
          'desc': 'Décontracté & confortable',
          'badge': badge,
          'c1': const Color(0xFF059669),
          'c2': const Color(0xFF34D399),
          'cats': ['T-shirts', 'Pantalons', 'Chaussures', 'Pulls'],
        },
        {
          'occasion': 'Soirée',
          'emoji': '✨',
          'title': 'Soirée',
          'desc': 'Pour sortir & briller',
          'badge': badge,
          'c1': const Color(0xFF7C3AED),
          'c2': const Color(0xFFA855F7),
          'cats': ['Robes', 'Vestes', 'Chaussures', 'Chemises'],
        },
        {
          'occasion': 'Sport',
          'emoji': '🏃',
          'title': 'Sport',
          'desc': 'Restez actif',
          'badge': badge,
          'c1': const Color(0xFFEA580C),
          'c2': const Color(0xFFFB923C),
          'cats': ['T-shirts', 'Pantalons', 'Chaussures'],
        },
      ];
    }
    return [
      {
        'occasion': 'Travail',
        'emoji': '💼',
        'title': 'Travail',
        'desc': 'Professionnel & soigné',
        'badge': badge,
        'c1': const Color(0xFF1D4ED8),
        'c2': const Color(0xFF60A5FA),
        'cats': ['Chemises', 'Vestes', 'Pantalons', 'Chaussures'],
      },
      {
        'occasion': 'Quotidienne',
        'emoji': '👗',
        'title': 'Casual',
        'desc': 'Pour la journée',
        'badge': badge,
        'c1': _C.primary,
        'c2': const Color(0xFFA78BFA),
        'cats': ['T-shirts', 'Pulls', 'Pantalons', 'Robes'],
      },
      {
        'occasion': 'Soirée',
        'emoji': '🌙',
        'title': 'Après-travail',
        'desc': 'Prêt(e) pour la soirée',
        'badge': badge,
        'c1': const Color(0xFF0D9488),
        'c2': const Color(0xFF2DD4BF),
        'cats': ['Robes', 'Vestes', 'Chemises', 'Chaussures'],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWeatherHero(),
              const SizedBox(height: 28),
              _label('Fonctionnalités IA'),
              const SizedBox(height: 14),
              _buildAiFeatures(context),
              const SizedBox(height: 28),
              _label('Tenues du jour'),
              const SizedBox(height: 14),
              BlocBuilder<WardrobeCubit, WardrobeState>(
                buildWhen: (p, c) => p.items != c.items,
                builder: (ctx, ws) => _buildCarousel(ctx, ws),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherHero() {
    if (_weatherLoading) {
      return _heroShell(
        child: Row(children: [
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)),
          const SizedBox(width: 14),
          Text('Chargement météo…',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
        ]),
      );
    }

    if (_weather == null) {
      return _heroShell(
        child: Row(children: [
          const Text('🌐', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Météo indisponible',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _weatherLoading = true);
              _loadWeather();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Réessayer',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      );
    }

    final w = _weather!;
    return _heroShell(
      child: Column(
        children: [
          Row(
            children: [
              Text(_weatherEmoji(w.description),
                  style: const TextStyle(fontSize: 52)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${w.temperature}°C',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 1.0)),
                    const SizedBox(height: 3),
                    Text(_cap(w.description),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(children: [
                    Icon(
                        _usingGps
                            ? Icons.gps_fixed_rounded
                            : Icons.location_on_outlined,
                        color: Colors.white.withValues(alpha: 0.80),
                        size: 12),
                    const SizedBox(width: 4),
                    Text(w.city,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(Icons.water_drop_outlined,
                          size: 11,
                          color: Colors.white.withValues(alpha: 0.90)),
                      const SizedBox(width: 3),
                      Text('${w.humidity}%',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.90))),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Container(
                height: 1, color: Colors.white.withValues(alpha: 0.18)),
          ),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tips_and_updates_outlined,
                  size: 14, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _fashionTip(w.temperature),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    height: 1.4),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _weatherLoading = true);
                _loadWeather();
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _heroShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), _C.primary, _C.fuchsia],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.50, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: _C.primary.withValues(alpha: 0.38),
              blurRadius: 28,
              offset: const Offset(0, 12)),
        ],
      ),
      child: child,
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _C.ink,
            letterSpacing: -0.3));
  }

  Widget _buildAiFeatures(BuildContext context) {
    return Column(
      children: [
        _featureCard(
          icon: Icons.camera_enhance_outlined,
          iconBg: _C.primarySoft,
          iconColor: _C.primary,
          title: 'Analyser un vêtement',
          subtitle:
              'Photo → catégorie, couleur & description détectées par l\'IA',
          tag: 'Vision IA',
          tagColor: _C.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => sl<OutfitAnalysisCubit>()),
                  BlocProvider.value(value: context.read<WardrobeCubit>()),
                  BlocProvider.value(value: context.read<MarketplaceCubit>()),
                ],
                child: const AiAnalysisScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _featureCard(
          icon: Icons.style_outlined,
          iconBg: const Color(0xFFCCFBF1),
          iconColor: const Color(0xFF0D9488),
          title: 'Suggestions de tenues',
          subtitle:
              'Tenues personnalisées selon la météo et l\'occasion du jour',
          tag: 'Météo + IA',
          tagColor: const Color(0xFF0D9488),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => sl<OutfitAnalysisCubit>()),
                  BlocProvider.value(value: context.read<WardrobeCubit>()),
                ],
                child: const AiOutfitScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDE9FE)),
          boxShadow: [
            BoxShadow(
                color: _C.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, size: 26, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _C.ink)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(tag,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: tagColor)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: _C.muted, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: _C.primarySoft,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: _C.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(BuildContext context, WardrobeState ws) {
    final occasions = _getDayOccasions();
    final isWeekend = DateTime.now().weekday >= 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(
            isWeekend ? 'Pour ce week-end' : 'Pour aujourd\'hui',
            style: const TextStyle(fontSize: 13, color: _C.muted),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isWeekend ? const Color(0xFFDCFCE7) : _C.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isWeekend ? '🌿 Week-end' : '💼 Semaine',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isWeekend ? const Color(0xFF166534) : _C.primary,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.zero,
            itemCount: occasions.length,
            itemBuilder: (ctx, i) {
              final o = occasions[i];
              final preview = ws.items
                  .where((it) =>
                      (o['cats'] as List<String>).contains(it.categorie))
                  .take(3)
                  .toList();
              return Container(
                width: 178,
                margin: const EdgeInsets.only(right: 14),
                child: _buildOutfitCard(
                  ctx: ctx,
                  occasion: o['occasion'] as String,
                  emoji: o['emoji'] as String,
                  title: o['title'] as String,
                  desc: o['desc'] as String,
                  badge: o['badge'] as String,
                  c1: o['c1'] as Color,
                  c2: o['c2'] as Color,
                  preview: preview,
                  empty: ws.items.isEmpty,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOutfitCard({
    required BuildContext ctx,
    required String occasion,
    required String emoji,
    required String title,
    required String desc,
    required String badge,
    required Color c1,
    required Color c2,
    required List<WardrobeItemEntity> preview,
    required bool empty,
  }) {
    return GestureDetector(
      onTap: () => _goToAiOutfit(ctx),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [c1, c2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
                color: c1.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(13)),
                  child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 20))),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(badge,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(desc,
                style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.white.withValues(alpha: 0.78)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const Spacer(),
            if (preview.isNotEmpty)
              SizedBox(
                height: 36,
                child: Stack(
                  children: List.generate(preview.length, (i) {
                    final item = preview[i];
                    return Positioned(
                      left: i * 24.0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.25),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.60),
                              width: 2),
                        ),
                        child: ClipOval(
                          child: item.imageUrl.isNotEmpty
                              ? Image.network(item.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                      Icons.checkroom_outlined,
                                      size: 16,
                                      color:
                                          Colors.white.withValues(alpha: 0.80)))
                              : Icon(Icons.checkroom_outlined,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.80)),
                        ),
                      ),
                    );
                  }),
                ),
              )
            else
              Text(
                empty ? 'Ajoutez des vêtements' : 'Aucune pièce disponible',
                style: TextStyle(
                    fontSize: 10, color: Colors.white.withValues(alpha: 0.70)),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Générer une tenue',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 13, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Floating NavBar ───────────────────────────────────────────────────────────
class _NavDef {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  const _NavDef(this.activeIcon, this.inactiveIcon, this.label);
}

class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavDef(Icons.home_rounded, Icons.home_outlined, 'Accueil'),
    _NavDef(Icons.checkroom_rounded, Icons.checkroom_outlined, 'Garde-robe'),
    _NavDef(Icons.store_rounded, Icons.store_outlined, 'Marketplace'),
    _NavDef(Icons.person_rounded, Icons.person_outline, 'Profil'),
  ];

  const _FloatingNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    const pillH = 64.0;
    const circleD = 52.0;
    const overlap = circleD * 0.55;
    final totalH = pillH + overlap + bottomPad;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final itemW = w / _items.length;
        final circleLeft = itemW * selectedIndex + (itemW - circleD) / 2;

        return Container(
          color: const Color(0xFFF8F4FF),
          height: totalH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                bottom: bottomPad,
                left: 0,
                right: 0,
                height: pillH,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                          color:
                              const Color(0xFF6D28D9).withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Row(
                    children: List.generate(_items.length, (i) {
                      final sel = i == selectedIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onTap(i),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!sel)
                                Icon(_items[i].inactiveIcon,
                                    size: 22, color: Colors.grey.shade400),
                              if (sel) const SizedBox(height: 22),
                              const SizedBox(height: 4),
                              Text(
                                _items[i].label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight:
                                      sel ? FontWeight.w700 : FontWeight.w400,
                                  color: sel
                                      ? const Color(0xFF6D28D9)
                                      : Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                bottom: bottomPad + pillH - overlap,
                left: 16 + circleLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: circleD,
                  height: circleD,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B21B6), Color(0xFF9333EA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color:
                              const Color(0xFF6D28D9).withValues(alpha: 0.40),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Icon(
                    _items[selectedIndex].activeIcon,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
