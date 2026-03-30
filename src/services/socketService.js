let ioInstance = null;

const buildAccountRoom = (accountRole, accountId) => `${accountRole}:${accountId}`;
const buildEmergencyRoom = (emergencyId) => `emergency:${emergencyId}`;

const setIoServer = (io) => {
  ioInstance = io;
};

const getIoServer = () => ioInstance;

const emitToAccount = (accountRole, accountId, event, payload) => {
  if (!ioInstance) {
    return;
  }

  ioInstance.to(buildAccountRoom(accountRole, accountId)).emit(event, payload);
};

const emitToManyAccounts = (accounts, event, payloadFactory) => {
  if (!ioInstance) {
    return;
  }

  accounts.forEach(({ accountRole, accountId, payload }) => {
    emitToAccount(accountRole, accountId, event, payloadFactory ? payloadFactory(payload) : payload);
  });
};

const emitToEmergencyRoom = (emergencyId, event, payload) => {
  if (!ioInstance) {
    return;
  }

  ioInstance.to(buildEmergencyRoom(emergencyId)).emit(event, payload);
};

module.exports = {
  buildAccountRoom,
  buildEmergencyRoom,
  setIoServer,
  getIoServer,
  emitToAccount,
  emitToManyAccounts,
  emitToEmergencyRoom,
};
