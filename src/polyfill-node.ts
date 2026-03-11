/**
 * Run before any other app code. @actual-app/api may reference browser globals (e.g. navigator);
 * in Node / add-on we must polyfill them so the API loads without throwing.
 */
if (typeof globalThis.navigator === 'undefined') {
  ;(globalThis as { navigator?: { userAgent: string } }).navigator = {
    userAgent: 'Node',
  }
}
