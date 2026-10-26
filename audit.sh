#!/bin/bash


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
    echo "Audit système"
}

# Fonction Audit réseau
audit_reseau() {
    echo "Audit réseau"
}

# Fonction Audit de sécurité
audit_securite() {
    echo "Audit sécurité"
}

# Condition qui vérifie le nombre d'arguments
if [ "$#" -ne 1 ]; then
    afficher_aide
    exit 1
fi

# Traitement et choix de l'option
case "$1" in
    --system)    audit_systeme ;;
    --network)   audit_reseau  ;;
    --security)  audit_securite ;;
    --all)       audit_systeme ; audit_reseau ; audit_securite ;;
    --help)      afficher_aide ;;
    *)           
        
esac