---
layout: page
title: Política de Privacidade de Dados
subtitle: Em vigor desde 11 de outubro de 2026
permalink: /meditate_app_data_privacy/
share-title: Política de Privacidade de Dados do aplicativo | Meditação & Exercícios de Respiração (Garmin)
share-description: Política de privacidade do aplicativo Meditação & Exercícios de Respiração para relógios Garmin (dados coletados, uso, retenção e seus direitos).
---

No geigl.online, sua privacidade é importante para mim. Esta Política de Privacidade explica como coleto, uso e protejo suas informações pessoais quando você usa meu [aplicativo de meditação](/meditate_app/) no seu dispositivo Garmin.

Este texto é uma tradução. Em caso de divergência, prevalece a versão em inglês.

**1. Informações que coleto**

O aplicativo não se conecta à internet por conta própria. Todas as solicitações de rede são feitas pelo aplicativo Garmin Connect no celular pareado. Por isso, todo servidor que recebe uma solicitação vê o endereço IP público do seu celular no momento da conexão.

Quando você usa meu aplicativo de meditação, posso coletar algumas informações automaticamente. Após cada sessão salva, o aplicativo envia um evento de análise que inclui:
* O [identificador único da Garmin](https://developer.garmin.com/connect-iq/api-docs/Toybox/System/DeviceSettings.html#uniqueIdentifier-var), exclusivo para cada aplicativo e dispositivo
* Seu endereço IP, anonimizado no relógio conforme descrito abaixo; o Google Analytics usa esse endereço para estimar sua localização aproximada (país, região e cidade). Essa informação é omitida se a consulta falhar
* Dados básicos da sessão: duração e horário de término
* Versão do aplicativo, versão da API Connect IQ, versão do firmware e idioma do sistema
* Tipo de dispositivo (número de peça da Garmin), resolução da tela e sistema operacional
* Um identificador de sessão baseado no horário de término
* Padrões de uso dentro do aplicativo
* Se você é desenvolvedor, pode consultar o código-fonte correspondente [aqui](https://github.com/floriangeigl/Meditate/tree/main/Meditate/source/com)

Os eventos ficam armazenados no relógio (no máximo 10, por até 71 horas) até que o celular esteja acessível. Depois, são enviados juntos. O evento não contém frequência cardíaca, HRV, stress, respiração, nomes de atividades, configurações da sessão nem quaisquer outros dados de saúde ou de atividade.

Uso o Google Analytics para entender como as pessoas interagem com meu aplicativo. O Google vê o endereço IP do seu celular no momento da conexão e pode coletar outros dados técnicos, conforme descrito em sua [Política de Privacidade](https://policies.google.com/privacy).

Para consultar o endereço IP do seu celular, o aplicativo usa o GeoJS (desde outubro de 2026). Ele envia uma solicitação para `https://get.geojs.io/v1/ip.json` no máximo uma vez por tentativa de envio: após cada sessão salva e quando o aplicativo é iniciado enquanto há eventos aguardando envio. A resposta contém apenas o endereço IP público do seu celular; o GeoJS vê esse endereço completo no momento da conexão. O aplicativo anonimiza o endereço IP no relógio antes de usá-lo: no IPv4, o último bloco é definido como 0 (por exemplo, 203.0.113.0); no IPv6, apenas os três primeiros blocos (/48) são mantidos. O endereço IP completo não é armazenado nem encaminhado. O GeoJS afirma que não mantém registros de acesso, apenas registros de erros, e que está sujeito à Lei de Privacidade da Austrália de 1988 (Privacy Act 1988). Para saber mais, consulte a [Política de Privacidade do GeoJS](https://www.geojs.io/privacy/).

Antes de outubro de 2026, o aplicativo usava o ipapi.co: o ipapi.co via o endereço IP completo do seu celular, e o aplicativo enviava ao Google Analytics apenas o país, a região e a cidade retornados, não o endereço IP. Para saber mais, consulte a [Política de Privacidade do ipapi.co](https://ipapi.co/privacy/).

No máximo uma vez por mês, após um mês em que você tenha meditado por pelo menos 15 minutos, e somente quando o celular estiver conectado, o aplicativo abre minha [página de contribuições](/tipme/) no seu celular. O link contém os minutos de meditação do mês anterior (arredondados para cima até um número inteiro) no parâmetro `meditate-minutes`, além de `utm_source=meditate_app`, `utm_medium=garmin_watch` e `utm_campaign=tip`. Como a página de contribuições faz parte do meu site, o Google Analytics do site (veja abaixo) registra o endereço da página, incluindo esses parâmetros.

O aplicativo também contém uma ferramenta oculta de backup na nuvem que uso para desenvolvimento. Ela não faz parte dos menus normais do aplicativo e só pode ser acessada ao manter pressionada a tela Sobre. Somente quando você inicia um backup nessa tela, o aplicativo envia suas configurações, suas sessões salvas, seus minutos mensais de meditação e a rotina aprendida (referente, no máximo, às últimas 100 sessões salvas em um período de 90 dias: qual foi a sessão, a data e o horário de início, sua duração em minutos e qual sessão você concluiu até uma hora antes dela, se houver) para um banco de dados [Firebase](https://firebase.google.com/support/privacy) Realtime Database (operado pelo Google). Esses dados são armazenados sob o mesmo identificador único da Garmin mencionado acima. Nada é enviado automaticamente ao Firebase. Com exceção da página de contribuições e desse backup, seus minutos mensais de meditação permanecem no relógio; com exceção desse backup, a rotina aprendida permanece no relógio.

Meu site, incluindo a página de contribuições, usa o Google Analytics para entender como os visitantes o utilizam. Os sinais do Google e a personalização de anúncios estão desativados.

Uso a Cloudflare como rede de distribuição de conteúdo (CDN) e provedora de segurança para que meu site seja disponibilizado de forma rápida e segura. Quando você acessa meu site, sua solicitação passa pelos servidores da Cloudflare, que podem registrar temporariamente seu endereço IP e outras informações técnicas para fins de segurança e desempenho. A Cloudflare trata esses dados em meu nome e não os utiliza para nenhuma outra finalidade. Para saber mais, consulte a [Política de Privacidade da Cloudflare](https://www.cloudflare.com/privacypolicy/).

Uso redes públicas de distribuição de conteúdo (CDNs), como jsDelivr ou CDNJS, para carregar recursos estáticos como jQuery e Bootstrap. Essas CDNs podem registrar temporariamente informações técnicas, como seu endereço IP, para disponibilizar o conteúdo de forma eficiente. Essas informações não são usadas para rastreamento nem para análise.

**2. Como uso suas informações**

Coleto e uso essas informações para:
* Analisar e melhorar o desempenho e a facilidade de uso do meu aplicativo
* Entender como as pessoas interagem com o aplicativo
* Melhorar sua experiência geral de uso

Uso sua localização aproximada (país, região e cidade), junto com o idioma do sistema, para:
* Decidir quais traduções do aplicativo manter, atualizar ou adicionar
* Adaptar a página de contribuições, por exemplo, suas moedas e formas de pagamento
* Decidir em quais países e mercados de lojas de aplicativos divulgar o aplicativo
* Saber quais leis de privacidade se aplicam às pessoas que usam meu aplicativo
* Detectar e filtrar tráfego falso nos dados de análise, que muitas vezes vem de países incomuns ou se concentra em locais específicos
* Entender em que horário local as pessoas meditam, o que exige conhecer seu fuso horário
* Identificar padrões sazonais de uso, por exemplo, entre os hemisférios norte e sul

As bases legais previstas no Regulamento Geral sobre a Proteção de Dados (RGPD) são:
* Análise de uso do aplicativo, incluindo a consulta de IP pelo GeoJS (antes de outubro de 2026: a consulta de localização pelo ipapi.co): meu interesse legítimo em entender como o aplicativo é usado e melhorá-lo (Art. 6(1)(f) RGPD). O aplicativo não tem uma configuração para desativar a análise de uso; você pode se opor a qualquer momento por e-mail (veja a seção 5).
* Página de contribuições: meu interesse legítimo em pedir apoio voluntário ao aplicativo (Art. 6(1)(f) RGPD).
* Análise de uso do site: seu consentimento dado por meio do banner de cookies no meu site (Art. 6(1)(a) RGPD), que você pode retirar a qualquer momento.
* Backup na nuvem: sua solicitação ao iniciar um backup (Art. 6(1)(b) RGPD).

Não tomo decisões automatizadas sobre você que produzam efeitos jurídicos ou outros efeitos igualmente significativos (Art. 22 RGPD).

**3. Compartilhamento de dados**

Não vendo nem compartilho suas informações pessoais com terceiros para fins de marketing. Os eventos de análise descritos acima são enviados ao Google Analytics, a consulta de IP é feita pelo GeoJS (antes de outubro de 2026: pelo ipapi.co), e os backups que você inicia são armazenados no Firebase.

**4. Retenção de dados**

Não mantenho os dados de análise por mais tempo do que o necessário. O período de retenção dos dados no Google Analytics (do aplicativo e do site) está atualmente definido em 14 meses para permitir a análise das tendências de uso ao longo de um ano. O GeoJS afirma que não mantém registros de acesso, apenas registros de erros. O ipapi.co (usado antes de outubro de 2026) mantém registros de solicitações por um período limitado, conforme descrito em sua [Política de Privacidade](https://ipapi.co/privacy/). Os backups no Firebase não são excluídos automaticamente; eles são mantidos até que você me peça para excluí-los.

**5. Seus direitos**

Dependendo de onde você mora, você pode ter o direito de:
* Acessar os dados que tenho sobre você
* Solicitar a correção ou exclusão dos seus dados
* Restringir o tratamento dos seus dados
* Receber seus dados em um formato portátil
* Retirar seu consentimento para o tratamento de dados
* Opor-se ao tratamento baseado no meu interesse legítimo, incluindo a análise de uso do aplicativo
* Apresentar uma reclamação a uma autoridade supervisora de proteção de dados, especialmente no Estado-membro da UE onde você mora ou trabalha

Para exercer seus direitos, entre em contato comigo pelo e-mail florian.geigl+privacy@gmail.com

**6. Segurança dos dados**

Adoto medidas adequadas para proteger seus dados contra acesso, alteração, divulgação ou destruição não autorizados.

**7. Usuários internacionais**

Trato seus dados de acordo com o Regulamento Geral sobre a Proteção de Dados (RGPD). Alguns dos serviços que uso tratam dados nos EUA:
* O Google (Google Analytics, Firebase) e a Cloudflare são certificados pelo Quadro de Privacidade de Dados UE-EUA (EU-U.S. Data Privacy Framework).
* O ipapi.co (usado antes de outubro de 2026) é operado pela Kloudend, Inc. (EUA). De acordo com sua Política de Privacidade, essas transferências são regidas por Cláusulas Contratuais Padrão.

O GeoJS está sujeito à Lei de Privacidade da Austrália de 1988 (Privacy Act 1988).

O aplicativo anonimiza seu endereço IP no relógio antes de enviá-lo ao Google Analytics.

**8. Alterações nesta política**

Posso atualizar esta Política de Privacidade de tempos em tempos. A versão revisada será publicada nesta página com a data de entrada em vigor atualizada.

**9. Entre em contato**

Se você tiver alguma dúvida sobre esta Política de Privacidade ou seus dados, pode entrar em contato comigo por:
* 📧 E-mail: florian.geigl+privacy@gmail.com
* 🌐 Site: https://geigl.online
