import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../../blocs/transaction/transaction_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Future<void> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (result == true) {
      context.read<AuthCubit>().logout();
      Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          String username = '';
          if (state is AuthSuccess) {
            username = state.user.username;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Пользователь'),
                subtitle: Text(username),
              ),
              const Divider(),
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  return SwitchListTile(
                    title: const Text('Тёмная тема'),
                    value: themeMode == ThemeMode.dark,
                    onChanged: (val) => context.read<ThemeCubit>().toggleTheme(),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Выйти'),
                onTap: () => _confirmLogout(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Сбросить всё'),
                subtitle: const Text('Удалить все операции и статистику'),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Очистить все данные?'),
                      content: const Text('Вы уверены, что хотите удалить все доходы, расходы и баланс? Это действие необратимо.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Отмена'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Удалить'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final authState = context.read<AuthCubit>().state;
                    if (authState is AuthSuccess) {
                      final transactionCubit = context.read<TransactionCubit>();
                      await transactionCubit.deleteAllTransactions();
                      await transactionCubit.loadTransactions();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Все операции удалены')),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}