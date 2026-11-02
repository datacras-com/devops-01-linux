#!/usr/bin/env bash
# DataCras DevOps Linux Lab — izahlı praktika mühərriki
# Hər dərs lessons/NN-ad/lesson.sh faylıdır və bu kitabxananı istifadə edir.
# Rejimlər: step (Enter ilə) | auto (özü gedir) | explain (icra etmir) | dry | verify (yalnız yoxlama)

LAB_MODE=${LAB_MODE:-step}
LAB_DELAY=${LAB_DELAY:-1}
LAB_HOME=${LAB_HOME:-$HOME/devops-lab}
[ -t 0 ] || [ "$LAB_MODE" != step ] || LAB_MODE=auto      # terminal yoxdursa (CI) avtomatik rejim

if [ -t 1 ]; then
  B=$'\e[1m'; D=$'\e[2m'; R=$'\e[0m'; G=$'\e[32m'; Y=$'\e[33m'; RD=$'\e[31m'; C=$'\e[36m'; M=$'\e[35m'
else B=; D=; R=; G=; Y=; RD=; C=; M=; fi

LAB_PASS=0; LAB_FAIL=0; LAB_N=0; LAB_TOTAL=0; LAB_TASK=0; LAB_TASKS=0

# root olmayan istifadəçi üçün sudo lazımdırsa; konteynerdə (root) sudo yoxdur → shim
if [ "$(id -u)" = 0 ] && ! command -v sudo >/dev/null 2>&1; then sudo() { "$@"; }; fi

_hr()  { printf '%s\n' "${D}────────────────────────────────────────────────────────────${R}"; }
_wait() {  # $1 = mesaj ; qaytarır: 0 davam, 1 keç
  [ "$LAB_MODE" = step ] || { [ "$LAB_MODE" = auto ] && sleep "$LAB_DELAY"; return 0; }
  local a; while true; do
    read -r -p "${Y}▶ ${1:-Davam} [Enter=icra, s=keç, q=çıx] ${R}" a </dev/tty || a=q
    case "$a" in ""|y) return 0;; s) return 1;; q) echo "Dərs dayandırıldı."; exit 130;; esac
  done
}

lab_init() {   # lab_init NN "Başlıq"
  LAB_NUM=$1; LAB_TITLE=$2
  LAB_WORK="$LAB_HOME/s$1"
  if [ "$LAB_MODE" != verify ]; then rm -rf "$LAB_WORK"; fi
  mkdir -p "$LAB_WORK"; cd "$LAB_WORK" || exit 1
  LAB_LOG="$LAB_HOME/lab-log-s$1.md"
  [ "$LAB_MODE" = verify ] || printf '# Sessiya %s — %s\n\n' "$1" "$2" > "$LAB_LOG"
  LAB_TOTAL=$(grep -c '^step ' "${LAB_LESSON_FILE:-/dev/null}" 2>/dev/null || echo 0)
  LAB_TASKS=$(grep -cE '^(task|inject) ' "${LAB_LESSON_FILE:-/dev/null}" 2>/dev/null || echo 0)
  echo; printf '%s\n' "${B}${G}╔══════════════════════════════════════════════════════════╗${R}"
  printf '%s\n' "${B}${G}║${R} ${B}Sessiya $1 — $2${R}"
  printf '%s\n' "${B}${G}╚══════════════════════════════════════════════════════════╝${R}"
  echo "${D}İş qovluğu: $LAB_WORK  (təhlükəsizdir, hər başlanğıcda sıfırlanır)${R}"
  echo "${D}Rejim: $LAB_MODE · ${LAB_TOTAL} addım · ${LAB_TASKS} tapşırıq${R}"
}

objective() { [ "$LAB_MODE" = verify ] && return 0; echo; echo "${B}🎯 Bu dərsin sonunda siz bacaracaqsınız:${R}"; local o; for o in "$@"; do echo "   • $o"; done; }

concept() {   # concept "Başlıq" "mətn" ...  (qısa nəzəri qeyd)
  [ "$LAB_MODE" = verify ] && return 0
  echo; _hr; echo "${B}${M}🧠 $1${R}"; shift; local l; for l in "$@"; do echo "   $l"; done
  _wait "Davam" || true
}

