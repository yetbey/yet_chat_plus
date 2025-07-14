import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

Deno.serve(async (req) => {
  // CORS preflight isteğini işle
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Kullanıcının yetkilendirme token'ı ile bir Supabase client oluştur
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // Token'dan kullanıcıyı al
    const { data: { user } } = await userClient.auth.getUser()
    if (!user) {
      return new Response(JSON.stringify({ error: 'Kullanıcı doğrulanmadı' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    // İstek gövdesinden post_id'yi al
    const { post_id } = await req.json()
    if (!post_id) {
      return new Response(JSON.stringify({ error: 'post_id gerekli' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // Veritabanı fonksiyonunu çağırmak için service_role client'ı kullan
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // SQL fonksiyonunu RPC ile çağır
    const { data, error } = await supabaseAdmin.rpc('toggle_like_post', {
      p_post_id: post_id,
    }).single()

    if (error) throw error

    // SQL fonksiyonundan dönen sonucu istemciye gönder
    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})

