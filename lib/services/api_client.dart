import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/book.dart';

class ApiClient {
  static const String baseUrl = 'https://api.example.com';
  String? _token;

  // Auth Methods
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      return User.fromJson(data['user']);
    } else {
      throw Exception('Failed to login');
    }
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      return User.fromJson(data['user']);
    } else {
      throw Exception('Failed to register');
    }
  }

  Future<void> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      _token = null;
    } else {
      throw Exception('Failed to logout');
    }
  }

  Future<User?> getCurrentUser() async {
    if (_token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    }
    return null;
  }

  // Book Methods
  Future<List<Book>> getBooks({
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;

    final uri = Uri.parse('$baseUrl/books').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri, headers: _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> booksJson = data['books'];
      return booksJson.map((json) => Book.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch books');
    }
  }

  Future<List<String>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['categories']);
    } else {
      throw Exception('Failed to fetch categories');
    }
  }

  Future<Book> getBookById(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/books/$id'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Book.fromJson(data);
    } else {
      throw Exception('Failed to fetch book');
    }
  }

  Future<List<Book>> getFavoriteBooks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/books/favorites'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> booksJson = data['books'];
      return booksJson.map((json) => Book.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch favorite books');
    }
  }

  Future<void> toggleFavorite(String bookId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/books/$bookId/favorite'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle favorite');
    }
  }

  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }
}
