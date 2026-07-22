import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';
import 'package:taxi_driver/model/DocumentListModel.dart';
import 'package:taxi_driver/model/RideDetailModel.dart';
import 'package:taxi_driver/model/RiderListModel.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';

import '../languageConfiguration/ServerLanguageResponse.dart';
import '../main.dart';
import '../utils/Common.dart';
import '../model/AdditionalFeesList.dart';
import '../model/AppSettingModel.dart';
import '../model/ChangePasswordResponseModel.dart';
import '../model/ComplaintCommentModel.dart';
import '../model/ContactNumberListModel.dart';
import '../model/CurrentRequestModel.dart';
import '../model/DriverDocumentList.dart';
import '../model/EarningListModelWeek.dart';
import '../model/LDBaseResponse.dart';
import '../model/LoginResponse.dart';
import '../model/NotificationListModel.dart';
import '../model/PaymentListModel.dart';
import '../model/ProfileUpdateModel.dart';
import '../model/ServiceModel.dart';
import '../model/WalletDetailModel.dart';
import '../model/WalletListModel.dart';
import '../model/WithDrawListModel.dart';
import '../screens/SignInScreen.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import 'NetworkUtils.dart';

Future<LoginResponse> signUpApi(Map request) async {
  Response response = await buildHttpResponse('driver-register', request: request, method: HttpMethod.POST);

  if (!(response.statusCode >= 200 && response.statusCode <= 206)) {
    if (response.body.isJson()) {
      var json = jsonDecode(response.body);

      if (json.containsKey('code') && json['code'].toString().contains('invalid_username')) {
        throw 'invalid_username';
      }
    }
  }

  return await handleResponse(response).then((json) async {
    var loginResponse = LoginResponse.fromJson(json);
    if (loginResponse.data!.loginType == LoginTypeOTP) {
      await sharedPref.setString(TOKEN, loginResponse.data!.apiToken.validate());
      await sharedPref.setString(USER_TYPE, loginResponse.data!.userType.validate());
      await sharedPref.setString(FIRST_NAME, loginResponse.data!.firstName.validate());
      await sharedPref.setString(LAST_NAME, loginResponse.data!.lastName.validate());
      await sharedPref.setString(CONTACT_NUMBER, loginResponse.data!.contactNumber.validate());
      await sharedPref.setString(USER_EMAIL, loginResponse.data!.email.validate());
      await sharedPref.setString(USER_NAME, loginResponse.data!.username.validate());
      await sharedPref.setString(ADDRESS, loginResponse.data!.address.validate());
      await sharedPref.setInt(USER_ID, loginResponse.data!.id ?? 0);
      await sharedPref.setString(GENDER, loginResponse.data!.gender.validate());
      await sharedPref.setInt(IS_ONLINE, loginResponse.data!.isOnline ?? 0);
      await sharedPref.setString(UID, loginResponse.data!.uid.validate());
      await sharedPref.setString(LOGIN_TYPE, loginResponse.data!.loginType.validate());
      await sharedPref.setInt(IS_Verified_Driver, loginResponse.data!.isVerifiedDriver ?? 0);
      await sharedPref.setInt(IS_DOCUMENT_REQUIRED, loginResponse.data!.isDocumentRequired ?? 1);
      syncProfilePhotoRequiredFromUser(loginResponse.data);

      await appStore.setLoggedIn(true);
      await appStore.setUserEmail(loginResponse.data!.email.validate());
      await appStore.setUserProfile(loginResponse.data!.profileImage.validate());
    }
    return loginResponse;
  }).catchError((e) {
    toast(e.toString());
    return e;
  });
}

