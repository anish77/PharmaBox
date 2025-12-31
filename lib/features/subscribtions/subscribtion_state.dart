abstract class SubscribtionState {}

class SubscribtionInitial extends SubscribtionState {}

class SubscribtionLoading extends SubscribtionState {}

class SubscribtionLoaded extends SubscribtionState {
  final bool isPro;
  SubscribtionLoaded(this.isPro);
}

class SubscribtionError extends SubscribtionState {
  final String message;
  SubscribtionError(this.message);
}
