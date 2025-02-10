part of 'stock_bloc.dart';

abstract class StockEvent {
  @override
  List<Object> get props => [];
}

class LoadInitialStocksEvent extends StockEvent {}

class SearchStockEvent extends StockEvent {
  final String query;
  SearchStockEvent(this.query);

  @override
  List<Object> get props => [query];
}
