#!/bin/bash


# Сохраняем вывод команды в переменную
# output=$(ip -4 -o a)


# Извлекаем имена интерфейсов
# interfaces=$(echo "$output" | awk '{print $2}')
interfaces='lo
lo
eth1'
unique_interfaces=""


for interface in $interfaces; do
    if printf "$unique_interfaces" | grep -Fxq "$interface"; then

        # Извлекаем IP-адреса для eth1
        ips=($(echo "$ip_output" | awk -v iface="$interface" '$2 == iface { for (i = 1; i <= NF; i++) if ($i ~ /^inet/) print $(i+1) }'))

        # Присваиваем значения переменным
        ip1=${ips[0]}
        ip2=${ips[1]}
        
        # Проверка, что найдено два IP-адреса
        if [[ -z "$ip1" || -z "$ip2" ]]; then
            echo "Error: Could not find two IP addresses for interface $interface."
            exit 1
        fi
    else
        unique_interfaces+="$interface"$'\n'
    fi
done

echo "$unique_interfaces"