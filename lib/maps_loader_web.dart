// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void loadMapsScript(String apiKey) {
  final script = html.ScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey&loading=async'
    ..async = true;
  html.document.head!.append(script);
}
