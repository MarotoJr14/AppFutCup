"""
Script para crear usuarios de prueba en la base de datos.
Ubicación: backend/scripts/seed_users.py
"""

import sys
import os

# Añadir el directorio raíz del backend al path
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from app.db.session import SessionLocal
from app.repositories.user_repository import UserRepository
from app.schemas.user_schema import UserCreate
from app.models.enums import UserRole

USERS = [
    {
        "username": "futcup_admin",
        "email": "futcup.admin@pro2fp.es",
        "password": "Admin1234!",
        "role": UserRole.admin,
    },
    {
        "username": "futcup_org",
        "email": "futcup.org@pro2fp.es",
        "password": "Org1234!",
        "role": UserRole.org,
    },
    {
        "username": "futcup_user",
        "email": "futcup.user@pro2fp.es",
        "password": "User1234!",
        "role": UserRole.user,
    },
]

def seed():
    db = SessionLocal()
    repo = UserRepository(db)
    created = 0
    skipped = 0

    print("Iniciando seed de usuarios...\n")

    for u in USERS:
        existing = repo.get_by_email(u["email"])
        if existing:
            print(f"  [SKIP] {u['username']} — ya existe en la BD")
            skipped += 1
            continue

        user_data = UserCreate(
            username=u["username"],
            email=u["email"],
            password=u["password"],
            role=u["role"],
        )

        # Saltamos la validación de dominio y contraseña fuerte para el seed
        user = repo.create(user_data)
        print(f"  [OK]   {user.username} ({user.role.value}) creado con id={user.id}")
        created += 1

    db.close()
    print(f"\nResultado: {created} creados, {skipped} omitidos.")

if __name__ == "__main__":
    seed()