#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.conf"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "配置文件不存在: ${CONFIG_FILE}"
  exit 1
fi

# shellcheck disable=SC1090
source "${CONFIG_FILE}"

VIDEO_DIR="${VIDEO_DIR:-./videos}"
OUTPUT_DIR="${OUTPUT_DIR:-./output}"
FRAME_INTERVAL="${FRAME_INTERVAL:-1800}"

if [[ "${VIDEO_DIR}" != /* ]]; then
  VIDEO_DIR="${SCRIPT_DIR}/${VIDEO_DIR}"
fi
if [[ "${OUTPUT_DIR}" != /* ]]; then
  OUTPUT_DIR="${SCRIPT_DIR}/${OUTPUT_DIR}"
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "未找到 ffmpeg，请先安装 ffmpeg。"
  exit 1
fi

if [[ ! -d "${VIDEO_DIR}" ]]; then
  echo "视频目录不存在: ${VIDEO_DIR}"
  exit 1
fi

if ! [[ "${FRAME_INTERVAL}" =~ ^[0-9]+$ ]] || [[ "${FRAME_INTERVAL}" -le 0 ]]; then
  echo "FRAME_INTERVAL 必须是正整数，当前值: ${FRAME_INTERVAL}"
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

echo "开始扫描目录: ${VIDEO_DIR}"
mapfile -d '' mp4_files < <(find "${VIDEO_DIR}" -type f \( -iname "*.mp4" \) -print0)

if [[ "${#mp4_files[@]}" -eq 0 ]]; then
  echo "未找到 mp4 文件。"
  exit 0
fi

echo "共找到 ${#mp4_files[@]} 个 mp4 文件，开始抽取关键帧..."

processed=0
for video_path in "${mp4_files[@]}"; do
  video_name="$(basename "${video_path}")"
  video_stem="${video_name%.*}"

  target_dir="${OUTPUT_DIR}/${video_stem}"
  mkdir -p "${target_dir}"

  echo "处理: ${video_name}"

  ffmpeg -hide_banner -loglevel error -y \
    -i "${video_path}" \
    -vf "select='eq(n\\,0)+eq(pict_type\\,I)*gte(n-prev_selected_n\\,${FRAME_INTERVAL})'" \
    -vsync vfr \
    "${target_dir}/${video_stem}_%06d.jpg"

  extracted_count=$(find "${target_dir}" -maxdepth 1 -type f -name "${video_stem}_*.jpg" | wc -l | tr -d ' ')
  echo "完成: ${video_name}，输出 ${extracted_count} 张"
  processed=$((processed + 1))
done

echo "全部完成。已处理 ${processed} 个视频。输出目录: ${OUTPUT_DIR}"