Future<LoginResponse> logInApi(Map request, {bool isSocialLogin = false}) async {
  Response response = await buildHttpResponse(isSocialLogin ? 'social-login' : 'login', request: request, method: HttpMethod.POST);

  if (!(response.statusCode >= 200 && response.statusCode <= 206)) {
    if (response.body.isJson()) {
      var json = jsonDecode(response.body);

      if (json.containsKey('code') && json['code'].toString().contains('invalid_username')) {
        throw 'invalid_username';
      }
    }
  }

  return await handleResponse(response).then((json) async {
    var loginResponse = LoginResponse.fromJson(json);
    if (loginResponse.data != null) {
      await sharedPref.setString(TOKEN, loginResponse.data!.apiToken.validate());
      await sharedPref.setString(USER_TYPE, loginResponse.data!.userType.validate());
      await sharedPref.setString(FIRST_NAME, loginResponse.data!.firstName.validate());
      await sharedPref.setString(LAST_NAME, loginResponse.data!.lastName.validate());
      await sharedPref.setString(CONTACT_NUMBER, loginResponse.data!.contactNumber.validate());
      await sharedPref.setString(USER_EMAIL, loginResponse.data!.email.validate());
      await sharedPref.setString(USER_NAME, loginResponse.data!.username.validate());
      await sharedPref.setString(ADDRESS, loginResponse.data!.address.validate());
      await sharedPref.setInt(USER_ID, loginResponse.data!.id ?? 0);
      await sharedPref.setString(GENDER, loginResponse.data!.gender.validate());
      if (loginResponse.data!.isOnline != null) await sharedPref.setInt(IS_ONLINE, loginResponse.data!.isOnline ?? 0);
      await sharedPref.setInt(IS_Verified_Driver, loginResponse.data!.isVerifiedDriver ?? 0);
      await sharedPref.setInt(IS_DOCUMENT_REQUIRED, loginResponse.data!.isDocumentRequired ?? 1);
      syncProfilePhotoRequiredFromUser(loginResponse.data);
      if (loginResponse.data!.uid != null) await sharedPref.setString(UID, loginResponse.data!.uid.validate());
      await sharedPref.setString(LOGIN_TYPE, loginResponse.data!.loginType.validate());

      await appStore.setLoggedIn(true);
      await appStore.setUserEmail(loginResponse.data!.email.validate());
      await appStore.setUserProfile(loginResponse.data!.profileImage.validate());
    }
    return loginResponse;
  }).catchError((e) {
    throw e.toString();
  });
}

Future<MultipartRequest> getMultiPartRequest(String endPoint, {String? baseUrl}) async {
  String url = '${baseUrl ?? buildBaseUrl(endPoint).toString()}';
  log(url);
  return MultipartRequest('POST', Uri.parse(url));
}

Future sendMultiPartRequest(MultipartRequest multiPartRequest, {Function(dynamic)? onSuccess, Function(dynamic)? onError}) async {
  multiPartRequest.headers.addAll(buildHeaderTokens());

  try {
    final res = await multiPartRequest.send();
    final value = await res.stream.bytesToString();
    if (res.statusCode == 200) {
      if (value.contains("Server Error")) {
        onError?.call("Server Error");
      } else {
        final decoded = jsonDecode(value);
        final result = onSuccess?.call(decoded);
        if (result is Future) {
          await result;
        }
      }
    } else {
      onError?.call(res.statusCode.toString());
    }
  } catch (error) {
    onError?.call(error.toString());
  }
}

