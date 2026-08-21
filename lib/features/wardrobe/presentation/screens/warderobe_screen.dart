import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/outfit_entity.dart';
import '../../domain/entities/wardrobe_item_entity.dart';
import '../cubit/wardrobe_cubit.dart';
import '../cubit/wardrobe_state.dart';
import 'analysis_history_screen.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
class _K {
  static const primary = Color(0xFF6D28D9);
  static const primaryLight = Color(0xFF7C3AED);
  static const primarySurface = Color(0xFFF5F0FF);
  static const primarySoft = Color(0xFFF5F0FF);
  static const border = Color(0xFFE9D5FF);
  static const textMain = Color(0xFF1A1A2E);
  static const textMuted = Color(0xFF9CA3AF);
}

// ─── Screen principal ─────────────────────────────────────────────────────────
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  @override
  Widget build(BuildContext context) {
    return const _WardrobeBody();
  }
}

// ─── Corps principal ──────────────────────────────────────────────────────────
class _WardrobeBody extends StatefulWidget {
  const _WardrobeBody();

  @override
  State<_WardrobeBody> createState() => _WardrobeBodyState();
}

class _WardrobeBodyState extends State<_WardrobeBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'Tous';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'Tous',
    'T-shirts',
    'Chemises',
    'Pulls',
    'Vestes',
    'Manteaux',
    'Pantalons',
    'Jupes',
    'Robes',
    'Chaussures',
    'Accessoires',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WardrobeCubit, WardrobeState>(
      listenWhen: (prev, curr) => curr.errorMessage != null && prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ));
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F7FF),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVetementsTab(),
                    _buildOutfitsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFAB(context),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D0061), Color(0xFF5B21B6), Color(0xFF7C3AED)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Garde-robe',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  )),
              BlocBuilder<WardrobeCubit, WardrobeState>(
                buildWhen: (p, c) => p.items.length != c.items.length,
                builder: (_, state) {
                  final count = state.items.length;
                  return Text('$count vêtement${count > 1 ? 's' : ''}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7)));
                },
              ),
            ],
          ),
          const Spacer(),
          // Bouton historique
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<WardrobeCubit>(),
                  child: const AnalysisHistoryScreen(),
                ),
              ),
            ),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: BlocBuilder<WardrobeCubit, WardrobeState>(
                buildWhen: (p, c) => p.history.length != c.history.length,
                builder: (_, state) => Stack(
                  children: [
                    const Center(
                      child: Icon(Icons.history_rounded,
                          color: Colors.white, size: 20),
                    ),
                    if (state.history.isNotEmpty)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEC4899),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showAiSuggestion(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_K.primary, _K.primaryLight]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _K.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                  SizedBox(width: 5),
                  Text('Suggestion IA',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TabBar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _K.primary,
        unselectedLabelColor: _K.textMuted,
        indicatorColor: _K.primary,
        indicatorWeight: 2,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Vêtements'),
          Tab(text: 'Tenues'),
        ],
      ),
    );
  }

  // ─── FAB ───────────────────────────────────────────────────────────────────
  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        if (_tabController.index == 0) {
          _showAddItemSheet(context);
        } else {
          _showCreateOutfitSheet(context);
        }
      },
      backgroundColor: _K.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 — VÊTEMENTS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildVetementsTab() {
    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoryFilter(),
        Expanded(child: _buildItemsList()),
      ],
    );
  }


  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: _K.primarySoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _K.border, width: 0.5),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Rechercher dans ma garde-robe...',
            hintStyle:
                TextStyle(fontSize: 13, color: Colors.grey.shade400),
            prefixIcon:
                Icon(Icons.search, size: 18, color: Colors.grey.shade500),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear,
                        size: 16, color: Colors.grey.shade500),
                    onPressed: () => setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    }),
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 44,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final sel = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: sel ? _K.primary : _K.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : _K.primaryLight,
                    )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsList() {
    return BlocBuilder<WardrobeCubit, WardrobeState>(
      buildWhen: (p, c) =>
          p.items != c.items || p.isLoading != c.isLoading,
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: _K.primary));
        }

        var items = state.items;

        if (_selectedCategory != 'Tous') {
          items = items
              .where((i) => i.categorie == _selectedCategory)
              .toList();
        }
        if (_searchQuery.isNotEmpty) {
          items = items
              .where((i) =>
                  i.nom.toLowerCase().contains(_searchQuery) ||
                  i.marque.toLowerCase().contains(_searchQuery) ||
                  i.couleur.toLowerCase().contains(_searchQuery))
              .toList();
        }

        if (items.isEmpty) {
          if (state.items.isEmpty) {
            return _emptyState(
              'Votre garde-robe est vide\nAppuyez sur + pour ajouter !',
              Icons.checkroom_outlined,
            );
          }
          return _emptyState('Aucun résultat', Icons.search_off_outlined);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          itemCount: items.length,
          itemBuilder: (_, i) => _buildItemTile(context, items[i]),
        );
      },
    );
  }

  Widget _buildItemTile(BuildContext context, WardrobeItemEntity item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _K.border, width: 0.5),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 90,
              height: 100,
              child: item.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: _K.primarySurface),
                      errorWidget: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.marque.isNotEmpty)
                        Text(item.marque.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: _K.primaryLight,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w600,
                            )),
                      const Spacer(),
                      _sourceBadge(item.source),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(item.nom,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _K.textMain),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _chip(item.categorie, _K.primarySurface, _K.primary),
                      if (item.taille.isNotEmpty)
                        _chip(item.taille, const Color(0xFFF0FFF0),
                            Colors.green.shade700),
                      if (item.couleur.isNotEmpty)
                        _chip(item.couleur, Colors.grey.shade100,
                            Colors.grey.shade600),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _iconBtn(Icons.edit_outlined,
                    () => _showEditItemSheet(context, item)),
                const SizedBox(height: 4),
                _iconBtn(
                    Icons.delete_outline,
                    () => _deleteItem(context, item),
                    color: Colors.red.shade300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 — TENUES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOutfitsTab() {
    return BlocBuilder<WardrobeCubit, WardrobeState>(
      buildWhen: (p, c) =>
          p.outfits != c.outfits || p.items != c.items,
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: _K.primary));
        }
        if (state.outfits.isEmpty) {
          return _emptyState(
              'Aucune tenue créée\nAppuyez sur + pour composer !',
              Icons.style_outlined);
        }

        final wardrobeMap = {for (var i in state.items) i.id: i};

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          itemCount: state.outfits.length,
          itemBuilder: (_, i) =>
              _buildOutfitCard(context, state.outfits[i], wardrobeMap),
        );
      },
    );
  }

  Widget _buildOutfitCard(BuildContext context, OutfitEntity outfit,
      Map<String, WardrobeItemEntity> wardrobeMap) {
    final items = outfit.itemIds
        .map((id) => wardrobeMap[id])
        .whereType<WardrobeItemEntity>()
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _K.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              children: [
                const Icon(Icons.style_outlined,
                    size: 16, color: _K.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(outfit.nom,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _K.textMain)),
                ),
                Text(
                    '${outfit.itemIds.length} pièce${outfit.itemIds.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 11, color: _K.textMuted)),
                const SizedBox(width: 8),
                _iconBtn(Icons.delete_outline,
                    () => _deleteOutfit(context, outfit),
                    color: Colors.red.shade300),
              ],
            ),
          ),
          if (items.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final it = items[i];
                  return Container(
                    width: 72,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _K.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          it.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: it.imageUrl,
                                  fit: BoxFit.cover)
                              : Container(
                                  color: _K.primarySurface,
                                  child: const Icon(Icons.checkroom,
                                      color: _K.primary, size: 24)),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 3, horizontal: 4),
                              color: Colors.black.withValues(alpha: 0.45),
                              child: Text(it.categorie,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (outfit.note != null && outfit.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  Icon(Icons.notes,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(outfit.note!,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUGGESTION IA
  // ═══════════════════════════════════════════════════════════════════════════
  void _showAiSuggestion(BuildContext context) {
    final cubit = context.read<WardrobeCubit>();

    if (cubit.state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Ajoutez des vêtements pour obtenir des suggestions'),
          backgroundColor: Colors.orange));
      return;
    }

    cubit.getAiSuggestion();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: BlocBuilder<WardrobeCubit, WardrobeState>(
          buildWhen: (p, c) =>
              p.isAiLoading != c.isAiLoading ||
              p.aiSuggestion != c.aiSuggestion ||
              p.aiError != c.aiError,
          builder: (ctx, state) => Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(ctx).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            _K.primary,
                            _K.primaryLight
                          ]),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text('Suggestion IA',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _K.textMain)),
                        Text(
                            'Basée sur ${cubit.state.items.length} vêtement${cubit.state.items.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: _K.textMuted)),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: state.isAiLoading
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 40),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                    color: _K.primary),
                                const SizedBox(height: 16),
                                Text(
                                    'Analyse de vos ${cubit.state.items.length} vêtements...',
                                    style: TextStyle(
                                        color:
                                            Colors.grey.shade500,
                                        fontSize: 13)),
                              ],
                            ),
                          )
                        : state.aiError != null
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                        color:
                                            Colors.red.shade200)),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red.shade400,
                                        size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: Text(state.aiError!,
                                            style: TextStyle(
                                                color: Colors
                                                    .red.shade700,
                                                fontSize: 13))),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: _K.primarySoft,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                        color: _K.border)),
                                child: Text(
                                    state.aiSuggestion ?? '',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: _K.textMain,
                                        height: 1.7)),
                              ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!state.isAiLoading)
                  GestureDetector(
                    onTap: () => cubit.getAiSuggestion(),
                    child: Container(
                      width: double.infinity,
                      height: 46,
                      decoration: BoxDecoration(
                          color: _K.primarySurface,
                          borderRadius:
                              BorderRadius.circular(14)),
                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh,
                              color: _K.primary, size: 16),
                          SizedBox(width: 6),
                          Text('Nouvelle suggestion',
                              style: TextStyle(
                                  color: _K.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHEET — Ajouter / Modifier vêtement
  // ═══════════════════════════════════════════════════════════════════════════
  void _showAddItemSheet(BuildContext context) =>
      _showItemSheet(context, null);
  void _showEditItemSheet(BuildContext context, WardrobeItemEntity item) =>
      _showItemSheet(context, item);

  void _showItemSheet(BuildContext context, WardrobeItemEntity? existing) {
    final cubit = context.read<WardrobeCubit>();
    final nomCtrl =
        TextEditingController(text: existing?.nom ?? '');
    final marqueCtrl =
        TextEditingController(text: existing?.marque ?? '');
    final couleurCtrl =
        TextEditingController(text: existing?.couleur ?? '');
    String categorie = existing?.categorie ?? 'T-shirts';
    String taille = existing?.taille ?? '';
    String source = existing?.source ?? 'manuel';
    XFile? pickedImage;
    List<int>? pickedImageBytes;
    bool isLoading = false;

    final tailles = [
      'XS', 'S', 'M', 'L', 'XL', 'XXL',
      '34', '36', '38', '40', '42', '44'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                          color: _K.primary,
                          borderRadius:
                              BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                        existing == null
                            ? 'Ajouter un vêtement'
                            : 'Modifier le vêtement',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _K.textMain)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle),
                        child:
                            const Icon(Icons.close, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Image picker
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final xfile = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 1024);
                    if (xfile != null) {
                      final bytes = await xfile.readAsBytes();
                      setS(() {
                        pickedImage = xfile;
                        pickedImageBytes = bytes;
                      });
                    }
                  },
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: _K.primarySurface,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: _K.border, width: 1),
                    ),
                    child: pickedImageBytes != null
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(16),
                            child: Image.memory(
                                Uint8List.fromList(pickedImageBytes!),
                                fit: BoxFit.cover,
                                width: double.infinity))
                        : existing?.imageUrl.isNotEmpty == true
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                    imageUrl: existing!.imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity))
                            : Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                      Icons
                                          .add_photo_alternate_outlined,
                                      size: 32,
                                      color: _K.primary),
                                  const SizedBox(height: 8),
                                  Text('Ajouter une photo',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors
                                              .grey.shade500)),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 14),

                // Source
                Container(
                  decoration: BoxDecoration(
                      color: _K.primarySurface,
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: ['manuel', 'marketplace'].map((s) {
                      final sel = source == s;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setS(() => source = s),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                            decoration: BoxDecoration(
                                color: sel
                                    ? _K.primary
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(10)),
                            child: Text(
                                s == 'manuel'
                                    ? 'Ajout manuel'
                                    : 'Marketplace',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? Colors.white
                                        : _K.primaryLight)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                _sheetField(nomCtrl, 'Nom du vêtement *',
                    Icons.checkroom_outlined),
                const SizedBox(height: 10),
                _sheetField(
                    marqueCtrl, 'Marque', Icons.store_outlined),
                const SizedBox(height: 10),
                _sheetField(couleurCtrl, 'Couleur',
                    Icons.palette_outlined),
                const SizedBox(height: 14),

                _sheetLabel('Catégorie'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children:
                      _categories.where((c) => c != 'Tous').map((c) {
                    final sel = categorie == c;
                    return GestureDetector(
                      onTap: () => setS(() => categorie = c),
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                            color: sel
                                ? _K.primary
                                : _K.primarySoft,
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                                color: sel
                                    ? _K.primary
                                    : _K.border)),
                        child: Text(c,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? Colors.white
                                    : _K.primary)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                _sheetLabel('Taille'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: tailles.map((t) {
                    final sel = taille == t;
                    return GestureDetector(
                      onTap: () => setS(() =>
                          taille = taille == t ? '' : t),
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                            color: sel
                                ? _K.primary
                                : _K.primarySoft,
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(
                                color: sel
                                    ? _K.primary
                                    : _K.border)),
                        child: Text(t,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? Colors.white
                                    : _K.primary)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),

                // Bouton sauvegarder
                GestureDetector(
                  onTap: isLoading
                      ? null
                      : () async {
                          if (nomCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                                    content:
                                        Text('Le nom est requis'),
                                    backgroundColor:
                                        Colors.orange));
                            return;
                          }
                          setS(() => isLoading = true);

                          final entity = WardrobeItemEntity(
                            id: existing?.id ?? '',
                            nom: nomCtrl.text.trim(),
                            marque: marqueCtrl.text.trim(),
                            couleur: couleurCtrl.text.trim(),
                            categorie: categorie,
                            taille: taille,
                            source: source,
                            imageUrl: existing?.imageUrl ?? '',
                          );

                          if (existing != null) {
                            await cubit.updateItem(entity,
                                imageFile: pickedImage);
                          } else {
                            await cubit.addItem(entity,
                                imageFile: pickedImage);
                          }

                          setS(() => isLoading = false);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_K.primary, _K.primaryLight]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2)
                          : Text(
                              existing == null
                                  ? 'Ajouter à la garde-robe'
                                  : 'Enregistrer les modifications',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHEET — Créer tenue
  // ═══════════════════════════════════════════════════════════════════════════
  void _showCreateOutfitSheet(BuildContext context) {
    final cubit = context.read<WardrobeCubit>();
    final nomCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final Set<String> selectedIds = {};
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (ctx, scrollCtrl) => SingleChildScrollView(
            controller: scrollCtrl,
            padding:
                const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                            color: _K.primary,
                            borderRadius:
                                BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    const Text('Créer une tenue',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _K.textMain)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sheetField(nomCtrl, 'Nom de la tenue *',
                    Icons.style_outlined),
                const SizedBox(height: 10),
                _sheetField(noteCtrl, 'Occasion / note',
                    Icons.event_note_outlined),
                const SizedBox(height: 20),
                _sheetLabel('Sélectionnez les pièces'),
                const SizedBox(height: 10),
                // Sélection des vêtements depuis l'état du cubit
                Builder(builder: (_) {
                  final items = cubit.state.items;
                  if (items.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: _K.primarySurface,
                          borderRadius:
                              BorderRadius.circular(12)),
                      child: const Text(
                          'Ajoutez d\'abord des vêtements à votre garde-robe',
                          style: TextStyle(
                              color: _K.textMuted,
                              fontSize: 13),
                          textAlign: TextAlign.center),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final it = items[i];
                      final sel = selectedIds.contains(it.id);
                      return GestureDetector(
                        onTap: () => setS(() {
                          if (sel) {
                            selectedIds.remove(it.id);
                          } else {
                            selectedIds.add(it.id);
                          }
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(
                              bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: sel
                                  ? _K.primarySurface
                                  : Colors.white,
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                  color: sel
                                      ? _K.primary
                                      : _K.border,
                                  width: sel ? 1.5 : 0.5)),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: it.imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: it.imageUrl,
                                          fit: BoxFit.cover)
                                      : Container(
                                          color:
                                              _K.primarySurface,
                                          child: const Icon(
                                              Icons.checkroom,
                                              color: _K.primary,
                                              size: 20)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(it.nom,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w600,
                                            color:
                                                _K.textMain)),
                                    Text(
                                        '${it.categorie}${it.taille.isNotEmpty ? ' · T${it.taille}' : ''}${it.couleur.isNotEmpty ? ' · ${it.couleur}' : ''}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color:
                                                _K.textMuted)),
                                  ],
                                ),
                              ),
                              Icon(
                                  sel
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: sel
                                      ? _K.primary
                                      : Colors.grey.shade300,
                                  size: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: isLoading
                      ? null
                      : () async {
                          if (nomCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                                    content: Text(
                                        'Donnez un nom à la tenue'),
                                    backgroundColor:
                                        Colors.orange));
                            return;
                          }
                          if (selectedIds.isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                                    content: Text(
                                        'Sélectionnez au moins un vêtement'),
                                    backgroundColor:
                                        Colors.orange));
                            return;
                          }
                          setS(() => isLoading = true);
                          await cubit.addOutfit(OutfitEntity(
                            id: '',
                            nom: nomCtrl.text.trim(),
                            note: noteCtrl.text.trim(),
                            itemIds: selectedIds.toList(),
                          ));
                          setS(() => isLoading = false);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          _K.primary,
                          _K.primaryLight
                        ]),
                        borderRadius: BorderRadius.circular(16)),
                    child: Center(
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2)
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Icon(
                                    Icons.style_outlined,
                                    color: Colors.white,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                    selectedIds.isEmpty
                                        ? 'Créer la tenue'
                                        : 'Créer la tenue (${selectedIds.length} pièce${selectedIds.length > 1 ? 's' : ''})',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.w600)),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRUD
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _deleteItem(
      BuildContext context, WardrobeItemEntity item) async {
    final cubit = context.read<WardrobeCubit>();
    final confirm = await _confirmDialog(
        context, 'Supprimer "${item.nom}" de votre garde-robe ?');
    if (confirm == true && mounted) cubit.deleteItem(item.id);
  }

  Future<void> _deleteOutfit(
      BuildContext context, OutfitEntity outfit) async {
    final cubit = context.read<WardrobeCubit>();
    final confirm = await _confirmDialog(
        context, 'Supprimer la tenue "${outfit.nom}" ?');
    if (confirm == true && mounted) cubit.deleteOutfit(outfit.id);
  }

  Future<bool?> _confirmDialog(BuildContext context, String message) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirmer',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          content:
              Text(message, style: const TextStyle(fontSize: 14)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Annuler',
                    style: TextStyle(
                        color: Colors.grey.shade600))),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text('Supprimer',
                    style: TextStyle(color: Colors.white))),
          ],
        ),
      );

  // ─── Helpers UI ────────────────────────────────────────────────────────────
  Widget _sourceBadge(String source) {
    final isMarket = source == 'marketplace';
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isMarket
            ? _K.primarySurface
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isMarket ? 'Shop' : 'Manuel',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: isMarket ? _K.primary : Colors.orange.shade700,
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                color: fg,
                fontWeight: FontWeight.w500)),
      );

  Widget _iconBtn(IconData icon, VoidCallback onTap,
          {Color? color}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: (color ?? _K.primary).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color ?? _K.primary),
        ),
      );

  Widget _imgPlaceholder() => Container(
        color: _K.primarySurface,
        child: const Center(
            child:
                Icon(Icons.checkroom, color: _K.primary, size: 32)),
      );

  Widget _emptyState(String msg, IconData icon) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: _K.primarySurface, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: _K.primary),
            ),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _K.textMuted, fontSize: 14, height: 1.5)),
          ],
        ),
      );

  Widget _sheetField(
          TextEditingController ctrl, String hint, IconData icon) =>
      TextField(
        controller: ctrl,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.grey.shade400, fontSize: 13),
          prefixIcon:
              Icon(icon, color: _K.primary, size: 18),
          filled: true,
          fillColor: _K.primarySoft,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: _K.primary, width: 1)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      );

  Widget _sheetLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _K.textMain));
}
