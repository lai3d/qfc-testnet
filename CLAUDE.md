# QFC Testnet Infrastructure

测试网部署基础设施，包含 Docker、Kubernetes、Terraform 和监控配置。

## 目录结构

```
qfc-testnet/
├── docker/                     # Docker Compose 配置
│   ├── docker-compose.yml      # 单节点开发
│   ├── docker-compose.multi.yml # 多节点 (5 验证者)
│   ├── genesis.json            # 创世区块配置
│   ├── nginx.conf              # 负载均衡配置 (本地)
│   ├── nginx.production.conf   # 负载均衡配置 (生产)
│   ├── .env                    # 环境变量 (本地)
│   └── .env.production.example # 环境变量示例 (生产)
├── k8s/                        # Kubernetes
│   └── charts/qfc-node/        # Helm Chart
├── terraform/                  # 基础设施即代码
│   ├── aws/                    # AWS 部署
│   ├── gcp/                    # GCP 部署
│   └── modules/                # 共享模块
└── monitoring/                 # 监控
    ├── prometheus/             # 指标收集
    ├── grafana/                # 仪表板
    └── alertmanager/           # 告警
```

## 部署模式

### 本地开发 (Local)

使用默认 `.env` 配置，服务通过 localhost 访问：

```bash
cd docker

# 核心服务 (node + explorer + postgres + redis)
docker compose up -d

# 包含监控 (+ prometheus + grafana + alertmanager)
docker compose --profile monitoring up -d

# 包含水龙头 (+ faucet)
docker compose --profile faucet up -d

# 全部服务
docker compose --profile monitoring --profile faucet up -d
```

访问地址：
- Explorer: http://localhost:3000
- RPC: http://localhost:8545
- Grafana: http://localhost:3002 (需要 `--profile monitoring`)

### 生产部署 (Production)

1. 复制并修改配置文件：
```bash
cp .env.production.example .env
# 编辑 .env，设置域名和安全密钥
```

2. 配置 SSL 证书（使用 Let's Encrypt）：
```bash
certbot certonly --standalone -d rpc.testnet.qfc.network \
  -d explorer.testnet.qfc.network \
  -d faucet.testnet.qfc.network \
  -d grafana.testnet.qfc.network
```

3. 启动服务：
```bash
docker compose -f docker-compose.multi.yml up -d
```

访问地址（示例域名）：
- Explorer: https://explorer.testnet.qfc.network
- RPC: https://rpc.testnet.qfc.network
- WebSocket: wss://rpc.testnet.qfc.network/ws
- Faucet: https://faucet.testnet.qfc.network
- Grafana: https://grafana.testnet.qfc.network

## 常用命令

```bash
# 本地开发 (单节点，核心服务)
cd docker && docker compose up -d

# 本地开发 (含监控)
cd docker && docker compose --profile monitoring up -d

# 本地测试网 (5节点)
cd docker && docker compose -f docker-compose.multi.yml up -d

# 停止所有服务
cd docker && docker compose --profile monitoring --profile faucet down

# Kubernetes 部署
helm install qfc ./k8s/charts/qfc-node -n qfc --create-namespace

# Terraform (AWS)
cd terraform/aws && terraform init && terraform apply

# 查看日志
docker compose logs -f qfc-node
kubectl logs -f deployment/qfc-node -n qfc

# 重建单个服务
docker compose build explorer --no-cache
docker compose up -d explorer
```

## 服务端口

| 服务 | 端口 | 说明 |
|------|------|------|
| RPC | 8545 | JSON-RPC API |
| WebSocket | 8546 | WebSocket 订阅 |
| P2P | 30303 | 节点间通信 |
| Metrics | 6060 | Prometheus 指标 |
| Explorer | 3000 | 区块浏览器 |
| Faucet | 3001 | 测试币水龙头 |
| Grafana | 3002 | 监控仪表板 |
| Prometheus | 9090 | 指标服务 |

## 环境变量

关键配置项（在 `.env` 中设置）：

| 变量 | 本地默认值 | 生产示例 |
|------|-----------|----------|
| `NEXT_PUBLIC_RPC_URL` | http://localhost:8545 | https://rpc.testnet.qfc.network |
| `NEXT_PUBLIC_WS_URL` | ws://localhost:8546 | wss://rpc.testnet.qfc.network |
| `NEXT_PUBLIC_BASE_URL` | http://127.0.0.1:3000 | https://explorer.testnet.qfc.network |
| `GRAFANA_ROOT_URL` | http://localhost:3002 | https://grafana.testnet.qfc.network |

## 监控告警

已配置告警规则：
- 节点离线 > 1 分钟
- 区块生产停止 > 2 分钟
- 内存/磁盘使用率过高
- 验证者数量不足
- 网络延迟过高

## 依赖项目

- `qfc-core` - 区块链核心 (构建节点镜像)
- `qfc-explorer` - 区块浏览器
- `qfc-faucet` - 测试网水龙头

## 网络配置

| 网络 | Chain ID | 验证者数 |
|------|----------|----------|
| 本地开发 | 9000 | 1 |
| 本地测试 | 9000 | 5 |
| 公开测试网 | 9000 | 10+ |
| 主网 | 9001 | 21+ |
