import { reactive } from 'vue'

export default {

  install: (app) => {
    let _user = reactive({
      user_id: null,
      email: null,
      first_name: null,
      last_name: null,
      organisation: null,
      groups: ['public'],
      isAdmin: false
    })
    _user.hasGroup = (group) => {
      console.log('Checking group', group)
      return _user.groups.includes(group)
    }

    if (localStorage.user) {
      const u = JSON.parse(localStorage.user)
      _user.user_id = u.user_id
      _user.email = u.email
      _user.first_name = u.first_name
      _user.last_name = u.last_name
      _user.organisation = u.organisation
      app.axios.http.get('/current-user')
        .then(response => {
          console.log(response.data)
        })
        .catch(error => {
          console.error('Error fetching current user:', error)
          delete localStorage.csrf
          delete localStorage.user
        })
    }
    app.provide('user', _user)

    const signout = () => {
      delete localStorage.csrf
      delete localStorage.user
      _user.user_id = null
      _user.email = null
      _user.first_name = null
      _user.last_name = null
      _user.organisation = null
      _user.groups = ['public']
      _user.isAdmin = false
    }
    app.provide('signout', signout)
    app.config.globalProperties.$signout = signout

    const getGroups = () => {
      return app.axios.http.get('/usergroups/' + _user.user_id)
        .then(response => {
          const groups = response.data.map(v => v.usergroup_ref)
          groups.push('public')
          _user.groups = groups
          _user.isAdmin = groups.includes('admin')
          return groups
        })
    }
    app.provide('getGroups', getGroups)

    const signin = (username, password) => {
      return app.axios.http.post('/signin', { email: username, password: password })
        .then(response => {
          if (!response.data.csrf) {
            delete localStorage.csrf
            delete localStorage.user
            throw new Error('Login failed')
          }
          console.log('Logged in', response.data)
          localStorage.csrf = response.data.csrf
          return app.axios.http.get('/current-user')
        })
        .then(response => {
          const u = response.data
          _user.user_id = u.user_id
          _user.email = u.email
          _user.first_name = u.first_name
          _user.last_name = u.last_name
          _user.organisation = u.organisation

          localStorage.user = JSON.stringify(_user)

          // Fetch user groups
          return getGroups().then(() => _user)
        })
        .catch(error => {
          delete localStorage.csrf
          delete localStorage.user
          throw error
        })
    }
    app.provide('signin', signin)
  }
}

