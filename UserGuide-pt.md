Iy Guia do Usuário do Aplicativo Garmin

## Funcionalidades

- capacidade de salvar a sessão de meditação como atividade Garmin Connect  
   - tipo de atividade **Meditação** ou **Yoga**
- capacidade de configurar sessões de meditação/yoga múltiplas
   - ex. uma sessão de 20 min com alertas recorrentes, desencadeando um alerta diferente no 10º minuto
   - cada sessão suporta alertas para intervalos de vibração
   - alertas intervalares podem ser acionados de poucos segundos até poucas horas
- sessões padrão pré-configuradas de meditação com 5/10/15/20/25/30min e também curta vibração a cada 5min
- configurações avançadas das sessões de meditação padrão para 45min e 1h com curta vibração a cada 15min
- [HRV](https://pt.wikipedia.org/wiki/Variabilidade_da_frequ%C3%AAncia_cardiaca) (Variabilidade da Frequência Cardíaca)
   - RMSSD - Raiz quadrada média das diferenças de sucessivas (intervalos batimento-a-batimento)
   - pNN20 - % de intervalos batimento-a-batimento que diferem por mais de 20 ms
   - pNN50 - % de intervalos batimento-a-batimento que diferem por mais de 50 ms
   - intervalo batimento-a-batimento - leitura direta do sensor de relógio
   - HRV Diferenças Sucessivas - diferença entre os intervalos batimento-a-batimento atuais e anteriores
   - SDRR - [Desvio Padrão](https://pt.wikipedia.org/wiki/Desvio_padr%C3%A3o) de intervalos batimento-a-batimento 
     - calculado a partir dos primeiros e últimos 5 min da sessão
   - HRV RMSSD 30s Janela - RMSSD calculado para intervalos de 30 segundos consecutivos    
   - HR do batimento cardíaco - intervalo batimento-a-batimento convertido em HR
- rastreamento de estresse
   - Resumo de Estresse - resumo do estresse médio durante a sessão 
   - Média de estresse para o início e fim da sessão (calculada automaticamente pelo relógio para sessão de 5min ou mais)
   - HR Picos 10s Janela
     - métrica interna para calcular estresse
     - rastreia em sobreposição de 10 janelas de segundos Janela Máx HR para cada janela
     - HR calculado de intervalo batimento-a-batimento
- respiração
   - Respirações por minuto tempo real em relógios que suportam isso (funciona bem para atividade bug no Connect IQ API para atividade de Respiração)
- tempo de preparação configurável antes da sessão de meditação
- estatísticas de resumo no final da sessão 
   - Gráfico de taxa de coração incluindo min, avg e máx HR
   - Gráfico de taxa de Respiração incluindo min, avg e máx estimada taxa de respiração
   - Estresse
   - HRV
- pausar/retomar sessão atual usando o botão de volta
- capacidade de configurar nome de atividade personalizado padrão no Garmin Connect usando Garmin Express em PC conectado ao relógio via cabo

![Demonstração do Seletor de Sessão](userGuideScreenshots/sessionPickerDemo.gif)
![Demonstração do Detalhe da Sessão](userGuideScreenshots/sessionDetailedDemo.gif)

### Como Usar 
### 1. Iniciando uma Sessão

1.1. Na tela do seletor de sessão, pressione o botão de iniciar ou toque na tela (apenas dispositivos touch).

![Seletor de Sessão](userGuideScreenshots/sessionPicker.gif)

1.2. A tela de progresso da sessão contém os seguintes elementos:
- tempo decorrido arc
  - mostra a porcentagem de tempo de sessão decorrido
  - círculo completo significa que o tempo de sessão expirou
- interval alert triggers 
  - a pequena marca colorida representa o tempo de acionar um alerta intervalar
  - cada posição marcada corresponde a um alerta de acionamento
  - você pode ocultar por alerta selecionando cor transparente no [menu de configurações de alertas intervalares](#2-configurando-uma-sessão)
- tempo decorrido 
- HR atual
- diferença de HRV atual 
  - diferença entre os intervalos batimento-a-batimento atuais e anteriores medidos em milissegundos
  - mostra apenas quando o rastreamento de HRV está ativado
  - **para obter boas leituras de HRV você precisa minimizar movimentos intensos**
- estimativa de taxa de respiração atual calculada pelo relógio
   - **para obter boas leituras de respiração você precisa minimizar movimentos intensos**

A sessão de meditação termina quando você pressiona o botão de início/parada.
A sessão de meditação pode ser pausada/retomada usando o botão de volta.
Ativar/desativar a luz de tela durante a sessão usando o botão de luz ou toque na tela (apenas dispositivos touch).

![Sessão em Progresso Explicada](userGuideScreenshots/sessionInProgressExplained.gif)

1.3. Quando você para a sessão, você tem a opção de salvá-la.

1.3.1 Você pode configurar para salvar automaticamente ou descartar a sessão via [Configurações Globais](#4-global-settings) -> [Confirmar Salvar](#42-confirmar-salvar)

![Confirmar Salvar Sessão](userGuideScreenshots/confirmSaveSession.gif)

1.4. Se você está no modo de sessão única (padrão) no final você vê a Tela de Resumo (para o modo Multi-Sessão veja a próxima seção **1.5**). Deslize para cima/baixo (apenas dispositivos touch) ou pressione os botões de página para ver as estatísticas de resumo de HR, Estresse e HRV. Volte desta tela para sair do aplicativo.

![Tela de Resumo da Sessão Detalhada Demonstrada](userGuideScreenshots/sessionSummaryDetailedDemo.gif)

1.5 Se você está no modo multi-sessão (determinado por [Configurações Globais](#4-global-settings) -> [Multi-Sessão](#43-multi-session)) então você retorna à tela de seleção de sessão. A partir daí você pode iniciar outra sessão. Assim que finalizar sua sessão você pode retornar à tela do seletor de sessão para acessar a vista Resumo de Sessões.

![Rolagem de Resumo](userGuideScreenshots/summaryRollup.gif)

1.6 Da vista Resumo de Sessões você pode deslizar para baixo para ver sessões individuais ou sair do aplicativo. Deslizar para baixo mostra o estado resumido de HR, Taxa de Respiração, Estresse e HRV. Se você retornar da vista de Sumário de Sessões você pode continuar fazendo mais sessões.

### 2. Configurando uma Sessão

2.1 Na tela do seletor de sessão, segure o botão menu (meio esquerdo) até você ver o menu de configurações de sessão.
   - para dispositivos com suporte a toque de tela, é possível também tocar e manter na tela

![Menu de Configurações de Sessão](userGuideScreenshots/sessionSettingsMenu.gif)

2.2 Em Adicionar Novo/Editar você pode configurar:
- Tempo - duração total da sessão em H:MM
- Cor - a cor da sessão usada nos controles gráficos; selecionar deslizando cima/baixo comportamento no relógio (Vivoactive 3/4/Venu - desenhar deslizando cima/baixo)
- Padrão de Vibração - padrões mais curtos ou mais longos variando de pulsante ou contínuo
- Alertas Intervalares - capacidade de configurar alertas intervalares múltiplos
   - uma vez que você está em um alerta intervalar específico, você verá no menu o título ID do Alerta (ex. Alerta 1) relativo aos alertas intervalares atuais da sessão
   - Tempo 
       - selecione um alerta único ou recorrente
       - alertas recorrentes permitem durações mais curtas do que um minuto
       - apenas um alerta único será executado a qualquer tempo dado
       - prioridade dos alertas com o mesmo tempo
       - 1. alerta final de sessão
       - 2. último alerta único
       - 3. último alerta repetitivo
   - Cor - a cor do intervalo de alerta atual usado nos controles gráficos. Selecione cores diferentes para cada alerta para diferenciá-los durante a meditação. Selecione cor transparente se você não quiser ver marcas visuais para o alerta durante a meditação
   - Padrão de Vibração/Som - padrões mais curtos ou mais longos variando de pulsante ou contínuo ou som
- Tipo de Atividade - capacidade de salvar a sessão como **Meditação** ou **Yoga**. Você pode configurar um tipo de atividade padrão para novas sessões nas Configurações Globais (veja seção [4](#4-global-settings)).
- Rastreamento de HRV - determina se a HRV e o estresse estão sendo rastreados
   - ON - rastreia estresse e as métricas de HRV
     - RMSSD
     - Diferenças Sucessivas da HRV
     - SDRR (Desvio Padrão da Diferença Rítmica Sucessiva)
     - batimento-a-batimento com diferença
     - pNN50
     - pNN20
     - HR do batimento cardíaco
     - RMSSD 30 Janela seg Incremental
     - HR Picos 10 Janela Segundos
     - SDRR Primeiro 5 min da sessão
     - SDRR Último 5 min da sessão
     - RMSSD 30 Seg Janela
     - HR do batimento cardíaco
     - HR Picos 10 Seg Janela
- On Detalhado (Padrão) - rastreia estresse extra e métricas de HRV em adição à opção **On**
   - RMSSD
   - Diferenças Sucessivas da HRV
   - pNN20  
   - pNN50
   - batimento-a-batimento com diferença
   - SDRR Primeiro 5 min da sessão
   - SDRR Último 5 min da sessão
   - RMSSD 30 Seg Janela
   - HR do batimento cardíaco
   - HR Picos 10 Seg Janela

2.3 Excluir - exclui uma sessão após confirmação

2.4 Configurações Globais - [veja seção 4](#4-global-settings)

### 3. Escolhendo uma Sessão

Na tela do seletor de sessão, pressione o botão de página para cima/baixo (para dispositivos de toque swipes para cima/baixo). Nesta tela você pode ver as configurações aplicáveis para a sessão selecionada
- tipo de atividade - no título
  - Meditação
- tempo - duração total da sessão
- padrão de vibração
- alertas de disparo intervalares - o gráfico no meio da tela representa o alerta intervalar relativo ao tempo do disparador em comparação ao tempo total da sessão 
- Indicador HRV
  - ![Off](userGuideScreenshots/hrvIndicatorOff.png) Off - indica que rastreio de estresse e HRV está desativado
  - ![Esperando HRV](userGuideScreenshots/hrvIndicatorWaitingHrv.png) Aguardando HRV 
     - o sensor de hardware não detecta HRV
     - você pode iniciar a sessão mas terá falta de dados HRV, é recomendado ficar quieto até que HRV esteja pronto
  - ![HRV Leitura Pendente](userGuideScreenshots/hrvIndicatorReady.png) HRV Pendente
     - o sensor de hardware detecta HRV
     - a sessão rastreia padrão HRV e métricas de estresse
     - **a sessão pode ser gravada com dados confiáveis HRV desde que você minimize o movimento**
  - ![HRV Leitura Detalhada Pendente](userGuideScreenshots/hrvIndicatorReadyDetailed.png) HRV Leitura Detalhada  
     - o sensor de hardware detecta HRV
     - a sessão rastreia métricas HRV e Estresse estendidas
     - **a sessão pode ser gravada com dados confiáveis HRV desde que você minimize o movimento**

![Explicação do Picker de Sessão](userGuideScreenshots/sessionPickerExplained.gif)

### 4. Configurações Globais

Na tela do seletor de sessão, mantenha pressionado o botão de menu (ou toque e segure a tela) até que você veja o menu de configurações da sessão. Selecione o Menu de Configurações Globais. Você vê uma visão com os estados das configurações globais. Mantenha o botão do menu novamente (ou toque e segure a tela) para editar configurações globais.

![Configurações Globais](userGuideScreenshots/globalSettings.gif)

#### 4.1 Rastreamento de HRV

Esta configuração fornece o padrão de **Rastreamento de HRV** para novas sessões.

- **Ligado** - rastreia métricas padrão de HRV e Estresse
  - RMSSD
  - Diferenças Sucessivas
  - SDRR
- **Ligado Detalhado** - estende métricas de HRV e Estresse
  - RMSSD
  - Diferenças Sucessivas
  - SDRR
  - intervalo batimento-a-batimento
  - pNN50
  - pNN20
  - HR do batimento cardíaco
  - RMSSD 30 Seg Janela
  - HR Picos 10 Seg Janela
  - SDRR Primeiro 5 min da sessão
  - SDRR Último 5 min da sessão
- **Desligado** - HRV e rastreamento de estresse desativado

#### 4.2 Confirmar Salvar

- Perguntar - quando uma atividade finaliza pergunta se para confirmar se deseja salvar a atividade
- Auto Sim - quando uma atividade finaliza salva automaticamente
- Auto Não - quando uma atividade finaliza auto descarta a atividade

#### 4.3 Multi-Sessão

- Sim 
  - o aplicativo continua a funcionar após finalizar sessão
  - isso permite a gravação de múltiplas sessões
- Não
  - o aplicativo encerra após finalizar sessão

#### 4.4 Tempo de Preparação

- 0 seg - Sem tempo de preparação
- 15 seg (Padrão) - 15s para se preparar antes de iniciar a sessão de meditação
- 30 seg - 30s para se preparar antes de iniciar a sessão de meditação
- 60 seg - 1min para se preparar antes de iniciar a sessão de meditação

#### 4.5 Taxa de Respiração (nota: alguns dispositivos não suportam esse recurso)

- Ligado (Padrão) - métricas de taxa de respiração habilitadas durante a sessão
- Desligado - métricas de taxa de respiração desabilitadas durante a sessão

#### 4.6 Novo Tipo de Atividade

Você pode definir o tipo de atividade padrão para novas sessões.

- Yoga
- Meditação
