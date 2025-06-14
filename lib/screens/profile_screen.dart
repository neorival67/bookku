import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../models/book.dart';
import '../services/api_client.dart';
import '../services/favorite_update_service.dart';
import '../widgets/book_list_widget.dart';
import 'book_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ApiClient _apiClient;
  late final StreamSubscription _favoriteSubscription;
  List<Book> _favoriteBooks = [];
  bool _isLoading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _apiClient = context.read<ApiClient>();
      _initializeFavoriteListener();
      _loadFavoriteBooks();
      _initialized = true;
    }
  }

  void _initializeFavoriteListener() {
    _favoriteSubscription = FavoriteUpdateService().stream.listen((_) {
      _loadFavoriteBooks();
    });
  }

  @override
  void dispose() {
    _favoriteSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadFavoriteBooks() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final favoriteBooks = await _apiClient.getFavoriteBooks();

      if (!mounted) return;

      setState(() {
        _favoriteBooks = favoriteBooks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading favorite books: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onBookTap(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(book: book),
      ),
    );
  }

  void _onFavoriteTap(Book book) async {
    try {
      // Call API
      await _apiClient.toggleFavorite(book.id);
      
      if (!mounted) return;

      // Notify other screens
      FavoriteUpdateService().notifyFavoriteUpdated(book.id);

      // Reload favorite books to ensure sync with server
      await _loadFavoriteBooks();

      // Show success message
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            !book.isFavorite 
              ? 'Added to favorites' 
              : 'Removed from favorites'
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error updating favorite: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state.status != AuthStatus.authenticated) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final user = state.user!;

          return RefreshIndicator(
            onRefresh: _loadFavoriteBooks,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // User Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          backgroundImage: user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null
                              ? Text(
                                  user.name?.isNotEmpty == true
                                      ? user.name![0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // User Name
                        Text(
                          user.name ?? 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // User Email
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(),
                  
                  // Favorite Books
                  Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Favorite Books',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300, // Atau sesuaikan tinggi sesuai kebutuhan
                        child: BookListWidget(
                          books: _favoriteBooks,
                          onBookTap: _onBookTap,
                          onFavoriteTap: _onFavoriteTap,
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
                ),
                  
                  const SizedBox(height: 24),
                  
                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
