---
layout: page
title: Politique de confidentialité des données
subtitle: Date d'entrée en vigueur : 11 octobre 2026
permalink: /meditate_app_data_privacy/
share-title: Politique de confidentialité de l'application | Méditation & Respiration (Garmin)
share-description: Politique de confidentialité de l'application Méditation & Respiration pour montres Garmin (données collectées, utilisation, conservation et tes droits).
---

Sur geigl.online, ta vie privée compte pour moi. Cette politique de confidentialité explique comment je collecte, utilise et protège tes informations personnelles lorsque tu utilises mon [application de méditation](/meditate_app/) sur ton appareil Garmin.

Ce texte est une traduction. La version anglaise fait foi.

**1. Informations que je collecte**

L'application ne se connecte pas elle-même à Internet. Toutes les requêtes réseau sont effectuées par l'application Garmin Connect sur ton téléphone associé. Chaque serveur qui reçoit une requête voit donc l'adresse IP publique de ton téléphone au niveau de la connexion.

Lorsque tu utilises mon application de méditation, je peux collecter automatiquement certaines informations. Après chaque session enregistrée, l'application envoie un événement d'analyse contenant :
* L'[identifiant unique Garmin](https://developer.garmin.com/connect-iq/api-docs/Toybox/System/DeviceSettings.html#uniqueIdentifier-var), propre à chaque application et à chaque appareil
* Ton adresse IP, anonymisée sur ta montre comme indiqué ci-dessous ; Google Analytics en déduit ta localisation approximative (pays, région et ville). Cette information est omise si la recherche échoue
* Des données de base sur la session : sa durée et l'heure à laquelle elle s'est terminée
* La version de l'application, la version de l'API Connect IQ, la version du micrologiciel et la langue du système
* Le type d'appareil (référence Garmin), la résolution de l'écran et le système d'exploitation
* Un identifiant de session basé sur l'heure à laquelle la session s'est terminée
* Les habitudes d'utilisation dans l'application
* Si tu développes des applications, tu peux consulter le code source concerné [ici](https://github.com/floriangeigl/Meditate/tree/main/Meditate/source/com)

Les événements restent sur ta montre (10 au maximum, pendant 71 heures au maximum) jusqu'à ce que ton téléphone soit joignable, puis ils sont envoyés ensemble. L'événement ne contient ni fréquence cardiaque, ni HRV, ni stress, ni données respiratoires, ni noms d'activités, ni réglages de session, ni aucune autre donnée de santé ou d'activité.

J'utilise Google Analytics pour comprendre comment les utilisateurs interagissent avec mon application. Google voit l'adresse IP de ton téléphone au niveau de la connexion et peut collecter d'autres données techniques, comme indiqué dans sa [politique de confidentialité](https://policies.google.com/privacy).

Pour obtenir l'adresse IP de ton téléphone, l'application utilise GeoJS (depuis octobre 2026). Elle envoie une requête à `https://get.geojs.io/v1/ip.json` au maximum une fois par tentative d'envoi : après chaque session enregistrée et au démarrage de l'application si des événements attendent encore d'être envoyés. La réponse contient uniquement l'adresse IP publique de ton téléphone ; GeoJS voit cette adresse IP complète au niveau de la connexion. L'application anonymise l'adresse IP sur ta montre avant de l'utiliser : pour IPv4, le dernier bloc est remplacé par 0 (par exemple 203.0.113.0) ; pour IPv6, seuls les trois premiers blocs (/48) sont conservés. L'adresse IP complète n'est ni stockée ni transmise. GeoJS indique ne conserver aucun journal d'accès, seulement des journaux d'erreurs, et être soumis à la loi australienne Privacy Act 1988. Pour en savoir plus, consulte la [politique de confidentialité de GeoJS](https://www.geojs.io/privacy/).

Avant octobre 2026, l'application utilisait ipapi.co à la place : ipapi.co voyait l'adresse IP complète de ton téléphone, et l'application envoyait à Google Analytics uniquement le pays, la région et la ville renvoyés par ce service, pas l'adresse IP. Pour en savoir plus, consulte la [politique de confidentialité de ipapi.co](https://ipapi.co/privacy/).

Au maximum une fois par mois, après un mois comprenant au moins 15 minutes de méditation, et uniquement lorsque ton téléphone est connecté, l'application ouvre ma [page de soutien](/tipme/) sur ton téléphone. Le lien contient le nombre de minutes de méditation du mois précédent (arrondi à l'entier supérieur) dans le paramètre `meditate-minutes`, ainsi que `utm_source=meditate_app`, `utm_medium=garmin_watch` et `utm_campaign=tip`. Comme cette page fait partie de mon site web, le Google Analytics du site (voir ci-dessous) enregistre l'adresse de la page, y compris ces paramètres.

L'application contient également un outil caché de sauvegarde dans le cloud que j'utilise pour le développement. Il ne figure pas dans les menus habituels de l'application et n'est accessible qu'en maintenant le doigt appuyé sur l'écran À propos. Ce n'est que si tu lances toi-même une sauvegarde depuis cet écran que l'application envoie ses réglages, tes sessions enregistrées, tes minutes de méditation mensuelles et la routine apprise (pour les 100 dernières sessions enregistrées au maximum sur une période de 90 jours : la session concernée, sa date et son heure de début, sa durée en minutes et, le cas échéant, la session que tu as terminée au plus une heure avant) vers une base de données [Firebase](https://firebase.google.com/support/privacy) Realtime Database (exploitée par Google). Ces données sont stockées sous le même identifiant unique Garmin que celui mentionné plus haut. Rien n'est envoyé automatiquement à Firebase. En dehors de la page de soutien et de cette sauvegarde, tes minutes de méditation mensuelles restent sur ta montre ; en dehors de cette sauvegarde, la routine apprise reste sur ta montre.

Mon site web, y compris la page de soutien, utilise Google Analytics pour comprendre comment les visiteurs s'en servent. Les signaux Google et la personnalisation des annonces sont désactivés.

J'utilise Cloudflare comme réseau de diffusion de contenu (CDN) et fournisseur de sécurité afin que mon site web soit accessible rapidement et de façon sécurisée. Lorsque tu consultes mon site, ta requête passe par les serveurs de Cloudflare, qui peuvent enregistrer temporairement ton adresse IP et d'autres informations techniques pour des raisons de sécurité et de performance. Cloudflare agit comme sous-traitant pour mon compte et n'utilise pas ces données à d'autres fins. Pour en savoir plus, consulte la [politique de confidentialité de Cloudflare](https://www.cloudflare.com/privacypolicy/).

J'utilise des réseaux publics de diffusion de contenu (CDN), tels que jsDelivr ou CDNJS, pour charger des ressources statiques comme jQuery et Bootstrap. Ces CDN peuvent enregistrer temporairement des informations techniques, comme ton adresse IP, afin de fournir le contenu efficacement. Ces informations ne sont pas utilisées à des fins de suivi ou d'analyse.

**2. Comment j'utilise tes informations**

Je collecte et utilise ces informations pour :
* Analyser et améliorer les performances et la facilité d'utilisation de mon application
* Comprendre comment les utilisateurs interagissent avec l'application
* Améliorer ton expérience globale

J'utilise ta localisation approximative (pays, région et ville), ainsi que la langue de ton système, pour :
* Décider quelles traductions de l'application conserver, mettre à jour ou ajouter
* Adapter la page de soutien, par exemple ses devises et ses moyens de paiement
* Décider dans quels pays et sur quels marchés des boutiques d'applications promouvoir l'application
* Savoir quelles lois sur la protection de la vie privée s'appliquent à mes utilisateurs
* Détecter et filtrer le faux trafic dans les données d'analyse, qui provient souvent de pays inhabituels ou se concentre autour d'un même lieu
* Comprendre à quel moment de la journée, selon l'heure locale, les personnes méditent, ce qui nécessite de connaître leur fuseau horaire
* Repérer les variations saisonnières d'utilisation, par exemple entre les hémisphères nord et sud

Les bases légales prévues par le règlement général sur la protection des données (RGPD) sont les suivantes :
* Analyse de l'utilisation de l'application, y compris la recherche de l'adresse IP via GeoJS (avant octobre 2026 : la recherche de la localisation via ipapi.co) : mon intérêt légitime à comprendre comment l'application est utilisée et à l'améliorer (art. 6(1)(f) RGPD). L'application ne propose pas de réglage permettant de désactiver l'analyse ; tu peux t'y opposer à tout moment par e-mail (voir section 5).
* Page de soutien : mon intérêt légitime à demander un soutien volontaire pour l'application (art. 6(1)(f) RGPD).
* Analyse de l'utilisation du site web : ton consentement donné via le bandeau de cookies sur mon site web (art. 6(1)(a) RGPD), que tu peux retirer à tout moment.
* Sauvegarde dans le cloud : ta demande lorsque tu lances une sauvegarde (art. 6(1)(b) RGPD).

Je ne prends aucune décision automatisée te concernant qui produirait des effets juridiques ou des effets d'une importance comparable (art. 22 RGPD).

**3. Partage des données**

Je ne vends pas tes informations personnelles et ne les partage pas avec des tiers à des fins de marketing. Les événements d'analyse décrits ci-dessus sont envoyés à Google Analytics, la recherche de l'adresse IP est effectuée par GeoJS (avant octobre 2026 : ipapi.co), et les sauvegardes que tu déclenches toi-même sont stockées dans Firebase.

**4. Durée de conservation des données**

Je ne conserve les données d'analyse que pendant la durée nécessaire. La durée de conservation des données dans Google Analytics (application et site web) est actuellement fixée à 14 mois pour comprendre les tendances d'utilisation sur une année. GeoJS indique ne conserver aucun journal d'accès, seulement des journaux d'erreurs. ipapi.co (utilisé avant octobre 2026) conserve les journaux des requêtes pendant une durée limitée, comme indiqué dans sa [politique de confidentialité](https://ipapi.co/privacy/). Les sauvegardes dans Firebase ne sont pas supprimées automatiquement ; elles sont conservées jusqu'à ce que tu me demandes de les supprimer.

**5. Tes droits**

Selon le lieu où tu te trouves, tu peux avoir le droit de :
* Accéder aux données que je détiens à ton sujet
* Demander la rectification ou la suppression de tes données
* Limiter le traitement de tes données
* Recevoir tes données dans un format portable
* Retirer ton consentement au traitement de tes données
* T'opposer à un traitement fondé sur mon intérêt légitime, y compris l'analyse de l'utilisation de l'application
* Déposer une plainte auprès d'une autorité de contrôle de la protection des données, notamment dans l'État membre de l'UE où tu vis ou travailles

Pour exercer tes droits, contacte-moi à florian.geigl+privacy@gmail.com

**6. Sécurité des données**

Je prends les mesures appropriées pour protéger tes données contre tout accès, toute modification, toute divulgation ou toute destruction non autorisés.

**7. Utilisateurs internationaux**

Je traite tes données conformément au règlement général sur la protection des données (RGPD). Certains des services que j'utilise traitent des données aux États-Unis :
* Google (Google Analytics, Firebase) et Cloudflare sont certifiés dans le cadre du Data Privacy Framework UE-États-Unis.
* ipapi.co (utilisé avant octobre 2026) est exploité par Kloudend, Inc. (États-Unis). Selon sa politique de confidentialité, ces transferts sont encadrés par des clauses contractuelles types.

GeoJS est soumis à la loi australienne Privacy Act 1988.

L'application anonymise ton adresse IP sur ta montre avant de l'envoyer à Google Analytics.

**8. Modifications de cette politique**

Je peux mettre à jour cette politique de confidentialité de temps à autre. La version révisée sera publiée sur cette page avec une nouvelle date d'entrée en vigueur.

**9. Me contacter**

Si tu as des questions sur cette politique de confidentialité ou sur tes données, tu peux me contacter aux coordonnées suivantes :
* 📧 E-mail : florian.geigl+privacy@gmail.com
* 🌐 Site web : https://geigl.online
