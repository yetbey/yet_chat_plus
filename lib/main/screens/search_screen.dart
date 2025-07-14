import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:yet_chat_plus/controller/search_controller.dart' as app_search;
import 'package:yet_chat_plus/main/components/empty_state_widget.dart';
import 'package:yet_chat_plus/main/screens/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Controller'ı bu ekrana özel olarak 'put' edip, çıkarken 'delete' edeceğiz.
  // Bu, her arama ekranı açıldığında temiz bir başlangıç sağlar.
  final app_search.SearchController searchController = Get.put(app_search.SearchController());
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void dispose() {
    // Ekran kapandığında controller'ı hafızadan sil
    Get.delete<app_search.SearchController>();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar başlığı olarak bir arama TextField'ı kullanıyoruz
        title: TextField(
          controller: _textEditingController,
          autofocus: true, // Sayfa açılır açılmaz klavyeyi açar
          decoration: InputDecoration(
            hintText: 'Kullanıcı ara...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: searchController.onSearchChanged,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _textEditingController.clear();
              searchController.clearSearch();
            },
          )
        ],
      ),
      body: Obx(() {
        if (searchController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (searchController.searchResults.isEmpty) {
          // Eğer arama yapıldı ve sonuç yoksa "sonuç bulunamadı" göster
          if (searchController.hasSearched.value) {
            return const EmptyStateWidget(
              icon: Icons.search_off,
              title: 'Sonuç Bulunamadı',
              subtitle: 'Lütfen farklı bir anahtar kelime ile aramayı deneyin.',
            );
          }
          // Başlangıçta ise bir ipucu göster
          return const EmptyStateWidget(
            icon: Icons.search,
            title: 'Kullanıcıları Keşfet',
            subtitle: 'Arama çubuğuna bir isim yazarak aramaya başlayın.',
          );
        }

        // Arama sonuçlarını listele
        return ListView.builder(
          itemCount: searchController.searchResults.length,
          itemBuilder: (context, index) {
            final user = searchController.searchResults[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user['image_url'] != null ? NetworkImage(user['image_url']) : null,
                child: user['image_url'] == null ? Icon(Icons.person) : null,
              ),
              title: Text(user['fullName'] ?? ''),
              onTap: () {
                Get.to(() => ProfileScreen(userId: user['UID']));
              },
            );
          },
        );
      }),
    );
  }
}