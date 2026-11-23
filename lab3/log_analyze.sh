#!/bin/bash
# ЛР6 (Вариант 1). Анализ журнала аутентификации
LOG="${1:-auth_sample.log}"
LIMIT=3

echo "Всего неудачных попыток входа: $(grep -c 'Failed password' "$LOG")"
echo "Успешных входов: $(grep -c 'Accepted' "$LOG")"
echo
echo "Топ IP-адресов по неудачным попыткам:"
grep 'Failed password' "$LOG" | grep -oE 'from [0-9.]+' | awk '{print $2}' \
    | sort | uniq -c | sort -rn
echo
echo "Попытки входа под несуществующими пользователями:"
grep 'invalid user' "$LOG" | awk '{for(i=1;i<=NF;i++) if($i=="user") print $(i+1)}' | sort -u
echo
echo "Кандидаты на блокировку (>= $LIMIT неудачных попыток):"
grep 'Failed password' "$LOG" | grep -oE 'from [0-9.]+' | awk '{print $2}' \
    | sort | uniq -c | awk -v lim="$LIMIT" '$1 >= lim {print $2 " (" $1 " попыток)"}'
echo
echo "Попытки запуска sudo без прав (NOT in sudoers):"
grep 'NOT in sudoers' "$LOG"
