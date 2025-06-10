import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/user.dart' as app_user;
import '../models/book.dart';
import '../utils/app_exceptions.dart';

class SupabaseService {
  // Get the Supabase client instance
  static supabase.SupabaseClient get client => supabase.Supabase.instance.client;
  
  // Auth Methods
  static Future<app_user.User> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Step 1: Sign up the user first
      final authResponse = await client.auth.signUp(
        email: email,
        password: password,
      );
      
      if (authResponse.user == null) {
        throw AppAuthException('Failed to create account');
      }

      // Step 2: Create the profile record directly
      try {
        final profile = await client
            .from('profiles')
            .insert({
              'id': authResponse.user!.id,
              'name': name,
              'email': email,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        // Step 3: Call the Supabase function for any additional setup
        try {
          await client.functions.invoke('on_user_signup', body: {
            'user_id': authResponse.user!.id,
            'email': email,
            'name': name,
          });
        } catch (e) {
          // Log but don't fail if function call fails
          print('Warning: Failed to call on_user_signup function: $e');
        }

        return app_user.User(
          id: authResponse.user!.id,
          email: email,
          name: name,
          profileImage: profile['profile_image'],
          createdAt: DateTime.parse(profile['created_at']),
        );
      } catch (e) {
        // If profile creation fails, attempt to clean up by deleting the auth user
        try {
          await client.auth.admin.deleteUser(authResponse.user!.id);
        } catch (_) {
          // Ignore cleanup errors
        }
        throw AppAuthException('Failed to create user profile: ${e.toString()}');
      }
    } on supabase.AuthException catch (e) {
      throw AppAuthException('Registration failed: ${e.message}');
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw AppAuthException('Registration failed: ${e.toString()}');
    }
  }
  
