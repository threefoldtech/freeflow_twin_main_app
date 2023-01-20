import 'dart:convert';

import 'package:freeflow/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

Future<String> getCurrentFreeFlowVersion() async {
  String url = AppConfig().appConfig.spawnerUrl() + '/api/v1/version';
  Uri parsedUrl = Uri.parse(url);

  try {
    Response r = await http.get(parsedUrl);

    dynamic version = jsonDecode(r.body);

    return version['version'];
  }

  catch(e) {
    print(e);
    return '';
  }
}