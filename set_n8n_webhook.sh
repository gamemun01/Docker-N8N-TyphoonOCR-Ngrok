#!/bin/bash

# รอให้ ngrok service เริ่มทำงานและมี public URL
echo "Waiting for ngrok tunnel to be available..."
NGROK_URL=""

for i in $(seq 1 60); do # ลอง 60 วินาที
  # ใช้ curl ดึงข้อมูล และใช้ jq เพื่อดึงค่า public_url ของ tunnel แรกที่เป็น https
  NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[] | select(.proto=="https") | .public_url')

  if [[ -n "$NGROK_URL" && "$NGROK_URL" != "null" ]]; then
    echo "Ngrok Public URL: $NGROK_URL"
    break
  fi
  sleep 1
done

if [ -z "$NGROK_URL" ]; then
  echo "Failed to get Ngrok Public URL after 60 seconds. Exiting."
  exit 1
fi

echo "Updating WEBHOOK_URL in .env file..."
# สำรองไฟล์ .env เดิมไว้ก่อน
cp .env .env.bak

# ตรวจสอบว่ามีบรรทัด WEBHOOK_URL อยู่ในไฟล์ .env หรือไม่
if grep -q "^WEBHOOK_URL=" .env; then
  # ถ้ามี ให้อัปเดตค่า
  sed -i.bak "s#^WEBHOOK_URL=.*#WEBHOOK_URL=$NGROK_URL#" .env
else
  # ถ้าไม่มี ให้เพิ่มเข้าไปใหม่
  echo "WEBHOOK_URL=$NGROK_URL" >> .env
fi

# ลบไฟล์สำรองที่ sed สร้างขึ้น (ถ้าไม่ต้องการ)
rm .env.bak

echo "Restarting n8n service to apply new WEBHOOK_URL..."
# ตรวจสอบให้แน่ใจว่าคุณรันคำสั่งนี้บน Host machine ไม่ใช่ภายใน container
docker compose restart n8n

echo "n8n WEBHOOK_URL updated and n8n restarted."