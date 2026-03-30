const { validationResult } = require("express-validator");

const validate = (req, _res, next) => {
  const result = validationResult(req);

  if (result.isEmpty()) {
    return next();
  }

  return next({
    statusCode: 422,
    message: "Validation failed.",
    details: result.array(),
  });
};

module.exports = {
  validate,
};
