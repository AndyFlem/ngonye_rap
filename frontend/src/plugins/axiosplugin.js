import axios from 'axios'

export default {
  install: (app, options) => {

    const securedInstance = securedAxiosInstance(options)

    app.provide('axiosSecure', securedInstance)
    app.axios = {}
    app.axios.http = securedInstance

function securedAxiosInstance (options) {
  const securedInstance = axios.create({
    baseURL: options.config.baseUrl,
    withCredentials: true,
    timeout: options.config.timeout,
    headers: {'Content-Type': 'application/json'},
    responseType: 'json'
  })

  securedInstance.interceptors.request.use(request => {
    console.log('Starting Request', request.method, request.baseURL,request.url)
    return request
  })

  securedInstance.interceptors.request.use(config => {
    const method = config.method.toUpperCase()
    const token = localStorage.csrf

    if (method !== 'OPTIONS' && token) {
      config.headers = {
        ...config.headers,
        'x-access-token': token
      }
    }
    return config
  })

  securedInstance.interceptors.response.use(
    response => response,
    async error => {
    // Unauthorised
    if ((error.response && error.response.status === 401)) {
      console.log('401 Unauthorised', )
      app.config.globalProperties.$signout()
      // If not on the home page, redirect to home
      if (window.location.pathname !== '/') {
        window.location.href = '/'
      }
    } else {
      console.log('Error', error.status , error.message)
      throw error
    }
  }
  )

  securedInstance.defaults.raxConfig = {
    instance: securedInstance,
  }

  return securedInstance
}
  }
}
