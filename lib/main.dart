import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:heroes2048game/pages/home_page.dart';
import 'package:heroes2048game/services/ad_state.dart';
import 'firebase_options.dart';

AppOpenAd? openAd;
Future<void> loadAd() async {
  await AppOpenAd.load(
    adUnitId:  AdState.openAppAdUnitId,
    request: const AdRequest(),
    orientation: AppOpenAd.orientationPortrait,
    adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print("AD is loaded");
          openAd = ad;
          openAd?.show();
        },
        onAdFailedToLoad: (error) {}
    ),
  );
}

void main() async {

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    MobileAds.instance.initialize();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    loadAd(); /// AppOpenAd

    runApp(MyApp());
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
}

class MyApp extends StatelessWidget {

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
  FirebaseAnalyticsObserver(analytics: analytics);

  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Heroes 2048 game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
      navigatorObservers: <NavigatorObserver>[observer],
    );
  }
}