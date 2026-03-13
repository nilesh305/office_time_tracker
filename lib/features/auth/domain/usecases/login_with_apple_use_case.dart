import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginWithAppleUseCase {
  final AuthRepository repository;

  LoginWithAppleUseCase(this.repository);

  Future<UserEntity> call() async {
    return await repository.loginWithApple();
  }
}
