# QFC Testnet Infrastructure

测试网部署基础设施，包含 Docker、Kubernetes、Terraform 和监控配置。

## 目录结构

```
qfc-testnet/
├── docker/                     # Docker Compose 配置
│   ├── docker-compose.yml      # 单节点开发
│   ├── docker-compose.multi.yml # 多节点 (5 验证者)
│   ├── genesis.json            # 创世区块配置
│   └── nginx.conf              # 负载均衡配置
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

## 常用命令

```bash
# 本地开发 (单节点)
cd docker && docker-compose up -d

# 本地测试网 (5节点)
cd docker && docker-compose -f docker-compose.multi.yml up -d

# Kubernetes 部署
helm install qfc ./k8s/charts/qfc-node -n qfc --create-namespace

# Terraform (AWS)
cd terraform/aws && terraform init && terraform apply

# 查看日志
docker-compose logs -f node-1
kubectl logs -f deployment/qfc-node -n qfc
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
