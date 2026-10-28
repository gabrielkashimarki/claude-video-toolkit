---
name: edicao-anuncio
description: Regras para editar anúncio em vídeo vertical para Meta (Reels, Stories, Feed 9:16). Use ao editar, cortar, legendar, mixar ou revisar um vídeo de anúncio, ou quando pedirem "versão curta", "gancho", "legenda", "CTA" ou "deixar pronto para subir no Meta".
---

# Edição de anúncio vertical (Meta)

## Regras

- Formato 9:16, 1080x1920, 30 fps, H.264 + AAC.
- Gancho nos 2 primeiros segundos: rosto próximo e uma frase escrita grande no topo da tela.
- Texto e legenda ficam entre 55% e 65% da altura (y de 1056 a 1248 px). A faixa de baixo, cerca de 35% da tela, é coberta pela interface do Reels; nada importante ali.
- Legenda uma palavra por vez, centralizada, fonte grossa, contorno ou sombra para ler em qualquer fundo.
- Áudio a -14 LUFS integrado, pico -1 dBTP, com loudnorm em duas passadas.
- Trilha desce de 3 a 6 dB enquanto alguém fala (ducking). Menos que isso, a voz embola no celular e a transcrição erra palavra.
- Algum estímulo visual novo a cada 2,5 s no máximo (corte, zoom, B-roll, texto, mudança de enquadramento).
- Cartão final de 2 a 3 s com a ação escrita (ex.: "Chame no WhatsApp").
- Sempre entregar também uma versão curta de 15 a 25 s: gancho, dor, CTA.
- Antes de entregar: folha de frames, medição de loudness e folha do earshot. Não entregue sem olhar as três.

## Legenda no lugar certo (ASS)

Gere a legenda em `.ass` com a resolução do vídeo, assim a posição em pixels vale de verdade.
`MarginV=770` com alinhamento 2 (embaixo, centro) põe a linha base em 1150 px, cerca de 60% da altura.

```
[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, OutlineColour, BackColour, Bold, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV
Style: Palavra,Arial Black,110,&H00FFFFFF,&H00000000,&H80000000,1,1,6,2,2,60,60,770

[Events]
Format: Layer, Start, End, Style, Text
Dialogue: 0,0:00:00.00,0:00:00.40,Palavra,Olha
```

Queimar no vídeo: `ffmpeg -i entrada.mp4 -vf "ass=legenda.ass" -c:a copy saida.mp4`

## Loudnorm em duas passadas

```bash
IN=entrada.mp4; OUT=saida.mp4
# 1ª passada: mede
M=$(ffmpeg -hide_banner -i "$IN" -af loudnorm=I=-14:TP=-1:LRA=11:print_format=json -f null - 2>&1 | sed -n '/^{/,/^}/p')
v() { python3 -c "import json,sys; print(json.loads(sys.argv[1])['$1'])" "$M"; }
# 2ª passada: aplica com os valores medidos
ffmpeg -hide_banner -y -i "$IN" -c:v copy -c:a aac -b:a 192k -ar 48000 \
  -af "loudnorm=I=-14:TP=-1:LRA=11:measured_I=$(v input_i):measured_TP=$(v input_tp):measured_LRA=$(v input_lra):measured_thresh=$(v input_thresh):offset=$(v target_offset):linear=true" \
  "$OUT"
# Conferir: "I:" perto de -14 LUFS e "Peak:" abaixo de -1 dBFS
ffmpeg -hide_banner -nostats -i "$OUT" -af ebur128=peak=true:framelog=quiet -f null - 2>&1 | grep -E "^ +(I|Peak):"
```

## Folha de frames

Um quadro por segundo, com o tempo escrito, numa imagem só (5 colunas x 6 linhas = 30 s; aumente `tile` se o vídeo for maior):

```bash
ffmpeg -hide_banner -y -i saida.mp4 -frames:v 1 \
  -vf "fps=1,scale=216:-2,drawtext=text='%{pts\:hms}':x=6:y=6:fontsize=22:fontcolor=white:box=1:boxcolor=black@0.6,tile=5x6:padding=4" \
  folha.png
```

Abra `folha.png` e confira: gancho com rosto e texto no topo, legenda na faixa de 55% a 65%, nada importante na faixa de baixo, troca visual a cada 2,5 s, cartão final legível.

## Ouvir o áudio (earshot)

```bash
earshot timeline saida.mp4 > timeline.txt   # cortes, efeitos, voz e queda da trilha, em texto
earshot sheet saida.mp4 -o earshot.png      # a mesma coisa numa imagem anotada
```

Confira no `timeline.txt`:
- Quanto a trilha desce sob a voz. Se ficar abaixo de 3 dB, baixe mais a trilha nos trechos com fala.
- Cortes sem som junto. Num anúncio é normal ter efeito só no gancho, na virada e no CTA; não encha todo corte de efeito.

O `earshot critique` compara com filmes de lançamento de produto, não com anúncio de Reels. Não vale o tempo.
