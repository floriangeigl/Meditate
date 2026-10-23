---
layout: page
title: Informativa sulla privacy dei dati
subtitle: In vigore dall'11 ottobre 2026
permalink: /meditate_app_data_privacy/
share-title: Informativa sulla privacy dei dati dell'app | Meditazione & Esercizi di respirazione (Garmin)
share-description: Informativa sulla privacy dell'app Meditazione & Esercizi di respirazione per orologi Garmin (dati raccolti, utilizzo, conservazione e tuoi diritti).
---

Su geigl.online, la tua privacy è importante per me. Questa informativa spiega come raccolgo, utilizzo e proteggo i tuoi dati personali quando usi la mia [app di meditazione](/meditate_app/) sul tuo dispositivo Garmin.

Questa è una traduzione dell'informativa. Fa fede la versione in inglese.

**1. Informazioni che raccolgo**

L'app non si connette a Internet autonomamente. Tutte le richieste di rete vengono effettuate dall'app Garmin Connect sul telefono associato, quindi ogni server che riceve una richiesta vede l'indirizzo IP pubblico del tuo telefono a livello di connessione.

Quando usi la mia app di meditazione, potrei raccogliere automaticamente alcune informazioni. Dopo ogni sessione salvata, l'app invia un evento di analisi che include:
* L'[identificativo univoco di Garmin](https://developer.garmin.com/connect-iq/api-docs/Toybox/System/DeviceSettings.html#uniqueIdentifier-var), specifico per ciascuna app e ciascun dispositivo
* Il tuo indirizzo IP, anonimizzato sull'orologio come descritto di seguito; Google Analytics ne ricava la tua posizione approssimativa (Paese, regione e città). Se la ricerca non riesce, questo dato non viene incluso
* Dati essenziali della sessione: durata e ora di conclusione
* Versione dell'app, versione dell'API Connect IQ, versione del firmware e lingua del sistema
* Tipo di dispositivo (numero di parte Garmin), risoluzione dello schermo e sistema operativo
* Un identificativo della sessione basato sull'ora in cui si è conclusa
* Modalità di utilizzo dell'app
* Se sei uno sviluppatore, puoi consultare il codice sorgente pertinente [qui](https://github.com/floriangeigl/Meditate/tree/main/Meditate/source/com)

Gli eventi restano sull'orologio (al massimo 10, per non più di 71 ore) finché il telefono non è raggiungibile, poi vengono inviati insieme. L'evento non contiene frequenza cardiaca, HRV, stress, respirazione, nomi delle attività, impostazioni delle sessioni né altri dati relativi alla salute o all'attività fisica.

Uso Google Analytics per capire come le persone interagiscono con la mia app. Google vede l'indirizzo IP del tuo telefono a livello di connessione e potrebbe raccogliere ulteriori dati tecnici, come descritto nella sua [Informativa sulla privacy](https://policies.google.com/privacy).

Per ottenere l'indirizzo IP del tuo telefono, l'app usa GeoJS (da ottobre 2026). Invia una richiesta a `https://get.geojs.io/v1/ip.json` al massimo una volta per ogni tentativo di invio: dopo ogni sessione salvata e quando l'app si avvia mentre ci sono eventi in attesa di invio. La risposta contiene soltanto l'indirizzo IP pubblico del tuo telefono; GeoJS vede l'indirizzo IP completo a livello di connessione. L'app anonimizza l'indirizzo IP sull'orologio prima di utilizzarlo: per IPv4, l'ultimo blocco viene impostato su 0 (per esempio 203.0.113.0); per IPv6, vengono conservati solo i primi tre blocchi (/48). L'indirizzo IP completo non viene memorizzato né inoltrato. GeoJS dichiara di non conservare i registri degli accessi, ma solo quelli degli errori, e di essere soggetta alla legge australiana sulla privacy del 1988 (Privacy Act 1988). Per maggiori informazioni, consulta l'[Informativa sulla privacy di GeoJS](https://www.geojs.io/privacy/).

Prima di ottobre 2026, l'app usava invece ipapi.co: ipapi.co vedeva l'indirizzo IP completo del tuo telefono e l'app inviava a Google Analytics soltanto il Paese, la regione e la città restituiti dal servizio, non l'indirizzo IP. Per maggiori informazioni, consulta l'[Informativa sulla privacy di ipapi.co](https://ipapi.co/privacy/).

Al massimo una volta al mese, dopo un mese in cui hai meditato per almeno 15 minuti, e solo quando il telefono è connesso, l'app apre sul telefono la mia [pagina per lasciare una mancia](/tipme/). Il link contiene i minuti di meditazione del mese precedente (arrotondati per eccesso a un numero intero) nel parametro `meditate-minutes`, oltre a `utm_source=meditate_app`, `utm_medium=garmin_watch` e `utm_campaign=tip`. Poiché la pagina per lasciare una mancia fa parte del mio sito, Google Analytics del sito (vedi sotto) registra l'indirizzo della pagina, compresi questi parametri.

L'app contiene anche uno strumento nascosto di backup nel cloud che uso per lo sviluppo. Non compare nei normali menu dell'app ed è accessibile solo tenendo premuta la schermata Informazioni. Solo quando avvii tu stesso un backup da quella schermata, l'app carica le proprie impostazioni, le tue sessioni salvate, i tuoi minuti di meditazione mensili e la routine appresa (per un massimo delle ultime 100 sessioni salvate nell'arco di 90 giorni: quale sessione era, data e ora di inizio, durata in minuti e quale sessione, se presente, avevi concluso nell'ora precedente) in un database Realtime di [Firebase](https://firebase.google.com/support/privacy) (gestito da Google). I dati vengono memorizzati sotto lo stesso identificativo univoco Garmin indicato sopra. Nulla viene inviato automaticamente a Firebase. A parte la pagina per lasciare una mancia e questo backup, i tuoi minuti di meditazione mensili restano sull'orologio; a parte questo backup, anche la routine appresa resta sull'orologio.

Il mio sito web, compresa la pagina per lasciare una mancia, usa Google Analytics per capire come viene utilizzato dai visitatori. Google Signals e la personalizzazione degli annunci sono disattivati.

Uso Cloudflare come rete per la distribuzione dei contenuti (CDN) e fornitore di servizi di sicurezza per distribuire il mio sito web in modo rapido e sicuro. Quando accedi al sito, la tua richiesta passa attraverso i server di Cloudflare, che potrebbero registrare temporaneamente il tuo indirizzo IP e altre informazioni tecniche per motivi di sicurezza e prestazioni. Cloudflare tratta questi dati per mio conto e non li utilizza per altri scopi. Per maggiori informazioni, consulta l'[Informativa sulla privacy di Cloudflare](https://www.cloudflare.com/privacypolicy/).

Uso reti pubbliche per la distribuzione dei contenuti (CDN), come jsDelivr o CDNJS, per caricare risorse statiche come jQuery e Bootstrap. Queste CDN potrebbero registrare temporaneamente informazioni tecniche, come il tuo indirizzo IP, per distribuire i contenuti in modo efficiente. Queste informazioni non vengono utilizzate per il tracciamento o l'analisi statistica.

**2. Come utilizzo le tue informazioni**

Raccolgo e utilizzo queste informazioni per:
* Analizzare e migliorare le prestazioni e la facilità d'uso della mia app
* Capire come le persone interagiscono con l'app
* Migliorare la tua esperienza complessiva con l'app

Uso la tua posizione approssimativa (Paese, regione e città), insieme alla lingua del sistema, per:
* Decidere quali traduzioni dell'app mantenere, aggiornare o aggiungere
* Adattare la pagina per lasciare una mancia, per esempio le valute e i metodi di pagamento
* Decidere in quali Paesi e mercati degli app store promuovere l'app
* Sapere quali leggi sulla privacy si applicano alle persone che usano la mia app
* Rilevare e filtrare il traffico di analisi fittizio, che spesso proviene da Paesi insoliti o si concentra attorno a singole località
* Capire in quale momento della giornata, secondo l'ora locale, le persone meditano, per cui è necessario conoscere il loro fuso orario
* Riconoscere le variazioni stagionali nell'utilizzo, per esempio tra l'emisfero settentrionale e quello meridionale

Le basi giuridiche previste dal Regolamento generale sulla protezione dei dati (GDPR) sono:
* Analisi dell'app, inclusa la ricerca dell'indirizzo IP tramite GeoJS (prima di ottobre 2026: la ricerca della posizione tramite ipapi.co): il mio legittimo interesse a capire come viene usata l'app e a migliorarla (Art. 6(1)(f) GDPR). L'app non dispone di un'impostazione per disattivare l'analisi; puoi opporti in qualsiasi momento via email (vedi sezione 5).
* Pagina per lasciare una mancia: il mio legittimo interesse a chiedere un sostegno volontario per l'app (Art. 6(1)(f) GDPR).
* Analisi del sito web: il consenso che esprimi tramite il banner dei cookie sul mio sito (Art. 6(1)(a) GDPR), che puoi revocare in qualsiasi momento.
* Backup nel cloud: la richiesta che fai quando avvii un backup (Art. 6(1)(b) GDPR).

Non prendo decisioni automatizzate che ti riguardano e che producano effetti giuridici o analogamente significativi (Art. 22 GDPR).

**3. Condivisione dei dati**

Non vendo né condivido i tuoi dati personali con terzi per finalità di marketing. Gli eventi di analisi descritti sopra vengono inviati a Google Analytics, la ricerca dell'indirizzo IP viene effettuata tramite GeoJS (prima di ottobre 2026: ipapi.co) e i backup che avvii tu stesso vengono conservati in Firebase.

**4. Conservazione dei dati**

Conservo i dati di analisi solo per il tempo necessario. Il periodo di conservazione dei dati di Google Analytics (dell'app e del sito web) è attualmente impostato su 14 mesi, per capire le tendenze di utilizzo nell'arco di un anno. GeoJS dichiara di non conservare i registri degli accessi, ma solo quelli degli errori. ipapi.co (usato prima di ottobre 2026) conserva i registri delle richieste per un periodo limitato, come descritto nella [sua Informativa sulla privacy](https://ipapi.co/privacy/). I backup in Firebase non vengono eliminati automaticamente: restano conservati finché non mi chiedi di eliminarli.

**5. I tuoi diritti**

A seconda di dove ti trovi, potresti avere il diritto di:
* Accedere ai dati che conservo su di te
* Chiedere la rettifica o la cancellazione dei tuoi dati
* Limitare il trattamento dei tuoi dati
* Ricevere i tuoi dati in un formato portabile
* Revocare il consenso al trattamento dei dati
* Opporti al trattamento basato sul mio legittimo interesse, inclusa l'analisi dell'app
* Presentare un reclamo a un'autorità di controllo per la protezione dei dati, in particolare nello Stato membro dell'UE in cui vivi o lavori

Per esercitare i tuoi diritti, contattami all'indirizzo florian.geigl+privacy@gmail.com

**6. Sicurezza dei dati**

Adotto misure adeguate per proteggere i tuoi dati da accessi, modifiche, divulgazioni o distruzioni non autorizzati.

**7. Utenti internazionali**

Tratto i tuoi dati nel rispetto del Regolamento generale sulla protezione dei dati (GDPR). Alcuni servizi che utilizzo trattano dati negli Stati Uniti:
* Google (Google Analytics, Firebase) e Cloudflare sono certificati nell'ambito del Quadro UE-USA per la protezione dei dati (EU-U.S. Data Privacy Framework).
* ipapi.co (usato prima di ottobre 2026) è gestito da Kloudend, Inc. (USA). Secondo la sua Informativa sulla privacy, questi trasferimenti sono regolati dalle Clausole contrattuali standard.

GeoJS è soggetta alla legge australiana sulla privacy del 1988 (Privacy Act 1988).

L'app anonimizza il tuo indirizzo IP sull'orologio prima di inviarlo a Google Analytics.

**8. Modifiche a questa informativa**

Potrei aggiornare periodicamente questa informativa sulla privacy. La versione aggiornata sarà pubblicata su questa pagina con una nuova data di entrata in vigore.

**9. Contatti**

Se hai domande su questa informativa sulla privacy o sui tuoi dati, puoi contattarmi:
* 📧 Email: florian.geigl+privacy@gmail.com
* 🌐 Sito web: https://geigl.online
