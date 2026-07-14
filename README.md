# AutoBuild Docker

Docker 镜像构建仓库 通过 GitHub Actions 自动化构建, 推送到 Docker Hub 和 GHCR

## 项目

| 目录 | 说明 |
|------|------|
| `derper/` | Tailscale DERP 中继服务器 (独立二进制) |
| `jupyterhub/` | JupyterHub + Dockerspawner + Idle Culler + Native Authenticator |
| `jupyterlab/` | JupyterLab + 中文语言包 + R Kernel + code-server + Zsh |
| `sharelatex/` | Overleaf + 全套 TeX Live + 中文字体 |

## 构建

所有构建通过手动触发 [build.yml](.github/workflows/build.yml) (`workflow_dispatch`),
并推送到:

- **Docker Hub**: `v8040/<项目名>:latest`
- **GHCR**: `ghcr.io/v8040/<项目名>:latest`

## 镜像同步

[images.txt](./images.txt) 中的镜像通过 [sync.yml](.github/workflows/sync.yml) 同步到腾讯云 TCR (`ccr.ccs.tencentyun.com`)
