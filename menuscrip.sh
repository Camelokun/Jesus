#!/bin/bash

# Definir la ruta del archivo JSON
config_file="/root/udp/config.json"

# Funci�n para mostrar las contrase�as existentes
function show_passwords() {
  # Leer las contrase�as desde el archivo JSON
  passwords=$(jq -r '.auth.pass | join(", ")' "$config_file")

  # Mostrar las contrase�as al usuario
  echo -e "\e[1m\e[32mContrase�as existentes:\e[0m"
  echo "$passwords"
}

# Funci�n para agregar una contrase�a
function add_password() {
  # Pedir los d�as de duraci�n de las contrase�as
  echo -e "\e[1m\e[32mIngrese la duraci�n en d�as de las nuevas contrase�as: \e[0m"
  read days_duration

  # Leer las nuevas contrase�as desde el usuario
  echo -e "\e[1m\e[32mIngrese las nuevas contrase�as separadas por comas: \e[0m"
  read new_passwords

  # Convertir las contrase�as a un array
  IFS=',' read -ra passwords_arr <<< "$new_passwords"

  # Leer las contrase�as existentes desde el archivo JSON
  existing_passwords=$(jq -r '.auth.pass | join(",")' "$config_file")

  # Concatenar las contrase�as existentes con las nuevas
  updated_passwords="$existing_passwords,${passwords_arr[@]}"

  # Actualizar el archivo JSON con las nuevas contrase�as y duraci�n
  jq ".auth.pass = [\"$(echo $updated_passwords | sed 's/,/", "/g')\"] | .auth.expire = \"$days_duration\"" "$config_file" > tmp.json && mv tmp.json "$config_file"

  # Confirmar que se actualizaron las contrase�as correctamente
  if [ "$?" -eq 0 ]; then
    echo -e "\e[1m\e[32mContrase�as actualizadas correctamente.\e[0m"
  else
    echo -e "\e[1m\e[31mNo se pudo actualizar las contrase�as.\e[0m"
  fi

  # Recargar el daemon de systemd y reiniciar el servicio
  sudo systemctl daemon-reload
  sudo systemctl restart udp-custom
}

# Funci�n para eliminar una contrase�a

function delete_password() {
  # Obtener la fecha actual
  current_date=$(date +%Y-%m-%d)

  # Leer las contrase�as y fechas de vencimiento desde el archivo JSON
  passwords=$(jq -r '.auth.pass | @tsv' "$config_file")
  expirations=$(jq -r '.auth.expire | @tsv' "$config_file")

  # Convertir las contrase�as y fechas de vencimiento en arrays
  IFS=$'\n' read -ra passwords_arr <<< "$passwords"
  IFS=$'\n' read -ra expirations_arr <<< "$expirations"

   # Crear un nuevo array de contrase�as y fechas de vencimiento sin las contrase�as expiradas
  updated_passwords=()
  updated_expirations=()
  for i in "${!passwords_arr[@]}"; do
    expiration_date=${expirations_arr[$i]}
    if [[ "$current_date" < "$expiration_date" ]]; then
      updated_passwords+=("${passwords_arr[$i]}")
      updated_expirations+=("$expiration_date")
    fi
  done

  # Actualizar el archivo JSON con las contrase�as y fechas de vencimiento actualizadas
  jq ".auth.pass = [\"$(printf '%s\n' "${updated_passwords[@]}")\"] | .auth.expire = [\"$(printf '%s\n' "${updated_expirations[@]}")\"]" "$config_file" > tmp.json && mv tmp.json "$config_file"

  # Confirmar que se eliminaron las contrase�as expiradas correctamente
  if [ "$?" -eq 0 ]; then
    echo -e "\e[1m\e[32mContrase�as expiradas eliminadas correctamente.\e[0m"
  else
    echo -e "\e[1m\e[31mNo se pudieron eliminar las contrase�as expiradas.\e[0m"
  fi

  # Recargar el daemon de systemd y reiniciar el servicio
  sudo systemctl daemon-reload
  sudo systemctl restart udp-custom
}

# Recargar el daemon de systemd y reiniciar el servicio
sudo systemctl daemon-reload
sudo systemctl restart udp-custom

# Men� principal
while true; do
  echo -e "\e[1m\e[36mGesti�n de contrase�as para UDP Custom\e[0m"
  echo ""
  echo "Seleccione una opci�n:"
  echo "1. Mostrar contrase�as existentes"
  echo "2. Agregar una contrase�a"
  echo "3. Eliminar una contrase�a"
  echo "4. Salir"
  read option

  case $option in
    1) show_passwords;;
    2) add_password;;
    3) delete_password;;
    4) break;;
    *) echo -e "\e[1m\e[31mOpci�n inv�lida.\e[0m";;
  esac

  echo ""
done

# Eliminar los caracteres de retorno de carro no deseados del archivo menudp.sh
sed -i 's/\r//' menudp.sh

