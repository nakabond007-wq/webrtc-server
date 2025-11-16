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
  }
});

const PORT = process.env.PORT || 3000;

const users = {};
let userCounter = 10; // Start from 10 for 2-digit IDs

io.on('connection', (socket) => {
  // Assign short 2-digit ID
  const shortId = userCounter.toString();
  socket.shortId = shortId;
  userCounter++;
  
  console.log('User connected:', socket.id, '-> Short ID:', shortId);
  users[shortId] = socket;
  
  // Send short ID to client
  socket.emit('short-id', shortId);

  socket.on('offer', (data) => {
    console.log('Offer received from', socket.shortId, 'to', data.targetUserId, 'isVideo:', data.isVideo);
    const targetSocket = users[data.targetUserId];
    if (targetSocket) {
      // Track who is calling whom
      socket.callPartner = data.targetUserId;
      targetSocket.callPartner = socket.shortId;
      
      targetSocket.emit('offer', {
        offer: data.offer,
        callerId: socket.shortId,
        isVideo: data.isVideo,
      });
    } else {
      console.log('Target user not found:', data.targetUserId);
    }
  });

  socket.on('answer', (data) => {
    console.log('Answer received from', socket.shortId, 'to', data.targetUserId);
    const targetSocket = users[data.targetUserId];
    if (targetSocket) {
      targetSocket.emit('answer', {
        answer: data.answer,
      });
    }
  });

  socket.on('ice-candidate', (data) => {
    console.log('ICE candidate received from', socket.shortId);
    // Broadcast to all other users (simplified)
    socket.broadcast.emit('ice-candidate', data);
  });

  socket.on('call-ended', (data) => {
    console.log('Call ended by', socket.shortId, 'with data:', data);
    if (socket.callPartner) {
      const partnerSocket = users[socket.callPartner];
      if (partnerSocket) {
        console.log('Notifying partner', socket.callPartner, 'that call ended');
        partnerSocket.emit('call-ended', {});
        partnerSocket.callPartner = null;
      }
      socket.callPartner = null;
    } else {
      console.log('No call partner found for', socket.shortId);
    }
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.shortId);
    // Notify call partner if in active call
    if (socket.callPartner) {
      const partnerSocket = users[socket.callPartner];
      if (partnerSocket) {
        console.log('Notifying', socket.callPartner, 'that user disconnected');
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
