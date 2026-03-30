const Caregiver = require("../models/Caregiver");
const EmergencyRequest = require("../models/EmergencyRequest");
const {
  createEmergencySnapshot,
  ensureEmergencyCanBeCompleted,
  ensureEmergencyParticipant,
  findEmergencyByIdOrThrow,
  findNearbyCaregivers,
} = require("../services/emergencyService");
const {
  emitToAccount,
  emitToEmergencyRoom,
} = require("../services/socketService");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const { EMERGENCY_STATUS, ROLES, SOCKET_EVENTS } = require("../utils/constants");
const { toPoint } = require("../utils/geo");

const triggerSos = asyncHandler(async (req, res) => {
  const user = req.account;
  const location = req.body.location ? toPoint(req.body.location) : user.location;

  if (!location) {
    throw new ApiError(400, "A valid location is required to trigger SOS.");
  }

  user.location = location;
  await user.save();

  const emergency = await EmergencyRequest.create({
    userId: user._id,
    location,
    medicalSnapshot: createEmergencySnapshot(user),
  });

  const nearbyCaregivers = await findNearbyCaregivers(location);

  nearbyCaregivers.forEach(({ caregiver, distanceMeters }) => {
    emitToAccount(caregiver.accountRole, caregiver._id, SOCKET_EVENTS.EMERGENCY_NEW, {
      emergencyId: emergency._id,
      userId: user._id,
      userName: user.fullName,
      location,
      medicalSnapshot: emergency.medicalSnapshot,
      distanceMeters,
      createdAt: emergency.createdAt,
    });
  });

  res.status(201).json({
    success: true,
    message: "SOS triggered successfully.",
    data: {
      emergency,
      nearbyCaregivers: nearbyCaregivers.map(({ caregiver, distanceMeters }) => ({
        caregiverId: caregiver._id,
        fullName: caregiver.fullName,
        phone: caregiver.phone,
        rating: caregiver.rating,
        distanceMeters,
      })),
    },
  });
});

const getEmergencyById = asyncHandler(async (req, res) => {
  const emergency = await findEmergencyByIdOrThrow(req.params.id);
  ensureEmergencyParticipant(emergency, req.auth);

  res.status(200).json({
    success: true,
    data: emergency,
  });
});

const acceptEmergency = asyncHandler(async (req, res) => {
  if (!req.account.isVerified) {
    throw new ApiError(403, "Only verified caregivers can accept emergencies.");
  }

  if (!req.account.isAvailable) {
    throw new ApiError(400, "Caregiver must be marked available before accepting emergencies.");
  }

  const emergency = await EmergencyRequest.findOneAndUpdate(
    {
      _id: req.body.emergencyId,
      status: EMERGENCY_STATUS.PENDING,
      caregiverId: null,
      location: {
        $near: {
          $geometry: req.account.location,
          $maxDistance: Number(process.env.SOS_SEARCH_RADIUS_METERS) || 5000,
        },
      },
    },
    {
      $set: {
        caregiverId: req.account._id,
        status: EMERGENCY_STATUS.ACCEPTED,
      },
    },
    { new: true },
  )
    .populate("userId", "fullName phone emergencyContact location")
    .populate("caregiverId", "fullName phone location");

  if (!emergency) {
    throw new ApiError(409, "Emergency request is no longer available.");
  }

  req.account.isAvailable = false;
  await req.account.save();

  emitToAccount(ROLES.USER, emergency.userId._id, SOCKET_EVENTS.EMERGENCY_ACCEPTED, {
    emergencyId: emergency._id,
    caregiver: emergency.caregiverId,
    status: emergency.status,
  });

  emitToEmergencyRoom(emergency._id, SOCKET_EVENTS.EMERGENCY_ACCEPTED, {
    emergencyId: emergency._id,
    caregiver: emergency.caregiverId,
    status: emergency.status,
  });

  res.status(200).json({
    success: true,
    message: "Emergency accepted successfully.",
    data: emergency,
  });
});

const rejectEmergency = asyncHandler(async (req, res) => {
  const emergency = await EmergencyRequest.findById(req.body.emergencyId)
    .populate("userId", "fullName phone")
    .populate("caregiverId", "fullName phone");

  if (!emergency) {
    throw new ApiError(404, "Emergency request not found.");
  }

  if ([EMERGENCY_STATUS.REJECTED, EMERGENCY_STATUS.COMPLETED].includes(emergency.status)) {
    throw new ApiError(400, "This emergency is already closed.");
  }

  if (req.auth.accountRole === ROLES.USER && emergency.userId._id.toString() !== req.auth.accountId.toString()) {
    throw new ApiError(403, "You can only reject your own emergency requests.");
  }

  if (
    req.auth.accountRole === ROLES.CAREGIVER &&
    (!emergency.caregiverId || emergency.caregiverId._id.toString() !== req.auth.accountId.toString())
  ) {
    throw new ApiError(403, "You can only reject emergencies assigned to you.");
  }

  emergency.status = EMERGENCY_STATUS.REJECTED;
  await emergency.save();

  if (req.auth.accountRole === ROLES.CAREGIVER) {
    await Caregiver.findByIdAndUpdate(req.auth.accountId, { isAvailable: true });
  }

  emitToAccount(ROLES.USER, emergency.userId._id, SOCKET_EVENTS.EMERGENCY_REJECTED, {
    emergencyId: emergency._id,
    status: emergency.status,
  });
  emitToEmergencyRoom(emergency._id, SOCKET_EVENTS.EMERGENCY_REJECTED, {
    emergencyId: emergency._id,
    status: emergency.status,
  });

  res.status(200).json({
    success: true,
    message: "Emergency rejected successfully.",
    data: emergency,
  });
});

const completeEmergency = asyncHandler(async (req, res) => {
  const emergency = await EmergencyRequest.findById(req.body.emergencyId)
    .populate("userId", "fullName phone")
    .populate("caregiverId", "fullName phone");

  if (!emergency) {
    throw new ApiError(404, "Emergency request not found.");
  }

  ensureEmergencyCanBeCompleted(emergency);

  if (
    req.auth.accountRole === ROLES.CAREGIVER &&
    (!emergency.caregiverId || emergency.caregiverId._id.toString() !== req.auth.accountId.toString())
  ) {
    throw new ApiError(403, "You can only complete emergencies assigned to you.");
  }

  emergency.status = EMERGENCY_STATUS.COMPLETED;
  await emergency.save();

  if (emergency.caregiverId) {
    await Caregiver.findByIdAndUpdate(emergency.caregiverId._id, { isAvailable: true });
  }

  emitToAccount(ROLES.USER, emergency.userId._id, SOCKET_EVENTS.EMERGENCY_COMPLETED, {
    emergencyId: emergency._id,
    status: emergency.status,
  });
  emitToEmergencyRoom(emergency._id, SOCKET_EVENTS.EMERGENCY_COMPLETED, {
    emergencyId: emergency._id,
    status: emergency.status,
  });

  res.status(200).json({
    success: true,
    message: "Emergency completed successfully.",
    data: emergency,
  });
});

module.exports = {
  triggerSos,
  getEmergencyById,
  acceptEmergency,
  rejectEmergency,
  completeEmergency,
};
