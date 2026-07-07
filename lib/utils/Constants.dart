import 'package:flutter/material.dart';

//region App name
const mAppName = 'ZIGO CONDUCTOR';
//endregion

//region DomainUrl
const DOMAIN_URL = 'https://zigotaxi.com/backend'; // Don't add slash at the end of the url
//endregion

//region Google map key
const GOOGLE_MAP_API_KEY = 'AIzaSyCXn1MGy_9obvgjtwc9hu5HhZ5bEGEas60';
//endregion

//region Currency & country code
const currencySymbol = 'S/';
const currencyNameConst = 'pen';
const defaultCountry = 'PE';
//endregion

/// Antigüedad máxima del vehículo (Perú): año de fabricación entre [año actual − este valor] y año actual.
const int kMaxVehicleAgeYearsPeru = 15;

//region decimal
const digitAfterDecimal = 2;
//endregion

//region OneSignal Keys
//You have to generate 2 apps on onesignal account one for Rider and one for Driver
const mOneSignalAppIdDriver = '675225dd-eade-4895-b433-bf58aa5d5e8b';
const mOneSignalDriverChannelID = 'default';

const mOneSignalAppIdRider = '404128d4-cfa0-40a0-9a0c-547b4c168817';
const mOneSignalRiderChannelID = 'default';
// Las REST keys están en secrets.dart (gitignored). Ver secrets.example.dart.
//endregion

//region firebase configuration
// zigo-taxi-produccion — app com.zigotaxi.driver (mobilesdk_app_id en google-services.json)
const projectId = 'zigo-taxi-produccion';
const appIdAndroid = '1:596360016418:android:f7b632ce1e80d998e3507b';
const apiKeyFirebase = 'AIzaSyBOEdpMal83dLG9n27u_mmqz6kpZpb3Zwo';
const messagingSenderId = '596360016418';
const storageBucket = 'zigo-taxi-produccion.firebasestorage.app';
const authDomain = 'zigo-taxi-produccion.firebaseapp.com';
//endregion

//region top up default value
const PRESENT_TOP_UP_AMOUNT_CONST = '1000|2000|3000';
const PRESENT_TIP_AMOUNT_CONST = '10|20|30';
//endregion

//region url
const mBaseUrl = "$DOMAIN_URL/api/";
//endregion

//region login type
const LoginTypeGoogle = 'google';
const LoginTypeOTP = 'mobile';
const LoginTypeApple = 'apple';
//endregion

//region error field
var errorThisFieldRequired = 'This field is required';
var errorSomethingWentWrong = 'Something Went Wrong';
//endregion

//region SharedReference keys
const REMEMBER_ME = 'REMEMBER_ME';
const IS_FIRST_TIME = 'IS_FIRST_TIME';
const IS_LOGGED_IN = 'IS_LOGGED_IN';
const ON_RIDE_MODEL = 'ON_RIDE_MODEL';
const IS_TIME2 = 'IS_TIME2';
const USER_ID = 'USER_ID';
const FIRST_NAME = 'FIRST_NAME';
const LAST_NAME = 'LAST_NAME';
const TOKEN = 'TOKEN';
const USER_EMAIL = 'USER_EMAIL';
const USER_TOKEN = 'USER_TOKEN';
const USER_PROFILE_PHOTO = 'USER_PROFILE_PHOTO';
const USER_TYPE = 'USER_TYPE';
const USER_NAME = 'USER_NAME';
const USER_PASSWORD = 'USER_PASSWORD';
const USER_ADDRESS = 'USER_ADDRESS';
const STATUS = 'STATUS';
const CONTACT_NUMBER = 'CONTACT_NUMBER';
const PLAYER_ID = 'PLAYER_ID';
const UID = 'UID';
const ADDRESS = 'ADDRESS';
const IS_OTP = 'IS_OTP';
const IS_GOOGLE = 'IS_GOOGLE';
const GENDER = 'GENDER';
const IS_ONLINE = 'IS_ONLINE';
const IS_Verified_Driver = 'is_verified_driver';
/// 0 = documentación completa según backend; distinto de 0 = aún faltan documentos (ir a pantalla de documentos).
const IS_DOCUMENT_REQUIRED = 'is_document_required';
const IS_PROFILE_PHOTO_REQUIRED = 'is_profile_photo_required';
const LATITUDE = 'LATITUDE';
const LONGITUDE = 'LONGITUDE';
//endregion

/// Foto por defecto que devuelve el backend si el usuario no tiene imagen subida
/// (`helper.php` → asset `images/user/1.jpg`). Tratarla como «sin foto» para que
/// la app muestre el avatar conductor empaquetado en la APK, sin parpadeo.
String normalizeDriverProfileUrl(String? url) {
  final u = (url ?? '').trim();
  if (u.isEmpty) return '';
  final lower = u.toLowerCase();
  if (lower.contains('/images/user/1.jpg')) return '';
  return u;
}

//region user roles
const ADMIN = 'admin';
const DRIVER = 'driver';
const RIDER = 'rider';
//endregion

//region Taxi Status
const IN_ACTIVE = 'inactive';
const PENDING = 'pending';
const BANNED = 'banned';
const REJECT = 'reject';
//endregion

//region Wallet keys
const CREDIT = 'credit';
const DEBIT = 'debit';
//endregion

