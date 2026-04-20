const config = require('./config/config')
const debug = require('debug')('ulendo:app')

process.env.NODE_ENV = config.development_mode ? 'development' : 'production'

const express = require('express')
const app = express()

const http = require('http').Server(app)
const bodyParser = require('body-parser')
const cors = require('cors')
const path = require('path')
const fileUpload = require("express-fileupload")

console.log(config)

const allowedOrigins = new Set(config.cors_origin)
const corsOptions = {
  origin: (origin, callback) => {
    // Allow same-origin/non-browser requests with no Origin header.
    if (!origin) {
      return callback(null, true)
    }

    // Explicit allow list from config.
    if (allowedOrigins.has(origin)) {
      return callback(null, true)
    }

    // Allow localhost/127.0.0.1 on any port during development.
    if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) {
      return callback(null, true)
    }

    return callback(new Error('CORS origin not allowed'))
  },
  credentials: true,
  methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-access-token'],
  optionsSuccessStatus: 200 // some legacy browsers (IE11, various SmartTVs) choke on 204
}

debug('Starting ulendo api server.')

//app.set('trust proxy', true)
app.use(cors(corsOptions))
app.options('*', cors(corsOptions))
app.use(bodyParser.json())
app.use(fileUpload())

app.use(express.static('public'))

app.use((req, res, next) => {
  let dString = req.method + ' ' + req.baseUrl + req.path
  if (req.query) {
    dString += ' Qry: ' + JSON.stringify(req.query)
  }
  if (req.form) {
    dString += ' Frm: ' + JSON.stringify(req.form)
  }  
  debug(dString)

  next()
})

require('./routes')(app)

http.listen(config.port)

debug(`Ulendo api server started on ${config.port}. Development mode: ${config.development_mode}`)
