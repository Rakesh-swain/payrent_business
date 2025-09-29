import 'package:payrent_business/services/firestore_service.dart';
import 'package:payrent_business/repositories/session_cache.dart';

/// BaseRepository centralizes common dependencies and helpers
/// for repository implementations.
abstract class BaseRepository {
  BaseRepository({FirestoreService? firestore})
      : firestore = firestore ?? FirestoreService();

  final FirestoreService firestore;
  final SessionCache cache = SessionCache.instance;

  /// Helper to build a namespaced cache key.
  String key(String scope, [String? id]) => id == null ? scope : '${scope}_$id';
}
