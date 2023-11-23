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


class RecipeTestCase(APITestCase):
    def setUp(self):
        self.factory = APIRequestFactory()
        self.user = User.objects.create_user("testuser", "testmail@test.com", "test")
        self.photo_file = self.generate_photo_file()

        view = RecipeViewSet.as_view({"post": "create"})

        data = {
            "title": "palacsinta :)",
            "ingredients": "tej",
            "description": "csinald meg",
            "directions": "ugyesen",
            "preparation_time": "01:13:03",
            "cooking_time": "02:00:32",
            "photo": self.photo_file,
            "guides": ["https://test.xd", "https://test2.xd"],
        }

        content = encode_multipart("wyz", data)
        content_type = "multipart/form-data; boundary=wyz"

        request = self.factory.post(
            "/api/falatok/recipes/", content, content_type=content_type
        )
        force_authenticate(request, user=self.user)

        response = view(request)
        response.render()

    def generate_photo_file(self):
        pname = str(random.randint(100000000000, 999999999999))
        file = io.BytesIO()
        image = Image.new("RGBA", size=(10, 10), color=(155, 0, 0))
        image.save(file, "png")
        file.name = pname + ".png"
        file.seek(0)
        return file
