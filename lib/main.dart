// فایل main.dart باید به این صورت به‌روزرسانی شود.
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ایمپورت فایل پیکربندی دستی:
import 'firebase_options.dart'; 


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // راه‌اندازی Firebase با استفاده از پیکربندی دستی
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ورود به صورت ناشناس برای دسترسی به Firestore
  try {
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    print('خطا در ورود ناشناس به Firebase: $e');
    // ادامه اجرا حتی در صورت بروز خطا برای نمایش رابط کاربری
  }

  runApp(const TempMonitorApp());
}
// ... بقیه کد برنامه TempMonitorApp در اینجا ادامه می‌یابد ...
// ... بقیه کد برنامه TempMonitorApp در اینجا ادامه می‌یابد ...

class TempMonitorApp extends StatelessWidget {
  const TempMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ناظر دما',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TempMonitorScreen(),
    );
  }
}

class TempMonitorScreen extends StatefulWidget {
  const TempMonitorScreen({super.key});

  @override
  State<TempMonitorScreen> createState() => _TempMonitorScreenState();
}

class _TempMonitorScreenState extends State<TempMonitorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _tempController = TextEditingController();

  // نام کالکشن در Firestore 
  final String collectionName = 'temperature_readings'; 

  // تابع ارسال دما به Firestore
  Future<void> _addTemperature() async {
    final double? temp = double.tryParse(_tempController.text);
    if (temp == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً یک عدد معتبر وارد کنید.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      await _firestore.collection(collectionName).add({
        'temperature': temp,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
      });
      _tempController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('دما با موفقیت ثبت شد.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ثبت دما: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ناظر دمای فایربیس', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ویجت ورودی دما
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _tempController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'دمای جدید (سانتی‌گراد)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                        prefixIcon: Icon(Icons.thermostat),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addTemperature,
                      icon: const Icon(Icons.upload),
                      label: const Text('ثبت دما'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'آخرین دماهای ثبت شده:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Divider(),

            // ویجت نمایش داده‌ها از Firestore (Real-Time)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection(collectionName)
                    .orderBy('timestamp', descending: true)
                    .limit(10) // نمایش 10 مورد آخر
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('خطا در بارگذاری داده‌ها: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'هنوز دمایی ثبت نشده است.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  final data = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final doc = data[index];
                      final temp = doc['temperature']?.toString() ?? 'N/A';
                      final timestamp = doc['timestamp'] as Timestamp?;

                      String timeString = 'زمان نامشخص';
                      if (timestamp != null) {
                        timeString = '${timestamp.toDate().toLocal().hour}:${timestamp.toDate().toLocal().minute}';
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Icon(Icons.device_thermostat, color: Colors.orange.shade800),
                          ),
                          title: Text(
                            '$temp °C',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
                          ),
                          subtitle: Text('زمان ثبت: $timeString'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              // حذف سند از Firestore
                              await doc.reference.delete();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('دما حذف شد.'), backgroundColor: Colors.red),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
