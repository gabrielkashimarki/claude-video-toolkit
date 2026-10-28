# claude-video-toolkit

Um comando que prepara o Mac para o Claude Code editar vídeo de anúncio: cortar, legendar, ajustar o áudio, buscar B-roll e conferir antes de entregar.

Funciona em Mac com chip Apple (M1, M2, M3, M4). Não precisa ter nada de programação instalado.

## Instalar

1. Abra o app **Terminal** (aperte Cmd + Espaço, digite "Terminal" e dê Enter).
2. Cole a linha abaixo e aperte Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/gabrielkashimarki/claude-video-toolkit/main/install.sh | bash
```

Ou, se preferir baixar o repositório antes:

```bash
git clone https://github.com/gabrielkashimarki/claude-video-toolkit && cd claude-video-toolkit && bash install.sh
```

O que esperar:

- Na primeira vez ele pede a **senha do Mac** (a mesma de desbloquear a tela). Enquanto você digita, nada aparece. É normal.
- Se abrir uma janela pedindo para instalar as "ferramentas de linha de comando", aceite, espere terminar e cole o comando de novo.
- Leva de 10 a 30 minutos, conforme a internet.
- No fim aparece uma lista com OK ou FALTA em cada item, e o que ainda falta fazer à mão.

Depois, feche e abra o Terminal (e o app do Claude) para tudo valer.

## O que ele instala

| Item | Para quê |
|---|---|
| Homebrew | Instalador de programas do Mac, usado para todo o resto |
| ffmpeg-full | Cortar, juntar, legendar e ajustar áudio de vídeo (versão completa, com texto na tela e legenda) |
| sox | Tratar áudio |
| rclone | Copiar arquivos de e para Google Drive e outras nuvens |
| node, git, uv, Python 3.13 | Base para as ferramentas abaixo rodarem |
| yt-dlp | Baixar vídeo de referência (YouTube, Instagram) |
| crv (claude-real-video) | Deixa o Claude "assistir" um vídeo: tira quadros-chave e transcreve a fala |
| mlx-whisper | Transcrição de fala rodando no próprio Mac |
| earshot | Deixa o Claude "ouvir" o áudio: mostra se cada corte tem som junto e quanto a trilha desce sob a voz (baixa ~1,1 GB de modelos) |
| Claude Code | O Claude que trabalha nos arquivos do seu computador |
| Skill video-use | Edição conversada: você fala o que quer e ele corta e monta |
| Skills do Remotion | Animação, letreiro e legenda feitos em código |
| Skill get-brolls (e plugin) | Busca de B-roll com prévia para você aprovar e origem registrada |
| Skill claude-real-video | Ensina o Claude a usar o crv |
| Skill edicao-anuncio | Regras de anúncio vertical para Meta: 9:16, gancho, posição da legenda, áudio a -14 LUFS, cartão final |

Para scripts avulsos que o Claude escrever (mexer em imagem, contas), existe um Python pronto com pillow e numpy em `~/.video-toolkit/venv/bin/python`.

## Chave da ElevenLabs

A skill video-use transcreve a fala pela ElevenLabs e precisa de uma chave. O instalador não pede nem guarda chave nenhuma, você coloca:

1. Crie a chave em https://elevenlabs.io/app/settings/api-keys
2. No Terminal, rode `open -e ~/Developer/video-use/.env`
3. Deixe a linha assim, com a sua chave depois do sinal de igual, e salve:

```
ELEVENLABS_API_KEY=sua_chave_aqui
```

## Plugin get-brolls

O instalador tenta instalar sozinho. Se no fim ele disser que falta, abra o Claude Code e digite, um de cada vez:

```
/plugin marketplace add engenheirodevideo/get-brolls
/plugin install get-brolls@engenheirodevideo
```

## Como usar

1. Ponha os vídeos brutos numa pasta, por exemplo `~/Videos/anuncio-novembro`.
2. No app do Claude, abra o Claude Code escolhendo essa pasta. Ou, no Terminal:

```bash
cd ~/Videos/anuncio-novembro
claude
```

3. Peça em português, do jeito que você pediria a um editor. Exemplos:

- "Edite esses vídeos num anúncio de 30 segundos para Reels, com legenda palavra por palavra e cartão final escrito Chame no WhatsApp."
- "Faça também uma versão de 20 segundos só com gancho, dor e chamada."
- "Assista esse vídeo de referência e me diga o que funciona nele: https://..."
- "Ache 5 B-rolls de cozinha profissional para cobrir os cortes."

Antes de entregar, peça a folha de frames, a medição de áudio e a folha do earshot. A skill edicao-anuncio já manda o Claude fazer isso.

## Conferir e atualizar

- Para ver se está tudo instalado: `bash ~/.video-toolkit/src/claude-video-toolkit/doctor.sh` (ou `bash doctor.sh` dentro da pasta do repositório, se você clonou).
- Para atualizar tudo: rode o comando de instalação de novo. Ele não duplica nada, só atualiza.

## Licença

MIT. Veja [LICENSE](LICENSE).