/// Profile Update
Future updateProfile(
    {String? firstName,
    String? lastName,
    String? userEmail,
    String? address,
    String? contactNumber,
    String? gender,
    File? file,
    String? uid,
    String? carModel,
    String? carColor,
    String? carPlateNumber,
    String? carProduction,
    String? country_code,
    int? serviceId,
    String? allyReferralCode}) async {
  MultipartRequest multiPartRequest = await getMultiPartRequest('update-profile');
  if (country_code != null) {
    multiPartRequest.fields['country_code'] = country_code.toString();
  }
  multiPartRequest.fields['username'] = sharedPref.getString(USER_NAME).validate();
  multiPartRequest.fields['email'] = userEmail ?? appStore.userEmail;
  multiPartRequest.fields['first_name'] = firstName.validate();
  multiPartRequest.fields['last_name'] = lastName.validate();
  multiPartRequest.fields['contact_number'] = contactNumber.validate();
  multiPartRequest.fields['address'] = address.validate();
  multiPartRequest.fields['gender'] = gender.validate();
  if (uid != null) multiPartRequest.fields['uid'] = uid.validate();
  if (carModel.validate().isNotEmpty) multiPartRequest.fields['user_detail[car_model]'] = carModel.validate();
  if (carColor.validate().isNotEmpty) multiPartRequest.fields['user_detail[car_color]'] = carColor.validate();
  if (carPlateNumber.validate().isNotEmpty) multiPartRequest.fields['user_detail[car_plate_number]'] = carPlateNumber.validate();
  if (carProduction.validate().isNotEmpty) multiPartRequest.fields['user_detail[car_production_year]'] = carProduction.validate();
  if (serviceId != null) multiPartRequest.fields['service_id'] = '$serviceId';
  final code = allyReferralCode.validate().trim();
  if (code.isNotEmpty) multiPartRequest.fields['ally_referral_code'] = code;
  multiPartRequest.fields['player_id'] = sharedPref.getString(PLAYER_ID).toString();

  if (file != null) multiPartRequest.files.add(await MultipartFile.fromPath('profile_image', file.path));

  Object? requestError;
  await sendMultiPartRequest(multiPartRequest, onSuccess: (data) async {
    if (data != null) {
      ProfileUpdate res = ProfileUpdate.fromJson(data);
      if (res.data != null) {
        await sharedPref.setString(FIRST_NAME, res.data!.firstName.validate());
        await sharedPref.setString(LAST_NAME, res.data!.lastName.validate());
        await sharedPref.setString(USER_NAME, res.data!.username.validate());
        await sharedPref.setString(USER_ADDRESS, res.data!.address.validate());
        await sharedPref.setString(CONTACT_NUMBER, res.data!.contactNumber.validate());
        await sharedPref.setString(GENDER, res.data!.gender.validate());
        await appStore.setUserEmail(res.data!.email.validate());
        await appStore.setFirstName(res.data!.firstName.validate());

        final uploadedPhoto = file != null;
        final photoUrl = normalizeDriverProfileUrl(res.data!.profileImage);
        if (uploadedPhoto || photoUrl.isNotEmpty) {
          if (photoUrl.isNotEmpty) {
            final oldUrl = appStore.userProfile;
            await evictDriverProfilePhotoCache(oldUrl);
            await evictDriverProfilePhotoCache(photoUrl);
            // Misma URL del servidor → bust de caché para que el menú muestre la foto nueva
            final cacheBusted = photoUrl.contains('?')
                ? '$photoUrl&v=${DateTime.now().millisecondsSinceEpoch}'
                : '$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}';
            await appStore.setUserProfile(cacheBusted);
          }
          await sharedPref.setInt(IS_PROFILE_PHOTO_REQUIRED, 0);
        }
      }
    }
  }, onError: (error) {
    toast(error.toString());
    requestError = error;
  });
  if (requestError != null) {
    throw requestError!;
  }
}

Future<void> logout({bool isDelete = false}) async {
  if (!isDelete) {
    await logoutRemoteBestEffort();
  }
  await logOutSuccess();
}

Future<ChangePasswordResponseModel> changePassword(Map req) async {
  return ChangePasswordResponseModel.fromJson(await handleResponse(await buildHttpResponse('change-password', request: req, method: HttpMethod.POST)));
}

Future<ChangePasswordResponseModel> forgotPassword(Map req) async {
  return ChangePasswordResponseModel.fromJson(await handleResponse(await buildHttpResponse('forget-password', request: req, method: HttpMethod.POST)));
}

Future<ServiceModel> getServices() async {
  return ServiceModel.fromJson(await handleResponse(await buildHttpResponse('service-list', method: HttpMethod.GET)));
}

Future<UserDetailModel> getUserDetail({int? userId}) async {
  return UserDetailModel.fromJson(await handleResponse(await buildHttpResponse('user-detail?id=$userId', method: HttpMethod.GET)));
}

Future<LDBaseResponse> changeStatus(Map request) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('update-user-status', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> saveBooking(Map request) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('update-user-status', method: HttpMethod.POST, request: request)));
}

Future<WalletListModel> getWalletList({required int pageData}) async {
  return WalletListModel.fromJson(await handleResponse(await buildHttpResponse('wallet-list?page=$pageData', method: HttpMethod.GET)));
}

Future<PaymentListModel> getPaymentList() async {
  return PaymentListModel.fromJson(await handleResponse(await buildHttpResponse('payment-gateway-list?status=1', method: HttpMethod.GET)));
}

