class ApiResponse<T> {
  final int totalItem;
  final String detail;
  final int statusCode;
  final String? access;
  final String? refresh;
  final T? data;

  ApiResponse({
    required this.totalItem,
    required this.detail,
    required this.statusCode,
    this.refresh,
    this.access,
    this.data,
  });

  // Factory to parse JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponse<T>(
      totalItem: json['total_item'] ?? 0,
      detail: json['detail'] ?? '',
      statusCode: json['status_code'] ?? '',
      refresh: json['refresh'] ?? '',
      access: json['access'] ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T value) toJsonT) {
    return {
      'total_item': totalItem,
      'detail': detail,
      'status_code': statusCode,
      'access': access,
      'refresh': refresh,
      'data': data != null ? toJsonT(data!) : null,
    };
  }
}
