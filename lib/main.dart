import 'dart:convert';
//import 'VideoCallPage.dart';
import 'check_internet.dart';
import 'notification_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info/device_info.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gradient_animation_text/flutter_gradient_animation_text.dart';

import 'dart:async';
import 'VideoCall.dart'; // Import your VideoCallPage

import 'audiocall.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
//import 'package:razorpay_web/razorpay_web.dart';
import 'razorpay.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  // Initialize Flutter Local Notifications
  //FirebaseAdMob.instance.initialize(appId: 'ca-app-pub-7485117943588110~1348926440');
  const initializationSettingsAndroid =
   AndroidInitializationSettings('@mipmap/ic_launcher');


  const initializationSettingsIOS = IOSInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,

  );
  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      appId: '1:223793989507:android:69fc7f1a656463d8b858b6',
      apiKey: 'AIzaSyCvzI3kUIScQy_duF69HbGw9sFzd-Mnl_A',
      projectId: 'umeed-2d7e6',
      messagingSenderId: ''
    ),
  );


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromRGBO(33, 37, 41, 1.0) // Set your desired color here
    ));
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: const Color.fromRGBO(33, 37, 41, 1.0), // Set your desired color here
        body: SafeArea(
          child: MyWebView(initialUrl: 'https://umeed.app/start'),
        ),
      ),
    );
  }
}



class MyWebView extends StatefulWidget {
  const MyWebView({Key? key, required this.initialUrl}) : super(key: key);
  final String initialUrl;


  @override
  _MyWebViewState createState() => _MyWebViewState();

}

class _MyWebViewState extends State<MyWebView>  with WidgetsBindingObserver {
  //late WebViewController __webViewController;

  bool _isLoading = true;
  InAppWebViewSettings settings = InAppWebViewSettings(
    // crossPlatform: InAppWebViewSetting(
      userAgent: "flutterAppUserAgent", // Customize this user agent
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      supportMultipleWindows: true,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true,
      saveFormData: true,
      networkAvailable: true
    //),
    // android: AndroidInAppWebViewOptions(supportMultipleWindows: true,
    //  ),
    //  ios: IOSInAppWebViewOptions(),
  );

  late FirebaseMessaging _firebaseMessaging; // Add this line
  late InAppWebViewController _webViewController;
  late bool canGoBack;


  String dynamicLink = '';
  InterstitialAd? interstitialAd;
  Timer? adTimer;

  String? userId;

  int checkInt = -1;



