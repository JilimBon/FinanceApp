import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/transaction/transaction_cubit.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();
      if (_isLogin) {
        context.read<AuthCubit>().login(username, password, rememberMe: _rememberMe);
      } else {
        context.read<AuthCubit>().register(username, password, rememberMe: _rememberMe);
      }
    }
  }

  void _clearSavedUsername() {
    setState(() {
      _usernameController.clear();
      _passwordController.clear();
      context.read<AuthCubit>().clearSavedUsername();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is AuthSuccess) {
            context.read<TransactionCubit>().setUserId(state.user.id!);
            Navigator.pushReplacementNamed(context, '/home');
          }
          if (state is AuthSavedUsername) {
            _usernameController.text = state.username;
            _isLogin = true; // При сохраненном логине всегда показываем форму входа
          }
        },
        builder: (context, state) {
          final hasSavedUsername = state is AuthSavedUsername;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLogin ? 'Вход' : 'Регистрация',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 32),
                    // Логин
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Логин',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите логин';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Пароль',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите пароль';
                        }
                        if (value.length < 6) {
                          return 'Минимум 6 символов';
                        }
                        return null;
                      },
                      autofocus: hasSavedUsername,
                    ),
                    if (_isLogin) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) => setState(() => _rememberMe = v ?? false),
                          ),
                          const Text('Запомнить меня'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (state is AuthLoading)
                      const CircularProgressIndicator()
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: Text(_isLogin ? 'Войти' : 'Зарегистрироваться'),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (hasSavedUsername) {
                            _clearSavedUsername();
                          } else {
                            setState(() {
                              _isLogin = !_isLogin;
                              _passwordController.clear();
                            });
                          }
                        },
                        child: Text(_isLogin
                            ? 'Нет аккаунта? Зарегистрироваться'
                            : 'Уже есть аккаунт? Войти'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}