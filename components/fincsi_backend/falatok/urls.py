from django.urls import include, path
from rest_framework.routers import DefaultRouter

from falatok import views

router = DefaultRouter()
router.register(f"api/recipes", views.RecipeViewSet)
router.register(f"api/users", views.UserViewSet)

urlpatterns = [ path("", include(router.urls)) ]
