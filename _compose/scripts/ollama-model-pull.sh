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

# コーディング・Markdown出力推奨モデル
# qwen2.5-coder (7B または 32B) [推奨度: ★★★★★]
#. 特徴: コード理解力が極めて高く、ドキュメント生成、コメント追加、リファクタリングのすべてにおいて商用モデルに迫る精度です。日本語の出力品質も非常に安定しています。
# gemma4 (26B) / gemma3 (4B / 16B) [推奨度: ★★★★☆]
#. 特徴: Googleの最新モデル。文脈の理解力（コンテキストウィンドウ）が広く、長大なプログラムを一気に読み込ませても破綻しにくいのが強みです。解説の日本語がとても自然です。
# codegemma (7B) [推奨度: ★★★☆☆]
#. 特徴: Google製のコード特化型。動作が比較的軽量で、関数の目的や引数・戻り値の仕様を箇条書きでまとめるような標準的ドキュメント作成に向いています。

# 画像読み込み推奨モデル
# gemma3 (27B) [推奨度: ★★★★★]
#. 特徴: Googleの最新マルチモーダルモデル。画像の読み取り精度が非常に高く、日本語の文章構成力もトップクラスです。画面レイアウトからの仕様書起こしや、複雑な図の解説に最も向いています。
# llama3.2-vision (11B / 90B) [推奨度: ★★★★☆]
#. 特徴: Meta製の定番ビジョンモデル。11Bサイズは画像対応モデルとしては比較的軽量で動作が速く、グラフの読み取りや手書き文字の認識、コードの画面キャプチャからのドキュメント化をバランスよくこなします。
# minicpm-v (8B前後) [推奨度: ★★★☆☆]
#. 特徴: 非常に軽量ながら高解像度画像の認識に強いモデル。PCのスペックが限られている環境で、図表の細かい文字を読み取らせたい場合に重宝します。


pull_if_missing "qwen2.5:3b-instruct"
pull_if_missing "qwen2.5:7b-instruct"
