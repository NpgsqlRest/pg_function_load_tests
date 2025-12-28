from django.urls import path
from app.views import get_test_data

urlpatterns = [
    path('api/perf-test', get_test_data),
]
