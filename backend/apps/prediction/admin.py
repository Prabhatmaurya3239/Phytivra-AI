from django.contrib import admin

from .models import LeafImage


@admin.register(LeafImage)
class LeafImageAdmin(admin.ModelAdmin):
    list_display = ('image', 'uploaded_at')
    readonly_fields = ('uploaded_at',)
    search_fields = ('image',)
