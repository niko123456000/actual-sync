// @actual-app/api expects navigator (browser global). Run before main.cjs via node --require.
(function () {
  if (typeof globalThis.navigator === 'undefined') {
    globalThis.navigator = { userAgent: 'Node' };
  }
})();
