part of 'price_graph_bloc.dart';

abstract class PriceGraphState {
  const PriceGraphState();
  @override
  List<Object> get props => [];
}

class PriceGraphInitial extends PriceGraphState {}

class PriceGraphLoading extends PriceGraphState {}

class PriceGraphLoaded extends PriceGraphState {
  final List<dynamic> data;
  const PriceGraphLoaded(this.data);

  @override
  List<Object> get props => [data];
}

class PriceGraphError extends PriceGraphState {
  final String message;
  const PriceGraphError(this.message);

  @override
  List<Object> get props => [message];
}
