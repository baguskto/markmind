import 'package:get/get.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' show PreviewData;

class HomeController extends GetxController {
  RxMap<String, PreviewData> datas = <String, PreviewData>{}.obs;
  RxList<String> urls = [
    'github.com/flyerhq',
    'https://u24.gov.ua',
    'https://twitter.com/SpaceX/status/1564975288655630338',
  ].obs;


  @override
  void onInit() {
    super.onInit();
  }
}
