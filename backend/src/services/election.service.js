const Election = require('../models/election.model');

const getElectionByState = async (state) => {
  return Election.findByState(state);
};

const getAllActiveElections = async () => {
  return Election.findAllActive();
};

const isElectionDay = async (state) => {
  if (!state) return false;
  const election = await getElectionByState(state);
  if (!election) return false;
  const today = new Date();
  const eDay = new Date(election.electionDate);
  return today.toDateString() === eDay.toDateString();
};

module.exports = { getElectionByState, getAllActiveElections, isElectionDay };