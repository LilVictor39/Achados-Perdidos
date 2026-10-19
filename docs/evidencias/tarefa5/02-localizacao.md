# Localização dos volumes

Os caminhos abaixo vieram de `docker volume inspect` durante a TAREFA 5.

| Volume nomeado | Ponto de montagem informado pelo Docker | Caminho dentro do contêiner |
| --- | --- | --- |
| `achadosperdidos_dados_banco` | `/var/lib/docker/volumes/achadosperdidos_dados_banco/_data` | `/var/lib/postgresql/data` no `db` |
| `achadosperdidos_fotos` | `/var/lib/docker/volumes/achadosperdidos_fotos/_data` | `/app/uploads` no `web` |

No Docker Desktop para Windows, os pontos de montagem pertencem ao ambiente Linux gerenciado pelo Docker; não são pastas comuns do repositório no Windows.

**Saídas originais:** [volume do banco](02-inspect-dados-banco.json) · [volume de fotos](02-inspect-fotos.json) · [arquivos em `/app/uploads`](02-ls-uploads.txt).
