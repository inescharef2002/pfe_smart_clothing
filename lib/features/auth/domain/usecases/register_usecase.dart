import 'package:dartz/dartz.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import 'package:pfe_smart_clothing/features/auth/domain/entities/user_entity.dart';
import 'package:pfe_smart_clothing/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    required String name,
  }) async {
    return await repository.registerWithEmail(
      email: email,
      password: password,
      name: name,
    );
  }
}