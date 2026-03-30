const express = require("express");
const { body, param } = require("express-validator");

const adminController = require("../controllers/adminController");
const { authenticate } = require("../middleware/auth");
const { authorize } = require("../middleware/rbac");
const { validate } = require("../middleware/validate");
const { ROLES } = require("../utils/constants");

const router = express.Router();

router.post(
  "/login",
  [
    body("email").isEmail().normalizeEmail(),
    body("password").notEmpty(),
    validate,
  ],
  adminController.loginAdmin,
);

router.get("/users", authenticate, authorize(ROLES.ADMIN), adminController.getAllUsers);
router.get("/caregivers", authenticate, authorize(ROLES.ADMIN), adminController.getAllCaregivers);
router.get("/emergencies", authenticate, authorize(ROLES.ADMIN), adminController.getEmergencyLogs);

router.put(
  "/verify/:id",
  authenticate,
  authorize(ROLES.ADMIN),
  [param("id").isMongoId(), validate],
  adminController.verifyCaregiver,
);

router.delete(
  "/user/:id",
  authenticate,
  authorize(ROLES.ADMIN),
  [param("id").isMongoId(), validate],
  adminController.deleteUser,
);

router.delete(
  "/caregiver/:id",
  authenticate,
  authorize(ROLES.ADMIN),
  [param("id").isMongoId(), validate],
  adminController.deleteCaregiver,
);

module.exports = router;