# cleanup 'əmr' — dərs bitəndə (və ya Ctrl+C-də) icra olunur; sistemi dəyişən dərslər üçün məcburidir
LAB_CLEAN=()
cleanup() { LAB_CLEAN+=("$1"); }
_run_cleanup() {
  case $LAB_MODE in verify|explain|dry) return 0;; esac
  local i; for ((i=${#LAB_CLEAN[@]}-1; i>=0; i--)); do eval "${LAB_CLEAN[$i]}" >/dev/null 2>&1 </dev/null; done
  LAB_CLEAN=()
}
trap _run_cleanup EXIT

# cleanup_pkgs paket... — YALNIZ hazırda quraşdırılmamış paketləri dərs bitəndə silir (tələbənin öz paketlərinə toxunmur)
cleanup_pkgs() {
  local p todo=(); for p in "$@"; do dpkg -s "$p" >/dev/null 2>&1 || todo+=("$p"); done
  [ ${#todo[@]} -gt 0 ] && cleanup "apt-get purge -y ${todo[*]}; apt-get autoremove -y"
  return 0
}

prep() { [ "$LAB_MODE" = verify ] && return 0; eval "$1" >/dev/null 2>&1; }   # səssiz hazırlıq

step() {   # step "Başlıq" --why .. --cmd .. [--explain "tok|məna"]... [--expect ..] [--predict ..] [--note ..] [--assert ..] [--show ..]
  [ "$LAB_MODE" = verify ] && return 0
  local title=$1; shift
  local why= cmd= expect= predict= note= assert= show= root=0 allow=0; local -a ex=()
  while [ $# -gt 0 ]; do case $1 in
    --why) why=$2; shift 2;; --cmd) cmd=$2; shift 2;; --explain) ex+=("$2"); shift 2;;
    --expect) expect=$2; shift 2;; --predict) predict=$2; shift 2;; --note) note=$2; shift 2;;
    --assert) assert=$2; shift 2;; --show) show=$2; shift 2;; --root) root=1; shift;; --allow-fail) allow=1; shift;;
    *) echo "step: naməlum arqument $1"; return 1;; esac; done
  LAB_N=$((LAB_N+1)); echo; _hr
  echo "${B}${C}ADDIM $LAB_N/$LAB_TOTAL — $title${R}"
  [ -n "$why" ] && echo "💡 ${B}Niyə:${R} $why"
  echo "⌨️  ${B}Əmr:${R}  ${G}${show:-$cmd}${R}"
  local e; for e in "${ex[@]:-}"; do [ -n "$e" ] || continue; printf '   %s├─%s %s%s%s → %s\n' "$D" "$R" "$B" "${e%%|*}" "$R" "${e#*|}"; done
  [ -n "$expect" ] && echo "🔮 ${B}Gözlənti:${R} $expect"
  if [ "$LAB_MODE" = step ] && [ -n "$predict" ]; then
    echo "🤔 ${B}Proqnoz:${R} $predict"; read -r -p "   Cavabınız (qısa yazın, Enter): " _ </dev/tty || true
  fi
  if [ "$LAB_MODE" = explain ]; then [ -n "$note" ] && echo "📖 ${B}Şərh:${R} $note"; return 0; fi
  if [ "$LAB_MODE" = dry ]; then echo "${D}(dry-run: icra edilmir)${R}"; return 0; fi
  _wait "İcra et" || { echo "${D}(keçildi)${R}"; return 0; }
  local out; out=$(mktemp); local rc
  if [ "$root" = 1 ] && [ "$(id -u)" != 0 ]; then sudo -v || true; fi
  eval "$cmd" >"$out" 2>&1 </dev/null; rc=$?
  printf '%s\n' "$D┌─ çıxış ─────────────────────────────────────────────────$R"
  local n; n=$(wc -l <"$out"); head -n 40 "$out" | sed "s/^/${D}│${R} /"
  [ "$n" -gt 40 ] && echo "${D}│ … (daha $((n-40)) sətir gizlədildi)${R}"
  [ -s "$out" ] || echo "${D}│ (çıxış yoxdur — əmr səssiz uğurlu oldu)${R}"
  printf '%s\n' "$D└─────────────────────────────────────────────────────────$R"
  { printf '## %s\n\n```bash\n%s\n```\n\n```\n' "$title" "$cmd"; head -n 40 "$out"; printf '```\n\n'; } >>"$LAB_LOG"
  rm -f "$out"
  if [ "$rc" -ne 0 ] && [ "$allow" = 0 ]; then echo "${Y}⚠ Əmr $rc kodu ilə bitdi (gözlənilən deyilsə, xəta mesajını oxuyun).${R}"; fi
  [ -n "$note" ] && echo "📖 ${B}Şərh:${R} $note"
  if [ -n "$assert" ]; then
    if (eval "$assert") >/dev/null 2>&1; then echo "${G}✅ Yoxlama keçdi${R}"; LAB_PASS=$((LAB_PASS+1))
    else echo "${RD}❌ Yoxlama uğursuz: $assert${R}"; LAB_FAIL=$((LAB_FAIL+1)); fi
  fi
  return 0
}

