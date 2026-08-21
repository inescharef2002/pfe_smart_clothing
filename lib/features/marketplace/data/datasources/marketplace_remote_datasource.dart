import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

abstract class MarketplaceDataSource {
  Stream<List<ProductModel>> watchProducts({String? category});
  Stream<List<CartItemModel>> watchCartItems(String userId);
  Stream<List<String>> watchFavorites(String userId);
  Future<void> addToCart(String userId, CartItemModel item);
  Future<void> updateCartQuantity(String userId, String itemId, int quantity);
  Future<void> removeFromCart(String userId, String itemId);
  Future<void> toggleFavorite(String userId, String productId);
  Future<String> checkout({
    required String userId,
    required String userEmail,
    required String nom,
    required String adresse,
    required String telephone,
    required String methodePaiement,
    required List<CartItemModel> cartItems,
    required double total,
  });
}

class MarketplaceRemoteDataSource implements MarketplaceDataSource {
  final FirebaseFirestore _firestore;

  MarketplaceRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference _cartRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('cart');

  CollectionReference _favRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('favorites');

  @override
  Stream<List<String>> watchFavorites(String userId) =>
      _favRef(userId).snapshots().map((s) => s.docs.map((d) => d.id).toList());

  @override
  Future<void> toggleFavorite(String userId, String productId) async {
    final ref = _favRef(userId).doc(productId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({'addedAt': FieldValue.serverTimestamp()});
    }
  }

  @override
  Stream<List<ProductModel>> watchProducts({String? category}) {
    Query<Map<String, dynamic>> query = _firestore.collection('articles');
    if (category != null && category != 'Tous') {
      query = query.where('categorie', isEqualTo: category);
    }
    return query
        .snapshots()
        .map((snap) => snap.docs.map(ProductModel.fromFirestore).toList());
  }

  @override
  Stream<List<CartItemModel>> watchCartItems(String userId) {
    return _cartRef(userId)
        .snapshots()
        .map((snap) => snap.docs.map(CartItemModel.fromFirestore).toList());
  }

  @override
  Future<void> addToCart(String userId, CartItemModel item) async {
    final existing = await _cartRef(userId)
        .where('articleId', isEqualTo: item.articleId)
        .where('taille', isEqualTo: item.taille)
        .where('couleur', isEqualTo: item.couleur)
        .get();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final current =
          (doc.data() as Map<String, dynamic>)['quantity'] as int? ?? 0;
      await doc.reference.update({'quantity': current + 1});
    } else {
      await _cartRef(userId).add(item.toMap());
    }
  }

  @override
  Future<void> updateCartQuantity(
      String userId, String itemId, int quantity) async {
    await _cartRef(userId).doc(itemId).update({'quantity': quantity});
  }

  @override
  Future<void> removeFromCart(String userId, String itemId) async {
    await _cartRef(userId).doc(itemId).delete();
  }

  @override
  Future<String> checkout({
    required String userId,
    required String userEmail,
    required String nom,
    required String adresse,
    required String telephone,
    required String methodePaiement,
    required List<CartItemModel> cartItems,
    required double total,
  }) async {
    final orderNumber = _generateOrderNumber();

    // ── 1. Créer la commande ──────────────────────────────────────────
    final orderRef = _firestore.collection('commandes').doc();
    await orderRef.set({
      'userId': userId,
      'userEmail': userEmail,
      'userName': nom,
      'adresse': adresse,
      'telephone': telephone,
      'methodePaiement': methodePaiement,
      'articles': cartItems.map((i) => i.toMap()).toList(),
      'total': total,
      'statut': 'En attente',
      'numeroCommande': orderNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ── 2. Vider le panier ────────────────────────────────────────────
    // On vide article par article pour éviter la limite de 500 ops du batch
    for (final item in cartItems) {
      await _cartRef(userId).doc(item.id).delete();
    }

    // Note : la décrémentation du stock est gérée côté admin dashboard
    // quand il traite la commande (statut → Confirmée / Expédiée)

    return orderNumber;
  }

  String _generateOrderNumber() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'SCA-${ts.toString().substring(8)}-${(ts % 10000).toString().padLeft(4, '0')}';
  }
}
