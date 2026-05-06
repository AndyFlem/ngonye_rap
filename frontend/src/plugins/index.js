/**
 * plugins/index.js
 *
 * Automatically included in `./src/main.js`
 */

// Plugins
import axiosPlugin from './axiosplugin'
import user from './user'

export function registerPlugins (app, options) {
  app
    .use(axiosPlugin, options)
    .use(user)

}
