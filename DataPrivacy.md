---
layout: page
title: Data Privacy Policy
subtitle: Effective Date: 4th Oct 2026
permalink: /meditate_app_data_privacy/
share-title: App Data Privacy Policy | Meditation & Breathwork (Garmin)
share-description: Privacy policy for the Meditation & Breathwork Garmin watch app (data collected, usage, retention, and your rights).
---

At geigl.online, your privacy is important to me. This Privacy Policy explains how I collect, use, and protect your personal information when you use my [Meditation app](/meditate_app/) on your Garmin device.

**1. Information I Collect**

The app does not connect to the internet by itself. All network requests are made by the Garmin Connect app on your paired phone, so every server that receives a request sees your phone's public IP address at the connection level.

When you use my Meditation app, I may collect certain information automatically. After each saved session, the app sends one analytics event, including:
* [Garmin's unique identifier](https://developer.garmin.com/connect-iq/api-docs/Toybox/System/DeviceSettings.html#uniqueIdentifier-var) that is unique per app and device
* Your IP address, anonymised on your watch as described below; Google Analytics derives your approximate location (country, region and city) from it. Left out if the lookup fails
* Basic session metrics: the session duration and the time the session ended
* App version, Connect IQ API version, firmware version and system language
* Device type (Garmin part number), screen resolution and operating system
* A session identifier based on the time the session ended
* Usage patterns within the app
* If you are a developer, feel free to look at the relevant source code [here](https://github.com/floriangeigl/Meditate/tree/main/Meditate/source/com)

Events are kept on your watch (at most 10, for at most 71 hours) until your phone is reachable, and are then sent together. The event does not contain heart rate, HRV, stress, respiration, activity names, session settings or any other health or activity data.

I use Google Analytics to help me understand how users interact with my app. Google sees your phone's IP address at the connection level and may collect additional technical data as described in their [Privacy Policy](https://policies.google.com/privacy).

To look up your phone's IP address, the app uses GeoJS (since October 2026). It sends a request to `https://get.geojs.io/v1/ip.json` at most once per send attempt: after each saved session, and when the app starts while unsent events are waiting. The answer contains only your phone's public IP address; GeoJS sees this full IP address at the connection level. The app anonymises the IP address on your watch before using it: for IPv4 the last block is set to 0 (e.g. 203.0.113.0), for IPv6 only the first three blocks (/48) are kept. The full IP address is not stored and not forwarded. GeoJS states that it keeps no access logs, only error logs, and that it is subject to Australia's Privacy Act 1988. For more information, please see [GeoJS's Privacy Policy](https://www.geojs.io/privacy/).

Before October 2026, the app used ipapi.co instead: ipapi.co saw your phone's full IP address, and the app sent only the country, region and city it returned to Google Analytics, not the IP address. For more information, please see [ipapi.co's Privacy Policy](https://ipapi.co/privacy/).

At most once a month, after a month with at least 15 minutes of meditation, and only when your phone is connected, the app opens my [tip page](/tipme/) on your phone. The link contains last month's meditation minutes (rounded up to a whole number) as the parameter `meditate-minutes`, plus `utm_source=meditate_app`, `utm_medium=garmin_watch` and `utm_campaign=tip`. Because the tip page is part of my website, the website's Google Analytics (see below) records the page address including these parameters.

The app also contains a hidden cloud backup tool that I use for development. It is not part of the regular app menus and can only be reached by long-pressing the About screen. Only when you trigger a backup there yourself, the app uploads its settings, your saved sessions and your monthly meditation minutes to a [Firebase](https://firebase.google.com/support/privacy) Realtime Database (operated by Google), stored under the same Garmin unique identifier as above. Nothing is sent to Firebase automatically. Apart from the tip page and this backup, your monthly meditation minutes stay on your watch.

My website, including the tip page, uses Google Analytics to understand how visitors use it. Google signals and ad personalization are turned off.

I use Cloudflare as a content delivery network (CDN) and security provider to ensure the fast and secure delivery of my website. When you access my website, your request is routed through Cloudflare's servers, which may temporarily log your IP address and other technical information for security and performance purposes. Cloudflare acts as a data processor on my behalf and does not use this data for any other purpose. For more information, please see [Cloudflare's Privacy Policy](https://www.cloudflare.com/privacypolicy/).

I use public content delivery networks (CDNs), such as jsDelivr or CDNJS, to load static resources like jQuery and Bootstrap. These CDNs may temporarily log technical information such as your IP address to serve content efficiently. This information is not used for tracking or analytics purposes.

**2. How I Use Your Information**

I collect and use this information to:
* Analyze and improve the performance and usability of my app
* Understand how users interact with the app
* Enhance your overall user experience

I use your approximate location (country, region and city), together with your system language, to:
* Decide which translations of the app to keep, maintain or add
* Adapt the tip page, for example its currencies and payment methods
* Decide in which countries and app store markets to promote the app
* Know which privacy laws apply to my users
* Detect and filter fake analytics traffic, which often comes from unusual countries or clusters around single locations
* Understand at what local time of day people meditate, which requires their time zone
* Recognise seasonal usage patterns, for example between the northern and southern hemisphere

The legal bases under the General Data Protection Regulation (GDPR) are:
* App analytics, including the IP lookup via GeoJS (before October 2026: the location lookup via ipapi.co): my legitimate interest in understanding how the app is used and improving it (Art. 6(1)(f) GDPR). The app has no setting to turn analytics off; you can object at any time by email (see section 5).
* Tip page: my legitimate interest in asking for voluntary support of the app (Art. 6(1)(f) GDPR).
* Website analytics: your consent given via the cookie banner on my website (Art. 6(1)(a) GDPR), which you can withdraw at any time.
* Cloud backup: your own request when you start a backup (Art. 6(1)(b) GDPR).

I do not make automated decisions about you that have legal or similarly significant effects (Art. 22 GDPR).

**3. Data Sharing**

I do not sell or share your personal information with third parties for marketing purposes. The analytics events described above are sent to Google Analytics, the IP lookup is done by GeoJS (before October 2026: ipapi.co), and backups you trigger yourself are stored in Firebase.

**4. Data Retention**

I retain analytics data for no longer than necessary. Google Analytics data retention (app and website) is currently set to 14 months to understand usage trends over the course of a year. GeoJS states that it keeps no access logs, only error logs. ipapi.co (used before October 2026) keeps request logs for a limited time, as described in [its Privacy Policy](https://ipapi.co/privacy/). Backups in Firebase are not deleted automatically; they are kept until you ask me to delete them.

**5. Your Rights**

Depending on your location, you may have the right to:
* Access the data I hold about you
* Request correction or deletion of your data
* Restrict processing of your data
* Receive your data in a portable format
* Withdraw your consent to data processing
* Object to processing based on my legitimate interest, including app analytics
* Lodge a complaint with a data protection supervisory authority, in particular in the EU member state where you live or work

To exercise your rights, please contact me at florian.geigl+privacy@gmail.com

**6. Data Security**

I take appropriate measures to protect your data from unauthorized access, alteration, disclosure, or destruction.

**7. International Users**

I process your data in accordance with the General Data Protection Regulation (GDPR). Some of the services I use process data in the USA:
* Google (Google Analytics, Firebase) and Cloudflare are certified under the EU-U.S. Data Privacy Framework.
* ipapi.co (used before October 2026) is operated by Kloudend, Inc. (USA). According to its Privacy Policy, these transfers are governed by Standard Contractual Clauses.

GeoJS is subject to Australia's Privacy Act 1988.

The app anonymises your IP address on your watch before sending it to Google Analytics.

**8. Changes to This Policy**

I may update this Privacy Policy from time to time. The revised version will be posted on this page with an updated effective date.

**9. Contact Me**

If you have any questions about this Privacy Policy or your data, you can contact me at:
* 📧 Email: florian.geigl+privacy@gmail.com
* 🌐 Website: https://geigl.online