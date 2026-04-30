# ffmpeg_getPic

使用 Bash + ffmpeg 批量扫描目录中的 mp4 视频，按配置的帧间隔抽取关键帧并保存到本地目录。

## 功能

- 自动递归扫描指定视频目录中的所有 mp4 文件
- 按 FRAME_INTERVAL 控制抽帧间隔，默认 1800 帧
- 每个视频单独生成一个本地输出目录

## 依赖

运行前请确保系统中已安装：

- ffmpeg

示例安装命令：

```bash
sudo apt update
sudo apt install -y ffmpeg
```

## 文件说明

- extract_keyframes.sh：主脚本，负责抽帧与上传
- config.conf：配置文件，包含本地路径和抽帧参数
- videos/：默认视频目录，脚本会递归扫描其中的 mp4

## 配置

编辑 config.conf：

```bash
# 视频目录（可使用绝对路径或相对脚本目录的路径）
VIDEO_DIR=./videos

# 输出目录（每个视频会创建独立子目录）
OUTPUT_DIR=./output

# 抽帧间隔：至少间隔多少帧再保存下一张关键帧
FRAME_INTERVAL=1800

```

配置说明：

- VIDEO_DIR：本地视频目录，支持绝对路径或相对脚本目录的相对路径
- OUTPUT_DIR：本地图片输出目录
- FRAME_INTERVAL：每隔多少帧保存一次关键帧

## 使用方法

1. 把需要处理的 mp4 放入 VIDEO_DIR 指定的目录，例如默认的 videos/
2. 修改 config.conf 中的视频目录和抽帧间隔
3. 执行脚本：

```bash
chmod +x extract_keyframes.sh
./extract_keyframes.sh
```

## 处理结果

假设视频名为 sample.mp4：

- 本地输出目录：OUTPUT_DIR/sample/
- 生成图片：sample_000001.jpg、sample_000002.jpg ...
- 抽帧逻辑当前以首帧 + 关键帧间隔控制输出数量

## 注意事项

- 该脚本不再包含 SSH 认证或自动上传逻辑
- 如需更改输出位置，修改 `OUTPUT_DIR` 即可