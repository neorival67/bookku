import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/book.dart';

class BookRepository {
  final SupabaseClient _supabase;

  BookRepository(this._supabase);

  Future<List<Book>> getBooks({
    String? category,
    String? search,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
    int page = 1,
  }) async {
    try {
      // Build query parameters
      String? categoryId;
      if (category != null) {
        final categoryData = await _supabase
            .from('categories')
            .select('id')
            .eq('name', category)
            .single();
        categoryId = categoryData['id'];
      }
      
      // Build the complete query
      final from = (page - 1) * limit;
      final to = from + limit - 1;
      final ascending = sortOrder?.toLowerCase() != 'desc';
      final orderBy = sortBy ?? 'created_at';
      
      // Execute query based on filters
      List<Map<String, dynamic>> response;
      
      if (categoryId != null && search != null && search.isNotEmpty) {
        response = await _supabase
            .from('books')
            .select('''
              *,
              categories:category_id(name)
            ''')
            .eq('category_id', categoryId)
            .textSearch('title,author,description', search)
            .order(orderBy, ascending: ascending)
            .range(from, to);
      } else if (categoryId != null) {
        response = await _supabase
            .from('books')
            .select('''
              *,
              categories:category_id(name)
            ''')
            .eq('category_id', categoryId)
            .order(orderBy, ascending: ascending)
            .range(from, to);
      } else if (search != null && search.isNotEmpty) {
        response = await _supabase
            .from('books')
            .select('''
              *,
              categories:category_id(name)
            ''')
            .textSearch('title,author,description', search)
            .order(orderBy, ascending: ascending)
            .range(from, to);
      } else {
        response = await _supabase
            .from('books')
            .select('''
              *,
              categories:category_id(name)
            ''')
            .order(orderBy, ascending: ascending)
            .range(from, to);
      }

      // Check if books are favorites
      final currentUser = _supabase.auth.currentUser;
      List<String> favoriteBookIds = [];
      
      if (currentUser != null) {
        final favorites = await _supabase
            .from('user_favorites')
            .select('book_id')
            .eq('user_id', currentUser.id);
        
        favoriteBookIds = favorites
            .map<String>((fav) => fav['book_id'] as String)
            .toList();
      }

      return response.map<Book>((json) {
        final isFavorite = favoriteBookIds.contains(json['id']);
        
        return Book(
          id: json['id'],
          title: json['title'],
          author: json['author'],
          description: json['description'],
          coverUrl: json['cover_url'],
          category: json['categories']['name'],
          rating: (json['rating'] as num).toDouble(),
          pages: json['pages'],
          pdfUrl: json['pdf_url'],
          publishedDate: DateTime.parse(json['published_date']),
          isFavorite: isFavorite,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch books: $e');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select('name')
          .order('name');
      
      return response
          .map<String>((json) => json['name'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  Future<void> toggleFavorite(String bookId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Check if already favorited
      final existing = await _supabase
          .from('user_favorites')
          .select()
          .eq('user_id', user.id)
          .eq('book_id', bookId)
          .maybeSingle();
      
      if (existing != null) {
        // Remove from favorites
        await _supabase
            .from('user_favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('book_id', bookId);
      } else {
        // Add to favorites
        await _supabase
            .from('user_favorites')
            .insert({
              'user_id': user.id,
              'book_id': bookId,
            });
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  Future<List<Book>> getFavoriteBooks({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final from = (page - 1) * limit;
      final to = from + limit - 1;
      
      final response = await _supabase
          .from('user_favorites')
          .select('''
            books:book_id(
              *,
              categories:category_id(name)
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .range(from, to);
      
      return response.map<Book>((json) {
        final book = json['books'];
        return Book(
          id: book['id'],
          title: book['title'],
          author: book['author'],
          description: book['description'],
          coverUrl: book['cover_url'],
          category: book['categories']['name'],
          rating: (book['rating'] as num).toDouble(),
          pages: book['pages'],
          pdfUrl: book['pdf_url'],
          publishedDate: DateTime.parse(book['published_date']),
          isFavorite: true,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch favorite books: $e');
    }
  }
}
