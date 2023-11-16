from django.urls import include, path, re_path
from rest_framework.routers import DefaultRouter

from falatok import views

router = DefaultRouter()
router.register(r"recipes", views.RecipeViewSet)
router.register(r"users", views.UserViewSet)

urlpatterns = [
  path("api/falatok/", include(router.urls)),
  # https://fractalideas.com/blog/making-react-and-django-play-well-together-hybrid-app-model/
  re_path('', views.catchall),
]
