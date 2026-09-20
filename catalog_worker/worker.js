// Musicfy Catalog Worker — Cloudflare Worker + KV
// Handles admin song uploads and serves audio/images to all users.
//
// KV key structure:
//   catalog_meta       → JSON array of song metadata
//   audio_{id}         → raw audio bytes (ArrayBuffer)
//   cover_{id}         → raw cover image bytes (ArrayBuffer)

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS headers (needed for app requests)
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, X-Admin-Pin',
    };

    // Handle preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // ── GET /catalog ── List all songs (public) ──
      if (request.method === 'GET' && path === '/catalog') {
        const meta = await env.CATALOG_KV.get('catalog_meta');
        return new Response(meta || '[]', {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // ── GET /catalog/stream/:id ── Serve audio file (public) ──
      if (request.method === 'GET' && path.startsWith('/catalog/stream/')) {
        const id = path.replace('/catalog/stream/', '');
        const meta = JSON.parse(await env.CATALOG_KV.get('catalog_meta') || '[]');
        const song = meta.find(s => s.id === id);
        if (!song) return new Response('Not found', { status: 404, headers: corsHeaders });

        const audio = await env.CATALOG_KV.get(`audio_${id}`, 'arrayBuffer');
        if (!audio) return new Response('Audio not found', { status: 404, headers: corsHeaders });

        return new Response(audio, {
          headers: {
            ...corsHeaders,
            'Content-Type': song.audioContentType || 'audio/mpeg',
            'Content-Length': audio.byteLength.toString(),
            'Accept-Ranges': 'bytes',
            'Cache-Control': 'public, max-age=86400',
          },
        });
      }

      // ── GET /catalog/cover/:id ── Serve cover image (public) ──
      if (request.method === 'GET' && path.startsWith('/catalog/cover/')) {
        const id = path.replace('/catalog/cover/', '');
        const image = await env.CATALOG_KV.get(`cover_${id}`, 'arrayBuffer');
        if (!image) return new Response('Image not found', { status: 404, headers: corsHeaders });

        const meta = JSON.parse(await env.CATALOG_KV.get('catalog_meta') || '[]');
        const song = meta.find(s => s.id === id);

        return new Response(image, {
          headers: {
            ...corsHeaders,
            'Content-Type': song?.imageContentType || 'image/jpeg',
            'Cache-Control': 'public, max-age=86400',
          },
        });
      }

      // ── Admin-only routes below ── require X-Admin-Pin header ──
      const pin = request.headers.get('X-Admin-Pin');
      if (pin !== env.ADMIN_PIN) {
        return new Response(JSON.stringify({ error: 'Unauthorized' }), {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // ── POST /catalog ── Upload a new song (admin only) ──
      if (request.method === 'POST' && path === '/catalog') {
        const formData = await request.formData();
        const title = formData.get('title');
        const artist = formData.get('artist');
        const language = formData.get('language') || 'unknown';
        const audioFile = formData.get('audio');
        const coverFile = formData.get('cover');

        if (!title || !artist || !audioFile) {
          return new Response(JSON.stringify({ error: 'Title, artist, and audio file are required' }), {
            status: 400,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          });
        }

        const id = `catalog_${Date.now()}`;

        // Store audio file in KV
        const audioBuffer = await audioFile.arrayBuffer();
        await env.CATALOG_KV.put(`audio_${id}`, audioBuffer);

        // Store cover image if provided
        let hasImage = false;
        let imageContentType = 'image/jpeg';
        if (coverFile && coverFile.size > 0) {
          const imageBuffer = await coverFile.arrayBuffer();
          await env.CATALOG_KV.put(`cover_${id}`, imageBuffer);
          hasImage = true;
          imageContentType = coverFile.type || 'image/jpeg';
        }

        // Update metadata list
        const meta = JSON.parse(await env.CATALOG_KV.get('catalog_meta') || '[]');
        meta.unshift({
          id,
          title,
          artist,
          language: language.toLowerCase(),
          hasImage,
          audioContentType: audioFile.type || 'audio/mpeg',
          imageContentType,
          createdAt: new Date().toISOString(),
        });
        await env.CATALOG_KV.put('catalog_meta', JSON.stringify(meta));

        return new Response(JSON.stringify({ success: true, id }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      // ── DELETE /catalog/:id ── Delete a song (admin only) ──
      if (request.method === 'DELETE' && path.startsWith('/catalog/')) {
        const id = path.replace('/catalog/', '');

        // Remove files from KV
        await env.CATALOG_KV.delete(`audio_${id}`);
        await env.CATALOG_KV.delete(`cover_${id}`);

        // Remove from metadata
        const meta = JSON.parse(await env.CATALOG_KV.get('catalog_meta') || '[]');
        const filtered = meta.filter(s => s.id !== id);
        await env.CATALOG_KV.put('catalog_meta', JSON.stringify(filtered));

        return new Response(JSON.stringify({ success: true }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      return new Response('Not found', { status: 404, headers: corsHeaders });
    } catch (err) {
      return new Response(JSON.stringify({ error: err.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  },
};
