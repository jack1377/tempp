import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:ui'; 
import 'package:flutter/foundation.dart';

// ایمپورت صحیح بر اساس نام پروژه شما (temp_monitor)
import 'package:temp_monitor/firebase_options.dart'; 


// ====================================================================
// مدل داده‌ای علائم حیاتی
// ====================================================================

class VitalSigns {
  final double temperature;
  final int heartRate;
  final int spo2;
  final int timestamp; 

  VitalSigns({
    required this.temperature,
    required this.heartRate,
    required this.spo2,
    required this.timestamp,
  });

  factory VitalSigns.fromSnapshot(Map<dynamic, dynamic> data) {
    return VitalSigns(
      // استفاده از ?? 0 برای جلوگیری از خطای Null
      temperature: (data['T'] as num? ?? 0).toDouble(), 
      heartRate: (data['HR'] as num? ?? 0).toInt(),
      spo2: (data['SpO2'] as num? ?? 0).toInt(),
      timestamp: (data['TS'] as num? ?? 0).toInt(),
    );
  }
}

// ====================================================================
// تعریف پایگاه داده با آدرس دقیق
// ====================================================================
// تعریف به صورت getter برای اطمینان از مقداردهی شدن Firebase.app()
FirebaseDatabase get _database {
  return FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: "https://temp-monitor-d2607-default-rtdb.firebaseio.com/",
  );
}


// ====================================================================
// تابع اصلی و راه‌اندازی
// ====================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مانیتور علائم حیاتی',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'RobotoMono', 
      ),
      home: FirebaseInitializer(),
    );
  }
}

// ====================================================================
// ویجت راه‌انداز Firebase با مدیریت خطا 
// ====================================================================
class FirebaseInitializer extends StatelessWidget {
  
  Future<void> _initializeFirebase() async {
    try {
      // 1. راه‌اندازی هسته Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // 2. ورود ناشناس (برای مطابقت با قوانین "auth != null")
      await FirebaseAuth.instance.signInAnonymously();
      print('✅ اتصال به Firebase و ورود ناشناس موفقیت‌آمیز بود.');
      
    } on FirebaseException catch (e) {
      String errorMessage = 'خطای Firebase: کد (${e.code}). پیام: ${e.message}';
      throw Exception(errorMessage); 
    } catch (e) {
      throw Exception('خطای ناشناخته در راه‌اندازی Firebase: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeFirebase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.teal),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('خطای جدی سیستم', style: TextStyle(color: Colors.amber))),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 15),
                    Text(
                      '❌ خطا در راه‌اندازی Firebase ❌',
                      style: TextStyle(color: Colors.red[400], fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      snapshot.error.toString().replaceFirst('Exception:', ''), 
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 20),
                    const Text('لطفا فایل‌های پیکربندی و اتصال اینترنت را بررسی کنید.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
            ),
          );
        }

        return VitalMonitorScreen();
      },
    );
  }
}

// ====================================================================
// صفحه نمایش مانیتور علائم حیاتی (با خواندن یک‌باره از temperature_data)
// ====================================================================

class VitalMonitorScreen extends StatelessWidget {
  
  // 🎯 خواندن یک‌باره از گره جدید و صحیح: 'temperature_data'
  final Future<DatabaseEvent> _dataFuture = _database.ref('temperature_data').once();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        title: const Text('مانیتور علائم حیاتی - داده‌های ذخیره شده', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300)),
        backgroundColor: Colors.blueGrey[900],
        elevation: 0,
      ),
      body: FutureBuilder<DatabaseEvent>(
        future: _dataFuture, 
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          
          if (snapshot.hasError) {
             // ⚠️ خطای اصلی "Permission Denied" یا خطاهای دیگر در اینجا نمایش داده می‌شوند
             return Center(child: Text('🚨 خطای RTDB: ${snapshot.error.toString()}', style: TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }
          
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('هیچ داده‌ای در temperature_data موجود نیست.', style: TextStyle(color: Colors.grey, fontSize: 24)));
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final currentVitals = VitalSigns.fromSnapshot(data);

          return GridView.count(
            crossAxisCount: 2, 
            padding: const EdgeInsets.all(15),
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: <Widget>[
              _buildVitalCard(title: 'ضربان قلب (HR)', value: '${currentVitals.heartRate}', unit: 'bpm', color: Colors.redAccent, icon: Icons.favorite),
              _buildVitalCard(title: 'اکسیژن خون (SpO₂)', value: '${currentVitals.spo2}', unit: '%', color: Colors.lightBlueAccent, icon: Icons.water_drop),
              _buildVitalCard(title: 'دمای بدن (Temp)', value: '${currentVitals.temperature.toStringAsFixed(1)}', unit: '°C', color: Colors.amberAccent, icon: Icons.thermostat),
              _buildVitalCard(
                title: 'زمان ذخیره داده', 
                value: '${DateTime.fromMillisecondsSinceEpoch(currentVitals.timestamp).toString().substring(11,19)}', 
                unit: 'زمان', color: Colors.grey[700]!, icon: Icons.schedule,
              ),
            ],
          );
        },
      ),
    );
  }

  // ویجت کمکی برای ساخت کارت‌ها
  Widget _buildVitalCard({required String title, required String value, required String unit, required Color color, required IconData icon}) {
    return Card(
      color: Colors.black,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: color, width: 3), 
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w300)),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 72, 
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()], 
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    unit,
                    style: const TextStyle(color: Colors.white54, fontSize: 24),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
