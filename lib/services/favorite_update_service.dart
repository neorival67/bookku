import 'dart:async';

class FavoriteUpdateService {
  static final FavoriteUpdateService _instance = FavoriteUpdateService._internal();
  factory FavoriteUpdateService() => _instance;
  FavoriteUpdateService._internal();

  final _controller = StreamController<String>.broadcast();
  Stream<String> get stream => _controller.stream;

  void notifyFavoriteUpdated(String bookId) {
    _controller.add(bookId);
  }

  void dispose() {
    _controller.close();
  }
}
