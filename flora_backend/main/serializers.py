# serializers.py
from rest_framework import serializers
from .models import IdentifiedPlant

class IdentifiedPlantSerializer(serializers.ModelSerializer):
    class Meta:
        model = IdentifiedPlant
        fields = ['id', 'image', 'best_match_scientific_name', 'best_match_common_names', 'results', 'created_at'] # Include new fields