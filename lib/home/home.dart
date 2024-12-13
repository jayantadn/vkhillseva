import 'package:flutter/material.dart';
import 'package:vkhillseva/nitya_seva/nitya_seva.dart';
import 'package:vkhillseva/widgets/launcher_tile.dart';

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
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/Logo/KrishnaLilaPark_circle.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
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
          SizedBox(height: 50),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                LauncherTile(
                    image: 'assets/images/LauncherIcons/NityaSeva.png',
                    title: "Nitya Seva",
                    callback: LauncherTileCallback(onClick: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const NityaSeva(title: "Nitya Seva")),
                      );
                    })),
                LauncherTile(
                  image: 'assets/images/LauncherIcons/Harinaam.png',
                  title: "Harinaam",
                ),
                LauncherTile(
                  image: 'assets/images/LauncherIcons/Deepotsava.png',
                  title: "Deepotsava",
                ),
              ],
            ),
          )
        ],
      )),
    );
  }
}
