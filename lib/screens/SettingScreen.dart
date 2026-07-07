import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:taxi_driver/utils/Common.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../model/SettingModel.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/legal_urls.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/app_common.dart';
import 'AboutScreen.dart';
import 'ChangePasswordScreen.dart';
import 'DeleteAccountScreen.dart';
import 'LanguageScreen.dart';
import 'TermsConditionScreen.dart';

class SettingScreen extends StatefulWidget {
  @override
  SettingScreenState createState() => SettingScreenState();
}

class SettingScreenState extends State<SettingScreen> {
  SettingModel settingModel = SettingModel();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    LiveStream().on(CHANGE_LANGUAGE, (p0) {
      setState(() {});
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
        title: Text(language.settings, style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(left: 16, right: 16, top: 30, bottom: 24),
            child: Column(
              children: [
                Visibility(
                  visible: sharedPref.getString(LOGIN_TYPE) != LoginTypeOTP && sharedPref.getString(LOGIN_TYPE) != LoginTypeGoogle && sharedPref.getString(LOGIN_TYPE) != null,
                  child: settingItemWidget(Ionicons.ios_lock_closed_outline, language.changePassword, () {
                    launchScreen(context, ChangePasswordScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
                  }),
                ),
                settingItemWidget(Ionicons.language_outline, language.language, () {
                  launchScreen(context, LanguageScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
                }),
                settingItemWidget(Ionicons.ios_document_outline, language.privacyPolicy, () {
                  launchScreen(
                    context,
                    TermsConditionScreen(title: language.privacyPolicy, subtitle: kDefaultZigoPrivacyPolicyUrl),
                    pageRouteAnimation: PageRouteAnimation.Slide,
                  );
                }),
                if (appStore.mHelpAndSupport != null)
                  settingItemWidget(Ionicons.help_outline, language.helpSupport, () {
                    if (appStore.mHelpAndSupport != null) {
                      launchUrl(Uri.parse(appStore.mHelpAndSupport!));
                    } else {
                      toast(language.txtURLEmpty);
                    }
                  }),
                settingItemWidget(Ionicons.document_outline, language.termsConditions, () {
                  launchScreen(
                    context,
                    TermsConditionScreen(title: language.termsConditions, subtitle: kDefaultZigoTermsUrl),
                    pageRouteAnimation: PageRouteAnimation.Slide,
                  );
                }),
                settingItemWidget(
                  Ionicons.information,
                  language.aboutUs,
                  () {
                    launchScreen(context, AboutScreen(settingModel: appStore.settingModel), pageRouteAnimation: PageRouteAnimation.Slide);
                  },
                ),
                settingItemWidget(Ionicons.ios_trash_outline, color: neonError, language.deleteAccount, () {
                  launchScreen(context, DeleteAccountScreen(), pageRouteAnimation: PageRouteAnimation.Slide);
                }),
              ],
            ),
          ),
          Observer(builder: (context) {
            return Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            );
          })
        ],
      ),
    );
  }

  Widget settingItemWidget(IconData icon, String title, Function() onTap, {bool isLast = false, Widget? suffixIcon, Color? color}) {
    final Color accent = color ?? neonAccent;
    final Color borderCol = color ?? neonAccent.withOpacity(0.4);
    return inkWellWidget(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: neonSurfaceCard,
          borderRadius: radius(defaultRadius),
          border: Border.all(color: borderCol, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: radius(),
                border: Border.all(color: accent.withOpacity(0.45)),
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: primaryTextStyle(color: color ?? Colors.white, size: 16),
              ),
            ),
            suffixIcon != null ? suffixIcon : Icon(Icons.chevron_right, color: neonHighlight.withOpacity(0.85), size: 22),
          ],
        ),
      ),
    );
  }
}
