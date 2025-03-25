#!/bin/bash

# Сохраняем вывод команды в переменную
output=$(ip -4 -o a)

# # Массив для хранения уникальных интерфейсов
# declare -A unique_interfaces

# Обрабатываем каждый интерфейс
echo "$output" | awk '{print $2}' | while read -r interface; do
    # # Проверяем, что интерфейс ещё не обработан
    # if [[ -v unique_interfaces["$interface"] ]]; then
    #     continue
    # fi

    # # Помечаем интерфейс как обработанный
    # unique_interfaces["$interface"]=1

    echo "Обрабатываем интерфейс: $interface"

    # Извлекаем IP-адреса для интерфейса
    ips=($(echo "$output" | awk -v iface="$interface" '$2 == iface && $3 == "inet" { print $4 }'))

    # Проверяем, что найдено хотя бы два IP-адреса
    if [[ ${#ips[@]} -lt 2 ]]; then
        echo "у интерфеса $interface один ip адрес, пропускаю его"
        continue
    fi

    ip1=${ips[0]}
    ip2=${ips[1]}

    echo "IP-адреса для $interface: $ip1, $ip2"

    # Чтение текущего IP-адреса из файла конфигурации
    config_file="/etc/systemd/network/${interface}.network"
    if [[ ! -f "$config_file" ]]; then
        echo "Error: File $config_file does not exist."
        continue
    fi

    current_ip=$(awk -F'=' '/^Address=/ {print $2}' "$config_file")
    if [[ -z "$current_ip" ]]; then
        echo "Error: Could not find current IP address in $config_file."
        continue
    fi

    echo "Текущий IP-адрес: $current_ip"

    # Определяем новый IP-адрес
    new_ip=""
    if [[ "$current_ip" == "$ip1" ]]; then
        new_ip="$ip2"
    elif [[ "$current_ip" == "$ip2" ]]; then
        new_ip="$ip1"
    else
        echo "Error: Current IP address ($current_ip) does not match any of the IPs for $interface."
        continue
    fi

    echo "Новый IP-адрес: $new_ip"

    # Вычисляем шлюз и номер таблицы
    gateway="${new_ip%.*}.1"
    penultimate_octet=$(echo "$new_ip" | cut -d'.' -f3)
    table_number=$((100 + penultimate_octet))

    echo "Шлюз: $gateway"
    echo "Номер таблицы: $table_number"

    # Создаём временный файл для редактирования
    temp_file=$(mktemp)

    # Обновляем файл конфигурации
    awk -v new_ip="$new_ip" -v gateway="$gateway" -v table_number="$table_number" '
    /^Address=/ { $0 = "Address=" new_ip }
    /^Gateway=/ { $0 = "Gateway=" gateway }
    /^Table=/ { $0 = "Table=" table_number }
    { print }
    ' "$config_file" > "$temp_file"

    # Перемещаем временный файл на место оригинала
    mv "$temp_file" "$config_file"

    echo "Файл $config_file успешно обновлён."
done

# Выводим список обработанных интерфейсов
echo "Обработанные интерфейсы:"
for iface in "${!unique_interfaces[@]}"; do
    echo "$iface"
done