# Achados & Perdidos

Projeto da avaliação de Computação em Nuvem, desenvolvido por etapas.

## Etapa atual: TAREFA 2

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

O `docker-compose.yml` será implementado na TAREFA 3; ainda não é possível subir o ambiente completo. O arquivo `.env` é local e não deve ser entregue.
