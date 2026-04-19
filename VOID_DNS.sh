#!/bin/bash

# Переход на альтернативный экран для чистоты
tput smcup
clear

# Цвета
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
center "=== V.O.I.D™ DNS COMMANDER v2.0 ===" "$CYAN"
center "Лицензия: Манифест Свободной Цитадели" "$CYAN"
center "===========================================" "$CYAN"
echo ""

# 1. СИСТЕМНЫЙ ДЕТЕКТ
OS_ID=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')

case $OS_ID in
    arch)
        center "[ARCH DETECTED]" "$YELLOW"
        echo "Обнаружена система Arch Linux. Вы выбрали путь глубокой настройки."
        echo -e "\nНажмите любую клавишу для выхода..."
        read -n 1 -s
        tput rmcup
        exit 0
        ;;
    gentoo)
        center "[GENTOO ERROR]" "$RED"
        echo "Ошибка: Обнаружена бесконечная компиляция мира."
        echo -e "\nНажмите любую клавишу для выхода..."
        read -n 1 -s
        tput rmcup
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
    echo -n "Желаете продолжить? (y/n): "
    read -r confirm_change
    if [[ "$confirm_change" != "y" ]]; then 
        tput rmcup
        echo -e "${CYAN}Спасибо за использование софта от V.O.I.D™${NC}"
        exit 0
    fi
fi

# 3. РАСШИРЕННАЯ БАЗА DNS
DNS_NAMES=("Xbox-DNS" "Malw-Link" "Google" "Cloudflare" "Quad9" "AdGuard" "OpenDNS" "G-Core" "Mullvad" "Comodo" "Level3")
DNS_TARGETS=("176.99.11.77" "176.103.130.130" "8.8.8.8" "1.1.1.1" "9.9.9.9" "94.140.14.14" "208.67.222.222" "95.161.10.10" "194.242.2.2" "8.26.56.26" "4.2.2.1")

# 4. СКАНИРОВАНИЕ
echo -e "\n${CYAN}[*] Запуск анализа задержки узлов...${NC}\n"
best_ping=999
declare -a results_ping

for i in "${!DNS_NAMES[@]}"; do
    echo -n -e "[$i] Анализ ${DNS_NAMES[$i]} (${DNS_TARGETS[$i]})... "
    ping_res=$(ping -c 2 -W 1 "${DNS_TARGETS[$i]}" 2>/dev/null | tail -1 | awk '{print $4}' | cut -d '/' -f 2 | cut -d '.' -f 1)
    
    if [[ -z "$ping_res" ]]; then
        echo -e "${RED}НЕДОСТУПЕН${NC}"
        results_ping[$i]=999
    else
        echo -e "${GREEN}${ping_res}ms${NC}"
        results_ping[$i]=$ping_res
        if [ "$ping_res" -lt "$best_ping" ]; then
            best_ping=$ping_res
            best_idx=$i
        fi
    fi
done

echo ""
center "--- РЕКОМЕНДАЦИЯ V.O.I.D ---" "$CYAN"
center "Лидер по пингу: ${DNS_NAMES[$best_idx]} ($best_ping ms)" "$GREEN"
echo ""

# 5. ВЫБОР И ПРИМЕНЕНИЕ
echo -e "${YELLOW}Введите номер DNS для установки (или 'n' для выхода):${NC}"
read -p "Выбор [0-$(( ${#DNS_NAMES[@]} - 1 ))]: " user_choice

if [[ "$user_choice" =~ ^[0-9]+$ ]] && [ "$user_choice" -lt "${#DNS_NAMES[@]}" ]; then
    selected_name=${DNS_NAMES[$user_choice]}
    selected_ip=${DNS_TARGETS[$user_choice]}
    
    echo -e "\nВыбран: $selected_name ($selected_ip)"
    read -p "Выберите протокол (DoH/std): " dns_type
    
    if [[ "$dns_type" == "doh" || "$dns_type" == "DoH" ]]; then
        center "[ИНСТРУКЦИЯ ПО DOH]" "$YELLOW"
        echo "$DOH_ADVICE"
        echo "Endpoint: https://$selected_ip/dns-query"
        read -n 1 -s -p "Нажмите любую клавишу..."
    else
        INTERFACE=$(nmcli -t -f DEVICE,STATE device | grep ":connected" | cut -d: -f1 | grep -v "lo" | head -n1)
        sudo nmcli device modify "$INTERFACE" ipv4.dns "$selected_ip"
        sudo nmcli device modify "$INTERFACE" ipv4.ignore-auto-dns yes
        center "[SUCCESS] Настройки применены к $INTERFACE." "$GREEN"
        sleep 2
    fi
else
    echo "Отмена операции."
    sleep 1
fi

# ЗАВЕРШЕНИЕ
tput rmcup
echo -e "${CYAN}Спасибо за использование софта от V.O.I.D™${NC}"
