/// SessionCache provides a simple in-memory cache for the current app session.
/// It stores values by string key and persists until the app process is killed.
/// Repositories should use this for memoizing Firestore/API reads and expose
/// explicit refresh/invalidate methods to callers when fresh data is required.
class SessionCache {
  SessionCache._internal();
  static final SessionCache _instance = SessionCache._internal();
  static SessionCache get instance => _instance;

  final Map<String, dynamic> _store = <String, dynamic>{};

  /// Returns a cached value for [key] casted to [T], or null if not present.
  T? get<T>(String key) {
    final value = _store[key];
    if (value is T) return value;
    return null;
  }

  /// Sets a value for [key]. Overwrites existing.
  void set(String key, dynamic value) {
    _store[key] = value;
  }

  /// Removes a specific [key] from the cache.
  void invalidate(String key) {
    _store.remove(key);
  }

  /// Clears the entire cache.
  void invalidateAll() {
    _store.clear();
  }

  /// Returns true if the key exists in cache.
  bool contains(String key) => _store.containsKey(key);
}
