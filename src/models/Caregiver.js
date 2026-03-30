const bcrypt = require("bcrypt");
const mongoose = require("mongoose");

const { ROLES } = require("../utils/constants");

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

const caregiverSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: true,
      trim: true,
    },
    phone: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      required: true,
      minlength: 8,
      select: false,
    },
    accountRole: {
      type: String,
      enum: [ROLES.CAREGIVER],
      default: ROLES.CAREGIVER,
    },
    location: {
      type: locationSchema,
      required: true,
    },
    documents: {
      type: [String],
      default: [],
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    isAvailable: {
      type: Boolean,
      default: false,
    },
    rating: {
      type: Number,
      default: 0,
      min: 0,
      max: 5,
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform: (_doc, ret) => {
        ret.role = ret.accountRole;
        delete ret.password;
        delete ret.accountRole;
        delete ret.__v;
        return ret;
      },
    },
  },
);

caregiverSchema.index({ location: "2dsphere" });

caregiverSchema.pre("save", async function hashPassword(next) {
  if (!this.isModified("password")) {
    return next();
  }

  this.password = await bcrypt.hash(this.password, 12);
  next();
});

caregiverSchema.methods.comparePassword = function comparePassword(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model("Caregiver", caregiverSchema);
