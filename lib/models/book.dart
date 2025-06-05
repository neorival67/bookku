class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String coverUrl;
  final String category;
  final double rating;
  final int pages;
  final String? pdfUrl;
  final DateTime publishedDate;
  final bool isFavorite;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverUrl,
    required this.category,
    required this.rating,
    required this.pages,
    this.pdfUrl,
    required this.publishedDate,
    this.isFavorite = false,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      description: json['description'],
      coverUrl: json['cover_url'],
      category: json['category'],
      rating: (json['rating'] as num).toDouble(),
      pages: json['pages'],
      pdfUrl: json['pdf_url'],
      publishedDate: DateTime.parse(json['published_date']),
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'cover_url': coverUrl,
      'category': category,
      'rating': rating,
      'pages': pages,
      'pdf_url': pdfUrl,
      'published_date': publishedDate.toIso8601String(),
      'is_favorite': isFavorite,
    };
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? coverUrl,
    String? category,
    double? rating,
    int? pages,
    String? pdfUrl,
    DateTime? publishedDate,
    bool? isFavorite,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      pages: pages ?? this.pages,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      publishedDate: publishedDate ?? this.publishedDate,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
