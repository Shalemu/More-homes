import 'package:flutter/material.dart';

void main() {
  runApp(const Homedetails());
}

class Homedetails extends StatefulWidget {
  const Homedetails({super.key});

  @override
  State<Homedetails> createState() => _HomedetailsState();
}

class _HomedetailsState extends State<Homedetails> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Demo', theme: ThemeData());
  }
}
