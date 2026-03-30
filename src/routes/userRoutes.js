const express = require("express");
const { body } = require("express-validator");

const userController = require("../controllers/userController");
const { authenticate } = require("../middleware/auth");
const { authorize } = require("../middleware/rbac");
const { validate } = require("../middleware/validate");
const { ROLES } = require("../utils/constants");

const router = express.Router();

const locationValidation = [
  body("location.type").equals("Point"),
  body("location.coordinates").isArray({ min: 2, max: 2 }),
  body("location.coordinates.*").isFloat(),
];

router.post(
  "/register",
  [
    body("fullName").trim().notEmpty(),
    body("age").isInt({ min: 0, max: 130 }),
    body("gender").trim().notEmpty(),
    body("phone").trim().notEmpty(),
    body("email").isEmail().normalizeEmail(),
    body("password").isLength({ min: 8 }),
    ...locationValidation,
    body("medicalHistory.conditions").optional().isArray(),
    body("medicalHistory.medications").optional().isArray(),
    body("medicalHistory.allergies").optional().isArray(),
    body("emergencyContact.name").trim().notEmpty(),
    body("emergencyContact.phone").trim().notEmpty(),
    validate,
  ],
  userController.registerUser,
);

router.post(
  "/login",
  [
    body("email").isEmail().normalizeEmail(),
    body("password").notEmpty(),
    validate,
  ],
  userController.loginUser,
);

router.get(
  "/profile",
  authenticate,
  authorize(ROLES.USER),
  userController.getProfile,
);

router.put(
  "/profile",
  authenticate,
  authorize(ROLES.USER),
  [
    body("email").optional().isEmail().normalizeEmail(),
    body("age").optional().isInt({ min: 0, max: 130 }),
    body("password").optional().isLength({ min: 8 }),
    body("medicalHistory.conditions").optional().isArray(),
    body("medicalHistory.medications").optional().isArray(),
    body("medicalHistory.allergies").optional().isArray(),
    body("location.type").optional().equals("Point"),
    body("location.coordinates").optional().isArray({ min: 2, max: 2 }),
    body("location.coordinates.*").optional().isFloat(),
    validate,
  ],
  userController.updateProfile,
);

router.get(
  "/history",
  authenticate,
  authorize(ROLES.USER),
  userController.getEmergencyHistory,
);

module.exports = router;
