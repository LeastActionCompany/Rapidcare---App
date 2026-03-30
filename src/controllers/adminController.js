const Admin = require("../models/Admin");
const Caregiver = require("../models/Caregiver");
const EmergencyRequest = require("../models/EmergencyRequest");
const User = require("../models/User");
const { signToken } = require("../services/tokenService");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");

const loginAdmin = asyncHandler(async (req, res) => {
  const admin = await Admin.findOne({ email: req.body.email.toLowerCase() }).select("+password");

  if (!admin || !(await admin.comparePassword(req.body.password))) {
    throw new ApiError(401, "Invalid email or password.");
  }

  const token = signToken({
    accountId: admin._id,
    accountRole: admin.accountRole,
  });

  res.status(200).json({
    success: true,
    message: "Admin login successful.",
    data: {
      admin: admin.toJSON(),
      token,
    },
  });
});

const getAllUsers = asyncHandler(async (_req, res) => {
  const users = await User.find().sort({ createdAt: -1 });

  res.status(200).json({
    success: true,
    count: users.length,
    data: users,
  });
});

const getAllCaregivers = asyncHandler(async (_req, res) => {
  const caregivers = await Caregiver.find().sort({ createdAt: -1 });

  res.status(200).json({
    success: true,
    count: caregivers.length,
    data: caregivers,
  });
});

const verifyCaregiver = asyncHandler(async (req, res) => {
  const caregiver = await Caregiver.findByIdAndUpdate(
    req.params.id,
    { isVerified: true },
    { new: true },
  );

  if (!caregiver) {
    throw new ApiError(404, "Caregiver not found.");
  }

  res.status(200).json({
    success: true,
    message: "Caregiver verified successfully.",
    data: caregiver,
  });
});

const deleteUser = asyncHandler(async (req, res) => {
  const user = await User.findByIdAndDelete(req.params.id);

  if (!user) {
    throw new ApiError(404, "User not found.");
  }

  await EmergencyRequest.deleteMany({ userId: user._id });

  res.status(200).json({
    success: true,
    message: "User deleted successfully.",
  });
});

const deleteCaregiver = asyncHandler(async (req, res) => {
  const caregiver = await Caregiver.findByIdAndDelete(req.params.id);

  if (!caregiver) {
    throw new ApiError(404, "Caregiver not found.");
  }

  await EmergencyRequest.updateMany(
    { caregiverId: caregiver._id },
    { $set: { caregiverId: null, status: "REJECTED" } },
  );

  res.status(200).json({
    success: true,
    message: "Caregiver deleted successfully.",
  });
});

const getEmergencyLogs = asyncHandler(async (_req, res) => {
  const logs = await EmergencyRequest.find()
    .populate("userId", "fullName phone")
    .populate("caregiverId", "fullName phone")
    .sort({ createdAt: -1 });

  res.status(200).json({
    success: true,
    count: logs.length,
    data: logs,
  });
});

module.exports = {
  loginAdmin,
  getAllUsers,
  getAllCaregivers,
  verifyCaregiver,
  deleteUser,
  deleteCaregiver,
  getEmergencyLogs,
};
