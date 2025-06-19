import 'package:flutter_dotenv/flutter_dotenv.dart';

class API {
  final String baseUrl = dotenv.env['BASE_URL']!;
  final String socketUrl = dotenv.env['SOCKET_URL']!;
}
