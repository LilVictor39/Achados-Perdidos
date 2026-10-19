# Arquitetura local

```mermaid
flowchart LR
    cliente[Cliente: navegador ou curl]
    subgraph host[Host: computador com Docker Desktop]
        porta[Porta publicada 8080]
        sql[db/init.sql no projeto]
        dados[(Volume nomeado dados_banco)]
        fotos[(Volume nomeado fotos)]
        subgraph rede[rede_interna: rede bridge do Compose]
            web[web: Flask + Gunicorn<br/>porta interna 5000]
            db[db: PostgreSQL<br/>porta interna 5432]
        end
    end
    cliente -->|HTTP localhost:8080| porta
    porta -->|8080:5000| web
    web -->|DB_HOST=db:5432| db
    db -->|montagem /var/lib/postgresql/data| dados
    web -->|montagem /app/uploads| fotos
    sql -.->|bind mount somente leitura<br/>/docker-entrypoint-initdb.d/init.sql| db
```

O cliente e a porta 8080 ficam fora da `rede_interna`. Os dois contêineres pertencem à rede. O PostgreSQL não publica a porta 5432 no host; somente `web` pode alcançá-lo pelo nome `db` dentro da rede. Os volumes nomeados e o arquivo `db/init.sql` são recursos de armazenamento do host Docker, montados nos caminhos indicados dentro dos contêineres. O arquivo SQL é usado na primeira inicialização de um volume de banco vazio.

No Docker Desktop para Windows, os volumes são gerenciados pelo ambiente Linux do Docker. Os caminhos físicos observados na TAREFA 5 estão em [localização dos volumes](evidencias/tarefa5/02-localizacao.md).
