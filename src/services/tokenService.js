const jwt = require("jsonwebtoken");

const ApiError = require("../utils/ApiError");

const signToken = ({ accountId, accountRole }) => {
  const secret = process.env.JWT_SECRET;

  if (!secret) {
    throw new ApiError(500, "JWT_SECRET is not configured.");
  }

  return jwt.sign(
    {
      sub: accountId,
      role: accountRole,
    },
    secret,
    {
      expiresIn: process.env.JWT_EXPIRES_IN || "7d",
    },
  );
};

const verifyToken = (token) => {
  const secret = process.env.JWT_SECRET;

  if (!secret) {
    throw new ApiError(500, "JWT_SECRET is not configured.");
  }

  return jwt.verify(token, secret);
};

module.exports = {
  signToken,
  verifyToken,
};
