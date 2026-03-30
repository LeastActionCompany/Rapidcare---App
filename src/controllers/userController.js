const EmergencyRequest = require("../models/EmergencyRequest");
const User = require("../models/User");
const { assertUniqueIdentity } = require("../services/accountService");
const { signToken } = require("../services/tokenService");
const asyncHandler = require("../utils/asyncHandler");
const ApiError = require("../utils/ApiError");
const { toPoint } = require("../utils/geo");

const registerUser = asyncHandler(async (req, res) => {
  await assertUniqueIdentity({
    email: req.body.email,
    phone: req.body.phone,
  });

  const user = await User.create({
    ...req.body,
    location: toPoint(req.body.location),
  });

  const token = signToken({
    accountId: user._id,
    accountRole: user.accountRole,
  });

  res.status(201).json({
    success: true,
    message: "User registered successfully.",
    data: {
      user,
      token,
    },
  });
});

const loginUser = asyncHandler(async (req, res) => {
  const user = await User.findOne({ email: req.body.email.toLowerCase() }).select("+password");

  if (!user || !(await user.comparePassword(req.body.password))) {
    throw new ApiError(401, "Invalid email or password.");
  }

  const token = signToken({
    accountId: user._id,
    accountRole: user.accountRole,
  });

  res.status(200).json({
    success: true,
    message: "User login successful.",
    data: {
      user: user.toJSON(),
      token,
    },
  });
});

const getProfile = asyncHandler(async (req, res) => {
  res.status(200).json({
    success: true,
    data: req.account,
  });
});

const updateProfile = asyncHandler(async (req, res) => {
  const user = req.account;

  if (req.body.email || req.body.phone) {
    await assertUniqueIdentity({
      email: req.body.email || user.email,
      phone: req.body.phone || user.phone,
      excludeModel: User,
      excludeId: user._id,
    });
  }

  const allowedFields = [
    "fullName",
    "age",
    "gender",
    "phone",
    "email",
    "password",
    "medicalHistory",
    "emergencyContact",
  ];

  allowedFields.forEach((field) => {
    if (req.body[field] !== undefined) {
      user[field] = req.body[field];
    }
  });

  if (req.body.location) {
    user.location = toPoint(req.body.location);
  }

  await user.save();

  res.status(200).json({
    success: true,
    message: "User profile updated successfully.",
    data: user,
  });
});

const getEmergencyHistory = asyncHandler(async (req, res) => {
  const history = await EmergencyRequest.find({ userId: req.account._id })
    .populate("caregiverId", "fullName phone rating")
    .sort({ createdAt: -1 });

  res.status(200).json({
    success: true,
    count: history.length,
    data: history,
  });
});

module.exports = {
  registerUser,
  loginUser,
  getProfile,
  updateProfile,
  getEmergencyHistory,
};
