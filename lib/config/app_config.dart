import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://your-project-ref.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  
  // App Configuration
  static const String appName = 'Book Reader';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const int apiTimeout = 30; // seconds
  static const int maxRetries = 3;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache Configuration
  static const int cacheExpirationHours = 24;
  static const int maxCacheSize = 100; // MB
  
  // Development flags
  static const bool isDevelopment = true;
  static const bool enableLogging = true;
  static const bool enableAnalytics = false;

  // Initialize Supabase
  static Future<void> initializeSupabase() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      if (enableLogging) {
        print('✅ Supabase initialized successfully');
      }
    } catch (e) {
      print('❌ Failed to initialize Supabase: $e');
      rethrow; // Rethrow to handle in the app
    }
  }
}
