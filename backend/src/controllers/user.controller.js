const User = require("../models/user.models");

const registerUser = async (req, res) => {
  try {
    const { firebaseUid, email, firstName, lastName, contact, role } = req.body;
    let user = await User.findOne({ firebaseUid });
    if (user) return res.status(200).json({ message: "User exists", user });

    user = await User.create({
      firebaseUid,
      email,
      firstName,
      lastName,
      contact,
      role: "farmer",
    });
    res.status(201).json({ message: "User created", user });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

const getCurrentUser = async (req, res) => {
  try {
    const user = await User.findOne({ firebaseUid: req.user.uid });
    if (!user) return res.status(404).json({ message: "Not found" });
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

module.exports = { registerUser, getCurrentUser };
