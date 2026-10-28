#!/usr/bin/env bash
# Confere se cada peça do toolkit está instalada. Imprime OK ou FALTA por linha.
# Sai com código 1 se faltar algo obrigatório.
set -uo pipefail

# Mesmo PATH que o instalador deixa no ~/.zprofile, para funcionar logo depois de instalar.
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -d /opt/homebrew/opt/ffmpeg-full/bin ] && PATH="/opt/homebrew/opt/ffmpeg-full/bin:$PATH"
PATH="$HOME/.local/bin:$PATH"

faltas=0
ok() { printf 'OK     %s\n' "$1"; }
falta() { printf 'FALTA  %s\n' "$1"; faltas=$((faltas + 1)); }
opcional() { printf 'AVISO  %s\n' "$1"; }
checa() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else falta "$1"; fi; }

checa brew 'command -v brew'
filtros="$(ffmpeg -hide_banner -filters 2>/dev/null)"
for f in drawtext subtitles loudnorm; do
  if grep -q " $f " <<<"$filtros"; then ok "ffmpeg com $f"; else falta "ffmpeg com $f (precisa do ffmpeg-full antes no PATH)"; fi
done
for c in ffprobe sox rclone node uv yt-dlp crv mlx_whisper earshot claude; do
  checa "$c" "command -v $c"
done
checa "modelos do earshot (~1,1 GB)" 'test -d "$HOME/.cache/earshot/hf/models--laion--larger_clap_general" && test -d "$HOME/.cache/earshot/hf/models--MIT--ast-finetuned-audioset-10-10-0.4593"'
checa "venv de scripts (pillow, numpy)" '"$HOME/.video-toolkit/venv/bin/python" -c "import PIL, numpy"'

for s in video-use remotion-best-practices remotion-captions get-brolls claude-real-video edicao-anuncio; do
  checa "skill $s" "test -f \"$HOME/.claude/skills/$s/SKILL.md\""
done

# Só confere se a chave existe; o valor nunca é impresso.
if grep -qE '^ELEVENLABS_API_KEY=.+' "$HOME/Developer/video-use/.env" 2>/dev/null; then
  ok "chave da ElevenLabs no .env do video-use"
else
  opcional "chave da ElevenLabs no .env do video-use (o video-use não transcreve sem ela)"
fi

gb="$HOME/.claude/skills/get-brolls"
if [ -f "$gb/scripts/gb.py" ]; then
  py=python3
  [ -x "$gb/.venv/bin/python" ] && py="$gb/.venv/bin/python"
  resumo="$(cd "$gb" && PATH="$gb/.venv/bin:$PATH" "$py" scripts/gb.py doctor 2>/dev/null | python3 -c '
import json, sys
s = json.load(sys.stdin).get("summary", {})
print("faltando: " + (", ".join(s.get("missing", [])) or "nada"))
print("opcional: " + (", ".join(i["item"] for i in s.get("optional", [])) or "nada"))
' 2>/dev/null)"
  if [ -z "$resumo" ]; then
    falta "doctor do get-brolls não rodou (rode: cd $gb && bash scripts/install.sh)"
  elif grep -q '^faltando: nada' <<<"$resumo"; then
    ok "doctor do get-brolls ($(tail -1 <<<"$resumo"))"
  else
    falta "doctor do get-brolls ($(head -1 <<<"$resumo"))"
  fi
fi

echo
if [ "$faltas" -gt 0 ]; then
  echo "$faltas item(ns) faltando. Rode o install.sh de novo."
  exit 1
fi
echo "Tudo certo."
