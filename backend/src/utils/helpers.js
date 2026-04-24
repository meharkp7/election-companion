const isAgeEligible = (age) => age >= 18;

const getFormForIssue = (issueType) => {
  const map = {
    missing_name: 'Form 6',
    wrong_details: 'Form 8',
    transfer: 'Form 8A',
    deletion: 'Form 7',
  };
  return map[issueType] || 'Form 6';
};

const daysUntil = (date) => {
  const diff = new Date(date) - new Date();
  return Math.ceil(diff / (1000 * 60 * 60 * 24));
};

module.exports = { isAgeEligible, getFormForIssue, daysUntil };