# Achados & Perdidos

Projeto da avaliação de Computação em Nuvem, desenvolvido por etapas.

## Etapa atual: TAREFA 3

Estrutura inicial do repositório e arquivos fornecidos no Apêndice A:

```text
achados-perdidos/
├── app/
│   ├── app.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .dockerignore
├── db/
│   └── init.sql
├── docs/
├── docker-compose.yml
├── .env.example
├── .gitignore
└── README.md
```

O `app.py` usa `/app/uploads` para as fotos, procura o banco no host `db` quando `DB_HOST` não é informado e espera as variáveis `DB_PORT`, `DB_NAME`, `DB_USER` e `DB_PASSWORD`.

## Imagem da aplicação (TAREFA 2)

O `app/Dockerfile` usa `python:3.12-slim`. Ele copia e instala `requirements.txt` antes de copiar `app.py`, para que uma alteração no código não obrigue a reinstalar as dependências. A instalação usa `--no-cache-dir` para não guardar o cache do pip na imagem.

O diretório `/app/uploads` pertence ao usuário `app`, que executa o processo sem privilégios de root. A porta 5000 é documentada com `EXPOSE`, e o Gunicorn escuta em `0.0.0.0:5000` para aceitar conexões encaminhadas ao contêiner. O `.dockerignore` exclui `.env`, `__pycache__/` e arquivos `.pyc` do contexto de build.

Para construir apenas a imagem web:

```sh
docker build -t achados-web:local ./app
```

## Orquestração (TAREFA 3)

O `docker-compose.yml` conecta os serviços `web` e `db` pela rede `rede_interna`. Somente a aplicação publica uma porta no host: `8080:5000`. O nome `db` funciona como endereço interno do PostgreSQL. O `healthcheck` usa `pg_isready`, e `web` espera o banco ficar saudável antes de iniciar.

Os volumes nomeados `dados_banco` e `fotos` guardam, respectivamente, os dados do PostgreSQL e os arquivos de `/app/uploads`. O arquivo `db/init.sql` é montado somente para leitura na pasta de inicialização do PostgreSQL e executado quando o volume do banco é criado pela primeira vez.

As três chaves `POSTGRES_DB`, `POSTGRES_USER` e `POSTGRES_PASSWORD` vêm do `.env`. O Compose passa os valores correspondentes para a aplicação como `DB_NAME`, `DB_USER` e `DB_PASSWORD`. O `.env` é local, está no `.gitignore` e não deve ser entregue.

Para subir o ambiente completo:

```sh
docker compose up -d --build
```
