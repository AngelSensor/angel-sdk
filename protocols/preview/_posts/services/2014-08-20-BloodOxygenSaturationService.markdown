# Blood Oxygen Saturation Service
Service UUID: `902dcf38-ccc0-4902-b22c-70cab5ee5df2`

## Characteristics Summary

| Characteristic          | Read | Write | Notify | Indicate
|-------------------------|------|-------|--------|-----------
| Blood Oxygen Saturation |      |       |        | Y
| Body Sensor Location    | Y    |       |        |



## Blood Oxygen Saturation Measurement Characteristic
Characteristic UUID: `b269c33f-df6b-4c32-801d-1b963190bc71`

| Field name           | Format   | Info    
| -------------------- | -------- | -------------- 
| Blood Oxygen Saturation Value | [FLOAT][FormatTypes]| Units: [percentage][GattUnits]
| Time Stamp | | [org.bluetooth.characteristic.date_time][date_time]


[FormatTypes]:https://developer.bluetooth.org/gatt/Pages/FormatTypes.aspx
[date_time]:https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.date_time.xml
[GattUnits]:https://developer.bluetooth.org/gatt/units/Pages/default.aspx

## Body Sensor Location Characteristic
Characterisitc UUID: `0x2A38`

| Field name            | Size     | Data format    
| --------------------- | -------- | -------------- 
| Body Sensor Location  | 8bit     | [org.bluetooth.characteristic.body_sensor_location][body_sensor_location]

[body_sensor_location]:https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.body_sensor_location.xml

## Protocol Revision Characteristic
Characteristic UUID: `3b8e7983-133a-4a0f-90fc-82006ed55505`

This characteristic is a constant value. It defines the revision number of the current service specification. The service protocol may be updated with each specification revision.

| Field name            | Format                  | Info
|-----------------------|-------------------------| -------------- 
| Protocol Revision     | [uint8][FormatTypes]    | 0-255


TODO:

* Consider making time stamp optional similar to Health Thermometer. 
