const express = require('express');
const cors = require('cors');
const { AccessToken } = require('livekit-server-sdk');
const crypto = require('crypto');

const app = express();
app.use(cors());
app.use(express.json());

// ─── LIVEKIT CONFIG ────────────────────────────────────────────
// Set these in Render environment variables
const LIVEKIT_API_KEY = process.env.LIVEKIT_API_KEY || 'your-api-key';
const LIVEKIT_API_SECRET = process.env.LIVEKIT_API_SECRET || 'your-api-secret';
const LIVEKIT_URL = process.env.LIVEKIT_URL || 'wss://vibecall.livekit.cloud';

// ─── IN-MEMORY MATCHING QUEUE ──────────────────────────────────
// { roomName: { users: [{identity, name, gender, age, interests}], createdAt } }
const matchingQueues = {
  'random-video': { users: [], createdAt: Date.now() },
  'random-audio': { users: [], createdAt: Date.now() },
};

// Cleanup old queues every 5 minutes
setInterval(() => {
  const now = Date.now();
  for (const [key, queue] of Object.entries(matchingQueues)) {
    // Remove users waiting > 60 seconds
    queue.users = queue.users.filter(u => now - u.joinedAt < 60000);
  }
}, 30000);

// ─── TOKEN ENDPOINT ────────────────────────────────────────────
app.post('/api/token', (req, res) => {
  try {
    const { identity, name, roomName, metadata } = req.body;

    if (!identity || !roomName) {
      return res.status(400).json({ error: 'identity and roomName required' });
    }

    const at = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
      identity: identity,
      name: name || identity,
      metadata: metadata || '',
      ttl: 3600, // 1 hour
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
      token: token,
      url: LIVEKIT_URL,
      roomName: roomName,
    });
  } catch (err) {
    console.error('Token error:', err);
    res.status(500).json({ error: 'Failed to generate token' });
  }
});

// ─── MATCHING ENDPOINT ─────────────────────────────────────────
app.post('/api/match/join', (req, res) => {
  const { identity, name, gender, age, interests, callType } = req.body;
  const queueKey = callType === 'audio' ? 'random-audio' : 'random-video';
  const queue = matchingQueues[queueKey];

  if (!queue) {
    return res.status(400).json({ error: 'Invalid call type' });
  }

  // Remove user if already in queue
  queue.users = queue.users.filter(u => u.identity !== identity);

  // Try to find a compatible match
  const myInterests = interests || [];
  let bestMatch = null;
  let bestScore = -1;

  for (const candidate of queue.users) {
    // Skip same user
    if (candidate.identity === identity) continue;

    // Check gender preference
    if (gender && gender !== 'All' && candidate.gender && candidate.gender !== gender) {
      // Also check if candidate wants my gender
      if (candidate.genderFilter && candidate.genderFilter !== 'All') {
        continue; // Skip if gender doesn't match their filter
      }
    }

    // Score by shared interests
    const theirInterests = candidate.interests || [];
    const shared = myInterests.filter(i => theirInterests.includes(i)).length;
    const score = shared * 10 + Math.random() * 5; // Small random factor

    if (score > bestScore) {
      bestScore = score;
      bestMatch = candidate;
    }
  }

  if (bestMatch) {
    // Remove matched user from queue
    queue.users = queue.users.filter(u => u.identity !== bestMatch.identity);

    // Generate room name from matched pair
    const roomId = crypto.randomBytes(8).toString('hex');
    const roomName = `vibe_${roomId}`;

    return res.json({
      matched: true,
      roomName: roomName,
      partner: {
        identity: bestMatch.identity,
        name: bestMatch.name,
      },
    });
  }

  // No match found - add to queue
  queue.users.push({
    identity: identity,
    name: name || identity,
    gender: gender || '',
    age: age || 0,
    interests: myInterests,
    genderFilter: req.body.genderFilter || 'All',
    joinedAt: Date.now(),
  });

  res.json({ matched: false, message: 'Added to queue, waiting for match...' });
});

// ─── LEAVE QUEUE ───────────────────────────────────────────────
app.post('/api/match/leave', (req, res) => {
  const { identity, callType } = req.body;
  const queueKey = callType === 'audio' ? 'random-audio' : 'random-video';
  const queue = matchingQueues[queueKey];

  if (queue) {
    queue.users = queue.users.filter(u => u.identity !== identity);
  }

  res.json({ success: true });
});

// ─── QUEUE STATUS ──────────────────────────────────────────────
app.get('/api/match/status', (req, res) => {
  res.json({
    videoQueue: matchingQueues['random-video'].users.length,
    audioQueue: matchingQueues['random-audio'].users.length,
  });
});

// ─── HEALTH CHECK ──────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    service: 'VibeCall LiveKit Server',
    livekitUrl: LIVEKIT_URL,
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`VibeCall LiveKit server running on port ${PORT}`);
  console.log(`LiveKit URL: ${LIVEKIT_URL}`);
});
