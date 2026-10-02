import re

path = "android/app/src/main/AndroidManifest.xml"
with open(path, encoding="utf-8") as f:
    xml = f.read()

permissions = """    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="com.android.alarm.permission.SET_ALARM"/>
    <queries>
        <intent>
            <action android:name="android.speech.RecognitionService"/>
        </intent>
        <intent>
            <action android:name="android.intent.action.TTS_SERVICE"/>
        </intent>
    </queries>
"""

if "RECORD_AUDIO" not in xml:
    xml = xml.replace("<application", permissions + "    <application", 1)

xml = re.sub(r'android:label="[^"]*"', 'android:label="CAPITÃO_MAYBANK"', xml, count=1)

with open(path, "w", encoding="utf-8") as f:
    f.write(xml)
print("Manifest ajustado")
