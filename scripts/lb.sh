echo "[TASK 1] LB - Install Dependencies"
apt update -qq >/dev/null 2>&1
apt install -qq -y hatop haproxy >/dev/null 2>&1

echo "[TASK 2] LB - Set Configuration Permissions"
install -d -m 700 /etc/haproxy
install /tmp/haproxy.cfg -m 644 /etc/haproxy/haproxy.cfg

echo "[TASK 3] LB - Reload"
systemctl reload haproxy >/dev/null 2>&1

echo "[TASK 4] LB - Create Alias"
echo "alias proxtop=\"sudo hatop -s /var/run/haproxy/haproxy.sock\"" >> ~/.aliases