# Dynatrace Legacy Windows Agent

Agente minimalista para Windows Server legado (pre-2008) usando .NET Framework 2.0.

Ele:
- envia metricas para Dynatrace Metrics API v2
- envia eventos para Dynatrace Events API v2
- expoe um proxy OTLP HTTP local e encaminha traces/metricas/logs para Dynatrace

## Requisitos
- Windows Server 2003+ (compatibilidade maxima)
- .NET Framework 2.0
- Acesso a Dynatrace SaaS ou ActiveGate

## Build

```cmd
msbuild src\DtLegacyAgent.csproj /p:Configuration=Release
```

Output:
```
src\bin\Release\DtLegacyAgent.exe
```

## Empacotar para repositorio (dist)

Gera uma pasta `dist` com os arquivos necessarios para instalar via download.

```powershell
cd d:\OneDrive\TRABALHO\AGENTE-X\win-legacy-agent
.\publish.ps1
```

Arquivos em `dist`:
- `DtLegacyAgent.exe`
- `install.cmd`
- `uninstall.cmd`
- `agent.conf.example`

## Instalacao facil (gera servico e inicia no boot)

```cmd
install.cmd https://<env>.live.dynatrace.com dt0c01...token...
```

Isso:
- copia o exe para `C:\Program Files\DtLegacyAgent`
- grava `agent.conf` com token/ambiente
- cria o servico `DtLegacyAgent` com inicio automatico
- inicia o servico

Se o `DtLegacyAgent.exe` nao estiver na mesma pasta do `install.cmd`, o instalador baixa automaticamente do repositorio (branch `main`).

Você pode ajustar a origem com:
```
set AGENT_DOWNLOAD_BASE=https://raw.githubusercontent.com/CassioCirino/AGENTEX/main/dist
```

Opcional: se voce quiser levar somente o EXE para o cliente, copie `DtLegacyAgent.exe` e `install.cmd` para a maquina e passe o caminho do EXE:

```cmd
install.cmd https://<env>.live.dynatrace.com dt0c01...token... "C:\Program Files\DtLegacyAgent" "C:\Temp\DtLegacyAgent.exe"
```

Para remover:

```cmd
uninstall.cmd
```

## Baixar e instalar apenas com comandos (PowerShell 2+)

Substitua `<org>/<repo>` pelo seu repositorio. Este exemplo baixa do `dist` na branch `main`.

```powershell
$dir = "C:\Temp\DtLegacyAgent"
New-Item -ItemType Directory -Force $dir | Out-Null
(New-Object Net.WebClient).DownloadFile("https://raw.githubusercontent.com/CassioCirino/AGENTEX/main/dist/install.cmd", "$dir\install.cmd")
cmd /c ""$dir\install.cmd" https://<env>.live.dynatrace.com dt0c01...token..."
```

Se nao houver PowerShell, use `bitsadmin` (Windows 2003/2008):

```cmd
set DIR=C:\Temp\DtLegacyAgent
mkdir %DIR%
bitsadmin /transfer dt1 https://raw.githubusercontent.com/CassioCirino/AGENTEX/main/dist/install.cmd %DIR%\install.cmd
%DIR%\install.cmd https://<env>.live.dynatrace.com dt0c01...token...
```

## Execucao manual

```cmd
set DT_BASE_URL=https://<env>.live.dynatrace.com
set DT_API_TOKEN=dt0c01...token...
set AGENT_OTLP_LISTEN=http://127.0.0.1:4318/
set AGENT_INTERVAL=15
set AGENT_HTTP_TIMEOUT=15

src\bin\Release\DtLegacyAgent.exe
```

## Config file (opcional)

Crie um arquivo (ex: `agent.conf`) e aponte `AGENT_CONFIG` para ele:

```cmd
set AGENT_CONFIG=C:\path\to\agent.conf
```

Exemplo `agent.conf`:
```
DT_BASE_URL=https://<env>.live.dynatrace.com
DT_API_TOKEN=dt0c01...token...
AGENT_OTLP_LISTEN=http://127.0.0.1:4318/
AGENT_INTERVAL=15
AGENT_HTTP_TIMEOUT=15
AGENT_ENABLE_OTLP=true
AGENT_ENABLE_METRICS=true
AGENT_ENABLE_EVENTS=true
```

## Endpoints usados

Se `DT_BASE_URL` estiver definido:
- Metrics ingest: `<base>/api/v2/metrics/ingest`
- Events ingest: `<base>/api/v2/events/ingest`
- OTLP base: `<base>/api/v2/otlp`

Overrides:
- `DT_METRICS_ENDPOINT`
- `DT_EVENTS_ENDPOINT`
- `DT_OTLP_ENDPOINT`

## OTLP proxy

O agente escuta em `AGENT_OTLP_LISTEN` (default `http://127.0.0.1:4318/`) e encaminha:
- `/v1/traces`
- `/v1/metrics`
- `/v1/logs`

## Notas
- Windows muito antigo pode nao suportar TLS 1.2. Se precisar, use ActiveGate como endpoint local.
- OTLP e HTTP/protobuf (sem gRPC).
- Este agente roda como console ou como servico (quando instalado pelo install.cmd).
- Se voce atualizou o EXE, rode o install.cmd novamente para reinstalar o servico.
- Logs em `agent.log` com rotacao basica (ate ~5MB, 1 backup).

## Variaveis de ambiente
- `DT_BASE_URL`
- `DT_API_TOKEN`
- `DT_METRICS_ENDPOINT`
- `DT_EVENTS_ENDPOINT`
- `DT_OTLP_ENDPOINT`
- `AGENT_OTLP_LISTEN`
- `AGENT_INTERVAL`
- `AGENT_HTTP_TIMEOUT`
- `AGENT_HOSTNAME`
- `AGENT_ENABLE_OTLP`
- `AGENT_ENABLE_METRICS`
- `AGENT_ENABLE_EVENTS`

## Escopos do token
- Metrics: `metrics.ingest`
- Events: `events.ingest`
- OTLP traces: `openTelemetryTrace.ingest`
- OTLP logs: `logs.ingest`
- OTLP metrics: `metrics.ingest`
