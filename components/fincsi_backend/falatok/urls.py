from django.urls import include, path
from rest_framework.routers import DefaultRouter

from falatok import views

router = DefaultRouter()
router.register(r"recipes", views.RecipeViewSet)
router.register(r"users", views.UserViewSet)

urlpatterns = [path("", include(router.urls))]
