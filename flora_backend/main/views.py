# main/views.py

import os
import json
import time
import tempfile
import requests
import logging
import shutil
import urllib.parse  # <-- Import this
from django.conf import settings
from rest_framework import viewsets
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import IdentifiedPlant
from .serializers import IdentifiedPlantSerializer

# Set up logging
logger = logging.getLogger(__name__)


def safe_delete_file(file_path, max_attempts=3, delay=0.5):
    """Safely delete a file with multiple attempts in case of Windows file locking"""
    for attempt in range(max_attempts):
        try:
            if os.path.exists(file_path):
                os.remove(file_path)
                return True
        except Exception as e:
            logger.warning(f"Delete attempt {attempt+1} failed: {str(e)}")
            time.sleep(delay)
    return False


class IdentifyPlantView(viewsets.ModelViewSet):
    queryset = IdentifiedPlant.objects.all()
    serializer_class = IdentifiedPlantSerializer

    def create(self, request, *args, **kwargs):
        uploaded_image = request.FILES.get("image")
        if not uploaded_image:
            return Response(
                {"error": "No image provided"}, status=status.HTTP_400_BAD_REQUEST
            )

        # Create a temporary file outside Django's media system
        temp_dir = tempfile.mkdtemp()
        temp_file_path = os.path.join(temp_dir, "temp_plant_image.jpg")
        plant_instance = None # Initialize to None

        try:
            # Save the uploaded image to our temp file
            with open(temp_file_path, "wb") as f:
                for chunk in uploaded_image.chunks():
                    f.write(chunk)

            logger.info(f"Image saved temporarily at: {temp_file_path}")

            # Removed temporary plant instance creation here, as it's deleted anyway.
            # If you need it for other reasons, keep it, but ensure it's handled.

            # Call PlantNet API using our temp file
            url = "https://my-api.plantnet.org/v2/identify/all"
            api_key = settings.PLANTNET_API_KEY

            if not api_key:
                logger.error("PlantNet API key not found in settings")
                # Clean up temp file before returning error
                if os.path.exists(temp_dir):
                    shutil.rmtree(temp_dir, ignore_errors=True)
                return Response(
                    {"error": "PlantNet API key not configured"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )

            logger.info(f"Calling PlantNet API with image: {temp_file_path}")
            with open(temp_file_path, "rb") as image_file:
                files = {"images": image_file}
                params = {"api-key": api_key}
                response = requests.post(url, files=files, params=params)

                logger.info(f"PlantNet API response status: {response.status_code}")
                if response.status_code == 200:
                    plantnet_data = response.json()
                    logger.info("Successfully received PlantNet data")

                    # Extract PlantNet results
                    best_match_scientific = plantnet_data.get("bestMatch")
                    results = plantnet_data.get("results", [])

                    if not results:
                        logger.warning("No results found in PlantNet response")
                        return Response(
                            {"error": "No plant matches found"},
                            status=status.HTTP_404_NOT_FOUND,
                        )

                    extracted_results = []
                    first_result_common_names = []
                    first_result_scientific_name = None

                    for i, result in enumerate(results):
                        species_data = result.get("species", {})
                        common_names = species_data.get("commonNames", [])
                        scientific_name = species_data.get("scientificNameWithoutAuthor") # Often cleaner than scientificName
                        if not scientific_name:
                           scientific_name = species_data.get("scientificName") # Fallback
                        score = result.get("score")

                        if i == 0: # Store details of the top result
                            first_result_common_names = common_names
                            first_result_scientific_name = scientific_name

                        extracted_result = {
                            "scientific_name": scientific_name,
                            "common_names": common_names,
                            "score": score,
                        }
                        extracted_results.append(extracted_result)

                    # --- Determine the best name to use for search links ---
                    # Prioritize common name if available, otherwise use scientific name
                    plant_name_for_search = None
                    if first_result_common_names:
                        plant_name_for_search = first_result_common_names[0] # Use the first common name
                    elif best_match_scientific:
                         plant_name_for_search = best_match_scientific
                    elif first_result_scientific_name:
                        plant_name_for_search = first_result_scientific_name

                    if plant_name_for_search:
                        logger.info(f"Using '{plant_name_for_search}' for purchase links.")
                        # --- Generate Purchase Links ---
                        encoded_plant_name = urllib.parse.quote_plus(plant_name_for_search)
                        purchase_links = [
                            {
                                "site_name": "Google Shopping",
                                "url": f"https://www.google.com/search?tbm=shop&q={encoded_plant_name}"
                            },
                            {
                                "site_name": "Amazon",
                                "url": f"https://www.amazon.in/s?k={encoded_plant_name}"
                            },
                            {
                                "site_name": "Etsy",
                                "url": f"https://www.etsy.com/search?q={encoded_plant_name}"
                            },
                            # Add more sites if desired
                        ]
                        # --- End Generate Purchase Links ---
                    else:
                        logger.warning("Could not determine a suitable plant name for search links.")
                        purchase_links = [] # Return empty list if no name found


                    # Prepare response data
                    response_data = {
                        # Use the specific names identified above
                        "best_match_scientific_name": first_result_scientific_name or best_match_scientific,
                        "best_match_common_names": ", ".join(first_result_common_names),
                        "results": { # Keep the original structure if Flutter expects it
                            "best_match": best_match_scientific, # Keep original bestMatch if needed
                            "results": extracted_results,
                         },
                         "purchase_links": purchase_links # <-- Add the links here
                    }


                    return Response(response_data, status=status.HTTP_200_OK)

                else:
                    # Handle PlantNet API error
                    try:
                        error_data = response.json()
                        error_message = error_data.get("message", response.text)
                    except ValueError:
                        error_message = response.text

                    logger.error(f"PlantNet API error: {error_message}")
                    return Response(
                        {
                            "error": "Bad Request to PlantNet API",
                            "details": error_message,
                        },
                        status=status.HTTP_400_BAD_REQUEST,
                    )

        except requests.exceptions.RequestException as e:
            # Handle network errors
            logger.error(f"Network error: {str(e)}")
            return Response(
                {"error": f"Network error: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        except Exception as e:
            # Handle unexpected errors
            logger.error(f"Unexpected error: {str(e)}", exc_info=True)
            return Response(
                {"error": f"An unexpected error occurred: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        finally:
            # Clean up resources in finally block
            try:
                # Clean up the temp directory
                if os.path.exists(temp_dir):
                    shutil.rmtree(temp_dir, ignore_errors=True)
                    logger.info(f"Deleted temporary directory: {temp_dir}")
            except Exception as cleanup_error:
                logger.warning(f"Cleanup error (non-fatal): {str(cleanup_error)}")


class PlantDetailsView(APIView):
    """
    API endpoint for getting detailed information about a plant from GROQ
    (No changes needed in this view)
    """
    def post(self, request, format=None):
        # ... (keep existing code for PlantDetailsView) ...
        plant_name = request.data.get("plant_name")

        if not plant_name:
            return Response(
                {"error": "Plant name is required"}, status=status.HTTP_400_BAD_REQUEST
            )

        logger.info(f"Received request for plant details: {plant_name}")

        try:
            # Check for GROQ API key
            groq_api_key = settings.GROQ_API_KEY
            if not groq_api_key:
                logger.error("GROQ API key not found in settings")
                return Response(
                    {"error": "GROQ API key not configured"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )

            logger.info(f"Calling GROQ API for details about {plant_name}")
            from groq import Groq

            client = Groq(api_key=groq_api_key)

            completion = client.chat.completions.create(
                model="meta-llama/llama-4-scout-17b-16e-instruct",
                messages=[
                    {
                        "role": "system",
                        "content": "You are a plant instructor in an app called FLORA. You'll be provided with the name of a specific plant. Provide information in these categories: 'introduction' (brief overview), 'history' (origins and cultural significance), 'facts' (list of interesting facts as an array), and 'usage' (list of ways the plant is used as an array). Answer in JSON format only.",
                    },
                    {"role": "user", "content": f"Tell me about {plant_name}"},
                ],
                temperature=1,
                max_tokens=1024,
                top_p=1,
                response_format={"type": "json_object"},
            )

            groq_data = completion.choices[0].message.content
            logger.info("Successfully received GROQ data")

            # Parse the GROQ response to ensure it's valid JSON
            try:
                parsed_data = json.loads(groq_data)
                return Response(parsed_data, status=status.HTTP_200_OK)
            except json.JSONDecodeError:
                logger.error(f"Invalid JSON in GROQ response: {groq_data}")
                return Response(
                    {
                        "error": "Invalid response format from GROQ API",
                        "raw_response": groq_data,
                    },
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                )

        except Exception as e:
            logger.error(f"Error getting plant details: {str(e)}", exc_info=True)
            return Response(
                {"error": f"Failed to get plant details: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )