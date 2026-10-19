# Reflexão e equivalência em nuvem — TAREFA 6

As respostas abaixo relacionam os conceitos do enunciado à configuração real do projeto. Os comandos e resultados citados podem ser conferidos nas [evidências](evidencias/README.md).

> As medidas de proteção e os serviços de nuvem mencionados aqui são propostas de evolução. A implementação entregue é o ambiente local descrito no [README](../README.md).

## Q1. Nome `db` e resolução

- Em [`docker-compose.yml`](../docker-compose.yml), `web` e `db` estão na mesma `rede_interna`.
- O DNS embutido do Docker registra o nome do serviço `db` e o resolve dentro dessa rede, evitando fixar o IP, que pode mudar quando o contêiner é recriado.
- Com `docker run` na rede bridge padrão, os contêineres não recebem essa resolução automática por nome; seria preciso criar uma rede bridge definida pelo usuário e conectá-los a ela, ou usar outra configuração de comunicação.
- Referência: [redes do Compose](https://docs.docker.com/compose/how-tos/networking/) e [rede bridge do Docker](https://docs.docker.com/engine/network/drivers/bridge/).

## Q2. Volume nomeado e bind mount

- Volume nomeado é armazenamento gerenciado pelo Docker e identificado pelo nome; bind mount mapeia um caminho escolhido no host para o contêiner.
- [`dados_banco`](../docker-compose.yml) é volume nomeado porque os arquivos internos do PostgreSQL precisam sobreviver à recriação do contêiner sem depender de um diretório específico do projeto.
- `db/init.sql` é um arquivo de texto versionado no projeto e foi montado como bind mount somente leitura, para o PostgreSQL lê-lo na inicialização de um banco vazio.
- A [inspeção dos volumes](evidencias/tarefa5/resultado.md) confirma as duas montagens persistentes.

## Q3. Alteração em `init.sql`

- Rodar `docker compose up -d` novamente não aplica uma mudança em `db/init.sql` a um banco já inicializado.
- Os scripts de `/docker-entrypoint-initdb.d/` são executados quando o diretório de dados do PostgreSQL está vazio; [`dados_banco`](../docker-compose.yml) preserva esse diretório entre subidas.
- Para acrescentar uma coluna sem perder dados, faça backup e execute uma migração, por exemplo `ALTER TABLE itens ADD COLUMN ...`, de forma controlada e versionada.
- A [prova de remoção](evidencias/tarefa5/resultado.md) mostra que o script só voltou a rodar quando o volume foi apagado. Referência: [guia de PostgreSQL do Docker](https://docs.docker.com/guides/postgresql/networking-and-connectivity/).

## Q4. `depends_on` e saúde

- A simples criação ou partida do processo do banco não significa que o PostgreSQL já aceite conexões e que o banco solicitado esteja pronto.
- Se `web` iniciar nesse intervalo, sua primeira conexão pode falhar.
- O [`healthcheck` e `condition: service_healthy`](../docker-compose.yml) fazem o Compose aguardar `pg_isready` antes de iniciar `web`.
- Isso reduz falhas na primeira subida, embora uma aplicação em produção ainda deva lidar com indisponibilidades posteriores do banco.

## Q5. Cache de camadas

- No [`Dockerfile`](../app/Dockerfile), `COPY requirements.txt` vem antes de `RUN pip install`, que vem antes de `COPY app.py`.
- O Docker pode reaproveitar as camadas de dependências enquanto `requirements.txt` e as instruções anteriores não mudarem.
- Quando só `app.py` muda, a cópia do código e as camadas seguintes são refeitas, mas o `pip install` pode usar o cache do build.
- Isso evita reinstalar todas as dependências a cada alteração pequena no código.

## Q6. Porta do banco e proteção de fotos

- O [Compose](../docker-compose.yml) publica apenas `8080:5000`; a porta 5432 fica acessível pela rede interna para `web`, reduzindo a exposição direta do PostgreSQL no host.
- Uma foto de RG ou carteira pode conter dados pessoais; o [art. 46 da LGPD](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/L13709.htm) exige medidas técnicas e administrativas contra acesso não autorizado e situações acidentais ou ilícitas.
- Medida adicional 1: exigir autenticação e autorização para cadastrar e consultar fotos, inclusive em `GET /fotos/<nome>`.
- Medida adicional 2: criptografar dados e backups, restringindo as permissões de acesso às chaves e definindo prazo de retenção para as fotos.
- O código atual fornece a rota de foto sem autenticação; essas medidas são propostas para uma implantação real, não características já implementadas.

## Q7. Três réplicas de `web`

- O comando pedido é `docker compose up -d --scale web=3`; [`docs/testar-tarefa6.ps1`](testar-tarefa6.ps1) registra sua saída e restaura uma réplica.
- Com `ports: "8080:5000"` fixo no [Compose](../docker-compose.yml), houve conflito: a [tentativa registrada](evidencias/tarefa6/05-scale-web-3.txt) falhou com `port is already allocated`, pois três contêineres não podem publicar a mesma porta 8080 do mesmo host simultaneamente.
- Para três réplicas, remova a publicação fixa de `web` e coloque um proxy ou balanceador na frente, publicando 8080 uma vez; o banco continua em serviço separado.
- Um volume `fotos` compartilhado pode ser tecnicamente montado nas três réplicas de um mesmo host, mas exige escrita concorrente e acesso consistentes. Para escala em vários hosts, prefira armazenamento de objetos e adapte o código. O UUID reduz colisões de nomes, mas não resolve todos os problemas de consistência.

## 5.1. Do ambiente local para a nuvem

Equivalência **funcional** dos componentes; nomes e configurações mudam conforme o provedor.

| Peça local | Microsoft Azure | AWS | Google Cloud |
| --- | --- | --- | --- |
| Contêiner `web` | Azure Container Apps | Amazon ECS com AWS Fargate | Cloud Run |
| Contêiner `db` + `dados_banco` | Azure Database for PostgreSQL | Amazon RDS for PostgreSQL | Cloud SQL for PostgreSQL |
| Volume `fotos` | Azure Blob Storage | Amazon S3 | Cloud Storage |
| `rede_interna` | Azure Virtual Network + acesso privado aos serviços | Amazon VPC + sub-redes privadas e security groups | VPC + acesso privado/egresso VPC para serviços |
| `.env` (segredos) | Azure Key Vault | AWS Secrets Manager | Secret Manager |
| Imagem construída localmente | Azure Container Registry | Amazon ECR | Artifact Registry |

Esta tabela indica equivalências de função, não uma migração automática do Compose. A peça que exige mais mudança no código é `fotos`: [`app.py`](../app/app.py) usa `foto.save()` e `send_from_directory()` em um diretório local. Em serviços com múltiplas instâncias, a aplicação precisaria gravar e ler os arquivos pela API do armazenamento de objetos, guardar a chave do objeto no banco e configurar permissões para cada operação. A rede, credenciais e publicação da imagem também exigem configuração própria de cada provedor.

Fontes dos serviços: [Azure Container Apps e VNet](https://learn.microsoft.com/en-us/azure/container-apps/custom-virtual-networks), [arquitetura AWS com ECS, RDS, S3, VPC, ECR e Secrets Manager](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/access-container-applications-privately-on-amazon-ecs-by-using-aws-fargate-aws-privatelink-and-a-network-load-balancer.html) e [integrações do Cloud Run](https://docs.cloud.google.com/run/docs/integrate/using-gcp-services).
