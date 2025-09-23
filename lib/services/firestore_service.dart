import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Generic methods for CRUD operations
  
  // Create document with auto-generated ID
  Future<DocumentReference> createDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    return await _firestore.collection(collection).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Create document with specific ID
  Future<void> createDocumentWithId({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection(collection).doc(documentId).set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Get document by ID
  Future<DocumentSnapshot> getDocument({
    required String collection,
    required String documentId,
  }) async {
    return await _firestore.collection(collection).doc(documentId).get();
  }
  
  // Get collection
  CollectionReference getCollection(String collection) {
    return _firestore.collection(collection);
  }
  
  // Update document
  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection(collection).doc(documentId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Delete document
  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    await _firestore.collection(collection).doc(documentId).delete();
  }
  
  // Query documents with filters
  Future<QuerySnapshot> queryDocuments({
    required String collection,
    required List<List<dynamic>> filters,
    String? orderBy,
    bool? descending,
    int? limit,
  }) async {
    Query query = _firestore.collection(collection);
    
    for (final filter in filters) {
      query = query.where(filter[0], isEqualTo: filter[1]);
    }
    
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending ?? false);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return await query.get();
  }
  
  // Stream of documents from a collection
  Stream<QuerySnapshot> streamCollection(String collection) {
    return _firestore.collection(collection).snapshots();
  }
  
  // Stream of a specific document
  Stream<DocumentSnapshot> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots();
  }
  
  // Batch operations
  Future<void> batchOperation(Function(WriteBatch) batchOperation) async {
    final batch = _firestore.batch();
    batchOperation(batch);
    await batch.commit();
  }
  
  // Transaction operations
  Future<T> transactionOperation<T>(
      Future<T> Function(Transaction) transactionOperation) async {
    return await _firestore.runTransaction(transactionOperation);
  }
}
