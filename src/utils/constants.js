const ROLES = {
  USER: "USER",
  CAREGIVER: "CAREGIVER",
  ADMIN: "ADMIN",
};

const ACCOUNT_MODEL_BY_ROLE = {
  [ROLES.USER]: "User",
  [ROLES.CAREGIVER]: "Caregiver",
  [ROLES.ADMIN]: "Admin",
};

const EMERGENCY_STATUS = {
  PENDING: "PENDING",
  ACCEPTED: "ACCEPTED",
  REJECTED: "REJECTED",
  COMPLETED: "COMPLETED",
};

const SOCKET_EVENTS = {
  EMERGENCY_NEW: "emergency:new",
  EMERGENCY_ACCEPTED: "emergency:accepted",
  EMERGENCY_REJECTED: "emergency:rejected",
  EMERGENCY_COMPLETED: "emergency:completed",
  CHAT_MESSAGE: "chat:message",
  CHAT_TYPING: "chat:typing",
};

module.exports = {
  ROLES,
  ACCOUNT_MODEL_BY_ROLE,
  EMERGENCY_STATUS,
  SOCKET_EVENTS,
};
