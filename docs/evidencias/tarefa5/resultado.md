# TAREFA 5 - prova de persistência

| Momento | Itens no banco | Fotos no volume | Evidência |
| --- | ---: | ---: | --- |
| Antes dos novos cadastros | 4 | 1 | [Estatísticas iniciais](01-estatisticas-iniciais.json) |
| Após cadastrar dois itens com foto | 6 | 3 | [Antes de `down`](01-estatisticas-antes-down.json) |
| Após `docker compose down` e `up -d` | 6 | 3 | [Após recriação](01-estatisticas-apos-up.json) |
| Antes de `docker compose down -v` | 6 | 3 | [Antes da remoção](03-estatisticas-antes-remocao.json) |
| Após `down -v` e nova subida | 3 | 0 | [Após remoção](03-estatisticas-apos-remocao.json) |

## 1. Recriação dos contêineres — passou

Os dois [cadastros com foto](01-ids-criados.json) continuaram em [GET /itens](01-itens-apos-up.json) após a recriação. As duas fotos foram recuperadas e seus hashes SHA-256 são idênticos aos do arquivo enviado. O comando `docker compose down` remove contêineres e rede, mas preserva os volumes nomeados.

## 2. Inspeção dos volumes — passou

O [volume do banco](02-inspect-dados-banco.json) foi montado em `/var/lib/postgresql/data`; o [volume de fotos](02-inspect-fotos.json), em `/app/uploads`. Os caminhos físicos reportados pelo Docker estão em [localização dos volumes](02-localizacao.md). A [listagem de `/app/uploads`](02-ls-uploads.txt) mostrou as três fotos. No Docker Desktop, esses caminhos pertencem ao ambiente Linux do Docker.

## 3. Remoção dos volumes — passou

O [comando `down -v`](03-compose-down-v.txt) removeu os dois volumes do projeto, que ficaram ausentes na [listagem feita imediatamente depois](03-volumes-apos-down-v.txt). Na nova subida, o PostgreSQL criou outro volume e executou `db/init.sql` novamente. Por isso, [GET /itens](03-itens-apos-remocao.json) voltou a mostrar somente os três objetos de exemplo, enquanto as fotos e os itens cadastrados desapareceram.
