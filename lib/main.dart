import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:payrent_business/screens/auth/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        title: 'PayRent',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white, scrolledUnderElevation: 0.0),
          useMaterial3: true,
        ),
        home:  SplashPage(),
        debugShowCheckedModeBanner: false,
    );
  }
}
