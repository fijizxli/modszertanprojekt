from rest_framework import viewsets
from .models import Recipe
from django.contrib.auth.models import User
from falatok.permissions import IsUserReadOnly
from rest_framework import permissions
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter

from falatok.serializers import RecipeSerializer, UserSerializer


# https://fractalideas.com/blog/making-react-and-django-play-well-together-hybrid-app-model/
from django.views.generic import TemplateView
catchall_prod = TemplateView.as_view(template_name='index.html')
import urllib.request
from django.conf import settings
from django.http import HttpResponse
from django.template import engines

import logging

def catchall_dev(request):
  upstream = settings.REACT_DEV_SERVER_URL
  upstream_url = upstream + request.path
  #import code
  #code.interact(local=globals())
  req = urllib.request.Request(upstream_url)
  req.add_header("Accept", "*/*") # The dev server gives 404 without this for some reason
  with urllib.request.urlopen(req) as response:
    content_type = response.headers.get('Content-Type')

    if content_type.startswith('text/html'):
      response_text = response.read().decode()
      content = engines['django'].from_string(response_text).render()
    else:
      content = response.read()

    return HttpResponse(
      content,
      content_type=content_type,
      status=response.status,
      reason=response.reason)

catchall = catchall_dev if settings.DEBUG else catchall_prod

class RecipeViewSet(viewsets.ModelViewSet):
    queryset = Recipe.objects.all()
    serializer_class = RecipeSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsUserReadOnly]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ["title", "cooking_time", "owner"]
    search_fields = ["title"]
    ordering_fields = ["title", "owner"]
    ordering = ["title"]

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class UserViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
