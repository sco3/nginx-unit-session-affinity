#!/bin/sh
set -e

UNIT_WORKERS=${UNIT_WORKERS:-4}

cat > /app/unit_config.json <<EOF
{
  "listeners": {
    "*:8080": {
      "pass": "applications/hello_app"
    }
  },
  "applications": {
    "hello_app": {
      "type": "python 3.12",
      "path": "/app",
      "module": "main",
      "callable": "app",
      "processes": {
        "spare": 0,
        "max": ${UNIT_WORKERS}
      }
    }
  }
}
EOF

/usr/sbin/unitd --no-daemon --control unix:/var/run/control.unit.sock &

for i in $(seq 1 30); do
  if [ -S /var/run/control.unit.sock ]; then
    break
  fi
  sleep 0.1
 done

if [ ! -S /var/run/control.unit.sock ]; then
  echo "Unit control socket not found"
  exit 1
fi

curl -s -X PUT --data-binary @unit_config.json --unix-socket /var/run/control.unit.sock http://localhost/config
wait
