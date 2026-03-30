const express = require("express");

const adminRoutes = require("./adminRoutes");
const caregiverRoutes = require("./caregiverRoutes");
const chatRoutes = require("./chatRoutes");
const emergencyRoutes = require("./emergencyRoutes");
const userRoutes = require("./userRoutes");

const router = express.Router();

router.use("/users", userRoutes);
router.use("/caregivers", caregiverRoutes);
router.use("/emergency", emergencyRoutes);
router.use("/chat", chatRoutes);
router.use("/admin", adminRoutes);

module.exports = router;
