import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_chat_plus/models/chat_model.dart';
import 'package:yet_chat_plus/models/message_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';

import '../models/post_model.dart';

class MessageController extends GetxController {
  final supabase = Supabase.instance.client;

  // Sadece bu controller'ın yönettiği listeler
  final RxList<Chat> chats = <Chat>[].obs;
  final RxList<Message> messages = <Message>[].obs;

  final isLoadingChats = false.obs;
  final isLoadingMessages = false.obs;

  RealtimeChannel? _chatScreenChannel;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    leaveChatScreenChannel();
    super.onClose();
  }

  Future<void> sendMessage({
    required int chatId,
    required String otherUserId,
    String? content,
    File? imageFile,
    Message? replyingTo,
    PostModel? sharedPost,
  }) async {
    if ((content?.trim().isEmpty ?? true) && imageFile == null && sharedPost == null) return;

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    final messageType = imageFile != null ? 'image' : (sharedPost != null ? 'post_share' : 'text');
    final tempContent = imageFile?.path ?? content ?? "Bir gönderi paylaşıldı";

    // 1. ANINDA GÖRÜNME İÇİN GEÇİCİ MESAJ NESNESİ OLUŞTUR
    final tempMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch,
      chatId: chatId,
      senderId: currentUser.id,
      content: tempContent,
      createdAt: DateTime.now(),
      type: messageType,
      replyToMessageId: replyingTo?.id,
      repliedToMessage: replyingTo,
      sharedPostId: sharedPost?.id,
      sharedPost: sharedPost,
      localImageFile: imageFile,
    );
    messages.add(tempMessage);

    try {
      String? finalContent = content;
      if (imageFile != null) {
        final fileExtension = path.extension(imageFile.path);
        final fileName = '${Uuid().v4()}$fileExtension';
        await supabase.storage.from('chat_images').upload(fileName, imageFile);
        finalContent = supabase.storage.from('chat_images').getPublicUrl(fileName);
      } else if (sharedPost != null) {
        finalContent = "Bir gönderi paylaştı.";
      }

      // --- DEĞİŞİKLİK BURADA: Sadece ekleme yapıp, basit bir select ile dönüyoruz ---
      final response = await supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': currentUser.id,
        'receiver_id': otherUserId,
        'content': finalContent,
        'type': messageType,
        'reply_to_message_id': replyingTo?.id,
        'shared_post_id': sharedPost?.id,
      }).select().single(); // Karmaşık join'leri ve !inner'ı kaldırdık

      // Geçici mesajı, veritabanından gelen gerçek ID ve zaman bilgisiyle güncelliyoruz.
      // repliedTo ve sharedPost bilgilerini ise zaten elimizde olan geçici mesajdan koruyoruz.
      final index = messages.indexWhere((m) => m.id == tempMessage.id);
      if (index != -1) {
        // `fromJson`'dan gelen nesnenin `repliedTo` ve `sharedPost`'u boş olacaktır,
        // bu yüzden onları geçici mesajımızdan alıyoruz.
        final dbMessage = Message.fromJson(response);
        dbMessage.repliedToMessage = tempMessage.repliedToMessage;
        dbMessage.sharedPost = tempMessage.sharedPost;

        messages[index] = dbMessage;
      }

      await supabase.from('chats').update({'updated_at': DateTime.now().toIso8601String()}).eq('id', chatId);

    } catch (e) {
      print('Mesaj gönderme hatası: $e');
      messages.removeWhere((m) => m.id == tempMessage.id);
      Get.snackbar('Hata', 'Mesaj gönderilemedi.');
    }
  }

  Future<void> fetchChats() async {
    if (supabase.auth.currentUser == null) return;
    try {
      isLoadingChats.value = true;
      final userId = supabase.auth.currentUser!.id;

      final response = await supabase
          .from('chats')
          .select('*, unread_count, user1:Users!user1_id(*), user2:Users!user2_id(*)')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('updated_at', ascending: false);

      final List<Chat> fetchedChats = (response as List)
          .map((item) => Chat.fromJson(item, userId))
          .toList();

      chats.value = fetchedChats;
    } catch (e) {
      print('Sohbetleri getirme hatası: $e');
    } finally {
      isLoadingChats.value = false;
    }
  }

  Future<void> fetchMessages(int chatId) async {
    if (supabase.auth.currentUser == null) return;
    try {
      isLoadingMessages.value = true;
      messages.clear();

      final response = await supabase
          .from('messages')
          .select('*, replied_message:reply_to_message_id(*, sender:Users!sender_id(fullName)), shared_post:shared_post_id(*, Users!user_id(*))')
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      messages.value = (response as List).map((item) {
        // Gelen verideki join isimlerini düzeltmemiz gerekebilir
        if(item['shared_post'] != null) {
          item['shared_post']['Users'] = item['shared_post']['user_id'];
        }
        return Message.fromJson(item);
      }).toList();
    } catch (e) {
      print('Mesajları getirme hatası: $e');
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<int> createOrGetChat(String otherUserId) async {
    try {
      final response = await supabase.rpc('create_or_get_chat', params: {
        'user_id_1': supabase.auth.currentUser!.id,
        'user_id_2': otherUserId
      });
      // fetchChats();
      return response as int;
    } catch (e) {
      print('Sohbet oluşturma/getirme hatası: $e');
      rethrow;
    }
  }

  void joinChatScreenChannel(int chatId) {
    leaveChatScreenChannel();
    _chatScreenChannel = supabase.channel('chat_screen_$chatId');
    _chatScreenChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'chat_id', value: chatId),
      callback: (payload) async {
        if (payload.newRecord['sender_id'] == supabase.auth.currentUser?.id) {
          return;
        }
        final newId = payload.newRecord['id'];
        try {
          // 2. Sadece o tek mesajın tüm detaylarını (yanıt bilgisi dahil) çek
          final response = await supabase
              .from('messages')
              .select('*, replied_message:reply_to_message_id(*, sender:Users!sender_id(fullName))')
              .eq('id', newId)
              .single(); // .single() ile tek bir kayıt alıyoruz

          // 3. Tam ve eksiksiz mesaj nesnesini oluştur
          final newMessage = Message.fromJson(response);

          // 4. Bu tam nesneyi listeye ekle
          messages.add(newMessage);

        } catch (e) {
          print("Yeni anlık mesaj işlenirken hata oluştu: $e");
        }
      },
    ).subscribe();
  }

  void leaveChatScreenChannel() {
    if (_chatScreenChannel != null) {
      supabase.removeChannel(_chatScreenChannel!);
    }
  }

  Future<void> deleteChat(int chatId) async {
    try {
      // Önce yerel listeden anında kaldırarak UI'ı akıcı hale getir
      chats.removeWhere((chat) => chat.id == chatId);

      // Sonra veritabanından kalıcı olarak sil
      await supabase.from('chats').delete().eq('id', chatId);

    } catch (e) {
      Get.snackbar('Hata', 'Sohbet silinirken bir sorun oluştu.');
      print('Sohbet silme hatası: $e');
      // Hata durumunda, veritabanı ile tutarlılığı sağlamak için listeyi yeniden çek
      fetchChats();
    }
  }

}