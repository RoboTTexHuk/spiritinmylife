// -----------------------------------------------------------------------------
// Spirit-flavored refactor: все классы и переменные переименованы в стиле "spirit"
// -----------------------------------------------------------------------------

import 'dart:convert';
import 'dart:io';

import 'package:appsflyer_sdk/appsflyer_sdk.dart' show AppsFlyerOptions, AppsflyerSdk;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodCall, MethodChannel, SystemUiOverlayStyle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// Предполагаемые новые имена экранов в main.dart
import 'main.dart' show SpiritMafiaHarbor, SpiritCaptainHarbor, CaptainHarbor, CaptainDeck;

// ============================================================================
// Паттерны/инфраструктура (spirit edition)
// ============================================================================

class SpiritBlackBox {
  const SpiritBlackBox();
  void spiritLog(Object msg) => debugPrint('[SpiritBlackBox] $msg');
  void spiritWarn(Object msg) => debugPrint('[SpiritBlackBox/WARN] $msg');
  void spiritErr(Object msg) => debugPrint('[SpiritBlackBox/ERR] $msg');
}

class SpiritRumChest {
  static final SpiritRumChest _spiritSingle = SpiritRumChest._spirit();
  SpiritRumChest._spirit();
  factory SpiritRumChest() => _spiritSingle;

  final SpiritBlackBox spiritBox = const SpiritBlackBox();
}

/// Утилиты маршрутов/почты (Spirit Sextant)
class SpiritSextantKit {
  // Похоже ли на голый e-mail (без схемы)
  static bool spiritLooksLikeBareMail(Uri spiritUri) {
    final s = spiritUri.scheme;
    if (s.isNotEmpty) return false;
    final raw = spiritUri.toString();
    return raw.contains('@') && !raw.contains(' ');
  }

  // Превращает "bare" или обычный URL в mailto:
  static Uri spiritToMailto(Uri spiritUri) {
    final full = spiritUri.toString();
    final bits = full.split('?');
    final who = bits.first;
    final qp = bits.length > 1 ? Uri.splitQueryString(bits[1]) : <String, String>{};
    return Uri(
      scheme: 'mailto',
      path: who,
      queryParameters: qp.isEmpty ? null : qp,
    );
  }

  // Делает Gmail compose-ссылку
  static Uri spiritGmailize(Uri spiritMailto) {
    final qp = spiritMailto.queryParameters;
    final params = <String, String>{
      'view': 'cm',
      'fs': '1',
      if (spiritMailto.path.isNotEmpty) 'to': spiritMailto.path,
      if ((qp['subject'] ?? '').isNotEmpty) 'su': qp['subject']!,
      if ((qp['body'] ?? '').isNotEmpty) 'body': qp['body']!,
      if ((qp['cc'] ?? '').isNotEmpty) 'cc': qp['cc']!,
      if ((qp['bcc'] ?? '').isNotEmpty) 'bcc': qp['bcc']!,
    };
    return Uri.https('mail.google.com', '/mail/', params);
  }

  static String spiritJustDigits(String s) => s.replaceAll(RegExp(r'[^0-9+]'), '');
}

/// Сервис открытия внешних ссылок/протоколов (Spirit Messenger)
class SpiritParrotSignal {
  static Future<bool> spiritOpen(Uri spiritUri) async {
    try {
      if (await launchUrl(spiritUri, mode: LaunchMode.inAppBrowserView)) return true;
      return await launchUrl(spiritUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('SpiritParrotSignal error: $e; url=$spiritUri');
      try {
        return await launchUrl(spiritUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }
}

// ============================================================================
// FCM Background Handler — дух-попугай
// ============================================================================
@pragma('vm:entry-point')
Future<void> spiritBgParrot(RemoteMessage spiritBottle) async {
  debugPrint("Spirit Bottle ID: ${spiritBottle.messageId}");
  debugPrint("Spirit Bottle Data: ${spiritBottle.data}");
}

// ============================================================================
// Виджет-каюта с webview — SpiritCaptainDeck
// ============================================================================
class SpiritCaptainDeck extends StatefulWidget with WidgetsBindingObserver {
  String spiritSeaRoute;
  SpiritCaptainDeck(this.spiritSeaRoute, {super.key});

  @override
  State<SpiritCaptainDeck> createState() => _SpiritCaptainDeckState(spiritSeaRoute);
}

class _SpiritCaptainDeckState extends State<SpiritCaptainDeck> with WidgetsBindingObserver {
  _SpiritCaptainDeckState(this._spiritCurrentRoute);

  final SpiritRumChest _spiritRum = SpiritRumChest();

  late InAppWebViewController _spiritHelm; // штурвал
  String? _spiritParrotToken; // FCM token
  String? _spiritShipId; // device id
  String? _spiritShipBuild; // os build
  String? _spiritShipKind; // android/ios
  String? _spiritShipOS; // locale/lang
  String? _spiritAppSextant; // timezone
  bool _spiritCannonArmed = true; // push enabled
  bool _spiritCrewBusy = false;
  var _spiritGateOpen = true;
  String _spiritCurrentRoute;
  DateTime? _spiritLastDockTime;

  // Внешние гавани (tg/wa/bnl)
  final Set<String> _spiritHarborHosts = {
    't.me', 'telegram.me', 'telegram.dog',
    'wa.me', 'api.whatsapp.com', 'chat.whatsapp.com',
    'bnl.com', 'www.bnl.com',
  };
  final Set<String> _spiritHarborSchemes = {'tg', 'telegram', 'whatsapp', 'bnl'};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    FirebaseMessaging.onBackgroundMessage(spiritBgParrot);

    _spiritRigParrotFCM();
    _spiritScanShipGizmo();
    _spiritWireForedeckFCM();
    _bindBell();

    Future.delayed(const Duration(seconds: 2), () {});
    Future.delayed(const Duration(seconds: 6), () {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState spiritTide) {
    if (spiritTide == AppLifecycleState.paused) {
      _spiritLastDockTime = DateTime.now();
    }
    if (spiritTide == AppLifecycleState.resumed) {
      if (Platform.isIOS && _spiritLastDockTime != null) {
        final now = DateTime.now();
        final drift = now.difference(_spiritLastDockTime!);
        if (drift > const Duration(minutes: 25)) {
          _spiritHardReloadToHarbor();
        }
      }
      _spiritLastDockTime = null;
    }
  }

  void _spiritHardReloadToHarbor() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CaptainHarbor(signal: "")),
            (route) => false,
      );
    });
  }

