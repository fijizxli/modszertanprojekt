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

    def testRecipePost(self):
        photo_file = self.generate_photo_file()

        view = RecipeViewSet.as_view({"post": "create"})

        data = {
            "title": "palacsinta :)",
            "ingredients": "tej",
            "description": "csinald meg",
            "directions": "ugyesen",
            "preparation_time": "01:13:03",
            "cooking_time": "02:00:32",
            "photo": photo_file,
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
        jresponse = j.loads(response.content)

        expresponse = {
            "owner": "testuser",
            "title": "palacsinta :)",
            "ingredients": "tej",
            "description": "csinald meg",
            "directions": "ugyesen",
            "preparation_time": "01:13:03",
            "cooking_time": "02:00:32",
            "photo": "http://testserver/media/" + photo_file.name,
            "guides": ["https://test.xd", "https://test2.xd"],
        }

        del jresponse["id"]
        del jresponse["url"]
        del jresponse["recipe"]

        self.assertEqual(jresponse, expresponse)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def testRecipeModel(self):
        self.assertEqual(Recipe.objects.get().title, "palacsinta :)")
        self.assertEqual(Recipe.objects.get().ingredients, "tej")
        self.assertEqual(Recipe.objects.get().description, "csinald meg")
        self.assertEqual(Recipe.objects.get().directions, "ugyesen")
        self.assertEqual(
            Recipe.objects.get().photo.name,
            Recipe.objects.get().photo.name,
        )
        self.assertEqual(
            Recipe.objects.get().preparation_time,
            timedelta(hours=1, minutes=13, seconds=3),
        )
        self.assertEqual(
            Recipe.objects.get().cooking_time, timedelta(hours=2, minutes=0, seconds=32)
        )

        self.assertEqual(
            Recipe.objects.get().guides,
            ["https://test.xd", "https://test2.xd"],
        )

