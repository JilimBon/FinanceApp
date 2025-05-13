import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/transaction/transaction_cubit.dart';
import '../../blocs/auth/auth_cubit.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/category/category_cubit.dart';
import '../../blocs/category/category_state.dart';
import '../../data/models/transaction.dart';
import '../../data/models/category.dart';

class AddTransactionDialog extends StatefulWidget {
  final TransactionModel? editingTransaction;

  const AddTransactionDialog({
    Key? key,
    this.editingTransaction,
  }) : super(key: key);

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late int _type;
  late String _category;
  late DateTime _date;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final editingTx = widget.editingTransaction;
    _type = editingTx?.type ?? 1;
    _category = editingTx?.category ?? '';
    _date = editingTx != null ? DateTime.parse(editingTx.date) : DateTime.now();
    _amountController = TextEditingController(
      text: editingTx?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: editingTx?.description ?? '',
    );

    // Load categories for the initial type
    context.read<CategoryCubit>().loadCategories(_type);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Получаем список категорий в зависимости от типа
  List<DropdownMenuItem<String>> _getCategories(BuildContext context) {
    final categoryState = context.watch<CategoryCubit>().state;
    if (categoryState is CategoryLoaded) {
      return categoryState.categories.map((category) => DropdownMenuItem(
        value: category.name,
        child: Text(category.name),
      )).toList();
    }
    return [];
  }

  // Обновляем тип и категорию
  void _updateType(int newType) {
    setState(() {
      _type = newType;
      _category = ''; // Reset category when type changes
    });
    // Load categories for the new type
    context.read<CategoryCubit>().loadCategories(newType);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);

      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка авторизации')),
        );
        return;
      }

      final amount = double.parse(_amountController.text.replaceAll(',', '.'));

      final transaction = TransactionModel(
        id: widget.editingTransaction?.id,
        userId: authState.user.id!,
        amount: amount,
        type: _type,
        category: _category,
        date: _date.toIso8601String(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );

      if (widget.editingTransaction != null) {
        await context.read<TransactionCubit>().updateTransaction(transaction);
      } else {
        await context.read<TransactionCubit>().addTransaction(transaction);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editingTransaction != null
                ? 'Транзакция обновлена'
                : 'Транзакция добавлена'
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    if (widget.editingTransaction != null) {
      await context.read<TransactionCubit>().deleteTransaction(widget.editingTransaction!.id!);
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Транзакция удалена')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getCategories(context);

    return AlertDialog(
      title: Text(widget.editingTransaction != null ? 'Редактировать операцию' : 'Добавить операцию'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Сумма'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Введите сумму';
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Некорректная сумма';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _updateType(0),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: 0,
                          groupValue: _type,
                          onChanged: (v) => _updateType(v!),
                        ),
                        const Text('Доход'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  GestureDetector(
                    onTap: () => _updateType(1),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: 1,
                          groupValue: _type,
                          onChanged: (v) => _updateType(v!),
                        ),
                        const Text('Расход'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BlocBuilder<CategoryCubit, CategoryState>(
                builder: (context, state) {
                  if (state is CategoryLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CategoryLoaded && state.categories.isNotEmpty) {
                    if (_category.isEmpty && state.categories.isNotEmpty) {
                      _category = state.categories.first.name;
                    }
                    return DropdownButtonFormField<String>(
                      value: _category,
                      items: categories,
                      decoration: const InputDecoration(labelText: 'Категория'),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _category = value);
                        }
                      },
                    );
                  }
                  return const Text('Нет доступных категорий');
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text('Дата: ${DateFormat.yMMMd('ru_RU').format(_date)}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        locale: const Locale('ru', 'RU'),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Описание (необязательно)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        if (widget.editingTransaction != null) // Show delete button only when editing
          TextButton(
            onPressed: _delete,
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(widget.editingTransaction != null ? 'Сохранить' : 'Добавить'),
        ),
      ],
    );
  }
}