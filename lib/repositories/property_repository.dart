import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payrent_business/repositories/base_repository.dart';

/// PropertyRepository encapsulates all property data access and caching.
class PropertyRepository extends BaseRepository {
  static const String _kPropertyListKey = 'property_list';

  Future<List<DocumentSnapshot>> fetchProperties({required String landlordId, bool forceRefresh = false}) async {
    final cacheKey = key(_kPropertyListKey, landlordId);
    if (!forceRefresh && cache.contains(cacheKey)) {
      return cache.get<List<DocumentSnapshot>>(cacheKey) ?? <DocumentSnapshot>[];
    }

    final qs = await firestore.querySubcollectionDocuments(
      parentCollection: 'users',
      parentDocumentId: landlordId,
      subcollection: 'properties',
    );

    final result = qs.docs;
    cache.set(cacheKey, result);
    return result;
  }

  Future<DocumentSnapshot?> getProperty({required String landlordId, required String propertyId, bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final list = await fetchProperties(landlordId: landlordId);
      final match = list.firstWhere(
        (d) => d.id == propertyId,
        orElse: () => null as DocumentSnapshot,
      );
      if (match != null) return match;
    }

    final doc = await firestore.getSubcollectionDocument(
      parentCollection: 'users',
      parentDocumentId: landlordId,
      subcollection: 'properties',
      documentId: propertyId,
    );
    return doc.exists ? doc : null;
  }

  Future<void> invalidateList(String landlordId) async {
    cache.invalidate(key(_kPropertyListKey, landlordId));
  }
}
