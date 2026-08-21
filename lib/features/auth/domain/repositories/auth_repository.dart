import 'package:dartz/dartz.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import 'package:pfe_smart_clothing/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<Failure, void>> forgotPassword({required String email});

  Future<Either<Failure, void>> logout();
  Future<UserEntity?> getCurrentUser();
  Future<Either<Failure, UserEntity>> signInWithGoogle();
}
