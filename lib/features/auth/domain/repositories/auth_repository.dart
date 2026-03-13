import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> loginWithGoogle();
  Future<UserEntity> loginWithApple();
  Future<void> logout();
  UserEntity? getCurrentUser();
}
