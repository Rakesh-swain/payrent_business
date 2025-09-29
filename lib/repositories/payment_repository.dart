import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:payrent_business/repositories/base_repository.dart';

class mentsPaymentRepository extends BaseRepository {
  static const String _kPaymentListKey = 'payment_list';

  Future<List<DocumentSnapshot>> fetchPayments({required String landlordId, bool forceRefresh = false}) async {
    final cacheKey = key(_kPaymentListKey, landlordId);
    if (!forceRefresh && cache.contains(cacheKey)) {
      return cache.get<List<DocumentSnapshot>>(cacheKey) ?? <DocumentSnapshot>[];
    }

    final qs = await firestore.querySubcollectionDocuments(
      parentCollection: 'users',
      parentDocumentId: landlordId,
      subcollection: 'payments',
      orderBy: 'dueDate',
      descending: true,
    );
    final result = qs.docs;
    cache.set(cacheKey, result);
    return result;
  }

  Future<void> invalidateList(String landlordId) async {
    cache.invalidate(key(_kPaymentListKey, landlordId));
  }
}
