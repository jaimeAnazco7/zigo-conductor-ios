import 'package:flutter/material.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';

import '../../main.dart';
import '../languageConfiguration/LanguageDataConstant.dart';
import '../languageConfiguration/LanguageDefaultJson.dart';
import '../languageConfiguration/ServerLanguageResponse.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/app_common.dart';

class LanguageScreen extends StatefulWidget {
  @override
  LanguageScreenState createState() => LanguageScreenState();
}

class LanguageScreenState extends State<LanguageScreen> {
  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neonBackground,
      appBar: AppBar(
        title: Text(language.language, style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 16, top: 30, right: 16, bottom: 24),
        child: Wrap(
          runSpacing: 12,
          spacing: 12,
          children: List.generate(defaultServerLanguageData!.length, (index) {
            LanguageJsonData data = defaultServerLanguageData![index];
            final bool selected = (sharedPref.getString(SELECTED_LANGUAGE_CODE) ?? defaultLanguageCode) == data.languageCode;
            return inkWellWidget(
              onTap: () async {
                setValue(SELECTED_LANGUAGE_CODE, data.languageCode);
                setValue(SELECTED_LANGUAGE_COUNTRY_CODE, data.countryCode);
                selectedServerLanguageData = data;
                setValue(IS_SELECTED_LANGUAGE_CHANGE, true);
                appStore.setLanguage(data.languageCode!, context: context);
                setState(() {});
                LiveStream().emit(CHANGE_LANGUAGE);
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? neonAccent : neonSurfaceCard,
                  border: Border.all(width: 1, color: selected ? neonAccent : neonAccent.withOpacity(0.38)),
                  borderRadius: radius(),
                ),
                width: (MediaQuery.of(context).size.width - 44) / 2,
                child: Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(4), child: commonCachedNetworkImage(data.languageImage.validate(), width: 34, height: 34)),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Text(
                        '${data.languageName.validate()}',
                        style: primaryTextStyle(color: selected ? neonOnAccent : Colors.white, size: 14),
                      ),
                    ),
                    sharedPref.getString(SELECTED_LANGUAGE_CODE).validateLanguage() == data.languageCode
                        ? Icon(Icons.radio_button_checked, size: 20, color: selected ? neonOnAccent : neonAccent)
                        : Icon(Icons.radio_button_off, size: 20, color: neonHighlight.withOpacity(0.55)),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
