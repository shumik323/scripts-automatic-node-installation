#!/bin/bash

# Функция для вывода обратного отсчета с указанием цвета
function countdown {
    local counter=$1
    local color=$2

    while [ $counter -gt 0 ]; do
        echo -ne "\e[93mОжидание завершения установки... $counter сек\e[0m\r"
        sleep 1
        ((counter--))
    done
    echo -ne "\n"
}

# Функция для вывода сообщения с указанием цвета
function print_message {
    local message=$1
    local color=$2

    echo -e "\e[${color}m${message}\e[0m"
}

# Установка debconf-utils для предварительной настройки
print_message "Установка debconf-utils для предварительной настройки..." "32"
sudo apt-get install -y debconf-utils

# Предварительная настройка для автоматического перезапуска сервисов
print_message "Настройка debconf для автоматического режима" "32"
echo "debconf debconf/frontend select Noninteractive" | sudo debconf-set-selections
echo "debconf debconf/reconfigure boolean true" | sudo debconf-set-selections

# Обновление пакетов
print_message "Обновление пакетов..." "32"
if sudo DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y; then
    print_message "Пакеты успешно обновлены." "32"
else
    print_message "Ошибка при обновлении пакетов. Прерывание скрипта." "31"
    exit 1
fi

# Установка необходимых пакетов
print_message "Установка необходимых пакетов..." "32"
if sudo DEBIAN_FRONTEND=noninteractive apt install -y curl git wget build-essential jq screen; then
    print_message "Пакеты успешно установлены." "32"
else
    print_message "Ошибка при установке пакетов. Прерывание скрипта." "31"
    exit 1
fi

# Запуск screen сессии и выполнение команды установки ноды
print_message "Запуск screen сессии и установка ноды..." "32"
if screen -S nubit -dm bash -c 'curl -sL https://nubit.sh | bash'; then
    print_message "Screen сессия успешно запущена для установки ноды." "32"
else
    print_message "Ошибка при запуске screen сессии. Прерывание скрипта." "31"
    exit 1
fi

# Ожидание 3 минут перед проверкой логов
print_message "Ожидание 3 минут перед проверкой логов..." "93"
countdown 180

# Проверка появления логов с сообщениями INFO
print_message "Ожидание появления логов с сообщениями INFO..." "93"
while ! screen -S nubit -X hardcopy .nubit.log; do
    print_message "Логи INFO не найдены. Увеличиваем время ожидания на 1 минуту и продолжаем..." "93"
    countdown 60
done

if grep -q "INFO" .nubit.log; then
    print_message "Сообщения INFO найдены. Продолжаем..." "32"
else
    print_message "Логи INFO не найдены после ожидания. Прерывание скрипта." "31"
    exit 1
fi

# Автоматический выход из screen сессии
print_message "Автоматический выход из screen сессии..." "32"
if screen -S nubit -X quit; then
    print_message "Screen сессия успешно завершена." "32"
else
    print_message "Ошибка при завершении screen сессии." "31"
fi

# Сохранение сид-фразы
print_message "Сохранение сид-фразы..." "33"
cat $HOME/nubit-node/mnemonic.txt

# Удаление скрипта после успешного выполнения
print_message "Удаление скрипта..." "33"
rm -- "$0"