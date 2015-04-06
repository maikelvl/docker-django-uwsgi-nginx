"""
WSGI config for main project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/1.7/howto/deployment/wsgi/
"""

import os
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "main.settings.{}-docker".format(os.environ.get('APPLICATION_ENV', 'production')))

from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()
