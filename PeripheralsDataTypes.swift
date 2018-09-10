/*
********************************************************************************

Software License Agreement

Copyright © 2015 Microchip Technology Inc. and its licensors.  All
rights reserved.

Microchip licenses to you the right to: (1) install Software on a single
computer and use the Software with Microchip microcontrollers and
digital signal controllers ("Microchip Product"); and (2) at your
own discretion and risk, use, modify, copy and distribute the device
driver files of the Software that are provided to you in Source Code;
provided that such Device Drivers are only used with Microchip Products
and that no open source or free software is incorporated into the Device
Drivers without Microchip's prior written consent in each instance.

You should refer to the license agreement accompanying this Software for
additional information regarding your rights and obligations.

SOFTWARE AND DOCUMENTATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION, ANY
WARRANTY OF MERCHANTABILITY, TITLE, NON-INFRINGEMENT AND FITNESS FOR A
PARTICULAR PURPOSE. IN NO EVENT SHALL MICROCHIP OR ITS LICENSORS BE
LIABLE OR OBLIGATED UNDER CONTRACT, NEGLIGENCE, STRICT LIABILITY,
CONTRIBUTION, BREACH OF WARRANTY, OR OTHER LEGAL EQUITABLE THEORY ANY
DIRECT OR INDIRECT DAMAGES OR EXPENSES INCLUDING BUT NOT LIMITED TO ANY
INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES, LOST PROFITS OR
LOST DATA, COST OF PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY,
SERVICES, ANY CLAIMS BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY
DEFENSE THEREOF), OR OTHER SIMILAR COSTS.

********************************************************************************
*/

//
//  Created by JM on 3/2/15.
//

import Foundation
import CoreBluetooth

struct PeripheralAttributes {
    var service: CBService
    var characteristics: [CBCharacteristic]
    var characteristicsValues: [String]
}

struct PeripheralsStructure {
    var peripheralInstance: CBPeripheral?
    var peripheralRSSI: NSNumber?
    var timeStamp: Date?
}

struct DataLog {
    var characteristicsValue = [String](repeating: "", count: 0)
    var timestampValue = [Date](repeating: Date(), count: 0)
}

