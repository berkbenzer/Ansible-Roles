#!/bin/bash

EMAIL="reciever@gmail.com"

SUBJECT="ALERT: Root Access Detected"
LOG_FILE="/var/log/root_access.log"
LAST_LOGGED_FILE="/var/log/last_root_alert"
DEBUG_LOG="/var/log/root_alert_debug.log"

AUTH_LOG="/var/log/auth.log"
SECURE_LOG="/var/log/secure"

echo "-----------------------------" >> $DEBUG_LOG
echo "$(date) - Script started" >> $DEBUG_LOG
LAST_LOGIN=$(sudo ausearch -m USER_START --start recent | tail -n 1)
echo "Last login audit log: $LAST_LOGIN" >> $DEBUG_LOG

USER_UID=$(echo "$LAST_LOGIN" | grep -oP 'auid=\K[0-9]+')
echo "Extracted UID: $USER_UID" >> $DEBUG_LOG

USERNAME=$(getent passwd "$USER_UID" | cut -d: -f1)

if [[ -z "$USERNAME" ]]; then
    USERNAME=$(sudo grep "session opened" $AUTH_LOG $SECURE_LOG 2>/dev/null | grep "root" | tail -n 1 | awk '{print $NF}')
fi

if [[ -z "$USERNAME" ]]; then
    echo "$(date) - No username found, skipping alert" >> $DEBUG_LOG
    exit 0  # Stop execution if no valid username is found
fi

DATE_TIME=$(date "+%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)

EVENT_TIME=$(echo "$LAST_LOGIN" | grep -oP 'msg=audit\(\K[^)]+' | cut -d: -f1)
if [[ -z "$EVENT_TIME" ]]; then
    EVENT_TIME=$DATE_TIME  # Use system time if audit log doesn't provide one
fi

echo "Event Time: $EVENT_TIME" >> $DEBUG_LOG

if [[ -f "$LAST_LOGGED_FILE" ]]; then
    LAST_RECORDED=$(cat "$LAST_LOGGED_FILE")
else
    LAST_RECORDED=""
fi

if [[ "$EVENT_TIME" != "$LAST_RECORDED" ]]; then
    BODY="User: $USERNAME
Server: $HOSTNAME
Date/Time: $DATE_TIME"

    echo -e "$BODY" | mail -s "$SUBJECT" "$EMAIL"
    echo "$DATE_TIME - ALERT: User '$USERNAME' switched to root" >> "$LOG_FILE"
    echo "$EVENT_TIME" > "$LAST_LOGGED_FILE"
    echo "$(date) - Email sent successfully" >> $DEBUG_LOG
else
    echo "$(date) - Duplicate login detected, skipping alert" >> $DEBUG_LOG
fi




