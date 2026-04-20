
export default {
  development: {
    baseUrl: 'http://localhost:4001/api/v1/',
    baseUrlStatic: 'http://localhost:4001/',
    timeout: 5000
  },
  production: {
    baseUrl: 'https://maps.westernpower.org/api/v1/',
    baseUrlStatic: 'https://maps.westernpower.org/',
    timeout: 5000
  }
}
