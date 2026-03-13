import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_use_case.dart';
import '../../domain/usecases/login_with_apple_use_case.dart';
import '../../domain/usecases/login_with_google_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../viewmodels/auth_viewmodel.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final googleSignInProvider = Provider<GoogleSignIn>(
  (ref) => GoogleSignIn.instance,
);

final authDatasourceProvider = Provider<AuthDatasource>((ref) {
  return AuthDatasource(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authDatasourceProvider));
});

final loginWithGoogleUseCaseProvider = Provider<LoginWithGoogleUseCase>((ref) {
  return LoginWithGoogleUseCase(ref.watch(authRepositoryProvider));
});

final loginWithAppleUseCaseProvider = Provider<LoginWithAppleUseCase>((ref) {
  return LoginWithAppleUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(() {
  return AuthViewModel();
});
