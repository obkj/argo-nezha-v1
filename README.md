# Argo Nezha Dashboard V1

本项目修改自 [yutian81/argo-nezha-v1](https://github.com/yutian81/argo-nezha-v1)


备份和恢复脚本修改自 [fscarmen2/Argo-Nezha-Service-Container](https://github.com/fscarmen2/Argo-Nezha-Service-Container)

# 部署方法

1、克隆仓库并进入仓库目录

```bash
git clone https://github.com/fxf981/argo-nezha-v1.git
cd argo-nezha-v1
```

2、编辑.env文件
```bash
nano .env
```

3、拉取最新镜像
```bash
docker-compose pull
```

4、启动容器
```bash
docker-compose up -d
```