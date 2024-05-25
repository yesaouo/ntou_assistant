import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Bus {
  final String city;
  String? stopName;
  late String url;
  List<BusData> datas = [];
  Map<String, dynamic> destinationStopsMap = {
    '303576': '八斗子車站',
    '303002': '圓山轉運站(玉門)',
    '134300': '福隆',
    '192223': '國家新城',
  };

  Bus({required this.city, required this.stopName}) {
    updateUrl();
  }

  void updateUrl() {
    if (stopName == '公路客運') {
      url =
          'https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/InterCity/1579?%24filter=StopName%2FZh_tw%20eq%20%27海大(濱海校門)%27%20and%20IsLastBus%20eq%20false%20and%20EstimateTime%20ne%20null&%24orderby=EstimateTime&%24format=JSON';
    } else if (stopName == '新北公車') {
      url =
          'https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/NewTaipei/791?%24filter=StopName%2FZh_tw%20eq%20%27海大(濱海校門)%27%20and%20EstimateTime%20ne%20null&%24orderby=EstimateTime&%24format=JSON';
    } else {
      url =
          'https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/$city?%24filter=StopName%2FZh_tw%20eq%20%27海大$stopName%27%20and%20IsLastBus%20eq%20false%20and%20EstimateTime%20ne%20null&%24orderby=EstimateTime&%24format=JSON';
    }
  }

  void setStopName(String name) {
    stopName = name;
    updateUrl();
  }

  Future<Map<String, String>> getHeader() async {
    final prefs = await SharedPreferences.getInstance();
    int? expiration = prefs.getInt('tdx_expiration');
    String? token = prefs.getString('tdx_token');

    if (token == null ||
        expiration == null ||
        DateTime.now().millisecondsSinceEpoch >= expiration) {
      final response = await http.post(
        Uri.parse(
            'https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token'),
        headers: {'content-type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'client_credentials',
          'client_id': dotenv.env['tdx_client_id'],
          'client_secret': dotenv.env['tdx_client_secret'],
        },
      );

      final responseBody = jsonDecode(response.body);
      token = responseBody['access_token'];
      expiration = (DateTime.now().millisecondsSinceEpoch +
          responseBody['expires_in'] * 1000) as int?;

      await prefs.setInt('tdx_expiration', expiration!);
      await prefs.setString('tdx_token', token!);
    }

    return {
      'accept': 'application/json',
      'authorization': 'Bearer $token',
    };
  }

  Future<void> get() async {
    try {
      datas = [];
      final response =
          await http.get(Uri.parse(url), headers: await getHeader());
      if (response.statusCode == 200) {
        final searchResponse = jsonDecode(response.body);
        DateTime now = DateTime.now();

        if (stopName == '新北公車') {
          for (var json in searchResponse) {
            DateTime dataTime = DateTime.parse(json['SrcUpdateTime']);
            Duration difference = dataTime.difference(now);
            json['EstimateTime'] += difference.inSeconds;
            if (json['EstimateTime'] > 0) {
              json['DestinationStop'] = json['Direction'] == 0 ? '134300' : '192223';
              datas.add(BusData.fromJson(json));
            }
          }
        } else {
          for (var json in searchResponse) {
            DateTime dataTime = DateTime.parse(json['DataTime']);
            Duration difference = dataTime.difference(now);
            json['EstimateTime'] += difference.inSeconds;
            if (json['EstimateTime'] > 0) {
              datas.add(BusData.fromJson(json));
            }
          }
        }

        for (var data in datas) {
          if (!destinationStopsMap.containsKey(data.destinationStop)) {
            destinationStopsMap[data.destinationStop] = null;
          }
        }

        if (destinationStopsMap.values.any((value) => value == null)) {
          await fetchDestinationStopNames();
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchDestinationStopNames() async {
    List<String> stopIDConditions = destinationStopsMap.entries
        .where((entry) => entry.value == null)
        .map((entry) => "StopID eq '${entry.key}'")
        .toList();
    if (stopIDConditions.isNotEmpty) {
      String queryString = stopIDConditions.join(' or ');
      String stopUrl =
          'https://tdx.transportdata.tw/api/basic/v2/Bus/Stop/City/$city?%24filter=$queryString&%24format=JSON';
      final stopResponse =
          await http.get(Uri.parse(stopUrl), headers: await getHeader());
      final stops = jsonDecode(stopResponse.body);
      for (var stop in stops) {
        destinationStopsMap[stop['StopID']] = stop['StopName']['Zh_tw'];
      }
    }
  }
}

class BusData {
  final String stopName;
  final String routeName;
  final String destinationStop;
  final int estimateTime;

  BusData({
    required this.stopName,
    required this.routeName,
    required this.destinationStop,
    required this.estimateTime,
  });

  factory BusData.fromJson(Map<String, dynamic> json) {
    return BusData(
      stopName: json['StopName']['Zh_tw'],
      routeName: json['RouteName']['Zh_tw'],
      destinationStop: json['DestinationStop'],
      estimateTime: json['EstimateTime'],
    );
  }
}

class BusCard extends StatefulWidget {
  const BusCard({super.key});

  @override
  BusCardState createState() => BusCardState();
}

class BusCardState extends State<BusCard> {
  final Bus bus = Bus(city: 'Keelung', stopName: '祥豐校門');
  final List<String> menuItems = ['祥豐校門', '濱海校門', '體育館', '公路客運', '新北公車'];
  String dropdownValue = '祥豐校門';
  late Future<void> _future;
  String? _refreshTime;

  Future<void> refresh() async {
    try {
      setState(() {
        _future = bus.get();
      });
      await _future;
      setState(() {
        _refreshTime = DateTime.now().toLocal().toString().substring(0, 19);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刷新失敗: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _future = bus.get();
    _refreshTime = DateTime.now().toLocal().toString().substring(0, 19);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          DropdownButton<String>(
            isExpanded: true,
            value: dropdownValue,
            onChanged: (String? newValue) async {
              setState(() {
                dropdownValue = newValue!;
                bus.setStopName(dropdownValue);
              });
              await refresh();
            },
            items: menuItems.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Center(child: Text(value)),
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder<void>(
              future: _future,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (bus.datas.isEmpty) {
                  return Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(15),
                        child: Text('暫無公車運行中。'),
                      ),
                      Text('更新時間: $_refreshTime'),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      SizedBox(
                        height: 300,
                        child: BusList(
                          busDatas: bus.datas,
                          stopsMap: bus.destinationStopsMap,
                        ),
                      ),
                      Text('更新時間: $_refreshTime'),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BusList extends StatelessWidget {
  const BusList({super.key, required this.busDatas, required this.stopsMap});
  final List<BusData> busDatas;
  final Map<String, dynamic> stopsMap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: busDatas.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(busDatas[index].routeName),
          subtitle: Text(
            '往 ${stopsMap[busDatas[index].destinationStop] ?? busDatas[index].destinationStop}',
          ),
          trailing: Text(busDatas[index].estimateTime < 60
              ? '進站中'
              : '${busDatas[index].estimateTime ~/ 60} 分鐘'),
        );
      },
    );
  }
}
