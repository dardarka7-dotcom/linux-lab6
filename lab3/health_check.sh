#!/bin/bash
REPORT="health_$(hostname)_$(date +%Y%m%d_%H%M).txt"
CPU_LIMIT=80
RAM_LIMIT=85
DISK_LIMIT=90
SERVICES=("ssh" "cron")

{
echo "=== Отчёт о состоянии сервера ==="
echo "Сервер:   $(hostname)"
echo "Дата:     $(date '+%Y-%m-%d %H:%M:%S')"
echo "Аптайм:   $(uptime -p)"
echo "ОС:       $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
echo "Ядро:     $(uname -r)"
echo
echo "--- Сеть ---"
echo "IP-адрес: $(hostname -I | awk '{print $1}')"
echo "Шлюз:     $(ip route | awk '/default/ {print $3; exit}')"
echo "DNS:      $(awk '/^nameserver/ {print $2}' /etc/resolv.conf | tr '\n' ' ')"
echo
echo "--- Ресурсы ---"
CPU=$(vmstat 1 2 | tail -1 | awk '{print 100 - $15}')
RAM=$(free | awk '/Mem:/ {printf "%d", $3/$2*100}')
DISK=$(df / | awk 'NR==2 {gsub("%",""); print $5}')
echo "CPU:  ${CPU}%"
echo "RAM:  ${RAM}%"
echo "Disk: ${DISK}%"
[ "$CPU"  -ge "$CPU_LIMIT" ]  && echo "ВНИМАНИЕ: высокая загрузка CPU"
[ "$RAM"  -ge "$RAM_LIMIT" ]  && echo "ВНИМАНИЕ: мало свободной памяти"
[ "$DISK" -ge "$DISK_LIMIT" ] && echo "ВНИМАНИЕ: диск почти заполнен"
echo
echo "--- Топ-5 процессов по памяти ---"
ps -eo pid,user,%mem,comm --sort=-%mem | head -6
echo
echo "--- Состояние служб ---"
for srv in "${SERVICES[@]}"; do
    echo "$srv: $(systemctl is-active "$srv")"
done
echo
echo "--- Пользователи (UID >= 1000) ---"
awk -F: '$3 >= 1000 && $1 != "nobody" {print $1 " (UID: " $3 ")"}' /etc/passwd
echo
echo "--- Администраторы (группа sudo) ---"
getent group sudo | cut -d: -f4
} | tee "$REPORT"

echo
echo "Отчёт сохранён: $REPORT"
