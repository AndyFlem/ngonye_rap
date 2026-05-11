
export default {
  development: {
    baseUrl: 'http://localhost:4040/api/v1/',
    baseUrlStatic: 'http://localhost:4041/',
    timeout: 5000
  },
  production: {
    baseUrl: 'https://rap.westernpower.org/api/v1/',
    baseUrlStatic: 'https://rap.westernpower.org/',
    timeout: 5000
  }
}
