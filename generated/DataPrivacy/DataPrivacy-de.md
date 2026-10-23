---
layout: page
title: Datenschutzerklärung
subtitle: Gültig ab 11. Oktober 2026
permalink: /meditate_app_data_privacy/
share-title: Datenschutzerklärung der App | Meditation & Atemübungen (Garmin)
share-description: Datenschutzerklärung für die Garmin-Uhren-App Meditation & Atemübungen (erhobene Daten, Nutzung, Speicherdauer und deine Rechte).
---

Bei geigl.online ist mir deine Privatsphäre wichtig. Diese Datenschutzerklärung erläutert, wie ich personenbezogene Daten erhebe, nutze und schütze, wenn du meine [Meditations-App](/meditate_app/) auf deinem Garmin-Gerät verwendest.

Dies ist eine Übersetzung. Rechtlich maßgeblich ist die englische Fassung.

**1. Welche Daten ich erhebe**

Die App stellt selbst keine Verbindung zum Internet her. Alle Netzwerkanfragen werden von der Garmin Connect App auf deinem gekoppelten Smartphone gesendet. Deshalb sieht jeder Server, der eine Anfrage erhält, beim Verbindungsaufbau die öffentliche IP-Adresse deines Smartphones.

Wenn du meine Meditations-App nutzt, kann ich bestimmte Daten automatisch erheben. Nach jeder gespeicherten Session sendet die App ein Analyseereignis mit folgenden Angaben:
* Die [eindeutige Kennung von Garmin](https://developer.garmin.com/connect-iq/api-docs/Toybox/System/DeviceSettings.html#uniqueIdentifier-var), die für jede App und jedes Gerät einmalig ist
* Deine IP-Adresse, die wie unten beschrieben auf deiner Uhr anonymisiert wird; Google Analytics leitet daraus deinen ungefähren Standort ab (Land, Region und Stadt). Falls die Abfrage fehlschlägt, entfällt diese Angabe
* Grundlegende Angaben zur Session: ihre Dauer und der Zeitpunkt, zu dem sie endete
* App-Version, Connect IQ API-Version, Firmware-Version und Systemsprache
* Gerätetyp (Garmin-Artikelnummer), Bildschirmauflösung und Betriebssystem
* Eine Sitzungskennung, die auf dem Zeitpunkt basiert, zu dem die Session endete
* Nutzungsmuster innerhalb der App
* Wenn du selbst entwickelst, kannst du dir den betreffenden Quellcode gern [hier](https://github.com/floriangeigl/Meditate/tree/main/Meditate/source/com) ansehen

Ereignisse bleiben auf deiner Uhr gespeichert (höchstens 10 und höchstens 71 Stunden lang), bis dein Smartphone erreichbar ist. Dann werden sie gemeinsam gesendet. Das Ereignis enthält weder Herzfrequenz, HRV, stress, Atemfrequenz, Aktivitätsnamen, Session-Einstellungen noch andere Gesundheits- oder Aktivitätsdaten.

Ich nutze Google Analytics, um besser zu verstehen, wie Menschen meine App verwenden. Google sieht beim Verbindungsaufbau die IP-Adresse deines Smartphones und kann weitere technische Daten erfassen, wie in der [Datenschutzerklärung von Google](https://policies.google.com/privacy) beschrieben.

Um die IP-Adresse deines Smartphones abzufragen, nutzt die App seit Oktober 2026 GeoJS. Sie sendet höchstens eine Anfrage pro Sendeversuch an `https://get.geojs.io/v1/ip.json`: nach jeder gespeicherten Session und beim Start der App, wenn noch nicht gesendete Ereignisse warten. Die Antwort enthält nur die öffentliche IP-Adresse deines Smartphones. GeoJS sieht diese vollständige IP-Adresse beim Verbindungsaufbau. Die App anonymisiert die IP-Adresse auf deiner Uhr, bevor sie sie verwendet: Bei IPv4 wird der letzte Block auf 0 gesetzt (z. B. 203.0.113.0), bei IPv6 bleiben nur die ersten drei Blöcke (/48) erhalten. Die vollständige IP-Adresse wird weder gespeichert noch weitergeleitet. GeoJS gibt an, keine Zugriffsprotokolle, sondern nur Fehlerprotokolle zu speichern, und unterliegt dem australischen Privacy Act 1988. Weitere Informationen findest du in der [Datenschutzerklärung von GeoJS](https://www.geojs.io/privacy/).

Vor Oktober 2026 nutzte die App stattdessen ipapi.co: ipapi.co sah die vollständige IP-Adresse deines Smartphones. Die App sendete an Google Analytics nur das von ipapi.co zurückgegebene Land, die Region und die Stadt, nicht die IP-Adresse. Weitere Informationen findest du in der [Datenschutzerklärung von ipapi.co](https://ipapi.co/privacy/).

Höchstens einmal im Monat öffnet die App meine [Trinkgeldseite](/tipme/) auf deinem Smartphone, sofern du im vorangegangenen Monat mindestens 15 Minuten meditiert hast und dein Smartphone verbunden ist. Der Link enthält die Meditationsminuten des vorangegangenen Monats (auf eine ganze Zahl aufgerundet) als Parameter `meditate-minutes` sowie `utm_source=meditate_app`, `utm_medium=garmin_watch` und `utm_campaign=tip`. Da die Trinkgeldseite Teil meiner Website ist, erfasst das Google Analytics der Website (siehe unten) die Seitenadresse einschließlich dieser Parameter.

Die App enthält außerdem ein verborgenes Cloud-Backup-Werkzeug, das ich für die Entwicklung nutze. Es gehört nicht zu den regulären App-Menüs und ist nur durch langes Drücken auf den Info-Bildschirm erreichbar. Nur wenn du dort selbst ein Backup auslöst, lädt die App ihre Einstellungen, deine gespeicherten Sessions, deine monatlichen Meditationsminuten und die erlernte Routine in eine [Firebase](https://firebase.google.com/support/privacy) Realtime Database (betrieben von Google) hoch. Die erlernte Routine umfasst höchstens die letzten 100 gespeicherten Sessions innerhalb von 90 Tagen: um welche Session es sich handelte, wann sie begann, ihre Länge in Minuten und gegebenenfalls welche Session du bis zu einer Stunde davor abgeschlossen hattest. Die Daten werden unter derselben eindeutigen Garmin-Kennung wie oben gespeichert. Es wird nichts automatisch an Firebase gesendet. Abgesehen von der Trinkgeldseite und diesem Backup bleiben deine monatlichen Meditationsminuten auf deiner Uhr. Abgesehen von diesem Backup bleibt die erlernte Routine auf deiner Uhr.

Meine Website, einschließlich der Trinkgeldseite, verwendet Google Analytics, um zu verstehen, wie Besucher sie nutzen. Google-Signale und personalisierte Werbung sind deaktiviert.

Ich nutze Cloudflare als Content Delivery Network (CDN) und Sicherheitsanbieter, damit meine Website schnell und sicher ausgeliefert wird. Wenn du meine Website aufrufst, wird deine Anfrage über Server von Cloudflare geleitet. Cloudflare kann dabei deine IP-Adresse und andere technische Informationen vorübergehend für Sicherheits- und Leistungszwecke protokollieren. Cloudflare verarbeitet diese Daten in meinem Auftrag und nutzt sie nicht für andere Zwecke. Weitere Informationen findest du in der [Datenschutzerklärung von Cloudflare](https://www.cloudflare.com/privacypolicy/).

Ich nutze öffentliche Content Delivery Networks (CDNs) wie jsDelivr oder CDNJS, um statische Ressourcen wie jQuery und Bootstrap zu laden. Diese CDNs können technische Informationen wie deine IP-Adresse vorübergehend protokollieren, um Inhalte effizient auszuliefern. Diese Informationen werden weder zur Nachverfolgung noch zu Analysezwecken verwendet.

**2. Wie ich deine Daten verwende**

Ich erhebe und nutze diese Daten, um:
* Die Leistung und Bedienbarkeit meiner App zu analysieren und zu verbessern
* Zu verstehen, wie Menschen die App nutzen
* Das Nutzungserlebnis insgesamt zu verbessern

Deinen ungefähren Standort (Land, Region und Stadt) nutze ich zusammen mit deiner Systemsprache, um:
* Zu entscheiden, welche Übersetzungen der App ich beibehalte, pflege oder ergänze
* Die Trinkgeldseite anzupassen, etwa ihre Währungen und Zahlungsmethoden
* Zu entscheiden, in welchen Ländern und App-Store-Märkten ich die App bewerbe
* Zu wissen, welche Datenschutzgesetze für die Menschen gelten, die meine App nutzen
* Gefälschten Analyse-Traffic zu erkennen und herauszufiltern, der häufig aus ungewöhnlichen Ländern oder aus Häufungen an einzelnen Orten stammt
* Zu verstehen, zu welcher lokalen Tageszeit Menschen meditieren, wofür ihre Zeitzone erforderlich ist
* Saisonale Nutzungsmuster zu erkennen, etwa Unterschiede zwischen der Nord- und Südhalbkugel

Die Rechtsgrundlagen nach der Datenschutz-Grundverordnung (DSGVO) sind:
* App-Analyse einschließlich der IP-Abfrage über GeoJS (vor Oktober 2026: der Standortabfrage über ipapi.co): mein berechtigtes Interesse daran, zu verstehen, wie die App genutzt wird, und sie zu verbessern (Art. 6(1)(f) DSGVO). Die App bietet keine Einstellung, um die Analyse zu deaktivieren. Du kannst ihr jederzeit per E-Mail widersprechen (siehe Abschnitt 5).
* Trinkgeldseite: mein berechtigtes Interesse daran, um freiwillige Unterstützung für die App zu bitten (Art. 6(1)(f) DSGVO).
* Website-Analyse: deine Einwilligung über das Cookie-Banner auf meiner Website (Art. 6(1)(a) DSGVO), die du jederzeit widerrufen kannst.
* Cloud-Backup: deine eigene Anfrage, wenn du ein Backup startest (Art. 6(1)(b) DSGVO).

Ich treffe keine automatisierten Entscheidungen über dich, die rechtliche oder ähnlich erhebliche Auswirkungen haben (Art. 22 DSGVO).

**3. Weitergabe von Daten**

Ich verkaufe deine personenbezogenen Daten nicht und gebe sie nicht zu Marketingzwecken an Dritte weiter. Die oben beschriebenen Analyseereignisse werden an Google Analytics gesendet, die IP-Abfrage erfolgt über GeoJS (vor Oktober 2026: ipapi.co), und Backups, die du selbst auslöst, werden in Firebase gespeichert.

**4. Speicherdauer**

Ich speichere Analysedaten nicht länger als nötig. Die Speicherdauer für Daten in Google Analytics (App und Website) ist derzeit auf 14 Monate eingestellt, um Nutzungstrends im Laufe eines Jahres zu verstehen. GeoJS gibt an, keine Zugriffsprotokolle, sondern nur Fehlerprotokolle zu speichern. ipapi.co (vor Oktober 2026 verwendet) speichert Anfrageprotokolle für begrenzte Zeit, wie in seiner [Datenschutzerklärung](https://ipapi.co/privacy/) beschrieben. Backups in Firebase werden nicht automatisch gelöscht. Sie bleiben gespeichert, bis du mich bittest, sie zu löschen.

**5. Deine Rechte**

Je nach deinem Aufenthaltsort hast du möglicherweise das Recht:
* Auskunft über die Daten zu erhalten, die ich über dich gespeichert habe
* Die Berichtigung oder Löschung deiner Daten zu verlangen
* Die Verarbeitung deiner Daten einzuschränken
* Deine Daten in einem übertragbaren Format zu erhalten
* Deine Einwilligung zur Datenverarbeitung zu widerrufen
* Einer Verarbeitung auf Grundlage meines berechtigten Interesses zu widersprechen, einschließlich der App-Analyse
* Eine Beschwerde bei einer Datenschutzaufsichtsbehörde einzureichen, insbesondere in dem EU-Mitgliedstaat, in dem du wohnst oder arbeitest

Um deine Rechte auszuüben, kontaktiere mich bitte unter florian.geigl+privacy@gmail.com

**6. Datensicherheit**

Ich treffe geeignete Maßnahmen, um deine Daten vor unbefugtem Zugriff, Veränderung, Offenlegung oder Vernichtung zu schützen.

**7. Nutzerinnen und Nutzer aus verschiedenen Ländern**

Ich verarbeite deine Daten gemäß der Datenschutz-Grundverordnung (DSGVO). Einige der von mir genutzten Dienste verarbeiten Daten in den USA:
* Google (Google Analytics, Firebase) und Cloudflare sind nach dem EU-U.S. Data Privacy Framework zertifiziert.
* ipapi.co (vor Oktober 2026 verwendet) wird von Kloudend, Inc. (USA) betrieben. Laut der Datenschutzerklärung von ipapi.co gelten für diese Datenübermittlungen Standardvertragsklauseln.

GeoJS unterliegt dem australischen Privacy Act 1988.

Die App anonymisiert deine IP-Adresse auf deiner Uhr, bevor sie sie an Google Analytics sendet.

**8. Änderungen dieser Datenschutzerklärung**

Ich kann diese Datenschutzerklärung von Zeit zu Zeit aktualisieren. Die überarbeitete Fassung wird mit einem aktualisierten Gültigkeitsdatum auf dieser Seite veröffentlicht.

**9. Kontakt**

Wenn du Fragen zu dieser Datenschutzerklärung oder deinen Daten hast, kannst du mich hier erreichen:
* 📧 E-Mail: florian.geigl+privacy@gmail.com
* 🌐 Website: https://geigl.online
