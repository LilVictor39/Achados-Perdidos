# Achados & Perdidos

API de achados e perdidos para a avaliação de Computação em Nuvem. O projeto demonstra uma aplicação Flask em contêiner, PostgreSQL, rede interna e persistência de dados e fotos em volumes Docker.

## Pré-requisitos

- Docker Desktop iniciado, com Docker Compose disponível (`docker compose version`).
- PowerShell para executar os roteiros de teste incluídos. Os comandos básicos do Compose também funcionam em outro terminal.
- Porta 8080 livre no computador.

Execute os comandos na pasta raiz do projeto.

## Configurar e subir

1. Se ainda não existir `.env`, crie o arquivo local de configuração a partir do modelo:

   ```powershell
   Copy-Item .env.example .env
   notepad .env
   ```

2. Ajuste `POSTGRES_DB`, `POSTGRES_USER` e, principalmente, `POSTGRES_PASSWORD` no `.env`. Use uma senha própria. O arquivo `.env` está no `.gitignore` e não deve ser enviado ao repositório.
3. Confira a configuração e inicie os serviços:

   ```powershell
   docker compose config --quiet
   docker compose up -d --build
   docker compose ps
   ```

O PostgreSQL precisa ficar `healthy`; a aplicação `web` fica disponível em `http://localhost:8080`. A primeira subida pode demorar enquanto a imagem é construída e o banco inicia. `db/init.sql` cria a tabela e três itens de exemplo somente quando o volume do banco está vazio.

## Testar

Consulta rápida no PowerShell:

```powershell
curl.exe http://localhost:8080/health
curl.exe http://localhost:8080/itens
curl.exe http://localhost:8080/estatisticas
```

Para executar e salvar as provas funcionais da TAREFA 4:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\docs\testar-tarefa4.ps1
```

O roteiro testa saúde, lista, filtro, cadastro com foto, recuperação da foto, estatísticas e logs. As saídas estão em [evidências da TAREFA 4](docs/evidencias/tarefa4/resultado.md). Se apenas os logs faltarem, use `-ApenasLogs` no fim do comando.

Para repetir a prova de persistência da TAREFA 5:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\docs\testar-tarefa5.ps1 -RemoverVolumes
```

Esse roteiro cadastra itens de teste, verifica `down` + `up`, inspeciona volumes e, ao final, **apaga os dados dos volumes** com `down -v` antes de subir novamente. Execute apenas quando não houver dados que queira preservar. Os resultados anteriores estão em [evidências da TAREFA 5](docs/evidencias/tarefa5/resultado.md).

Para gerar as duas evidências adicionais da TAREFA 6 e registrar a tentativa de escala:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\docs\testar-tarefa6.ps1
```

## Rotas da API

| Método | Rota | Entrada | Resultado |
| --- | --- | --- | --- |
| GET | `/health` | Nenhuma | Estado da API, conexão com o banco e nome do contêiner. |
| GET | `/itens` | Filtro opcional `?local=Biblioteca` | Lista de itens cadastrados. |
| POST | `/itens` | Formulário `multipart/form-data` com `descricao`, `local` e `foto` opcional | Cria item; retorna ID e nome da foto com HTTP 201. |
| GET | `/fotos/<nome>` | Nome de foto retornado pela API | Arquivo da foto. |
| GET | `/estatisticas` | Nenhuma | Quantidade de itens no banco e de arquivos no volume de fotos. |

Exemplo de cadastro com foto existente no computador:

```powershell
curl.exe -X POST http://localhost:8080/itens -F "descricao=Chave" -F "local=Biblioteca" -F "foto=@C:\caminho\foto.png"
```

Se quiser cadastrar sem foto, omita o último `-F`.

## Parar ou destruir o ambiente

```powershell
docker compose down
```

Esse comando remove contêineres e a rede do projeto, mas preserva `dados_banco` e `fotos`. Para subir novamente, use `docker compose up -d`.

```powershell
docker compose down -v
```

Esse comando também remove os dois volumes e **apaga definitivamente os itens cadastrados e as fotos**. Na próxima subida, o banco executa `init.sql` de novo e recria os três itens de exemplo. A imagem construída continua no Docker; se precisar reconstruí-la, use `docker compose up -d --build`.

## Arquivos de entrega e defesa

- [Diagrama da arquitetura](docs/arquitetura.md): host, portas, rede, contêineres e armazenamento.
- [Relatório técnico](docs/RELATORIO.md): Dockerfile, Compose, fluxo do POST e persistência.
- [Evidências](docs/evidencias/README.md): resultados das TAREFAS 4 e 5, inspeção de rede e imagem.
- [Reflexão e equivalência em nuvem](docs/REFLEXAO.md): sete respostas e tabela Azure/AWS/Google Cloud.
