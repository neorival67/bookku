import '../models/user.dart';
import '../models/book.dart';
import 'supabase_service.dart';

class ApiClient {
  // Auth Methods
  Future<User> login({
    required String email,
    required String password,
  }) async {
    return await SupabaseService.signIn(
      email: email,
      password: password,
    );
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return await SupabaseService.signUp(
      email: email,
      password: password,
      name: name,
    );
  }

  Future<void> logout() async {
    await SupabaseService.signOut();
  }

  Future<User?> getCurrentUser() async {
    return await SupabaseService.getCurrentUser();
  }

  Future<User> updateProfile({
    String? name,
    String? profileImage,
  }) async {
    return await SupabaseService.updateProfile(
      name: name,
      profileImage: profileImage,
    );
  }

  // Book Methods
  Future<List<Book>> getBooks({
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
  }) async {
    return await SupabaseService.getBooks(
      category: category,
      search: search,
      page: page,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  Future<Book> getBookById(String id) async {
    return await SupabaseService.getBookById(id);
  }

  Future<List<String>> getCategories() async {
    return await SupabaseService.getCategories();
  }

  Future<void> toggleFavorite(String bookId) async {
    await SupabaseService.toggleFavorite(bookId);
  }

  Future<List<Book>> getFavoriteBooks({
    int page = 1,
    int limit = 20,
  }) async {
    return await SupabaseService.getFavoriteBooks(
      page: page,
      limit: limit,
    );
  }

  Future<void> updateReadingProgress(String bookId, int currentPage) async {
    await SupabaseService.updateReadingProgress(bookId, currentPage);
  }

  Future<int> getReadingProgress(String bookId) async {
    return await SupabaseService.getReadingProgress(bookId);
  }

  Future<Map<String, dynamic>> getUserReadingStats() async {
    return await SupabaseService.getUserReadingStats();
  }
}
