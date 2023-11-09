from django.db import models
from django.conf import settings
from django.contrib.postgres.fields import ArrayField


class Recipe(models.Model):
    owner = models.ForeignKey(
        "auth.User", related_name="recipes", on_delete=models.CASCADE, null=False
    )
    title = models.CharField(max_length=80)
    ingredients = models.TextField(max_length=1000)
    description = models.TextField(max_length=1000)
    directions = models.TextField(max_length=1000)
    preparation_time = models.DurationField(blank=True, null=True)
    cooking_time = models.DurationField(blank=True, null=True)
    photo = models.ImageField(blank=True, null=True)

    guides = ArrayField(models.URLField(blank=True), blank=True, null=True)

    class Meta:
        ordering = ["owner", "title"]
