function extractFences(text) {
  const re = /```[a-zA-Z0-9]*\r?\n([\s\S]*?)```/g;
  const blocks = [];
  let m;
  while ((m = re.exec(text)) !== null) blocks.push(m[1]);
  return blocks;
}

function largestBlock(text) {
  const blocks = extractFences(text);
  if (!blocks.length) return null;
  return blocks.reduce((a, b) => (b.length > a.length ? b : a));
}

function countLoc(code) {
  return code.split(/\r?\n/).filter((l) => l.trim().length > 0).length;
}

module.exports = { extractFences, largestBlock, countLoc };
