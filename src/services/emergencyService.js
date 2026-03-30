const Caregiver = require("../models/Caregiver");
const EmergencyRequest = require("../models/EmergencyRequest");
const ApiError = require("../utils/ApiError");
const { calculateApproxDistanceMeters } = require("../utils/geo");
const { ACCOUNT_MODEL_BY_ROLE, EMERGENCY_STATUS, ROLES } = require("../utils/constants");

const defaultRadius = Number(process.env.SOS_SEARCH_RADIUS_METERS) || 5000;

const findNearbyCaregivers = async (location) => {
  const caregivers = await Caregiver.find({
    isVerified: true,
    isAvailable: true,
    location: {
      $near: {
        $geometry: location,
        $maxDistance: defaultRadius,
      },
    },
  }).select("fullName phone email location rating isAvailable");

  return caregivers.map((caregiver) => ({
    caregiver,
    distanceMeters: calculateApproxDistanceMeters(
      location.coordinates,
      caregiver.location.coordinates,
    ),
  }));
};

const createEmergencySnapshot = (user) => ({
  fullName: user.fullName,
  age: user.age,
  gender: user.gender,
  conditions: user.medicalHistory?.conditions || [],
  medications: user.medicalHistory?.medications || [],
  allergies: user.medicalHistory?.allergies || [],
  emergencyContact: user.emergencyContact,
});

const findEmergencyByIdOrThrow = async (emergencyId) => {
  const emergency = await EmergencyRequest.findById(emergencyId)
    .populate("userId", "fullName phone location medicalHistory emergencyContact age gender")
    .populate("caregiverId", "fullName phone location isAvailable isVerified rating");

  if (!emergency) {
    throw new ApiError(404, "Emergency request not found.");
  }

  return emergency;
};

const ensureEmergencyParticipant = (emergency, auth) => {
  if (!auth) {
    throw new ApiError(401, "Authentication required.");
  }

  if (auth.accountRole === ROLES.ADMIN) {
    return;
  }

  const accountId = auth.accountId.toString();
  const isUser = emergency.userId && emergency.userId._id.toString() === accountId;
  const isCaregiver =
    emergency.caregiverId && emergency.caregiverId._id.toString() === accountId;

  if (!isUser && !isCaregiver) {
    throw new ApiError(403, "You are not allowed to access this emergency.");
  }
};

const resolveChatReceiver = (emergency, senderRole) => {
  if (senderRole === ROLES.USER) {
    if (!emergency.caregiverId) {
      throw new ApiError(400, "No caregiver has accepted this emergency yet.");
    }

    return {
      receiverId: emergency.caregiverId._id,
      receiverModel: ACCOUNT_MODEL_BY_ROLE[ROLES.CAREGIVER],
    };
  }

  return {
    receiverId: emergency.userId._id,
    receiverModel: ACCOUNT_MODEL_BY_ROLE[ROLES.USER],
  };
};

const ensureEmergencyCanBeCompleted = (emergency) => {
  if (emergency.status !== EMERGENCY_STATUS.ACCEPTED) {
    throw new ApiError(400, "Only accepted emergencies can be completed.");
  }
};

module.exports = {
  defaultRadius,
  findNearbyCaregivers,
  createEmergencySnapshot,
  findEmergencyByIdOrThrow,
  ensureEmergencyParticipant,
  resolveChatReceiver,
  ensureEmergencyCanBeCompleted,
};
