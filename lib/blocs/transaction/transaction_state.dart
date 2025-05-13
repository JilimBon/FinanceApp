import '../../data/models/transaction.dart';

abstract class TransactionState {}

class TransactionInitial extends TransactionState {}
class TransactionLoading extends TransactionState {}
class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  TransactionLoaded(this.transactions);
}
class TransactionFailure extends TransactionState {
  final String message;
  TransactionFailure(this.message);
}