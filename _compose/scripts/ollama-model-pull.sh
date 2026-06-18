#!/bin/sh
set -eu

has_model() {
	model_name="$1"
	ollama list | awk 'NR>1 {print $1}' | grep -Fx "$model_name" >/dev/null 2>&1
}

pull_if_missing() {
	model_name="$1"
	if has_model "$model_name"; then
		printf '%s\n' "Model already exists. Skip pull: $model_name"
	else
		printf '%s\n' "Pulling model: $model_name"
		ollama pull "$model_name"
	fi
}

# 運用方針（2026-06）
# - ドキュメント生成: Llama 3.3 70B
# - コーディング支援: DeepSeek-R1 70B
# - 画像生成: FLUX.2 Klein
#
# このスクリプトは上記3モデルのみを対象にし、未取得時のみ pull します。


pull_if_missing "llama3.3:70b"
pull_if_missing "deepseek-r1:70b"
pull_if_missing "x/flux2-klein"
