const Message = require("../models/Message");
const {
  ensureEmergencyParticipant,
  findEmergencyByIdOrThrow,
  resolveChatReceiver,
} = require("../services/emergencyService");
const { emitToAccount, emitToEmergencyRoom } = require("../services/socketService");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const {
  ACCOUNT_MODEL_BY_ROLE,
  ROLES,
  SOCKET_EVENTS,
} = require("../utils/constants");

const getMessagesByEmergency = asyncHandler(async (req, res) => {
  const emergency = await findEmergencyByIdOrThrow(req.params.emergencyId);
  ensureEmergencyParticipant(emergency, req.auth);

  const messages = await Message.find({ emergencyId: req.params.emergencyId }).sort({
    createdAt: 1,
  });

  res.status(200).json({
    success: true,
    count: messages.length,
    data: messages,
  });
});

const sendMessage = asyncHandler(async (req, res) => {
  if (![ROLES.USER, ROLES.CAREGIVER].includes(req.auth.accountRole)) {
    throw new ApiError(403, "Only users and caregivers can send messages.");
  }

  const emergency = await findEmergencyByIdOrThrow(req.body.emergencyId);
  ensureEmergencyParticipant(emergency, req.auth);

  const { receiverId, receiverModel } = resolveChatReceiver(emergency, req.auth.accountRole);

  const message = await Message.create({
    emergencyId: emergency._id,
    senderId: req.auth.accountId,
    senderModel: ACCOUNT_MODEL_BY_ROLE[req.auth.accountRole],
    receiverId,
    receiverModel,
    message: req.body.message,
  });

  const payload = {
    emergencyId: emergency._id,
    message,
  };

  const receiverRole = receiverModel === "User" ? ROLES.USER : ROLES.CAREGIVER;

  emitToAccount(receiverRole, receiverId, SOCKET_EVENTS.CHAT_MESSAGE, payload);
  emitToEmergencyRoom(emergency._id, SOCKET_EVENTS.CHAT_MESSAGE, payload);

  res.status(201).json({
    success: true,
    message: "Message sent successfully.",
    data: message,
  });
});

module.exports = {
  getMessagesByEmergency,
  sendMessage,
};
