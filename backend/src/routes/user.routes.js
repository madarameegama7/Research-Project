const express = require("express");
const {
  registerUser,
  getCurrentUser,
} = require("../controllers/user.controller");
const verifyToken = require("../middleware/auth.middleware");
const authorizedRoles = require("../middleware/role.middleware");

const router = express.Router();

router.post("/register", registerUser); // called by client after Firebase signUp
router.get("/me", verifyToken, getCurrentUser);
router.get("/admin-only", verifyToken, authorizedRoles("admin"), (req, res) =>
  res.json({ ok: true })
);

module.exports = router;
