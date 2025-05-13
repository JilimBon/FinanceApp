import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final UserRepository userRepository;
  UserModel? _user;
  static const String _savedUsernameKey = 'saved_username';
  static const String _rememberMeKey = 'remember_me';

  AuthCubit(this.userRepository) : super(AuthInitial()) {
    _checkSavedCredentials();
  }

  UserModel? get user => _user;

  Future<void> _checkSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final savedUsername = prefs.getString(_savedUsernameKey);
    if (rememberMe && savedUsername != null) {
      // Автоматически логиним пользователя
      final user = await userRepository.getUserByUsername(savedUsername);
      if (user != null) {
        _user = user;
        emit(AuthSuccess(user));
        return;
      }
    }
    if (savedUsername != null) {
      emit(AuthSavedUsername(savedUsername));
    }
  }

  Future<void> _saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedUsernameKey, username);
  }

  Future<void> _clearSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedUsernameKey);
  }

  Future<void> clearSavedUsername() async {
    await _clearSavedUsername();
    emit(AuthInitial());
  }

  Future<void> login(String username, String password, {bool rememberMe = false}) async {
    emit(AuthLoading());
    final user = await userRepository.getUserByUsername(username);
    if (user != null && userRepository.verifyPassword(password, user.passwordHash)) {
      _user = user;
      await _saveUsername(username);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, rememberMe);
      emit(AuthSuccess(user));
    } else {
      emit(AuthFailure('Неверный логин или пароль'));
    }
  }

  Future<void> register(String username, String password, {bool rememberMe = false}) async {
    emit(AuthLoading());
    final exists = await userRepository.getUserByUsername(username) != null;
    if (exists) {
      emit(AuthFailure('Пользователь уже существует'));
      return;
    }
    final user = await userRepository.createUser(username, password);
    _user = user;
    await _saveUsername(username);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe);
    emit(AuthSuccess(user));
  }

  void logout() async {
    _user = null;
    _clearSavedUsername();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, false);
    emit(AuthInitial());
  }
}