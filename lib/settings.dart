import 'package:flutter/material.dart';
import 'package:ntou_assistant/firebase.dart';
import 'package:ntou_assistant/map.dart';
import 'package:ntou_assistant/website.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<Widget> widgets = [
    const WebsiteCard(),
    const MapCard(),
    const AuthCheck(),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: widgets.length,
      itemBuilder: (BuildContext context, int index) {
        return widgets[index];
      },
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    );
  }
}
