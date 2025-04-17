# FLORA - Plant Identification App

FLORA is a modern plant identification application that allows users to identify plants from photos using computer vision and provides detailed botanical information. The application consists of a Flutter frontend and a Django backend that interfaces with PlantNet API for plant identification and GROQ AI for detailed plant information.

![FLORA App Logo](assets/icons/app_icon.png)

## Features

- **Plant Identification**: Upload or take photos of plants to get quick and accurate identification
- **Multiple Match Results**: View the most likely plant species and alternative matches with confidence scores
- **Detailed Information**: Access comprehensive plant details including:
  - Introduction to the plant species
  - Historical background and origins
  - Interesting botanical facts
  - Usage information (medicinal, ornamental, etc.)
- **Purchase Links**: Get direct links to online stores where you can buy seeds or plants of the identified species

## Tech Stack

### Frontend (Flutter)
- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **HTTP Client**: http package
- **Image Handling**: image_picker
- **Link Handling**: url_launcher

### Backend (Django)
- **Framework**: Django with Django REST Framework
- **Image Processing**: tempfile, shutil
- **External APIs**: 
  - PlantNet API for plant identification
  - GROQ AI API for detailed plant information
- **Database**: SQLite (development)

## Project Structure

```
FLORA/
├── flora_app/           # Frontend Flutter application
│   ├── lib/
│   │   ├── main.dart
│   │   └── screens/
│   │       ├── identify_plant_screen.dart
│   │       ├── response_screen.dart
│   │       └── plant_details_screen.dart
│   ├── assets/
│   └── pubspec.yaml
└── flora_backend/       # Backend Django application
    ├── flora_backend/   # Django project files
    ├── main/            # Django app for plant identification
    │   ├── models.py
    │   ├── views.py
    │   ├── serializers.py
    │   └── urls.py
    ├── manage.py
    └── requirements.txt
```

## Setup Instructions

### Prerequisites
- Python 3.9+ 
- Flutter SDK
- PlantNet API key
- GROQ API key

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd flora_backend
   ```

2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Create a `.env` file in the `flora_backend` directory:
   ```
   PLANTNET_API_KEY=your_plantnet_api_key
   GROQ_API_KEY=your_groq_api_key
   ```

5. Run migrations:
   ```bash
   python manage.py migrate
   ```

6. Start the development server:
   ```bash
   python manage.py runserver
   ```

### Frontend Setup

1. Navigate to the frontend directory:
   ```bash
   cd flora_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## API Endpoints

- **POST `/api/identify/`**: Upload an image for plant identification
  - Request: Multipart form with `image` field
  - Response: JSON with plant identification results

- **POST `/api/plant-details/`**: Get detailed information about a plant
  - Request: JSON with `plant_name` field
  - Response: JSON with introduction, history, facts, and usage information

## Application Flow

1. User opens the app and is presented with the option to take a photo or choose from gallery
2. After selecting/capturing an image, the app sends it to the backend for identification
3. The backend processes the image through PlantNet API and returns identification results
4. The app displays the top match and other possible matches with confidence scores
5. User can click "Know more about this plant" to get detailed information
6. The app requests additional information from the backend's GROQ integration
7. Detailed botanical information is displayed on a new screen

## Environment Variables

### Backend
- `PLANTNET_API_KEY`: API key for PlantNet plant identification service
- `GROQ_API_KEY`: API key for GROQ AI service

## Credits

- Plant identification powered by [PlantNet API](https://my.plantnet.org/)
- Detailed plant information powered by [GROQ AI](https://groq.com/)

## License

This project is licensed under the MIT License - see the LICENSE file for details.