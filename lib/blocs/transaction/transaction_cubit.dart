import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/models/transaction.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository transactionRepository;
  int userId;

  TransactionCubit(this.transactionRepository, this.userId) : super(TransactionInitial());

  void setUserId(int newUserId) {
    userId = newUserId;
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    emit(TransactionLoading());
    try {
      final transactions = await transactionRepository.getTransactions(userId);
      emit(TransactionLoaded(transactions));
    } catch (e) {
      emit(TransactionFailure(e.toString()));
    }
  }

  Future<void> addTransaction(TransactionModel tx) async {
    try {
      await transactionRepository.addTransaction(tx);
      await loadTransactions();
    } catch (e) {
      emit(TransactionFailure(e.toString()));
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await transactionRepository.deleteTransaction(id);
      await loadTransactions();
    } catch (e) {
      emit(TransactionFailure(e.toString())); // Обработка ошибок
    }
  }

  Future<void> updateTransaction(TransactionModel tx) async {
    try {
      await transactionRepository.updateTransaction(tx);
      await loadTransactions();
    } catch (e) {
      emit(TransactionFailure(e.toString()));
    }
  }

  Future<void> deleteAllTransactions() async {
    try {
      await transactionRepository.deleteAllTransactions(userId);
      await loadTransactions();
    } catch (e) {
      emit(TransactionFailure(e.toString()));
    }
  }
}