const express = require("express");
const { body, param } = require("express-validator");

const emergencyController = require("../controllers/emergencyController");
const { authenticate } = require("../middleware/auth");
const { authorize } = require("../middleware/rbac");
const { validate } = require("../middleware/validate");
const { ROLES } = require("../utils/constants");

const router = express.Router();

router.post(
  "/sos",
  authenticate,
  authorize(ROLES.USER),
  [
    body("location.type").optional().equals("Point"),
    body("location.coordinates").optional().isArray({ min: 2, max: 2 }),
    body("location.coordinates.*").optional().isFloat(),
    validate,
  ],
  emergencyController.triggerSos,
);

router.get(
  "/:id",
  authenticate,
  [param("id").isMongoId(), validate],
  emergencyController.getEmergencyById,
);

router.put(
  "/accept",
  authenticate,
  authorize(ROLES.CAREGIVER),
  [body("emergencyId").isMongoId(), validate],
  emergencyController.acceptEmergency,
);

router.put(
  "/reject",
  authenticate,
  authorize(ROLES.USER, ROLES.CAREGIVER, ROLES.ADMIN),
  [body("emergencyId").isMongoId(), validate],
  emergencyController.rejectEmergency,
);

router.put(
  "/complete",
  authenticate,
  authorize(ROLES.CAREGIVER, ROLES.ADMIN),
  [body("emergencyId").isMongoId(), validate],
  emergencyController.completeEmergency,
);

module.exports = router;
