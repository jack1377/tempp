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
      temperature: (data['T'] as num? ?? 0).toDouble(), 
      heartRate: (data['HR'] as num? ?? 0).toInt(),
      spo2: (data['SpO2'] as num? ?? 0).toInt(),
      timestamp: (data['TS'] as num? ?? 0).toInt(),
    );
  }
}

// ====================================================================
// مدل داده‌ای بیمار
// ====================================================================
class PatientInfo {
  final String name;
  final String lastName;
  final String age;
  final String medicalHistory;

  PatientInfo({
    required this.name,
    required this.lastName,
    required this.age,
    required this.medicalHistory,
  });
  
  String get fullName => '$name $lastName';
}

// ====================================================================
// تعریف پایگاه داده
// ====================================================================
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
        primaryColor: const Color(0xFF1E88E5), 
        scaffoldBackgroundColor: const Color(0xFF121212), 
        fontFamily: 'RobotoMono', 
      ),
      home: FirebaseInitializer(),
    );
  }
}

// ====================================================================
// ویجت راه‌انداز Firebase
// ====================================================================
class FirebaseInitializer extends StatelessWidget {
  
  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseException catch (e) {
      throw Exception('خطای Firebase: ${e.message}'); 
    } catch (e) {
      throw Exception('خطای ناشناخته: ${e.toString()}');
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
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('خطا')),
            body: Center(
              child: Text(
                '❌ خطا در راه‌اندازی: ${snapshot.error.toString()}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return PatientEntryScreen();
      },
    );
  }
}

// --------------------------------------------------------------------
// صفحه اول: ورود اطلاعات بیمار
// --------------------------------------------------------------------
class PatientEntryScreen extends StatefulWidget {
  @override
  _PatientEntryScreenState createState() => _PatientEntryScreenState();
}

class _PatientEntryScreenState extends State<PatientEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _lastName = '';
  String _age = '';
  String _medicalHistory = '';

  void _startMonitoring() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final patient = PatientInfo(
        name: _name,
        lastName: _lastName,
        age: _age,
        medicalHistory: _medicalHistory,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VitalMonitorScreen(patientInfo: patient),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1117), 
            Color(0xFF161B22),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          centerTitle: true, 
          title: const Text(
            'ورود اطلاعات بیمار', 
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.w600
            )
          ),
          backgroundColor: Colors.transparent, 
          elevation: 0,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'لطفاً مشخصات فردی را وارد کنید', 
                      style: TextStyle(
                        color: Colors.white70, 
                        fontSize: 18, 
                        fontWeight: FontWeight.w300
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    
                    // نام و نام خانوادگی
                    Row(
                      children: [
                        Expanded(child: _buildTextField('نام', (value) => _name = value ?? '')),
                        const SizedBox(width: 15),
                        Expanded(child: _buildTextField('نام خانوادگی', (value) => _lastName = value ?? '')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // سن
                    _buildTextField(
                      'سن', 
                      (value) => _age = value ?? '', 
                      keyboardType: TextInputType.number
                    ),
                    const SizedBox(height: 20),

                    // سابقه بیماری
                    _buildTextField(
                      'سابقه بیماری (اختیاری)', 
                      (value) => _medicalHistory = value ?? '', 
                      maxLines: 3,
                      required: false,
                    ),
                    const SizedBox(height: 30),

                    // دکمه شروع مانیتورینگ
                    ElevatedButton(
                      onPressed: _startMonitoring,
                      style: ElevatedButton.styleFrom(
                        // ✅ رفع خطای primary با استفاده از backgroundColor
                        backgroundColor: const Color(0xFF1E88E5), 
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'شروع مانیتورینگ علائم حیاتی', 
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ویجت کمکی برای ساخت فیلد‌های فرم 
  Widget _buildTextField(String label, FormFieldSetter<String> onSaved, {TextInputType keyboardType = TextInputType.text, int maxLines = 1, bool required = true}) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey.shade300),
        fillColor: const Color(0xFF0D1117),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'لطفاً $label را وارد کنید.';
        }
        return null;
      },
      onSaved: onSaved,
    );
  }
}

// --------------------------------------------------------------------
// صفحه دوم: مانیتور علائم حیاتی
// --------------------------------------------------------------------

class VitalMonitorScreen extends StatelessWidget {
  final PatientInfo patientInfo; 

  VitalMonitorScreen({required this.patientInfo});
  
