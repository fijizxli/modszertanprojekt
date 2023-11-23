from rest_framework.test import (
    APITestCase,
    APIRequestFactory,
    force_authenticate,
)

from django.conf import settings
from rest_framework import status
import random
from django.contrib.auth.models import User
from .models import Recipe
from datetime import timedelta
from .views import RecipeViewSet
import json as j
from django.test.client import encode_multipart
import io
from PIL import Image
from django.utils.encoding import force_bytes
