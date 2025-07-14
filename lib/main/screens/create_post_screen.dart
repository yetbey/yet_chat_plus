import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_chat_plus/main/screens/navigator_screen.dart';
import '../../controller/post_controller.dart';
import 'package:yet_chat_plus/models/post_model.dart';

class CreatePostScreen extends StatefulWidget {
  final PostModel? postToEdit;
  const CreatePostScreen({super.key,  this.postToEdit});

  @override
  CreatePostScreenState createState() => CreatePostScreenState();
}

class CreatePostScreenState extends State<CreatePostScreen> {
  final PostController postController = Get.find<PostController>();
  final TextEditingController captionController = TextEditingController();
  late final TextEditingController _captionController;
  File? _imageFile;
  File? selectedImage;
  bool isUploading = false;
  final supabase = Supabase.instance.client;
  bool get _isEditing => widget.postToEdit != null;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.postToEdit?.caption ?? '');
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submit() {
    // Mod'a göre doğru fonksiyonu çağır
    if (_isEditing) {
      postController.updatePost(
        postId: widget.postToEdit!.id,
        oldImageUrl: widget.postToEdit!.imageUrl ?? '',
        caption: _captionController.text,
        newImageFile: _imageFile,
      );
    } else {
      postController.createPost(
        _captionController.text,
        _imageFile,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingImageUrl = widget.postToEdit?.imageUrl;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Gönderiyi Düzenle' : 'Yeni Gönderi Oluştur'),
        actions: [
          Obx(() => postController.isLoading.value
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
              : TextButton(
            onPressed: _submit,
            child: Text(_isEditing ? 'Kaydet' : 'Paylaş'),
          ))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                hintText: 'Ne düşünüyorsun?',
                border: InputBorder.none,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            // Resim seçme ve gösterme alanı
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : (existingImageUrl != null
                    ? Image.network(existingImageUrl, fit: BoxFit.cover)
                    : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined),
                      SizedBox(height: 8),
                      Text('Resim Ekle'),
                    ],
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.photo_library),
              onPressed: _pickImage,
            ),
            IconButton(
              icon: Icon(Icons.camera_alt),
              onPressed: _takePhoto,
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  Future<void> _createPost() async {
    if ((captionController.text.isEmpty || captionController.text.trim().isEmpty) && selectedImage == null) {
      Get.snackbar(
        'Hata',
        'Lütfen bir metin veya resim ekleyin',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      await postController.createPost(
        captionController.text.trim().isNotEmpty ? captionController.text.trim() : null,
        selectedImage,
      );
      Get.off(NavigatorScreen());
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }
}