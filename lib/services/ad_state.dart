import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdState {
  Future<InitializationStatus> initialization;

  AdState(this.initialization);

  static String openAppAdUnitId = "ca-app-pub-2100935671633643/5601050507";
  // static String openAppAdUnitId = "ca-app-pub-3940256099942544/3419835294"; // TestId


  static String mainBannerAdUnitId = "ca-app-pub-2100935671633643/7593822860";
  // static String mainBannerAdUnitId = "ca-app-pub-3940256099942544/6300978111"; // TestId


  // static String bannerAdUnitId = "ca-app-pub-2100935671633643/2735435129";
  // static String pauseBannerAdUnitId = "ca-app-pub-3940256099942544/6300978111"; // TestId

  static String interstitialAdUnitId = "ca-app-pub-2100935671633643/7386186721";
  // static String interstitialAdUnitId = "ca-app-pub-3940256099942544/1033173712"; // TestId

  static String rewardedAdUnitId = "ca-app-pub-2100935671633643/9453699446";
  // static String rewardedAdUnitId = "ca-app-pub-3940256099942544/5224354917"; // TestId

  // BannerAdListener get adListener => _adListener;
  // final BannerAdListener _adListener = BannerAdListener (
  //   onAdLoaded: (ad) => print("Ad loaded: ${ad.adUnitId}"),
  //   onAdClosed: (ad) => print("Ad closed ${ad.adUnitId}"),
  //   onAdFailedToLoad: (ad, error) => print("Ad failed to load: ${ad.adUnitId}, $error"),
  //   onAdOpened: (ad) => print("Ad opened: ${ad.adUnitId}"),
  // );




}