#!/bin/bash

# FUNCIONES
function ctrl_c(){
        echo -e "\n\n [!] Saliendo... \n"
        tput cnorm && exit 1
}

trap ctrl_c INT

# VARIABLES GLOBALES
main_url="https://htbmachines.github.io/bundle.js"

function helpPanel(){
        echo -e "\n\n[+] Uso:"
        echo -e "\tm) [+] Buscar por un nombre de máquina"
	echo -e "\ti) [+] Buscar por IP de la máquina"
	echo -e "\ts) [+] Buscar por SO de la máquina"
	echo -e "\td) [+] Buscar por dificultad de la máquina"
        echo -e "\th) [+] Mostrar panel de ayuda"
        echo -e "\tu) [+] Descargar o actualizar máquinas"
	echo -e "\ty) [+] Sacar link de YouTube"
	echo -e "\ta) [+] Buscar por habilidad"

}


function searchMachine() {
    tput civis
    machineName="$1"
    machineNameChecker="$(awk -v name="$machineName" '$0 ~ "name: \""name"\"" , /resuelta:/ {print}' bundle.js | grep -vE "id|sku|resuelta" | tr -d '"' | tr -d ',' | sed 's/^ *//g')"
    
    if [ "$machineNameChecker" ]; then
        echo -e "\n[*] Listando propiedades de la máquina ... $machineName\n"
        awk -v name="$machineName" '$0 ~ "name: \""name"\"" , /resuelta:/ {print}' bundle.js | grep -vE "id|sku|resuelta" | tr -d '"' | tr -d ',' | sed 's/^ *//g'
    else
        echo -e "\n[!] La máquina $machineName no existe"
    fi
}

