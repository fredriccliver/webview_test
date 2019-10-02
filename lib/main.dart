import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Todo: have to prevent open 'hotels.com' in hotel.com native app.
// Todo: change the _blank target. bypass the opening in new tab while browsing.


void main() => runApp(MyApp());

class UrlManager extends ChangeNotifier {
  String _url = '';
  String get url => _url;
  WebViewController _webViewController;
  void updateUrl(String newUrl) {
    _url = newUrl;
    print('new url is : ' + newUrl);
    // todo: if there 'http', attach or search in google
  }

  void registerWebview(WebViewController wvc) {
    _webViewController = wvc;
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // WebViewController _webviewController;
    final Completer<WebViewController> webviewController =
        Completer<WebViewController>();
    String homeUrl = 'https://google.com';
    final urlBarController = TextEditingController(text: '');
    // String CurrentUrl = '';
    // WebViewController controller;

    return ChangeNotifierProvider(
      builder: (_) => UrlManager(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Consumer<UrlManager>(builder: (context, urlmanager, _){
                      return CupertinoTextField(
                        style: TextStyle(color: CupertinoColors.inactiveGray),
                        placeholder: "URL",
                        enabled: true,
                        controller: urlBarController,
                        onEditingComplete: () {
                          print('onEditingComplete');
                        },
                        onSubmitted: (String str) {
                          print('onSubmitted');
                          urlmanager._webViewController.loadUrl(str);
                        },
                      );
                    }),
                  ),
                  Consumer<UrlManager>(builder: (context, urlmanager, _) {
                    return Expanded(
                      child: WebView(
                        initialUrl: homeUrl,
                        javascriptMode: JavascriptMode.unrestricted,
                        onWebViewCreated: (WebViewController cont) {
                          print('webview was created.');
                          webviewController.complete(cont);
                          urlmanager.registerWebview(cont);
                          urlBarController.text = cont.currentUrl().toString();
                        },
                        onPageFinished: (String url) {
                          urlmanager._webViewController.evaluateJavascript("window.open = function(open) { return function (url, name, features) { window.location.href = url; return window; }; } (window.open);");
                          print('url changed : ' + url);
                          urlBarController.text = url;
                          urlmanager.updateUrl(url);
                          // Scaffold.of(context).showSnackBar(SnackBar(content: Text(url),));
                        },
                      ),
                    );
                  }),
                  new NavigationControls(webviewController.future),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls(this._webViewControllerFuture)
      : assert(_webViewControllerFuture != null);

  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
        future: _webViewControllerFuture,
        builder:
            (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
          // final bool webViewReady =
          //     snapshot.connectionState == ConnectionState.done;
          final WebViewController controller = snapshot.data;
          return Row(
            children: <Widget>[
              CupertinoButton(
                child: Text('Back'),
                onPressed: () {
                  controller.goBack();
                },
              ),
              CupertinoButton(
                child: Text('Forward'),
                onPressed: () {
                  controller.goForward();
                },
              ),
              CupertinoButton(
                child: Text('Refresh'),
                onPressed: () {
                  controller.reload();
                },
              ),
              Spacer(),
              CupertinoButton(
                child: Text('Scrap'),
                onPressed: () async {
                  String docu = await controller
                      .evaluateJavascript('document.documentElement.innerHTML');
                  // print(docu);
                  var dom = parse(docu);
                  var str = dom.getElementsByTagName('title')[0].innerHtml;
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text(str),
                  ));
                },
              ),
            ],
          );
        });
  }
}
