#!/bin/env python3

import gi, json, ssl, datetime, socket
import paho.mqtt.client as mqtt

gi.require_version('Secret', '1')
from gi.repository import Secret

passwords = Secret.password_lookup_sync(None, { "account": "nl.peetz0r.bami.secureStorage" }, None)
password_dict = json.loads(passwords)

print(f"We have {len(password_dict)} passwords for these printers:")
for printer in password_dict.keys():
  print(f" - {printer}")

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.bind(('', 2021))

while True:
  (payload, (ip, port)) = s.recvfrom(1024)
  lines = payload.decode().split('\r\n')
  found = False
  for line in lines:
    if ': ' in line:
      (header, value) = line.split(': ')
      if header == 'Location':
        location = value
      if header == 'USN':
        usn = value
        if value in password_dict:
          password = json.loads(json.loads(passwords)[value])['pass']
          found = True
  print(f"Found {usn} at {location} ({location})")
  if found:
    print("We have a password for that, assuming it's our printer")
    break
s.close()


def on_message(client, userdata, message):
  j = json.loads(message.payload.removesuffix(b"\0"))
  key = list(j.keys())[0]
  cmd = j[key]['command']

  file = f"log/{datetime.datetime.now():%Y-%m-%d_%H.%M.%S.%f}_{message.topic.replace('/', '-')}_{key}-{cmd}.log"

  print(f"Writing to {file}")
  with open(file, 'wb') as f:
    f.write(message.payload)



def on_connect(client, flags, reason_code_list, properties):
  print("Connected on MQTT, subscribing and logging everything")
  client.subscribe("#")

mqttc = mqtt.Client()
mqttc.on_connect = on_connect
mqttc.on_message = on_message

mqttc.tls_set(cert_reqs = ssl.CERT_NONE)

mqttc.username_pw_set('bblp', password)
mqttc.connect(location, 8883)
mqttc.loop_forever()

