#!/bin/bash

DIR=$(cd "$(dirname "$0")" && pwd) # répertoire du script
LOG="$DIR/logs/audit.log"
DATE=$(date '+%Y-%m-%d_%H-%M-%S')
RAPPORT="$DIR/reports/audit_$DATE.txt"

# Compteurs pour les tests réussis et échoués
NB_TESTS_OK=0
NB_TESTS_ERREUR=0


# Affiche la liste des option
afficher_aide(){
    echo "Usage : $0 OPTION"
    echo "--system       audit du système"
    echo "--network      tests réseau"
    echo "--security     contrôles de sécurité"
    echo "--all          les trois audits"
    echo "--help         cette aide"
}

# Fonction Audit du système
audit_systeme() {
    {
        echo "[1] Informations système"
        echo "Noyau : $(uname -r)"
        echo "Démarrée : $(uptime -p)"
        echo
        echo "Mémoire :"
        free -h
        echo
        echo "Disque racine :"
        df -h /
        echo
        echo "Les 5 processus les plus gourmands :"
        ps aux --sort=-%cpu | head -n 6
        echo
    } >> "$RAPPORT"
    journaliser "Audit système terminé"
}

# Fonction Audit réseau
audit_reseau() {
    echo "[2] Test réseau">> "$RAPPORT"
    while read -r cible; do
    if [ -z "$cible" ] || [ "${cible:0:1}" = "#" ]; then
    continue # ligne vide ou commentaire
    fi
    if ping -c 1 -W 1 "$cible" > /dev/null 2>&1; then
    echo "[OK] $cible répond" >> "$RAPPORT"
    NB_TESTS_OK=$((NB_TESTS_OK + 1))
    else
    echo "[ERREUR] $cible ne répond pas" >> "$RAPPORT"
    NB_TESTS_ERREUR=$((NB_TESTS_ERREUR + 1))
    fi
    done < "$DIR/config/targets.conf"
    journaliser "Audit réseau terminé"
    
}

# Fonction Audit de sécurité
audit_securite() {
    {
        echo "[3] Analyse de sécurité"
        echo "Comptes avec un shell bash : "
        grep 'bash$' /etc/passwd | cut -d: -f1
        echo
        echo "Ports en écoute : "
        ss -tuln
        echo
        echo "Fichiers en mode 777 dans $HOME :"
        find "$HOME" -type f -perm 0777 2>/dev/null
        echo
        echo "(Indicateurs à examiner, pas une preuve de vulnérabilité)"
    } >> "$RAPPORT"
    journaliser "Audit de sécurité terminé" 
}
# Fonction pour journaliser les messages dans le fichier de log
journaliser() {
    echo "[$(date '+%F %T')] $1" >> "$LOG"
}

# Fonction résumé

ecrire_resume() {
    {
        echo "[4] Résumé"
        echo "Tests OK : $NB_TESTS_OK"
        echo "Tests en échec : $NB_TESTS_ERREUR"
    } >> "$RAPPORT"
}

# Fonction qui archive le rapport

archiver_rapport() {
    archive="$DIR/archives/audit_$DATE.tar.gz"
    tar -czf "$archive" -C "$DIR/reports" "$(basename "$RAPPORT")"
    journaliser "Archive créée : $(basename "$archive")"
}

# Fonction pour écrire l'en-tête du rapport d'audit
ecrire_entete() {
    {
    echo "RAPPORT D'AUDIT"
    echo "Date : $(date '+%F %T')"
    echo "Machine : $(hostname)"
    echo "Utilisateur : $(whoami)"
    echo
    } > "$RAPPORT"
}


#### MAIN ####
mkdir -p "$DIR/logs" "$DIR/reports" "$DIR/archives"

# Condition qui vérifie le nombre d'arguments
if [ "$#" -ne 1 ]; then
    afficher_aide
    exit 1
fi

if [ ! -r "$DIR/config/targets.conf" ]; then    
    echo "Fichier de configuration des cibles introuvable."
    exit 2;
fi


# Traitement et choix de l'option
case "$1" in
    --system)   ecrire_entete 
                audit_systeme ;;
    --network)  
                ecrire_entete 
                audit_reseau  ;;
    
    --security)  ecrire_entete 

                audit_securite ;;
    --all)       
                ecrire_entete 
                audit_systeme ; audit_reseau ; audit_securite ; archiver_rapport;;
         
                
    --help)      
                afficher_aide ;;
    *)           
        echo "Option inconue : $1"
        afficher_aide
        exit 1;;
esac

ecrire_resume

echo "Rapport créé : reports/$(basename "$RAPPORT")"
if [ "$1" = "--network" ] || [ "$1" = "--all" ]; then
    echo "Tests OK : $NB_TESTS_OK - Tests en échec : $NB_TESTS_ERREUR"
fi

