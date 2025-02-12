from django.db import models

class IdentifiedPlant(models.Model):
    image = models.ImageField(upload_to='plant_images/')
    best_match_scientific_name = models.CharField(max_length=255, blank=True, null=True)  # New field
    best_match_common_names = models.TextField(blank=True, null=True)  # New field
    results = models.JSONField(blank=True, null=True) # Store all results for future use
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Identified Plant {self.id}"