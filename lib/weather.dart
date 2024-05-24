import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:ntou_assistant/forecast.dart';

class Weather {
  String? apiKey = dotenv.env['cwa_gov_tw'];
  Map<String, String> headers = {
    'accept': 'application/json',
  };

  final String? stationId; // = 'C0B050';
  String? url;
  WeatherData? data;
  Weather({required this.stationId}) {
    url =
        'https://opendata.cwa.gov.tw/api/v1/rest/datastore/O-A0001-001?Authorization=$apiKey&format=JSON&StationId=$stationId';
  }

  Future<void> get() async {
    try {
      final response = await http.get(
        Uri.parse(url!),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final searchResponse = jsonDecode(response.body);
        data = WeatherData.fromJson(searchResponse['records']['Station'][0]);
      } else {
        print('error ${response.statusCode}');
      }
    } catch (e) {
      print('error $e');
    }
  }
}

class WeatherData {
  final String stationName;
  final String countyName;
  final String townName;
  final String weather;
  final double precipitation;
  final double temperature;
  final double windDirection;
  final double windSpeed;
  final int humidity;
  final double airPressure;
  final String dateTime;

  WeatherData({
    required this.stationName,
    required this.countyName,
    required this.townName,
    required this.weather,
    required this.precipitation,
    required this.temperature,
    required this.windDirection,
    required this.windSpeed,
    required this.humidity,
    required this.airPressure,
    required this.dateTime,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      stationName: json['StationName'],
      countyName: json['GeoInfo']['CountyName'],
      townName: json['GeoInfo']['TownName'],
      weather: json['WeatherElement']['Weather'],
      precipitation: json['WeatherElement']['Now']['Precipitation'],
      temperature: json['WeatherElement']['AirTemperature'],
      windDirection: json['WeatherElement']['WindDirection'],
      windSpeed: json['WeatherElement']['WindSpeed'],
      humidity: json['WeatherElement']['RelativeHumidity'],
      airPressure: json['WeatherElement']['AirPressure'],
      dateTime: json['ObsTime']['DateTime'],
    );
  }
}

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  WeatherCardState createState() => WeatherCardState();
}

class WeatherCardState extends State<WeatherCard> {
  final Weather weather = Weather(stationId: 'C0B050');
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            FutureBuilder<void>(
              future: _future,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (weather.data == null) {
                  return const Padding(
                    padding: EdgeInsets.all(15),
                    child: Text('資料獲取失敗，請稍後再試。'),
                  );
                } else {
                  return Column(
                    children: <Widget>[
                      Text(
                        '${weather.data?.countyName}/${weather.data?.townName}/${weather.data?.stationName}',
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          HumidityWidget(
                            humidity: weather.data!.humidity,
                          ),
                          WeatherWidget(
                            description: weather.data!.weather,
                            temperature: weather.data!.temperature,
                          ),
                          WindWidget(
                            windSpeed: weather.data!.windSpeed,
                            windDirection: weather.data!.windDirection,
                          ),
                        ],
                      ),
                      Text('本日累積降水量: ${weather.data?.precipitation} mm'),
                      const ForecastCard(),
                      Text('觀測時間: ${weather.data?.dateTime.substring(0, 19).replaceAll('T', ' ')}'),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class WindWidget extends StatelessWidget {
  final double windSpeed;
  final double windDirection;

  const WindWidget(
      {super.key, required this.windSpeed, required this.windDirection});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          '$windSpeed m/s',
        ),
        Transform.rotate(
          angle: math.pi / 180 * windDirection,
          child: const Icon(
            Icons.arrow_upward,
            size: 50,
          ),
        ),
      ],
    );
  }
}

class WeatherWidget extends StatelessWidget {
  final String description;
  final double temperature;

  const WeatherWidget({
    super.key,
    required this.description,
    required this.temperature,
  });

  bool isNight() {
    DateTime now = DateTime.now();
    int hour = now.hour;
    if (hour >= 6 && hour < 18) {
      return false;
    }
    return true;
  }

  Widget weatherDescription() {
    String cloudType = '';
    String weatherPhenomenon = '';
    List<String> cloudTypes = ['晴', '多雲', '陰'];
    for (String type in cloudTypes) {
      if (description.startsWith(type)) {
        cloudType = type;
        weatherPhenomenon = description.substring(type.length);
        break;
      }
    }
    if (cloudType.isNotEmpty && weatherPhenomenon.isNotEmpty) {
      return Row(
        children: [
          Image.asset(
            'assets/weather/$cloudType${isNight() ? '-夜晚' : ''}.png',
            width: 70,
            height: 70,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            weatherPhenomenon,
            style: const TextStyle(fontSize: 22),
          ),
        ],
      );
    } else if (cloudType.isNotEmpty) {
      return Image.asset(
        'assets/weather/$cloudType${isNight() ? '-夜晚' : ''}.png',
        width: 70,
        height: 70,
      );
    } else {
      return Text(
        weatherPhenomenon,
        style: const TextStyle(fontSize: 22),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        weatherDescription(),
        const SizedBox(
          width: 10,
        ),
        Text(
          '$temperature°',
          style: const TextStyle(fontSize: 35),
        ),
      ],
    );
  }
}

class HumidityWidget extends StatelessWidget {
  final int humidity;

  const HumidityWidget({super.key, required this.humidity});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text(
          '濕度',
        ),
        Text(
          '$humidity%',
          style: const TextStyle(fontSize: 25),
        ),
      ],
    );
  }
}
