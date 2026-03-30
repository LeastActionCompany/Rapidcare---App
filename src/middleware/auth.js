const Admin = require("../models/Admin");
const Caregiver = require("../models/Caregiver");
const User = require("../models/User");
const ApiError = require("../utils/ApiError");
const { ACCOUNT_MODEL_BY_ROLE } = require("../utils/constants");
const { verifyToken } = require("../services/tokenService");

const modelMap = {
  User,
  Caregiver,
  Admin,
};

const authenticate = async (req, _res, next) => {
  try {
    const authorization = req.headers.authorization;

    if (!authorization || !authorization.startsWith("Bearer ")) {
      throw new ApiError(401, "Authorization token is required.");
    }

    const token = authorization.split(" ")[1];
    const decoded = verifyToken(token);
    const modelName = ACCOUNT_MODEL_BY_ROLE[decoded.role];

    if (!modelName) {
      throw new ApiError(401, "Invalid authentication role.");
    }

    const account = await modelMap[modelName].findById(decoded.sub);

    if (!account) {
      throw new ApiError(401, "Account no longer exists.");
    }

    req.auth = {
      accountId: account._id,
      accountRole: decoded.role,
      modelName,
    };
    req.account = account;

    next();
  } catch (error) {
    next(error);
  }
};

module.exports = {
  authenticate,
};
