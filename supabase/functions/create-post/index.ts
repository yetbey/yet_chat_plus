import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// CORS (Cross-Origin Resource Sharing) başlıkları,
// Flutter web veya diğer web istemcilerinden gelen istekler için gereklidir.
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  // Bu, tarayıcıdan gelen bir 'preflight' (OPTIONS) isteğini işlemek için gereklidir.
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Fonksiyonu çağıran kullanıcıya özel bir Supabase istemcisi oluştur.
    // Bu, RLS (Row Level Security) politikalarının doğru çalışmasını sağlar.
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // İstek yapan kullanıcının kimliğini doğrula.
    const { data: { user } } = await supabaseClient.auth.getUser()
    if (!user) {
      return new Response(JSON.stringify({ error: 'Authentication required' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    // İstek gövdesinden post verilerini al.
    const { caption, image_url } = await req.json()

    // Temel doğrulama: caption veya image_url olmalı.
    if (!caption && !image_url) {
      return new Response(JSON.stringify({ error: 'Caption or image URL is required' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // 'Posts' tablosuna yeni veriyi ekle.
    // .select() ile eklenen kaydın tüm verilerini (ilişkili kullanıcı verileri dahil) geri alıyoruz.
    const { data: newPost, error } = await supabaseClient
      .from('Posts')
      .insert({
        user_id: user.id,
        caption: caption,
        image_url: image_url,
      })
      .select('*, comment_count, Users!user_id(UID, fullName, image_url, username)')
      .single() // Sadece tek bir obje dönmesini sağlıyoruz.

    if (error) {
      console.error('Supabase insert error:', error)
      throw error
    }

    // Başarılı olursa, yeni oluşturulan post verisini istemciye geri gönder.
    return new Response(JSON.stringify(newPost), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    console.error('Function error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})