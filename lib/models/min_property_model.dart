class MiniProperty {
  final String uuid;
  final String title; // <-- this will map from JSON 'name'
  final String type;
  final String address;
  final String price;
  final String thumbnail;

  MiniProperty({
    required this.uuid,
    required this.title,
    required this.type,
    required this.address,
    required this.price,
    required this.thumbnail,
  });

  factory MiniProperty.fromJson(Map<String, dynamic> json) {
    return MiniProperty(
      uuid: json['uuid'] ?? "",
      title: json['name'] ?? "No Title", // <-- map 'name' from backend
      type: json['type'] ?? "",
      address: json['address'] ?? "",
      price: json['price']?.toString() ?? "0",
      thumbnail: json['thumbnail'] ?? "",
    );
  }
}
