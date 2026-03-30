const Admin = require("../models/Admin");
const Caregiver = require("../models/Caregiver");
const User = require("../models/User");
const ApiError = require("../utils/ApiError");

const models = [User, Caregiver, Admin];

const isExcludedDocument = (document, excludeModel, excludeId) =>
  Boolean(
    excludeModel &&
      excludeId &&
      document.collection.name === excludeModel.collection.collectionName &&
      document._id.toString() === excludeId.toString(),
  );

const assertUniqueIdentity = async ({ email, phone, excludeModel = null, excludeId = null }) => {
  const filters = [];

  if (email) {
    filters.push({ email: email.toLowerCase() });
  }

  if (phone) {
    filters.push({ phone });
  }

  if (!filters.length) {
    return;
  }

  const results = await Promise.all(models.map((model) => model.findOne({ $or: filters })));
  const conflict = results.find(
    (result) => result && !isExcludedDocument(result, excludeModel, excludeId),
  );

  if (!conflict) {
    return;
  }

  throw new ApiError(409, "An account with this email or phone already exists.");
};

module.exports = {
  assertUniqueIdentity,
};