//region payment
const PAYMENT_TYPE_STRIPE = 'stripe';
const PAYMENT_TYPE_RAZORPAY = 'razorpay';
const PAYMENT_TYPE_PAYSTACK = 'paystack';
const PAYMENT_TYPE_FLUTTERWAVE = 'flutterwave';
const PAYMENT_TYPE_PAYPAL = 'paypal';
const PAYMENT_TYPE_PAYTABS = 'paytabs';
const PAYMENT_TYPE_MERCADOPAGO = 'mercadopago';
const PAYMENT_TYPE_PAYTM = 'paytm';
const PAYMENT_TYPE_MYFATOORAH = 'myfatoorah';
const CASH = 'cash';
const Wallet = 'wallet';

const stripeURL = 'https://api.stripe.com/v1/payment_intents';

const mRazorDescription = mAppName;
const mStripeIdentifier = defaultCountry;
//endregion

//region Rides Status
const UPCOMING = 'upcoming';
const NEW_RIDE_REQUESTED = 'new_ride_requested';
const BID_ACCEPTED = 'bid_accepted';
const BID_REJECTED = 'bid_rejected';
const ACCEPTED = 'accepted';
const ARRIVING = 'arriving';
const ACTIVE = 'active';
const ARRIVED = 'arrived';
const IN_PROGRESS = 'in_progress';
const CANCELED = 'canceled';
const COMPLETED = 'completed';
const COMPLAIN_COMMENT = "complaintcomment";
//endregion

//region FireBase Collection Name
const MESSAGES_COLLECTION = "RideTalk";
// const MESSAGES_COLLECTION = "messages";
const RIDE_CHAT = "RideTalkHistory";
const RIDE_COLLECTION = 'rides';

const USER_COLLECTION = "users";
// const CONTACT_COLLECTION = "contact";
// const CHAT_DATA_IMAGES = "chatImages";

//endregion

//region keys
const IS_ENTER_KEY = "IS_ENTER_KEY";
const SELECTED_WALLPAPER = "SELECTED_WALLPAPER";
const PER_PAGE_CHAT_COUNT = 50;
const PAYMENT_PENDING = 'pending';
const PAYMENT_FAILED = 'failed';
const PAYMENT_PAID = 'paid';
const THEME_MODE_INDEX = 'theme_mode_index';
const CHANGE_LANGUAGE = 'CHANGE_LANGUAGE';
const CHANGE_MONEY = 'CHANGE_MONEY';
const LOGIN_TYPE = 'login_type';

const TEXT = "TEXT";
const IMAGE = "IMAGE";

const VIDEO = "VIDEO";
const AUDIO = "AUDIO";

const FIXED_CHARGES = "fixed_charges";
const MIN_DISTANCE = "min_distance";
const MIN_WEIGHT = "min_weight";
const PER_DISTANCE_CHARGE = "per_distance_charges";
const PER_WEIGHT_CHARGE = "per_weight_charges";

const CHARGE_TYPE_FIXED = 'fixed';
const CHARGE_TYPE_PERCENTAGE = 'percentage';
const CASH_WALLET = 'cash_wallet';
const MALE = 'male';
const FEMALE = 'female';
const OTHER = 'other';
const LEFT = 'left';
//endregion

//region app setting key
const CLOCK = 'clock';
const PRESENT_TOPUP_AMOUNT = 'preset_topup_amount';
const PRESENT_TIP_AMOUNT = 'preset_tip_amount';
const MAX_TIME_FOR_RIDER_MINUTE = 'max_time_for_find_drivers_for_regular_ride_in_minute';
const MAX_TIME_FOR_DRIVER_SECOND = 'ride_accept_decline_duration_for_driver_in_second';
const MIN_AMOUNT_TO_ADD = 'min_amount_to_add';
const MAX_AMOUNT_TO_ADD = 'max_amount_to_add';
const APPLY_ADDITIONAL_FEE = 'apply_additional_fee';
const DOC_REJECTED = 'document_approved';
const DOC_APPROVED = 'document_rejected';
const RIDE_DRIVER_CAN_REVIEW = 'RIDE_DRIVER_CAN_REVIEW';
//endregion

//region chat
List<String> rtlLanguage = ['ar', 'ur'];

enum MessageType {
  TEXT,
  IMAGE,
  VIDEO,
  AUDIO,
}

extension MessageExtension on MessageType {
  String? get name {
    switch (this) {
      case MessageType.TEXT:
        return 'TEXT';
      case MessageType.IMAGE:
        return 'IMAGE';
      case MessageType.VIDEO:
        return 'VIDEO';
      case MessageType.AUDIO:
        return 'AUDIO';
      default:
        return null;
    }
  }
}
//endregion

//region const values
const passwordLengthGlobal = 8;
const defaultRadius = 10.0;
const defaultSmallRadius = 6.0;

const textPrimarySizeGlobal = 16.00;
const textBoldSizeGlobal = 16.00;
const textSecondarySizeGlobal = 14.00;

double tabletBreakpointGlobal = 600.0;
double desktopBreakpointGlobal = 720.0;
double statisticsItemWidth = 230.0;
double defaultAppButtonElevation = 4.0;

bool enableAppButtonScaleAnimationGlobal = true;
int? appButtonScaleAnimationDurationGlobal;
ShapeBorder? defaultAppButtonShapeBorder;

var customDialogHeight = 140.0;
var customDialogWidth = 220.0;
const PER_PAGE = 50;
//endregion
