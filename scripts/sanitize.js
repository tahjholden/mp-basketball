function sanitizeString(str) {
  if (typeof str !== 'string') return str;
  return str.replace(/[{}"'`]/g, '');
}

function sanitizePayload(value) {
  if (Array.isArray(value)) {
    return value.map(sanitizePayload);
  }
  if (value && typeof value === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      out[k] = sanitizePayload(v);
    }
    return out;
  }
  return sanitizeString(value);
}

module.exports = { sanitizeString, sanitizePayload };
