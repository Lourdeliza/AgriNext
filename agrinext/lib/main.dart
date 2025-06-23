import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: "https://whoolrrnsvpynflzqoim.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indob29scnJuc3ZweW5mbHpxb2ltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk1MjA5MjMsImV4cCI6MjA2NTA5NjkyM30.3jeHU1zqUtaTP1azP3eoLxCiAvOTp57LIGoOp8jTGkU",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriNext',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginPage(),
    );
  }
}

