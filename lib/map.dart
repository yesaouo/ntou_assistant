import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapCard extends StatefulWidget {
  const MapCard({super.key});

  @override
  State<MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<MapCard> {
  final TextEditingController textEditingController = TextEditingController();
  Future<void> _launchInBrowserView(Uri url) async {
    //if (!await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
    //  throw Exception('無法打開 $url');
    //}
    await launchUrl(url, mode: LaunchMode.inAppBrowserView);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text('Google Maps'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '輸入想前往的地方',
                      ),
                      controller: textEditingController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.travel_explore),
                    onPressed: () => _launchInBrowserView(Uri.parse(
                        'https://www.google.com/maps/dir/國立臺灣海洋大學+202基隆市中正區北寧路2號/${textEditingController.text}/')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
