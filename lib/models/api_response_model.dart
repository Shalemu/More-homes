class ApiResponse<T> {
  final int totalItem;
  final String detail;
  final int statusCode;

  final String? access;
  final String? refresh;
  final T? data;

 
  final String? msg;


  final String? currentVersion;
  final String? latestVersion;
  final bool? forceUpdate;

  ApiResponse({
    required this.totalItem,
    required this.detail,
    required this.statusCode,
    this.access,
    this.refresh,
    this.data,
    this.msg,
    this.currentVersion,
    this.latestVersion,
    this.forceUpdate,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponse<T>(
      totalItem: json['total_item'] ?? 0,

      // fallback priority: msg > detail
      detail: json['detail'] ?? json['msg'] ?? '',

      statusCode: json['status_code'] is int
          ? json['status_code']
          : int.tryParse(json['status_code'].toString()) ?? 0,

      access: json['access'],
      refresh: json['refresh'],

      data: json['data'] != null ? fromJsonT(json['data']) : null,

    
      msg: json['msg'],

     
      currentVersion: json['current_version'],
      latestVersion: json['latest_version'],
      forceUpdate: json['force_update'] ?? false,
    );
  }

  Map<String, dynamic> toJson(
    Map<String, dynamic> Function(T value) toJsonT,
  ) {
    return {
      'total_item': totalItem,
      'detail': detail,
      'status_code': statusCode,
      'access': access,
      'refresh': refresh,
      'msg': msg,
      'current_version': currentVersion,
      'latest_version': latestVersion,
      'force_update': forceUpdate,
      'data': data != null ? toJsonT(data!) : null,
    };
  }
}