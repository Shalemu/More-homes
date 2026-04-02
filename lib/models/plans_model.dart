class PlanModel {
  final String uuid;
  final String name;
  final String price;
  final String billingCycle;
  final String discount;

  PlanModel({
    required this.uuid,
    required this.name,
    required this.price,
    required this.billingCycle,
    required this.discount,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      uuid: json['uuid'],
      name: json['name'],
      price: json['actual_price'],
      billingCycle: json['billing_cycle_name'],
      discount: json['discount_per'],
    );
  }
}