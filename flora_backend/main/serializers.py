# main/serializers.py
# NO CHANGES NEEDED HERE for the purchase links functionality
# based on how IdentifyPlantView.create is written.

from rest_framework import serializers
from .models import IdentifiedPlant

class IdentifiedPlantSerializer(serializers.ModelSerializer):
    class Meta:
        model = IdentifiedPlant
        # Ensure these fields match your model if you ever use the serializer directly
        fields = ['id', 'image', 'best_match_scientific_name', 'best_match_common_names', 'results', 'created_at']
        read_only_fields = ['id', 'created_at', 'best_match_scientific_name', 'best_match_common_names', 'results'] # Example: image is write, others read-only