import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';

final paymentServiceProvider =
    Provider<PaymentService>((ref) => PaymentService());

final paymentsProvider = FutureProvider<List<Payment>>((ref) {
  final service = ref.watch(paymentServiceProvider);
  return service.listPayments();
});
