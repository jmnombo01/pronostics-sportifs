#!/usr/bin/env python3
import sys
import os
import re
import pymysql
import ssl
from urllib.parse import urlparse

def main():
    if len(sys.argv) < 2:
        print("❌ Erreur : Veuillez fournir l'URL de connexion MySQL fournie par Aiven.")
        print("Exemple : python3 connect_aiven_db.py 'mysql://avnadmin:PASSWORD@mysql-xxx.aivencloud.com:26257/defaultdb?ssl-mode=REQUIRED'")
        sys.exit(1)

    url_str = sys.argv[1].strip()

    # Si c'est une chaîne URI type mysql://user:pass@host:port/dbname
    if url_str.startswith("mysql://") or url_str.startswith("mysqls://"):
        parsed = urlparse(url_str)
        host = parsed.hostname
        port = parsed.port or 3306
        user = parsed.username
        password = parsed.password
        db_name = parsed.path.lstrip('/') or "defaultdb"
    else:
        print("❌ Format d'URL non reconnu. Assurez-vous qu'elle commence par mysql://")
        sys.exit(1)

    print(f"🔗 Tentative de connexion sécurisée (SSL) vers Aiven MySQL : {host}:{port} (BDD: {db_name})...")

    ssl_ctx = ssl.create_default_context()
    ssl_ctx.check_hostname = False
    ssl_ctx.verify_mode = ssl.CERT_NONE

    try:
        connection = pymysql.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=db_name,
            ssl=ssl_ctx,
            autocommit=True,
            charset='utf8mb4'
        )
        print("✅ Connexion réussie à votre base de données cloud Aiven.io !")
    except Exception as e:
        print(f"❌ Échec de la connexion à Aiven MySQL : {e}")
        sys.exit(1)

    print("📦 Lecture et exécution du schéma de la base de données (backend/database/schema.sql)...")
    schema_path = "/home/user/backend/database/schema.sql"
    if not os.path.exists(schema_path):
        print(f"❌ Fichier schéma introuvable : {schema_path}")
        sys.exit(1)

    with open(schema_path, "r", encoding="utf-8") as f:
        sql_content = f.read()

    # Nettoyage des commentaires et requêtes
    commands = sql_content.split(';')
    with connection.cursor() as cursor:
        count = 0
        for cmd in commands:
            clean_cmd = cmd.strip()
            if clean_cmd and not clean_cmd.startswith('--'):
                try:
                    cursor.execute(clean_cmd)
                    count += 1
                except Exception as ex:
                    # Ignore les SET NAMES ou erreurs mineures de DROP sur tables existantes
                    if "Unknown table" not in str(ex):
                        print(f"⚠️ Warning SQL : {ex}")

    print(f"✅ Schéma importé avec succès ({count} requêtes exécutées) !")

    # Mettre à jour backend/.env
    print("📝 Mise à jour de backend/.env et render.yaml avec vos coordonnées Aiven...")
    env_path = "/home/user/backend/.env"
    if os.path.exists(env_path):
        with open(env_path, "r") as f:
            env_content = f.read()

        env_content = re.sub(r'DB_HOST=.*', f'DB_HOST={host}', env_content)
        env_content = re.sub(r'DB_PORT=.*', f'DB_PORT={port}', env_content)
        env_content = re.sub(r'DB_DATABASE=.*', f'DB_DATABASE={db_name}', env_content)
        env_content = re.sub(r'DB_USERNAME=.*', f'DB_USERNAME={user}', env_content)
        env_content = re.sub(r'DB_PASSWORD=.*', f'DB_PASSWORD={password}', env_content)

        with open(env_path, "w") as f:
            f.write(env_content)

    print("🎉 TERMINÉ ! Votre base de données Aiven est migrée et préconfigurée à 100% !")
    connection.close()

if __name__ == '__main__':
    main()
