'use strict';

/**
 * Build a PDP prompt string from provided fields.
 * Required field: player_name.
 * Optional fields default to "None provided" if empty.
 * Throws if a required field is missing or empty.
 * @param {Object} data
 * @returns {string}
 */
function buildPdpPrompt(data) {
  if (!data || typeof data !== 'object') {
    throw new Error('Data object is required');
  }

  const required = ['player_name'];
  for (const key of required) {
    if (!data[key] || String(data[key]).trim() === '') {
      throw new Error(`Missing required field: ${key}`);
    }
  }

  const getField = (key) => {
    const val = data[key];
    if (val === undefined || val === null || String(val).trim() === '') {
      return 'None provided';
    }
    return String(val);
  };

  const joinedObservations = getField('joined_observations');
  const joinedTags = getField('joined_tags');
  const joinedConstraints = getField('joined_constraints');

  return [
    `Generate a detailed Player Development Plan (PDP) for ${data.player_name} using the following data:`,
    '',
    `- Observations: ${joinedObservations}`,
    `- Skill Tags: ${joinedTags}`,
    `- Constraint Tags: ${joinedConstraints}`,
  ].join('\n');
}

module.exports = { buildPdpPrompt };
