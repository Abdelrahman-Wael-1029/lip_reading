import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ----------------- Document Operations -----------------

  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(collection).doc(documentId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      throw Exception('Failed to get document: $e');
    }
  }

  Future<String> addDocument({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      final ref = _firestore.collection(collection);
      if (documentId != null) {
        await ref.doc(documentId).set(data);
        return documentId;
      }
      return (await ref.add(data)).id;
    } catch (e) {
      throw Exception('Failed to add document: $e');
    }
  }

  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  Future<String> setDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).set(data, SetOptions(merge: merge));
      return documentId;
    } catch (e) {
      throw Exception('Failed to set document: $e');
    }
  }

  // ----------------- Collection Operations -----------------

  Future<List<Map<String, dynamic>>> getCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
    Map<String, dynamic>? whereCondition,
  }) async {
    try {
      final query = _buildQuery(
        collection: collection,
        orderBy: orderBy,
        descending: descending,
        limit: limit,
        whereCondition: whereCondition,
      );

      final querySnapshot = await query.get();
      return _mapQuerySnapshot(querySnapshot);
    } catch (e) {
      throw Exception('Failed to get collection: $e');
    }
  }

  Future<int> getCollectionCount({
    required String collection,
  }) async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      return snapshot.size;
    } catch (e) {
      throw Exception('Failed to count documents: $e');
    }
  }

  // ----------------- Real-Time Streams -----------------

  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots().map(
          (doc) => doc.exists ? doc.data() as Map<String, dynamic> : null,
        );
  }

  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
    Map<String, dynamic>? whereCondition,
  }) {
    final query = _buildQuery(
      collection: collection,
      orderBy: orderBy,
      descending: descending,
      limit: limit,
      whereCondition: whereCondition,
    );

    return query.snapshots().map(_mapQuerySnapshot);
  }

  // ----------------- Batch and Transaction -----------------

  Future<void> batchOperation({
    required List<Map<String, dynamic>> operations,
  }) async {
    final batch = _firestore.batch();

    try {
      for (var op in operations) {
        final ref = _firestore.collection(op['collection']).doc(op['documentId']);

        switch (op['type']) {
          case 'set':
            batch.set(ref, op['data'], SetOptions(merge: op['merge'] ?? false));
            break;
          case 'update':
            batch.update(ref, op['data']);
            break;
          case 'delete':
            batch.delete(ref);
            break;
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to perform batch operation: $e');
    }
  }

  Future<void> runTransaction({
    required Future<void> Function(Transaction) transaction,
  }) async {
    try {
      await _firestore.runTransaction(transaction);
    } catch (e) {
      throw Exception('Failed to run transaction: $e');
    }
  }

  // ----------------- Helpers -----------------

  Query _buildQuery({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
    Map<String, dynamic>? whereCondition,
  }) {
    Query query = _firestore.collection(collection);

    if (whereCondition != null) {
      final field = whereCondition['field'];
      final value = whereCondition['value'];
      final operator = whereCondition['operator'];

      query = _applyWhereCondition(query, field, value, operator);
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query;
  }

  Query _applyWhereCondition(
    Query query,
    String field,
    dynamic value,
    String operator,
  ) {
    switch (operator) {
      case '==':
        return query.where(field, isEqualTo: value);
      case '>':
        return query.where(field, isGreaterThan: value);
      case '>=':
        return query.where(field, isGreaterThanOrEqualTo: value);
      case '<':
        return query.where(field, isLessThan: value);
      case '<=':
        return query.where(field, isLessThanOrEqualTo: value);
      case 'array-contains':
        return query.where(field, arrayContains: value);
      default:
        throw Exception('Unsupported operator: $operator');
    }
  }

  List<Map<String, dynamic>> _mapQuerySnapshot(QuerySnapshot snapshot) {
    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
        .toList();
  }
}
