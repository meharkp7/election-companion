module.exports = {
  STATES: [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan',
    'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh',
    'Uttarakhand', 'West Bengal',
  ],
  ECI_PORTAL: 'https://voters.eci.gov.in',
  ELECTORAL_SEARCH: 'https://electoralsearch.eci.gov.in',
  READINESS_WEIGHTS: {
    eligible: 25,
    registered: 25,
    verified: 25,
    boothKnown: 15,
    votingDayReady: 10,
  },
};