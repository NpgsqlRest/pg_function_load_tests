from django.urls import path
from app.views import get_test_data, perf_minimal, perf_post, perf_nested, perf_large_payload, perf_many_params

urlpatterns = [
    path('api/perf-test', get_test_data),
    path('api/perf-minimal', perf_minimal),
    path('api/perf-post', perf_post),
    path('api/perf-nested', perf_nested),
    path('api/perf-large-payload', perf_large_payload),
    path('api/perf-many-params', perf_many_params),
]
