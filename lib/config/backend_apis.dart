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
  //ads
 static const String addBanner = "$baseUrl/auth/ads/";

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




// feedback
  static const String listPropertyFeedback = "$baseUrl/homes/property-feedbacks/"; //list property feedbacks
  static const String propertyFeedback = "$baseUrl/homes/property-owner-feedbacks/"; //list property owner feedbacks
  static const String saveFeedback = "$baseUrl/homes/property-feedbacks/"; //save property feedbacks


  /// Check if user can access contact
  static const String checkEligibility =
      "$baseUrl/payment/check-eligibility?subscribe_url=subscribe&invoice_url=invoice";

  /// Get all plans
  static const String plans = "$baseUrl/payment/plans";

  /// Get all user invoices
  static const String myInvoices = "$baseUrl/payment/invoices/me";

  /// Dynamic: Subscribe to plan
  static String subscribe(String planUuid) =>
      "$baseUrl/payment/subscribe/$planUuid";

  /// Dynamic: Get invoice detail
  static String invoiceDetail(String invoiceId) =>
      "$baseUrl/payment/invoice/$invoiceId";

  /// Dynamic: Make payment
  static String makePayment(String invoiceId) =>
  "$baseUrl/payment/make-payment/$invoiceId";

  //change plans

static String changePlan(String planUuid) =>
  "$baseUrl/payment/changes-subscription/$planUuid";

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
