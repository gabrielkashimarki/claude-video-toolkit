#!/usr/bin/env bash
# Instala tudo que o Claude Code precisa para editar vídeo de anúncio num Mac Apple Silicon.
# Pode rodar de novo quantas vezes quiser: o que já existe é atualizado, não duplicado.
set -euo pipefail

REPO_URL="https://github.com/gabrielkashimarki/claude-video-toolkit"
BASE="$HOME/.video-toolkit"
SKILLS="$HOME/.claude/skills"

passo() { printf '\n==> %s\n' "$*"; }
aviso() { printf 'AVISO: %s\n' "$*"; }

# Acrescenta uma linha ao ~/.zprofile só se ela ainda não estiver lá.
linha_no_zprofile() {
  touch "$HOME/.zprofile"
  grep -qxF "$1" "$HOME/.zprofile" || printf '%s\n' "$1" >> "$HOME/.zprofile"
}

# Cria (ou atualiza) um atalho para a skill. Pasta de verdade no lugar não é mexida.
ligar_skill() {
  local origem="$1" destino="$SKILLS/$2"
  if [ -e "$destino" ] && [ ! -L "$destino" ]; then
    aviso "$destino já existe e não é atalho; deixei como está."
  else
    ln -sfn "$origem" "$destino"
  fi
}

# Clona o repositório ou, se já existir, puxa a versão nova.
clonar_ou_atualizar() {
  local url="$1" pasta="$2"
  shift 2
  if [ -d "$pasta/.git" ]; then
    git -C "$pasta" pull --ff-only --quiet || aviso "não consegui atualizar $pasta (segue a versão que já está lá)."
  elif [ -e "$pasta" ]; then
    aviso "$pasta existe mas não é um clone do git; deixei como está."
  else
    git clone --quiet "$@" "$url" "$pasta"
  fi
}

[ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ] || {
  echo "Este instalador é só para Mac com chip Apple (M1, M2, M3...)."
  exit 1
}

# Rodando por "curl ... | bash": baixa o toolkit inteiro e roda a cópia baixada.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"
if [ ! -f "$DIR/skills/edicao-anuncio/SKILL.md" ]; then
  passo "Baixando o toolkit"
  if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install || true
    echo "Abriu uma janela para instalar as ferramentas de linha de comando da Apple. Termine essa instalação e rode o comando de novo."
    exit 1
  fi
  mkdir -p "$BASE/src"
  clonar_ou_atualizar "$REPO_URL" "$BASE/src/claude-video-toolkit" --depth 1
  exec bash "$BASE/src/claude-video-toolkit/install.sh" </dev/tty
fi

passo "Homebrew"
if [ ! -x /opt/homebrew/bin/brew ]; then
  echo "Vai pedir a senha do seu Mac (a mesma de desbloquear a tela). Ao digitar, nada aparece na tela, é normal."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
linha_no_zprofile 'eval "$(/opt/homebrew/bin/brew shellenv)"'

passo "Programas (ffmpeg completo, sox, rclone, node, git, uv, python)"
# ffmpeg-full: o ffmpeg comum do Homebrew vem sem drawtext e sem subtitles (libass).
brew install ffmpeg-full sox rclone node git uv python@3.13
FFMPEG_BIN="$(brew --prefix ffmpeg-full)/bin"
# ffmpeg-full é keg-only: precisa vir antes no PATH para ganhar do ffmpeg comum.
linha_no_zprofile "export PATH=\"$FFMPEG_BIN:\$PATH\""
linha_no_zprofile 'export PATH="$HOME/.local/bin:$PATH"'
export PATH="$FFMPEG_BIN:$HOME/.local/bin:$PATH"

passo "Ferramentas Python (yt-dlp, crv, mlx-whisper)"
# O Python do brew não aceita pip global, então cada ferramenta ganha seu ambiente pelo uv.
uv tool install --upgrade --python 3.13 yt-dlp
uv tool install --upgrade --python 3.13 "claude-real-video[mlx]"
uv tool install --upgrade --python 3.13 mlx-whisper
# Ambiente para scripts avulsos que o Claude escrever (imagem, números).
[ -x "$BASE/venv/bin/python" ] || uv venv --quiet --python 3.13 "$BASE/venv"
uv pip install --quiet --upgrade --python "$BASE/venv/bin/python" pillow numpy

passo "Claude Code"
command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash

passo "Skills do Claude"
mkdir -p "$SKILLS" "$BASE/src" "$HOME/Developer"

# video-use: edição conversada com transcrição pela ElevenLabs.
clonar_ou_atualizar https://github.com/browser-use/video-use "$HOME/Developer/video-use"
(cd "$HOME/Developer/video-use" && uv sync --quiet && { [ -f .env ] || cp .env.example .env; })
ligar_skill "$HOME/Developer/video-use" video-use

# Remotion: animação e legenda feitas em código.
clonar_ou_atualizar https://github.com/remotion-dev/skills "$BASE/src/remotion-skills" --depth 1
ligar_skill "$BASE/src/remotion-skills/skills/remotion-best-practices" remotion-best-practices
ligar_skill "$BASE/src/remotion-skills/skills/remotion-captions" remotion-captions

# crv: o Claude "assiste" um vídeo (quadros-chave + transcrição).
clonar_ou_atualizar https://github.com/HUANGCHIHHUNGLeo/claude-real-video "$BASE/src/claude-real-video" --depth 1
ligar_skill "$BASE/src/claude-real-video/skills/claude-real-video" claude-real-video

# get-brolls: busca e entrega de B-roll com revisão.
clonar_ou_atualizar https://github.com/engenheirodevideo/get-brolls "$SKILLS/get-brolls"
if [ -d "$SKILLS/get-brolls/.git" ]; then
  (cd "$SKILLS/get-brolls" && bash scripts/install.sh) || aviso "o instalador do get-brolls falhou; rode de novo mais tarde."
fi

# Regras de anúncio vertical deste toolkit (cópia, para não depender de onde o repo foi clonado).
mkdir -p "$SKILLS/edicao-anuncio"
cp -R "$DIR/skills/edicao-anuncio/." "$SKILLS/edicao-anuncio/"

passo "Plugin get-brolls"
PLUGIN_MANUAL=0
if claude plugin marketplace add engenheirodevideo/get-brolls </dev/null >/dev/null 2>&1 \
  && claude plugin install get-brolls@engenheirodevideo </dev/null >/dev/null 2>&1; then
  echo "Plugin instalado."
else
  PLUGIN_MANUAL=1
fi

passo "Conferindo"
bash "$DIR/doctor.sh" || true

if [ "$PLUGIN_MANUAL" = 1 ]; then
  cat <<'EOF'

FALTA UM PASSO: abra o Claude Code e digite, um de cada vez:
  /plugin marketplace add engenheirodevideo/get-brolls
  /plugin install get-brolls@engenheirodevideo
EOF
fi

if ! grep -qE '^ELEVENLABS_API_KEY=.+' "$HOME/Developer/video-use/.env" 2>/dev/null; then
  cat <<'EOF'

FALTA A CHAVE DA ELEVENLABS (usada para transcrever a fala).
  1. Crie a chave em https://elevenlabs.io/app/settings/api-keys
  2. No Terminal, rode:  open -e ~/Developer/video-use/.env
  3. Escreva uma linha assim, com a sua chave depois do sinal de igual, e salve:
     ELEVENLABS_API_KEY=sua_chave_aqui
EOF
fi

printf '\nPronto. Feche e abra o Terminal (ou o app do Claude) para valer o PATH novo.\n'
