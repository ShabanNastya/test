import 'dart:async';
import 'dart:convert' show json, utf8;
import 'dart:io';

const apiCategory = {
  'name': 'Валюта',
  'route': 'currency',
};

class Api {
  final HttpClient _httpClient = HttpClient();
  final String _url = 'flutter.udacity.com';
  Future<List> getMeasures(String category) async {
    final uri = Uri.https(_url, '/$category');
    final jsonResponse = await _getJson(uri);
    if (jsonResponse == null || jsonResponse['units'] == null) {
      print('Ошибка единиц измерения');
      return null;
    }
    return jsonResponse['units'];
  }
  Future<double> convert(
      String category, String amount, String fromMeasure, String toMeasure) async {
    final uri = Uri.https(_url, '/$category/convert',
        {'amount': amount, 'from': fromMeasure, 'to': toMeasure});
    final jsonResponse = await _getJson(uri);
    if (jsonResponse == null || jsonResponse['status'] == null) {
      print('Ошибка при загрузке');
      return null;
    } else if (jsonResponse['status'] == 'error') {
      print(jsonResponse['message']);
      return null;
    }
    return jsonResponse['conversion'].toDouble();
  }
  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final httpRequest = await _httpClient.getUrl(uri);
      final httpResponse = await httpRequest.close();

      if (httpResponse.statusCode != HttpStatus.OK) {
        return null;
      }
      final responseBody = await httpResponse.transform(utf8.decoder).join();
      return json.decode(responseBody);
    } on Exception catch (e) {
      print('$e');
      return null;
    }
  }
}