import 'package:dartz/dartz.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import '../entities/cart_item_entity.dart';
import '../entities/product_entity.dart';

abstract class MarketplaceRepository {
  Stream<List<ProductEntity>> watchProducts({String? category});
  Stream<List<CartItemEntity>> watchCartItems(String userId);
  Stream<List<String>> watchFavorites(String userId);
  Future<Either<Failure, Unit>> toggleFavorite(String userId, String productId);
  Future<Either<Failure, Unit>> addToCart({
    required String userId,
    required ProductEntity product,
    required String taille,
    required String couleur,
  });
  Future<Either<Failure, Unit>> updateCartQuantity({
    required String userId,
    required String itemId,
    required int quantity,
  });
  Future<Either<Failure, Unit>> removeFromCart({
    required String userId,
    required String itemId,
  });
  Future<Either<Failure, String>> checkout({
    required String userId,
    required String userEmail,
    required String nom,
    required String adresse,
    required String telephone,
    required String methodePaiement,
    required List<CartItemEntity> cartItems,
    required double total,
  });
}
