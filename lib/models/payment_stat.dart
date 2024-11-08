// Payment statistics model
class PaymentStats {
  final double totalReceived;
  final double totalExpected;
  final double paymentRate;
  final int onTimePayments;
  final int latePayments;

  PaymentStats({
    required this.totalReceived,
    required this.totalExpected,
    required this.paymentRate,
    required this.onTimePayments,
    required this.latePayments,
  });

  factory PaymentStats.empty() {
    return PaymentStats(
      totalReceived: 0,
      totalExpected: 0,
      paymentRate: 0,
      onTimePayments: 0,
      latePayments: 0,
    );
  }
}