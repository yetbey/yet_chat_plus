import 'package:flutter/material.dart';
import 'package:yet_chat_plus/controller/user_controller.dart';
import 'package:get/get.dart';

class BankProfileScreen extends StatefulWidget {
  const BankProfileScreen({super.key});

  @override
  State<BankProfileScreen> createState() => _BankProfileScreenState();
}

class _BankProfileScreenState extends State<BankProfileScreen> {
  final UserController userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }


  Future<void> _fetchInitialData() async {
    userController.fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF00BF6D),
        foregroundColor: Colors.white,
        title: Obx( () => Text(
            userController.userName.value ?? "Kullanıcı Adı",
            style: TextStyle(fontSize: 21),
          ),
        ),
        actions: [
          Obx(() => Padding(
              padding: const EdgeInsets.only(right: 2, bottom: 4, top: 4),
              child: CircleAvatar(
                radius: 40,
                backgroundImage:
                userController.imageUrl.value != null
                    ? NetworkImage(userController.imageUrl.value!)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const Info(
              infoKey: "Kullanıcı Adı",
              info: "@yetncr53",
            ),
            const Info(
              infoKey: "Konum",
              info: "Rize, TR",
            ),
            Obx(() => Info(
                infoKey: "Telefon Numarası",
                info: "+905${userController.phoneNumber.value}",
              ),
            ),
            Obx(() => Info(
                infoKey: "Email",
                info: userController.email.value ?? "",
              ),
            ),
            const SizedBox(height: 16.0),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 160,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BF6D),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {},
                  child: const Text("Profili Düzenle"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Info extends StatelessWidget {
  const Info({
    super.key,
    required this.infoKey,
    required this.info,
  });

  final String infoKey, info;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            infoKey,
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .color!
                  .withValues(alpha: .8),
            ),
          ),
          Text(info),
        ],
      ),
    );
  }
}
