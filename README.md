# QFC Testnet Infrastructure

QFC 区块链测试网部署基础设施，包含 Docker、Kubernetes、Terraform 配置和监控系统。

## 目录结构

```
qfc-testnet/
├── docker/                     # Docker Compose 配置
│   ├── docker-compose.yml      # 单节点开发环境
│   ├── docker-compose.multi.yml # 多节点测试网
│   └── .env.example            # 环境变量模板
├── k8s/                        # Kubernetes 配置
│   ├── charts/                 # Helm Charts
│   │   └── qfc-node/           # QFC 节点 Chart
│   └── base/                   # 基础 Manifests
├── terraform/                  # Terraform IaC
│   ├── aws/                    # AWS 部署
│   ├── gcp/                    # GCP 部署
│   └── modules/                # 可复用模块
├── monitoring/                 # 监控配置
│   ├── prometheus/             # Prometheus 配置
│   ├── grafana/                # Grafana 仪表板
│   └── alertmanager/           # 告警配置
└── scripts/                    # 部署脚本
```

## 快速开始

### 1. 本地开发 (单节点)

```bash
cd docker
cp .env.example .env
docker-compose up -d
```

访问:
- RPC: http://localhost:8545
- Explorer: http://localhost:3000
- Faucet: http://localhost:3001
- Grafana: http://localhost:3002

### 2. 本地测试网 (多节点)

```bash
cd docker
docker-compose -f docker-compose.multi.yml up -d
```

启动 5 个验证者节点 + 完整基础设施。

### 3. Kubernetes 部署

```bash
# 安装 Helm Chart
helm install qfc-testnet ./k8s/charts/qfc-node \
  --namespace qfc \
  --create-namespace \
  -f k8s/charts/qfc-node/values-testnet.yaml
```

### 4. 云部署 (Terraform)

```bash
cd terraform/aws
terraform init
terraform plan
terraform apply
```

## 环境配置

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `QFC_CHAIN_ID` | 链 ID | 9000 |
| `QFC_NETWORK` | 网络名称 | testnet |
| `QFC_NODE_COUNT` | 节点数量 | 5 |
| `QFC_RPC_PORT` | RPC 端口 | 8545 |
| `QFC_P2P_PORT` | P2P 端口 | 30303 |
| `QFC_METRICS_PORT` | 指标端口 | 9090 |

## 监控

### Grafana 仪表板

- **QFC Overview**: 网络总览 (TPS, 区块高度, 节点数)
- **Node Metrics**: 单节点详情 (CPU, 内存, 磁盘)
- **Consensus**: 共识状态 (出块时间, 验证者活跃度)
- **Transactions**: 交易统计 (成功率, Gas 使用)

### 告警规则

- 节点离线 > 5 分钟
- 区块生产停止 > 1 分钟
- 内存使用 > 90%
- 磁盘使用 > 85%
- 共识分叉检测

## 架构图

```
                    ┌─────────────────────────────────────┐
                    │           Load Balancer             │
                    │        (Nginx / AWS ALB)            │
                    └──────────────┬──────────────────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
        ▼                          ▼                          ▼
┌───────────────┐        ┌───────────────┐        ┌───────────────┐
│   Validator   │◄──────►│   Validator   │◄──────►│   Validator   │
│    Node 1     │  P2P   │    Node 2     │  P2P   │    Node 3     │
│   (Leader)    │        │  (Standby)    │        │  (Standby)    │
└───────┬───────┘        └───────┬───────┘        └───────┬───────┘
        │                        │                        │
        └────────────────────────┼────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                    ▼                         ▼
            ┌─────────────┐           ┌─────────────┐
            │  Explorer   │           │   Faucet    │
            │  (Next.js)  │           │  (Next.js)  │
            └─────────────┘           └─────────────┘
                    │
                    ▼
            ┌─────────────┐
            │ PostgreSQL  │
            │  (Indexer)  │
            └─────────────┘

        ┌─────────────────────────────────────────────┐
        │              Monitoring Stack               │
        │  ┌──────────┐ ┌──────────┐ ┌─────────────┐  │
        │  │Prometheus│ │ Grafana  │ │AlertManager │  │
        │  └──────────┘ └──────────┘ └─────────────┘  │
        └─────────────────────────────────────────────┘
```

## 常用命令

```bash
# 查看节点日志
docker-compose logs -f node-1

# 进入节点容器
docker-compose exec node-1 /bin/sh

# 重启单个服务
docker-compose restart explorer

# 查看节点状态
curl http://localhost:8545 -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"qfc_getNodeInfo","params":[],"id":1}'

# Kubernetes: 查看 Pod 状态
kubectl get pods -n qfc

# Kubernetes: 查看日志
kubectl logs -f deployment/qfc-node-0 -n qfc
```

## 故障排除

### 节点无法同步
1. 检查 P2P 端口是否开放
2. 验证 bootnodes 配置
3. 查看节点日志中的错误

### 共识停止
1. 检查验证者数量 (至少 2/3 在线)
2. 检查网络时间同步
3. 查看共识日志

### 监控无数据
1. 确认 Prometheus 目标状态
2. 检查节点 metrics 端口
3. 验证 Grafana 数据源配置

## License

MIT
