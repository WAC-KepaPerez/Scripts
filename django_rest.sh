#!/bin/bash

# Function to display loading message
function show_loading() {
    local pid=$1
    local delay=0.2
    local spin[0]="-"
    local spin[1]="/"
    local spin[2]="|"
    local spin[3]="\\"
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        echo -ne "\b${spin[i++ % ${#spin[@]}]}"
        sleep $delay
    done
}

# Create virtual environment
echo "Creating virtual environment..."
python -m venv venv &
show_loading $!

# Activate virtual environment
echo -e "\nActivating virtual environment..."
source venv/Scripts/activate

# Install Django
echo "Installing Dependencies..."
pip install django djangorestframework django-cors-headers

# Create Django project
read -p "Enter Django project name: " project_name
echo "Creating Django project '$project_name'..."
django-admin startproject $project_name

# Configure Django project
settings_file="$project_name/$project_name/settings.py"
if grep -q "rest_framework" "$settings_file"; then
    echo "Django REST Framework already installed."
else
    echo "Configuring Django project for Django REST Framework and CORS headers..."
    sed -i "s/'django.contrib.staticfiles',/'django.contrib.staticfiles',\n    'rest_framework',\n    'corsheaders',/" $settings_file
    echo -e "\n# CORS Settings\nCORS_ORIGIN_ALLOW_ALL = True\n" >> $settings_file
    echo "Django REST Framework and CORS headers configured."
fi

# Create Django app
read -p "Enter Django app name: " app_name
echo "Creating Django app '$app_name'..."
django-admin startapp $app_name

# Create urls.py file inside the app
echo "Creating urls.py file inside the app..."
touch $app_name/urls.py

# Add app's URLs to the main project's urls.py
echo "Adding app's URLs to the main project's urls.py..."
echo -e "\nfrom django.urls import path, include" >> $project_name/$project_name/urls.py
echo -e "urlpatterns = [\n    path('', include('$app_name.urls')),\n]" >> $project_name/$project_name/urls.py


# Add the endpoint to the app's urls.py
echo "Adding endpoint to the app's urls.py..."
echo -e "from django.urls import path\nfrom .views import HelloWorld\n\nurlpatterns = [\n    path('hello/', HelloWorld.as_view(), name='hello_world'),\n]" > $app_name/urls.py

# Add the view to the app's views.py
echo "Adding view to the app's views.py..."
echo -e "from rest_framework.views import APIView\nfrom rest_framework.response import Response\nfrom rest_framework import status\n\nclass HelloWorld(APIView):\n    def get(self, request):\n        return Response({\"message\": \"Hello, world!\"}, status=status.HTTP_200_OK)" > $app_name/views.py

# Move the app and the virtual environment inside the Django project directory
echo "Moving the app and the virtual environment inside the Django project directory..."
mv $app_name $project_name
mv venv $project_name

echo "Project creation completed successfully!"
echo "Now copy and run this:"
echo "cd $project_name"
echo "venv/Scripts/activate"
echo "python manage.py runserver"