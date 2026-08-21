import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;
  UpdateProfileUseCase(this.repository);

  Future<Either<Failure, Unit>> call({
    required String userId,
    required ProfileEntity profile,
    XFile? imageFile,
  }) =>
      repository.updateProfile(userId: userId, profile: profile, imageFile: imageFile);
}
