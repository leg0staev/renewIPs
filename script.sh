#!/bin/bash


# Сохраняем вывод команды в переменную
output=$(ip a -4 -o)

# Извлекаем имена интерфейсов
interfaces=$(echo "$output" | awk '{print $2}')

# Проверяем, есть ли повторяющиеся имена интерфейсов
duplicates=$(echo "$interfaces" | sort | uniq -d)


ip -4 -o a | grep "$duplicates"