import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
                height: 200,
                width: 200,
                child: Image.asset(
                    'assets/images/Logo/KrishnaLilaPark_circle.png')),
          ),
          Text(
            'Welcome Guest',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          Text(
            'ISKCON Vaikuntha Hill',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text('Seva App', style: Theme.of(context).textTheme.headlineMedium),
        ],
      )),
    );
  }
}
