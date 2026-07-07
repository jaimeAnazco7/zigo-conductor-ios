import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxi_driver/screens/DashboardScreen.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Extensions/context_extensions.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';
import 'package:taxi_driver/utils/Images.dart';

import '../../main.dart';
import '../Services/AuthService.dart';
import '../components/OTPDialog.dart';
import '../model/UserDetailModel.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/legal_urls.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';
import 'DocumentsScreen.dart';
import 'ForgotPasswordScreen.dart';
import 'SignUpScreen.dart';
import 'TermsConditionScreen.dart';

class SignInScreen extends StatefulWidget {
  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late UserData _userModel;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  AuthServices authService = AuthServices();
  GoogleAuthServices googleAuthService = GoogleAuthServices();

  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode passFocus = FocusNode();

  bool mIsCheck = false;
  bool isAcceptedTc = false;
  String? privacyPolicy;
  String? termsCondition;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    appSetting();
    if (sharedPref.getString(PLAYER_ID).validate().isEmpty) {
      await saveOneSignalPlayerId().then((value) {
        //
      });
    }
    mIsCheck = sharedPref.getBool(REMEMBER_ME) ?? false;
    if (mIsCheck) {
      emailController.text = sharedPref.getString(USER_EMAIL).validate();
      passController.text = sharedPref.getString(USER_PASSWORD).validate();
    }
  }

  Future<void> logIn() async {
    hideKeyboard(context);
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if (isAcceptedTc) {
        appStore.setLoading(true);
        Map req = {
          'email': emailController.text.trim(),
          'password': passController.text.trim(),
          "player_id": sharedPref.getString(PLAYER_ID).validate(),
          'user_type': DRIVER,
        };
        if (mIsCheck) {
          await sharedPref.setBool(REMEMBER_ME, mIsCheck);
          await sharedPref.setString(USER_EMAIL, emailController.text);
          await sharedPref.setString(USER_PASSWORD, passController.text);
        }
        await logInApi(req).then((value) async {
          _userModel = value.data!;
          await _auth.signInWithEmailAndPassword(email: emailController.text, password: passController.text).then((value) async {
            sharedPref.setString(UID, value.user!.uid);
            updateProfileUid();
            await launchDriverPostLoginScreen(context, isNewTask: true);
            appStore.isLoading = false;
          }).catchError((e) async {
            if (e.toString().contains('user-not-found') || e.toString().contains('invalid')) {
              authService.signUpWithEmailPassword(
                context,
                mobileNumber: _userModel.contactNumber,
                email: emailController.text,
                fName: _userModel.firstName,
                lName: _userModel.lastName,
                userName: _userModel.username,
                password: passController.text,
                userType: DRIVER,
              );
            } else {
              await launchDriverPostLoginScreen(context, isNewTask: true);
            }
            //toast(e.toString());
            log('${e.toString()}');
            log(e.toString());
          });
        }).catchError((error) {
          appStore.setLoading(false);

          toast(error.toString());
          log('${error.toString()}');
        });
      } else {
        toast(language.pleaseAcceptTermsOfServicePrivacyPolicy);
      }
    }
  }

  Future<void> appSetting() async {
    privacyPolicy = kDefaultZigoPrivacyPolicyUrl;
    termsCondition = kDefaultZigoTermsUrl;
    appStore.privacyPolicy = kDefaultZigoPrivacyPolicyUrl;
    appStore.termsCondition = kDefaultZigoTermsUrl;
    await getAppSettingApi().then((_) {
      // Términos y privacidad: siempre URLs fijas Zigo (legal_urls.dart)
    }).catchError((error) {
      log(error.toString());
    });
  }

  void googleSignIn() async {
    hideKeyboard(context);
    appStore.setLoading(true);

    await googleAuthService.signInWithGoogle(context).then((value) async {
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      print(e.toString());
      toast(e.toString());
    });
  }

  appleLoginApi() async {
    hideKeyboard(context);
    appStore.setLoading(true);
    await appleLogIn().then((value) {
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neonBackground,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light, statusBarBrightness: Brightness.dark),
      ),
      // appBar: AppBar(),
      body: Stack(
        children: [
          Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: context.statusBarHeight + 16),
                  // Mismo logo que SplashScreen (conductor / ic_driver_white)
                  Image.asset(ic_logo_white, fit: BoxFit.contain, height: 150, width: 150),
                  SizedBox(height: 16),
                  Text(language.welcome, style: boldTextStyle(size: 22, color: appTextPrimaryColorWhite)),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: '${language.signContinue}', style: primaryTextStyle(size: 14, color: neonHighlight)),
                        TextSpan(text: '🚗', style: primaryTextStyle(size: 20, color: neonHighlight)),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  AppTextField(
                    controller: emailController,
                    nextFocus: passFocus,
                    autoFocus: false,
                    textFieldType: TextFieldType.EMAIL,
                    keyboardType: TextInputType.emailAddress,
                    errorThisFieldRequired: language.thisFieldRequired,
                    cursorColor: neonAccent,
                    textStyle: primaryTextStyle(color: appTextPrimaryColorWhite),
                    keyboardAppearance: Brightness.dark,
                    decoration: inputDecorationNeonForm(context, label: language.email),
                  ),
                  SizedBox(height: 16),
                  AppTextField(
                    controller: passController,
                    focus: passFocus,
                    autoFocus: false,
                    textFieldType: TextFieldType.PASSWORD,
                    errorThisFieldRequired: language.thisFieldRequired,
                    cursorColor: neonAccent,
                    textStyle: primaryTextStyle(color: appTextPrimaryColorWhite),
                    suffixIconColor: neonHighlight,
                    keyboardAppearance: Brightness.dark,
                    decoration: inputDecorationNeonForm(context, label: language.password),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 18.0,
                            width: 18.0,
                            child: Checkbox(
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: radius(4)),
                              side: WidgetStateBorderSide.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return BorderSide(color: primaryColor, width: 1.5);
                                }
                                return const BorderSide(color: Colors.white, width: 1.5);
                              }),
                              fillColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return primaryColor;
                                }
                                return Colors.transparent;
                              }),
                              checkColor: Colors.white,
                              value: mIsCheck,
                              onChanged: (v) async {
                                mIsCheck = v!;
                                if (!mIsCheck) {
                                  sharedPref.remove(REMEMBER_ME);
                                } else {
                                  await sharedPref.setBool(REMEMBER_ME, mIsCheck);
                                  await sharedPref.setString(USER_EMAIL, emailController.text);
                                  await sharedPref.setString(USER_PASSWORD, passController.text);
                                }

                                setState(() {});
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          inkWellWidget(
                            onTap: () async {
                              mIsCheck = !mIsCheck;
                              setState(() {});
                            },
                            child: Text(language.rememberMe, style: primaryTextStyle(size: 14, color: neonHighlight)),
                          ),
                        ],
                      ),
                      inkWellWidget(
                        onTap: () {
                          launchScreen(context, ForgotPasswordScreen(), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                        },
                        child: Text(language.forgotPassword, style: primaryTextStyle(color: neonAccent)),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        height: 18,
                        width: 18,
                        child: Checkbox(
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: radius(4)),
                          side: WidgetStateBorderSide.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return BorderSide(color: primaryColor, width: 1.5);
                            }
                            return const BorderSide(color: Colors.white, width: 1.5);
                          }),
                          fillColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return primaryColor;
                            }
                            return Colors.transparent;
                          }),
                          checkColor: Colors.white,
                          value: isAcceptedTc,
                          onChanged: (v) async {
                            isAcceptedTc = v!;
                            setState(() {});
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: language.iAgreeToThe + " ", style: primaryTextStyle(size: 12, color: neonHighlight)),
                              TextSpan(
                                text: language.termsConditions.splitBefore(' &'),
                                style: boldTextStyle(color: neonAccent, size: 14),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    if (termsCondition != null && termsCondition!.isNotEmpty) {
                                      launchScreen(context, TermsConditionScreen(title: language.termsConditions, subtitle: termsCondition), pageRouteAnimation: PageRouteAnimation.Slide);
                                    } else {
                                      toast(language.txtURLEmpty);
                                    }
                                  },
                              ),
                              TextSpan(text: ' & ', style: primaryTextStyle(size: 12, color: neonHighlight)),
                              TextSpan(
                                text: language.privacyPolicy,
                                style: boldTextStyle(color: neonAccent, size: 14),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    if (privacyPolicy != null && privacyPolicy!.isNotEmpty) {
                                      launchScreen(context, TermsConditionScreen(title: language.privacyPolicy, subtitle: privacyPolicy), pageRouteAnimation: PageRouteAnimation.Slide);
                                    } else {
                                      toast(language.txtURLEmpty);
                                    }
                                  },
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left,
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 32),
                  AppButtonWidget(
                    width: MediaQuery.of(context).size.width,
                    text: language.logIn,
                    onTap: () async {
                      logIn();
                    },
                  ),
                  SizedBox(height: 16),
                  socialWidget(),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Observer(
            builder: (context) {
              return Visibility(
                visible: appStore.isLoading,
                child: loaderWidget(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeScaffoldBottomBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(language.donHaveAnAccount, style: primaryTextStyle(color: neonHighlight)),
                  SizedBox(width: 8),
                  inkWellWidget(
                    onTap: () {
                      hideKeyboard(context);
                      launchScreen(
                        context,
                        SignUpScreen(privacyPolicyUrl: kDefaultZigoPrivacyPolicyUrl, termsConditionUrl: kDefaultZigoTermsUrl),
                      );
                    },
                    child: Text(language.signUp, style: boldTextStyle(size: 18, color: appTextPrimaryColorWhite)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget socialWidget() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: Divider(color: neonAccent.withOpacity(0.35))),
              Padding(
                padding: EdgeInsets.only(left: 16, right: 16),
                child: Text(language.orLogInWith, style: primaryTextStyle(color: neonHighlight)),
              ),
              Expanded(
                child: Divider(color: neonAccent.withOpacity(0.35)),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            inkWellWidget(
                onTap: () async {
                  googleSignIn();
                },
                child: socialWidgetComponent(img: ic_google)),
            SizedBox(width: 12),
            inkWellWidget(
              onTap: () async {
                showNeonOtpDialog(
                  context,
                  child: OTPDialog(),
                );
                appStore.setLoading(false);
              },
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: neonSurfaceCard.withOpacity(0.4),
                  border: Border.all(color: neonAccent.withOpacity(0.45)),
                  borderRadius: radius(defaultRadius),
                ),
                child: Image.asset(ic_mobile, fit: BoxFit.cover, height: 30, width: 30),
              ),
            ),
            if (Platform.isIOS) SizedBox(width: 12),
            if (Platform.isIOS)
              inkWellWidget(
                onTap: () async {
                  appleLoginApi();
                },
                child: Padding(padding: EdgeInsets.only(bottom: 4.0), child: socialWidgetComponent(img: ic_apple)),
              ),
          ],
        ),
      ],
    );
  }

  Widget socialWidgetComponent({required String img, bool? isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: neonSurfaceCard.withOpacity(0.4),
        border: Border.all(color: neonAccent.withOpacity(0.45)),
        borderRadius: radius(defaultRadius),
      ),
      child: Image.asset(img, fit: BoxFit.cover, height: 30, width: 30),
    );
  }
}
