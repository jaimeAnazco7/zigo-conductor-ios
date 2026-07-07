import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../utils/Colors.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/legal_urls.dart';
import '../utils/utils.dart';

class TermsConditionScreen extends StatefulWidget {
  final String? title;
  final String? subtitle;

  TermsConditionScreen({this.title, this.subtitle});

  @override
  TermsConditionScreenState createState() => TermsConditionScreenState();
}

class TermsConditionScreenState extends State<TermsConditionScreen> {
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    if (isHttpOrHttpsUrl(widget.subtitle)) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(widget.subtitle!.trim()));
    }
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
        title: Text(widget.title.validate(), style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: ColoredBox(
        color: neonBackground,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (isHttpOrHttpsUrl(widget.subtitle) && _webViewController != null) {
      return WebViewWidget(controller: _webViewController!);
    }
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 16, top: 24, right: 16, bottom: 24),
      child: HtmlWidget(
        widget.subtitle.validate(),
        textStyle: TextStyle(color: Colors.white, fontSize: 15, height: 1.45),
      ),
    );
  }
}
