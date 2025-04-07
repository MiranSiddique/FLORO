from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from django.conf import settings
from django.conf.urls.static import static
from main.views import IdentifyPlantView, PlantDetailsView

router = DefaultRouter()
router.register(r'identify', IdentifyPlantView, basename='identify') 

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
    path('api/plant-details/', PlantDetailsView.as_view(), name='plant-details'),
    path('api-auth/', include('rest_framework.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)