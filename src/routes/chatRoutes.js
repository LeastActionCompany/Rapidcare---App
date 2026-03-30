const express = require("express");
const { body, param } = require("express-validator");

const chatController = require("../controllers/chatController");
const { authenticate } = require("../middleware/auth");
const { authorize } = require("../middleware/rbac");
const { validate } = require("../middleware/validate");
const { ROLES } = require("../utils/constants");

const router = express.Router();

router.get(
  "/:emergencyId",
  authenticate,
  authorize(ROLES.USER, ROLES.CAREGIVER, ROLES.ADMIN),
  [param("emergencyId").isMongoId(), validate],
  chatController.getMessagesByEmergency,
);

router.post(
  "/send",
  authenticate,
  authorize(ROLES.USER, ROLES.CAREGIVER),
  [
    body("emergencyId").isMongoId(),
    body("message").trim().notEmpty().isLength({ max: 2000 }),
    validate,
  ],
  chatController.sendMessage,
);

module.exports = router;
