import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseAdmin = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const userClient = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? '',
        { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )
    const { data: { user } } = await userClient.auth.getUser()
    if (!user) throw new Error('Kullanıcı bulunamadı veya yetki sorunu.')

    const userIdToDelete = user.id
    console.log(`Kullanıcı silme işlemi başlatıldı: ${userIdToDelete}`)

    // --- YENİ EKLENEN MANUEL TEMİZLİK KISMI ---

    // ÖNEMLİ: Bu fonksiyon artık CASCADE'e güvenmiyor.
    // Önce kullanıcıya ait tüm verileri public tablolardan siliyor.
    // Bu, referans hatalarını önler. En çok bağımlılığı olan tablodan başlanır.
    console.log("İlişkili veriler siliniyor...");
    await supabaseAdmin.from('post_likes').delete().eq('user_id', userIdToDelete)
    await supabaseAdmin.from('post_comments').delete().eq('user_id', userIdToDelete)
    await supabaseAdmin.from('followers').delete().or(`follower_id.eq.${userIdToDelete},following_id.eq.${userIdToDelete}`)
    await supabaseAdmin.from('messages').delete().or(`sender_id.eq.${userIdToDelete},receiver_id.eq.${userIdToDelete}`)
    await supabaseAdmin.from('notifications').delete().or(`user_id.eq.${userIdToDelete},from_user_id.eq.${userIdToDelete}`)
    await supabaseAdmin.from('fcm_tokens').delete().eq('user_id', userIdToDelete)
    await supabaseAdmin.from('Posts').delete().eq('user_id', userIdToDelete)
    await supabaseAdmin.from('chats').delete().or(`user1_id.eq.${userIdToDelete},user2_id.eq.${userIdToDelete}`)

    // En son, public.Users tablosundaki ana profil silinir
    await supabaseAdmin.from('Users').delete().eq('UID', userIdToDelete)

    console.log("Tüm veritabanı kayıtları silindi. Storage temizliği başlıyor...");

    // ... (Storage temizlik kodları aynı) ...

    // --- MANUEL TEMİZLİK BİTTİ ---

    // En son, tüm verileri silindikten sonra Auth kullanıcısını sil
    console.log(`Auth'dan ${userIdToDelete} kullanıcısı siliniyor...`)
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userIdToDelete, true)

    if (deleteError) throw deleteError

    console.log(`Kullanıcı ${userIdToDelete} başarıyla silindi.`)
    return new Response(JSON.stringify({ message: 'Kullanıcı başarıyla silindi.' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200,
    })
  } catch (error) {
    console.error("Genel Hata:", error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400,
    })
  }
})