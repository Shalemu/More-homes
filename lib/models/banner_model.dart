class BannerModel {
  final String image;
  final String title;

  BannerModel({
    required this.image,
    required this.title,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      image: json['ads_url'] ?? '',
      title: json['title'] ?? '',
    );
  }

 
  Map<String, dynamic> toJson() {
    return {
      'ads_url': image,
      'title': title,
    };
  }
}