// این فایل به صورت دستی برای پیکربندی Firebase بدون CLI ایجاد شده است.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
// kIsWeb و switch case برای پلتفرم‌های بومی اضافه شد
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb; 

/// کلاس FirebaseOptions که حاوی تمام پیکربندی‌های پلتفرم‌های مختلف است.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    
    // 1. اول از همه، بررسی می‌کنیم که آیا روی وب اجرا می‌شود یا خیر (با استفاده از kIsWeb).
    if (kIsWeb) { 
      return const FirebaseOptions(
        // **این مقادیر را با API Key و App ID واقعی وب خود جایگزین کنید!**
        apiKey: 'AIzaSyA5C2ubgJmIONViCeNYywQIs2wpVBFFc6Q', 
        appId: '1:1035898446761:web:e1c6b276a3186eef939ab8', 
        messagingSenderId: '1035898446761',
        projectId: 'temp-monitor-d2607',
        storageBucket: 'temp-monitor-d2607.firebasestorage.app"',
      );
    }

    // 2. سپس، پلتفرم‌های نیتیو (بومی) را بررسی می‌کنیم.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyA5C2ubgJmIONViCeNYywQIs2wpVBFFc6Q', 
          appId: '1:1035898446761:android:df99fbf0449e0418939ab8',
          messagingSenderId: '1035898446761',
          projectId: 'temp-monitor-d2607',
          storageBucket: 'temp-monitor-d2607.firebasestorage.app"',
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyA5C2ubgJmIONViCeNYywQIs2wpVBFFc6Q', 
          appId: '1:1035898446761:web:e1c6b276a3186eef939ab8',
          messagingSenderId: '1035898446761',
          projectId: 'temp-monitor-d2607',
          storageBucket: 'temp-monitor-d2607.firebasestorage.app"',
          iosClientId: 'YOUR_IOS_CLIENT_ID',
        );
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        // این گزینه برای بیلد لینوکس در حالت debug استفاده می‌شود.
        return const FirebaseOptions(
          apiKey: 'AIzaSyA5C2ubgJmIONViCeNYywQIs2wpVBFFc6Q', 
          appId: '1:1035898446761:web:e1c6b276a3186eef939ab8',
          messagingSenderId: '1035898446761',
          projectId: 'temp-monitor-d2607',
          storageBucket: 'temp-monitor-d2607.firebasestorage.app"',
        );
      case TargetPlatform.fuchsia:
        break; // فوشیا فعلاً پشتیبانی نمی‌شود
    }

    throw UnsupportedError(
      'پلتفرم مورد پشتیبانی نیست: '
      'DefaultFirebaseOptions فقط از Android, iOS, macOS, web, linux و windows پشتیبانی می‌کند.',
    );
  }
}
