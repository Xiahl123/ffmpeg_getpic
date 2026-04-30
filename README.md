# ffmpeg_getPic

使用 Bash + ffmpeg 批量扫描目录中的 `mp4` 视频，按配置的帧间隔抽取关键帧，并可在抽帧完成后通过 `scp` 上传到远程服务器。

## 功能

- 自动递归扫描指定视频目录中的所有 `mp4` 文件
- 按 `FRAME_INTERVAL` 控制抽帧间隔，默认 `1800` 帧
- 每个视频单独生成一个本地输出目录
- 支持将抽取出的图片通过 `scp` 上传到服务器
- 上传后远端文件名保持与本地一致

## 依赖

运行前请确保系统中已安装：

- `ffmpeg`
- `ssh` / `scp`（一般由 `openssh-client` 提供）

示例安装命令：

```bash
sudo apt update
sudo apt install -y ffmpeg openssh-client
```

## 文件说明

- `extract_keyframes.sh`：主脚本，负责抽帧与上传
- `config.conf`：配置文件，包含本地路径、抽帧参数和远程服务器信息
- `videos/`：默认视频目录，脚本会递归扫描其中的 `mp4`

## 配置

编辑 `config.conf`：

```bash
# 视频目录（可使用绝对路径或相对脚本目录的路径）
VIDEO_DIR=./videos

# 输出目录（每个视频会创建独立子目录）
OUTPUT_DIR=./output

# 抽帧间隔：至少间隔多少帧再保存下一张关键帧
FRAME_INTERVAL=1800

# 是否在抽帧后上传图片到服务器：1=上传，0=不上传
UPLOAD_ENABLED=1

# 服务器 SSH 信息
SSH_HOST=example.com
SSH_PORT=22
SSH_USER=root

# 远程图片根目录
REMOTE_DIR=/data/ffmpeg_frames

# SSH 私钥路径，留空则使用默认 SSH 配置
SSH_KEY=
```

配置说明：

- `VIDEO_DIR`：本地视频目录，支持绝对路径或相对脚本目录的相对路径
- `OUTPUT_DIR`：本地图片输出目录
- `FRAME_INTERVAL`：每隔多少帧保存一次关键帧
- `UPLOAD_ENABLED`：是否启用上传，`1` 为启用，`0` 为关闭
- `SSH_HOST` / `SSH_PORT` / `SSH_USER`：服务器连接信息
- `REMOTE_DIR`：远端保存目录，脚本会在其下按视频名创建子目录
- `SSH_KEY`：指定私钥路径时会优先使用该密钥

## 使用方法

1. 把需要处理的 `mp4` 放入 `VIDEO_DIR` 指定的目录，例如默认的 `videos/`
2. 修改 `config.conf` 中的视频目录、抽帧间隔和服务器信息
3. 执行脚本：

```bash
chmod +x extract_keyframes.sh
./extract_keyframes.sh
```

## 处理结果

假设视频名为 `sample.mp4`：

- 本地输出目录：`OUTPUT_DIR/sample/`
- 生成图片：`sample_000001.jpg`、`sample_000002.jpg` ...
- 如果启用上传，远端目录会创建为：`REMOTE_DIR/sample/`

## 注意事项

- 上传功能依赖 `scp` 和 `ssh` 可用
- 如果启用了上传，但未正确配置 `SSH_HOST`、`SSH_USER` 或 `REMOTE_DIR`，脚本会直接退出并提示错误
- 抽帧逻辑当前以关键帧为主，并结合帧间隔控制输出数量

## 常见场景

### 仅本地抽帧

将 `UPLOAD_ENABLED=0`，然后运行脚本即可。

### 抽帧后自动上传

将 `UPLOAD_ENABLED=1`，并填写 `SSH_HOST`、`SSH_USER`、`REMOTE_DIR`，如有需要再配置 `SSH_KEY`。