  @override
  void initState() {
    super.initState();
    _checkInternetConnection();


    canGoBack = false;
    FlutterLocalNotificationsPlugin().initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),

      ),
    );

    _firebaseMessaging =
        FirebaseMessaging.instance; // Initialize Firebase Cloud Messaging
    _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    _firebaseMessaging.subscribeToTopic('flutter_notification');
    void handleFCMNotification(Map<String, dynamic> message) {
      final String? title = message['data']['title'];
      final String? body = message['data']['body'];

      // Display the notification directly without checking deviceId
      NotificationHandler.showNotification(
        id: 0, // You can use any unique identifier here
        title: title ?? 'Notification Title',
        body: body ?? 'Notification Body',
      );
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle the message when the app is in the foreground
      handleFCMNotification(message.data);
    });
    // Subscribe to FCM topic

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle the message when the app is opened from a terminated state
      handleFCMNotification(message.data);
    });



  }




  void loadAndShowAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-7485117943588110/2856878412',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          interstitialAd = ad;
          interstitialAd?.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (kDebugMode) {
            print('Ad failed to load: $error');
          }
        },
      ),
    );
  }
  void startAds() {
    // Check if the timer is already running
    loadAndShowAd();
    if (adTimer == null || !adTimer!.isActive) {
      // Start the timer only if it's not already running
      adTimer = Timer.periodic(const Duration(seconds: 120), (timer) {
        loadAndShowAd();
      });
    }
  }

  void stopAds() {
    // Pause the ads when "stopads" is received
    if (adTimer != null && adTimer!.isActive) {
      adTimer!.cancel();
    }
    interstitialAd?.dispose(); // Dispose of the current ad
  }





  Future<void> _checkInternetConnection() async {
    int value = await CheckInternet().checkInternetConnection();
    if (value == 0) {
      setState(() {
        checkInt = 0;
      });
    } else {
      setState(() {
        checkInt = 1;
      });
    }
    Future.delayed(Duration.zero, () {
      _requestPermissions(context);
    });
  }

  Future<void> _requestPermissions(BuildContext context) async {
  //Future<void> _requestPermissions() async {
    WidgetsFlutterBinding.ensureInitialized();

    /*if (Platform.isAndroid) {
      await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
    }*/
    await FlutterDownloader.initialize(debug: true);
    // set true to enable printing logs to console
    //await Permission.storage.request();
    await Permission.mediaLibrary.request();
    await Permission.manageExternalStorage.request();
    await Permission.microphone.request();
    await Permission.camera.request();
    await Permission.storage.request();
    await Permission.bluetooth.request(); // Add Bluetooth permission
    await Permission.notification.request(); // Add Notification permission
    //await Permission.internet.request(); // Add Internet permission


    // ask for storage permission on app create


  }

  Future<void> _handleUserIdExtraction(String userId) async {
    // Handle the user ID extracted from JavaScript
    if (kDebugMode) {
      print('User ID from JavaScript: $userId');
    }

    // Get the device ID from Flutter
    final String fcmToken = await getFCMToken();

    if (kDebugMode) {
      print('FCM Token from Flutter: $fcmToken');
    }

    // Now, you have both userId and deviceId, you can send them to your Flask app.
    await postDataToFlask(userId, fcmToken);
  }

  Future<String> getFCMToken() async {
    final fcmToken = await _firebaseMessaging.getToken();
    return fcmToken ?? '';
  }


  Future<void> postDataToFlask(String? userId, String? fcmToken) async {
    if (userId != null) {
      if (kDebugMode) {
        print('FCM Token: $fcmToken');
      }
      if (kDebugMode) {
        print('User ID: $userId');
      }

      // Load local storage (SharedPreferences) to check if the data was sent successfully before
      final prefs = await SharedPreferences.getInstance();
      final bool dataSent = prefs.getBool('data_sent') ?? false;

      if (dataSent) {
        // Data has already been sent successfully, no need to send again
        if (kDebugMode) {
          print('Data already sent successfully.');
        }
      } else {
        const url =
            'https://umeed.app/receive_user_data'; // Replace with your Flask app's endpoint
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json', // Set the content type to JSON
          },
          body: jsonEncode({
            'device_id': fcmToken,
            'userId': userId,
          }),
        );

        if (response.statusCode == 200) {
          // Data posted successfully.
          if (kDebugMode) {
            print('Data Posted Successfully: ${response.body}');
          }

          // Update local storage to indicate that the data has been sent
          await prefs.setBool('data_sent', true);
        } else {
          // Handle the error if the post request fails.
          if (kDebugMode) {
            print('Error Posting Data: ${response.statusCode}');
          }
          if (kDebugMode) {
            print('Response Body: ${response.body}');
          }

          // Data sending failed, you can handle retries or other logic here
        }
      }
    }
  }





  Future<bool> _onWillPop() async {
    if (await _webViewController.canGoBack()) {
      _webViewController.goBack();
      return false;
    } else {
      return true;
    }
  }


  @override
  Widget build(BuildContext context) {
    if (checkInt == 0) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No Internet Connection',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    //InAppWebViewGroupOptions options = InAppWebViewGroupOptions(

    return WillPopScope(
      // Use WillPopScope to intercept the back button press
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
              onLoadStop: (controller, url) {
                setState(() {
                  _isLoading = false;
                });
              },
              initialSettings: settings,
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onCreateWindow: (controller, createWindowAction) async {
                showDialog(
                  context: context,
                  builder: (context) {
                    return WindowPopup(createWindowAction: createWindowAction);
                  },
                );
                return true;
              },
              onConsoleMessage: (controller, consoleMessage) {
                // Handle console messages (e.g., JavaScript console.log)
                if (kDebugMode) {
                  print('Console Message: ${consoleMessage.message}');
                }
                if (consoleMessage.message.startsWith('UserID: ')) {
                  final userId = consoleMessage.message.split('UserID: ')[1];
                  _handleUserIdExtraction(userId);
                }
                if (consoleMessage.message.contains('Received Data:')) {
                  // Parse the received data and start the video call
                  final data = json.decode(
                      consoleMessage.message.split('Received Data:')[1].trim());
                  _startVideoCall(data['token'], data['channelName'], data['timer'],
                      data['user']);
                }

                if (consoleMessage.message.contains('Voice Data:')) {
                  // Parse the received data and start the video call
                  final data = json.decode(
                      consoleMessage.message.split('Voice Data:')[1].trim());
                  _startVoiceCall(data['token'], data['channelName'], data['timer'],
                      data['user']);
                }
                if (consoleMessage.message.contains('Razor:')) {
                  // Parse the received data and start the video call
                  final data = json.decode(
                      consoleMessage.message.split('Razor:')[1].trim());
                  _startRazor(data['amount'], data['currency'], data['contact'],
                      data['email']);
                }

                if (consoleMessage.message == 'startads') {
                  // Load and show the ad when "startads" is received
                  //loadAndShowAd();
                  //adTimer = Timer.periodic(const Duration(seconds: 120), (timer) {
                  //  loadAndShowAd();
                  // });
                  startAds();
                } else if (consoleMessage.message == 'stopads') {
                  // Pause the ads when "stopads" is received
                  //adTimer.cancel();
                  //interstitialAd?.dispose(); // Dispose of the current ad
                  stopAds();
                }
                if (consoleMessage.message.startsWith('Open External Link: ')) {
                  dynamicLink = consoleMessage.message.substring('Open External Link: '.length);
                  openLink(dynamicLink);
                }

              },
            ),
            if (_isLoading)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(), // Loader
                    SizedBox(height: 20), // Spacer

                    GradientAnimationText(
                      text: Text(
                        'Wait, you are entering a new LGBTQ+ world',

                      ),
                      colors: [
                        Color(0xff8f00ff),  // violet
                        Colors.indigo,
                        Colors.blue,
                        Colors.green,
                        Colors.yellow,
                        Colors.orange,
                        Colors.red,
                      ],
                      duration: Duration(seconds: 5),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );


  }

  void _startVoiceCall(String token, String channelName, int timer,
      String user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AudioCall(
              token: token,
              channelName: channelName,
              timer: timer,
              user: user,
              //userType: userType
            ),
      ),
    );
  }

  void _startVideoCall(String token, String channelName, int timer,
      String user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VideoCall(
              token: token,
              channelName: channelName,
              timer: timer,
              user: user,
            ),
      ),
    );
  }

  void _startRazor(int amount, String currency, String contact,
      String email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            Razor(
              amount: amount,
              currency: currency,
              contact: contact,
              email: email,
            ),
      ),
    );
  }

}
void openLink(String dynamicLink) {
  launchUrl(Uri.parse(dynamicLink));
}


class WindowPopup extends StatefulWidget {
  final CreateWindowAction createWindowAction;

  const WindowPopup({Key? key, required this.createWindowAction})
      : super(key: key);

  @override
  State<WindowPopup> createState() => _WindowPopupState();
}

class _WindowPopupState extends State<WindowPopup> {
  String title = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black), // Customize the border color
        ),
        child: InAppWebView(
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
          },
          windowId: widget.createWindowAction.windowId,
          onTitleChanged: (controller, title) {
            setState(() {
              this.title = title ?? '';
            });
          },
          onCloseWindow: (controller) {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

}

