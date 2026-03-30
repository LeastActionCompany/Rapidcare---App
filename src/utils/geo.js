const ApiError = require("./ApiError");

const toPoint = (location) => {
  if (!location || location.type !== "Point" || !Array.isArray(location.coordinates)) {
    throw new ApiError(400, "Location must be valid GeoJSON Point data.");
  }

  const [lng, lat] = location.coordinates.map(Number);

  if (!Number.isFinite(lng) || !Number.isFinite(lat)) {
    throw new ApiError(400, "Location coordinates must be valid numbers.");
  }

  return {
    type: "Point",
    coordinates: [lng, lat],
  };
};

const calculateApproxDistanceMeters = ([lng1, lat1], [lng2, lat2]) => {
  const earthRadius = 6371e3;
  const toRadians = (value) => (value * Math.PI) / 180;
  const phi1 = toRadians(lat1);
  const phi2 = toRadians(lat2);
  const deltaPhi = toRadians(lat2 - lat1);
  const deltaLambda = toRadians(lng2 - lng1);

  const a =
    Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
    Math.cos(phi1) *
      Math.cos(phi2) *
      Math.sin(deltaLambda / 2) *
      Math.sin(deltaLambda / 2);

  return Math.round(earthRadius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
};

module.exports = {
  toPoint,
  calculateApproxDistanceMeters,
};