Future<LDBaseResponse> saveWallet(Map request) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-wallet', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> saveSOS(Map request) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-sos', method: HttpMethod.POST, request: request)));
}

Future<ContactNumberListModel> getSosList({int? regionId}) async {
  return ContactNumberListModel.fromJson(await handleResponse(await buildHttpResponse(regionId != null ? 'sos-list?region_id=$regionId' : 'sos-list', method: HttpMethod.GET)));
}

Future<ContactNumberListModel> deleteSosList({int? id}) async {
  return ContactNumberListModel.fromJson(await handleResponse(await buildHttpResponse('sos-delete/$id', method: HttpMethod.POST)));
}

Future<WithDrawListModel> getWithDrawList({int? page}) async {
  return WithDrawListModel.fromJson(await handleResponse(await buildHttpResponse('withdrawrequest-list?page=$page', method: HttpMethod.GET)));
}

Future<LDBaseResponse> saveWithDrawRequest(Map request) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-withdrawrequest', method: HttpMethod.POST, request: request)));
}

Future<AppSettingModel> getAppSetting() async {
  return AppSettingModel.fromJson(await handleResponse(await buildHttpResponse('admin-dashboard', method: HttpMethod.GET)));
}

Future<RiderListModel> getRiderRequestList({int? page, String? status, LatLng? sourceLatLog, int? driverId}) async {
  if (sourceLatLog != null) {
    return RiderListModel.fromJson(await handleResponse(await buildHttpResponse('riderequest-list?page=$page&driver_id=$driverId', method: HttpMethod.GET)));
  } else {
    return RiderListModel.fromJson(await handleResponse(
        await buildHttpResponse(status != null ? 'riderequest-list?page=$page&status=$status&driver_id=$driverId' : 'riderequest-list?page=$page&driver_id=$driverId', method: HttpMethod.GET)));
  }
}

Future<ServerLanguageResponse> getLanguageList(versionNo) async {
  return ServerLanguageResponse.fromJson(await handleResponse(await buildHttpResponse('language-table-list?version_no=$versionNo', method: HttpMethod.GET)).then((value) => value));
}

Future<DocumentListModel> getDocumentList() async {
  return DocumentListModel.fromJson(await handleResponse(await buildHttpResponse('document-list', method: HttpMethod.GET)));
}

Future<DriverDocumentList> getDriverDocumentList() async {
  return DriverDocumentList.fromJson(await handleResponse(await buildHttpResponse('driver-document-list', method: HttpMethod.GET)));
}

/// Profile Update
Future uploadDocument({int? driverId, int? documentId, File? file, int? isExpire}) async {
  MultipartRequest multiPartRequest = await getMultiPartRequest('driver-document-save');
  multiPartRequest.fields['driver_id'] = driverId.toString();
  multiPartRequest.fields['document_id'] = documentId.toString();
  multiPartRequest.fields['is_verified'] = '0';
  if (isExpire != null) multiPartRequest.fields['is_verified'] = '0';
  if (file != null) multiPartRequest.files.add(await MultipartFile.fromPath('driver_document', file.path));

  await sendMultiPartRequest(multiPartRequest, onSuccess: (data) async {
    if (data != null) {
      //
    }
  }, onError: (error) {
    toast(error.toString());
  });
}

Future<LDBaseResponse> deleteDeliveryDoc(int id) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('driver-document-delete/$id', method: HttpMethod.POST)));
}

Future<LoginResponse> updateStatus(Map request) async {
  return LoginResponse.fromJson(await handleResponse(await buildHttpResponse('update-user-status', method: HttpMethod.POST, request: request)));
}

/// Update Vehicle Info
Future updateVehicleDetail({String? carModel, String? carColor, String? carPlateNumber, String? carProduction}) async {
  MultipartRequest multiPartRequest = await getMultiPartRequest('update-profile');
  multiPartRequest.fields['id'] = sharedPref.getInt(USER_ID).toString();
  multiPartRequest.fields['email'] = sharedPref.getString(USER_EMAIL).validate();
  multiPartRequest.fields['contact_number'] = sharedPref.getString(CONTACT_NUMBER).validate();
  multiPartRequest.fields['username'] = sharedPref.getString(USER_NAME).validate();
  multiPartRequest.fields['user_detail[car_model]'] = carModel.validate();
  multiPartRequest.fields['user_detail[car_color]'] = carColor.validate();
  multiPartRequest.fields['user_detail[car_plate_number]'] = carPlateNumber.validate();
  multiPartRequest.fields['user_detail[car_production_year]'] = carProduction.validate();

  await sendMultiPartRequest(multiPartRequest, onSuccess: (data) async {
    if (data != null) {
      //
    }
  }, onError: (error) {
    toast(error.toString());
  });
}

