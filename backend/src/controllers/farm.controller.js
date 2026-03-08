const FarmPlot = require('../models/farm.model');

// GET /api/farm/plots
const getPlots = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ message: 'Unauthorized' });

    const plots = await FarmPlot.find({ ownerUid: uid }).lean().exec();
    return res.json(plots);
  } catch (err) {
    console.error('getPlots error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// POST /api/farm/plots
const createPlot = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ message: 'Unauthorized' });

    const { name, crop, area } = req.body;
    if (!name) return res.status(400).json({ message: 'Name is required' });

    const plot = new FarmPlot({ ownerUid: uid, name, crop: crop || '', area: area || 0 });
    await plot.save();
    return res.status(201).json(plot);
  } catch (err) {
    console.error('createPlot error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// PUT /api/farm/plots/:id
const updatePlot = async (req, res) => {
  try {
    const uid = req.user?.uid;
    if (!uid) return res.status(401).json({ message: 'Unauthorized' });

    const { id } = req.params;
    const { name, crop, area } = req.body;
    const plot = await FarmPlot.findById(id).exec();
    if (!plot) return res.status(404).json({ message: 'Plot not found' });
    if (plot.ownerUid !== uid) return res.status(403).json({ message: 'Forbidden' });

    if (name !== undefined) plot.name = name;
    if (crop !== undefined) plot.crop = crop;
    if (area !== undefined) plot.area = area;

    await plot.save();
    return res.json(plot);
  } catch (err) {
    console.error('updatePlot error:', err);
    return res.status(500).json({ message: 'Server error', error: err.message });
  }
};

module.exports = { getPlots, createPlot, updatePlot };
