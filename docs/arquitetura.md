# Arquitetura do ambiente local

O cliente acessa a API pela porta **8080** do host. Dentro da rede do Compose, `web` se conecta ao PostgreSQL pelo nome `db` e pela porta **5432**. Os dados e as fotos ficam em volumes separados.

```mermaid
flowchart LR
    cliente["Navegador ou curl"]

    subgraph host["Host · computador com Docker Desktop"]
        porta["Porta publicada<br/>8080"]
        script["db/init.sql<br/>arquivo do projeto"]
        dados[("dados_banco<br/>volume nomeado")]
        fotos[("fotos<br/>volume nomeado")]

        subgraph rede["rede_interna · bridge do Compose"]
            web["web<br/>Flask + Gunicorn · porta 5000"]
            db["db<br/>PostgreSQL · porta 5432"]
        end
    end

    cliente -->|"HTTP · localhost:8080"| porta
    porta -->|"8080 → 5000"| web
    web -->|"DB_HOST=db · 5432"| db
    web -->|"/app/uploads"| fotos
    db -->|"/var/lib/postgresql/data"| dados
    script -.->|"bind mount :ro<br/>/docker-entrypoint-initdb.d/init.sql"| db

    classDef service fill:#dbeafe,stroke:#2563eb,color:#172554
    classDef storage fill:#dcfce7,stroke:#16a34a,color:#14532d
    class web,db service
    class dados,fotos storage
```

## O que fica dentro e fora da rede

| Elemento | Local e função |
| --- | --- |
| `web` e `db` | Contêineres ligados à `rede_interna`; o DNS do Docker permite que `web` encontre `db` pelo nome. |
| Porta 8080 | Publicada no host e encaminhada à porta 5000 de `web`. É o ponto de entrada do cliente. |
| Porta 5432 | Usada pelo banco **dentro da rede**; não é publicada no host. |
| `dados_banco` | Volume gerenciado pelo Docker, montado em `/var/lib/postgresql/data` no `db`. |
| `fotos` | Volume gerenciado pelo Docker, montado em `/app/uploads` no `web`. |
| `db/init.sql` | Arquivo do projeto no host, montado no `db` somente para leitura (`:ro`). |

O arquivo `init.sql` é executado pelo PostgreSQL apenas quando o volume do banco está vazio. Os volumes sobrevivem a `docker compose down`; `docker compose down -v` os remove. No Docker Desktop para Windows, os caminhos físicos dos volumes ficam no ambiente Linux do Docker, conforme a [inspeção da TAREFA 5](evidencias/tarefa5/02-localizacao.md).

**Evidência da rede:** [`docker network inspect`](evidencias/tarefa6/02-docker-network-inspect.json) mostra os dois contêineres conectados à rede bridge do projeto.
