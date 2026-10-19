# Índice de evidências

Os arquivos abaixo registram execuções reais. O [diagrama](../arquitetura.md) e o [relatório](../RELATORIO.md) explicam a configuração examinada.

## TAREFA 4 — testes funcionais

| Evidência | Legenda |
| --- | --- |
| [01-compose-up.txt](tarefa4/01-compose-up.txt) | Construção e subida dos serviços. |
| [02-compose-ps.txt](tarefa4/02-compose-ps.txt) | Estado dos contêineres após a subida. |
| [03-health.json](tarefa4/03-health.json) | Resposta de saúde com o banco conectado. |
| [04-itens.json](tarefa4/04-itens.json) | Lista dos itens de exemplo. |
| [05-filtro-biblio.json](tarefa4/05-filtro-biblio.json) | Lista filtrada pelo local Biblioteca. |
| [06-cadastro.json](tarefa4/06-cadastro.json) | Resposta ao cadastro de um item com foto. |
| [07-itens-apos-cadastro.json](tarefa4/07-itens-apos-cadastro.json) | Lista após o cadastro. |
| [08-foto-baixada.png](tarefa4/08-foto-baixada.png) | Arquivo recuperado pela rota de fotos. |
| [09-estatisticas.json](tarefa4/09-estatisticas.json) | Contagem de itens e fotos após o cadastro. |
| [10-logs-web.txt](tarefa4/10-logs-web.txt) | Logs da aplicação durante os testes. |

Os arquivos `.status.txt` correspondentes registram o código HTTP de cada resposta. O [resultado da TAREFA 4](tarefa4/resultado.md) resume a aprovação dos testes.

## TAREFA 5 — persistência

| Evidência | Legenda |
| --- | --- |
| [01-estatisticas-antes-down.json](tarefa5/01-estatisticas-antes-down.json) | Contagem de 6 itens e 3 fotos antes de recriar os contêineres. |
| [01-compose-down.txt](tarefa5/01-compose-down.txt) | Remoção dos contêineres sem remover os volumes. |
| [01-compose-up-novamente.txt](tarefa5/01-compose-up-novamente.txt) | Nova subida utilizando os volumes existentes. |
| [01-estatisticas-apos-up.json](tarefa5/01-estatisticas-apos-up.json) | Contagem preservada após a nova subida. |
| [01-itens-apos-up.json](tarefa5/01-itens-apos-up.json) | Itens cadastrados ainda presentes após a recriação. |
| [02-docker-volume-ls.txt](tarefa5/02-docker-volume-ls.txt) | Lista dos volumes Docker. |
| [02-inspect-dados-banco.json](tarefa5/02-inspect-dados-banco.json) | Inspeção do volume persistente do PostgreSQL. |
| [02-inspect-fotos.json](tarefa5/02-inspect-fotos.json) | Inspeção do volume persistente de fotos. |
| [02-ls-uploads.txt](tarefa5/02-ls-uploads.txt) | Arquivos encontrados em `/app/uploads`. |
| [03-compose-down-v.txt](tarefa5/03-compose-down-v.txt) | Remoção dos contêineres e dos volumes nomeados. |
| [03-volumes-apos-down-v.txt](tarefa5/03-volumes-apos-down-v.txt) | Ausência dos volumes logo após a remoção. |
| [03-itens-apos-remocao.json](tarefa5/03-itens-apos-remocao.json) | Retorno somente dos três itens iniciais. |
| [03-estatisticas-apos-remocao.json](tarefa5/03-estatisticas-apos-remocao.json) | Contagem de 3 itens e 0 fotos após recriação. |

Os demais arquivos da pasta registram estados intermediários, códigos HTTP, fotos de teste e montagens. O [resultado da TAREFA 5](tarefa5/resultado.md) liga as três provas aos dados observados.

## TAREFA 6 — rede, imagem e escala

O [resultado e as legendas da TAREFA 6](tarefa6/resultado.md) incluem `docker network inspect`, `docker image ls`, a saída da tentativa de três réplicas e a confirmação do usuário `app`. Para repetir a coleta, execute `powershell -NoProfile -ExecutionPolicy Bypass -File .\docs\testar-tarefa6.ps1` no PowerShell do projeto, com Docker Desktop ativo.
