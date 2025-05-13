import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/transaction.dart';
import '../../blocs/transaction/transaction_cubit.dart';
import '../../blocs/auth/auth_cubit.dart';
import 'add_transaction_dialog.dart';

class TransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;

  const TransactionList({
    Key? key,
    required this.transactions,
  }) : super(key: key);

  IconData getCategoryIcon(String category, int type) {
    // Доходы
    if (type == 0) {
      switch (category) {
        case 'Зарплата':
          return Icons.attach_money;
        case 'Подработка':
          return Icons.work;
        case 'Инвестиции':
          return Icons.trending_up;
        default:
          return Icons.add_circle;
      }
    }
    // Расходы
    switch (category) {
      case 'Еда':
        return Icons.restaurant;
      case 'Транспорт':
        return Icons.directions_car;
      case 'Жилье':
        return Icons.home;
      case 'Здоровье':
        return Icons.local_hospital;
      case 'Развлечения':
        return Icons.movie;
      case 'Одежда и аксессуары':
        return Icons.checkroom;
      case 'Образование':
        return Icons.school;
      case 'Подарки':
        return Icons.card_giftcard;
      case 'Путешествия':
        return Icons.flight;
      default:
        return Icons.remove_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(child: Text('Нет транзакций'));
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 2,
    );

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final date = DateTime.parse(transaction.date);
        final formattedDate = DateFormat.yMMMd('ru').format(date);
        final amount = currencyFormat.format(transaction.amount);
        final isExpense = transaction.type == 1;

        return Dismissible(
          key: Key(transaction.id.toString()),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Подтверждение'),
                content: const Text('Вы уверены, что хотите удалить эту транзакцию?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Удалить'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            context.read<TransactionCubit>().deleteTransaction(transaction.id!);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Транзакция удалена')),
            );
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isExpense
                  ? Colors.red.withOpacity(0.8)
                  : Colors.green.withOpacity(0.8),
              child: Icon(
                getCategoryIcon(transaction.category, transaction.type),
                color: Colors.white,
              ),
            ),
            title: Text(transaction.category),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formattedDate),
                if (transaction.description != null && transaction.description!.isNotEmpty)
                  Text(
                    transaction.description!,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (isExpense ? '-' : '+') + amount,
                  style: TextStyle(
                    color: isExpense ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoMono',
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () async {
                    final transactionCubit = context.read<TransactionCubit>();
                    final result = await showDialog(
                      context: context,
                      builder: (dialogContext) => MultiBlocProvider(
                        providers: [
                          BlocProvider<TransactionCubit>.value(
                            value: transactionCubit,
                          ),
                          BlocProvider<AuthCubit>.value(
                            value: context.read<AuthCubit>(),
                          ),
                        ],
                        child: AddTransactionDialog(
                          editingTransaction: transaction,
                        ),
                      ),
                    );
                    if (result == true) {
                      transactionCubit.loadTransactions();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}