import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WebsiteCard extends StatefulWidget {
  const WebsiteCard({super.key});

  @override
  State<WebsiteCard> createState() => _WebsiteCardState();
}

class _WebsiteCardState extends State<WebsiteCard> {
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
            const Text(
              '相關網站',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _launchInBrowserView(Uri.parse(
                        'https://www.ntou.edu.tw/')),
                        child: const Text('海大官網'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () => _launchInBrowserView(Uri.parse(
                        'https://tronclass.ntou.edu.tw/user/index#/')),
                        child: const Text('TronClass'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _launchInBrowserView(Uri.parse(
                        'https://ais.ntou.edu.tw/Default.aspx')),
                        child: const Text('教學務系統'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () => _launchInBrowserView(Uri.parse(
                        'https://ga.ntou.edu.tw/p/405-1015-44293,c7337.php?Lang=zh-tw')),
                        child: const Text('校區平面圖'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
