import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/transaction/transaction_cubit.dart';
import '../../blocs/transaction/transaction_state.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/category/category_cubit.dart';
import '../../data/models/transaction.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_list.dart';
import '../widgets/add_transaction_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // Центральная вкладка (домашний экран) выбрана по умолчанию
  DateTime _selectedMonth = DateTime.now();

  void _onItemTapped(int index) async {
    if (index == 0) {
      Navigator.pushNamed(context, '/statistics');
      return;
    }
    if (index == 2) {
      await Navigator.pushNamed(context, '/settings');
      context.read<TransactionCubit>().loadTransactions();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                });
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                });
              },
            ),
          ],
        ),
      ),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TransactionLoaded) {
            final transactions = state.transactions.where((t) {
              final date = DateTime.parse(t.date);
              return date.year == _selectedMonth.year && date.month == _selectedMonth.month;
            }).toList();
            // Доходы (type == 0)
            final income = transactions
                .where((t) => t.type == 0)
                .fold<double>(0, (sum, t) => sum + t.amount);
            // Расходы (type == 1)
            final expense = transactions
                .where((t) => t.type == 1)
                .fold<double>(0, (sum, t) => sum + t.amount);
            // Вычисляем баланс
            final balance = income - expense;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final balanceColor = isDark ? Colors.white : Colors.black;
            final balanceStr = balance < 0 ? '-${balance.abs().toStringAsFixed(0)} ₽' : '${balance.abs().toStringAsFixed(0)} ₽';
            return RefreshIndicator(
              onRefresh: () async => context.read<TransactionCubit>().loadTransactions(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Builder(
                    builder: (context) {
                      final authState = context.read<AuthCubit>().state;
                      if (authState is AuthSuccess) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Здравствуйте, ${authState.user.username}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: BalanceCard(
                          title: 'Доходы',
                          value: income,
                          icon: Icons.account_balance,
                          valueColor: Colors.green,
                          label: 'Доходы',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BalanceCard(
                          title: 'Баланс',
                          value: balance,
                          icon: Icons.account_balance_wallet,
                          valueColor: balanceColor,
                          label: 'Баланс',
                          showMinus: false,
                          customValue: balanceStr,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BalanceCard(
                          title: 'Расходы',
                          value: expense,
                          icon: Icons.money_off,
                          valueColor: Colors.red,
                          label: 'Расходы',
                          showMinus: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Последние операции', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TransactionList(transactions: transactions.take(10).toList()),
                  // Добавляем отступ снизу для плавающей кнопки
                  const SizedBox(height: 80),
                ],
              ),
            );
          }
          if (state is TransactionFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<TransactionCubit>().loadTransactions(),
                    child: const Text('Попробовать снова'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Нет данных'));
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton(
          onPressed: () async {
            final transactionCubit = context.read<TransactionCubit>();
            final categoryCubit = context.read<CategoryCubit>();
            final result = await showDialog(
              context: context,
              builder: (dialogContext) => MultiBlocProvider(
                providers: [
                  BlocProvider<TransactionCubit>.value(value: transactionCubit),
                  BlocProvider<CategoryCubit>.value(value: categoryCubit),
                ],
                child: const AddTransactionDialog(), // Pass the editingTransaction if needed
              ),
            );
            if (result == true) {
              context.read<TransactionCubit>().loadTransactions();
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Статистика',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];
    return months[month - 1];
  }
}