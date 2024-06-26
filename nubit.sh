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
if ! sudo DEBIAN_FRONTEND=noninteractive apt install -y curl git wget build-essential jq screen; then
    print_message "Ошибка при установке пакетов. Прерывание скрипта." "31"
    exit 1
fi
print_message "Пакеты успешно установлены." "32"

# Запуск screen сессии и выполнение команды установки ноды
print_message "Запуск screen сессии и установка ноды..." "32"
if ! screen -S nubit -dm bash -c 'curl -sL https://nubit.sh | bash'; then
    print_message "Ошибка при запуске screen сессии. Прерывание скрипта." "31"
    exit 1
fi
print_message "Screen сессия успешно запущена для установки ноды." "32"

# Ожидание 3 минут перед проверкой логов
print_message "Ожидание 3 минут перед проверкой логов..." "93"
countdown 180 93

# Проверка появления логов с сообщениями INFO
print_message "Ожидание появления логов с сообщениями INFO..." "93"
while ! screen -list | grep -q "nubit"; do
    print_message "Screen сессия не найдена. Увеличиваем время ожидания на 1 минуту и продолжаем..." "93"
    countdown 60 93
done

screen -S nubit -X hardcopy .nubit.log
if grep -q "INFO" .nubit.log; then
    print_message "Сообщения INFO найдены. Продолжаем..." "32"
else
    print_message "Логи INFO не найдены после ожидания. Прерывание скрипта." "31"
    exit 1
fi

# Автоматический выход из screen сессии
print_message "Автоматический выход из screen сессии..." "32"
if ! screen -S nubit -X quit; then
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
