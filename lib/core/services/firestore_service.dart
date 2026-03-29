import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users ---
  Future<void> createUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data);
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  Stream<DocumentSnapshot> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // --- Buses ---
  Stream<List<Map<String, dynamic>>> streamActiveBuses() {
    return _db.collection('buses').where('status', isEqualTo: 'active').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    });
  }

  Stream<DocumentSnapshot> streamBus(String busId) {
    return _db.collection('buses').doc(busId).snapshots();
  }

  Stream<DocumentSnapshot> streamBusLocation(String busId) {
    return _db.collection('bus_locations').doc(busId).snapshots();
  }

  Future<void> updateBusLocation(String busId, double lat, double lng, {double? speed, double? direction}) async {
    final String normalizedBusId = busId.toString();

    await _db.collection('bus_locations').doc(normalizedBusId).set({
      'lat': lat,
      'lng': lng,
      if (speed != null) 'speed': speed,
      if (direction != null) 'direction': direction,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('buses').doc(normalizedBusId).set({
      'currentLat': lat,
      'currentLng': lng,
      'latitude': lat,
      'longitude': lng,
      if (speed != null) 'speed': speed,
      if (direction != null) 'direction': direction,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> assignBusToDriver(String driverId, String busId) async {
    final String normalizedBusId = busId.toString();
    final String normalizedDriverId = driverId.toString();

    // Clear existing bus assignment for this driver
    final driverDoc = await _db.collection('users').doc(normalizedDriverId).get();
    if (driverDoc.exists) {
      final oldBusId = (driverDoc.data()?['busId'] ?? '').toString();
      if (oldBusId.isNotEmpty && oldBusId != normalizedBusId) {
        await _db.collection('buses').doc(oldBusId).update({'driverId': null});
      }
    }

    await _db.collection('users').doc(normalizedDriverId).update({
      'busId': normalizedBusId,
      'role': 'driver',
    });

    await _db.collection('buses').doc(normalizedBusId).set({'driverId': normalizedDriverId}, SetOptions(merge: true));
  }

  Future<void> assignBusToStudent(String studentId, String busId, String driverId) async {
    final String normalizedStudentId = studentId.toString();
    final String normalizedBusId = busId.toString();
    final String normalizedDriverId = driverId.toString();

    await _db.collection('users').doc(normalizedStudentId).update({
      'busId': normalizedBusId,
      'driverId': normalizedDriverId,
      'role': 'student',
    });

    await _db.collection('buses').doc(normalizedBusId).set({
      'driverId': normalizedDriverId,
    }, SetOptions(merge: true));
  }

  // --- Trips ---
  Future<String> startTrip(String busId, String driverId, String routeId) async {
    final docRef = await _db.collection('trips').add({
      'busId': busId,
      'driverId': driverId,
      'routeId': routeId,
      'startTime': FieldValue.serverTimestamp(),
      'status': 'active',
      'currentStopIndex': 0,
    });
    
    await _db.collection('buses').doc(busId).update({'status': 'active', 'currentTripId': docRef.id});
    return docRef.id;
  }

  Future<void> endTrip(String tripId, String busId) async {
    await _db.collection('trips').doc(tripId).update({
      'endTime': FieldValue.serverTimestamp(),
      'status': 'completed',
    });
    await _db.collection('buses').doc(busId).update({'status': 'inactive', 'currentTripId': null});
  }

  Future<Map<String, dynamic>?> getMyBus(String uid) async {
    final userSnap = await _db.collection('users').doc(uid).get();
    if (!userSnap.exists) return null;
    final userData = userSnap.data() as Map<String, dynamic>;
    final busId = (userData['busId'] ?? '').toString();
    if (busId.isEmpty) return null;
    final busSnap = await _db.collection('buses').doc(busId).get();
    return busSnap.exists ? {...busSnap.data()!, 'id': busSnap.id} : null;
  }

  // --- Attendance (V3 Biometrics) ---
  Future<void> writeBiometricAttendance(String uid, String status) async {
    final dateKey = DateTime.now().toIso8601String().split('T').first; // 'YYYY-MM-DD'
    await _db.collection('attendance').doc(uid).collection('records').doc(dateKey).set({
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markStudentAttendance(String studentId, String busId, String date, String status) async {
    await _db.collection('attendance').add({
      'studentId': studentId,
      'busId': busId,
      'date': date,
      'status': status, // 'present', 'absent', 'late', 'half-day'
      'markedBy': 'driver',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> streamAttendanceRecords(String uid) {
    return _db.collection('attendance').doc(uid).collection('records').snapshots();
  }

  Future<void> reportMaintenance(String busId, String driverId, String description) async {
    await _db.collection('maintenance').add({
      'busId': busId,
      'driverId': driverId,
      'description': description,
      'status': 'reported',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }



  Future<void> updateBusStatus(String busId, String status) async {
    await _db.collection('buses').doc(busId).update({
      'status': status,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  // --- Complaints (V3 API) ---
  Future<void> submitComplaint({required String userId, required String role, required String message, required String type}) async {
    await _db.collection('complaints').add({
      'userId': userId,
      'role': role,
      'message': message,
      'type': type,
      'status': 'active',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> streamActiveComplaints() {
    return _db.collection('complaints').where('status', isEqualTo: 'active').orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> resolveComplaint(String complaintId) async {
    await _db.collection('complaints').doc(complaintId).update({'status': 'resolved'});
  }

  // --- Payments & Fees ---
  Stream<QuerySnapshot> streamStudentPayments(String studentId) {
    try {
      return _db.collection('payments')
          .where('studentId', isEqualTo: studentId)
          .orderBy('date', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint("Firestore Stream Error: $e");
      return const Stream.empty();
    }
  }

  Future<Map<String, dynamic>> getStudentFinancials(String studentId) async {
    try {
      final userDoc = await _db.collection('users').doc(studentId).get();
      if (!userDoc.exists) {
        return {
          'total_fee': 50000.0,
          'paid_amount': 0.0,
          'base_pending': 50000.0,
          'penalty_amount': 0.0,
          'total_payable': 50000.0,
        };
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final double basePending = (data['pending_amount'] is num) ? (data['pending_amount'] as num).toDouble() : 0.0;
      final double paidAmount = (data['paid_amount'] is num) ? (data['paid_amount'] as num).toDouble() : 0.0;
      final double totalFee = (data['total_fee'] is num) ? (data['total_fee'] as num).toDouble() : 0.0;
      final Timestamp? dueDateTimestamp = data['dueDate'];
      
      double penalty = 0.0;
      if (dueDateTimestamp != null && basePending > 0) {
        final dueDate = dueDateTimestamp.toDate();
        final now = DateTime.now();
        if (now.isAfter(dueDate)) {
          final daysLate = now.difference(dueDate).inDays;
          if (daysLate > 0) {
            penalty = daysLate * 50.0;
          }
        }
      }

      return {
        'total_fee': totalFee,
        'paid_amount': paidAmount,
        'base_pending': basePending,
        'penalty_amount': penalty,
        'total_payable': (basePending + penalty).clamp(0.0, double.infinity),
      };
    } catch (e) {
      debugPrint("Firestore GetFinancials Error: $e");
      throw Exception("Failed to load financial data. Please check your connection.");
    }
  }

  // --- Admin Stats ---
  Future<Map<String, dynamic>> getAdminFinancialStats() async {
    try {
      final studentsSnapshot = await _db.collection('users').where('role', isEqualTo: 'student').get();
      
      double totalReceived = 0.0;
      double totalPending = 0.0;
      double totalPenalty = 0.0;
      
      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        totalReceived += (data['paid_amount'] ?? 0.0);
        totalPending += (data['pending_amount'] ?? 0.0);
        
        final Timestamp? dueDate = data['dueDate'];
        if (dueDate != null && (data['pending_amount'] ?? 0.0) > 0) {
          final daysLate = DateTime.now().difference(dueDate.toDate()).inDays;
          if (daysLate > 0) {
            totalPenalty += (daysLate * 50.0);
          }
        }
      }
      
      return {
        'totalReceived': totalReceived,
        'totalPending': totalPending,
        'totalPenalty': totalPenalty,
        'studentCount': studentsSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint("Firestore AdminStats Error: $e");
      return {'totalReceived': 0.0, 'totalPending': 0.0, 'totalPenalty': 0.0, 'studentCount': 0};
    }
  }

  Stream<List<Map<String, dynamic>>> streamBuses() {
    return _db.collection('buses').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<void> deleteUser(String id) async {
    await _db.collection('users').doc(id).delete();
  }

  Future<void> recordPayment(Map<String, dynamic> paymentData) async {
    final String studentId = paymentData['studentId'];
    final double amountPaid = paymentData['amount'];

    try {
      await _db.runTransaction((transaction) async {
        final userRef = _db.collection('users').doc(studentId);
        final userSnap = await transaction.get(userRef);

        if (!userSnap.exists) throw Exception("User not found");

        final userData = userSnap.data() as Map<String, dynamic>;
        final double currentPaid = (userData['paid_amount'] ?? 0.0).toDouble();
        final double currentPending = (userData['pending_amount'] ?? 0.0).toDouble();

        // Update User Balances
        transaction.update(userRef, {
          'paid_amount': currentPaid + amountPaid,
          'pending_amount': currentPending - amountPaid > 0 ? currentPending - amountPaid : 0.0,
        });

        // Record Payment Entry
        final paymentRef = _db.collection('payments').doc();
        transaction.set(paymentRef, {
          ...paymentData,
          'date': FieldValue.serverTimestamp(),
        });
      });
      debugPrint("Payment recorded successfully for $studentId");
    } catch (e) {
      debugPrint("Payment Transaction Error: $e");
      throw Exception("Transaction failed: $e");
    }
  }

  // --- Routes & Stops ---
  Future<List<Map<String, dynamic>>> getRoutes() async {
    final snapshot = await _db.collection('routes').get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<Map<String, dynamic>?> getRoute(String routeId) async {
    final doc = await _db.collection('routes').doc(routeId).get();
    return doc.exists ? {...doc.data() as Map<String, dynamic>, 'id': doc.id} : null;
  }

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final snapshot = await _db.collection('payments').orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
  }

  Future<void> issueFine(String studentId, double amount, String reason) async {
    await _db.runTransaction((transaction) async {
      final studentRef = _db.collection('users').doc(studentId);
      final studentSnap = await transaction.get(studentRef);
      if (!studentSnap.exists) throw Exception("Student not found");
      
      final currentPending = (studentSnap.data()?['pending_amount'] ?? 0.0) as double;
      transaction.update(studentRef, {'pending_amount': currentPending + amount});
      
      final alertRef = _db.collection('alerts').doc();
      transaction.set(alertRef, {
        'userId': studentId,
        'type': 'FINE',
        'amount': amount,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      });
    });
  }

  Future<List<Map<String, dynamic>>> getAllAlerts() async {
    final snapshot = await _db.collection('alerts').orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
  }

  Future<void> resolveAlert(String alertId) async {
    await _db.collection('alerts').doc(alertId).update({'status': 'resolved'});
  }

  Future<void> reportSOS(String userId, double lat, double lng) async {
    await _db.collection('alerts').add({
      'userId': userId,
      'type': 'SOS',
      'latitude': lat,
      'longitude': lng,
      'status': 'active',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllRoutes() async {
    final snapshot = await _db.collection('routes').get();
    return snapshot.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
  }

  Future<void> addRoute(String name, List<Map<String, dynamic>> stops) async {
    await _db.collection('routes').add({
      'name': name,
      'stops': stops,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getParentChildren(String parentUid) async {
    final snapshot = await _db.collection('users')
        .where('parentIds', arrayContains: parentUid)
        .get();
    return snapshot.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList();
  }

  Future<void> linkChildToParent(String parentUid, String studentEmail) async {
    final studentQuery = await _db.collection('users')
        .where('email', isEqualTo: studentEmail)
        .where('role', isEqualTo: 'student')
        .limit(1)
        .get();
    
    if (studentQuery.docs.isEmpty) throw Exception("Student not found");
    
    final studentDoc = studentQuery.docs.first;
    await studentDoc.reference.update({
      'parentIds': FieldValue.arrayUnion([parentUid]),
    });
  }
}
