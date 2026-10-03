from django.core.management.base import BaseCommand

from apps.crops.models import Crop
from apps.disease.models import Disease
from apps.pesticides.models import Pesticide
from apps.recommendations.models import Recommendation


class Command(BaseCommand):
    help = "Populate the database with demo crop, disease, pesticide and recommendation data for local development."

    def handle(self, *args, **options):
        crop_seed = [
            {
                "name": "tomato",
                "scientific_name": "Solanum lycopersicum",
                "description": "A high-value vegetable crop often affected by fungal diseases during humid weather.",
            },
            {
                "name": "Potato",
                "scientific_name": "Solanum tuberosum",
                "description": "A major tuber crop that is vulnerable to late blight and early blight.",
            },
            {
                "name": "Rice",
                "scientific_name": "Oryza sativa",
                "description": "A staple cereal crop commonly affected by blast and brown spot diseases.",
            },
            {
                "name": "Maize",
                "scientific_name": "Zea mays",
                "description": "A major cereal crop used for food, feed and industrial processing.",
            },
            {
                "name": "wheat",
                "scientific_name": "Triticum aestivum",
                "description": "A major grain crop frequently affected by rust and fungal leaf diseases.",
            },
        ]

        for seed in crop_seed:
            crop, created = Crop.objects.get_or_create(
                name__iexact=seed["name"],
                defaults={
                    "scientific_name": seed["scientific_name"],
                    "description": seed["description"],
                },
            )
            if not created:
                crop.scientific_name = crop.scientific_name or seed["scientific_name"]
                crop.description = crop.description or seed["description"]
                crop.save(update_fields=["scientific_name", "description"])

        pesticide_seed = [
            {
                "name": "AgriNova",
                "company_name": "Demo Agri Solutions",
                "description": "Protective fungicide suitable for broad disease management in field crops.",
                "price_range": "₹400 - ₹700",
                "packing_size": "250 ml, 500 ml, 1 L",
                "dosage": "1 ml per litre of water",
                "spray_method": "Foliar spray on affected crop canopy",
                "precautions": "Use protective gloves and avoid exposure to skin and eyes.",
                "availability": True,
            },
            {
                "name": "Syngenta India",
                "company_name": "Syngenta India Ltd.",
                "description": "Broad-spectrum fungicide for controlling major fungal diseases in vegetables and cereals.",
                "price_range": "₹550 - ₹900",
                "packing_size": "200 ml, 500 ml, 1 L",
                "dosage": "1.5 ml per litre of water",
                "spray_method": "Foliar spray using knapsack sprayer",
                "precautions": "Follow label instructions and avoid drift in windy conditions.",
                "availability": True,
            },
            {
                "name": "Mancozeb",
                "company_name": "Demo Crop Care",
                "description": "A contact fungicide widely used to prevent fungal outbreaks in vegetables and cereals.",
                "price_range": "₹300 - ₹600",
                "packing_size": "500 g, 1 kg",
                "dosage": "2 g per litre of water",
                "spray_method": "Uniform foliar spray over the crop canopy",
                "precautions": "Keep away from children and livestock; wear gloves while spraying.",
                "availability": True,
            },
            {
                "name": "Copper Oxychloride",
                "company_name": "Demo Inputs Ltd.",
                "description": "A copper-based fungicide effective against fungal and bacterial disease outbreaks.",
                "price_range": "₹280 - ₹520",
                "packing_size": "250 g, 500 g, 1 kg",
                "dosage": "2.5 g per litre of water",
                "spray_method": "Wet spray on the infected foliage",
                "precautions": "Avoid mixing with alkaline pesticides and wash exposed skin immediately.",
                "availability": True,
            },
        ]

        pesticide_map = {}
        for seed in pesticide_seed:
            pesticide, created = Pesticide.objects.get_or_create(
                name=seed["name"],
                defaults={
                    "company_name": seed["company_name"],
                    "description": seed["description"],
                    "price_range": seed["price_range"],
                    "packing_size": seed["packing_size"],
                    "dosage": seed["dosage"],
                    "spray_method": seed["spray_method"],
                    "precautions": seed["precautions"],
                    "availability": seed["availability"],
                },
            )
            if not created:
                pesticide.company_name = pesticide.company_name or seed["company_name"]
                pesticide.description = pesticide.description or seed["description"]
                pesticide.price_range = pesticide.price_range or seed["price_range"]
                pesticide.packing_size = pesticide.packing_size or seed["packing_size"]
                pesticide.dosage = pesticide.dosage or seed["dosage"]
                pesticide.spray_method = pesticide.spray_method or seed["spray_method"]
                pesticide.precautions = pesticide.precautions or seed["precautions"]
                pesticide.availability = pesticide.availability if pesticide.availability is not None else seed["availability"]
                pesticide.save()
            pesticide_map[seed["name"]] = pesticide

        disease_seed = [
            {
                "crop": "tomato",
                "name": "Early Blight",
                "symptoms": "Dark concentric lesions, leaf yellowing and defoliation.",
                "causes": "Alternaria solani under warm and humid conditions.",
                "description": "A common fungal disease affecting tomato foliage and fruit quality.",
                "severity": "Medium",
                "recommended_pesticides": ["AgriNova", "Mancozeb"],
            },
            {
                "crop": "tomato",
                "name": "Late Blight",
                "symptoms": "Water-soaked lesions and rapid collapse of leaves and stems.",
                "causes": "Phytophthora infestans causing severe disease pressure in wet weather.",
                "description": "A highly destructive disease that can wipe out a tomato crop quickly.",
                "severity": "High",
                "recommended_pesticides": ["Syngenta India", "Copper Oxychloride"],
            },
            {
                "crop": "Rice",
                "name": "Brown Spot",
                "symptoms": "Brown spot lesions on older leaves with reduced tiller vigor.",
                "causes": "Caused by Bipolaris oryzae and favored by high humidity.",
                "description": "A widespread rice disease that reduces grain yield and quality.",
                "severity": "Medium",
                "recommended_pesticides": ["AgriNova", "Mancozeb"],
            },
            {
                "crop": "Potato",
                "name": "Potato Early Blight",
                "symptoms": "Target-like leaf lesions and rapid yellowing of older foliage.",
                "causes": "Alternaria solani stress under warm, humid conditions.",
                "description": "A frequent potato foliar disease that impacts yield potential.",
                "severity": "Medium",
                "recommended_pesticides": ["AgriNova", "Copper Oxychloride"],
            },
            {
                "crop": "Potato",
                "name": "Potato Late Blight",
                "symptoms": "Dark irregular lesions, stem infection and white sporulation in humid conditions.",
                "causes": "Phytophthora infestans infection in cool wet weather.",
                "description": "This disease is highly destructive and requires timely management.",
                "severity": "High",
                "recommended_pesticides": ["Syngenta India", "Mancozeb"],
            },
            {
                "crop": "Rice",
                "name": "Rice Blast",
                "symptoms": "Diamond-shaped lesions on leaves and neck blast in severe cases.",
                "causes": "Magnaporthe oryzae infection under high humidity and high nitrogen input.",
                "description": "A major rice disease affecting foliage and panicle health.",
                "severity": "High",
                "recommended_pesticides": ["Syngenta India", "AgriNova"],
            },
            {
                "crop": "wheat",
                "name": "Wheat Rust",
                "symptoms": "Orange-brown pustules on leaves and stems.",
                "causes": "Rust fungi spread rapidly under cool moist conditions.",
                "description": "A foliar disease that reduces the photosynthetic area of wheat.",
                "severity": "Medium",
                "recommended_pesticides": ["AgriNova", "Copper Oxychloride"],
            },
            {
                "crop": "Maize",
                "name": "Leaf Blight",
                "symptoms": "Long elliptical lesions on leaves with drying margins.",
                "causes": "Fungal infection favored by high moisture and warm conditions.",
                "description": "A damaging foliar disease affecting maize growth and grain filling.",
                "severity": "Medium",
                "recommended_pesticides": ["AgriNova", "Mancozeb"],
            },
        ]

        for seed in disease_seed:
            crop = Crop.objects.filter(name__iexact=seed["crop"]).first()
            if not crop:
                continue

            disease, created = Disease.objects.get_or_create(
                crop=crop,
                name__iexact=seed["name"],
                defaults={
                    "symptoms": seed["symptoms"],
                    "causes": seed["causes"],
                    "description": seed["description"],
                    "severity": seed["severity"],
                },
            )
            if not created:
                disease.symptoms = disease.symptoms or seed["symptoms"]
                disease.causes = disease.causes or seed["causes"]
                disease.description = disease.description or seed["description"]
                disease.severity = disease.severity or seed["severity"]
                disease.save(update_fields=["symptoms", "causes", "description", "severity"])

            selected_pesticides = [
                pesticide_map[pesticide_name]
                for pesticide_name in seed["recommended_pesticides"]
                if pesticide_name in pesticide_map
            ]
            if selected_pesticides:
                disease.recommended_pesticides.set(selected_pesticides)
                for pesticide in selected_pesticides:
                    Recommendation.objects.get_or_create(
                        disease=disease,
                        pesticide=pesticide,
                        defaults={
                            "dosage": pesticide.dosage,
                            "notes": "Demo recommendation for local development and testing.",
                        },
                    )

        self.stdout.write(
            self.style.SUCCESS(
                "Dummy development data is available for crops, diseases, pesticides and recommendations."
            )
        )
