#!/usr/bin/env python3
from PIL import Image
import os

# Configuración
source_image = r"C:\.MAROTO\Apps\AppFutCup2026\app\src\main\res\drawable\futcup2026_logo.png"
base_path = r"C:\.MAROTO\Apps\AppFutCup2026\app\src\main\res"

# Configuración de densidades: (carpeta, tamaño_en_px)
densities = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# Abrir imagen fuente
try:
    img = Image.open(source_image)
    print(f"✓ Imagen fuente cargada: {source_image}")
    print(f"  Tamaño original: {img.size}")
except Exception as e:
    print(f"✗ Error al cargar la imagen: {e}")
    exit(1)

# Generar versiones escaladas
for density, size in densities.items():
    # Crear carpeta si no existe
    target_dir = os.path.join(base_path, density)
    os.makedirs(target_dir, exist_ok=True)

    # Escalar imagen
    resized_img = img.resize((size, size), Image.Resampling.LANCZOS)

    # Guardar imagen
    target_path = os.path.join(target_dir, "futcup2026_logo.png")
    resized_img.save(target_path, "PNG")
    print(f"✓ Generado: {density} ({size}x{size}px) → {target_path}")

print("\n✓ ¡Iconos generados correctamente!")

