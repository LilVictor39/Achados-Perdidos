# Relatório técnico — TAREFA 6

## a) Dockerfile e ordem das instruções

Arquivo: [`app/Dockerfile`](../app/Dockerfile).

| Instrução | Função |
| --- | --- |
| `FROM python:3.12-slim` | Define a imagem base do Python, em variante compacta. |
| `WORKDIR /app` | Cria/seleciona `/app` como diretório de trabalho das instruções seguintes e do processo. |
| `COPY requirements.txt ./requirements.txt` | Copia somente a lista de dependências para uma camada própria. |
| `RUN pip install --no-cache-dir -r requirements.txt` | Instala Flask, psycopg e Gunicorn sem guardar o cache de download do pip na imagem. |
| `COPY app.py ./app.py` | Copia o código depois das dependências. Quando só `app.py` muda, o build pode reaproveitar as camadas de instalação. |
| `RUN groupadd ... && useradd ... && mkdir ... && chown ...` | Cria usuário e grupo de sistema `app`, cria `/app/uploads` e dá a esse usuário permissão para gravar as fotos. O `&&` interrompe a cadeia se algum comando falhar. |
| `USER app` | Executa o Gunicorn sem privilégios de root. |
| `EXPOSE 5000` | Documenta a porta interna; a publicação em `8080` é feita pelo Compose. |
| `CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]` | Inicia a aplicação Flask com Gunicorn, escutando nas interfaces do contêiner. |

A ordem separa dependências e código para aproveitar o cache do build. O usuário é criado antes de `USER app`, pois criar conta e ajustar dono exige privilégios durante a construção. `EXPOSE` e `CMD` ficam no fim porque descrevem a execução da imagem pronta.

## b) Blocos do Compose

Arquivo: [`docker-compose.yml`](../docker-compose.yml).

| Bloco | Função |
| --- | --- |
| `services.db.image` | Usa `postgres:16-alpine` para o banco. |
| `services.db.environment` | Lê nome do banco, usuário e senha do `.env`; a sintaxe `${VAR:?...}` exige que cada valor exista. |
| `services.db.volumes` | Monta `dados_banco` em `/var/lib/postgresql/data` e `db/init.sql` como bind mount somente leitura em `/docker-entrypoint-initdb.d/init.sql`. |
| `services.db.healthcheck` | Executa `pg_isready` a cada 5 segundos, com timeout de 3 segundos e até 10 tentativas. `$$` preserva `$` para expansão dentro do contêiner. |
| `services.db.networks` e `restart` | Liga o banco à `rede_interna` e reinicia salvo se for parado explicitamente. Não há `ports` para o banco. |
| `services.web.build` | Constrói a imagem a partir de `./app`. |
| `services.web.environment` | Configura host `db`, porta interna 5432, credenciais do banco e diretório `/app/uploads`. |
| `services.web.ports` | Encaminha a porta 8080 do host para a 5000 do contêiner. |
| `services.web.volumes` | Monta `fotos` em `/app/uploads`. |
| `services.web.depends_on` | Espera o estado `service_healthy` do banco antes de iniciar a aplicação. |
| `services.web.networks` e `restart` | Liga a API à mesma rede do banco e aplica a política de reinício. |
| `networks.rede_interna` | Cria uma rede bridge com DNS entre os serviços. |
| `volumes.dados_banco` e `volumes.fotos` | Declara os dois volumes nomeados, gerenciados pelo Docker. |

## c) Caminho de `POST /itens` com foto

1. `curl.exe` envia `multipart/form-data` para `http://localhost:8080/itens`, contendo `descricao`, `local` e o arquivo `foto`.
2. O Docker encaminha a conexão da porta 8080 do host para a porta 5000 do contêiner `web`.
3. O Gunicorn entrega a requisição ao Flask. A função `cadastrar()` lê os campos, verifica os obrigatórios e recebe o arquivo.
4. A aplicação gera um nome único com UUID e extensão da foto. `foto.save()` grava o arquivo em `/app/uploads` no contêiner, que é o volume nomeado `fotos` no armazenamento do Docker.
5. A aplicação abre conexão PostgreSQL para `db:5432`. O DNS da `rede_interna` resolve `db` para o contêiner do banco.
6. O `INSERT` grava descrição, local e nome da foto na tabela `itens`; os arquivos de dados do PostgreSQL ficam em `/var/lib/postgresql/data`, montado no volume `dados_banco`.
7. O banco confirma a transação quando a conexão sai do bloco `with`; a API responde HTTP 201 com o ID e o nome gerado para a foto.

O arquivo e a linha no banco são gravados por operações separadas: se o `INSERT` falhar depois de `foto.save()`, pode restar uma foto sem item. O código fornecido não faz limpeza compensatória.

## d) Ciclo de vida dos volumes

Os volumes são criados na primeira subida e sobrevivem à recriação dos contêineres. Na [prova da TAREFA 5](evidencias/tarefa5/resultado.md), havia 6 itens e 3 fotos antes de `docker compose down`; após `docker compose up -d`, continuaram 6 e 3. O `down` remove contêineres e rede, preservando os volumes nomeados.

`docker compose down -v` remove também `dados_banco` e `fotos`. Depois da nova subida, a prova mostrou 3 itens e 0 fotos. O PostgreSQL detectou o diretório de dados vazio e executou `db/init.sql` novamente, inserindo os três exemplos. Editar `init.sql` quando o volume já contém um banco não reaplica o script automaticamente; para preservar dados, é necessária uma migração SQL.

As montagens e os locais físicos observados estão em [inspeção do banco](evidencias/tarefa5/02-inspect-dados-banco.json), [inspeção das fotos](evidencias/tarefa5/02-inspect-fotos.json) e [localização](evidencias/tarefa5/02-localizacao.md).
