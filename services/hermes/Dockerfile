FROM nousresearch/hermes-agent:latest

# 1. タイムゾーンとシステム言語の設定
ENV TZ=Asia/Tokyo
ENV LANG=ja_JP.UTF-8
ENV LANGUAGE=ja

ARG LITELLM_PORT=4000

# 2. 一時ディレクトリ（/tmp）へ config.yaml をコピーして置換
RUN mkdir -p /tmp/hermes_init
COPY config.yaml /tmp/hermes_init/config.yaml

# 正規表現を使って、:-数字 の有無に関わらず実値へ置換
RUN sed -i -E "s/\\\$\{LITELLM_PORT(:-[0-9]+)?\}/${LITELLM_PORT}/g" /tmp/hermes_init/config.yaml

# Hermes のログイン画面は英語固定実装のため、ビルド時に日本語文言へ置換する
RUN python - <<'PY'
from pathlib import Path

path = Path('/opt/hermes/hermes_cli/dashboard_auth/login_page.py')
text = path.read_text(encoding='utf-8')

replacements = {
	'<html lang="en">': '<html lang="ja">',
	'<title>Sign in — Hermes Agent</title>': '<title>サインイン — Hermes Agent</title>',
	'<h1>Sign in</h1>': '<h1>サインイン</h1>',
	'Choose a sign-in method to continue to the Hermes Agent dashboard.': 'Hermes Agent ダッシュボードに進むため、サインイン方法を選択してください。',
	'Public bind &middot; Auth required': '公開バインド &middot; 認証が必要です',
	'<title>Sign-in unavailable — Hermes Agent</title>': '<title>サインイン不可 — Hermes Agent</title>',
	'<h1>Sign-in unavailable</h1>': '<h1>サインインできません</h1>',
	'This dashboard is bound to a non-loopback host but no authentication\nproviders are installed.': 'このダッシュボードはループバック以外のホストに公開されていますが、認証プロバイダが設定されていません。',
	'Install <code>plugins/dashboard-auth-nous</code> (default) or another\nauth provider, or restart with <code>--insecure</code> to bypass the\nauth gate (not recommended on untrusted networks).': 'デフォルトの <code>plugins/dashboard-auth-nous</code> または別の認証プロバイダを導入するか、<code>--insecure</code> で再起動してください（信頼できないネットワークでは非推奨）。',
	'Too many attempts. Please wait and try again.': '試行回数が多すぎます。しばらく待ってから再試行してください。',
	'Invalid username or password.': 'ユーザー名またはパスワードが正しくありません。',
	'Sign-in failed. Please try again.': 'サインインに失敗しました。もう一度お試しください。',
	'Network error. Please try again.': 'ネットワークエラーです。もう一度お試しください。',
	'Sign in with ': 'サインイン: ',
	'<span class="field-label">Username</span>': '<span class="field-label">ユーザー名</span>',
	'<span class="field-label">Password</span>': '<span class="field-label">パスワード</span>',
	'<button class="provider-btn" type="submit">Sign in</button>': '<button class="provider-btn" type="submit">サインイン</button>',
}

for old, new in replacements.items():
	text = text.replace(old, new)

path.write_text(text, encoding='utf-8')

basic_auth_path = Path('/opt/hermes/plugins/dashboard_auth/basic/__init__.py')
basic_auth_text = basic_auth_path.read_text(encoding='utf-8')
basic_auth_text = basic_auth_text.replace('display_name = "Username & Password"', 'display_name = "ユーザー名とパスワード"')
basic_auth_path.write_text(basic_auth_text, encoding='utf-8')
PY

# ダッシュボードの既定ロケールを en から ja に変更する
RUN python - <<'PY'
from pathlib import Path

assets_dir = Path('/opt/hermes/hermes_cli/web_dist/assets')
for path in assets_dir.glob('index-*.js'):
	text = path.read_text(encoding='utf-8')
	text = text.replace('return"en"}const zA=p.createContext({locale:"en",setLocale:()=>{},t:LA});', 'return"ja"}const zA=p.createContext({locale:"ja",setLocale:()=>{},t:LA});')
	path.write_text(text, encoding='utf-8')
PY

# 3. 起動スクリプト（entrypoint.sh）をコンテナのルート「/」に直接作成
# マウントされた /root/.hermes に、起動のたびに設定を同期します
RUN echo '#!/bin/bash\n\
mkdir -p /root/.hermes\n\
cp -f /tmp/hermes_init/config.yaml /root/.hermes/config.yaml\n\
mkdir -p /opt/data\n\
cp -f /tmp/hermes_init/config.yaml /opt/data/config.yaml\n\
chown hermes:hermes /opt/data/config.yaml 2>/dev/null || true\n\
exec /init "$@"' > /entrypoint.sh

# 4. スクリプトに実行権限を付与
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

# 5. 自作のスクリプトをエントリーポイントに指定
ENTRYPOINT ["/entrypoint.sh"]