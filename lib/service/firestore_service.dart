// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generic method to fetch a document by ID
  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(collection).doc(documentId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get document: $e');
    }
  }

  // Generic method to fetch all documents in a collection
  Future<List<Map<String, dynamic>>> getCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
    Map<String, dynamic>? whereCondition,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply where condition if provided
      if (whereCondition != null) {
        String field = whereCondition['field'];
        dynamic value = whereCondition['value'];
        String operator = whereCondition['operator'];

        switch (operator) {
          case '==':
            query = query.where(field, isEqualTo: value);
            break;
          case '>':
            query = query.where(field, isGreaterThan: value);
            break;
          case '>=':
            query = query.where(field, isGreaterThanOrEqualTo: value);
            break;
          case '<':
            query = query.where(field, isLessThan: value);
            break;
          case '<=':
            query = query.where(field, isLessThanOrEqualTo: value);
            break;
          case 'array-contains':
            query = query.where(field, arrayContains: value);
            break;
        }
      }

      // Apply order if provided
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit if provided
      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to get collection: $e');
    }
  }

  Future<int> getLenthDocsCollection({
    required String collection,
  }) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection(collection).get();
      return querySnapshot.size;
    } catch (e) {
      throw Exception('Failed to get collection: $e');
    }
  }

  // Generic method to add a document
  Future<String> addDocument({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        await _firestore.collection(collection).doc(documentId).set(data);
        return documentId;
      } else {
        DocumentReference docRef =
            await _firestore.collection(collection).add(data);
        return docRef.id;
      }
    } catch (e) {
      throw Exception('Failed to add document: $e');
    }
  }

  // Generic method to update a document
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

  // Generic method to delete a document
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

  // Method to create or update a document (upsert)
  Future<String> setDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(documentId)
          .set(data, SetOptions(merge: merge));
      return documentId;
    } catch (e) {
      throw Exception('Failed to set document: $e');
    }
  }

  // Method to listen to real-time updates on a document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    return _firestore
        .collection(collection)
        .doc(documentId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() as Map<String, dynamic> : null);
  }

  // Method to listen to real-time updates on a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
    Map<String, dynamic>? whereCondition,
  }) {
    Query query = _firestore.collection(collection);

    // Apply where condition if provided
    if (whereCondition != null) {
      String field = whereCondition['field'];
      dynamic value = whereCondition['value'];
      String operator = whereCondition['operator'];

      switch (operator) {
        case '==':
          query = query.where(field, isEqualTo: value);
          break;
        case '>':
          query = query.where(field, isGreaterThan: value);
          break;
        case '>=':
          query = query.where(field, isGreaterThanOrEqualTo: value);
          break;
        case '<':
          query = query.where(field, isLessThan: value);
          break;
        case '<=':
          query = query.where(field, isLessThanOrEqualTo: value);
          break;
        case 'array-contains':
          query = query.where(field, arrayContains: value);
          break;
      }
    }

    // Apply order if provided
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit if provided
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    });
  }

  // Method to perform a batch operation
  Future<void> batchOperation({
    required List<Map<String, dynamic>> operations,
  }) async {
    final batch = _firestore.batch();

    try {
      for (var operation in operations) {
        final String type = operation['type'];
        final String collection = operation['collection'];
        final String documentId = operation['documentId'];
        final DocumentReference docRef =
            _firestore.collection(collection).doc(documentId);

        switch (type) {
          case 'set':
            batch.set(docRef, operation['data'],
                SetOptions(merge: operation['merge'] ?? false));
            break;
          case 'update':
            batch.update(docRef, operation['data']);
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to perform batch operation: $e');
    }
  }

  // Method to perform a transaction
  Future<void> runTransaction(
      {required Function(Transaction) transaction}) async {
    try {
      await _firestore.runTransaction((Transaction tx) async {
        return await transaction(tx);
      });
    } catch (e) {
      throw Exception('Failed to run transaction: $e');
    }
  }
}
