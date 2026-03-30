const Caregiver = require("../models/Caregiver");
const EmergencyRequest = require("../models/EmergencyRequest");
const { assertUniqueIdentity } = require("../services/accountService");
const { signToken } = require("../services/tokenService");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const { EMERGENCY_STATUS, ROLES } = require("../utils/constants");
const { toPoint } = require("../utils/geo");

const registerCaregiver = asyncHandler(async (req, res) => {
  if (req.body.role !== ROLES.CAREGIVER) {
    throw new ApiError(422, "Caregiver role must be CAREGIVER.");
  }

  await assertUniqueIdentity({
    email: req.body.email,
    phone: req.body.phone,
  });

  const caregiver = await Caregiver.create({
    fullName: req.body.fullName,
    phone: req.body.phone,
    email: req.body.email,
    password: req.body.password,
    documents: req.body.documents,
    accountRole: ROLES.CAREGIVER,
    location: toPoint(req.body.location),
  });

  const token = signToken({
    accountId: caregiver._id,
    accountRole: caregiver.accountRole,
  });

  res.status(201).json({
    success: true,
    message: "Caregiver registered successfully.",
    data: {
      caregiver,
      token,
    },
  });
});

const loginCaregiver = asyncHandler(async (req, res) => {
  const caregiver = await Caregiver.findOne({
    email: req.body.email.toLowerCase(),
  }).select("+password");

  if (!caregiver || !(await caregiver.comparePassword(req.body.password))) {
    throw new ApiError(401, "Invalid email or password.");
  }

  const token = signToken({
    accountId: caregiver._id,
    accountRole: caregiver.accountRole,
  });

  res.status(200).json({
    success: true,
    message: "Caregiver login successful.",
    data: {
      caregiver: caregiver.toJSON(),
      token,
    },
  });
});

const updateAvailability = asyncHandler(async (req, res) => {
  const caregiver = req.account;

  if (typeof req.body.isAvailable === "boolean") {
    caregiver.isAvailable = req.body.isAvailable;
  }

  if (req.body.location) {
    caregiver.location = toPoint(req.body.location);
  }

  await caregiver.save();

  res.status(200).json({
    success: true,
    message: "Caregiver availability updated successfully.",
    data: caregiver,
  });
});

const getNearbyRequests = asyncHandler(async (req, res) => {
  if (!req.account.isVerified) {
    throw new ApiError(403, "Only verified caregivers can access nearby emergencies.");
  }

  const requests = await EmergencyRequest.find({
    status: EMERGENCY_STATUS.PENDING,
    caregiverId: null,
    location: {
      $near: {
        $geometry: req.account.location,
        $maxDistance: Number(process.env.SOS_SEARCH_RADIUS_METERS) || 5000,
      },
    },
  })
    .populate("userId", "fullName phone medicalHistory emergencyContact age gender")
    .sort({ createdAt: -1 });

  res.status(200).json({
    success: true,
    count: requests.length,
    data: requests,
  });
});

const getProfile = asyncHandler(async (req, res) => {
  res.status(200).json({
    success: true,
    data: req.account,
  });
});

module.exports = {
  registerCaregiver,
  loginCaregiver,
  updateAvailability,
  getNearbyRequests,
  getProfile,
};
