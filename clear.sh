#!/bin/bash

# Evita errores si "nodes/*" no encuentra ningún directorio
shopt -s nullglob

DIR="$(pwd)"
STATEFUL_NODES=("researcher_node" ) # "nodes/*")

# 1. Recorremos los patrones del array (como textos)
for PATTERN in "${STATEFUL_NODES[@]}"; do
    
    # 2. Al concatenar "${DIR}/"$PATTERN (sin comillas en $PATTERN), 
    # Bash expande el asterisco a los directorios reales.
    for NODE_DIR in "${DIR}/"$PATTERN; do
        TARGETS=("${NODE_DIR}/data/netDb" "${NODE_DIR}/data/peerProfiles" "${NODE_DIR}/data/addressbook")
        
		for TARGET in "${TARGETS[@]}"; do
			if [ -d "$TARGET" ]; then
				echo "Limpiando: $TARGET"
				rm -rf "${TARGET}/"*
			else
				echo "No encontrado: $TARGET"
			fi
		done
    done

done
