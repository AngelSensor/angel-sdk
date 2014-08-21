# Alarm Clock Service
Service UUID: `7cd50edd-8bab-44ff-a8e8-82e19393af10`

## Characteristics Summary

| Characteristic                | Read | Write | Notify | Indicate
|-------------------------------|------|-------|--------|-----------
| Date Time                     |  Y   |       |        | 
| Alarm Clock Control Point     |      | Y     | Y      |
| Protocol Revision             | Y    |       |        |


## Date Time Characteristic
Characteristic UUID: `2A08`

Represents the current Date and Time as reported by the device clock. This characteristic follows the [org.bluetooth.characteristic.date_time](https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.date_time.xml) specification. 

## Alarm Clock Control Point
Characteristic UUID: `e4616b0c-22d5-11e4-a7bf-b2227cce2b54`

| Field name  | Format              | 
|-------------|---------------------|
| Op Code     | [8bit][FormatTypes] |
| Operator    | [uint8][FormatTypes]|
| Operand     | Variable            |


### Alarm Clock Control Point Op Codes
<a href="opcodes"> </a>

| Value  | Info                              | Operator   | Operand  | Response Value |
|--------|-----------------------------------|------------|----------|---|
| 1      | Report maximum supported alarms   |            |          | Alarm Count |
| 2      | Report number of alarms defined   |            |          | Alarm Count |
| 3      | Read alarm                        | Alarm ID   |          | |
| 4      | Add alarm                         |            | Alarm Date Time |
| 5      | Remove alarm                      | Alarm ID   | |
| 6      | Remove all alarms                 |            | |
| 7      | Set system Date Time              |            | System Date Time |
| 0      | Reserved                          |            |  |
| 8-255  | Reserved                          |            | |

Each write to this Control Point shall contain an Op Code and optionally one or both the Operator and the Operand.

For example, Add Alarm is sent as follows: [Op Code=3] [Operand=date_time]. This operation does not require an operator, so the op code is followed immediately by the operand.

### Alarm Clock Control Point Response Format
Each response follows the next format:

| Field name  | Format              | Info
|----------------|---------------------|--------------- 
| Response Code  | [8bit][FormatTypes] | See [Response Codes](#response_codes) |
| Response Value | Variable            | See [Response Values](#response_values) |


### Alarm Clock Control Point Response Codes
<a href="response_codes"> </a>

| Value  | Info
|--------|-------------
| 1      | Success |
| 2      | Op Code not supported |
| 3      | Invalid operator (returned if the Alarm ID is invalid)|
| 0      | Reserved |
| 5-255  | Reserved |

### Alarm Clock Control Point Operators and Response Values
<a href="response_values"> </a>

| Value Type           | Format   | Info    
| -------------------- | -------- | -------------- 
| Alarm ID             | [uint8][FormatTypes]| Unique identifier of the alarm on the device |
| Alarm Date Time  | | [org.bluetooth.characteristic.date_time][date_time] |
| Alarm Count | [uint8][FormatTypes] | The number of alarms matching the requested op code |
| System Date Time  | | [org.bluetooth.characteristic.date_time][date_time] |

Note: the next revision of this service is expected to specify alarm notification types, e.g. vibrating motor mode, sound to play, light mode, etc.


## Protocol Revision Characteristic
Characteristic UUID: `3b8e7983-133a-4a0f-90fc-82006ed55505`

This characteristic is a constant value. It defines the revision number of the current service specification. The service protocol may be updated with each specification revision.

| Field name            | Format                  | Info
|-----------------------|-------------------------| -------------- 
| Protocol Revision     | [uint8][FormatTypes]    | 0-255



[FormatTypes]:https://developer.bluetooth.org/gatt/Pages/FormatTypes.aspx

[date_time]:https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.date_time.xml