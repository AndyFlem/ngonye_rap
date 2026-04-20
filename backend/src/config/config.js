const config = {
    port: 4001,
    cors_origin: ['http://localhost:4001', 'http://localhost:5174', 'http://localhost:5173','http://mphepo.ulendo.com','https://gis.westernpower.org'],
    development_mode: true,
    api_version: 'v1',
    auth_secret: 'kjsllwjksdflkjsd509kd_dks44AkfkA',
    auth_expiry: 24*60*60,
    db: {
        host: 'localhost',
        port:'5432',
        database: 'ngonye_rap',
        user: 'postgres',
        password: 'extramild20',
        schema: 'rap'
    },
}

module.exports = config