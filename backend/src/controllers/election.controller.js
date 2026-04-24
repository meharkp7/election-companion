const { getElectionByState, getAllActiveElections } = require('../services/election.service');

const getElectionInfo = async (req, res, next) => {
  try {
    const { state } = req.query;
    const election = state ? await getElectionByState(state) : await getAllActiveElections();
    res.json({ election });
  } catch (err) {
    next(err);
  }
};

module.exports = { getElectionInfo };