# Audit d'une machine Linux

## 1. Présentation du projet

Ce projet a pour but de réaliser un audit d'une machine Linux à l'aide d'un script Bash `audit.sh`.

Le script `audit.sh` permet de collecter des informations sur le système, d'effectuer un audit réseau et un audit de sécurité.

Les résultats sont enregistrés dans un rapport daté. Chaque exécution est également tracée dans un journal et le rapport peut être archivé au format compressé `.tar.gz`.

## 2. Prérequis

- Une machine Linux disposant de Bash.
- Les commandes `uname`, `uptime`, `free`, `df`, `ps`, `grep`, `cut`, `ss`, `find` et `tar`.
- Le fichier de configuration `config/targets.conf`.
- Des droits de lecture sur les fichiers examinés.

## 3. Installation

Cloner le dépôt Git :

```bash
git clone https://github.com/prcx-mg23/audit-shell-project.git
cd audit-shell-project
```

Rendre le script exécutable :

```bash
chmod +x audit.sh
```

Vérifier la présence du fichier de configuration :

```bash
cat config/targets.conf
```

Si le fichier n'existe pas, le créer conformément à la configuration prévue par le projet.

## 4. Utilisation

Syntaxe générale :

```bash
./audit.sh OPTION
```

### Options disponibles

| Option | Description |
|---|---|
| `--system` | Collecte les informations système : noyau, durée de fonctionnement, mémoire, disque racine et processus les plus gourmands en CPU. |
| `--network` | Effectue les contrôles réseau prévus par le script. |
| `--security` | Recherche les comptes utilisant Bash, affiche les ports en écoute et repère les fichiers en permissions `777` dans le répertoire personnel. |
| `--all` | Exécute les trois audits. |
| `--help` | Affiche l'aide du script. |

### Exemples

Lancer uniquement l'audit système :

```bash
./audit.sh --system
```

Lancer l'audit réseau :

```bash
./audit.sh --network
```

Lancer l'audit de sécurité :

```bash
./audit.sh --security
```

Exécuter tous les audits :

```bash
./audit.sh --all
```

Afficher l'aide :

```bash
./audit.sh --help
```

## 5. Rapports, journaux et archives

Les résultats sont organisés dans trois répertoires :

- `reports/` : rapports d'audit datés au format texte.
- `logs/` : journal des exécutions dans `logs/audit.log`.
- `archives/` : archives compressées des rapports au format `.tar.gz`.

Afficher le rapport le plus récent :

```bash
cat "reports/$(ls -t reports/ | head -n 1)"
```

Consulter les dernières entrées du journal :

```bash
tail -n 10 logs/audit.log
```

Lister le contenu de la dernière archive :

```bash
tar -tzf "archives/$(ls -t archives/ | head -n 1)"
```

## 6. Exécution quotidienne du script avec cron

Pour lancer automatiquement tous les audits chaque jour à 8 h, la ligne suivante peut être ajoutée à une crontab :

```cron
0 8 * * * /chemin/audit-shell-project/audit.sh --all
```

**Important :** remplacer `/chemin/audit-shell-project/audit.sh` par le chemin absolu réel du script sur la machine.

Pour afficher le chemin absolu du projet :

```bash
pwd
```

La ligne cron est fournie à titre d'exemple. Elle n'est pas installée automatiquement.

## 7. Limites et précautions

- Les résultats correspondent à un état ponctuel de la machine au moment de l'audit.
- Un port en écoute, un compte utilisant Bash ou un fichier en permissions `777` est un indicateur à examiner, et non une preuve de vulnérabilité.
- Les messages d'erreur de certaines recherches de fichiers peuvent être masqués pour faciliter la lecture du rapport.
- Les contrôles dépendent des commandes disponibles et des permissions de l'utilisateur qui exécute le script.
- Les rapports et les archives peuvent contenir des informations sur la machine. Leur accès doit être protégé.
- Le script collecte des informations et ne doit pas modifier la configuration de la machine.
- Les résultats des contrôles réseau dépendent de la connectivité et des cibles configurées.

## 8. Tests

Les tests fonctionnels sont documentés dans le fichier [`tests.md`](tests.md). Ils vérifient notamment les options, les codes de retour, la génération des rapports, l'archivage et la gestion d'une configuration manquante.