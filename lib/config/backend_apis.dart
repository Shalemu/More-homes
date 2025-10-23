import 'package:http/http.dart' as http;

class ApiConstants {
  static const String localIp = "10.120.47.43";
  static const String publicIp = "161.97.65.175";
  static const String baseUrl = 'http://$localIp:9099';

  // You can also add endpoints here
  static const String login = '$baseUrl/auth/login/';
  static const String registration = '$baseUrl/auth/registration/';
  static const String user = '$baseUrl/auth/user';
  static const String otpVerify = '$baseUrl/auth/otp/verify/';
  static const String otpRequest = '$baseUrl/auth/otp/request/';
  static const String getProperties = '$baseUrl/api/properties/';
  static const String postProperties = '$baseUrl/api/properties/';
  static const String propertyDetail = '$baseUrl/api/properties/detail/';
  static const String booking = '$baseUrl/api/book/property/';
  static const String airbnbBooking = '$baseUrl/api/airbnb-bookings/';
}

class MyHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Bypass SSL verification (DANGEROUS for production!)
    request.headers['Accept'] = 'application/json';
    return _inner.send(request);
  }
}
