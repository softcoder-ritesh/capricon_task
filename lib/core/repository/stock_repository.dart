import 'dart:convert';
import 'package:http/http.dart' as http;

class StockRepository {
  final String baseUrl = "https://illuminate-production.up.railway.app/api/stocks";
  final String token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NzAsImlhdCI6MTczODkzOTY0NywiZXhwIjoxNzQxNTMxNjQ3fQ.MrBKkzXSpICAkPLk5VN9T7iNuUu_AXh2jb2iOAx40Us"; // Replace with dynamic token handling if needed
  Future<List<dynamic>> getInitialStocks() async {
    final response = await http.get(
      Uri.parse("$baseUrl?limit=10"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch initial stocks");
    }
  }
  Future<List<dynamic>> searchStocks(String query) async {
    final response = await http.get(
      Uri.parse("$baseUrl/search?query=$query"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch stocks");
    }
  }

  Future<List<dynamic>> getStockPriceGraph(int stockId, String range) async {
    final response = await http.get(
      Uri.parse("$baseUrl/$stockId/price-graph?range=$range"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch price graph data");
    }
  }
}
