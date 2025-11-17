// Simple Node.js signaling server for WebRTC
// Install dependencies: npm install socket.io express
// Run: node signaling_server.js

const express = require('express');
const http = require('http');
const socketIO = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: '*',
  },
  perMessageDeflate: {
    threshold: 1024,
    zlibDeflateOptions: {
      chunkSize: 8 * 1024,
      level: 6,
    },
  },
  httpCompression: {
    threshold: 1024,
  },
  transports: ['websocket'],
  allowUpgrades: false,
});

const PORT = process.env.PORT || 3000;

const users = {};
const uniqueIdMap = {}; // Map uniqueId -> socket
let userCounter = 10; // Start from 10 for 2-digit IDs

io.on('connection', (socket) => {
  // Assign short 2-digit ID
  const shortId = userCounter.toString();
  socket.shortId = shortId;
  userCounter++;
  
  users[shortId] = socket;
  socket.emit('short-id', shortId);

  // Register unique ID
  socket.on('register-unique-id', (data) => {
    socket.uniqueId = data.uniqueId;
    uniqueIdMap[data.uniqueId] = socket;
  });

  socket.on('offer', (data) => {
    let targetSocket = uniqueIdMap[data.targetUserId] || users[data.targetUserId];
    
    if (targetSocket) {
      socket.callPartner = data.targetUserId;
      targetSocket.callPartner = socket.uniqueId || socket.shortId;
      
      targetSocket.emit('offer', {
        offer: data.offer,
        callerId: socket.uniqueId || socket.shortId,
        isVideo: data.isVideo,
      });
    }
  });

  socket.on('answer', (data) => {
    const targetSocket = uniqueIdMap[data.targetUserId] || users[data.targetUserId];
    if (targetSocket) {
      targetSocket.emit('answer', {
        answer: data.answer,
      });
    }
  });

  socket.on('ice-candidate', (data) => {
    socket.broadcast.emit('ice-candidate', data);
  });

  socket.on('call-ended', (data) => {
    if (socket.callPartner) {
      const partnerSocket = uniqueIdMap[socket.callPartner] || users[socket.callPartner];
      if (partnerSocket) {
        partnerSocket.emit('call-ended', {});
        partnerSocket.callPartner = null;
      }
      socket.callPartner = null;
    }
  });

  socket.on('disconnect', () => {
    if (socket.uniqueId) {
      delete uniqueIdMap[socket.uniqueId];
    }
    if (socket.callPartner) {
      const partnerSocket = uniqueIdMap[socket.callPartner] || users[socket.callPartner];
      if (partnerSocket) {
        partnerSocket.emit('call-ended');
        partnerSocket.callPartner = null;
      }
    }
    delete users[socket.shortId];
  });
});

server.listen(PORT, () => {
  console.log(`Signaling server running on port ${PORT}`);
  console.log('Available users will have socket IDs assigned on connection');
});