  // --------------------------------------------------------------------------
  // Каналы связи
  // --------------------------------------------------------------------------
  void _spiritWireForedeckFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage spiritBottle) {
      if (spiritBottle.data['uri'] != null) {
        _spiritSailTo(spiritBottle.data['uri'].toString());
      } else {
        _spiritReturnToCourse();
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage spiritBottle) {
      if (spiritBottle.data['uri'] != null) {
        _spiritSailTo(spiritBottle.data['uri'].toString());
      } else {
        _spiritReturnToCourse();
      }
    });
  }

  void _spiritSailTo(String spiritNewLane) async {
    await _spiritHelm.loadUrl(urlRequest: URLRequest(url: WebUri(spiritNewLane)));
  }

  void _spiritReturnToCourse() async {
    Future.delayed(const Duration(seconds: 3), () {
      _spiritHelm.loadUrl(urlRequest: URLRequest(url: WebUri(_spiritCurrentRoute)));
    });
  }

  Future<void> _spiritRigParrotFCM() async {
    FirebaseMessaging spiritDeck = FirebaseMessaging.instance;
    await spiritDeck.requestPermission(alert: true, badge: true, sound: true);
    _spiritParrotToken = await spiritDeck.getToken();
  }

  // --------------------------------------------------------------------------
  // Досье корабля
  // --------------------------------------------------------------------------
  Future<void> _spiritScanShipGizmo() async {
    try {
      final spiritSpy = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await spiritSpy.androidInfo;
        _spiritShipId = a.id;
        _spiritShipKind = "android";
        _spiritShipBuild = a.version.release;
      } else if (Platform.isIOS) {
        final i = await spiritSpy.iosInfo;
        _spiritShipId = i.identifierForVendor;
        _spiritShipKind = "ios";
        _spiritShipBuild = i.systemVersion;
      }
      final spiritPkg = await PackageInfo.fromPlatform();
      _spiritShipOS = Platform.localeName.split('_')[0];
      _spiritAppSextant = timezone.local.name;
    } catch (e) {
      debugPrint("Spirit Ship Gizmo Error: $e");
    }
  }

  void _bindBell() {
    MethodChannel('com.example.fcm/notification').setMethodCallHandler((call) async {
      if (call.method == "onNotificationTap") {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(call.arguments);
        if (payload["uri"] != null && !payload["uri"].contains("Нет URI")) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => CaptainDeck(payload["uri"].toString())),
                (route) => false,
          );
        }
      }
    });
  }

  // --------------------------------------------------------------------------
  // Построение UI
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    _bindBell(); // повторная привязка

    final spiritIsNight = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: spiritIsNight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            InAppWebView(
              initialSettings:  InAppWebViewSettings(
                javaScriptEnabled: true,
                disableDefaultErrorPage: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                allowsPictureInPictureMediaPlayback: true,
                useOnDownloadStart: true,
                javaScriptCanOpenWindowsAutomatically: true,
                useShouldOverrideUrlLoading: true,
                supportMultipleWindows: true,
              ),
              initialUrlRequest: URLRequest(url: WebUri(_spiritCurrentRoute)),
              onWebViewCreated: (spiritController) {
                _spiritHelm = spiritController;

                _spiritHelm.addJavaScriptHandler(
                  handlerName: 'onServerResponse',
                  callback: (spiritArgs) {
                    _spiritRum.spiritBox.spiritLog("JS Args: $spiritArgs");
                    try {
                      return spiritArgs.reduce((v, e) => v + e);
                    } catch (_) {
                      return spiritArgs.toString();
                    }
                  },
                );
              },
              onLoadStart: (spiritController, spiritUri) async {
                if (spiritUri != null) {
                  if (SpiritSextantKit.spiritLooksLikeBareMail(spiritUri)) {
                    try {
                      await spiritController.stopLoading();
                    } catch (_) {}
                    final mailto = SpiritSextantKit.spiritToMailto(spiritUri);
                    await SpiritParrotSignal.spiritOpen(SpiritSextantKit.spiritGmailize(mailto));
                    return;
                  }
                  final s = spiritUri.scheme.toLowerCase();
                  if (s != 'http' && s != 'https') {
                    try {
                      await spiritController.stopLoading();
                    } catch (_) {}
                  }
                }
              },
              onLoadStop: (spiritController, spiritUri) async {
                await spiritController.evaluateJavascript(source: "console.log('Ahoy from JS!');");
              },
              shouldOverrideUrlLoading: (spiritController, spiritNav) async {
                final spiritUri = spiritNav.request.url;
                if (spiritUri == null) return NavigationActionPolicy.ALLOW;

                if (SpiritSextantKit.spiritLooksLikeBareMail(spiritUri)) {
                  final mailto = SpiritSextantKit.spiritToMailto(spiritUri);
                  await SpiritParrotSignal.spiritOpen(SpiritSextantKit.spiritGmailize(mailto));
                  return NavigationActionPolicy.CANCEL;
                }

                final sch = spiritUri.scheme.toLowerCase();
                if (sch == 'mailto') {
                  await SpiritParrotSignal.spiritOpen(SpiritSextantKit.spiritGmailize(spiritUri));
                  return NavigationActionPolicy.CANCEL;
                }

                if (_spiritIsOuterHarbor(spiritUri)) {
                  await SpiritParrotSignal.spiritOpen(_spiritMapOuterToHttp(spiritUri));
                  return NavigationActionPolicy.CANCEL;
                }

                if (sch != 'http' && sch != 'https') {
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
              onCreateWindow: (spiritController, spiritReq) async {
                final u = spiritReq.request.url;
                if (u == null) return false;

                if (SpiritSextantKit.spiritLooksLikeBareMail(u)) {
                  final m = SpiritSextantKit.spiritToMailto(u);
                  await SpiritParrotSignal.spiritOpen(SpiritSextantKit.spiritGmailize(m));
                  return false;
                }

                final sch = u.scheme.toLowerCase();
                if (sch == 'mailto') {
                  await SpiritParrotSignal.spiritOpen(SpiritSextantKit.spiritGmailize(u));
                  return false;
                }

                if (_spiritIsOuterHarbor(u)) {
                  await SpiritParrotSignal.spiritOpen(_spiritMapOuterToHttp(u));
                  return false;
                }

                if (sch == 'http' || sch == 'https') {
                  spiritController.loadUrl(urlRequest: URLRequest(url: u));
                }
                return false;
              },
            ),

            if (_spiritCrewBusy)
              Positioned.fill(
                child: Container(
                  color: Colors.black87,
                  child: Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.grey.shade800,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                      strokeWidth: 6,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // Пиратские утилиты маршрутов (протоколы/внешние гавани)
  // ========================================================================
  bool _spiritIsOuterHarbor(Uri spiritUri) {
    final sch = spiritUri.scheme.toLowerCase();
    if (_spiritHarborSchemes.contains(sch)) return true;

    if (sch == 'http' || sch == 'https') {
      final h = spiritUri.host.toLowerCase();
      if (_spiritHarborHosts.contains(h)) return true;
    }
    return false;
  }

  Uri _spiritMapOuterToHttp(Uri spiritUri) {
    final sch = spiritUri.scheme.toLowerCase();

    if (sch == 'tg' || sch == 'telegram') {
      final qp = spiritUri.queryParameters;
      final domain = qp['domain'];
      if (domain != null && domain.isNotEmpty) {
        return Uri.https('t.me', '/$domain', {
          if (qp['start'] != null) 'start': qp['start']!,
        });
      }
      final path = spiritUri.path.isNotEmpty ? spiritUri.path : '';
      return Uri.https('t.me', '/$path', qp.isEmpty ? null : qp);
    }

    if (sch == 'whatsapp') {
      final qp = spiritUri.queryParameters;
      final phone = qp['phone'];
      final text = qp['text'];
      if (phone != null && phone.isNotEmpty) {
        return Uri.https('wa.me', '/${SpiritSextantKit.spiritJustDigits(phone)}', {
          if (text != null && text.isNotEmpty) 'text': text,
        });
      }
      return Uri.https('wa.me', '/', {if (text != null && text.isNotEmpty) 'text': text});
    }

    if (sch == 'bnl') {
      final newPath = spiritUri.path.isNotEmpty ? spiritUri.path : '';
      return Uri.https('bnl.com', '/$newPath', spiritUri.queryParameters.isEmpty ? null : spiritUri.queryParameters);
    }

    return spiritUri;
  }
}