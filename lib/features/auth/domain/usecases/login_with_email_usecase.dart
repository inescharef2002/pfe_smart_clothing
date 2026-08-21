import 'package:dartz/dartz.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import 'package:pfe_smart_clothing/features/auth/domain/entities/user_entity.dart';
import 'package:pfe_smart_clothing/features/auth/domain/repositories/auth_repository.dart';

class LoginWithEmailUseCase {
  final AuthRepository repository;

  LoginWithEmailUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
  }) async {
    return await repository.loginWithEmail(
      email: email,
      password: password,
    );
  }
}
