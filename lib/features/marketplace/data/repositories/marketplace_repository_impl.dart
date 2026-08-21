import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../datasources/marketplace_remote_datasource.dart';
import '../models/cart_item_model.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceDataSource _dataSource;

  MarketplaceRepositoryImpl(this._dataSource);

  @override
  Stream<List<ProductEntity>> watchProducts({String? category}) =>
      _dataSource.watchProducts(category: category);

  @override
  Stream<List<CartItemEntity>> watchCartItems(String userId) =>
      _dataSource.watchCartItems(userId);

  @override
  Stream<List<String>> watchFavorites(String userId) =>
      _dataSource.watchFavorites(userId);

  @override
  Future<Either<Failure, Unit>> toggleFavorite(
      String userId, String productId) async {
    try {
      await _dataSource.toggleFavorite(userId, productId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addToCart({
    required String userId,
    required ProductEntity product,
    required String taille,
    required String couleur,
  }) async {
    try {
      await _dataSource.addToCart(
          userId, CartItemModel.fromProduct(product: product, taille: taille, couleur: couleur));
      return const Right(unit);
    } on SocketException {
      return const Left(NetworkFailure('Pas de connexion internet'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateCartQuantity({
    required String userId,
    required String itemId,
    required int quantity,
  }) async {
    try {
      await _dataSource.updateCartQuantity(userId, itemId, quantity);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeFromCart({
    required String userId,
    required String itemId,
  }) async {
    try {
      await _dataSource.removeFromCart(userId, itemId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> checkout({
    required String userId,
    required String userEmail,
    required String nom,
    required String adresse,
    required String telephone,
    required String methodePaiement,
    required List<CartItemEntity> cartItems,
    required double total,
  }) async {
    try {
      final models = cartItems
          .map((i) => CartItemModel(
                id: i.id,
                articleId: i.articleId,
                nom: i.nom,
                prix: i.prix,
                imageUrl: i.imageUrl,
                quantity: i.quantity,
                taille: i.taille,
                couleur: i.couleur,
                marque: i.marque,
                categorie: i.categorie,
              ))
          .toList();
      final orderNumber = await _dataSource.checkout(
        userId: userId,
        userEmail: userEmail,
        nom: nom,
        adresse: adresse,
        telephone: telephone,
        methodePaiement: methodePaiement,
        cartItems: models,
        total: total,
      );
      return Right(orderNumber);
    } on SocketException {
      return const Left(NetworkFailure('Pas de connexion internet'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
