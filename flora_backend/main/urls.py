from django.urls import path
from .views import IdentifyPlantView 

urlpatterns = [
    path('identify-plant/', IdentifyPlantView.as_view(), name='identify-plant'),
]