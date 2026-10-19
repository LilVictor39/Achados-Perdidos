# TAREFA 4 — testes funcionais

**Resultado: todos os testes passaram.** O roteiro subiu os serviços, exercitou as rotas da API e guardou as respostas nesta pasta.

| Verificação | Resultado observado | Evidência |
| --- | --- | --- |
| Subida e estado dos serviços | `db` saudável e `web` em execução | [Subida](01-compose-up.txt) · [Serviços](02-compose-ps.txt) |
| `GET /health` | Banco conectado | [Resposta](03-health.json) · [HTTP](03-health.status.txt) |
| `GET /itens` | Três itens de exemplo | [Resposta](04-itens.json) · [HTTP](04-itens.status.txt) |
| Filtro por local | Busca por Biblioteca retornou o item correspondente | [Resposta](05-filtro-biblio.json) · [HTTP](05-filtro-biblio.status.txt) |
| `POST /itens` com foto | Item 4 criado | [Cadastro](06-cadastro.json) · [Lista posterior](07-itens-apos-cadastro.json) |
| `GET /fotos/<nome>` | Foto recuperada e idêntica ao arquivo enviado | [Foto baixada](08-foto-baixada.png) · [HTTP](08-foto-baixada.status.txt) |
| `GET /estatisticas` | 4 itens e 1 foto | [Resposta](09-estatisticas.json) · [HTTP](09-estatisticas.status.txt) |
| Logs da aplicação | Saída registrada | [Logs](10-logs-web.txt) |

O roteiro utilizado está em [`docs/testar-tarefa4.ps1`](../../testar-tarefa4.ps1). A [TAREFA 5](../tarefa5/resultado.md) usa esse estado como ponto de partida para provar a persistência.
