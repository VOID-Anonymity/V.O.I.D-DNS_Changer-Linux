#!/bin/bash

# Переход на альтернативный экран для чистоты
tput smcup
clear

# Цвета (Стильный Циан)
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Функция центровки
center() {
    local text="$1"
    local color="$2"
    local width=$(tput cols)
    local padding=$(( (width - ${#text}) / 2 ))
    if [ $padding -lt 0 ]; then padding=0; fi
    printf "%${padding}s" ""
    echo -e "${color}${text}${NC}"
}

center "Загрузка протоколов Свободной Цитадели... [OK]" "$CYAN"
sleep 1
clear

center "===========================================" "$CYAN"
center "=== V.O.I.D™ DNS COMMANDER v3.1 ===" "$CYAN"
center "Лицензия: Манифест Свободной Цитадели" "$CYAN"
center "===========================================" "$CYAN"
echo ""

# 1. СИСТЕМНЫЙ ДЕТЕКТ
OS_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')

case $OS_ID in
    arch)
        center "[ARCH DETECTED]" "$YELLOW"
        echo "Обнаружена система Arch Linux. Вы выбрали путь глубокой настройки."
        echo "Для стабильности рекомендуется использовать Arch Wiki."
        echo "Автоматизация V.O.I.D может конфликтовать с вашими ручными правками."
        echo -e "\nНажмите любую клавишу для выхода..."
        read -n 1 -s
        tput rmcup
        echo -e "${CYAN}Спасибо за использование софта от V.O.I.D™${NC}"
        exit 0
        ;;
    gentoo)
        center "[GENTOO ERROR]" "$RED"
        echo "Ошибка: Обнаружена бесконечная компиляция мира."
        echo "В Gentoo всё слишком индивидуально для автоматических сценариев."
        echo "Рекомендуется ручная правка /etc/resolv.conf."
        echo -e "\nНажмите любую клавишу для выхода..."
        read -n 1 -s
        tput rmcup
        echo -e "${CYAN}Спасибо за использование софта от V.O.I.D™${NC}"
        exit 0
        ;;
    linuxmint|ubuntu|debian)
        DOH_ADVICE="Команда: sudo apt install cloudflared && cloudflared proxy-dns"
        ;;
    *)
        DOH_ADVICE="Требуется ручная установка cloudflared для вашей системы."
        ;;
esac

# 2. ПРОВЕРКА ТЕКУЩИХ DNS
CURRENT_DNS=$(nmcli dev show | grep 'IP4.DNS' | awk '{print $2}' | xargs)
if [ ! -z "$CURRENT_DNS" ]; then
    center "Текущие DNS в системе: $CURRENT_DNS" "$YELLOW"
    echo -n "Желаете переназначить DNS на более быстрые? (y/n): "
    read -r confirm_change
    if [[ "$confirm_change" != "y" ]]; then 
        tput rmcup
        echo -e "${CYAN}Спасибо за использование софта от V.O.I.D™${NC}"
        exit 0
    fi
fi

# 3. БАЗА DNS
DNS_NAMES=("Xbox-DNS" "Malw-Link" "Google" "Cloudflare" "Quad9" "AdGuard")
DNS_TARGETS=("176.99.11.77" "176.103.130.130" "8.8.8.8" "1.1.1.1" "9.9.9.9" "94.140.14.14")

echo -n "Добавить ваш кастомный DNS для теста? (y/n): "
read -r add_own
if [[ "$add_own" == "y" ]]; then
    read -p "Введите адрес (IP или Домен): " custom_dns
    if [[ "$custom_dns" =~ [a-zA-Z] ]]; then
        resolved_ip=$(dig +short "$custom_dns" | head -n1)
        if [ -z "$resolved_ip" ]; then
            echo -e "${RED}Ошибка: Домен не может быть разрешен.${NC}"
        else
            DNS_NAMES+=("Custom-User")
            DNS_TARGETS+=("$resolved_ip")
        fi
    else
        DNS_NAMES+=("Custom-User")
        DNS_TARGETS+=("$custom_dns")
    fi
fi

# 4. СКАНИРОВАНИЕ
echo -e "\n${CYAN}[*] Запуск анализа задержки узлов...${NC}"
best_ping=999
for i in "${!DNS_NAMES[@]}"; do
    echo -n "Анализ ${DNS_NAMES[$i]} (${DNS_TARGETS[$i]})... "
    ping_res=$(ping -c 2 -W 1 "${DNS_TARGETS[$i]}" 2>/dev/null | tail -1 | awk '{print $4}' | cut -d '/' -f 2 | cut -d '.' -f 1)
    
    if [[ -z "$ping_res" ]]; then
        echo -e "${RED}НЕДОСТУПЕН${NC}"
    else
        echo -e "${GREEN}${ping_res}ms${NC}"
        if [ "$ping_res" -lt "$best_ping" ]; then
            best_ping=$ping_res
            best_name=${DNS_NAMES[$i]}
            best_ip=${DNS_TARGETS[$i]}
        fi
    fi
done

# 5. РЕКОМЕНДАЦИЯ
echo ""
center "--- РЕКОМЕНДАЦИЯ V.O.I.D ---" "$CYAN"
center "Оптимальный узел: $best_name ($best_ping ms)" "$GREEN"
echo ""

read -p "Применить данные настройки? (y/n): " final_y
if [[ "$final_y" == "y" ]]; then
    read -p "Выберите протокол (DoH/std): " dns_type
    if [[ "$dns_type" == "doh" || "$dns_type" == "DoH" ]]; then
        center "[ИНСТРУКЦИЯ ПО DOH]" "$YELLOW"
        echo "$DOH_ADVICE"
        echo "Endpoint: https://$best_ip/dns-query"
        read -n 1 -s -p "Нажмите любую клавишу после ознакомления..."
    else
        INTERFACE=$(nmcli -t -f DEVICE,STATE device | grep ":connected" | cut -d: -f1 | grep -v "lo" | head -n1)
        sudo nmcli device modify "$INTERFACE" ipv4.dns "$best_ip"
        sudo nmcli device modify "$INTERFACE" ipv4.ignore-auto-dns yes
        center "[SUCCESS] Локальные ограничения DNS сняты." "$GREEN"
        sleep 2
    fi
fi

# ЗАВЕРШЕНИЕ
tput rmcup
echo -e "${CYAN}Спасибо за использование софта от V.O.I.D™${NC}"
