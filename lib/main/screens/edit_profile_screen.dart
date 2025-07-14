import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yet_chat_plus/controller/profile_controller.dart';
import 'package:yet_chat_plus/controller/user_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileController profileController = Get.find<ProfileController>();
  final UserController userController = Get.find<UserController>();
  late final TextEditingController _nameController;

  File? _image; // Seçilen yeni resim dosyasını tutmak için

  @override
  void initState() {
    super.initState();
    // final userProvider = provider.Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: userController.userName.value ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Galeriden resim seçme fonksiyonu
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  void _onSave() {
    profileController.updateUserProfile(
      fullName: _nameController.text.trim(),
      newImageFile: _image,
    );
  }

  @override
  Widget build(BuildContext context) {
    // final userProvider = provider.Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profili Düzenle'),
        actions: [
          // Kaydet butonu
          TextButton(
            onPressed: _onSave,
            child: Text('Kaydet', style: TextStyle(fontSize: 16)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Profil Resmi Değiştirme Alanı
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Obx(() => CircleAvatar(
                      radius: 60,
                      backgroundImage: _image != null
                          ? FileImage(_image!) as ImageProvider
                          : (userController.imageUrl.value != null
                          ? NetworkImage(userController.imageUrl.value!)
                          : null),
                      child: _image == null && userController.imageUrl.value == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            // İsim Soyisim Alanı
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'İsim Soyisim',
                border: OutlineInputBorder(),
              ),
            ),

            // Gelecekte eklenebilecek diğer alanlar (bio, kullanıcı adı vb.)
            // const SizedBox(height: 20),
            // TextFormField(
            //   decoration: InputDecoration(
            //     labelText: 'Hakkında',
            //     border: OutlineInputBorder(),
            //   ),
            //   maxLines: 3,
            // ),
          ],
        ),
      ),
    );
  }
}