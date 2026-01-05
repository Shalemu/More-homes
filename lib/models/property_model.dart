import 'package:intl/intl.dart';

class PropertyModel {
  final String uuid;
  final String name;
  final String type;
  final String address;
  final String price;
  final String maintenance; // optional legacy field
  final String? thumbnail;
  final bool isBooked;
  final String description;
  final String totalPrice;
  final String latitude;
  final String longitude;
  final String region;
  final String district;
  final String category;

  final String uploaderName;
  final String uploaderPhone;
  final String uploaderRole;
  final String? uploaderId;
  final String? uploaderImageUrl;

  final List<String> images; // image URLs
  final List<String> base64Images; // for upload
  final List<String> facilities;

 
  final List<Map<String, String>> propertyCosts;
  final double totalCost;

  final DateTime? createdAt;

  PropertyModel({
    required this.uuid,
    required this.name,
    required this.type,
    required this.address,
    required this.price,
    this.maintenance = "1.00",
    this.thumbnail,
    required this.isBooked,
    required this.description,
    required this.totalPrice,
    required this.latitude,
    required this.longitude,
    required this.region,
    required this.district,
    required this.category,
    required this.uploaderName,
    required this.uploaderPhone,
    required this.uploaderRole,
    this.uploaderId,
    this.uploaderImageUrl,
    this.images = const [],
    this.base64Images = const [],
    this.facilities = const [],

   
    this.propertyCosts = const [],
    this.totalCost = 0.0,

    this.createdAt,
  });

  // ---------------- COPY WITH ----------------
  PropertyModel copyWith({
    String? name,
    String? type,
    String? address,
    String? price,
    String? maintenance,
    String? thumbnail,
    bool? isBooked,
    String? description,
    String? totalPrice,
    String? latitude,
    String? longitude,
    String? region,
    String? district,
    String? category,
    String? uploaderName,
    String? uploaderPhone,
    String? uploaderRole,
    String? uploaderId,
    String? uploaderImageUrl,
    List<String>? images,
    List<String>? base64Images,
    List<String>? facilities,
    List<Map<String, String>>? propertyCosts,
    double? totalCost,
    DateTime? createdAt,
  }) {
    return PropertyModel(
      uuid: uuid,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      price: price ?? this.price,
      maintenance: maintenance ?? this.maintenance,
      thumbnail: thumbnail ?? this.thumbnail,
      isBooked: isBooked ?? this.isBooked,
      description: description ?? this.description,
      totalPrice: totalPrice ?? this.totalPrice,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      region: region ?? this.region,
      district: district ?? this.district,
      category: category ?? this.category,
      uploaderName: uploaderName ?? this.uploaderName,
      uploaderPhone: uploaderPhone ?? this.uploaderPhone,
      uploaderRole: uploaderRole ?? this.uploaderRole,
      uploaderId: uploaderId ?? this.uploaderId,
      uploaderImageUrl: uploaderImageUrl ?? this.uploaderImageUrl,
      images: images ?? this.images,
      base64Images: base64Images ?? this.base64Images,
      facilities: facilities ?? this.facilities,

     
      propertyCosts: propertyCosts ?? this.propertyCosts,
      totalCost: totalCost ?? this.totalCost,

      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ---------------- FROM JSON ----------------
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    final imageList =
        (json['property_images'] ?? json['images'] ?? []) as List<dynamic>;

    final parsedImages = imageList
        .map((img) =>
            img['image_url'] ?? img['image'] ?? '')
        .where((e) => e.toString().isNotEmpty)
        .map((e) => e.toString())
        .toList();

    final facilities = (json['facilities'] as List<dynamic>? ?? [])
        .map((f) => f['name']?.toString() ?? '')
        .where((n) => n.isNotEmpty)
        .toList();


    final propertyCosts = (json['property_costs'] as List<dynamic>? ?? [])
        .map((c) => {
              'name': c['name'].toString(),
              'amount': c['amount'].toString(),
            })
        .toList();

    return PropertyModel(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      address: json['address'] ?? '',
      price: json['price']?.toString() ?? '',
      maintenance: json['maintenance']?.toString() ?? "1.00",
      thumbnail: json['thumbnail'],
      isBooked: json['is_booked'] ?? false,
      description: json['description'] ?? '',
      totalPrice: json['total_price']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      region: json['region'] ?? '',
      district: json['district'] ?? '',
      category: json['category'] ?? '',
      uploaderName: json['uploader_name'] ?? '',
      uploaderPhone: json['uploader_phone'] ?? '',
      uploaderRole: json['uploader_role'] ?? '',
      uploaderId: json['uploader']?.toString(),
      uploaderImageUrl: json['uploader_image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      images: parsedImages,
      facilities: facilities,

      propertyCosts: propertyCosts,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ---------------- TO JSON ----------------
  Map<String, dynamic> toJson({bool forUpload = false}) {
    final data = {
      'uuid': uuid,
      'name': name,
      'type': type,
      'address': address,
      'price': price,
      'maintenance': maintenance,
      'thumbnail': thumbnail,
      'is_booked': isBooked,
      'description': description,
      'total_price': totalPrice,
      'latitude': latitude,
      'longitude': longitude,
      'region': region,
      'district': district,
      'category': category,
      'uploader_name': uploaderName,
      'uploader_phone': uploaderPhone,
      'uploader_role': uploaderRole,
      'uploader': uploaderId,
      'uploader_image_url': uploaderImageUrl,
      'facilities': facilities.map((f) => {'name': f}).toList(),

     
      'property_costs': propertyCosts,
      'total_cost': totalCost,

      'created_at': createdAt?.toIso8601String(),
    };

    if (forUpload && base64Images.isNotEmpty) {
      data['images'] =
          base64Images.map((b64) => {'image': b64}).toList();
    } else {
      data['property_images'] =
          images.map((url) => {'image_url': url}).toList();
    }

    return data;
  }

  // ---------------- FORMAT DATE ----------------
  String get formattedUploadTime {
    if (createdAt == null) return '';
    return DateFormat('dd MMM yyyy, hh:mm a').format(createdAt!);
  }
}
