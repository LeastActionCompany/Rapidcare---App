const Admin = require("../models/Admin");

const ensureDefaultAdmin = async () => {
  const email = process.env.SEED_ADMIN_EMAIL;
  const password = process.env.SEED_ADMIN_PASSWORD;
  const fullName = process.env.SEED_ADMIN_NAME || "rapidCare Admin";

  if (!email || !password) {
    return;
  }

  const existingAdmin = await Admin.findOne({ email: email.toLowerCase() });

  if (existingAdmin) {
    return;
  }

  await Admin.create({
    fullName,
    email,
    password,
  });

  console.log(`Seeded default admin account for ${email}.`);
};

module.exports = {
  ensureDefaultAdmin,
};
