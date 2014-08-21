---
layout: default
title:  "Activity Monitoring Service"
<!-- date:   2014-08-20 21:47:34 -->
categories: services
---

# Activity Monitoring Service
Service UUID: `68b52738-4a04-40e1-8f83-337a29c3284d`

## Characteristics Summary

| Characteristic                | Read | Write | Notify | Indicate  |
|-------------------------------|------|-------|--------|-----------|
| Step Count                    | Y    |       | Y      |           |
| Acceleration Energy Magnitude | Y    |       |        |           |
| Body Sensor Location          | Y    |       |        |           |
| Activity Monitoring Control Point |  | Y     |        |           |
| Protocol Revision             | Y    |       |        |           |


## Step Count Characteristic
Characteristic UUID: `7a543305-6b9e-4878-ad67-29c5a9d99736`

<a href="step_count_characteristic"> </a>

| Field name           | Format   | Info    
| -------------------- | -------- | -------------- 
| Step Count Value | [uint24][FormatTypes]| 


[FormatTypes]:https://developer.bluetooth.org/gatt/Pages/FormatTypes.aspx
[date_time]:https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.date_time.xml


## Acceleration Energy Magnitude
Characteristic UUID: `9e3bd0d7-bdd8-41fd-af1f-5e99679183ff`

<a name="acceleration_energy_magnitude"> </a>

| Field name                    | Format   | Info
| ----------------------------- | -------- | -------------- 
| Acceleration Energy Magnitude | [uint24][FormatTypes]| Units: kJ (kilo-Joules)

## Body Sensor Location Characteristic
Characterisitc UUID: `0x2A38`

| Field name            | Format     | Info
| --------------------- | -------- | -------------- 
| Body Sensor Location  | [8bit][FormatTypes]     | [org.bluetooth.characteristic.body_sensor_location][body_sensor_location]

[body_sensor_location]:https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.body_sensor_location.xml

## Activity Monitoring Control Point
Characteristic UUID: `d1b446fe-1313-4fce-9ae1-d68ae2d29e60`

| Field name  | Format              | Info
|-------------|---------------------|--------------- 
| Op Code     | [8bit][FormatTypes] | See [Op Codes](#activity_monitoring_cp_opcodes)

### Activity Monitoring Control Point Op Codes
<a name="activity_monitoring_cp_opcodes"> </a>

| Value  | Info
|--------|-------------
| 1      | Reset Step Count: resets the value of [Step Count Value](#step_count_characteristic) field to 0 |
| 2      | Reset Acceleration Energy Magnitude: resets the value of [Acceleration Energy Magnitude](#acceleration_energy_magnitude) to 0 |
| 0      | Reserved
| 3-255  | Reserved


## Protocol Revision Characteristic
Characteristic UUID: `3b8e7983-133a-4a0f-90fc-82006ed55505`

This characteristic is a constant value. It defines the revision number of the current service specification. The service protocol may be updated with each specification revision.

| Field name            | Format                  | Info
|-----------------------|-------------------------| -------------- 
| Protocol Revision     | [uint8][FormatTypes]    | 0-255

