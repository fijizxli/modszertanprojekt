from rest_framework import serializers
from .models import Recipe
from django.contrib.auth.models import User

class RecipeSerializer(serializers.HyperlinkedModelSerializer):
    owner = serializers.ReadOnlyField(source='owner.username')
    recipe = serializers.HyperlinkedIdentityField(view_name='recipe-detail')
    class Meta:
        model = Recipe
        fields = [
            'id',
            'url',
            'recipe',
            'owner',
            'title',
            'ingredients',
            'description',
            'directions',
            'preparation_time',
            'cooking_time',
            'photo',
            'guides'
        ]

class UserSerializer(serializers.HyperlinkedModelSerializer):
    recipes = serializers.HyperlinkedRelatedField(many=True, view_name='recipe-detail', read_only=True)

    class Meta:
        model = User
        fields = ['id', 'url', 'username', 'recipes']
