import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payrent_business/repositories/base_repository.dart';
import 'package:payrent_business/models/tenant_model.dart';

/// TenantRepository encapsulates all tenant data access and caching.
class TenantRepository extends BaseRepository {
  static const String _kTenantListKey = 'tenant_list';

  /// Fetch all tenants for a landlord. Uses session cache unless [forceRefresh] is true.
  Future<List<DocumentSnapshot>> fetchTenants({required String landlordId, bool forceRefresh = false}) async {
    final cacheKey = key(_kTenantListKey, landlordId);
    if (!forceRefresh && cache.contains(cacheKey)) {
      return cache.get<List<DocumentSnapshot>>(cacheKey) ?? <DocumentSnapshot>[];
    }

    final qs = await firestore.querySubcollectionDocuments(
      parentCollection: 'users',
      parentDocumentId: landlordId,
      subcollection: 'tenants',
    );

    final result = qs.docs;
    cache.set(cacheKey, result);
    return result;
  }

  /// Get a tenant by id. It will look into cached list first to avoid reads.
  Future<DocumentSnapshot?> getTenant({required String landlordId, required String tenantId, bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final list = await fetchTenants(landlordId: landlordId, forceRefresh: false);
      DocumentSnapshot? match;
      for (final d in list) {
        if (d.id == tenantId) {
          match = d;
          break;
        }
      }
      if (match != null) return match;
    }

    final doc = await firestore.getSubcollectionDocument(
      parentCollection: 'users',
      parentDocumentId: landlordId,
      subcollection: 'tenants',
      documentId: tenantId,
    );

    return doc.exists ? doc : null;
  }

  Future<String> createTenant({required String landlordId, required TenantModel tenant}) async {
    final ref = await firestore.createSubcollectionDocument(
      parentCollection: 'users',
      parentDocumentId: landlordId,
      subcollection: 'tenants',
      data: tenant.toFirestore(),
    );
    // Invalidate cache for landlord
    cache.invalidate(key(_kTenantListKey, landlordId));
    return ref.id;
  }

  Future<void> updateTenant({required String landlordId, required String tenantId, required Map<String, dynamic> data}) async {
    await firestore.updateSubcollectionDocument(
      parentCollection: 'users',
      parentDocumentId: landlordId,
      subcollection: 'tenants',
      documentId: tenantId,
      data: data,
    );
    cache.invalidate(key(_kTenantListKey, landlordId));
  }

  Future<void> deleteTenant({required String landlordId, required String tenantId}) async {
    await firestore.deleteSubcollectionDocument(
      parentCollection: 'users',
      parentDocumentId: landlordId,
      subcollection: 'tenants',
      documentId: tenantId,
    );
    cache.invalidate(key(_kTenantListKey, landlordId));
  }
}
