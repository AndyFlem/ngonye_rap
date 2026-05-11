const config = {
    port: 4040,
    cors_origin: ['http://localhost:5173','https://rap.westernpower.org'],
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
        schema: 'public'
    },
}

module.exports = config