/// Update Bank Info
Future updateBankDetail({String? bankName, String? bankCode, String? accountName, String? accountNumber, String? routing, String? iban, String? swift}) async {
  MultipartRequest multiPartRequest = await getMultiPartRequest('update-profile');
  multiPartRequest.fields['email'] = sharedPref.getString(USER_EMAIL).validate();
  multiPartRequest.fields['contact_number'] = sharedPref.getString(CONTACT_NUMBER).validate();
  multiPartRequest.fields['username'] = sharedPref.getString(USER_NAME).validate();
  multiPartRequest.fields['user_bank_account[bank_name]'] = bankName.validate();
  multiPartRequest.fields['user_bank_account[bank_code]'] = bankCode.validate();
  multiPartRequest.fields['user_bank_account[account_holder_name]'] = accountName.validate();
  multiPartRequest.fields['user_bank_account[account_number]'] = accountNumber.validate();
  multiPartRequest.fields['user_bank_account[routing_number]'] = routing.validate();
  multiPartRequest.fields['user_bank_account[bank_iban]'] = iban.validate();
  multiPartRequest.fields['user_bank_account[bank_swift]'] = swift.validate();
  await sendMultiPartRequest(multiPartRequest, onSuccess: (data) async {
    if (data != null) {
      //
    }
  }, onError: (error) {
    toast(error.toString());
  });
}

Future<LDBaseResponse> responseBidListing(Map request) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('riderequest-bid-respond', method: HttpMethod.POST, request: request)));
}

Future<CurrentRequestModel> getCurrentRideRequest() async {
  return CurrentRequestModel.fromJson(await handleResponse(await buildHttpResponse('current-riderequest', method: HttpMethod.GET)));
}

Future<LDBaseResponse> rideRequestUpdate({required Map request, int? rideId}) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('riderequest-update/$rideId', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> applyBid({required Map request}) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('apply-bid', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> ratingReview({required Map request}) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-ride-rating', method: HttpMethod.POST, request: request)));
}

Future<AdditionalFeesList> getAdditionalFees() async {
  return AdditionalFeesList.fromJson(await handleResponse(await buildHttpResponse('additional-fees-list?status=1', method: HttpMethod.GET)));
}

Future<LDBaseResponse> adminNotify({required Map request}) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('admin-sos-notify', method: HttpMethod.POST, request: request)));
}

Future<RideDetailModel> rideDetail({required int? rideId}) async {
  return RideDetailModel.fromJson(await handleResponse(await buildHttpResponse('riderequest-detail?id=$rideId', method: HttpMethod.GET)));
}

Future<LDBaseResponse> saveComplain({required Map request}) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-complaint', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> completeRide({required Map request}) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('complete-riderequest', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> savePayment(Map request) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-payment', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> rideRequestResPond({required Map request}) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('riderequest-respond', method: HttpMethod.POST, request: request)));
}

Future<dynamic> dropOupUpdate({required String rideId, required String dropIndex}) async {
  return await handleResponse(await buildHttpResponse(
    'riderequest/$rideId/drop/$dropIndex',
    method: HttpMethod.POST,
  ));
}

/// Get Notification List
Future<NotificationListModel> getNotification({required int page}) async {
  return NotificationListModel.fromJson(await handleResponse(await buildHttpResponse('notification-list?page=$page&limit=$PER_PAGE', method: HttpMethod.POST)));
}

Future<LDBaseResponse> deleteUser() async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('delete-user-account', method: HttpMethod.POST)));
}

Future<EarningListModelWeek> earningList({Map? req}) async {
  var raw = await handleResponse(await buildHttpResponse('earning-list', method: HttpMethod.POST, request: req));
  // El backend puede devolver { "data": { total_earnings, ... } }; la app espera el objeto interno
  var data = (raw is Map && raw.containsKey('data') && raw['data'] != null) ? raw['data'] : raw;
  return EarningListModelWeek.fromJson(Map<String, dynamic>.from(data));
}

