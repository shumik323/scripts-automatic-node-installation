#!/bin/bash

# Функция для вывода обратного отсчета с указанием цвета
function countdown {
    local counter=$1
    local color=$2

    while [[ $counter -gt 0 ]]; do
        printf "\e[%smОжидание завершения установки... %d сек\e[0m\r" "$color" "$counter"
        sleep 1
        ((counter--))
    done
    printf "\n"
}

# Функция для вывода сообщения с указанием цвета
function print_message {
    local message=$1
    local color=$2

    printf "\e[%sm%s\e[0m\n" "$color" "$message"
}

# Установка debconf-utils для предварительной настройки
print_message "Установка debconf-utils для предварительной настройки..." "32"
if ! sudo apt-get install -y debconf-utils; then
    print_message "Ошибка при установке debconf-utils. Прерывание скрипта." "31"
    exit 1
fi

# Предварительная настройка для автоматического перезапуска сервисов
print_message "Настройка debconf для автоматического режима" "32"
if ! echo "debconf debconf/frontend select Noninteractive" | sudo debconf-set-selections || \
   ! echo "debconf debconf/reconfigure boolean true" | sudo debconf-set-selections; then
    print_message "Ошибка при настройке debconf. Прерывание скрипта." "31"
    exit 1
fi

# Обновление пакетов
print_message "Обновление пакетов..." "32"
if ! sudo DEBIAN_FRONTEND=noninteractive apt update || ! sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y; then
    print_message "Ошибка при обновлении пакетов. Прерывание скрипта." "31"
    exit 1
fi
print_message "Пакеты успешно обновлены." "32"

# Установка необходимых пакетов
print_message "Установка необходимых пакетов..." "32"
if ! sudo DEBIAN_FRONTEND=noninteractive apt install -y curl wget build-essential jq screen; then
    print_message "Ошибка при установке пакетов. Прерывание скрипта." "31"
    exit 1
fi
print_message "Пакеты успешно установлены." "32"

# Имя screen сессии
SESSION_NAME="nubit"

# Создание screen сессии с именем nubit
echo "Запуск screen сессии..." "32"
if screen -S ${SESSION_NAME} -dm; then
    echo "Screen сессия успешно запущена." "32"
else
    echo "Ошибка при запуске screen сессии. Прерывание скрипта." "31"
    exit 1
fi

# Установка ноды в созданной screen сессии
echo "Установка ноды..." "32"
if screen -S ${SESSION_NAME} -p 0 -X stuff "curl -sL1 https://nubit.sh | bash $(printf '\r')"; then
    echo "Команда установки ноды успешно отправлена в screen сессию." "32"
else
    echo "Ошибка при отправке команды установки ноды. Прерывание скрипта." "31"
    exit 1
fi

# Ожидание 3 минут перед проверкой логов
print_message "Ожидание 3 минут перед ..." "93"
countdown 180 93

# Автоматический выход из screen сессии
print_message "Автоматический выход из screen сессии..." "32"
if ! screen -S ${SESSION_NAME} -X detach; then
    print_message "Ошибка при завершении screen сессии." "31"
else
    print_message "Screen сессия успешно завершена." "32"
fi

# Сохранение сид-фразы
print_message "Сохранение сид-фразы..." "33"
if ! cat "$HOME/nubit-node/mnemonic.txt"; then
    print_message "Ошибка при сохранении сид-фразы." "31"
    exit 1
fi

# Извлечение значения key из вывода команды
print_message "Извлечение значения key..." "32"

# Выполнение команды и сохранение вывода в переменную
output=$($HOME/nubit-node/bin/nkey list --p2p.network nubit-alphatestnet-1 --node.type light)

# Извлечение строки с pubkey
pubkey_line=$(echo "$output" | grep 'pubkey')

# Извлечение значения key с помощью awk
key_value=$(echo "$pubkey_line" | awk -F'"key":"' '{print $2}' | awk -F'"}' '{print $1}')

# Вывод значения key
print_message "Key: $key_value" "32"