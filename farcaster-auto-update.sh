#!/bin/bash

# Проверка существования скрипта обновления
if [ -f ~/update_hubble.sh ]; then
    echo "Скрипт ~/update_hubble.sh уже существует. Прерывание выполнения."
    exit 1
fi

# Создание скрипта обновления ноды
echo -e '#!/bin/bash\ncd ~/hubble && ./hubble.sh upgrade' > ~/update_hubble.sh

# Делаем скрипт исполняемым
chmod +x ~/update_hubble.sh

# Добавление задания в cron
(crontab -l ; echo "0 0 */5 * * /bin/bash ~/update_hubble.sh") | crontab -

# Вывод текущих заданий cron
echo "Список текущих заданий cron:"
crontab -l

echo "Скрипт обновления ноды создан и добавлен в cron для выполнения каждые 5 дней."
