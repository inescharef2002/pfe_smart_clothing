import 'package:dartz/dartz.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GoogleSignInUseCase {
  final AuthRepository _repository;
  GoogleSignInUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call() => _repository.signInWithGoogle();
}
