from .views import *
from django.urls import path
from rest_framework import routers
from .health import health

router = routers.DefaultRouter()
router.register('users', UserViewSet, 'users')

urlpatterns = [
	path('health/', health),
] + router.urls