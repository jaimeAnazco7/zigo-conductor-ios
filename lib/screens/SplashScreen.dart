import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taxi_driver/screens/DashboardScreen.dart';
import 'package:taxi_driver/screens/SignInScreen.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';

import '../languageConfiguration/LanguageDataConstant.dart';
import '../languageConfiguration/ServerLanguageResponse.dart';
import '../main.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Images.dart';
import 'DocumentsScreen.dart';
import 'EditProfileScreen.dart';
import 'WalkThroughScreen.dart';

class SplashScreen extends StatefulWidget {
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNotifyPermission();
  }

  void init() async {
    List<ConnectivityResult> b = await Connectivity().checkConnectivity();
    if (b.contains(ConnectivityResult.none)) {
      return toast(language.yourInternetIsNotWorking);
    }
    await driverDetail();

    await Future.delayed(Duration(seconds: 1));
    if (sharedPref.getBool(IS_FIRST_TIME) ?? true) {
      await Geolocator.requestPermission().then((value) async {
        launchScreen(context, WalkThroughScreen(), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
        Geolocator.getCurrentPosition().then((value) {
          sharedPref.setDouble(LATITUDE, value.latitude);
          sharedPref.setDouble(LONGITUDE, value.longitude);
        });
      }).catchError((e) {
        launchScreen(context, WalkThroughScreen(), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
      });
    } else {
      if (sharedPref.getString(CONTACT_NUMBER).validate().isEmptyOrNull && appStore.isLoggedIn) {
        launchScreen(context, EditProfileScreen(isGoogle: true), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
      } else if (sharedPref.getString(UID).validate().isEmptyOrNull && appStore.isLoggedIn) {
        updateProfileUid().then((value) {
          launchDriverPostLoginScreen(context, isNewTask: true);
        });
      } else if (appStore.isLoggedIn) {
        if (shouldNavigateToProfilePhotoScreen()) {
          launchScreen(context, EditProfileScreen(isGoogle: false), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        } else if (shouldNavigateToDocumentsScreen()) {
          launchScreen(context, DocumentsScreen(isShow: true), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
        } else {
          launchScreen(context, DashboardScreen(), pageRouteAnimation: PageRouteAnimation.SlideBottomTop, isNewTask: true);
        }
      } else {
        launchScreen(context, SignInScreen(), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
      }
    }
  }

  Future<void> driverDetail() async {
    if (appStore.isLoggedIn) {
      await getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) async {
        await sharedPref.setInt(IS_ONLINE, value.data!.isOnline!);
        await sharedPref.setInt(IS_Verified_Driver, value.data!.isVerifiedDriver ?? 0);
        await sharedPref.setInt(IS_DOCUMENT_REQUIRED, value.data!.isDocumentRequired ?? 1);
        syncProfilePhotoRequiredFromUser(value.data);
        if (value.data!.status == REJECT || value.data!.status == BANNED) {
          toast('${language.yourAccountIs} ${value.data!.status}. ${language.pleaseContactSystemAdministrator}');
          logout();
        }
        appStore.setUserEmail(value.data!.email.validate());
        appStore.setUserName(value.data!.username.validate());
        appStore.setFirstName(value.data!.firstName.validate());
        appStore.setUserProfile(value.data!.profileImage.validate());

        sharedPref.setString(USER_EMAIL, value.data!.email.validate());
        sharedPref.setString(FIRST_NAME, value.data!.firstName.validate());
        sharedPref.setString(LAST_NAME, value.data!.lastName.validate());
      }).catchError((error) {});
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo marca: azul profundo (#01203d), no el acento turquesa (primaryColor).
      backgroundColor: neonBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(ic_logo_white, fit: BoxFit.contain, height: 150, width: 150),
            SizedBox(height: 16),
            Text(mAppName, style: boldTextStyle(color: Colors.white, size: 22)),
          ],
        ),
      ),
    );
  }

  void _checkNotifyPermission() async {
    String versionNo = sharedPref.getString(CURRENT_LAN_VERSION) ?? LanguageVersion;

    await getLanguageList(versionNo).then((value) {
      appStore.setLoading(false);
      app_update_check = value.driver_version;
      
      // Procesar los datos si existen, independientemente del status
      // El status solo indica si hay actualización disponible, no si hay datos
      if (value.data != null && value.data!.length > 0) {
        // Actualizar versión solo si status es true (hay actualización)
        if (value.status == true && value.currentVersionNo != null) {
          setValue(CURRENT_LAN_VERSION, value.currentVersionNo.toString());
        }
        
        // Procesar los datos de idiomas
        defaultServerLanguageData = value.data;
        performLanguageOperation(defaultServerLanguageData);
        setValue(LanguageJsonDataRes, value.toJson());
        
        bool isSetLanguage = sharedPref.getBool(IS_SELECTED_LANGUAGE_CHANGE) ?? false;
        if (!isSetLanguage) {
          for (int i = 0; i < value.data!.length; i++) {
            if (value.data![i].isDefaultLanguage == 1) {
              setValue(SELECTED_LANGUAGE_CODE, value.data![i].languageCode);
              setValue(SELECTED_LANGUAGE_COUNTRY_CODE, value.data![i].countryCode);
              appStore.setLanguage(value.data![i].languageCode!, context: context);
              break;
            }
          }
        }
      } else {
        // Si no hay datos en la respuesta, intentar usar datos guardados en caché
        String getJsonData = sharedPref.getString(LanguageJsonDataRes) ?? '';
        if (getJsonData.isNotEmpty) {
          ServerLanguageResponse languageSettings = ServerLanguageResponse.fromJson(json.decode(getJsonData.trim()));
          if (languageSettings.data != null && languageSettings.data!.length > 0) {
            defaultServerLanguageData = languageSettings.data;
            performLanguageOperation(defaultServerLanguageData);
          } else {
            defaultServerLanguageData = [];
            selectedServerLanguageData = null;
            setValue(LanguageJsonDataRes, "");
          }
        } else {
          defaultServerLanguageData = [];
          selectedServerLanguageData = null;
          setValue(LanguageJsonDataRes, "");
        }
      }
    }).catchError((error) {
      appStore.setLoading(false);
      log(error);
      // En caso de error, intentar usar datos guardados en caché
      String getJsonData = sharedPref.getString(LanguageJsonDataRes) ?? '';
      if (getJsonData.isNotEmpty) {
        try {
          ServerLanguageResponse languageSettings = ServerLanguageResponse.fromJson(json.decode(getJsonData.trim()));
          if (languageSettings.data != null && languageSettings.data!.length > 0) {
            defaultServerLanguageData = languageSettings.data;
            performLanguageOperation(defaultServerLanguageData);
          }
        } catch (e) {
          log('Error al cargar idiomas desde caché: $e');
        }
      }
    });
    if (await Permission.notification.isGranted) {
      init();
    } else {
      await Permission.notification.request();
      init();
    }
  }
}
