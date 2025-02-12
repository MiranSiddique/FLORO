from django.urls import path
from .views import IdentifyPlantView # Import your new view

urlpatterns = [
    path('identify-plant/', IdentifyPlantView.as_view(), name='identify-plant'),
]