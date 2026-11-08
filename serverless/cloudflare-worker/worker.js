/**
 * chessD Serverless Signaling & WebSocket Relay
 * Plataforma: Cloudflare Workers (Plano Gratuito: 100.000 req/dia - Custo R$ 0,00)
 * Suporta troca de SDP/ICE (WebRTC P2P) e relay de contingencia em tempo real.
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Endpoint de verificacao de saude e informacoes
    if (url.pathname === '/' || url.pathname === '/health') {
      return new Response(JSON.stringify({
        service: 'chessD-serverless-relay',
        version: '1.0.2',
        status: 'online',
        cost: 'free-tier',
        stun_servers: [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
      }), {
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
      });
    }

    // Endpoint WebSocket para sinalizacao e relay
    if (url.pathname === '/ws') {
      const upgradeHeader = request.headers.get('Upgrade');
      if (!upgradeHeader || upgradeHeader.toLowerCase() !== 'websocket') {
        return new Response('Esperado handshake WebSocket', { status: 426 });
      }

      const roomId = (url.searchParams.get('room') || 'default').toUpperCase().trim();
      const playerId = url.searchParams.get('player') || `p_${Math.random().toString(36).substring(2, 8)}`;

      const pair = new WebSocketPair();
      const [client, server] = Object.values(pair);

      server.accept();
      handleSession(roomId, playerId, server);

      return new Response(null, {
        status: 101,
        webSocket: client,
        headers: {
          'Sec-WebSocket-Protocol': request.headers.get('Sec-WebSocket-Protocol') || ''
        }
      });
    }

    return new Response('Not Found', { status: 404 });
  }
};

// Armazenamento em memoria do isolate por sala
const activeRooms = new Map();

function handleSession(roomId, playerId, ws) {
  if (!activeRooms.has(roomId)) {
    activeRooms.set(roomId, new Map());
  }

  const room = activeRooms.get(roomId);
  room.set(playerId, ws);

  // Notifica entrada do jogador
  broadcastToRoom(roomId, playerId, {
    type: 'peer_joined',
    player_id: playerId,
    room_size: room.size,
    timestamp: Date.now()
  });

  ws.addEventListener('message', event => {
    try {
      const data = JSON.parse(event.data);
      // Retransmite para todos os outros participantes da sala
      broadcastToRoom(roomId, playerId, data);
    } catch (err) {
      // Ignora payload malformado
    }
  });

  ws.addEventListener('close', () => {
    room.delete(playerId);
    if (room.size === 0) {
      activeRooms.delete(roomId);
    } else {
      broadcastToRoom(roomId, playerId, {
        type: 'peer_left',
        player_id: playerId,
        room_size: room.size,
        timestamp: Date.now()
      });
    }
  });

  ws.addEventListener('error', () => {
    room.delete(playerId);
  });
}

function broadcastToRoom(roomId, senderId, messageObj) {
  const room = activeRooms.get(roomId);
  if (!room) return;

  const payload = JSON.stringify(messageObj);
  for (const [id, socket] of room.entries()) {
    if (id !== senderId && socket.readyState === WebSocket.OPEN) {
      try {
        socket.send(payload);
      } catch (e) {
        // Falha silenciosa de envio
      }
    }
  }
}
