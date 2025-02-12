from django.contrib import admin
from .models import IdentifiedPlant

@admin.register(IdentifiedPlant)
class IdentifiedPlantAdmin(admin.ModelAdmin):
    list_display = ['id', 'created_at']