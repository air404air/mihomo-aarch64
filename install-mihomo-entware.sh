#!/bin/sh

set -e

PKG_URL="https://sw.ext.io/ent/aarch64/mihomo_1.19.23-1_aarch64-3.10.ipk"
PKG_FILE="/tmp/mihomo.ipk"
CONF_DIR="/opt/etc/mihomo"
CONF_FILE="$CONF_DIR/config.yaml"
UI_DIR="/opt/share/mihomo/ui"
INIT_FILE="/opt/etc/init.d/S99mihomo"

echo "[1/8] Проверка Entware..."
[ -d /opt ] || { echo "Ошибка: /opt не найден. Entware не установлен?"; exit 1; }
command -v opkg >/dev/null 2>&1 || { echo "Ошибка: opkg не найден."; exit 1; }

echo "[2/8] Установка зависимостей..."
opkg update || true
opkg install wget ca-certificates unzip coreutils-nohup || true

echo "[3/8] Скачивание mihomo..."
wget -O "$PKG_FILE" "$PKG_URL"

echo "[4/8] Установка mihomo..."
opkg install "$PKG_FILE" || opkg install --force-depends "$PKG_FILE"

echo "[5/8] Установка Web UI (MetaCubeXD)..."
rm -rf "$UI_DIR"
mkdir -p "$UI_DIR"
cd /tmp
rm -f metacubexd.zip
wget -O metacubexd.zip https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip
unzip -q metacubexd.zip
cp -r metacubexd-gh-pages/* "$UI_DIR/"
rm -rf /tmp/metacubexd.zip /tmp/metacubexd-gh-pages

echo "[6/8] Создание config.yaml..."
mkdir -p "$CONF_DIR"

if [ ! -f "$CONF_FILE" ]; then
cat > "$CONF_FILE" <<CFG
mixed-port: 7890
allow-lan: true
bind-address: "*"
mode: rule
log-level: info
ipv6: false

external-controller: 0.0.0.0:9090
external-ui: /opt/share/mihomo/ui
secret: ""

profile:
  store-selected: true
  store-fake-ip: true

dns:
  enable: false

proxies:
  - name: DIRECT
    type: direct

proxy-groups:
  - name: GLOBAL
    type: select
    proxies:
      - DIRECT

rules:
  - MATCH,GLOBAL
CFG
else
    echo "config.yaml уже существует, не перезаписываю."
fi

echo "[7/8] Создание init.d сервиса..."
cat > "$INIT_FILE" <<'INIT'
#!/bin/sh

ENABLED=yes
PROCS=mihomo
ARGS="-f /opt/etc/mihomo/config.yaml"
PREARGS=""
DESC="Mihomo proxy"
PATH=/opt/sbin:/opt/bin:/sbin:/bin:/usr/sbin:/usr/bin

. /opt/etc/init.d/rc.func
INIT

chmod +x "$INIT_FILE"

echo "[8/8] Запуск mihomo..."
"$INIT_FILE" stop >/dev/null 2>&1 || true
"$INIT_FILE" start

echo
echo "Готово."
echo
echo "Панель:"
echo "  http://IP_РОУТЕРА:9090/ui"
echo
echo "Команды:"
echo "  /opt/etc/init.d/S99mihomo start"
echo "  /opt/etc/init.d/S99mihomo stop"
echo "  /opt/etc/init.d/S99mihomo restart"
echo
echo "Конфиг:"
echo "  /opt/etc/mihomo/config.yaml"
echo
