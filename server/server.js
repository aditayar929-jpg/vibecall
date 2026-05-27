require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { AccessToken, RoomServiceClient } = require('livekit-server-sdk');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const LIVEKIT_API_KEY = process.env.LIVEKIT_API_KEY;
const LIVEKIT_API_SECRET = process.env.LIVEKIT_API_SECRET;

// ─── In-Memory Match Queue ──────────────────────────────────
const matchQueues = {
  video: [],
  audio: [],
};

// Clean stale entries older than 30 seconds
function cleanQueue(queueType) {
  const now = Date.now();
  matchQueues[queueType] = matchQueues[queueType].filter(
    (entry) => now - entry.timestamp < 30000
  );
}

// ─── Health Check ───────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    queue: {
      video: matchQueues.video.length,
      audio: matchQueues.audio.length,
    },
  });
});

// ─── Generate LiveKit Token ─────────────────────────────────
app.post('/api/token', (req, res) => {
  try {
    const { identity, name, roomName, metadata } = req.body;

    if (!identity || !roomName) {
      return res.status(400).json({ error: 'identity and roomName required' });
    }

    const at = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
      identity: identity,
      name: name || 'User',
      metadata: metadata || '',
    });

    at.addGrant({
      roomJoin: true,
      room: roomName,
      canPublish: true,
      canSubscribe: true,
      canPublishData: true,
    });

    const token = at.toJwt();

    res.json({
      token,
      roomName,
      identity,
    });
  } catch (err) {
    console.error('Token error:', err);
    res.status(500).json({ error: 'Failed to generate token' });
  }
});

// ─── Join Match Queue ───────────────────────────────────────
app.post('/api/match/join', (req, res) => {
  const { identity, name, avatar, gender, age, interests, genderFilter, callType } = req.body;

  if (!identity) {
    return res.status(400).json({ error: 'identity required' });
  }

  const type = callType || 'video';
  cleanQueue(type);

  // Remove if already in queue
  matchQueues[type] = matchQueues[type].filter((e) => e.identity !== identity);

  // Check for compatible match
  const myGender = gender || '';
  const myAge = age || 18;
  const filter = genderFilter || 'All';
  const myInterests = interests || [];

  const matchIndex = matchQueues[type].findIndex((entry) => {
    // Gender filter
    if (filter !== 'All' && entry.gender !== filter) return false;
    // Age filter
    if (myAge < entry.minAge || myAge > entry.maxAge) return false;
    // Their gender filter
    if (entry.genderFilter !== 'All' && myGender !== entry.genderFilter) return false;
    // My age in their range
    if (myAge < entry.minAge || myAge > entry.maxAge) return false;

    return true;
  });

  if (matchIndex !== -1) {
    // Found a match!
    const partner = matchQueues[type].splice(matchIndex, 1)[0];
    const roomName = `call_${identity.substring(0, 6)}_${partner.identity.substring(0, 6)}_${Date.now()}`;

    // Generate tokens for both
    const myToken = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
      identity,
      name: name || 'User',
    });
    myToken.addGrant({
      roomJoin: true,
      room: roomName,
      canPublish: true,
      canSubscribe: true,
    });

    const partnerToken = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
      identity: partner.identity,
      name: partner.name || 'User',
    });
    partnerToken.addGrant({
      roomJoin: true,
      room: roomName,
      canPublish: true,
      canSubscribe: true,
    });

    return res.json({
      matched: true,
      roomName,
      token: myToken.toJwt(),
      partner: {
        identity: partner.identity,
        name: partner.name,
        avatar: partner.avatar,
        gender: partner.gender,
        age: partner.age,
      },
    });
  }

  // No match found, add to queue
  matchQueues[type].push({
    identity,
    name: name || 'User',
    avatar: avatar || '',
    gender: myGender,
    age: myAge,
    interests: myInterests,
    genderFilter: filter,
    minAge: 18,
    maxAge: 99,
    callType: type,
    timestamp: Date.now(),
  });

  return res.json({
    matched: false,
    queuePosition: matchQueues[type].length,
  });
});

// ─── Leave Match Queue ──────────────────────────────────────
app.post('/api/match/leave', (req, res) => {
  const { identity, callType } = req.body;
  const type = callType || 'video';

  matchQueues[type] = matchQueues[type].filter((e) => e.identity !== identity);
  res.json({ success: true });
});

// ─── Check Queue Status ─────────────────────────────────────
app.get('/api/match/status', (req, res) => {
  cleanQueue('video');
  cleanQueue('audio');

  res.json({
    video: matchQueues.video.length,
    audio: matchQueues.audio.length,
  });
});

// ─── List Rooms (debug) ─────────────────────────────────────
app.get('/api/rooms', async (req, res) => {
  try {
    if (!LIVEKIT_API_KEY || LIVEKIT_API_KEY === 'your_api_key_here') {
      return res.json({ rooms: [], note: 'LiveKit not configured' });
    }
    const roomService = new RoomServiceClient(
      `https://${process.env.LIVEKIT_HOST || 'localhost'}`,
      LIVEKIT_API_KEY,
      LIVEKIT_API_SECRET
    );
    const rooms = await roomService.listRooms();
    res.json({ rooms });
  } catch (err) {
    res.json({ rooms: [], error: err.message });
  }
});

// ─── Start Server ───────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`VibeCall server running on port ${PORT}`);
  console.log(`LiveKit API Key: ${LIVEKIT_API_KEY ? 'configured' : 'NOT configured'}`);
  console.log(`Health: http://localhost:${PORT}/health`);
});
