import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/api_client.dart';
import '../services/favorite_update_service.dart';
import '../widgets/book_list_widget.dart';
import '../widgets/category_slider.dart';
import 'book_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Book> _books = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiClient = ApiClient();
      
      // Load categories
      final categories = await apiClient.getCategories();
      
      // Load books
      final books = await apiClient.getBooks(
        category: _selectedCategory,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );

      setState(() {
        _categories = categories;
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadData();
  }

  void _onSearch() {
    _loadData();
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
      final apiClient = ApiClient();
      await apiClient.toggleFavorite(book.id);
      
      // Notify other screens about the favorite update
      FavoriteUpdateService().notifyFavoriteUpdated(book.id);

      // Refresh the book list
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating favorite: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search books...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _onSearch(),
              )
            : const Text(
                'Explore',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _onSearch();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
            child: CategorySlider(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: _onCategorySelected,
              isLoading: _isLoading,
            ),
          ),
          
          // Books
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: BookListWidget(
                books: _books,
                onBookTap: _onBookTap,
                onFavoriteTap: _onFavoriteTap,
                isLoading: _isLoading,
                scrollable: true, // Enable scrolling in the explore screen
              ),
            ),
          ),
        ],
      ),
    );
  }
}