Future updateProfileUid() async {
  MultipartRequest multiPartRequest = await getMultiPartRequest('update-profile');
  multiPartRequest.fields['id'] = sharedPref.getInt(USER_ID).toString();
  multiPartRequest.fields['username'] = sharedPref.getString(USER_NAME).validate();
  multiPartRequest.fields['email'] = sharedPref.getString(USER_EMAIL).validate();
  multiPartRequest.fields['uid'] = sharedPref.getString(UID).toString();

  log('multipart request:${multiPartRequest.fields}');
  log(sharedPref.getString(UID).toString());

  await sendMultiPartRequest(multiPartRequest, onSuccess: (data) async {
    if (data != null) {
      //
    }
  }, onError: (error) {
    toast(error.toString());
  });
}

Future<WalletDetailModel> walletDetailApi() async {
  return WalletDetailModel.fromJson(await handleResponse(await buildHttpResponse('wallet-detail', method: HttpMethod.GET)));
}

Future<LDBaseResponse> complaintComment({required Map request}) async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('save-complaintcomment', method: HttpMethod.POST, request: request)));
}

Future<ComplaintCommentModel> complaintList({required int complaintId, required int currentPage}) async {
  return ComplaintCommentModel.fromJson(await handleResponse(await buildHttpResponse('complaintcomment-list?complaint_id=$complaintId&page=$currentPage', method: HttpMethod.GET)));
}

Future<LDBaseResponse> logoutApi() async {
  return LDBaseResponse.fromJson(await handleResponse(await buildHttpResponse('logout?clear=player_id', method: HttpMethod.GET)));
}

/// Cierre remoto sin [handleResponse]: evita 401→re-login (falla en Google/conductores sin password guardada).
Future<void> logoutRemoteBestEffort() async {
  try {
    final Response response = await buildHttpResponse('logout?clear=player_id', method: HttpMethod.GET);
    if (response.statusCode == 200 && response.body.validate().isNotEmpty && response.body.isJson()) {
      try {
        LDBaseResponse.fromJson(jsonDecode(response.body));
      } catch (_) {}
    } else if (response.statusCode != 200) {
      log('logout endpoint status=${response.statusCode}');
    }
  } catch (e, s) {
    log('logoutRemoteBestEffort: $e');
  }
}

Future<void> logOutSuccess() async {
  try {
    await GoogleSignIn().signOut();
  } catch (_) {}
  try {
    await FirebaseAuth.instance.signOut();
  } catch (_) {}
  sharedPref.remove(FIRST_NAME);
  sharedPref.remove(LAST_NAME);
  sharedPref.remove(USER_PROFILE_PHOTO);
  sharedPref.remove(IS_PROFILE_PHOTO_REQUIRED);
  sharedPref.remove(USER_NAME);
  sharedPref.remove(USER_ADDRESS);
  sharedPref.remove(CONTACT_NUMBER);
  sharedPref.remove(GENDER);
  sharedPref.remove(UID);
  sharedPref.remove(TOKEN);
  sharedPref.remove(USER_TYPE);
  sharedPref.remove(ADDRESS);
  sharedPref.remove(USER_ID);
  appStore.setLoggedIn(false);
  if (!(sharedPref.getBool(REMEMBER_ME) ?? false) || sharedPref.getString(LOGIN_TYPE) == LoginTypeGoogle || sharedPref.getString(LOGIN_TYPE) == LoginTypeOTP) {
    sharedPref.remove(USER_EMAIL);
    sharedPref.remove(USER_PASSWORD);
    sharedPref.remove(REMEMBER_ME);
  }
  sharedPref.remove(LOGIN_TYPE);
  sharedPref.remove(LATITUDE);
  sharedPref.remove(LONGITUDE);
  launchScreen(getContext, SignInScreen(), isNewTask: true);
}

Future<AppSettingModel> getAppSettingApi() async {
  return AppSettingModel.fromJson(await handleResponse(await buildHttpResponse('appsetting', method: HttpMethod.GET)));
}
