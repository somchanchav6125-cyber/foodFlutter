import 'package:get/get.dart';

class favIconfood extends GetxController {
  var favIcons = false.obs;
  void checkfavicon() {
    favIcons.value = !favIcons.value;
  }
}
