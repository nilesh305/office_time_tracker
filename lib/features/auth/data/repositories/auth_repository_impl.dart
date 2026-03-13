import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  Future<UserEntity> loginWithGoogle() async {
    final credential = await _datasource.signInWithGoogle();
    return _mapCredentialToUserEntity(credential);
  }

  @override
  Future<UserEntity> loginWithApple() async {
    final credential = await _datasource.signInWithApple();
    return _mapCredentialToUserEntity(credential);
  }

  @override
  Future<void> logout() async {
    await _datasource.signOut();
  }

  @override
  UserEntity? getCurrentUser() {
    final user = _datasource.getCurrentUser();
    if (user != null) {
      return UserEntity(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        photoUrl: user.photoURL ?? '',
      );
    }
    return null;
  }

  UserEntity _mapCredentialToUserEntity(UserCredential credential) {
    final user = credential.user;
    if (user == null) {
      throw Exception('Authentication failed: missing user');
    }
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
    );
  }
}
