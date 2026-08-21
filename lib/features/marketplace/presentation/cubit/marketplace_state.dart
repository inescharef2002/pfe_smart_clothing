import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/product_entity.dart';

class MarketplaceState extends Equatable {
  final List<ProductEntity> products;
  final List<CartItemEntity> cartItems;
  final Set<String> favoriteIds;
  final bool isLoading;
  final bool isActionLoading;
  final bool checkoutSuccess;
  final String selectedCategory;
  final String searchQuery;
  final bool showPromoOnly;
  final bool showNewOnly;
  final String? lastOrderNumber;
  final String? lastPaymentMethod;
  final String? errorMessage;
  final String? successMessage;

  const MarketplaceState({
    this.products = const [],
    this.cartItems = const [],
    this.favoriteIds = const {},
    this.isLoading = false,
    this.isActionLoading = false,
    this.checkoutSuccess = false,
    this.selectedCategory = 'Tous',
    this.searchQuery = '',
    this.showPromoOnly = false,
    this.showNewOnly = false,
    this.lastOrderNumber,
    this.lastPaymentMethod,
    this.errorMessage,
    this.successMessage,
  });

  bool get hasActiveFilters => showPromoOnly || showNewOnly;

  List<ProductEntity> get filteredProducts {
    var list = products;
    if (selectedCategory != 'Tous') {
      list = list.where((p) => p.categorie == selectedCategory).toList();
    }
    if (searchQuery.isNotEmpty) {
      list = list
          .where((p) =>
              p.nom.toLowerCase().contains(searchQuery) ||
              p.marque.toLowerCase().contains(searchQuery))
          .toList();
    }
    if (showPromoOnly) list = list.where((p) => p.promo).toList();
    if (showNewOnly) list = list.where((p) => p.nouveaute).toList();
    return list;
  }

  int get cartItemsCount =>
      cartItems.fold(0, (sum, i) => sum + i.quantity);

  double get cartTotal =>
      cartItems.fold(0.0, (sum, i) => sum + i.total);

  bool isFavorite(String productId) => favoriteIds.contains(productId);

  MarketplaceState copyWith({
    List<ProductEntity>? products,
    List<CartItemEntity>? cartItems,
    Set<String>? favoriteIds,
    bool? isLoading,
    bool? isActionLoading,
    bool? checkoutSuccess,
    String? selectedCategory,
    String? searchQuery,
    bool? showPromoOnly,
    bool? showNewOnly,
    String? lastOrderNumber,
    String? lastPaymentMethod,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return MarketplaceState(
      products: products ?? this.products,
      cartItems: cartItems ?? this.cartItems,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      checkoutSuccess: checkoutSuccess ?? this.checkoutSuccess,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      showPromoOnly: showPromoOnly ?? this.showPromoOnly,
      showNewOnly: showNewOnly ?? this.showNewOnly,
      lastOrderNumber: lastOrderNumber ?? this.lastOrderNumber,
      lastPaymentMethod: lastPaymentMethod ?? this.lastPaymentMethod,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        products, cartItems, favoriteIds, isLoading, isActionLoading,
        checkoutSuccess, selectedCategory, searchQuery, showPromoOnly,
        showNewOnly, lastOrderNumber, lastPaymentMethod, errorMessage, successMessage,
      ];
}
