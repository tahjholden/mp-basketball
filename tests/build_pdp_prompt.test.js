const { buildPdpPrompt } = require('../scripts/build_pdp_prompt');

describe('buildPdpPrompt', () => {
  test('fills missing optional fields with placeholder', () => {
    const result = buildPdpPrompt({ player_name: 'Cole', joined_tags: '' });
    expect(result).toContain('Observations: None provided');
    expect(result).toContain('Skill Tags: None provided');
    expect(result).toContain('Constraint Tags: None provided');
  });

  test('throws if required field is empty', () => {
    expect(() => buildPdpPrompt({})).toThrow('Missing required field: player_name');
  });
});
