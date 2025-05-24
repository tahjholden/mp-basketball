// Example n8n Code node for inserting unmatched player names into flagged_entities
// Input item should have keys: unmatched_names (array), raw_note, category, raw_observation_id

const names = Array.isArray($json.unmatched_names) ? $json.unmatched_names : [];
const observationText = $json.raw_note || $json.observation_text || null;
const category = $json.category || 'player';
const rawObservationId = $json.raw_observation_id || null;

const outputs = names
  .filter(name => typeof name === 'string' && name.trim())
  .map(name => ({
    json: {
      category,
      raw_observation_id: rawObservationId,
      flagged_name: name.trim(),
      observation_text: observationText,
      flagged_at: new Date().toISOString(),
      attempted_match: null,
      resolved_entity_id: null,
      resolution_status: 'pending',
      resolved_by: null,
      resolved_at: null
    }
  }));

return outputs;
