# Achados & Perdidos

API de achados e perdidos criada para a avaliação de Computação em Nuvem. O projeto usa **Flask**, **PostgreSQL** e **Docker Compose** para demonstrar comunicação entre contêineres, inicialização do banco e persistência de itens e fotos.

> **O que aparece no navegador?** A aplicação fornece uma API: as rotas de consulta exibem JSON. O enunciado não pede uma interface gráfica.

## Navegação

- [Preparar e iniciar](#preparar-e-iniciar)
- [Usar a API](#usar-a-api)
- [Executar os testes](#executar-os-testes)
- [Parar ou remover o ambiente](#parar-ou-remover-o-ambiente)
- [Documentação e estado da entrega](#documentação-e-estado-da-entrega)

## Preparar e iniciar

**Pré-requisitos:** Docker Desktop em execução, Docker Compose disponível (`docker compose version`), porta **8080** livre e PowerShell para os roteiros de teste. Execute os comandos na raiz do repositório.

1. Crie o `.env` a partir do modelo, caso ainda não exista:

   ```powershell
   Copy-Item .env.example .env
   notepad .env
   ```

2. No `.env`, defina `POSTGRES_DB`, `POSTGRES_USER` e uma senha própria em `POSTGRES_PASSWORD`. O Compose repassa esses valores à aplicação como `DB_NAME`, `DB_USER` e `DB_PASSWORD`. O `.env` é local e está no `.gitignore`; **não o inclua na entrega**.
3. Valide a configuração e suba os serviços:

   ```powershell
   docker compose config --quiet
   docker compose up -d --build
   docker compose ps
   ```

O serviço `db` deve aparecer como **healthy** e `web` como **running**. Na primeira subida, o PostgreSQL executa [`db/init.sql`](db/init.sql), cria a tabela e insere três itens de exemplo. Esse script só roda automaticamente quando o volume do banco está vazio.

**Endereço da API:** `http://localhost:8080`.

## Usar a API

| Método | Rota | Entrada | Resposta |
| --- | --- | --- | --- |
| GET | `/health` | Nenhuma | Estado da API, conexão com o banco e nome do contêiner. |
| GET | `/itens` | `?local=Biblioteca` é opcional | Lista de itens; o filtro por local ignora diferenças entre maiúsculas e minúsculas. |
| POST | `/itens` | Formulário com `descricao`, `local` e `foto` opcional | HTTP 201 com ID e nome da foto; HTTP 400 se faltar um campo obrigatório. |
| GET | `/fotos/<nome>` | Nome da foto retornado em `/itens` | Arquivo da foto. |
| GET | `/estatisticas` | Nenhuma | Total de itens no banco e arquivos no volume de fotos. |

Para ver as respostas no navegador, abra `/health`, `/itens` ou `/estatisticas`. No PowerShell, as mesmas consultas podem ser feitas com:

```powershell
curl.exe http://localhost:8080/health
curl.exe http://localhost:8080/itens
curl.exe http://localhost:8080/estatisticas
```

O cadastro usa `multipart/form-data`. Troque o caminho do arquivo por uma foto existente no seu computador:

```powershell
curl.exe -X POST http://localhost:8080/itens -F "descricao=Chave" -F "local=Biblioteca" -F "foto=@C:\caminho\foto.png"
```

Para cadastrar sem foto, omita o último `-F`.

## Executar os testes

Com o Docker Desktop iniciado, execute os roteiros na raiz do projeto:

| Etapa | Comando | O que verifica |
| --- | --- | --- |
| TAREFA 4 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\docs\testar-tarefa4.ps1` | Saúde, lista, filtro, cadastro, foto, estatísticas e logs. |
| TAREFA 5 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\docs\testar-tarefa5.ps1 -RemoverVolumes` | Persistência após `down` + `up`, inspeção dos volumes e efeito de `down -v`. |
| TAREFA 6 | `powershell -NoProfile -ExecutionPolicy Bypass -File .\docs\testar-tarefa6.ps1` | Rede, tamanho da imagem, tentativa de escala e usuário do contêiner. |

**Atenção à TAREFA 5:** a opção `-RemoverVolumes` apaga definitivamente os dados dos volumes ao final da prova. O roteiro verifica se há itens fora dos exemplos e dos testes antes dessa etapa. Para preservar dados, execute o script sem a opção; nesse caso, a prova de remoção ficará pendente. Se na TAREFA 4 faltar apenas o registro de logs, repita o comando com `-ApenasLogs`.

As saídas já coletadas estão no [índice de evidências](docs/evidencias/README.md). Não é preciso repetir os testes apenas para consultar os resultados.

## Parar ou remover o ambiente

| Objetivo | Comando | Efeito nos dados |
| --- | --- | --- |
| Parar e remover contêineres e rede | `docker compose down` | Preserva os volumes `dados_banco` e `fotos`. |
| Subir novamente | `docker compose up -d` | Reutiliza os volumes existentes. |
| Destruir também os volumes | `docker compose down -v` | **Apaga itens cadastrados e fotos.** |

Depois de `down -v`, uma nova subida cria volumes vazios. O PostgreSQL executa `init.sql` outra vez e recria somente os três itens de exemplo, sem fotos. A imagem construída permanece no Docker; `docker compose up -d --build` a reconstrói quando necessário.

## Documentação e estado da entrega

| Arquivo | Conteúdo |
| --- | --- |
| [Arquitetura](docs/arquitetura.md) | Diagrama com host, portas, rede, contêineres, volumes e bind mount. |
| [Relatório técnico](docs/RELATORIO.md) | Dockerfile, Compose, caminho de um POST com foto e ciclo dos volumes. |
| [Reflexão](docs/REFLEXAO.md) | Sete questões e equivalência entre o ambiente local e Azure, AWS e Google Cloud. |
| [Evidências](docs/evidencias/README.md) | Resultados das TAREFAS 4, 5 e 6, com arquivos e legendas. |

As tarefas obrigatórias foram implementadas e as provas funcionais e de persistência estão registradas. **Antes da entrega final**, ainda é preciso validar este passo a passo em uma pasta recém-clonada e enviar o link do repositório ou um ZIP sem `.env`. Os desafios bônus do enunciado são opcionais e não foram implementados.
