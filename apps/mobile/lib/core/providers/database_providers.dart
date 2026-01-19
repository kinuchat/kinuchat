import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meshlink_core/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Provider for database path
final databasePathProvider = FutureProvider<String>((ref) async {
  final appDir = await getApplicationDocumentsDirectory();
  return p.join(appDir.path, 'meshlink.db');
});

/// Provider for AppDatabase instance
final databaseProvider = Provider<AppDatabase>((ref) {
  // Get the database path asynchronously
  final pathAsync = ref.watch(databasePathProvider);

  return pathAsync.when(
    data: (path) => AppDatabase.forPath(path),
    loading: () => throw Exception('Database path not yet available'),
    error: (error, stack) => throw Exception('Failed to get database path: $error'),
  );
});

/// Async provider for AppDatabase that waits for path resolution
final asyncDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final path = await ref.watch(databasePathProvider.future);
  return AppDatabase.forPath(path);
});
