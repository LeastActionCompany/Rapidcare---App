const express = require("express");
const { body } = require("express-validator");

const caregiverController = require("../controllers/caregiverController");
const { authenticate } = require("../middleware/auth");
const { authorize } = require("../middleware/rbac");
const { validate } = require("../middleware/validate");
const { ROLES } = require("../utils/constants");

const router = express.Router();

router.post(
  "/register",
  [
    body("fullName").trim().notEmpty(),
    body("role").equals(ROLES.CAREGIVER),
    body("phone").trim().notEmpty(),
    body("email").isEmail().normalizeEmail(),
    body("password").isLength({ min: 8 }),
    body("location.type").equals("Point"),
    body("location.coordinates").isArray({ min: 2, max: 2 }),
    body("location.coordinates.*").isFloat(),
    body("documents").isArray({ min: 1 }),
    body("documents.*").isURL(),
    validate,
  ],
  caregiverController.registerCaregiver,
);

router.post(
  "/login",
  [
    body("email").isEmail().normalizeEmail(),
    body("password").notEmpty(),
    validate,
  ],
  caregiverController.loginCaregiver,
);

router.put(
  "/availability",
  authenticate,
  authorize(ROLES.CAREGIVER),
  [
    body("isAvailable").optional().isBoolean(),
    body("location.type").optional().equals("Point"),
    body("location.coordinates").optional().isArray({ min: 2, max: 2 }),
    body("location.coordinates.*").optional().isFloat(),
    validate,
  ],
  caregiverController.updateAvailability,
);

router.get(
  "/nearby-requests",
  authenticate,
  authorize(ROLES.CAREGIVER),
  caregiverController.getNearbyRequests,
);

router.get(
  "/profile",
  authenticate,
  authorize(ROLES.CAREGIVER),
  caregiverController.getProfile,
);

module.exports = router;
