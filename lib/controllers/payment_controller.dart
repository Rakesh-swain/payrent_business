import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:payrent_business/models/payment_chart_data.dart';
import 'package:payrent_business/models/payment_model.dart';
import '../controllers/auth_controller.dart';
import '../controllers/tenant_controller.dart';
import '../services/firestore_service.dart';

class PaymentController extends GetxController {
  static PaymentController get to => Get.find();

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();
  final TenantController _tenantController = Get.find<TenantController>();
  final RxList<PaymentModel> allPayments = <PaymentModel>[].obs;
  // Observables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;
  final RxList<DocumentSnapshot> payments = <DocumentSnapshot>[].obs;
  final RxList<DocumentSnapshot> filteredPayments = <DocumentSnapshot>[].obs;

  // Dashboard data
  final RxInt rentalApplicationCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPayments();
    fetchAllPayments();
  }

  void fetchAllPayments() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    isLoading.value = true;

    _firestore
        .collection('users')
        .doc(userId)
        .collection('payment')
        .snapshots()
        .listen(
          (snapshot) {
            allPayments.value = snapshot.docs.map((doc) {
              return PaymentModel.fromMap(doc.data(), doc.id);
            }).toList();

            isLoading.value = false;
            print('Fetched ${allPayments.length} payments');
          },
          onError: (error) {
            isLoading.value = false;
            print('Error fetching payments: $error');
          },
        );
  }

  // Get total pending payments for today
  double getTotalPendingPayments(String status) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return allPayments
        .where((payment) {
          if (payment.status.toLowerCase() == status) return true;

          final paymentDate = payment.date;
          return paymentDate.isAfter(
                startOfDay.subtract(const Duration(seconds: 1)),
              ) &&
              paymentDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
        })
        .fold(0.0, (sum, payment) {
          final amount = double.tryParse(payment.amount.toString()) ?? 0.0;
          return sum + amount;
        });
  }

  // Get total overdue payments
  double getTotalOverduePayments() {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    return allPayments
        .where((payment) {
          if (payment.status.toLowerCase() == 'collected' ||
              payment.status.toLowerCase() == 'pending')
            return false;
          print(payment.date.isBefore(startOfToday));
          return payment.date.isBefore(startOfToday);
        })
        .fold(0.0, (sum, payment) {
          final amount = double.tryParse(payment.amount.toString()) ?? 0.0;
          return sum + amount;
        });
  }

  // Get total collected payments
  double getTotalCollectedPayments() {
    return allPayments
        .where((payment) => payment.status.toLowerCase() == 'collected')
        .fold(0.0, (sum, payment) {
          final amount = double.tryParse(payment.amount.toString()) ?? 0.0;
          return sum + amount;
        });
  }

  // Fetch payments for current landlord from users subcollection
  Future<void> fetchPayments() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return;
      }

      final uid = _authController.firebaseUser.value!.uid;

      // Query payments from user's subcollection
      final querySnapshot = await _firestoreService.querySubcollectionDocuments(
        parentCollection: 'users',
        parentDocumentId: uid,
        subcollection: 'payments',
        orderBy: 'dueDate',
        descending: true,
      );

      payments.value = querySnapshot.docs;
      filteredPayments.value = querySnapshot.docs;
    } catch (e) {
      errorMessage.value = 'Failed to fetch payments';
      print('Error fetching payments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Create a new payment
  Future<void> createPayment({
    required String tenantId,
    required String propertyId,
    required double amount,
    required DateTime dueDate,
    String? description,
    String status = 'pending',
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return;
      }

      final uid = _authController.firebaseUser.value!.uid;

      // Get tenant details
      final tenant = await _tenantController.getTenantById(tenantId);

      if (tenant == null || !tenant.exists) {
        errorMessage.value = 'Invalid tenant selected';
        return;
      }

      final tenantData = tenant.data() as Map<String, dynamic>;
      final tenantName = '${tenantData['firstName']} ${tenantData['lastName']}';
      final propertyName = tenantData['propertyName'] as String? ?? '';
      final unitNumber = tenantData['unitNumber'] as String? ?? '';

      // Calculate due date info
      final formattedDueDate = DateFormat('yyyy-MM-dd').format(dueDate);
      final month = DateFormat('MMMM').format(dueDate);
      final year = DateFormat('yyyy').format(dueDate);

      // Create payment document in user's subcollection
      await _firestoreService.createSubcollectionDocument(
        parentCollection: 'users',
        parentDocumentId: uid,
        subcollection: 'payments',
        data: {
          'tenantId': tenantId,
          'tenantName': tenantName,
          'landlordId': uid,
          'propertyId': propertyId,
          'propertyName': propertyName,
          'unitNumber': unitNumber,
          'amount': amount,
          'dueDate': Timestamp.fromDate(dueDate),
          'formattedDueDate': formattedDueDate,
          'month': month,
          'year': year,
          'description': description ?? 'Monthly Rent',
          'status': status,
          'paymentDate': status == 'paid' ? Timestamp.now() : null,
          'paymentMethod': null,
          'transactionId': null,
          'notes': null,
          'isLate': false,
        },
      );

      successMessage.value = 'Payment created successfully';
      fetchPayments(); // Refresh payments list
    } catch (e) {
      errorMessage.value = 'Failed to create payment';
      print('Error creating payment: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Generate payments for all active tenants based on their payment frequency
  Future<void> generatePayments({
    required DateTime month,
    String? description,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return;
      }

      final uid = _authController.firebaseUser.value!.uid;

      // Get all active tenants
      await _tenantController.fetchTenants();
      final activeTenants = _tenantController.tenants.where((tenant) {
        final data = tenant.data() as Map<String, dynamic>;
        return (data['status'] as String? ?? '') == 'active' &&
            (data['isArchived'] as bool? ?? false) == false;
      }).toList();

      if (activeTenants.isEmpty) {
        successMessage.value = 'No active tenants found';
        return;
      }

      int createdCount = 0;

      // Create payment for each tenant based on their payment frequency
      for (final tenant in activeTenants) {
        final data = tenant.data() as Map<String, dynamic>;

        // Get tenant details
        final tenantId = tenant.id;
        final propertyId = data['propertyId'] as String? ?? '';
        final rentAmount = (data['rentAmount'] is int)
            ? (data['rentAmount'] as int).toDouble()
            : (data['rentAmount'] ?? 0.0);
        final rentDueDay = data['rentDueDay'] as int? ?? 1;
        final paymentFrequency =
            data['paymentFrequency'] as String? ?? 'monthly';
        final tenantName = '${data['firstName']} ${data['lastName']}';
        final propertyName = data['propertyName'] as String? ?? '';
        final unitNumber = data['unitNumber'] as String? ?? '';

        // Get lease dates
        DateTime? leaseStartDate;
        DateTime? leaseEndDate;

        if (data['leaseStartDate'] != null) {
          leaseStartDate = (data['leaseStartDate'] as Timestamp).toDate();
        }

        if (data['leaseEndDate'] != null) {
          leaseEndDate = (data['leaseEndDate'] as Timestamp).toDate();
        }

        // Calculate payment data using tenant controller
        if (leaseStartDate != null && leaseEndDate != null) {
          final paymentData = _tenantController.calculatePaymentData(
            paymentFrequency: paymentFrequency,
            leaseStartDate: leaseStartDate,
            leaseEndDate: leaseEndDate,
            rentAmount: rentAmount,
            currentDate: month,
          );

          final dueDate = paymentData['nextPaymentDate'] as DateTime;
          final formattedDueDate = DateFormat('yyyy-MM-dd').format(dueDate);
          final monthName = DateFormat('MMMM').format(dueDate);
          final year = DateFormat('yyyy').format(dueDate);

          // Check if payment already exists for this tenant and due date
          final existingPayments = await _firestoreService
              .querySubcollectionDocuments(
                parentCollection: 'users',
                parentDocumentId: uid,
                subcollection: 'payments',
                filters: [
                  ['tenantId', tenantId],
                  ['formattedDueDate', formattedDueDate],
                ],
              );

          if (existingPayments.docs.isNotEmpty) {
            print(
              'Payment already exists for tenant $tenantName for ${paymentData['formattedNextPaymentDate']}',
            );
            continue;
          }

          // Create payment document in user's subcollection
          await _firestoreService.createSubcollectionDocument(
            parentCollection: 'users',
            parentDocumentId: uid,
            subcollection: 'payments',
            data: {
              'tenantId': tenantId,
              'tenantName': tenantName,
              'landlordId': uid,
              'propertyId': propertyId,
              'propertyName': propertyName,
              'unitNumber': unitNumber,
              'amount': rentAmount,
              'dueDate': Timestamp.fromDate(dueDate),
              'formattedDueDate': formattedDueDate,
              'month': monthName,
              'year': year,
              'paymentFrequency': paymentFrequency,
              'periodDescription': paymentData['periodDescription'],
              'description':
                  description ?? '${paymentData['periodDescription']}ly Rent',
              'status': paymentData['paymentStatus'],
              'paymentDate': null,
              'paymentMethod': null,
              'transactionId': null,
              'notes': null,
              'isLate': paymentData['isOverdue'],
              'isDueToday': paymentData['isDueToday'],
              'daysUntilDue': paymentData['daysUntilDue'],
            },
          );

          createdCount++;
        }
      }

      successMessage.value =
          'Created $createdCount payments for ${DateFormat('MMMM yyyy').format(month)}';
      fetchPayments(); // Refresh payments list
    } catch (e) {
      errorMessage.value = 'Failed to generate payments';
      print('Error generating payments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Generate monthly payments for all active tenants (legacy method for backwards compatibility)
  Future<void> generateMonthlyPayments({
    required DateTime month,
    String? description,
  }) async {
    await generatePayments(month: month, description: description);
  }

  // Update payment status
  Future<void> updatePaymentStatus({
    required String paymentId,
    required String status,
    String? paymentMethod,
    String? transactionId,
    String? notes,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
      final Map<String, dynamic> updateData = {'status': status};

      if (status == 'paid') {
        updateData['paymentDate'] = Timestamp.now();
      }

      if (paymentMethod != null) updateData['paymentMethod'] = paymentMethod;
      if (transactionId != null) updateData['transactionId'] = transactionId;
      if (notes != null) updateData['notes'] = notes;

      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return;
      }

      final uid = _authController.firebaseUser.value!.uid;

      // Update the document in user's subcollection
      await _firestoreService.updateSubcollectionDocument(
        parentCollection: 'users',
        parentDocumentId: uid,
        subcollection: 'payments',
        documentId: paymentId,
        data: updateData,
      );

      successMessage.value = 'Payment status updated to $status';
      fetchPayments(); // Refresh payments list
    } catch (e) {
      errorMessage.value = 'Failed to update payment status';
      print('Error updating payment status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Delete payment
  Future<void> deletePayment(String paymentId) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      if (_authController.firebaseUser.value == null) {
        errorMessage.value = 'User not logged in';
        return;
      }

      final uid = _authController.firebaseUser.value!.uid;

      // Delete the payment document from user's subcollection
      await _firestoreService.deleteSubcollectionDocument(
        parentCollection: 'users',
        parentDocumentId: uid,
        subcollection: 'payments',
        documentId: paymentId,
      );

      successMessage.value = 'Payment deleted successfully';
      fetchPayments(); // Refresh payments list
    } catch (e) {
      errorMessage.value = 'Failed to delete payment';
      print('Error deleting payment: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Filter payments by status
  void filterPaymentsByStatus(String status) {
    if (status.isEmpty || status.toLowerCase() == 'all') {
      filteredPayments.value = payments;
      return;
    }

    filteredPayments.value = payments.where((payment) {
      final data = payment.data() as Map<String, dynamic>;
      return data['status'] == status;
    }).toList();
  }

  // Filter payments by property
  void filterPaymentsByProperty(String propertyId) {
    if (propertyId.isEmpty) {
      filteredPayments.value = payments;
      return;
    }

    filteredPayments.value = payments.where((payment) {
      final data = payment.data() as Map<String, dynamic>;
      return data['propertyId'] == propertyId;
    }).toList();
  }

  // Filter payments by tenant
  void filterPaymentsByTenant(String tenantId) {
    if (tenantId.isEmpty) {
      filteredPayments.value = payments;
      return;
    }

    filteredPayments.value = payments.where((payment) {
      final data = payment.data() as Map<String, dynamic>;
      return data['tenantId'] == tenantId;
    }).toList();
  }

  // Filter payments by date range
  void filterPaymentsByDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      filteredPayments.value = payments;
      return;
    }

    filteredPayments.value = payments.where((payment) {
      final data = payment.data() as Map<String, dynamic>;
      final dueDate = (data['dueDate'] as Timestamp).toDate();

      if (start != null && end != null) {
        return dueDate.isAfter(start) &&
            dueDate.isBefore(end.add(const Duration(days: 1)));
      } else if (start != null) {
        return dueDate.isAfter(start);
      } else if (end != null) {
        return dueDate.isBefore(end.add(const Duration(days: 1)));
      }

      return false;
    }).toList();
  }

  // Search payments
  void searchPayments(String searchTerm) {
    if (searchTerm.isEmpty) {
      filteredPayments.value = payments;
      return;
    }

    final searchTermLower = searchTerm.toLowerCase();

    filteredPayments.value = payments.where((payment) {
      final data = payment.data() as Map<String, dynamic>;

      final tenantName = (data['tenantName'] as String? ?? '').toLowerCase();
      final propertyName = (data['propertyName'] as String? ?? '')
          .toLowerCase();
      final unitNumber = (data['unitNumber'] as String? ?? '').toLowerCase();
      final month = (data['month'] as String? ?? '').toLowerCase();
      final year = (data['year'] as String? ?? '').toLowerCase();
      final monthYear = '$month $year'.toLowerCase();

      return tenantName.contains(searchTermLower) ||
          propertyName.contains(searchTermLower) ||
          unitNumber.contains(searchTermLower) ||
          monthYear.contains(searchTermLower);
    }).toList();
  }

  // Get payment summary by property
  Map<String, dynamic> getPaymentSummaryByProperty(String propertyId) {
    // Filter payments for the selected property
    final propertyPayments = payments.where((payment) {
      final data = payment.data() as Map<String, dynamic>;
      return data['propertyId'] == propertyId;
    }).toList();

    // Calculate totals
    double totalDue = 0.0;
    double totalPaid = 0.0;
    double totalPending = 0.0;
    double totalLate = 0.0;

    for (final payment in propertyPayments) {
      final data = payment.data() as Map<String, dynamic>;
      final amount = data['amount'] as double? ?? 0.0;
      final status = data['status'] as String? ?? '';
      final isLate = data['isLate'] as bool? ?? false;

      totalDue += amount;

      if (status == 'paid') {
        totalPaid += amount;
      } else if (status == 'pending') {
        totalPending += amount;
      }

      if (isLate) {
        totalLate += amount;
      }
    }

    return {
      'totalDue': totalDue,
      'totalPaid': totalPaid,
      'totalPending': totalPending,
      'totalLate': totalLate,
      'collectionRate': totalDue > 0 ? (totalPaid / totalDue) * 100 : 0.0,
      'paymentCount': propertyPayments.length,
    };
  }

  // Get payment summary by month
  Map<String, dynamic> getPaymentSummaryByMonth(String month, String year) {
    // Filter payments for the selected month/year
    final monthPayments = payments.where((payment) {
      final data = payment.data() as Map<String, dynamic>;
      return data['month'] == month && data['year'] == year;
    }).toList();

    // Calculate totals
    double totalDue = 0.0;
    double totalPaid = 0.0;
    double totalPending = 0.0;
    double totalLate = 0.0;

    for (final payment in monthPayments) {
      final data = payment.data() as Map<String, dynamic>;
      final amount = data['amount'] as double? ?? 0.0;
      final status = data['status'] as String? ?? '';
      final isLate = data['isLate'] as bool? ?? false;

      totalDue += amount;

      if (status == 'paid') {
        totalPaid += amount;
      } else if (status == 'pending') {
        totalPending += amount;
      }

      if (isLate) {
        totalLate += amount;
      }
    }

    return {
      'totalDue': totalDue,
      'totalPaid': totalPaid,
      'totalPending': totalPending,
      'totalLate': totalLate,
      'collectionRate': totalDue > 0 ? (totalPaid / totalDue) * 100 : 0.0,
      'paymentCount': monthPayments.length,
    };
  }

  // Calculate overall collection rate
  double get overallCollectionRate {
    double totalDue = 0.0;
    double totalPaid = 0.0;

    for (final payment in payments) {
      final data = payment.data() as Map<String, dynamic>;
      final amount = data['amount'] as double? ?? 0.0;
      final status = data['status'] as String? ?? '';

      totalDue += amount;

      if (status == 'paid') {
        totalPaid += amount;
      }
    }

    return totalDue > 0 ? (totalPaid / totalDue) * 100 : 0.0;
  }

  // Count payments by status
  Map<String, int> getPaymentCountByStatus() {
    final Map<String, int> statusCounts = {
      'paid': 0,
      'pending': 0,
      'late': 0,
      'cancelled': 0,
    };

    for (final payment in payments) {
      final data = payment.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';
      final isLate = data['isLate'] as bool? ?? false;

      if (status == 'pending' && isLate) {
        statusCounts['late'] = statusCounts['late']! + 1;
      } else if (statusCounts.containsKey(status)) {
        statusCounts[status] = statusCounts[status]! + 1;
      }
    }

    return statusCounts;
  }

  // Dashboard methods

  // Get total collected payments (sum of all paid payments)
  // double getTotalCollectedPayments() {
  //   double total = 0.0;
  //   for (final payment in payments) {
  //     final data = payment.data() as Map<String, dynamic>;
  //     final status = data['status'] as String? ?? '';
  //     final amount = data['amount'] as double? ?? 0.0;

  //     if (status == 'paid') {
  //       total += amount;
  //     }
  //   }
  //   return total;
  // }

  // // Get total pending payments (sum of all pending payments)
  // double getTotalPendingPayments() {
  //   double total = 0.0;
  //   for (final payment in payments) {
  //     final data = payment.data() as Map<String, dynamic>;
  //     final status = data['status'] as String? ?? '';
  //     final amount = data['amount'] as double? ?? 0.0;
  //     final isLate = data['isLate'] as bool? ?? false;

  //     if (status == 'pending' && !isLate) {
  //       total += amount;
  //     }
  //   }
  //   return total;
  // }

  // // Get total overdue payments (sum of all late payments)
  // double getTotalOverduePayments() {
  //   double total = 0.0;
  //   for (final payment in payments) {
  //     final data = payment.data() as Map<String, dynamic>;
  //     final status = data['status'] as String? ?? '';
  //     final amount = data['amount'] as double? ?? 0.0;
  //     final isLate = data['isLate'] as bool? ?? false;

  //     if ((status == 'pending' && isLate) || status == 'late') {
  //       total += amount;
  //     }
  //   }
  //   return total;
  // }

  // Get chart data for dashboard
  Map<String, List<FlSpot>> getChartData({int months = 6}) {
    // Initialize result maps
    final Map<String, List<FlSpot>> result = {
      'totalIncome': [],
      'netIncome': [],
    };

    // Get the current date
    final now = DateTime.now();

    // Collect data for the specified number of months
    for (int i = 0; i < months; i++) {
      // Calculate month and year for this data point (starting from oldest)
      final month = now.month - months + i + 1;
      final year = now.year + (month <= 0 ? -1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;

      final monthName = DateFormat(
        'MMMM',
      ).format(DateTime(2022, adjustedMonth, 1));
      final yearStr = year.toString();

      // Get payment summary for this month
      final monthSummary = getPaymentSummaryByMonth(monthName, yearStr);

      // Calculate total income and net income (in thousands for chart)
      final totalIncome = monthSummary['totalDue'] as double;
      final netIncome = monthSummary['totalPaid'] as double;

      // Add data points (convert to thousands for chart)
      result['totalIncome']!.add(FlSpot(i.toDouble(), totalIncome / 1000));
      result['netIncome']!.add(FlSpot(i.toDouble(), netIncome / 1000));
    }

    // If there's no data, provide some sample data for visualization
    if (result['totalIncome']!.isEmpty) {
      result['totalIncome'] = [
        const FlSpot(0, 20),
        const FlSpot(1, 25),
        const FlSpot(2, 22),
        const FlSpot(3, 30),
        const FlSpot(4, 35),
        const FlSpot(5, 28),
      ];

      result['netIncome'] = [
        const FlSpot(0, 10),
        const FlSpot(1, 16),
        const FlSpot(2, 15),
        const FlSpot(3, 22),
        const FlSpot(4, 25),
        const FlSpot(5, 20),
      ];
    }

    return result;
  }

  // Get count of properties with overdue payments
  int getOverduePropertiesCount() {
    final Set<String> overdueProperties = {};

    for (final payment in payments) {
      final data = payment.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';
      final isLate = data['isLate'] as bool? ?? false;
      final propertyId = data['propertyId'] as String? ?? '';

      if ((status == 'pending' && isLate) || status == 'late') {
        if (propertyId.isNotEmpty) {
          overdueProperties.add(propertyId);
        }
      }
    }

    return overdueProperties.length;
  }

  Stream<List<PaymentChartData>> getPaymentChartData({
    required int months, // 3, 6, 12
  }) async* {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      yield [];
      return;
    }

    final now = DateTime.now();
    // Calculate start date based on number of months
    final startDate = DateTime(
      now.year,
      now.month,
      1,
    ).subtract(Duration(days: 30 * (months - 1))); // approximate
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    print('Fetching paid payments from: $startDate to $endDate');

    final snapshots = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('payments')
        .where('status', isEqualTo: 'paid') // only paid payments
        // .where('payment_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        // .where('payment_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        // .orderBy('payment_date')
        .where(
          'due_date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('due_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('due_date')
        .snapshots();

    await for (final snapshot in snapshots) {
      print('Fetched ${snapshot.docs.length} paid documents');

      // Generate all months in the range
      final List<String> allMonths = [];
      final Map<String, double> monthlyTotals = {};

      for (int i = months - 1; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthName = DateFormat('MMM').format(monthDate);
        allMonths.add(monthName);
        monthlyTotals[monthName] = 0.0;
      }

      // Populate totals
      for (var doc in snapshot.docs) {
        final data = doc.data();

        final amountStr = data['amount']?.toString() ?? '0';
        final amount = double.tryParse(amountStr) ?? 0.0;
        print(amount);
        // final timestamp = data['payment_date'] as Timestamp?;
        final timestamp = data['due_date'] as Timestamp?;
        if (timestamp == null) continue;
        final date = timestamp.toDate();

        final monthKey = DateFormat('MMM').format(date);

        if (monthlyTotals.containsKey(monthKey)) {
          monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + amount;
        }
      }

      // Convert to chart data
      final chartData = allMonths
          .map(
            (month) => PaymentChartData(
              month: month,
              total: monthlyTotals[month] ?? 0,
            ),
          )
          .toList();

      print('Chart Data: $chartData');

      yield chartData;
    }
  }

  Future<double> getTotalCollectedPaymentsForMonths(int selectedIndex) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0.0;

    // Map index to months
    int months;
    switch (selectedIndex) {
      case 0:
        months = 3; // 3 months
        break;
      case 1:
        months = 6; // 6 months
        break;
      case 2:
        months = 12; // 1 year
        break;
      default:
        months = 3;
    }

    final now = DateTime.now();
    final startDate = DateTime(
      now.year,
      now.month,
      1,
    ).subtract(Duration(days: 30 * (months - 1)));

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('payments')
        .where('status', isEqualTo: 'paid')
        .where(
          'due_date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('due_date', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .get();

    double total = 0.0;
    for (var doc in querySnapshot.docs) {
      final amount = double.tryParse(doc['amount']?.toString() ?? '0') ?? 0.0;
      total += amount;
    }

    return total;
  }

  Future<double> getTotalPayments({required String filter}) async {
    double total = 0.0;

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('payments');

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(
        now.year,
        now.month + 1,
        1,
      ); // exclusive of next month

      switch (filter.toLowerCase()) {
        case 'total_earnings_this_month':
          query = query
              .where('status', isEqualTo: 'paid')
              .where(
                'due_date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
              )
              .where('due_date', isLessThan: Timestamp.fromDate(endOfMonth));
          break;

        case 'due_rent_today':
          query = query
              .where(
                'due_date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('due_date', isLessThan: Timestamp.fromDate(endOfDay));
          break;

        case 'overdue':
          query = query
              .where('status', isEqualTo: 'pending')
              .where('due_date', isLessThan: Timestamp.fromDate(startOfDay));
          break;

        case 'collected_today':
          query = query
              .where('status', isEqualTo: 'paid')
              .where(
                'due_date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('due_date', isLessThan: Timestamp.fromDate(endOfDay));
          break;

        default:
          // fallback: fetch all payments
          query = query;
      }

      final snapshot = await query.get();
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] ?? 0);
      }
    } catch (e) {
      print('Error fetching total payments: $e');
    }

    return total;
  }
}
