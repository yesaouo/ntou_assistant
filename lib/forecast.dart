import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class Forecast {
  String? apiKey = dotenv.env['cwa_gov_tw'];
  Map<String, String> headers = {
    'accept': 'application/json',
  };

  String? url;
  List<String> times = [];
  List<String> dataWx = [];
  List<String> dataT = [];
  List<String> dataPoP6h = [];

  final String? locationName; // = '中正區';
  Forecast({required this.locationName});

  void init() {
    times = [];
    DateTime temp = DateTime.now();
    for (int i = 0; i < 6; i++) {
      temp = temp.hour ~/ 6 * 6 + 6 > 24
          ? DateTime(temp.year, temp.month, temp.day + 1, 0)
          : DateTime(temp.year, temp.month, temp.day, temp.hour ~/ 6 * 6 + 6);
      String time = temp.toIso8601String();
      times.add(time.substring(0, time.length - 4));
    }
    url =
        'https://opendata.cwa.gov.tw/api/v1/rest/datastore/F-D0047-049?Authorization=$apiKey&locationName=$locationName&elementName=Wx,T,PoP6h&timeFrom=${times.first}&timeTo=${times.last}';
  }
  
  bool dataNull() {
    return dataWx.length != 5 || dataT.length != 5 || dataPoP6h.length != 5;
  }

  Future<void> get() async {
    try {
      init();
      final response = await http.get(
        Uri.parse(url!),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final searchResponse = jsonDecode(response.body);
        var weatherElement = searchResponse['records']['locations'][0]
            ['location'][0]['weatherElement'];
        dataWx = [];
        dataT = [];
        dataPoP6h = [];
        for (var weather in weatherElement[0]['time']) {
          if (weather['startTime'].endsWith('00:00:00') ||
              weather['startTime'].endsWith('06:00:00') ||
              weather['startTime'].endsWith('12:00:00') ||
              weather['startTime'].endsWith('18:00:00')) {
            dataWx.add(weather['elementValue'][0]['value']);
          }
        }
        for (var weather in weatherElement[1]['time']) {
          if (weather['dataTime'].endsWith('00:00:00') ||
              weather['dataTime'].endsWith('06:00:00') ||
              weather['dataTime'].endsWith('12:00:00') ||
              weather['dataTime'].endsWith('18:00:00')) {
            dataT.add(weather['elementValue'][0]['value']);
          }
        }
        for (var weather in weatherElement[2]['time']) {
          if (weather['startTime'].endsWith('00:00:00') ||
              weather['startTime'].endsWith('06:00:00') ||
              weather['startTime'].endsWith('12:00:00') ||
              weather['startTime'].endsWith('18:00:00')) {
            dataPoP6h.add(weather['elementValue'][0]['value']);
          }
        }
      } else {
        print('error ${response.statusCode}');
      }
    } catch (e) {
      print('error $e');
    }
  }
}

class ForecastCard extends StatefulWidget {
  const ForecastCard({super.key});

  @override
  ForecastCardState createState() => ForecastCardState();
}

class ForecastCardState extends State<ForecastCard> {
  final Forecast weather = Forecast(locationName: '中正區');
  late Future<void> _future;

  Future<void> refresh() async {
    setState(() {
      _future = weather.get();
    });
    await _future;
  }

  @override
  void initState() {
    super.initState();
    _future = weather.get();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
      child: FutureBuilder<void>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (weather.dataNull()) {
            return const Padding(
              padding: EdgeInsets.all(15),
              child: Text('資料獲取失敗，請稍後再試。'),
            );
          } else {
            return Row(
              children: List.generate(
                5,
                (index) => Expanded(
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('${(index + 1) * 6} hrs'),
                        const SizedBox(
                          height: 10,
                        ),
                        Container(
                          constraints: const BoxConstraints(
                              minHeight: 40, maxHeight: 40),
                          child: Center(
                            child: Text(
                              weather.dataWx[index],
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text('${weather.dataT[index]}°'),
                        const SizedBox(
                          height: 10,
                        ),
                        Image.asset(
                          'assets/forecast/umbrella.png',
                          height: 16,
                        ),
                        Text('${weather.dataPoP6h[index]}%'),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
