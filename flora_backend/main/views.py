import requests
from django.conf import settings
from rest_framework.views import APIView
from rest_framework import viewsets 
from rest_framework.response import Response
from rest_framework import status
from .models import IdentifiedPlant
from .serializers import IdentifiedPlantSerializer

# If using APIView, use this class
# class IdentifyPlantView(APIView):
#     def post(self, request, *args, **kwargs):

# If using ViewSets, use this class
class IdentifyPlantView(viewsets.ModelViewSet):
    queryset = IdentifiedPlant.objects.all()
    serializer_class = IdentifiedPlantSerializer

    def create(self, request, *args, **kwargs):
        uploaded_image = request.FILES.get('image')
        if not uploaded_image:
            return Response({"error": "No image provided"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            plant = IdentifiedPlant(image=uploaded_image)
            plant.save()

            url = "https://my-api.plantnet.org/v2/identify/all"
            api_key = settings.PLANTNET_API_KEY

            with open(plant.image.path, "rb") as image_file:
                files = {"images": image_file}
                params = {"api-key": api_key}

                response = requests.post(url, files=files, params=params)

                if response.status_code == 200:
                    plantnet_data = response.json()

                    best_match = plantnet_data.get('bestMatch')
                    results = plantnet_data.get('results', [])

                    extracted_results = []

                    for result in results:
                        species_data = result.get('species', {})
                        common_names = species_data.get('commonNames', [])
                        scientific_name = species_data.get('scientificName')
                        score = result.get('score')

                        extracted_result = {
                            'scientific_name': scientific_name,
                            'common_names': common_names,
                            'score': score
                        }
                        extracted_results.append(extracted_result)

                    plant.results = {
                        'best_match': best_match,
                        'results': extracted_results
                    }

                    if best_match:
                        plant.best_match_scientific_name = best_match
                        best_match_data = next((res for res in results if res['species']['scientificName'] == best_match), None)
                        if best_match_data:
                            plant.best_match_common_names = ", ".join(best_match_data['species'].get('commonNames', []))

                    plant.save()
                    serializer = IdentifiedPlantSerializer(plant)
                    return Response(serializer.data, status=status.HTTP_200_OK)

                elif response.status_code == 400:
                    try:
                        error_data = response.json()
                        error_message = error_data.get('message', response.text)
                    except ValueError:
                        error_message = response.text
                    return Response({"error": "Bad Request to PlantNet API", "details": error_message}, status=status.HTTP_400_BAD_REQUEST)
                # ... (other error handling)

        except requests.exceptions.RequestException as e:
            return Response({"error": "Network error"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        except Exception as e:
            return Response({"error": "An unexpected error occurred"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)