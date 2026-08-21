import 'package:dartz/dartz.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await remoteDataSource.loginWithEmail(email, password);
      return Right(userModel);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userModel =
          await remoteDataSource.registerWithEmail(email, password, name);
      return Right(userModel);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async {
    try {
      await remoteDataSource.forgotPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      return await remoteDataSource.getCurrentUser();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final userModel = await remoteDataSource.signInWithGoogle();
      return Right(userModel);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
