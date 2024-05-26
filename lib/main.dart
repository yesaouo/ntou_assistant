import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ntou_assistant/bus.dart';
import 'package:ntou_assistant/settings.dart';
import 'package:ntou_assistant/weather.dart';

Future main() async {
  await dotenv.load(fileName: "assets/.env");
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  static final List<Widget> _widgetOptions = <Widget>[
    MyHomePage(),
    const SettingsPage(),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NTOU Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          toolbarHeight: 75,
          title: Image.asset(
            'assets/ntou.png',
            height: 50,
          ),
          centerTitle: true,
          backgroundColor: Colors.grey[850],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

  final GlobalKey<WeatherCardState> weatherCardKey = GlobalKey<WeatherCardState>();
  final GlobalKey<BusCardState> busCardKey = GlobalKey<BusCardState>();

  Future<void> refresh() async {
    await weatherCardKey.currentState?.refresh();
    await busCardKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgets = [
      WeatherCard(key: weatherCardKey),
      BusCard(key: busCardKey),
    ];

    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.blue,
      strokeWidth: 4.0,
      onRefresh: refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: widgets.length,
        itemBuilder: (BuildContext context, int index) {
          return widgets[index];
        },
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      ),
    );
  }
}