let bleStandardUUIDs = [
    "1811"		:		"Alert Notification Service"							,
    "180F"		:       "Battery Service"                                   	,
    "1810"		:       "Blood Pressure"                                    	,
    "181B"		:       "Body Composition"                                  	,
    "181E"		:       "Bond Management"                                   	,
    "181F"		:       "Continuous Glucose Monitoring"                     	,
    "1805"		:       "Current Time Service"                              	,
    "1818"		:       "Cycling Power"                                     	,
    "1816"		:       "Cycling Speed and Cadence"                         	,
    "180A"		:       "Device Information"                                	,
    "181A"		:       "Environmental Sensing"                             	,
    "1800"		:       "Generic Access"                                    	,
    "1801"		:       "Generic Attribute"                                 	,
    "1808"		:       "Glucose"                                           	,
    "1809"		:       "Health Thermometer"                                	,
    "180D"		:       "Heart Rate"                                        	,
    "1812"		:       "Human Interface Device"                            	,
    "1802"		:       "Immediate Alert"                                   	,
    "1820"		:       "Internet Protocol Support"                         	,
    "1803"		:       "Link Loss"                                         	,
    "1819"		:       "Location and Navigation"                           	,
    "1807"		:       "Next DST Change Service"                           	,
    "180E"		:       "Phone Alert Status Service"                        	,
    "1806"		:       "Reference Time Update Service"                     	,
    "1814"		:       "Running Speed and Cadence"                         	,
    "1813"		:       "Scan Parameters"                                   	,
    "1804"		:       "Tx Power"                                          	,
    "181C"		:       "User Data"                                         	,
    "181D"		:       "Weight Scale"                                      	,
    "1815"		:       "Automation IO"                                     	,
    //"xxxx"		:       "Indoor Positioning"                                ,
    //"xxxx"		:       "Object Transfer"                                   ,
    
    "2A7E"		:		"Aerobic Heart Rate Lower Limit"						,
    "2A84"		:       "Aerobic Heart Rate Upper Limit"						,
    "2A7F"		:       "Aerobic Threshold"										,
    "2A80"		:       "Age"													,
    "2A43"		:       "Alert Category ID"										,
    "2A42"		:       "Alert Category ID Bit Mask"							,
    "2A06"		:       "Alert Level"											,
    "2A44"		:       "Alert Notification Control Point"						,
    "2A3F"		:       "Alert Status"											,
    "2A81"		:       "Anaerobic Heart Rate Lower Limit"						,
    "2A82"		:       "Anaerobic Heart Rate Upper Limit"						,
    "2A83"		:       "Anaerobic Threshold"									,
    "2A73"		:       "Apparent Wind Direction†"                              ,
    "2A72"		:       "Apparent Wind Speed"                                   ,
    "2A01"		:       "Appearance"                                            ,
    "2AA3"		:       "Barometric Pressure Trend"                             ,
    "2A19"		:       "Battery Level"                                         ,
    "2A49"		:       "Blood Pressure Feature"                                ,
    "2A35"		:       "Blood Pressure Measurement"                            ,
    "2A9B"		:       "Body Composition Feature"                              ,
    "2A9C"		:       "Body Composition Measurement"                          ,
    "2A38"		:       "Body Sensor Location"                                  ,
    "2AA4"		:       "Bond Management Control Point"							,
    "2AA5"		:       "Bond Management Feature"                               ,
    "2A22"		:       "Boot Keyboard Input Report"                            ,
    "2A32"		:       "Boot Keyboard Output Report"                           ,
    "2A33"		:       "Boot Mouse Input Report"                               ,
    "2AA6"		:       "Central Address Resolution"                            ,
    "2AA8"		:       "CGM Feature"                                           ,
    "2AA7"		:       "CGM Measurement"                                       ,
    "2AAB"		:       "CGM Session Run Time"                                  ,
    "2AAA"		:       "CGM Session Start Time"                                ,
    "2AAC"		:       "CGM Specific Ops Control Point"                        ,
    "2AA9"		:       "CGM Status"                                            ,
    "2A5C"		:       "CSC Feature"                                           ,
    "2A5B"		:       "CSC Measurement"                                       ,
    "2A2B"		:       "Current Time"                                          ,
    "2A66"		:       "Cycling Power Control Point"                           ,
    "2A65"		:       "Cycling Power Feature"                                 ,
    "2A63"		:       "Cycling Power Measurement"                             ,
    "2A64"		:       "Cycling Power Vector"                                  ,
    "2A99"		:       "Database Change Increment"                             ,
    "2A85"		:       "Date of Birth"                                         ,
    "2A86"		:       "Date of Threshold Assessment"                          ,
    "2A08"		:       "Date Time"												,
    "2A0A"		:       "Day Date Time"                                         ,
    "2A09"		:       "Day of Week"                                           ,
    "2A7D"		:       "Descriptor Value Changed"                              ,
    "2A00"		:       "Device Name"                                           ,
    "2A7B"		:       "Dew Point"                                             ,
    "2A0D"		:       "DST Offset"                                            ,
    "2A6C"		:       "Elevation"                                             ,
    "2A87"		:       "Email Address"                                         ,
    "2A0C"		:       "Exact Time 256"                                        ,
    "2A88"		:       "Fat Burn Heart Rate Lower Limit"                       ,
    "2A89"		:       "Fat Burn Heart Rate Upper Limit"                       ,
    "2A26"		:       "Firmware Revision String"                              ,
    "2A8A"		:       "First Name"                                            ,
    "2A8B"		:       "Five Zone Heart Rate Limits"                           ,
    "2A8C"		:       "Gender"                                                ,
    "2A51"		:       "Glucose Feature"                                       ,
    "2A18"		:       "Glucose Measurement"                                   ,
    "2A34"		:       "Glucose Measurement Context"                           ,
    "2A74"		:       "Gust Factor"                                           ,
    "2A27"		:       "Hardware Revision String"                              ,
    "2A39"		:       "Heart Rate Control Point"                              ,
    "2A8D"		:       "Heart Rate Max"										,
    "2A37"		:       "Heart Rate Measurement"                                ,
    "2A7A"		:       "Heat Index"                                            ,
    "2A8E"		:       "Height"                                                ,
    "2A4C"		:       "HID Control Point"                                     ,
    "2A4A"		:       "HID Information"                                       ,
    "2A8F"		:       "Hip Circumference"                                     ,
    "2A6F"		:       "Humidity"                                              ,
    "2A2A"		:       "IEEE 11073-20601 Regulatory Certification Data List"   ,
    "2A36"		:       "Intermediate Cuff Pressure"                            ,
    "2A1E"		:       "Intermediate Temperature"                              ,
    "2A77"		:       "Irradiance"                                            ,
    "2AA2"		:       "Language"                                              ,
    "2A90"		:       "Last Name"                                             ,
    "2A6B"		:       "LN Control Point"                                      ,
    "2A6A"		:       "LN Feature"                                            ,
    "2A0F"		:       "Local Time Information"                                ,
    "2A67"		:       "Location and Speed"                                    ,
    "2A2C"		:       "Magnetic Declination"                                  ,
    "2AA0"		:       "Magnetic Flux Density - 2D"                            ,
    "2AA1"		:       "Magnetic Flux Density - 3D"                            ,
    "2A29"		:       "Manufacturer Name String"                              ,
    "2A91"		:       "Maximum Recommended Heart Rate"                        ,
    "2A21"		:       "Measurement Interval"                                  ,
    "2A24"		:       "Model Number String"                                   ,
    "2A68"		:       "Navigation"                                            ,
    "2A46"		:       "New Alert"                                             ,
    "2A04"		:       "Peripheral Preferred Connection Parameters"            ,
    "2A02"		:       "Peripheral Privacy Flag"                               ,
    "2A50"		:       "PnP ID"                                                ,
    "2A75"		:       "Pollen Concentration"                                  ,
    "2A69"		:       "Position Quality"                                      ,
    "2A6D"		:       "Pressure"                                              ,
    "2A4E"		:       "Protocol Mode"                                         ,
    "2A78"		:       "Rainfall"                                              ,
    "2A03"		:       "Reconnection Address"                                  ,
    "2A52"		:       "Record Access Control Point"                           ,
    "2A14"		:       "Reference Time Information"                            ,
    "2A4D"		:       "Report"                                                ,
    "2A4B"		:       "Report Map"                                            ,
    "2A92"		:       "Resting Heart Rate"                                    ,
    "2A40"		:       "Ringer Control Point"                                  ,
    "2A41"		:       "Ringer Setting"                                        ,
    "2A54"		:       "RSC Feature"                                           ,
    "2A53"		:       "RSC Measurement"                                       ,
    "2A55"		:       "SC Control Point"                                      ,
    "2A4F"		:       "Scan Interval Window"                                  ,
    "2A31"		:       "Scan Refresh"                                          ,
    "2A5D"		:       "Sensor Location"                                       ,
    "2A25"		:       "Serial Number String"                                  ,
    "2A05"		:       "Service Changed"                                       ,
    "2A28"		:       "Software Revision String"                              ,
    "2A93"		:       "Sport Type for Aerobic and Anaerobic Thresholds"       ,
    "2A47"		:       "Supported New Alert Category"                          ,
    "2A48"		:       "Supported Unread Alert Category"                       ,
    "2A23"		:       "System ID"                                             ,
    "2A6E"		:       "Temperature"                                           ,
    "2A1C"		:       "Temperature Measurement"                               ,
    "2A1D"		:       "Temperature Type"                                      ,
    "2A94"		:       "Three Zone Heart Rate Limits"                          ,
    "2A12"		:       "Time Accuracy"                                         ,
    "2A13"		:       "Time Source"                                           ,
    "2A16"		:       "Time Update Control Point"                             ,
    "2A17"		:       "Time Update State"                                     ,
    "2A11"		:       "Time with DST"                                         ,
    "2A0E"		:       "Time Zone"                                             ,
    "2A71"		:       "True Wind Direction"									,
    "2A70"		:       "True Wind Speed"                                       ,
    "2A95"		:       "Two Zone Heart Rate Limit"                             ,
    "2A07"		:       "Tx Power Level"                                        ,
    "2A45"		:       "Unread Alert Status"                                   ,
    "2A9F"		:       "User Control Point"                                    ,
    "2A9A"		:       "User Index"                                            ,
    "2A76"		:       "UV Index"                                              ,
    "2A96"		:       "VO2 Max"                                               ,
    "2A97"		:       "Waist Circumference"                                   ,
    "2A98"		:       "Weight"                                                ,
    "2A9D"		:       "Weight Measurement"                                    ,
    "2A9E"		:       "Weight Scale Feature"                                  ,
    "2A79"		:       "Wind Chill"                                            ,
    "2A5A"		:       "Aggregate"                                             ,
    //"xxxx"		:       "Altitude"                                          ,
    "2A58"		:       "Analog"                                                ,
    "2A56"		:       "Digital"                                               ,
    /*
    "xxxx"		:       "Floor Number"                                          ,
    "xxxx"		:       "Indoor Positioning Configuration"                      ,
    "xxxx"		:       "Latitude"                                              ,
    "xxxx"		:       "LE Protocol Service Multiplexer"                       ,
    "xxxx"		:       "Local East"                                            ,
    "xxxx"		:       "Local North"                                           ,
    "xxxx"		:       "Location Name"                                         ,
    "xxxx"		:       "Longitude"                                             ,
    "xxxx"		:       "Object Action Control Point"                           ,
    "xxxx"		:       "Object Allocated Size"                                 ,
    "xxxx"		:       "Object Changed"                                        ,
    "xxxx"		:       "Object Checksum"                                       ,
    "xxxx"		:       "Object First-Created"                                  ,
    "xxxx"		:       "Object ID"                                             ,
    "xxxx"		:       "Object Last-Accessed"                                  ,
    "xxxx"		:       "Object Last-Modified"                                  ,
    "xxxx"		:       "Object List Control Point"                             ,
    "xxxx"		:       "Object List Filter"                                    ,
    "xxxx"		:       "Object Name"                                           ,
    "xxxx"		:       "Object Properties"                                     ,
    "xxxx"		:       "Object Type"                                           ,
    "xxxx"		:       "Octet Offset"                                          ,
    "xxxx"		:       "OTS Feature"                                           ,
    "xxxx"		:       "Uncertainty"                                           ,
    */
]
