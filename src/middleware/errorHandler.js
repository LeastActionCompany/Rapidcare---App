const ApiError = require("../utils/ApiError");

const notFoundHandler = (req, _res, next) => {
  next(new ApiError(404, `Route not found: ${req.originalUrl}`));
};

const errorHandler = (error, _req, res, _next) => {
  const statusCode = error.statusCode || 500;
  const duplicateKeyError = error.code === 11000;

  if (duplicateKeyError) {
    return res.status(409).json({
      success: false,
      message: "A record with this unique field already exists.",
      details: error.keyValue,
    });
  }

  return res.status(statusCode).json({
    success: false,
    message: error.message || "Internal server error.",
    details: error.details || null,
    ...(process.env.NODE_ENV !== "production" && error.stack ? { stack: error.stack } : {}),
  });
};

module.exports = {
  notFoundHandler,
  errorHandler,
};
