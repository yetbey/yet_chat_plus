// supabase/functions/toggle-follow/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    // 1. İstek yapan kullanıcının kimliğini (follower) doğrula.
    const { data: { user: followerUser } } = await supabaseClient.auth.getUser()
    if (!followerUser) {
      return new Response(JSON.stringify({ error: 'Authentication required' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }
    const followerId = followerUser.id

    // 2. Takip edilecek kullanıcının ID'sini (following) istek gövdesinden al.
    const { following_id: followingId } = await req.json()
    if (!followingId) {
      return new Response(JSON.stringify({ error: 'following_id is required' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // 3. Kullanıcının kendini takip etmesini engelle.
    if (followerId === followingId) {
      return new Response(JSON.stringify({ error: 'User cannot follow themselves' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // 4. Takip ilişkisi zaten var mı diye kontrol et.
    const { data: existingFollow, error: checkError } = await supabaseClient
      .from('followers')
      .select('*')
      .eq('follower_id', followerId)
      .eq('following_id', followingId)
      .maybeSingle()

    if (checkError) throw checkError

    let newStatus;

    // 5. İlişki varsa sil (takipten çık), yoksa oluştur (takip et).
    if (existingFollow) {
      // Takipten çık
      const { error } = await supabaseClient
        .from('followers')
        .delete()
        .match({ follower_id: followerId, following_id: followingId })
      
      if (error) throw error
      newStatus = 'unfollowed'
    } else {
      // Takip et
      const { error } = await supabaseClient
        .from('followers')
        .insert({ follower_id: followerId, following_id: followingId })
      
      if (error) throw error
      newStatus = 'followed'
    }

    // 6. Başarılı işlem sonucunu istemciye bildir.
    return new Response(JSON.stringify({ status: newStatus }), {
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