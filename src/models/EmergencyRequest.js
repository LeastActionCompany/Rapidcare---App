const mongoose = require("mongoose");

const { EMERGENCY_STATUS } = require("../utils/constants");

const locationSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ["Point"],
      default: "Point",
    },
    coordinates: {
      type: [Number],
      required: true,
      validate: {
        validator: (coordinates) => Array.isArray(coordinates) && coordinates.length === 2,
        message: "Location coordinates must contain longitude and latitude.",
      },
    },
  },
  { _id: false },
);

const emergencyRequestSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    caregiverId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Caregiver",
      default: null,
      index: true,
    },
    location: {
      type: locationSchema,
      required: true,
    },
    status: {
      type: String,
      enum: Object.values(EMERGENCY_STATUS),
      default: EMERGENCY_STATUS.PENDING,
      index: true,
    },
    medicalSnapshot: {
      fullName: String,
      age: Number,
      gender: String,
      conditions: {
        type: [String],
        default: [],
      },
      medications: {
        type: [String],
        default: [],
      },
      allergies: {
        type: [String],
        default: [],
      },
      emergencyContact: {
        name: String,
        phone: String,
      },
    },
  },
  {
    timestamps: true,
  },
);

emergencyRequestSchema.index({ location: "2dsphere" });

module.exports = mongoose.model("EmergencyRequest", emergencyRequestSchema);
