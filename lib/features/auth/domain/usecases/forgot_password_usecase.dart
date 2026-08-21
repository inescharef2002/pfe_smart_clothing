import 'package:dartz/dartz.dart';
import 'package:pfe_smart_clothing/core/error/failures.dart';
import 'package:pfe_smart_clothing/features/auth/domain/repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call({required String email}) async {
    return await repository.forgotPassword(email: email);
  }
}