task() {   # task "Başlıq" "Təlimat" --check 'expr' [--hint ..] [--solution 'cmd']
  local title=$1 text=$2; shift 2
  local check= hint= sol=
  while [ $# -gt 0 ]; do case $1 in --check) check=$2; shift 2;; --hint) hint=$2; shift 2;; --solution) sol=$2; shift 2;; *) shift;; esac; done
  LAB_TASK=$((LAB_TASK+1))
  cd "$LAB_WORK" 2>/dev/null || true      # hər tapşırıq sandbox kökündən başlayır
  if [ "$LAB_MODE" = verify ]; then
    if (cd "$LAB_WORK" && eval "$check") >/dev/null 2>&1; then echo "${G}✅ Tapşırıq $LAB_TASK — $title${R}"; LAB_PASS=$((LAB_PASS+1))
    else echo "${RD}❌ Tapşırıq $LAB_TASK — $title${R}${hint:+  ${D}ipucu: $hint${R}}"; LAB_FAIL=$((LAB_FAIL+1)); fi; return 0; fi
  echo; _hr; echo "${B}${Y}✍️  TAPŞIRIQ $LAB_TASK/$LAB_TASKS — $title${R}"; echo "   $text"
  if [ "$LAB_MODE" = explain ] || [ "$LAB_MODE" = dry ]; then return 0; fi
  if [ "$LAB_MODE" = auto ]; then
    [ -n "$sol" ] && { echo "${D}(auto: nümunə həll icra olunur)${R}"; echo "   ${G}\$ $sol${R}"; eval "$sol" >/dev/null 2>&1 </dev/null; }
  else
    echo "${D}İş qovluğu: $LAB_WORK — əmri burada yazın, ya da ayrı terminalda həmin qovluqda edin.${R}"
    local tries=0 line
    while true; do
      read -e -r -p "${Y}\$ ${R}" line </dev/tty || line=
      [ -n "$line" ] && { eval "$line" </dev/null; }
      if (eval "$check") >/dev/null 2>&1; then break; fi
      tries=$((tries+1))
      echo "${RD}Hələ tam deyil.${R}"
      [ $tries -ge 2 ] && [ -n "$hint" ] && echo "💡 Ipucu: $hint"
      if [ $tries -ge 3 ]; then read -r -p "   [Enter=yenə cəhd, h=həll göstər, s=keç] " a </dev/tty
        case $a in h) echo "   Həll: ${G}$sol${R}"; eval "$sol" >/dev/null 2>&1 </dev/null;; s) break;; esac; fi
    done
  fi
  if (eval "$check") >/dev/null 2>&1; then echo "${G}✅ Tapşırıq $LAB_TASK tamamlandı${R}"; LAB_PASS=$((LAB_PASS+1))
  else echo "${RD}❌ Tapşırıq $LAB_TASK tamamlanmadı${R}"; LAB_FAIL=$((LAB_FAIL+1)); fi
}

inject() {   # inject "Başlıq" "nə pozulur" --cmd 'pozucu əmr' --symptom 'əmr' --fix 'əmr' --check 'expr' --hint ..
  local title=$1 what=$2; shift 2
  local cmd= symptom= fix= check= hint=
  while [ $# -gt 0 ]; do case $1 in --cmd) cmd=$2; shift 2;; --symptom) symptom=$2; shift 2;; --fix) fix=$2; shift 2;; --check) check=$2; shift 2;; --hint) hint=$2; shift 2;; *) shift;; esac; done
  [ "$LAB_MODE" = verify ] && { task "$title" "$what" --check "$check" --hint "$hint"; return 0; }
  echo; _hr; echo "${B}${RD}💥 FAILURE INJECTION — $title${R}"; echo "   $what"
  if [ "$LAB_MODE" = explain ] || [ "$LAB_MODE" = dry ]; then return 0; fi
  _wait "Sistemi poz" || return 0
  eval "$cmd" >/dev/null 2>&1 </dev/null
  echo "${D}(sistem pozuldu)${R}"; [ -n "$symptom" ] && { echo "   Simptomu görün: ${G}$symptom${R}"; ( eval "$symptom" ) 2>&1 | head -n 15 | sed "s/^/${D}│${R} /"; }
  task "$title — bərpa et" "Problemi tapın və düzəldin." --check "$check" --hint "$hint" --solution "$fix"
}

lab_summary() {   # lab_summary "növbəti sessiya" "xülasə sətir"...
  local next=$1; shift
  echo; _hr; echo "${B}${G}📋 XÜLASƏ — Sessiya $LAB_NUM${R}"; local l; for l in "$@"; do echo "   • $l"; done
  _run_cleanup
  [ "$LAB_MODE" = verify ] || echo "${D}Dərs logu (portfolio üçün): $LAB_LOG${R}"
  local tot=$((LAB_PASS+LAB_FAIL))
  [ "$tot" -gt 0 ] && echo "${B}Nəticə: $LAB_PASS/$tot yoxlama keçdi${R}"
  [ -n "$next" ] && echo "➡️  Növbəti: $next"
  echo "${D}Ev tapşırığı: lab-log faylını oxuyun və hər əmri öz sözlərinizlə izah edin.${R}"
  [ "$LAB_FAIL" -eq 0 ]
}
