const ApiError = require("../utils/ApiError");

const authorize = (...roles) => (req, _res, next) => {
  if (!req.auth) {
    return next(new ApiError(401, "Authentication required."));
  }

  if (!roles.includes(req.auth.accountRole)) {
    return next(new ApiError(403, "You do not have permission to perform this action."));
  }

  return next();
};

module.exports = {
  authorize,
};
