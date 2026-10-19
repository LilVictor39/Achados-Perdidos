# TAREFA 6 — evidências adicionais

**Resultado:** rede e imagem inspecionadas; a tentativa de escala confirmou o conflito da porta 8080; o serviço voltou a uma réplica e executa como usuário `app`.

## Saídas registradas

| Evidência | Legenda |
| --- | --- |
| [01-compose-up.txt](01-compose-up.txt) | Ambiente iniciado para a coleta. |
| [02-docker-network-inspect.json](02-docker-network-inspect.json) | A rede `achadosperdidos_rede_interna` usa driver bridge e contém `db` e `web`. |
| [03-docker-image-ls.txt](03-docker-image-ls.txt) | A imagem `achadosperdidos-web:latest` aparece com tamanho de 219 MB. |
| [04-compose-images-web.txt](04-compose-images-web.txt) | A imagem listada pertence ao serviço `web` deste Compose. |
| [05-scale-web-3.txt](05-scale-web-3.txt) | A tentativa de três réplicas saiu com código 1: a porta 8080 já estava ocupada pela primeira réplica. |
| [06-restaurar-web-1.txt](06-restaurar-web-1.txt) | O Compose removeu as réplicas extras após a tentativa. |
| [07-compose-ps-final.txt](07-compose-ps-final.txt) | Estado final com banco saudável e uma réplica `web` na porta 8080. |
| [08-whoami.txt](08-whoami.txt) | `docker compose exec -T web whoami` retornou `app`, confirmando execução sem `root`. |

## Leitura do resultado

O [erro da tentativa de escala](05-scale-web-3.txt) contém `port is already allocated`. O [Compose](../../../docker-compose.yml) fixa a publicação `8080:5000` no serviço `web`, então uma segunda réplica não consegue usar a mesma porta do host. A [saída final](07-compose-ps-final.txt) confirma o banco saudável e apenas uma réplica da aplicação.

O roteiro que gerou essas saídas está em [`docs/testar-tarefa6.ps1`](../../testar-tarefa6.ps1).
