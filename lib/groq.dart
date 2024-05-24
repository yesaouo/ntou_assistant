import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class Groq {
  String? apiKey = dotenv.env['groq'];
  String url = 'https://api.groq.com/openai/v1/chat/completions';
  Map<String, String>? headers;
  Map<String, dynamic> body = {
    "messages": [],
    "model": "llama3-70b-8192",
    "temperature": 1,
    "max_tokens": 2048,
    "top_p": 1,
    "stream": false,
    "stop": null,
  };

  final String system;
  final String user;
  String? assistant;
  Groq({required this.system, required this.user}) {
    headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }

  void setMessages() {
    body['messages'] = [
      {"role": "system", "content": system},
      {"role": "user", "content": user}
    ];
  }

  Future<void> post() async {
    try {
      setMessages();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final searchResponse = jsonDecode(utf8.decode(response.bodyBytes));
        assistant = searchResponse['choices'][0]['message']['content'];
      } else {
        print('error ${response.statusCode}');
      }
    } catch (e) {
      print('error $e');
    }
  }
}

class GroqCard extends StatefulWidget {
  const GroqCard({super.key});

  @override
  State<GroqCard> createState() => _GroqCardState();
}

class _GroqCardState extends State<GroqCard> {
  final List<String> menuItems = [
    '112學年度第1學期行事曆',
    '112學年度第2學期行事曆',
    '113學年度第1學期行事曆'
  ];
  String dropdownValue = '112學年度第1學期行事曆';
  final TextEditingController textEditingController = TextEditingController();
  String displayText = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            DropdownButton<String>(
              isExpanded: true,
              value: dropdownValue,
              onChanged: (String? newValue) {
                setState(() {
                  dropdownValue = newValue!;
                });
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
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      maxLength: 50,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '與行事曆小助手開始對話',
                      ),
                      controller: textEditingController,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      final Groq groq = Groq(
                        system: '現在時間 ${DateTime.now().toString()}。',
                        user: textEditingController.text,
                      );
                      await groq.post();
                      setState(() {
                        displayText =
                            '選擇模型: $dropdownValue\n回覆內容: ${groq.assistant}';
                      });
                    },
                  ),
                ],
              ),
            ),
            Container(
              height: 100,
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.white60,
              child: Text(
                displayText,
                overflow: TextOverflow.ellipsis,
                maxLines: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