  final Stream<DatabaseEvent> _dataStream = _database.ref('temperature_data').onValue;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1117), 
            Color(0xFF161B22),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        appBar: AppBar(
          centerTitle: true, 
          // 🎯 نمایش نام و نام خانوادگی در عنوان صفحه
          title: Text(
            'مانیتورینگ: ${patientInfo.fullName}', 
            style: const TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.w600, 
              letterSpacing: 1.2
            )
          ),
          backgroundColor: Colors.transparent, 
          elevation: 0,
        ),
        body: StreamBuilder<DatabaseEvent>(
          stream: _dataStream, 
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            
            if (snapshot.hasError) {
               return Center(child: Text('🚨 خطای RTDB: ${snapshot.error.toString()}', style: TextStyle(color: Colors.red)));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)));
            }
            
            final data = (snapshot.hasData && snapshot.data!.snapshot.value != null) 
              ? snapshot.data!.snapshot.value as Map<dynamic, dynamic>
              : {};
              
            final currentVitals = VitalSigns.fromSnapshot(data);

            return Center( 
              child: ConstrainedBox( 
                constraints: const BoxConstraints(maxWidth: 800), 
                child: SingleChildScrollView( 
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // افکت نوری
                      const Center(
                        child: SizedBox(
                          width: 300,
                          height: 300,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x331E88E5), 
                                  blurRadius: 100,
                                  spreadRadius: 50,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // نمایش اطلاعات مختصر بیمار زیر App Bar (مانند سن و سابقه بیماری)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Text(
                          'سن: ${patientInfo.age} | سابقه بیماری: ${patientInfo.medicalHistory.isEmpty ? 'ندارد' : patientInfo.medicalHistory}',
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // GridView حاوی کارت‌ها
                      GridView.count(
                        physics: const NeverScrollableScrollPhysics(), 
                        shrinkWrap: true, 
                        crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2, 
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        childAspectRatio: 1.0,
                        children: <Widget>[
                          _buildNeumorphicCard(
                            context,
                            title: 'ضربان قلب', 
                            value: currentVitals.heartRate.toString(), 
                            unit: 'bpm', 
                            icon: Icons.favorite, 
                            gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
                          ),
                          _buildNeumorphicCard(
                            context,
                            title: 'اکسیژن خون', 
                            value: currentVitals.spo2.toString(), 
                            unit: '%', 
                            icon: Icons.water_drop, 
                            gradient: const LinearGradient(colors: [Color(0xFF00BFFF), Color(0xFF1E88E5)]),
                          ),
                          _buildNeumorphicCard(
                            context,
                            title: 'دمای بدن', 
                            value: currentVitals.temperature.toStringAsFixed(1), 
                            unit: '°C', 
                            icon: Icons.thermostat, 
                            gradient: const LinearGradient(colors: [Colors.amber, Colors.orangeAccent]),
                          ),
                          _buildNeumorphicCard(
                            context,
                            title: 'زمان ذخیره', 
                            value: DateTime.fromMillisecondsSinceEpoch(currentVitals.timestamp).toString().substring(11,19), 
                            unit: 'زمان', 
                            icon: Icons.schedule, 
                            gradient: const LinearGradient(colors: [Colors.blueGrey, Colors.grey]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ویجت کمکی برای ساخت کارت‌های نئومورفیسم (بدون تغییر)
  Widget _buildNeumorphicCard(
    BuildContext context,
    {
      required String title, 
      required String value, 
      required String unit, 
      required IconData icon, 
      required LinearGradient gradient
    }
  ) {
    const double borderRadius = 20.0;
    const Color baseColor = Color(0xFF1E1E1E);

    return Container(
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C2C2C),
            offset: const Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // عنوان و آیکون
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => gradient.createShader(bounds),
                  child: Icon(icon, size: 28, color: Colors.white), 
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title, 
                    style: const TextStyle(
                      color: Colors.white70, 
                      fontSize: 14, 
                      fontWeight: FontWeight.w400
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            // مقدار و واحد
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible( 
                  child: ShaderMask(
                    shaderCallback: (bounds) => gradient.createShader(bounds),
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 64, 
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()], 
                      ),
                      overflow: TextOverflow.ellipsis, 
                      softWrap: false, 
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 5.0),
                  child: Text(
                    unit,
                    style: const TextStyle(color: Colors.white54, fontSize: 20),
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
