#!/bin/bash

DIR=$(cd "$(dirname "$0")" && pwd) # répertoire du script
LOG="$DIR/logs/audit.log"
DATE=$(date '+%Y-%m-%d_%H-%M-%S')
RAPPORT="$DIR/reports/audit_$DATE.txt"

# Compteurs pour les tests réussis et échoués
NB_OK=0
NB_ERREUR=0
VERT='\e[32m'
ROUGE='\e[31m'
BLEU='\e[34m'
RESET='\e[0m'

# Bannière ASCII en vert "hacker" avec l'aide à droite (écran uniquement)
afficher_logo() {
    local lignes=(
    '    _   _   _ ____ ___ _____'
    '   / \ | | | |  _ \_ _|_   _|'
    '  / _ \| | | | | | | |  | |'
    ' / ___ \ |_| | |_| | |  | |'
    '/_/   \_\___/|____/___| |_|'
    ' _     ___ _   _ _   ___  __'
    '| |   |_ _| \ | | | | \ \/ /'
    '| |    | ||  \| | | | |\  / '
    '| |___ | || |\  | |_| |/  \ '
    '|_____|___|_| \_|\___//_/\_\'
)

    # Récupère l'aide ligne par ligne, avec une ligne vide devant
    local aide
    mapfile -t aide < <(afficher_aide)
    aide=("" "${aide[@]}")

    local i
    echo
    for i in "${!lignes[@]}"; do
        printf "$VERT%-38s$RESET %s\n" "${lignes[$i]}" "${aide[$i]}"
    done
    printf "$VERT── Audit système · réseau · sécurité ──$RESET\n"
    echo
}

# Affiche la liste des option
afficher_aide(){
    echo "Usage : $0 OPTION"
    echo "--system       audit du système"
    echo "--network      tests réseau"
    echo "--security     contrôles de sécurité"
    echo "--all          les trois audits"
    echo "--help         cette aide"
    echo "--interactive  mode interactif"
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
}

# Fonction Audit réseau
audit_reseau() {
    echo "[2] Test réseau">> "$RAPPORT"
    while read -r cible; do
        if [ -z "$cible" ] || [ "${cible:0:1}" = "#" ]; then
            continue 
        fi
        # Test de ping pour chaque cible
        if ping -c 1 -W 1 "$cible" > /dev/null 2>&1; then
            echo "[OK] $cible répond" >> "$RAPPORT"
            echo -e "${VERT}[OK]${RESET} $cible répond"
            NB_OK=$((NB_OK + 1))
        else
            echo -e "[ERREUR] $cible ne répond pas" >> "$RAPPORT"
            echo -e "${ROUGE}[ERREUR]${RESET} $cible ne répond pas"
            NB_ERREUR=$((NB_ERREUR + 1))
        fi

        # Test 2 : port 22 (SSH)
        if nc -z -w 1 "$cible" 22 > /dev/null 2>&1 < /dev/null; then
            echo "[OK] $cible : port 22 ouvert" >> "$RAPPORT"
            echo -e "${VERT}[OK]${RESET} $cible : port 22 ouvert"
            NB_OK=$((NB_OK + 1))
        else
            echo "[ERREUR] $cible : port 22 fermé ou inaccessible" >> "$RAPPORT"
            echo -e "${ROUGE}[ERREUR]${RESET} $cible : port 22 fermé ou inaccessible"
            NB_ERREUR=$((NB_ERREUR + 1))
        fi
    done < "$DIR/config/targets.conf"  
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
}
# Fonction pour journaliser les messages dans le fichier de log
journaliser() {
    echo "[$(date '+%F %T')] $1" >> "$LOG"
}

# Fonction résumé
ecrire_resume() {
    {
        echo "[4] Résumé"
        echo "Tests OK : $NB_OK"
        echo "Tests en échec : $NB_ERREUR"
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
#Option interactive
option_interactive() {
    local choix
    afficher_logo
    while true; do
        echo
        echo -e "${VERT} ------------------------${RESET}"
        echo -e "${VERT}|===== MENU D'AUDIT =====|${RESET}"
        echo -e "${VERT} ------------------------${RESET}"
        echo -e "${VERT}[1] Système${RESET}"
        echo -e "${VERT}[2] Réseau${RESET}"
        echo -e "${VERT}[3] Sécurité${RESET}"
        echo -e "${VERT}[4] Tout (les 3 audits)${RESET}"
        echo -e "${VERT}[5] Quitter${RESET}"
        read -r -p "Votre choix [1-5] : " choix
        case "$choix" in
            1) ecrire_entete; audit_systeme; journaliser "Audit système terminé";echo "Rapport créé : reports/$(basename "$RAPPORT")" ;;
            2) ecrire_entete; audit_reseau; journaliser "Audit réseau terminé";echo "Rapport créé : reports/$(basename "$RAPPORT")" ;;
            3) ecrire_entete; audit_securite; journaliser "Audit de sécurité terminé";echo "Rapport créé : reports/$(basename "$RAPPORT")" ;;
            4) ecrire_entete;  audit_systeme ; audit_reseau ; audit_securite ; ecrire_resume; archiver_rapport; journaliser "Audit --all terminé";generer_html;;
            5) echo "Au revoir !!!"; break ;;
            *) echo -e "${ROUGE}[ERREUR]${RESET} Choix invalide : '$choix'";;
        esac
    done
}
# Génère une version HTML du rapport texte
generer_html() {
    local html="${RAPPORT%.txt}.html"
    {
        echo '<html><head><meta charset="UTF-8"></head><body><pre>'
        cat "$RAPPORT"
        echo '</pre></body></html>'
    } > "$html"
    echo "Rapport HTML : reports/$(basename "$html")"
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
                    audit_systeme 
                    journaliser "Audit système terminé"
                    echo "Rapport créé : reports/$(basename "$RAPPORT")";;
        --network)  
                    ecrire_entete 
                    audit_reseau  
                    journaliser "Audit réseau terminé"
                    echo "Rapport créé : reports/$(basename "$RAPPORT")";;
        
        --security) ecrire_entete 
                    audit_securite 
                    journaliser "Audit de sécurité terminé"
                    echo "Rapport créé : reports/$(basename "$RAPPORT")";;

        --interactive) option_interactive;;       

        --all)       
                    ecrire_entete 
                    audit_systeme ; audit_reseau ; audit_securite ; archiver_rapport; ecrire_resume;  journaliser "Audit $1 terminé";generer_html
                    echo "Rapport créé : reports/$(basename "$RAPPORT")";;       
                    
        --help)      
                    afficher_aide ;;
        *)           
            echo "Option inconue : $1"
            afficher_aide
            exit 1;;
    esac