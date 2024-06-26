#!/bin/bash

# Функция для вывода обратного отсчета
function countdown {
    local counter=$1

    while [ $counter -gt 0 ]; do
        echo -ne "Ожидание завершения установки... $counter сек\r"
        sleep 1
        ((counter--))
    done
    echo -ne "\n"
}

# Установка debconf-utils для предварительной настройки
echo "Установка debconf-utils для предварительной настройки..."
sudo apt-get install -y debconf-utils

# Предварительная настройка для автоматического перезапуска сервисов
echo "debconf debconf/frontend select Noninteractive" | sudo debconf-set-selections
echo "debconf debconf/reconfigure boolean true" | sudo debconf-set-selections

# Обновление пакетов
echo "Обновление пакетов..."
sudo DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y

# Установка необходимых пакетов
echo "Установка необходимых пакетов..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y curl git wget build-essential jq screen

# Запуск screen сессии и выполнение команды установки ноды
echo "Запуск screen сессии и установка ноды..."
screen -S nubit -dm bash -c 'curl -sL https://nubit.sh | bash'

# Ожидание 3 минуты перед проверкой логов
echo "Ожидание 3 минуты перед проверкой логов..."
countdown 180

# Переменная для хранения времени ожидания
wait_time=180  # Исходное время ожидания 180 секунд (3 минуты)

# Ожидание появления логов с сообщениями INFO
echo "Ожидание появления логов с сообщениями INFO..."
while ! screen -S nubit -Q select . > /dev/null 2>&1; do
    if screen -S nubit -X stuff "tail -n 20 /dev/null | grep INFO\n"; then
        echo "Сообщения INFO найдены. Продолжаем..."
        break
    else
        echo "Логи INFO не найдены. Увеличиваем время ожидания на 1 минуту и продолжаем..."
        wait_time=$((wait_time + 60))  # Увеличиваем время ожидания на 1 минуту
        countdown 60  # Обратный отсчет 60 секунд (1 минута)
    fi
done

# Автоматический выход из screen сессии
echo "Автоматический выход из screen сессии..."
screen -S nubit -X stuff "exit\n"

# Сохранение сид-фразы
echo "Сохранение сид-фразы..."
cat $HOME/nubit-node/mnemonic.txt

# Удаление скрипта после успешного выполнения
echo "Удаление скрипта..."
rm -- "$0"