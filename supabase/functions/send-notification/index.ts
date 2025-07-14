import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.0.0";
import { create, getNumericDate, Header } from "https://deno.land/x/djwt@v2.8/mod.ts";
import { crypto } from "https://deno.land/std@0.159.0/crypto/mod.ts";

/**
 * Google'ın verdiği PEM formatındaki özel anahtarı, Web Crypto API'sinin
 * anlayacağı binary formata dönüştürür.
 */
function pemToBinary(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  return Uint8Array.from(atob(base64), (c) => c.charCodeAt(0));
}

/**
 * Google servis hesabını kullanarak bir "access token" alır.
 * Bu token, FCM'e istek yapma yetkisi verir.
 */
async function getAccessToken(): Promise<string> {
  const SERVICE_ACCOUNT_KEY = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY");
  if (!SERVICE_ACCOUNT_KEY) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_KEY secret not set.");
  }
  const serviceAccount = JSON.parse(SERVICE_ACCOUNT_KEY);

  // Anahtarı Web Crypto API için uygun formata getir
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToBinary(serviceAccount.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    true,
    ["sign"]
  );

  const header: Header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: getNumericDate(3600), // 1 saat geçerli
    iat: getNumericDate(0),
  };

  // JWT'yi oluştur ve imzala
  const jwt = await create(header, payload, cryptoKey);

  // İmzalanmış JWT ile access token talep et
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokens = await response.json();
  if (!response.ok) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokens)}`);
  }
  return tokens.access_token;
}

serve(async (req) => {
  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
    );

    const { record } = await req.json();

    if (!record || !record.user_id || !record.post_id) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400, headers: { "Content-Type": "application/json" },
      });
    }

    // --- Veritabanından Gerekli Bilgileri Çek ---
    const { data: actorData, error: actorError } = await supabaseClient
      .from("Users").select("fullName").eq("UID", record.user_id).single();
    if (actorError) throw actorError;

    const { data: postData, error: postError } = await supabaseClient
      .from("Posts").select("user_id").eq("id", record.post_id).single();
    if (postError) throw postError;

    if (record.user_id === postData.user_id) {
      return new Response(JSON.stringify({ message: "User liked their own post." }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const { data: ownerData, error: ownerError } = await supabaseClient
      .from("Users").select("fcm_token").eq("UID", postData.user_id).single();
    if (ownerError) throw ownerError;

    if (!ownerData.fcm_token) {
      return new Response(JSON.stringify({ message: "Post owner has no FCM token." }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // --- Bildirimi Gönder ---
    const accessToken = await getAccessToken();
    const projectId = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY")!).project_id;
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    const messagePayload = {
      message: {
        token: ownerData.fcm_token,
        notification: {
          title: "Yeni Beğeni!",
          body: `${actorData.fullName} gönderini beğendi.`,
        },
        data: { postId: record.post_id.toString(), type: "new_like" },
      },
    };

    const fcmResponse = await fetch(fcmEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${accessToken}`,
      },
      body: JSON.stringify(messagePayload),
    });

    if (!fcmResponse.ok) {
      const errorBody = await fcmResponse.text();
      throw new Error(`FCM request failed with status ${fcmResponse.status}: ${errorBody}`);
    }

    const responseData = await fcmResponse.json();
    return new Response(JSON.stringify({ success: true, fcmResponse: responseData }), {
      headers: { "Content-Type": "application/json" }, status: 200,
    });

  } catch (error) {
    console.error("Error in send-notification function:", error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" }, status: 500,
    });
  }
});