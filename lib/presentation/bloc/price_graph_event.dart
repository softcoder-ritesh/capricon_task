// part of 'price_graph_bloc.dart';
//
// abstract class PriceGraphEvent {
//   const PriceGraphEvent();
//   @override
//   List<Object> get props => [];
// }
//
// class FetchPriceGraphEvent extends PriceGraphEvent {
//   final int stockId;
//   final String range; // Allowed values: 1D, 1W, 1M, 1Y, 5Y
//   const FetchPriceGraphEvent({required this.stockId, required this.range});
//
//   @override
//   List<Object> get props => [stockId, range];
// }
part of 'price_graph_bloc.dart';

abstract class PriceGraphEvent{
  const PriceGraphEvent();
  @override
  List<Object> get props => [];
}

class FetchPriceGraphEvent extends PriceGraphEvent {
  final int stockId;
  final String range; // Allowed values: 1D, 1W, 1M, 1Y, 5Y

  const FetchPriceGraphEvent({required this.stockId, required this.range});

  @override
  List<Object> get props => [stockId, range];
}
