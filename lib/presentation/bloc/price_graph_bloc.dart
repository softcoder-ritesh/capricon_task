import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/repository/stock_repository.dart';

part 'price_graph_event.dart';
part 'price_graph_state.dart';

class PriceGraphBloc extends Bloc<PriceGraphEvent, PriceGraphState> {
  final StockRepository stockRepository;

  PriceGraphBloc(this.stockRepository) : super(PriceGraphInitial()) {
    on<FetchPriceGraphEvent>((event, emit) async {
      emit(PriceGraphLoading());
      try {
        final data = await stockRepository.getStockPriceGraph(event.stockId, event.range);
        print(data);
        emit(PriceGraphLoaded(data));
      } catch (e) {
        emit(PriceGraphError("Failed to fetch price graph data: ${e.toString()}"));
      }
    });
  }
}
