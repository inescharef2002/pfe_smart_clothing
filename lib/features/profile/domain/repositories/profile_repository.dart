import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getProfile(String userId);
  Future<Either<Failure, Unit>> updateProfile({
    required String userId,
    required ProfileEntity profile,
    XFile? imageFile,
  });
  Future<Either<Failure, String>> uploadPhoto(String userId, XFile imageFile);
  Stream<List<Map<String, dynamic>>> watchOrders(String userId);
  Stream<int> watchWardrobeCount(String userId);
  Stream<int> watchCartCount(String userId);
  Stream<int> watchOrdersCount(String userId);
}
