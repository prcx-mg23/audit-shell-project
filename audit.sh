#!/bin/bash

DIR=$(cd "$(dirname "$0")" && pwd) # répertoire du script
LOG="$DIR/logs/audit.log"
DATE=$(date '+%Y-%m-%d_%H-%M-%S')
RAPPORT="$DIR/reports/audit_$DATE.txt"




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
    echo "Audit réseau"
}

# Fonction Audit de sécurité
audit_securite() {
    echo "Audit sécurité"
}

# Fonction pour journaliser les messages dans le fichier de log
journaliser() {
    echo "[$(date '+%F %T')] $1" >> "$LOG"
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
                journaliser 
                audit_systeme ;;
    --network)  
                ecrire_entete 
                journaliser 
                audit_reseau  ;;
    
    --security)  ecrire_entete 
                journaliser 
                audit_securite ;;
    --all)       
                ecrire_entete 
                journaliser 
                audit_systeme ; audit_reseau ; audit_securite ;;
    --help)      
                afficher_aide ;;
    *)           
        echo "Option inconue : $1"
        afficher_aide
        exit 1;;
esac


