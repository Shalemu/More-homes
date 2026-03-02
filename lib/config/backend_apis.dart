import 'package:http/http.dart' as http;
class ApiConstants {
  static const String baseUrl = "https://morehomes.co.tz";


  // Auth
  static const String login = "$baseUrl/auth/login/";
  static const String registration = "$baseUrl/auth/registration/";
  static const String user = "$baseUrl/auth/user/";
  static const String otpVerify = "$baseUrl/auth/otp/verify/";
  static const String otpRequest = "$baseUrl/auth/otp/request/";
  static const String otpRequestForPassword = "$baseUrl/auth/request/reset-token";
  static const String resetPassword = "$baseUrl/auth/reset/user-password";
  static const String changePassword = "$baseUrl/auth/user-change-password";
  static const String roles = "$baseUrl/auth/roles/";

  // Properties
  static const String getProperties = "$baseUrl/homes/properties/"; // All public properties
  static const String getUploaderProperties = "$baseUrl/homes/uploader-properties/"; // Only my uploaded properties
  static const String uploaderProperties = "$baseUrl/homes/properties/"; // Endpoint to post new property
  static const String propertyDetail = "$baseUrl/homes/property/{uuid}"; 
  static const String propertyDetailUploader = "$baseUrl/homes/uploader-properties/properties/"; 
  static const String updateProperty = "$baseUrl/homes/update-property/{uuid}"; 


  // Booking
  static const String booking = "$baseUrl/api/book/property/";
  static const String airbnbBooking = "$baseUrl/api/airbnb-bookings/";

  //payment
static const String paymentUrl = "$baseUrl/payment/my-order";
static const String paymentHistory = "$baseUrl/payment/payment-history";

// feedback
  static const String listPropertyFeedback = "$baseUrl/homes/property-feedbacks/"; //list property feedbacks
  static const String propertyFeedback = "$baseUrl/homes/property-owner-feedbacks/"; //list property owner feedbacks
  static const String saveFeedback = "$baseUrl/homes/property-feedbacks/"; //save property feedbacks

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
