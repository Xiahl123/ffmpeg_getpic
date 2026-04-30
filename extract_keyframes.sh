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
UPLOAD_ENABLED="${UPLOAD_ENABLED:-0}"
SSH_HOST="${SSH_HOST:-}"
SSH_PORT="${SSH_PORT:-22}"
SSH_USER="${SSH_USER:-}"
REMOTE_DIR="${REMOTE_DIR:-}"
SSH_KEY="${SSH_KEY:-}"

# 将相对路径转为相对脚本目录的绝对路径
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

if [[ "${UPLOAD_ENABLED}" != "0" && "${UPLOAD_ENABLED}" != "1" ]]; then
  echo "UPLOAD_ENABLED 只能是 0 或 1，当前值: ${UPLOAD_ENABLED}"
  exit 1
fi

if [[ "${UPLOAD_ENABLED}" == "1" ]]; then
  if [[ -z "${SSH_HOST}" || -z "${SSH_USER}" || -z "${REMOTE_DIR}" ]]; then
    echo "启用上传时必须在 config.conf 中配置 SSH_HOST、SSH_USER 和 REMOTE_DIR。"
    exit 1
  fi
  if ! command -v scp >/dev/null 2>&1; then
    echo "未找到 scp，请先安装 openssh-client。"
    exit 1
  fi
  if ! command -v ssh >/dev/null 2>&1; then
    echo "未找到 ssh，请先安装 openssh-client。"
    exit 1
  fi
fi

mkdir -p "${OUTPUT_DIR}"

scp_base=(scp -P "${SSH_PORT}")
ssh_base=(ssh -p "${SSH_PORT}")

if [[ -n "${SSH_KEY}" ]]; then
  scp_base+=(-i "${SSH_KEY}")
  ssh_base+=(-i "${SSH_KEY}")
fi

remote_target="${SSH_USER}@${SSH_HOST}"

upload_images() {
  local source_dir="$1"
  local remote_subdir="$2"

  if [[ "${UPLOAD_ENABLED}" != "1" ]]; then
    return 0
  fi

  local image_files=("${source_dir}"/*.jpg)
  if [[ ! -e "${image_files[0]}" ]]; then
    echo "警告: ${remote_subdir} 未找到可上传图片，跳过上传。"
    return 0
  fi

  "${ssh_base[@]}" "${remote_target}" "mkdir -p '${REMOTE_DIR}/${remote_subdir}'"
  "${scp_base[@]}" "${image_files[@]}" "${remote_target}:${REMOTE_DIR}/${remote_subdir}/"
}

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
    -vf "select='eq(pict_type\\,I)*gte(n-prev_selected_n\\,${FRAME_INTERVAL})'" \
    -vsync vfr \
    "${target_dir}/${video_stem}_%06d.jpg"

  extracted_count=$(find "${target_dir}" -maxdepth 1 -type f -name "${video_stem}_*.jpg" | wc -l | tr -d ' ')
  upload_images "${target_dir}" "${video_stem}"
  echo "完成: ${video_name}，输出 ${extracted_count} 张"
  processed=$((processed + 1))
done

echo "全部完成。已处理 ${processed} 个视频。输出目录: ${OUTPUT_DIR}"
