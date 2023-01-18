import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:freeflow/app_config.dart';
import 'package:freeflow/helpers/shared_preference_data.dart';
import 'package:freeflow/screens/enter_username_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../globals/globals.dart';
import '../helpers/hex_color.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key, required this.url}) : super(key: key);

  final String url;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late InAppWebView iaWebView;

  showWarningDialog() async {
    return await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Are you sure'),
            content: const Text('Are you sure you want to go back to the login screen?'),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Yes'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                  webView.goBack();
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          );
        });
  }

  Future<bool> _goBack() async {
    if (await webView.canGoBack()) {
      Uri? url = await webView.getUrl();

      List<String> listWhenCannotBack = [
        this.widget.url + '/dashboard',
        this.widget.url + '/whisper',
        this.widget.url + '/quantum',
        this.widget.url
      ];

      if (listWhenCannotBack.contains(url.toString())) {
        var canceled = await showWarningDialog();

        if (canceled) {
          await Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (BuildContext context) => EnterUsernameScreen()));

          return Future.value(true);
        }

        return Future.value(false);
      } else {
        await webView.goBack();
        return Future.value(false);
      }
    } else {
      var canceled = await showWarningDialog();
      if (canceled) {
        await Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (BuildContext context) => EnterUsernameScreen()));
        return Future.value(true);
      }

      return Future.value(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: HexColor('#ffffff'), // <-- SEE HERE
        statusBarIconBrightness: Brightness.dark, //<-- For Android SEE HERE (dark icons)
        statusBarBrightness: Brightness.light, //<-- For iOS SEE HERE (dark icons)
      ),
      child: WillPopScope(
        onWillPop: () async {
          return await _goBack();
        },
        child: Scaffold(
          body: Container(
              child: Column(children: <Widget>[
            Expanded(
              child: Container(
                  padding: const EdgeInsets.only(top: 45),
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(url: Uri.parse(widget.url)),
                    initialOptions: InAppWebViewGroupOptions(
                        crossPlatform: InAppWebViewOptions(
                          useShouldOverrideUrlLoading: true,
                        ),
                        android: AndroidInAppWebViewOptions(
                            supportMultipleWindows: true, thirdPartyCookiesEnabled: true, useHybridComposition: true),
                        ios: IOSInAppWebViewOptions()),
                    onWebViewCreated: (InAppWebViewController controller) async {
                      webView = controller;
                      setState(() {});
                      addWebViewHandlers();
                    },
                    onConsoleMessage: (InAppWebViewController controller, ConsoleMessage consoleMessage) {
                      print("FreeFlow console: " + consoleMessage.message);
                    },
                    onReceivedServerTrustAuthRequest: (controller, challenge) async {
                      return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      final uri = navigationAction.request.url;

                      hasLoaded = true;
                      if (uri.toString().startsWith(AppConfig().deepLink())) {
                        _launchUrl(uri);
                        return NavigationActionPolicy.CANCEL;
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                    onLoadError: (controller, url, int i, String s) async {
                      print('CUSTOM_HANDLER: $i, $s, $url');
                    },
                    onLoadStop: (controller, url) {},
                  )),
            ),
          ])),
        ),
      ),
    );
  }

  addWebViewHandlers() {
    webView.addJavaScriptHandler(handlerName: "VUE_INITIALIZED", callback: initializedHandler);
    webView.addJavaScriptHandler(handlerName: "RETRIEVE_IDENTIFIER", callback: retrieveIdentifier);
    print('Added handlers');
  }

  Future<void> initializedHandler(List<dynamic> params) async {
    print('RECEIVED VUE_INITIALIZED');
  }

  Future<String> retrieveIdentifier(List<dynamic> params) async {
    print('RECEIVED RETRIEVE_IDENTIFIER');
    print(await getIdentifierInStorage());
    return await getIdentifierInStorage();
  }

  Future<void> _launchUrl(url) async {
    if (!await launchUrl(url)) {
      print('Could not launch app');
    }
  }
}
