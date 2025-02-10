import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/repository/stock_repository.dart';
import '../bloc/price_graph_bloc.dart';

class PriceGraphScreen extends StatefulWidget {
  final int stockId;
  final String stockName;
  final String symbol;
  final String createdAt;
  final String updatedAt;
  final String assetType;

  const PriceGraphScreen({
    Key? key,
    required this.stockId,
    required this.stockName,
    required this.symbol,
    required this.createdAt,
    required this.updatedAt,
    required this.assetType,
  }) : super(key: key);

  @override
  _PriceGraphScreenState createState() => _PriceGraphScreenState();
}

class _PriceGraphScreenState extends State<PriceGraphScreen> {
  // The currently selected range.
  String selectedRange = "1M"; // default range

  late PriceGraphBloc _priceGraphBloc;
  late TransformationController _transformationController;

  // Cache for the latest loaded data.
  List<dynamic>? cachedData;

  // Timeout flag & timer.
  bool _hasTimedOut = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _priceGraphBloc = PriceGraphBloc(StockRepository());
    _fetchGraphData();
    _startTimeoutTimer();
    _transformationController = TransformationController();
    // Lock vertical translation by resetting dy.
    _transformationController.addListener(() {
      Matrix4 current = _transformationController.value;
      if (current.storage[13] != 0) {
        current.storage[13] = 0;
        _transformationController.value = current;
      }
    });
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _hasTimedOut = false;
    _timeoutTimer = Timer(Duration(seconds: 5), () {
      if (mounted && _priceGraphBloc.state is PriceGraphLoading) {
        setState(() {
          _hasTimedOut = true;
        });
      }
    });
  }

  void _fetchGraphData() {
    _priceGraphBloc.add(
      FetchPriceGraphEvent(stockId: widget.stockId, range: selectedRange),
    );
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _priceGraphBloc.close();
    _transformationController.dispose();
    super.dispose();
  }

  // When a new range is selected, update state and fetch new data.
  void _onRangeSelected(String range) {
    if (range != selectedRange) {
      setState(() {
        selectedRange = range;
        _transformationController.value = Matrix4.identity();
      });
      _fetchGraphData();
    }
  }

  // Build a row of range selection buttons.
  Widget _buildRangeSelector() {
    final List<String> ranges = ["1D", "1W", "1M", "1Y", "5Y"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ranges.map((range) {
        bool isSelected = range == selectedRange;
        return GestureDetector(
          onTap: () => _onRangeSelected(range),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 6),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              range,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Choose date format based on the selected range.
  DateFormat _getDateFormat() {
    if (selectedRange == "1D" || selectedRange == "1W") {
      return DateFormat.Hm(); // e.g., "14:30"
    } else {
      return DateFormat("MM/dd"); // e.g., "04/21"
    }
  }

  // Build a fixed left Y-axis widget.
  Widget _buildYAxis(double minY, double maxY) {
    int labelCount = 5;
    double step = (maxY - minY) / (labelCount - 1);
    List<Widget> labels = [];
    for (int i = 0; i < labelCount; i++) {
      double value = minY + step * i;
      labels.add(Text(
        "\$${value.toStringAsFixed(0)}",
        style: TextStyle(fontSize: 10, color: Colors.grey),
      ));
    }
    labels = labels.reversed.toList();
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels,
    );
  }

  // Build additional stock details from the graph data.
  Widget _buildAdditionalDetails(List<dynamic> data) {
    double latestOpen = (data.last['OpenPrice'] as num).toDouble();
    double latestClose = (data.last['ClosePrice'] as num).toDouble();
    double oneYearHigh = data
        .map((point) => (point['HighPrice'] as num).toDouble())
        .reduce((a, b) => max(a, b));
    double oneYearLow = data
        .map((point) => (point['LowPrice'] as num).toDouble())
        .reduce((a, b) => min(a, b));

    return Card(
      elevation: 3,
      margin: EdgeInsets.only(top: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow("Latest Open Price", "\$${latestOpen.toStringAsFixed(2)}", Colors.blue),
            Divider(),
            _buildDetailRow("Latest Close Price", "\$${latestClose.toStringAsFixed(2)}", Colors.blue),
            Divider(),
            _buildDetailRow("1Y High", "\$${oneYearHigh.toStringAsFixed(2)}", Colors.green),
            Divider(),
            _buildDetailRow("1Y Low", "\$${oneYearLow.toStringAsFixed(2)}", Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(fontSize: 14, color: valueColor)),
      ],
    );
  }

  // Build an error widget with a refresh button.
  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchGraphData,
            icon: Icon(Icons.refresh),
            label: Text("Try Again"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap entire content in a SingleChildScrollView so the page is scrollable
    // if content overflows vertically.
    return BlocProvider<PriceGraphBloc>.value(
      value: _priceGraphBloc,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: AppBar(
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: Flexible(
              child: Text(
                widget.stockName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            // Extra bottom padding to prevent overflow.
            padding: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Stock details header.
                  BlocBuilder<PriceGraphBloc, PriceGraphState>(
                    builder: (context, state) {
                      String currentPrice = "";
                      Color trendColor = Colors.grey;
                      if (state is PriceGraphLoaded && state.data.isNotEmpty) {
                        double startPrice = (state.data.first['ClosePrice'] as num).toDouble();
                        double endPrice = (state.data.last['ClosePrice'] as num).toDouble();
                        currentPrice = "\$${endPrice.toStringAsFixed(2)}";
                        trendColor = endPrice >= startPrice ? Colors.green : Colors.red;
                      }
                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.stockName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                  ),
                                ),
                                Text(
                                  currentPrice,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: trendColor),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Symbol: ${widget.symbol}",
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                                Text(
                                  "Asset: ${widget.assetType}",
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Created: ${widget.createdAt}",
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                                Text(
                                  "Updated: ${widget.updatedAt}",
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  _buildRangeSelector(),
                  SizedBox(height: 20),
                  // Chart area: fixed height with InteractiveViewer.
                  SizedBox(
                    height: 300,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return BlocBuilder<PriceGraphBloc, PriceGraphState>(
                          builder: (context, state) {
                            // Use cached data if available.
                            List<dynamic>? dataToUse;
                            if (state is PriceGraphLoaded && state.data.isNotEmpty) {
                              dataToUse = state.data;
                              cachedData = state.data;
                            } else if (state is PriceGraphLoading && cachedData != null) {
                              dataToUse = cachedData;
                            } else if (state is PriceGraphError) {
                              return _buildErrorWidget("Something went wrong. Please try again.");
                            }

                            if (dataToUse == null || dataToUse.isEmpty) {
                              if (_hasTimedOut) {
                                return _buildErrorWidget("No chart data available for this stock.");
                              } else {
                                return Center(
                                  child: Text(
                                    "Loading Chart...",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                );
                              }
                            }

                            DateTime baseTime = DateTime.parse(dataToUse.first['Timestamp']);
                            final List<FlSpot> spots = [];
                            for (var point in dataToUse) {
                              if (point['ClosePrice'] != null && point['Timestamp'] != null) {
                                DateTime pointTime = DateTime.parse(point['Timestamp']);
                                double x = pointTime.difference(baseTime).inMinutes.toDouble();
                                double y = (point['ClosePrice'] as num).toDouble();
                                spots.add(FlSpot(x, y));
                              }
                            }
                            if (spots.isEmpty) {
                              return _buildErrorWidget("No chart data available for this stock.");
                            }
                            double minX = spots.first.x;
                            double maxX = spots.last.x;
                            double minY = spots.map((s) => s.y).reduce(min);
                            double maxY = spots.map((s) => s.y).reduce(max);
                            DateFormat dateFormat = _getDateFormat();

                            Widget chartContent = Container(
                              width: constraints.maxWidth,
                              height: 300,
                              child: LineChart(
                                LineChartData(
                                  minX: minX,
                                  maxX: maxX,
                                  minY: minY,
                                  maxY: maxY,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      color: spots.last.y >= spots.first.y ? Colors.green : Colors.red,
                                      barWidth: 2,
                                      dotData: FlDotData(show: false),
                                    ),
                                  ],
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    horizontalInterval: (maxY - minY) / 5,
                                    verticalInterval: (maxX - minX) / 6,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.withOpacity(0.3),
                                        strokeWidth: 1,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return FlLine(
                                        color: Colors.grey.withOpacity(0.3),
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          DateTime labelTime = baseTime.add(Duration(minutes: value.round()));
                                          return Text(
                                            dateFormat.format(labelTime),
                                            style: TextStyle(color: Colors.grey, fontSize: 10),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1),
                                  ),
                                ),
                              ),
                            );

                            Widget interactiveChart = InteractiveViewer(
                              transformationController: _transformationController,
                              constrained: true,
                              minScale: 1,
                              maxScale: 2,
                              panEnabled: true,
                              child: chartContent,
                            );

                            Widget yAxis = Container(
                              width: 40,
                              child: _buildYAxis(minY, maxY),
                            );

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                yAxis,
                                Expanded(child: interactiveChart),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Additional details section.
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: BlocBuilder<PriceGraphBloc, PriceGraphState>(
                      builder: (context, state) {
                        if (state is PriceGraphLoaded && state.data.isNotEmpty) {
                          return _buildAdditionalDetails(state.data);
                        }
                        return Container();
                      },
                    ),
                  ),
                  // Extra bottom spacing.
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
