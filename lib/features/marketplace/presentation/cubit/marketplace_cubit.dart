import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/marketplace_repository.dart';
import 'marketplace_state.dart';

class MarketplaceCubit extends Cubit<MarketplaceState> {
  final MarketplaceRepository _repository;
  StreamSubscription? _productsSub;
  StreamSubscription? _cartSub;
  StreamSubscription? _favoritesSub;

  MarketplaceCubit(this._repository) : super(const MarketplaceState());

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // ✅ Annuler tous les streams avant déconnexion
  void cancelStreams() {
    _productsSub?.cancel();
    _cartSub?.cancel();
    _favoritesSub?.cancel();
    _productsSub = null;
    _cartSub = null;
    _favoritesSub = null;
  }

  void loadData() {
    emit(state.copyWith(isLoading: true));
    _productsSub?.cancel();
    _cartSub?.cancel();
    _favoritesSub?.cancel();

    _productsSub = _repository.watchProducts().listen(
          (products) =>
              emit(state.copyWith(products: products, isLoading: false)),
          onError: (e) => emit(
              state.copyWith(isLoading: false, errorMessage: e.toString())),
        );

    final uid = _userId;
    if (uid != null) {
      _cartSub = _repository
          .watchCartItems(uid)
          .listen((items) => emit(state.copyWith(cartItems: items)));

      _favoritesSub = _repository
          .watchFavorites(uid)
          .listen((ids) => emit(state.copyWith(favoriteIds: ids.toSet())));
    }
  }

  void selectCategory(String category) =>
      emit(state.copyWith(selectedCategory: category));

  void search(String query) =>
      emit(state.copyWith(searchQuery: query.toLowerCase()));

  void togglePromoOnly() =>
      emit(state.copyWith(showPromoOnly: !state.showPromoOnly));

  void toggleNewOnly() => emit(state.copyWith(showNewOnly: !state.showNewOnly));

  Future<void> toggleFavorite(String productId) async {
    final uid = _userId;
    if (uid == null) return;
    await _repository.toggleFavorite(uid, productId);
  }

  Future<void> addToCart(ProductEntity product,
      {String taille = '', String couleur = ''}) async {
    final uid = _userId;
    if (uid == null) return;
    emit(state.copyWith(isActionLoading: true, clearError: true));
    final result = await _repository.addToCart(
        userId: uid, product: product, taille: taille, couleur: couleur);
    result.fold(
      (f) =>
          emit(state.copyWith(isActionLoading: false, errorMessage: f.message)),
      (_) => emit(state.copyWith(
          isActionLoading: false, successMessage: 'Ajouté au panier !')),
    );
  }

  Future<void> removeFromCart(String itemId) async {
    final uid = _userId;
    if (uid == null) return;
    final result =
        await _repository.removeFromCart(userId: uid, itemId: itemId);
    result.fold(
      (f) => emit(state.copyWith(errorMessage: f.message)),
      (_) => emit(state.copyWith(successMessage: 'Article retiré du panier')),
    );
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    final uid = _userId;
    if (uid == null) return;
    if (quantity <= 0) {
      await removeFromCart(itemId);
      return;
    }
    await _repository.updateCartQuantity(
        userId: uid, itemId: itemId, quantity: quantity);
  }

  Future<void> checkout({
    required String nom,
    required String adresse,
    required String telephone,
    required String methodePaiement,
  }) async {
    final uid = _userId;
    if (uid == null) return;
    emit(state.copyWith(isActionLoading: true, clearError: true));

    final user = FirebaseAuth.instance.currentUser;
    final result = await _repository.checkout(
      userId: uid,
      userEmail: user?.email ?? '',
      nom: nom,
      adresse: adresse,
      telephone: telephone,
      methodePaiement: methodePaiement,
      cartItems: state.cartItems,
      total: state.cartTotal,
    );
    result.fold(
      (f) =>
          emit(state.copyWith(isActionLoading: false, errorMessage: f.message)),
      (orderNumber) => emit(state.copyWith(
        isActionLoading: false,
        checkoutSuccess: true,
        lastOrderNumber: orderNumber,
        lastPaymentMethod: methodePaiement,
      )),
    );
  }

  void resetCheckout() =>
      emit(state.copyWith(checkoutSuccess: false, clearSuccess: true));

  void clearMessages() =>
      emit(state.copyWith(clearError: true, clearSuccess: true));

  @override
  Future<void> close() {
    cancelStreams();
    return super.close();
  }
}
