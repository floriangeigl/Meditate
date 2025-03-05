# Guia do Usuário do App de Meditação Garmin

## Recursos

- Salve suas sessões de meditação como atividades no Garmin Connect
  - Tipos de atividade: *Meditação* ou *Yoga*
- Configure várias sessões de meditação/yoga
  - Exemplo: sessão de 20 minutos com 1 minuto de alertas recorrentes, despertando um alarme sonoro a cada 10 minutos
  - Cada sessão suporta intervalos de vibração
  - Intervalos de alertas são acionados de poucos segundos até algumas horas
- Sessões de meditação pré-configuradas de 5/10/15/20/25/30 minutos com vibração curta a cada 5 minutos
- Sessões padrão de meditação avançada de 45 minutos e 1 hora com vibração curta a cada 15 minutos
- [Variabilidade de batimento cardíaco](https://en.wikipedia.org/wiki/Heart_rate_variability) (HRV)
  - RMSSD: Raiz Quadrada Média das Diferenças Sucessivas (intervalos batimento a batimento)
  - pNN20 - % de intervalos batimento a batimento que diferem em mais de 20 ms
  - pNN50 - % de intervalos batimento a batimento que diferem em mais de 50 ms
  - leitura de intervalos batimento a batimento diretamente do sensor do relógio
  - HRV Sucessivas Diferenças - diferença entre intervalos batimento a batimento atuais e anteriores
  - SDRR - [Desvio Padrão](https://en.wikipedia.org/wiki/Standard_deviation) dos intervalos batimento a batimento
  - cálculo feito a partir dos primeiros e últimos 5 minutos da sessão
  - HRV RMSSD 30 Seg Janela - RMSSD calculado a partir de janelas consecutivas de 30 segundos
  - HR da frequência cardíaca - intervalo batimento a batimento convertido em HR
- Rastreamento de estresse
  - Resumo do estresse médio durante a sessão
  - Estresse médio no início e fim da sessão (calculado automaticamente pelo relógio para sessões de 5 minutos ou mais)
  - HR Picos 10 Seg Janela
    - Métrica interna para calcular o estresse
    - Acompanha em janelas de sobreposição de 10 segundos Máximo HR para cada janela
    - HR calculado a partir do intervalo batimento a batimento
- Taxa de respiração
  - Respirações por minuto em tempo real nos relógios que a suportam (somente funciona para Yoga devido a bug no Connect IQ API para atividade de respiração)
- Configuração de tempo antes da sessão de meditação
- Resumo de estatísticas no final da sessão
  - Gráfico de taxa cardíaca incluindo HR mínimo, médio e máximo
  - Resumo da taxa de respiração incluindo taxa estimada mínima, média e máxima
  - Estresse
  - HRV
- Pause/retome a sessão atual usando o botão de retorno
- Configure o nome da atividade padrão no Garmin Connect usando o Garmin Express em um PC conectado ao relógio via cabo

![Sessão Picker Demo](userGuideScreenshots/sessionPickerDemo.gif)
![Sessão Detalhes Demo](userGuideScreenshots/sessionDetailedDemo.gif)

## Como Usar
### 1. Iniciando uma Sessão

1.1. Na tela do seletor de sessão, pressione o botão de iniciar ou toque na tela (somente dispositivos com touch).

![Seletor de Sessão](userGuideScreenshots/sessionPicker.gif)

1.2. A tela de progresso da sessão contém os seguintes elementos:
- tempo decorrido
  - mostra a porcentagem do tempo de sessão decorrido
  - círculo completo significa que o tempo de sessão se esgotou
- intervalos de alertas
  - pequenos marcadores coloridos representam o tempo de um alerta de intervalo
  - cada posição marcada corresponde a um alerta para um tempo de intervalo específico
  - você pode ocultá-los por alerta selecionando uma cor transparente nas [Configurações de Alerta de Intervalos](#2-configurando-uma-sessão)
- tempo decorrido
- HR atual
- atual HRV Sucessivas Diferenças
  - diferença entre os intervalos batimento a batimento atuais e anteriores
  - mostra somente quando HRV rastreamento está ativo
  - **Para obter leituras de HRV precisas, você precisa minimizar movimentos mesmo**

A sessão de meditação termina assim que você pressiona o botão de início/parada.
A sessão pode ser pausada/retomada usando o botão de retorno.
Habilite/Desabilite a tela durante a sessão usando o botão de luz ou toque na tela (somente dispositivos com touch).

![Sessão em Progresso Explicada](userGuideScreenshots/sessionInProgressExplained.gif)

1.3. Ao parar a sessão, você tem a opção de salvá-la.

1.3.1. Você pode configurar para salvar ou descartar automaticamente a sessão via [Configurações Globais](#4-configurações-globais) -> [Confirmar Salvar](#42-confirmar-salvar)

![Confirmação de Salvar Sessão](userGuideScreenshots/confirmSaveSession.gif)

1.4. Se você estiver no modo de sessão única (o padrão) no final, você verá a Tela de Resumo (para Multi-Sessão, veja a próxima seção **1.5**). Deslize para cima/baixo (dispositivos touch) ou pressione botão para cima/baixo para ver as estatísticas de resumo de HR, Estresse e HRV. Volte desta visão para sair do app.

![Sessão Resumo Detalhada Demo](userGuideScreenshots/sessionSummaryDetailedDemo.gif)

1.5. Se você estiver no modo Multi-Sessão (determinado por [Configurações Globais](#4-configurações-globais) -> [Multi-Sessão](#43-multi-sessao)), então você volta à tela do seletor de sessão. De lá, você pode iniciar outra sessão. Assim que terminar sua sessão, poderá voltar à tela do seletor de sessão para acessar a visão Resumo das Sessões.

![Resumo Rolagem](userGuideScreenshots/summaryRollup.gif)

1.6. Da visão de resumo das sessões, você pode rolar individualmente nas sessões ou sair do app. Rolando para baixo mostra as estatísticas de resumo de HR, Taxa de Respiração, Estresse e HRV. Se você voltar da visão das sessões, poderá continuar fazendo mais sessões.

## 2. Configurando uma Sessão

2.1. Na tela do seletor de sessão, mantenha o botão de menu (meio à esquerda) até ver o menu de configurações da sessão.
   - Em dispositivos com tela touch, também é possível tocar e segurar na tela para abrir o menu

![Menu de Configurações da Sessão](userGuideScreenshots/sessionSettingsMenu.gif)

2.2. Em Adicionar Novo/Editar, você pode configurar:
- Tempo - duração total da sessão em H:MM
- Cor - cor da sessão usada nos controles gráficos; selecione tocando a tela (Vivoactive 3/4/Venu)
- Padrão de Vibração - padrões mais curtos ou mais longos
- Alertas de Intervalos - capacidade de configurar múltiplos alertas para cada sessão
  - uma vez que você está em um alerta específico que você vê no título do menu o ID do Alerta (ex. Alerta 1) relativo aos alertas atuais de intervalos
  - Tempo
    - selecione um alerta único ou repetitivo
    - alertas repetitivos permitem durações mais curtas do que um minuto
    - apenas um único alerta irá executar a qualquer hora do dia
    - prioridade de alertas com o mesmo tempo
      1. alerta final de sessão
      2. último alerta único
      3. último alerta repetitivo
  - Cor - a cor do alerta atual de intervalo usado nos controles gráficos. Selecione cores diferentes para cada alerta para diferenciá-los durante a meditação. Selecionar cor transparente se não quiser ver marcas visuais para o alerta durante a meditação
  - Padrão de Vibração/Som - padrões mais curtos ou mais longos
- Tipo de Atividade - capacidade de salvar a sessão como **Meditação** ou **Yoga**. Você pode configurar o tipo padrão de atividade para novas sessões nas Configurações Globais (veja [seção 4](#4-configurações-globais)).
- Rastreamento HRV - determina se HRV e estresse são rastreados
  - ON - rastreia estresse e os seguintes métricas HRV
    - RMSSD
    - HRV Sucessivas Diferenças
  - Em Detalhado (Padrão) - rastreia estresse extra e métricas HRV além da opção **On**
    - RMSSD
    - HRV Sucessivas Diferenças
    - pNN20
    - pNN50
    - intervalos batimento a batimento
    - SDRR Primeiro 5 min da sessão
    - SDRR Último 5 min da sessão
    - RMSSD 30 Seg Janela
    - HR de ritmo cardíaco
    - HR Picos 10 Seg Janela

2.3 Excluir - elimina uma sessão depois de pedir confirmação

2.4 Configurações Globais - [veja seção 4](#4-configurações-globais)

## 3. Escolhendo uma Sessão

Na tela do seletor de sessão, pressione o botão de navegação para cima/baixo (para dispositivos touch deslize para cima/baixo).
Nesta tela, você pode ver as configurações aplicáveis para a sessão selecionada:
- tipo de atividade - no título
  - *Meditação*
- tempo - duração total da sessão
- padrão de vibração
- intervalos de alerta de alerta - o gráfico no meio da tela representa o tempo de alerta relativo comparado ao tempo da sessão total
- Indicador HRV
  - ![Off](userGuideScreenshots/hrvIndicatorOff.png) Off - indica que estresse e HRV estão desligados
  - ![Esperando HRV](userGuideScreenshots/hrvIndicatorWaitingHrv.png) Esperando HRV
    - o sensor de hardware não detecta HRV
    - você pode começar a sessão mas terá perdas de dados HRV, é recomendado permanecer em silêncio até que HRV esteja pronto
  - ![HRV Pronto](userGuideScreenshots/hrvIndicatorReady.png) HRV Pronto
    - o sensor de hardware detecta HRV
    - a sessão rastreia dados padrão HRV e métrica de Estresse
    - **a sessão pode ser gravada com dados HRV confiáveis fornecidos, minimizando movimento**

![Sessão Picker Explicada](userGuideScreenshots/sessionPickerExplained.gif)

## 4. Configurações Globais

Na tela do seletor de sessão, mantenha o botão de menu (ou toque e segure a tela) até ver o menu de configurações da sessão. Selecione o Menu de Configurações Globais. Você verá uma visão com os estados das configurações globais. Segure o botão de menu novamente (ou toque e segure na tela) para editar configurações globais.

![Configurações Globais](userGuideScreenshots/globalSettings.gif)

### 4.1 Rastreamento HRV

Essa configuração fornece o padrão **Rastreamento HRV** para novas sessões.
- **On** - rastreia métricas HRV e dados de Estresse
  - RMSSD
  - Diferenças Sucessivas
  - Estresse **HRV**
- **On Detalhado** - extensão de métricas HRV e Estresse
  - RMSSD
  - Diferenças Sucessivas
  - Estresse
  - intervalos batimento a batimento
  - pNN50
  - pNN20
  - HR de batimento cardíaco
  - RMSSD 30 Sec Janela
  - HR Picos 10 Sec Janela
  - SDRR Primeiro 5 min da sessão
  - SDRR Último 5 min da sessão
- **Off** - Rastreamento HRV e Estresse desligados

### 4.2 Confirmar Salvar

- **Perguntar** - quando uma atividade termina, pergunta para salvar
- **Auto Sim** - quando uma atividade termina, auto salva
- **Auto Não** - quando uma atividade termina, auto descarta

### 4.3 Multi-Sessão

- Sim  
  - o app continua rodando após a finalização da sessão
  - isso permite que você registre múltiplas sessões
- Não  
  - o app fecha após a finalização da sessão

### 4.4 Tempo de Preparação

- 0 seg - sem preparação
- 15 seg (padrão) - 15s para se preparar antes de iniciar a sessão de meditação
- 30 seg - 30s para se preparar antes de iniciar a sessão de meditação
- 60 seg - 1min para se preparar antes de iniciar a sessão de meditação

### 4.5 Taxa de Respiração (nota: alguns dispositivos não suportam este recurso)

- On (Padrão) - métricas de taxa de respiração habilitadas durante sessão
- Off - métricas de taxa de respiração desabilitadas durante sessão

### 4.6 Novo Tipo de Atividade

Você pode definir o tipo de atividade padrão para novas sessões.

- Yoga
- Meditação
