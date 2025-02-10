import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/stock_bloc.dart';
import 'price_graph_screen.dart'; // Screen to show the price graph

class StockSearchScreen extends StatefulWidget {
  @override
  _StockSearchScreenState createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Quick search keywords.
  final List<String> _keywords = [
    "Microsoft",
    "Nestle",
    "Audi",
    "Tesla",
    "Amazon",
    "ITC",
    "Google",
    "Facebook",
    "Apple",
    "Netflix",
    "Intel",
    "Cisco",
    "Oracle",
    "HP"
  ];

  // Debounce timer for search input.
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        BlocProvider.of<StockBloc>(context)
            .add(SearchStockEvent(query.trim()));
      } else {
        setState(() {}); // Refresh UI when cleared.
      }
    });
  }

  /// Build a keyword chip.
  Widget _buildKeywordChip(String keyword) {
    return ActionChip(
      label: Text(keyword, style: TextStyle(color: Colors.blue[900])),
      backgroundColor: Colors.blue[50],
      onPressed: () {
        _searchController.text = keyword;
        BlocProvider.of<StockBloc>(context).add(SearchStockEvent(keyword));
      },
    );
  }

  /// Build a stock card for search results.
  Widget _buildStockCard(dynamic stock) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Text(
            stock['name'][0].toUpperCase(),
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          stock['name'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        // subtitle: Text(
        //   "Price: \$${stock['price']}",
        //   style: TextStyle(color: Colors.green[700]),
        // ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PriceGraphScreen(
                stockId: stock['id'],
                stockName: stock['name'] ?? "Unknown Stock",
                symbol: stock['symbol'] ?? "",
                createdAt: stock['createdAt'] ?? "",
                updatedAt: stock['updatedAt'] ?? "",
                assetType: stock['asset_type'] ?? "",
              ),
            ),
          );
        },
      ),
    );
  }

  /// Custom header with gradient background, title, search field, and keyword chips.
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.lightBlueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Discover Stocks",
              style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          TextField(
            focusNode: _searchFocusNode,
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: "Search Stocks",
              hintStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white24,
              prefixIcon: Icon(Icons.search, color: Colors.white),
              suffixIcon: IconButton(
                icon: Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: () => _onSearchChanged(_searchController.text),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 12),
          // Use Wrap to allow keywords to span multiple lines.
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _keywords.map((kw) => _buildKeywordChip(kw)).toList(),
          ),
        ],
      ),
    );
  }

  /// Attractive empty state widget when no search query is active.
  Widget _buildAttractiveEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              "Start Your Stock Search",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600]),
            ),
            SizedBox(height: 10),
            Text(
              "Type a stock name or tap on a keyword to begin.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the Popular USA Stocks section.
  /// Only displays if matching stocks exist.
  Widget _buildUSAStocksSection(List<dynamic> stocks, {String? query}) {
    List<dynamic> usaStocks = stocks.where((stock) {
      final name = stock['name'].toString().toLowerCase();
      bool isUSA = name.contains("apple") ||
          name.contains("microsoft") ||
          name.contains("amazon") ||
          name.contains("google") ||
          name.contains("facebook") ||
          name.contains("tesla");
      if (query != null && query.trim().isNotEmpty) {
        return isUSA && name.contains(query.toLowerCase());
      }
      return isUSA;
    }).toList();

    if (usaStocks.isEmpty) return SizedBox.shrink();

    // Limit the number of stocks to display.
    if (usaStocks.length > 12) {
      usaStocks = usaStocks.sublist(0, 12);
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Popular USA Stocks",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: usaStocks.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5, // Adjust for desired row count.
            ),
            itemBuilder: (context, index) {
              final stock = usaStocks[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stock['name'],
                      style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    // Text("\$${stock['price']}",
                    //     style:
                    //     TextStyle(fontSize: 12, color: Colors.green[700])),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No default AppBar; using a custom header.
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 20),
              Expanded(
                child: BlocBuilder<StockBloc, StockState>(
                  builder: (context, state) {
                    // When no search query is active.
                    if (_searchController.text.trim().isEmpty) {
                      if (state is StockLoading) {
                        return Center(child: CircularProgressIndicator());
                      } else if (state is StockLoaded) {
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildAttractiveEmptyState(),
                              _buildUSAStocksSection(state.stocks),
                              // You can add more sections here.
                            ],
                          ),
                        );
                      } else if (state is StockError) {
                        return Center(child: Text(state.message));
                      }
                      return _buildAttractiveEmptyState();
                    }
                    // When there is a search query, show search results and updated USA stocks.
                    else {
                      if (state is StockLoading) {
                        return Center(child: CircularProgressIndicator());
                      } else if (state is StockLoaded) {
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              // Search Results Section.
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: state.stocks.length,
                                itemBuilder: (context, index) {
                                  final stock = state.stocks[index];
                                  return _buildStockCard(stock);
                                },
                              ),
                              SizedBox(height: 20),
                              // Updated USA Stocks Section based on search query.
                              _buildUSAStocksSection(state.stocks,
                                  query: _searchController.text.trim()),
                            ],
                          ),
                        );
                      } else if (state is StockError) {
                        return Center(child: Text(state.message));
                      }
                      return _buildAttractiveEmptyState();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
