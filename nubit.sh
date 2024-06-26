#!/bin/bash

# Функция для вывода обратного отсчета
function countdown {
    local counter=$1

    while [ $counter -gt 0 ]; do
        echo -ne "Ожидание завершения установки... $counter сек\r"
        sleep 1
        ((counter--))
    done
}

# Обновление пакетов
echo "Обновление пакетов..."
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
echo "Установка необходимых пакетов..."
sudo apt install curl git wget build-essential jq screen -y

# Запуск screen сессии и выполнение команды установки ноды
echo "Запуск screen сессии и установка ноды..."
screen -S nubit -dm bash -c 'curl -sL https://nubit.sh | bash'

# Переменная для хранения времени ожидания
wait_time=180  # Исходное время ожидания 180 секунд (3 минуты)

# Ожидание появления логов с сообщениями INFO
echo "Ожидание появления логов с сообщениями INFO..."
while ! screen -S nubit -X stuff "grep -q 'INFO' /dev/null && echo \"INFO found\"\n"; do
    echo "Логи INFO не найдены. Увеличиваем время ожидания на 1 минуту и продолжаем..."
    wait_time=$((wait_time + 60))  # Увеличиваем время ожидания на 1 минуту
    countdown 60  # Обратный отсчет 60 секунд (1 минута)
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