  static Future<app_user.User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw AppAuthException('Invalid credentials');
      }
      
      // Get user profile
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();
      
      return app_user.User(
        id: response.user!.id,
        email: response.user!.email!,
        name: profile['name'],
        profileImage: profile['profile_image'],
        createdAt: DateTime.parse(profile['created_at']),
      );
    } on supabase.AuthException catch (e) {
      // Handle Supabase AuthException
      throw AppAuthException('Login failed: ${e.message}');
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw AppAuthException('Login failed: ${e.toString()}');
    }
  }
  
  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } on supabase.AuthException catch (e) {
      throw AppAuthException('Logout failed: ${e.message}');
    } catch (e) {
      throw AppAuthException('Logout failed: ${e.toString()}');
    }
  }
  
  static Future<app_user.User?> getCurrentUser() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return null;
      
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      
      return app_user.User(
        id: user.id,
        email: user.email!,
        name: profile['name'],
        profileImage: profile['profile_image'],
        createdAt: DateTime.parse(profile['created_at']),
      );
    } catch (e) {
      return null;
    }
  }
  
  // Profile Methods
  static Future<app_user.User> updateProfile({
    String? name,
    String? profileImage,
  }) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw AppAuthException('User not authenticated');
      
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (name != null) updates['name'] = name;
      if (profileImage != null) updates['profile_image'] = profileImage;
      
      final response = await client
          .from('profiles')
          .update(updates)
          .eq('id', user.id)
          .select()
          .single();
      
      return app_user.User(
        id: user.id,
        email: user.email!,
        name: response['name'],
        profileImage: response['profile_image'],
        createdAt: DateTime.parse(response['created_at']),
      );
    } on supabase.PostgrestException catch (e) {
      throw FetchDataException('Failed to update profile: ${e.message}');
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw FetchDataException('Failed to update profile: ${e.toString()}');
    }
  }
  
  // Book Methods
  static Future<List<Book>> getBooks({
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      // Build query parameters
      String? categoryId;
      if (category != null) {
        final categoryData = await client
            .from('categories')
            .select('id')
            .eq('name', category)
            .single();
        categoryId = categoryData['id'];
      }
      
      // Build the complete query in one chain to avoid type issues
      final from = (page - 1) * limit;
      final to = from + limit - 1;
      final ascending = sortOrder?.toLowerCase() != 'desc';
      final orderBy = sortBy ?? 'created_at';
      
      // Execute query based on filters
      List<Map<String, dynamic>> response;
      
      if (categoryId != null && search != null && search.isNotEmpty) {
        // Category + Search
        response = await client
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
        // Category only
        response = await client
            .from('books')
            .select('''
              *,
              categories:category_id(name)
            ''')
            .eq('category_id', categoryId)
            .order(orderBy, ascending: ascending)
            .range(from, to);
      } else if (search != null && search.isNotEmpty) {
        // Search only
        response = await client
            .from('books')
            .select('''
              *,
              categories:category_id(name)
            ''')
            .textSearch('title,author,description', search)
            .order(orderBy, ascending: ascending)
            .range(from, to);
      } else {
        // No filters
        response = await client
            .from('books')
            .select('''
              *,
              categories:category_id(name)
            ''')
            .order(orderBy, ascending: ascending)
            .range(from, to);
      }
      
      // Check if book is favorite for current user
      final currentUser = client.auth.currentUser;
      List<String> favoriteBookIds = [];
      
      if (currentUser != null) {
        final favorites = await client
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
          categories: [json['categories']['name']],
          rating: (json['rating'] as num).toDouble(),
          pages: json['pages'],
          pdfUrl: json['pdf_url'],
          publishedDate: DateTime.parse(json['published_date']),
          isFavorite: isFavorite,
        );
      }).toList();
    } on supabase.PostgrestException catch (e) {
      throw FetchDataException('Failed to fetch books: ${e.message}');
    } catch (e) {
      throw FetchDataException('Failed to fetch books: ${e.toString()}');
    }
  }
  
  static Future<Book> getBookById(String id) async {
    try {
      print('Fetching book details for ID: $id');
      final response = await client
          .from('books')
          .select('''
            *,
            categories:category_id(name)
          ''')
          .eq('id', id)
          .single();
      
      print('Book PDF URL from DB: ${response['pdf_url']}');
      
      // Check if book is favorite for current user
      final currentUser = client.auth.currentUser;
      bool isFavorite = false;
      
      if (currentUser != null) {
        final favorite = await client
            .from('user_favorites')
            .select()
            .eq('user_id', currentUser.id)
            .eq('book_id', id)
            .maybeSingle();
        
        isFavorite = favorite != null;
      }
      
      return Book(
        id: response['id'],
        title: response['title'],
        author: response['author'],
        description: response['description'],
        coverUrl: response['cover_url'],
        categories: [response['categories']['name']],
        rating: (response['rating'] as num).toDouble(),
        pages: response['pages'],
        pdfUrl: response['pdf_url'],
        publishedDate: DateTime.parse(response['published_date']),
        isFavorite: isFavorite,
      );
    } on supabase.PostgrestException catch (e) {
      throw FetchDataException('Failed to fetch book: ${e.message}');
    } catch (e) {
      throw FetchDataException('Failed to fetch book: ${e.toString()}');
    }
  }
  
  static Future<List<String>> getCategories() async {
    try {
      final response = await client
          .from('categories')
          .select('name')
          .order('name');
      
      return response.map<String>((json) => json['name'] as String).toList();
    } on supabase.PostgrestException catch (e) {
      throw FetchDataException('Failed to fetch categories: ${e.message}');
    } catch (e) {
      throw FetchDataException('Failed to fetch categories: ${e.toString()}');
    }
  }
  
  // Favorites Methods
  static Future<void> toggleFavorite(String bookId) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw AppAuthException('User not authenticated');
      
      // Check if already favorited
      final existing = await client
          .from('user_favorites')
          .select()
          .eq('user_id', user.id)
          .eq('book_id', bookId)
          .maybeSingle();
      
      if (existing != null) {
        // Remove from favorites
        await client
            .from('user_favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('book_id', bookId);
      } else {
        // Add to favorites
        await client
            .from('user_favorites')
            .insert({
              'user_id': user.id,
              'book_id': bookId,
            });
      }
    } on supabase.PostgrestException catch (e) {
      throw FetchDataException('Failed to toggle favorite: ${e.message}');
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw FetchDataException('Failed to toggle favorite: ${e.toString()}');
    }
  }
  
  static Future<List<Book>> getFavoriteBooks({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw AppAuthException('User not authenticated');
      
      final from = (page - 1) * limit;
      final to = from + limit - 1;
      
      final response = await client
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
          categories: [book['categories']['name']],
          rating: (book['rating'] as num).toDouble(),
          pages: book['pages'],
          pdfUrl: book['pdf_url'],
          publishedDate: DateTime.parse(book['published_date']),
          isFavorite: true,
        );
      }).toList();
    } on supabase.PostgrestException catch (e) {
      throw FetchDataException('Failed to fetch favorite books: ${e.message}');
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw FetchDataException('Failed to fetch favorite books: ${e.toString()}');
    }
  }
  
  // Reading Progress Methods
  static Future<void> updateReadingProgress(String bookId, int currentPage) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw AppAuthException('User not authenticated');
      
      // Get total pages for percentage calculation
      final book = await client
          .from('books')
          .select('pages')
          .eq('id', bookId)
          .single();
      
      final totalPages = book['pages'] as int;
      final progressPercentage = (currentPage / totalPages) * 100;
      
      final progressData = {
        'user_id': user.id,
        'book_id': bookId,
        'current_page': currentPage,
        'progress_percentage': progressPercentage,
        'status': progressPercentage >= 100 ? 'completed' : 'reading',
        'last_read_at': DateTime.now().toIso8601String(),
      };
      
      if (progressPercentage >= 100) {
        progressData['completed_at'] = DateTime.now().toIso8601String();
      }
      
      // Check if progress already exists
      final existing = await client
          .from('reading_progress')
          .select()
          .eq('user_id', user.id)
          .eq('book_id', bookId)
          .maybeSingle();
      
      if (existing != null) {
        // Update existing progress
        await client
            .from('reading_progress')
            .update(progressData)
            .eq('user_id', user.id)
            .eq('book_id', bookId);
      } else {
        // Create new progress
        await client
            .from('reading_progress')
            .insert(progressData);
      }
    } on supabase.PostgrestException catch (e) {
      throw FetchDataException('Failed to update reading progress: ${e.message}');
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw FetchDataException('Failed to update reading progress: ${e.toString()}');
    }
  }
  
  static Future<int> getReadingProgress(String bookId) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return 0;
      
      final response = await client
          .from('reading_progress')
          .select('current_page')
          .eq('user_id', user.id)
          .eq('book_id', bookId)
          .maybeSingle();
      
      return response?['current_page'] ?? 0;
    } catch (e) {
      return 0;
    }
  }
  
  // Reading Statistics
  static Future<Map<String, dynamic>> getUserReadingStats() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw AppAuthException('User not authenticated');
      
      // Use separate functions to execute each query to avoid type issues
      Future<int> getCompletedBooksCount() async {
        final response = await client
            .from('reading_progress')
            .select('id')
            .eq('user_id', user.id)
            .eq('status', 'completed');
        return response.length;
      }
      
      Future<int> getCurrentlyReadingCount() async {
        final response = await client
            .from('reading_progress')
            .select('id')
            .eq('user_id', user.id)
            .eq('status', 'reading');
        return response.length;
      }
      
      Future<int> getFavoritesCount() async {
        final response = await client
            .from('user_favorites')
            .select('id')
            .eq('user_id', user.id);
        return response.length;
      }
      
      Future<int> getTotalReadingTime() async {
        final response = await client
            .from('reading_sessions')
            .select('duration_minutes')
            .eq('user_id', user.id);
        
        int total = 0;
        for (final session in response) {
          total += (session['duration_minutes'] as int? ?? 0);
        }
        return total;
      }
      
      Future<double> getAverageRating() async {
        final response = await client
            .from('book_reviews')
            .select('rating')
            .eq('user_id', user.id);
        
        if (response.isEmpty) return 0.0;
        
        double total = 0.0;
        for (final review in response) {
          total += (review['rating'] as num).toDouble();
        }
        return total / response.length;
      }
      
      // Execute all queries in parallel for better performance
      final results = await Future.wait([
        getCompletedBooksCount(),
        getCurrentlyReadingCount(),
        getFavoritesCount(),
        getTotalReadingTime(),
        getAverageRating(),
      ]);
      
      return {
        'total_books_read': results[0],
        'currently_reading': results[1],
        'total_favorites': results[2],
        'total_reading_time': results[3],
        'average_rating': results[4],
      };
    } on supabase.PostgrestException catch (e) {
      throw FetchDataException('Failed to fetch reading stats: ${e.message}');
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw FetchDataException('Failed to fetch reading stats: ${e.toString()}');
    }
  }
}
