from rest_framework import viewsets
from .models import Recipe
from django.contrib.auth.models import User
from falatok.permissions import IsUserReadOnly
from rest_framework import permissions

from falatok.serializers import RecipeSerializer, UserSerializer


class RecipeViewSet(viewsets.ModelViewSet):
    queryset = Recipe.objects.all()
    serializer_class = RecipeSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsUserReadOnly]

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class UserViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
