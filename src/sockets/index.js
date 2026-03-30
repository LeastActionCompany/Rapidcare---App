const { Server } = require("socket.io");

const EmergencyRequest = require("../models/EmergencyRequest");
const Message = require("../models/Message");
const ApiError = require("../utils/ApiError");
const {
  ACCOUNT_MODEL_BY_ROLE,
  ROLES,
  SOCKET_EVENTS,
} = require("../utils/constants");
const {
  buildAccountRoom,
  buildEmergencyRoom,
  emitToAccount,
  emitToEmergencyRoom,
  setIoServer,
} = require("../services/socketService");
const { verifyToken } = require("../services/tokenService");

const initializeSocket = (httpServer) => {
  const io = new Server(httpServer, {
    cors: {
      origin: process.env.CLIENT_URL ? process.env.CLIENT_URL.split(",") : "*",
      credentials: true,
    },
  });

  io.use(async (socket, next) => {
    try {
      const rawToken =
        socket.handshake.auth?.token ||
        socket.handshake.headers.authorization?.replace("Bearer ", "");

      if (!rawToken) {
        throw new ApiError(401, "Socket authentication token is required.");
      }

      const decoded = verifyToken(rawToken);
      socket.data.auth = {
        accountId: decoded.sub,
        accountRole: decoded.role,
      };

      next();
    } catch (error) {
      next(error);
    }
  });

  io.on("connection", (socket) => {
    socket.join(buildAccountRoom(socket.data.auth.accountRole, socket.data.auth.accountId));

    socket.on("emergency:join", async ({ emergencyId }) => {
      try {
        const emergency = await EmergencyRequest.findById(emergencyId);

        if (!emergency) {
          socket.emit("socket:error", { message: "Emergency not found." });
          return;
        }

        const isUser = emergency.userId?.toString() === socket.data.auth.accountId;
        const isCaregiver = emergency.caregiverId?.toString() === socket.data.auth.accountId;
        const isAdmin = socket.data.auth.accountRole === ROLES.ADMIN;

        if (!isUser && !isCaregiver && !isAdmin) {
          socket.emit("socket:error", { message: "You cannot join this emergency room." });
          return;
        }

        // Only authenticated participants can subscribe to room-level emergency updates.
        socket.join(buildEmergencyRoom(emergencyId));
      } catch (error) {
        socket.emit("socket:error", {
          message: error.message || "Unable to join emergency room.",
        });
      }
    });

    socket.on("chat:typing", async ({ emergencyId, isTyping }) => {
      try {
        const emergency = await EmergencyRequest.findById(emergencyId);

        if (!emergency) {
          throw new ApiError(404, "Emergency not found.");
        }

        const isUser = emergency.userId?.toString() === socket.data.auth.accountId;
        const isCaregiver = emergency.caregiverId?.toString() === socket.data.auth.accountId;

        if (!isUser && !isCaregiver) {
          throw new ApiError(403, "You are not part of this emergency chat.");
        }

        socket.to(buildEmergencyRoom(emergencyId)).emit(SOCKET_EVENTS.CHAT_TYPING, {
          emergencyId,
          senderId: socket.data.auth.accountId,
          senderRole: socket.data.auth.accountRole,
          isTyping: Boolean(isTyping),
        });
      } catch (error) {
        socket.emit("socket:error", {
          message: error.message || "Unable to update typing status.",
        });
      }
    });

    socket.on("chat:send", async ({ emergencyId, message }) => {
      try {
        if (!message || typeof message !== "string" || !message.trim()) {
          throw new ApiError(400, "Message content is required.");
        }

        const emergency = await EmergencyRequest.findById(emergencyId);

        if (!emergency) {
          throw new ApiError(404, "Emergency not found.");
        }

        const auth = socket.data.auth;
        const isUser = emergency.userId?.toString() === auth.accountId;
        const isCaregiver = emergency.caregiverId?.toString() === auth.accountId;

        if (!isUser && !isCaregiver) {
          throw new ApiError(403, "You are not part of this emergency chat.");
        }

        const receiverRole = auth.accountRole === ROLES.USER ? ROLES.CAREGIVER : ROLES.USER;
        const receiverId =
          receiverRole === ROLES.USER ? emergency.userId?.toString() : emergency.caregiverId?.toString();

        if (!receiverId) {
          throw new ApiError(400, "Receiver is not available for this emergency yet.");
        }

        const savedMessage = await Message.create({
          emergencyId,
          senderId: auth.accountId,
          senderModel: ACCOUNT_MODEL_BY_ROLE[auth.accountRole],
          receiverId,
          receiverModel: ACCOUNT_MODEL_BY_ROLE[receiverRole],
          message: message.trim(),
        });

        const payload = {
          emergencyId,
          message: savedMessage,
        };

        emitToAccount(receiverRole, receiverId, SOCKET_EVENTS.CHAT_MESSAGE, payload);
        emitToEmergencyRoom(emergencyId, SOCKET_EVENTS.CHAT_MESSAGE, payload);
      } catch (error) {
        socket.emit("socket:error", {
          message: error.message || "Failed to send chat message.",
        });
      }
    });
  });

  setIoServer(io);
  return io;
};

module.exports = {
  initializeSocket,
};
