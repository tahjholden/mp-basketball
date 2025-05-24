const { sanitizeString, sanitizePayload } = require('../scripts/sanitize');

test('sanitizeString removes braces and quotes', () => {
  const input = 'Jim "{Ho}use"';
  expect(sanitizeString(input)).toBe('Jim House');
});

test('sanitizePayload sanitizes nested values', () => {
  const input = { name: "O'Neal", tags: ['{A}', '"B"'] };
  const result = sanitizePayload(input);
  expect(result).toEqual({ name: 'ONeal', tags: ['A', 'B'] });
});
