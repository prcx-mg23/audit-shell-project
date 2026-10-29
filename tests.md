# Tests du script d'audit Linux

| Test | Commande             | Résultat attendu | Résultat obtenu                   | Code de retour |
|------|----------------------|------------------|-----------------------------------|----------------|
| T1   | ./audit.sh           | aide, code 1     | Aide affichée, aucun rapport créé | 1              |
| T2   | ./audit.sh --toto    | « Option inconnue », code 1 | Option inconnue : --toto + aide | 1     |
| T3   | ./audit.sh --system  | rapport avec la section [1] | Rapport créé, section [1] présente, archive créée | 0 |
| T4   | ./audit.sh --network | un OK, un ERREUR | [OK] 127.0.0.1 répond et [ERREUR] 192.0.2.10 ne répond pas (la ligne vide et le commentaire sont ignorés) | 0 |
| T5   | ./audit.sh --all     | rapport complet + archive | Sections [1] à [4], archive ".tar.gz" contenant le rapport, journal complet. Affichage : Tests OK : 1 - Tests en échec : 1 | 0 |
| T6   | targets.conf renommé, puis ./audit.sh --system | message d'erreur, code 2 | Erreur : fichier .../config/targets.conf introuvable ou illisible | 2 |