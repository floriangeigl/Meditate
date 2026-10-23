---
layout: page
title: Política de privacidad de datos
subtitle: Fecha de entrada en vigor: 11 de octubre de 2026
permalink: /meditate_app_data_privacy/
share-title: Política de privacidad de datos de la aplicación | Meditación & Ejercicios de respiración (Garmin)
share-description: Política de privacidad de la aplicación Meditación & Ejercicios de respiración para relojes Garmin (datos recopilados, uso, conservación y tus derechos).
---

En geigl.online, tu privacidad es importante para mí. Esta Política de privacidad explica cómo recopilo, uso y protejo tu información personal cuando utilizas mi [aplicación de meditación](/meditate_app/) en tu dispositivo Garmin.

Esta es una traducción. En caso de discrepancia, prevalece la versión en inglés.

**1. Información que recopilo**

La aplicación no se conecta a internet por sí sola. Todas las solicitudes de red las realiza la aplicación Garmin Connect en tu teléfono vinculado. Por eso, todos los servidores que reciben una solicitud pueden ver la dirección IP pública de tu teléfono al establecerse la conexión.

Cuando utilizas mi aplicación de meditación, puedo recopilar cierta información de forma automática. Después de cada sesión guardada, la aplicación envía un evento de análisis que incluye:
* El [identificador único de Garmin](https://developer.garmin.com/connect-iq/api-docs/Toybox/System/DeviceSettings.html#uniqueIdentifier-var), que es distinto para cada aplicación y dispositivo
* Tu dirección IP, anonimizada en tu reloj como se explica más abajo; Google Analytics obtiene a partir de ella tu ubicación aproximada (país, región y ciudad). Se omite si la consulta falla
* Datos básicos de la sesión: su duración y la hora a la que terminó
* Versión de la aplicación, versión de la API de Connect IQ, versión del firmware e idioma del sistema
* Tipo de dispositivo (número de pieza de Garmin), resolución de pantalla y sistema operativo
* Un identificador de sesión basado en la hora a la que terminó
* Patrones de uso dentro de la aplicación
* Si desarrollas software, puedes consultar el código fuente correspondiente [aquí](https://github.com/floriangeigl/Meditate/tree/main/Meditate/source/com)

Los eventos permanecen en tu reloj (como máximo 10, durante un máximo de 71 horas) hasta que se puede establecer conexión con tu teléfono. Entonces se envían juntos. Los eventos no contienen frecuencia cardíaca, HRV, estrés, respiración, nombres de actividades, ajustes de las sesiones ni ningún otro dato de salud o actividad.

Uso Google Analytics para entender cómo interactúan las personas con mi aplicación. Google puede ver la dirección IP de tu teléfono al establecerse la conexión y puede recopilar otros datos técnicos, según se describe en su [Política de privacidad](https://policies.google.com/privacy).

Para consultar la dirección IP de tu teléfono, la aplicación utiliza GeoJS (desde octubre de 2026). Envía una solicitud a `https://get.geojs.io/v1/ip.json` como máximo una vez por cada intento de envío: después de cada sesión guardada y al iniciar la aplicación si hay eventos pendientes de envío. La respuesta contiene únicamente la dirección IP pública de tu teléfono; GeoJS puede ver la dirección IP completa al establecerse la conexión. La aplicación anonimiza la dirección IP en tu reloj antes de usarla: en IPv4, sustituye el último bloque por 0 (por ejemplo, 203.0.113.0); en IPv6, conserva solo los tres primeros bloques (/48). La dirección IP completa no se almacena ni se reenvía. GeoJS afirma que no conserva registros de acceso, solo registros de errores, y que está sujeto a la Ley de Privacidad de Australia de 1988 (Privacy Act 1988). Para obtener más información, consulta la [Política de privacidad de GeoJS](https://www.geojs.io/privacy/).

Antes de octubre de 2026, la aplicación utilizaba ipapi.co: ipapi.co podía ver la dirección IP completa de tu teléfono, y la aplicación solo enviaba a Google Analytics el país, la región y la ciudad que devolvía el servicio, no la dirección IP. Para obtener más información, consulta la [Política de privacidad de ipapi.co](https://ipapi.co/privacy/).

Como máximo una vez al mes, después de un mes en el que hayas meditado al menos 15 minutos y solo cuando tu teléfono esté conectado, la aplicación abre mi [página de contribuciones](/tipme/) en tu teléfono. El enlace incluye los minutos que meditaste el mes anterior (redondeados al siguiente número entero) en el parámetro `meditate-minutes`, además de `utm_source=meditate_app`, `utm_medium=garmin_watch` y `utm_campaign=tip`. Como la página de contribuciones forma parte de mi sitio web, Google Analytics del sitio (consulta más abajo) registra la dirección de la página, incluidos estos parámetros.

La aplicación también incluye una herramienta oculta de copia de seguridad en la nube que utilizo durante el desarrollo. No aparece en los menús habituales de la aplicación y solo se puede acceder a ella manteniendo pulsada la pantalla Acerca de. Solo si tú mismo inicias una copia de seguridad desde allí, la aplicación sube sus ajustes, tus sesiones guardadas, tus minutos mensuales de meditación y la rutina aprendida (correspondiente, como máximo, a las últimas 100 sesiones guardadas en un plazo de 90 días: qué sesión fue, la fecha y hora a la que comenzó, su duración en minutos y, si la hubo, qué sesión terminaste hasta una hora antes de ella) a una base de datos Realtime Database de [Firebase](https://firebase.google.com/support/privacy) (operada por Google). Estos datos se almacenan bajo el mismo identificador único de Garmin mencionado antes. No se envía nada a Firebase automáticamente. Aparte de lo que se envía a la página de contribuciones y en esta copia de seguridad, tus minutos mensuales de meditación permanecen en tu reloj. Aparte de esta copia de seguridad, la rutina aprendida permanece en tu reloj.

Mi sitio web, incluida la página de contribuciones, utiliza Google Analytics para entender cómo lo usan los visitantes. Las señales de Google y la personalización de anuncios están desactivadas.

Uso Cloudflare como red de distribución de contenido (CDN) y proveedor de seguridad para que mi sitio web se entregue de forma rápida y segura. Cuando accedes a mi sitio web, tu solicitud pasa por los servidores de Cloudflare, que pueden registrar temporalmente tu dirección IP y otros datos técnicos por motivos de seguridad y rendimiento. Cloudflare trata estos datos por cuenta mía y no los utiliza para ningún otro fin. Para obtener más información, consulta la [Política de privacidad de Cloudflare](https://www.cloudflare.com/privacypolicy/).

Uso redes públicas de distribución de contenido (CDN), como jsDelivr o CDNJS, para cargar recursos estáticos como jQuery y Bootstrap. Estas CDN pueden registrar temporalmente datos técnicos, como tu dirección IP, para entregar el contenido de manera eficiente. Esta información no se utiliza para seguimiento ni análisis.

**2. Cómo uso tu información**

Recopilo y uso esta información para:
* Analizar y mejorar el rendimiento y la facilidad de uso de mi aplicación
* Entender cómo interactúan las personas con la aplicación
* Mejorar tu experiencia general al usarla

Uso tu ubicación aproximada (país, región y ciudad), junto con el idioma de tu sistema, para:
* Decidir qué traducciones de la aplicación conservar, mantener o añadir
* Adaptar la página de contribuciones, por ejemplo, sus monedas y métodos de pago
* Decidir en qué países y mercados de tiendas de aplicaciones promocionar la aplicación
* Saber qué leyes de privacidad se aplican a quienes usan mi aplicación
* Detectar y filtrar tráfico de análisis falso, que suele proceder de países poco habituales o concentrarse en torno a ubicaciones concretas
* Entender a qué hora local del día meditan las personas, para lo que necesito conocer su zona horaria
* Identificar patrones de uso estacionales, por ejemplo, entre los hemisferios norte y sur

Las bases jurídicas conforme al Reglamento General de Protección de Datos (RGPD) son:
* Análisis de la aplicación, incluida la consulta de la IP mediante GeoJS (antes de octubre de 2026: la consulta de la ubicación mediante ipapi.co): mi interés legítimo en entender cómo se usa la aplicación y mejorarla (art. 6(1)(f) del RGPD). La aplicación no tiene un ajuste para desactivar el análisis; puedes oponerte en cualquier momento por correo electrónico (consulta la sección 5).
* Página de contribuciones: mi interés legítimo en solicitar apoyo voluntario para la aplicación (art. 6(1)(f) del RGPD).
* Análisis del sitio web: el consentimiento que otorgas a través del aviso de cookies de mi sitio web (art. 6(1)(a) del RGPD), que puedes retirar en cualquier momento.
* Copia de seguridad en la nube: tu propia solicitud al iniciar una copia de seguridad (art. 6(1)(b) del RGPD).

No tomo decisiones automatizadas sobre ti que tengan efectos jurídicos o de importancia similar (art. 22 del RGPD).

**3. Comunicación de datos**

No vendo ni comparto tu información personal con terceros para fines de marketing. Los eventos de análisis descritos anteriormente se envían a Google Analytics, GeoJS realiza la consulta de la IP (antes de octubre de 2026: ipapi.co) y las copias de seguridad que tú mismo inicias se almacenan en Firebase.

**4. Conservación de datos**

Conservo los datos de análisis solo durante el tiempo necesario. El periodo de conservación de datos de Google Analytics (aplicación y sitio web) está configurado actualmente en 14 meses para entender las tendencias de uso a lo largo de un año. GeoJS afirma que no conserva registros de acceso, solo registros de errores. ipapi.co (utilizado antes de octubre de 2026) conserva los registros de solicitudes durante un tiempo limitado, según se describe en su [Política de privacidad](https://ipapi.co/privacy/). Las copias de seguridad de Firebase no se eliminan automáticamente; se conservan hasta que me pidas que las elimine.

**5. Tus derechos**

Según dónde te encuentres, puedes tener derecho a:
* Acceder a los datos que tengo sobre ti
* Solicitar la rectificación o eliminación de tus datos
* Limitar el tratamiento de tus datos
* Recibir tus datos en un formato portable
* Retirar tu consentimiento para el tratamiento de datos
* Oponerte al tratamiento basado en mi interés legítimo, incluido el análisis de la aplicación
* Presentar una reclamación ante una autoridad de control de protección de datos, en particular en el Estado miembro de la UE donde vives o trabajas

Para ejercer tus derechos, escríbeme a florian.geigl+privacy@gmail.com

**6. Seguridad de los datos**

Tomo medidas adecuadas para proteger tus datos frente al acceso, la modificación, la divulgación o la destrucción no autorizados.

**7. Usuarios internacionales**

Trato tus datos de conformidad con el Reglamento General de Protección de Datos (RGPD). Algunos de los servicios que utilizo tratan datos en Estados Unidos:
* Google (Google Analytics, Firebase) y Cloudflare están certificados conforme al Marco de Privacidad de Datos UE-EE. UU. (EU-U.S. Data Privacy Framework).
* ipapi.co (utilizado antes de octubre de 2026) está operado por Kloudend, Inc. (Estados Unidos). Según su Política de privacidad, estas transferencias se rigen por cláusulas contractuales tipo.

GeoJS está sujeto a la Ley de Privacidad de Australia de 1988 (Privacy Act 1988).

La aplicación anonimiza tu dirección IP en tu reloj antes de enviarla a Google Analytics.

**8. Cambios en esta política**

Puedo actualizar esta Política de privacidad de vez en cuando. La versión revisada se publicará en esta página con una fecha de entrada en vigor actualizada.

**9. Contacto**

Si tienes alguna pregunta sobre esta Política de privacidad o tus datos, puedes contactar conmigo en:
* 📧 Correo electrónico: florian.geigl+privacy@gmail.com
* 🌐 Sitio web: https://geigl.online
