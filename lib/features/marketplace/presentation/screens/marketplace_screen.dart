import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pfe_smart_clothing/features/marketplace/domain/entities/product_entity.dart';
import 'package:pfe_smart_clothing/features/marketplace/presentation/cubit/marketplace_cubit.dart';
import 'package:pfe_smart_clothing/features/marketplace/presentation/cubit/marketplace_state.dart';
import 'package:pfe_smart_clothing/features/profile/presentation/cubit/profile_cubit.dart';
import 'cart_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Tous', 'Robes', 'Pantalons', 'Chemises', 'Chaussures', 'Accessoires', 'Vestes',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCart(BuildContext context) {
    final marketplaceCubit = context.read<MarketplaceCubit>();
    final profileCubit = context.read<ProfileCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: marketplaceCubit),
            BlocProvider.value(value: profileCubit),
          ],
          child: const CartScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return BlocConsumer<MarketplaceCubit, MarketplaceState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.successMessage!),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Voir',
              textColor: Colors.white,
              onPressed: () => _openCart(context),
            ),
          ));
          context.read<MarketplaceCubit>().clearMessages();
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ));
          context.read<MarketplaceCubit>().clearMessages();
        }
      },
      builder: (context, state) => Scaffold(
        backgroundColor: const Color(0xFFF8F7FF),
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
                _buildHeader(context, state),
                // White card for content
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(
                      children: [
                        _buildSearchBar(context, state),
                        _buildCategories(context, state),
                        Expanded(child: _buildArticlesList(context, state, isSmallScreen, isLargeScreen)),
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

  Widget _buildHeader(BuildContext context, MarketplaceState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Marketplace',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5)),
              Text('Découvrez nos articles',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
          const Spacer(),
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3))),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _openCart(context),
                  icon: const Icon(Icons.shopping_bag_outlined,
                      color: Colors.white, size: 20),
                ),
              ),
              if (state.cartItemsCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B), shape: BoxShape.circle),
                    child: Center(
                      child: Text('${state.cartItemsCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, MarketplaceState state) {
    final cubit = context.read<MarketplaceCubit>();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(color: const Color(0xFFF5F0FF), borderRadius: BorderRadius.circular(14)),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => cubit.search(value),
              decoration: InputDecoration(
                hintText: 'Rechercher un article...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade500),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 16, color: Colors.grey.shade500),
                        onPressed: () { _searchController.clear(); cubit.search(''); },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _quickFilter(
                icon: Icons.local_fire_department_rounded,
                label: 'Promo',
                activeColor: const Color(0xFFEA580C),
                active: state.showPromoOnly,
                onTap: () => cubit.togglePromoOnly(),
              ),
              const SizedBox(width: 10),
              _quickFilter(
                icon: Icons.auto_awesome_rounded,
                label: 'Nouveautés',
                activeColor: const Color(0xFF7C3AED),
                active: state.showNewOnly,
                onTap: () => cubit.toggleNewOnly(),
              ),
              const Spacer(),
              if (state.hasActiveFilters)
                GestureDetector(
                  onTap: () {
                    if (state.showPromoOnly) cubit.togglePromoOnly();
                    if (state.showNewOnly) cubit.toggleNewOnly();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.close_rounded, size: 12, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 4),
                        const Text('Effacer',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: Color(0xFF7C3AED))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _quickFilter({
    required IconData icon,
    required String label,
    required Color activeColor,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: active ? activeColor : const Color(0xFFE8E0F0),
          ),
          boxShadow: active
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.30),
                  blurRadius: 10, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withValues(alpha: 0.25)
                    : activeColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 13,
                  color: active ? Colors.white : activeColor),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : const Color(0xFF374151),
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _catEmojis = {
    'Tous':        '✦',
    'Robes':       '👗',
    'Pantalons':   '👖',
    'Chemises':    '👔',
    'Chaussures':  '👟',
    'Vestes':      '🧥',
    'Pulls':       '🧶',
    'T-shirts':    '👕',
    'Accessoires': '👜',
    'Jupes':       '🩱',
  };

  Widget _buildCategories(BuildContext context, MarketplaceState state) {
    final cubit = context.read<MarketplaceCubit>();
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == state.selectedCategory;
          final emoji = _catEmojis[cat] ?? '🏷️';

          return GestureDetector(
            onTap: () => cubit.selectCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF5B21B6), Color(0xFF9333EA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : const Color(0xFFE8E0F5),
                ),
                boxShadow: isSelected
                    ? [BoxShadow(
                        color: const Color(0xFF6D28D9).withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )]
                    : [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji,
                      style: TextStyle(
                          fontSize: cat == 'Tous' ? 11 : 14)),
                  const SizedBox(width: 6),
                  Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF6B7280),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticlesList(BuildContext context, MarketplaceState state, bool isSmallScreen, bool isLargeScreen) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6D28D9)));
    }

    if (state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFF5F0FF), shape: BoxShape.circle),
              child: Icon(Icons.shopping_bag_outlined, size: 50, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text('Aucun article disponible', style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Revenez plus tard pour découvrir nos nouveautés', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );
    }

    final products = state.filteredProducts;
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 50, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Aucun résultat pour "${state.searchQuery}"', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isLargeScreen ? 4 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.68,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildArticleCard(context, products[index]),
    );
  }

  Widget _buildArticleCard(BuildContext context, ProductEntity product) {
    final bgColor = _getCategoryColor(product.categorie);
    return GestureDetector(
      onTap: () => _showArticleDetail(context, product),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDE0F5), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: bgColor, child: const Center(child: Icon(Icons.checkroom, size: 40, color: Color(0xFFCE93D8)))),
                            errorWidget: (_, __, ___) => Container(color: bgColor, child: const Center(child: Icon(Icons.checkroom, size: 40, color: Color(0xFFCE93D8)))),
                          )
                        : Container(color: bgColor, child: const Center(child: Icon(Icons.checkroom, size: 40, color: Color(0xFFCE93D8)))),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.promo && product.prixPromo != null)
                          _badge('-${(((product.prix - product.prixActuel) / product.prix) * 100).toStringAsFixed(0)}%', Colors.red.shade500),
                        if (product.nouveaute) ...[
                          if (product.promo) const SizedBox(height: 4),
                          _badge('NEW', Colors.green.shade600),
                        ],
                        if (!product.disponible) ...[
                          if (product.promo || product.nouveaute) const SizedBox(height: 4),
                          _badge('Indispo', Colors.grey.shade600),
                        ],
                        if (product.stock != null && product.stock! <= 0) ...[
                          if (product.promo || product.nouveaute || !product.disponible) const SizedBox(height: 4),
                          _badge('Épuisé', Colors.red.shade700),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                      child: const Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                    ),
                  ),
                  if (product.couleurs.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Row(
                        children: [
                          ...product.couleurs.take(3).map((c) => Container(
                                width: 11,
                                height: 11,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: Color(int.parse((c['hex'] as String).replaceAll('#', '0xFF'))),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                              )),
                          if (product.couleurs.length > 3)
                            Text('+${product.couleurs.length - 3}', style: const TextStyle(fontSize: 8, color: Colors.white)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 6, 11, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.marque.isNotEmpty)
                    Text(product.marque.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Color(0xFF9C4DC8), letterSpacing: 0.8)),
                  const SizedBox(height: 2),
                  Text(product.nom, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF222222), height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if (product.tailles.isNotEmpty)
                    Row(
                      children: [
                        ...product.tailles.take(3).map((t) => Container(
                              margin: const EdgeInsets.only(right: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE1D0F0), width: 0.5), borderRadius: BorderRadius.circular(5)),
                              child: Text(t.toString(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Color(0xFF7B52A8))),
                            )),
                        if (product.tailles.length > 3)
                          Text('+${product.tailles.length - 3}', style: const TextStyle(fontSize: 9, color: Color(0xFF9C4DC8))),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.promo && product.prixPromo != null) ...[
                        Text('${product.prixActuel} DT', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.red)),
                        const SizedBox(width: 5),
                        Text('${product.prix} DT', style: TextStyle(fontSize: 10, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough)),
                      ] else
                        Text('${product.prix} DT', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6D28D9))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w500)),
      );

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Robes': return const Color(0xFFF9F3EC);
      case 'Pantalons': return const Color(0xFFFDF6EC);
      case 'Vestes': return const Color(0xFFF0F0F0);
      case 'Chemises': return const Color(0xFFEAF3FB);
      case 'Chaussures': return const Color(0xFFF5F5F5);
      default: return const Color(0xFFF5F0FF);
    }
  }

  void _showArticleDetail(BuildContext context, ProductEntity product) {
    final cubit = context.read<MarketplaceCubit>();
    String? selectedTaille;
    String? selectedCouleur;

    final List<String> images = [
      if (product.imageUrl.isNotEmpty) product.imageUrl,
      if (product.imageUrl2.isNotEmpty) product.imageUrl2,
      if (product.imageUrl3.isNotEmpty) product.imageUrl3,
    ];
    int currentImage = 0;
    final bgColor = _getCategoryColor(product.categorie);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (ctx, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            SizedBox(
                              height: 350,
                              width: double.infinity,
                              child: images.isNotEmpty
                                  ? PageView.builder(
                                      onPageChanged: (i) => setModalState(() => currentImage = i),
                                      itemCount: images.length,
                                      itemBuilder: (_, i) => CachedNetworkImage(
                                        imageUrl: images[i],
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: bgColor, child: const Center(child: Icon(Icons.checkroom, size: 80, color: Color(0xFFCE93D8)))),
                                        errorWidget: (_, __, ___) => Container(color: bgColor, child: const Center(child: Icon(Icons.checkroom, size: 80, color: Color(0xFFCE93D8)))),
                                      ),
                                    )
                                  : Container(color: bgColor, child: const Center(child: Icon(Icons.checkroom, size: 80, color: Color(0xFFCE93D8)))),
                            ),
                            if (images.length > 1)
                              Positioned(
                                bottom: 20,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(images.length, (i) => Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: currentImage == i ? 18 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: currentImage == i ? const Color(0xFF6D28D9) : Colors.white.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  )),
                                ),
                              ),
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product.promo && product.prixPromo != null)
                                    _badge('-${(((product.prix - product.prixActuel) / product.prix) * 100).toStringAsFixed(0)}%', Colors.red.shade500),
                                  if (product.nouveaute) ...[
                                    if (product.promo) const SizedBox(height: 6),
                                    _badge('NOUVEAUTÉ', Colors.green.shade600),
                                  ],
                                ],
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(ctx),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (product.marque.isNotEmpty)
                                    Text(product.marque.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF6D28D9), letterSpacing: 1)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFFF5F0FF), borderRadius: BorderRadius.circular(20)),
                                    child: Text(product.categorie, style: const TextStyle(fontSize: 11, color: Color(0xFF9C4DC8), fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(product.nom, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF222222), height: 1.2)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (product.promo && product.prixPromo != null) ...[
                                    Text('${product.prixActuel} DT', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Colors.red)),
                                    const SizedBox(width: 10),
                                    Text('${product.prix} DT', style: TextStyle(fontSize: 14, color: Colors.grey.shade400, decoration: TextDecoration.lineThrough)),
                                  ] else
                                    Text('${product.prixActuel} DT', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Color(0xFF6D28D9))),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (product.stock != null)
                                Text(
                                  product.stock! > 10
                                      ? '✓ En stock'
                                      : product.stock! > 0
                                          ? '⚠ Plus que ${product.stock} en stock'
                                          : '✗ Rupture de stock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: product.stock! > 10
                                        ? Colors.green.shade600
                                        : product.stock! > 0
                                            ? Colors.orange.shade600
                                            : Colors.red.shade600,
                                  ),
                                ),
                              const Divider(height: 24, color: Color(0xFFEDE0F5)),
                              if (product.couleurs.isNotEmpty) ...[
                                const Text('Couleur', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF222222))),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  children: product.couleurs.map((c) {
                                    final isSelected = selectedCouleur == c['nom'];
                                    return GestureDetector(
                                      onTap: () => setModalState(() => selectedCouleur = c['nom'] as String?),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Color(int.parse((c['hex'] as String).replaceAll('#', '0xFF'))),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF6D28D9) : Colors.grey.shade300,
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: isSelected
                                              ? [BoxShadow(color: const Color(0xFF6D28D9).withValues(alpha: 0.3), blurRadius: 6)]
                                              : null,
                                        ),
                                        child: isSelected
                                            ? Icon(Icons.check, size: 16, color: c['hex'] == '#FFFFFF' || c['hex'] == '#F5F5DC' ? Colors.black : Colors.white)
                                            : null,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const Divider(height: 24, color: Color(0xFFEDE0F5)),
                              ],
                              if (product.tailles.isNotEmpty) ...[
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Taille', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF222222))),
                                    Text('Guide des tailles', style: TextStyle(fontSize: 11, color: Color(0xFF9C4DC8), decoration: TextDecoration.underline)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: product.tailles.map((t) {
                                    final isSelected = selectedTaille == t.toString();
                                    return GestureDetector(
                                      onTap: () => setModalState(() => selectedTaille = t.toString()),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF6D28D9) : Colors.white,
                                          border: Border.all(color: isSelected ? const Color(0xFF6D28D9) : const Color(0xFFE1D0F0)),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(t.toString(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF7B52A8))),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const Divider(height: 24, color: Color(0xFFEDE0F5)),
                              ],
                              if (product.description.isNotEmpty) ...[
                                const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF222222))),
                                const SizedBox(height: 8),
                                Text(product.description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.6)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Builder(builder: (ctx2) {
                    final outOfStock = product.stock != null && product.stock! <= 0;
                    return GestureDetector(
                      onTap: outOfStock ? null : () {
                        if (product.tailles.isNotEmpty && selectedTaille == null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('Veuillez choisir une taille'),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ));
                          return;
                        }
                        if (product.couleurs.isNotEmpty && selectedCouleur == null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('Veuillez choisir une couleur'),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ));
                          return;
                        }
                        Navigator.pop(ctx);
                        cubit.addToCart(product, taille: selectedTaille ?? '', couleur: selectedCouleur ?? '');
                      },
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: outOfStock
                              ? null
                              : const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)]),
                          color: outOfStock ? Colors.red.shade100 : null,
                          borderRadius: BorderRadius.circular(16),
                          border: outOfStock ? Border.all(color: Colors.red.shade300) : null,
                        ),
                        child: Center(
                          child: outOfStock
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.remove_shopping_cart_outlined, size: 18, color: Colors.red.shade700),
                                    const SizedBox(width: 8),
                                    Text('Stock épuisé', style: TextStyle(color: Colors.red.shade700, fontSize: 15, fontWeight: FontWeight.w600)),
                                  ],
                                )
                              : const Text('Ajouter au panier', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
