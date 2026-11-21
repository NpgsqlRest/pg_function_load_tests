import os

SECRET_KEY = 'test-secret-key-not-for-production'
DEBUG = False
ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'django.contrib.contenttypes',
]

MIDDLEWARE = []

ROOT_URLCONF = 'app.urls'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME', 'testdb'),
        'USER': os.getenv('DB_USER', 'testuser'),
        'PASSWORD': os.getenv('DB_PASSWORD', 'testpass'),
        'HOST': os.getenv('DB_HOST', 'postgres'),
        'PORT': '5432',
        'OPTIONS': {
            # Pool is per gunicorn worker; workers x max_size ~= 100 aggregate
            # to match the single-pool services (psycopg_pool default max is only 4).
            'pool': {
                'min_size': 2,
                'max_size': int(os.getenv('POOL_MAX_SIZE', '12')),
            },
        },
    }
}

LOGGING = {
    'version': 1,
    'disable_existing_loggers': True,
    'handlers': {
        'null': {
            'class': 'logging.NullHandler',
        },
    },
    'root': {
        'handlers': ['null'],
        'level': 'CRITICAL',
    },
}

USE_TZ = True
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
