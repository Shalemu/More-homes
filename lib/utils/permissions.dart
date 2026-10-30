import 'package:morehomesapp/models/user_model.dart';


class Permissions {
  Permissions._();

  static const String viewProperty = 'view_property';
  static const String addProperty = 'add_property';
  static const String changeProperty = 'change_property';

  static const String addPropertyImage = 'add_propertyimage';
  static const String viewPropertyImage = 'view_propertyimage';

  static const String addPropertyCost = 'add_propertycost';
  static const String viewPropertyCost = 'view_propertycost';

  static const String addPropertyFeedback = 'add_propertyfeedback';
  static const String viewPropertyFeedback = 'view_propertyfeedback';

  static const String addFacility = 'add_facility';
  static const String viewFacility = 'view_facility';
  static const String changeFacility = 'change_facility';

  static const String addFacilityProperty = 'add_facilityproperty';
  static const String viewFacilityProperty = 'view_facilityproperty';
  static const String changeFacilityProperty = 'change_facilityproperty';

  static const String viewPlan = 'view_plan';
  static const String viewSubscription = 'view_subscription';
  static const String viewSubscriptionUpdateLogs = 'view_subscriptionupdatelogs';

  static const String viewInvoice = 'view_invoice';
  static const String viewPaymentConfig = 'view_paymentconfig';
  static const String viewPaymentTransaction = 'view_paymenttransaction';
  static const String viewPaymentRequestLog = 'view_paymentrequestlog';

  static const String viewWebhookLog = 'view_webhooklog';
}

extension UserPermissions on UserModel {
  bool hasPermission(String permission) => permissions.contains(permission);

  bool hasAnyPermission(List<String> permissionList) =>
      permissionList.any(permissions.contains);


  bool get isOwner => hasPermission(Permissions.addProperty);

  bool get canAddProperty => hasPermission(Permissions.addProperty);
}