function searchIP() {
    ipAddress="$1"

    # Buscar nombre de la máquina asociado a la IP
    machineName=$(awk -v ip="$ipAddress" '
        $0 ~ "ip: \""ip"\"" { found=1 }
        found && /name: / {
            gsub(/"|,/, "", $0)
            print $NF
            exit
        }
    ' bundle.js)

    # Comprobación y salida
    if [ -n "$machineName" ]; then
        echo -e "\n[+] La IP $ipAddress es de la máquina:\n[-] $machineName"
        searchMachine "$machineName"
    else
        echo -e "\n[!] La IP $ipAddress no se asocia a ninguna máquina"
    fi
}


function getYTLink() {
    machineName="$1"

    # Buscar el link de YouTube asociado al nombre de la máquina
    videoLink=$(awk -v name="$machineName" '
        $0 ~ "name: \""name"\"" { found=1 }
        found && /youtube/ {
            gsub(/"|,/, "", $0)
            print $NF
            exit
        }
    ' bundle.js)

    # Verificar si se encontró el enlace
    if [ -n "$videoLink" ]; then
        echo -e "\n[+] El link de la máquina $machineName es:\n[-] $videoLink"
    else
        echo -e "\n[!] No se encontró ningún link de YouTube para la máquina \"$machineName\""
    fi
}


function searchMachineDifficult() {
    machineDifficult="$1"

    results=$(awk -v diff="$machineDifficult" '
        BEGIN { name = ""; ip = "" }
        /name: / { name = $0 }
        /ip: /   { ip = $0 }
        $0 ~ "dificultad: \""diff"\"" {
            if (name != "" && ip != "") {
                gsub(/"|,/, "", name)
                gsub(/"|,/, "", ip)
                split(name, nameParts, ": ")
                split(ip, ipParts, ": ")
                printf "%s\t%s\n", nameParts[2], ipParts[2]
            }
        }
    ' bundle.js)

    if [ -n "$results" ]; then
        echo -e "\n[+] Máquinas con la dificultad \"$machineDifficult\":\n"
        echo -e "Nombre\tIP\n-------\t-------------"
        echo "$results" | column -t -s $'\t'
    else
        echo -e "\n[!] No se encontraron máquinas con la dificultad \"$machineDifficult\""
    fi
}
function searchMachineSO() {
    machineSO="$1"

    results=$(awk -v so="$machineSO" '
        function tolowercase(str) {
            gsub(/[A-Z]/, "", str)
            return tolower(str)
        }
        BEGIN { name = ""; ip = ""; os = "" }
        /name: / { name = $0 }
        /ip: /   { ip = $0 }
        /so: /   { os = $0 }
        {
            # Extraer el valor de SO quitando comillas y espacios
            if (match($0, /so: "[^"]+"/)) {
                so_val = substr($0, RSTART+4, RLENGTH-5)
                # Convertir a minúsculas para comparación case-insensitive
                so_val_lc = tolower(so_val)
                so_lc = tolower(so)
                if (so_val_lc ~ so_lc) {
                    if (name != "" && ip != "" && os != "") {
                        gsub(/"|,/, "", name)
                        gsub(/"|,/, "", ip)
                        gsub(/"|,/, "", os)
                        split(name, nameParts, ": ")
                        split(ip, ipParts, ": ")
                        split(os, osParts, ": ")
                        printf "%s\t%s\t%s\n", nameParts[2], ipParts[2], osParts[2]
                    }
                }
            }
        }
    ' bundle.js)

    if [ -n "$results" ]; then
        echo -e "\n[+] Máquinas con el sistema operativo similar a \"$machineSO\":\n"
        echo -e "Nombre\tIP\tSistema Operativo\n-------\t-------------\t------------------"
        echo "$results" | column -t -s $'\t'
    else
        echo -e "\n[!] No se encontraron máquinas con el sistema operativo \"$machineSO\""
    fi
}


function searchSkillMachine(){

	skillName="$1"

	check_skill="$(cat bundle.js | grep "skills: " -B 6 | grep "$skillName" -i -B 6 | grep "name: " | awk 'NF{print $NF}' |tr -d '"' | tr -d ',' | column)"


	if [ "$check_skill" ]; then

		echo -e "\n[+] Estas son las maquinas con la habilidad $skillName:\n"


		(cat bundle.js | grep "skills: " -B 6 | grep "$skillName" -i -B 6 | grep "name: " | awk 'NF{print $NF}' |tr -d '"' | tr -d ',' | column)
	else


		echo -e  "\n[!] No se a encontrado la maquina con la Skill solicitada\n"


	fi



}


function updateFiles(){
        if [ ! -f bundle.js ]; then
                tput civis
                echo -e "\n[+] El archivo no existe. Descargándolo por primera vez..."
                curl -s "$main_url" > bundle.js
                js-beautify bundle.js | sponge bundle.js
                echo -e "[+] Archivo descargado y formateado."
                tput cnorm
        else
                tput civis
		echo -e "\n[+] Comprobando nuevas actualizaciones"
		echo -e "\n[+] Hay nuevas actualizaciónes"
                echo -e "\n[+] Actualizando archivo existente..."
                curl -s "$main_url" > bundle_temp.js
		js-beautify bundle_temp.js | sponge bundle_temp.js
		md5_temp_value=$(md5sum bundle_temp.js | awk '{print $1}')
		md5_original_value=$(md5sum bundle.js | awk '{print $1}')

		if [ "$md5_temp_value" == "$md5_original_value" ]; then
			echo " [+] No hay actualizaciones"
			rm bundle_temp.js 

		else

			echo -e "[+] Hay nuevas actualizaciones disponibles"
			rm bundle.js
			mv bundle_temp.js bundle.js
			echo -e "[+] Archivos actualizados"

		fi
                tput cnorm
        fi
}


# INDICADORES:
declare -i parameter_counter=0

while getopts "m:ui:hy:s:d:a:" arg; do
    case $arg in
        m) machineName="$OPTARG"; let parameter_counter+=1 ;;
        h) helpPanel ;;
	i) ipAddress="$OPTARG"; let parameter_counter+=3;;
        u) updateFiles; let parameter_counter+=2 ;;
	y) machineName="$OPTARG"; let parameter_counter+=4;;
	d) machineDifficult="$OPTARG"; let parameter_counter+=5;;
	s) machineSO="$OPTARG"; let parameter_counter+=6;;
	a) skillName="$OPTARG"; let parameter_counter+=7;;
    esac
done

if [ $parameter_counter -eq 1 ]; then
	searchMachine $machineName
elif [ $parameter_counter -eq 2 ]; then
	updateFiles
elif [ $parameter_counter -eq 3 ]; then
	searchIP $ipAddress
elif [ $parameter_counter -eq 4 ]; then

	getYTLink $machineName
elif [ $parameter_counter -eq 5 ]; then
	searchMachineDifficult $machineDifficult

elif [ $parameter_counter -eq 6 ]; then

	searchMachineSO $machineSO

elif [ $parameter_counter -eq 7 ]; then
	searchSkillMachine "$skillName"

else
	helpPanel
fi
