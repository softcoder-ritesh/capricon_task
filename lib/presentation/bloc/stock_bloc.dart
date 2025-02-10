import 'package:bloc/bloc.dart';
import '../../core/repository/stock_repository.dart';

part 'stock_event.dart';
part 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final StockRepository stockRepository;

  StockBloc(this.stockRepository) : super(StockInitial()) {
    on<LoadInitialStocksEvent>((event, emit) async {
      emit(StockLoading());
      try {
        final stocks = await stockRepository.getInitialStocks();
        print(stocks);
        emit(StockLoaded(stocks));
      } catch (e) {
        emit(StockError("Failed to load stocks"));
      }
    });

    on<SearchStockEvent>((event, emit) async {
      emit(StockLoading());
      try {
        final stocks = await stockRepository.searchStocks(event.query);
        print(stocks);
        emit(StockLoaded(stocks));
      } catch (e) {
        emit(StockError("Failed to fetch stocks"));
      }
    });
  }
}
