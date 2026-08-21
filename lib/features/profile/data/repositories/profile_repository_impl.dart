import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource _dataSource;

  ProfileRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, ProfileEntity>> getProfile(String userId) async {
    try {
      return Right(await _dataSource.getProfile(userId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProfile({
    required String userId,
    required ProfileEntity profile,
    XFile? imageFile,
  }) async {
    try {
      await _dataSource.updateProfile(
        userId,
        ProfileModel.fromEntity(profile),
        imageFile: imageFile,
      );
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadPhoto(String userId, XFile imageFile) async {
    try {
      final url = await _dataSource.uploadPhoto(userId, imageFile);
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchOrders(String userId) =>
      _dataSource.watchOrders(userId);

  @override
  Stream<int> watchWardrobeCount(String userId) =>
      _dataSource.watchWardrobeCount(userId);

  @override
  Stream<int> watchCartCount(String userId) =>
      _dataSource.watchCartCount(userId);

  @override
  Stream<int> watchOrdersCount(String userId) =>
      _dataSource.watchOrdersCount(userId);
}
