# Dərs yazmaq üçün qaydalar (lesson.sh)

Hər dərs `lab/lessons/NN-ad/lesson.sh` faylıdır. `lab/lessons/03-basic-commands/lesson.sh` istinad nümunəsidir.
Mühərrik: `lab/lib/lab.sh` (dəyişmə, yalnız oxu). Test: `lab/test.sh NN` (Ubuntu 24.04 konteynerində `--auto`).

## Struktur (hər dərsdə bu sıra)
1. `lab_init NN "Başlıq"` (ilk sətir, başlıq tək-dırnaqlı deyil, qoşa dırnaqlı)
2. `objective "..." "..."` — 3–4 ölçülə bilən məqsəd ("... bacaracaqsınız")
3. `concept "Başlıq" "sətir" "sətir"` — 1 (max 2) qısa nəzəri qeyd, DevOps kontekstində
4. 5–8 × `step` — hər biri tam: `--why` (DevOps niyə), `--cmd`, `--explain "token|məna"` (hər flag/hissə üçün), `--expect`, `--note` (çıxışı şərh), `--assert` (CI yoxlaması), çətin yerdə `--predict`
5. 2–3 × `task` — tələbə özü edir. Mütləq `--check`, `--hint`, `--solution`. Tapşırıqlar bir-birinə qalmayan, sandbox-da (iş qovluğunda) icra olunan olmalıdır
6. (uyğun olanda) 1 × `inject` — failure injection: sistemi poz, simptomu göstər, tələbə bərpa etsin
7. `lab_summary "Növbəti sessiya" "xülasə" ...`

## Qaydalar
- Dil: Azərbaycan. Əmrlər və fayl adları ingilis. Real DevOps nümunələri (nginx, deploy, log, backup). Data Engineering/Airflow/Kafka/ETL YOX.
- **Təhlükəsizlik:** yalnız `$LAB_WORK` (cari qovluq) daxilində işlə. `rm -rf` yalnız sandbox daxilində və qısa yolla. Sistem səviyyəli dəyişiklik (useradd, apt, systemctl) lazımdırsa: `--root` flag-ı + `sudo` istifadə et + mütləq `cleanup 'geri qaytaran əmr'` yaz (lab_init-dən sonra, dəyişiklikdən əvvəl). Başqa istifadəçi adı: `lab_` prefiksi (məs. `lab_ali`).
- `step` içində interaktiv əmr YOX (nano, vi, less, top, `tail -f` timeout-suz, parol soruşan). Əvəzinə qeyri-interaktiv: `sed -i`, `printf >`, `timeout 2 tail -f`, `top -bn1`, `cat`. İnteraktiv alətin mahiyyəti `concept`-də izah olunsun.
- `cd` addımlarında `cd` cari shell-də qalır (eval); mühərrik sandbox-dan başlayır.
- Çıxış **deterministik** olmalıdır ki `--assert` işləsin (tarix, PID kimi dəyişənlərə assert yazma, yalnız struktur yoxla).
- Konteynerdə (root, minimal Ubuntu) çalışmalıdır; real VM-də də (adi istifadəçi + sudo). Minimal imajda olmayan əmr (man, tree, ping, curl, ss...) üçün: ya `command -v X || sudo apt-get install -y X >/dev/null` əvvəlcə `prep` ilə, ya alternativ.
- Hər `task`-ın `--solution`-ı `--check`-i keçməlidir (auto rejim bunu sınayır).
- Mənbə məzmun: uyğun `session-NN-*.html` slaydı (mətn mövzuları, əmrlər). Slaydda olmayan əmr əlavə etmə; slaydın sırasını izlə.
- Kod şərhi və izah: tələbə-dostu, qısa, "niyə"yə fokus. Hər step ≤ 4 sətir izah.

## Agentlərin təcrübəsindən əlavə qaydalar
- Paket quraşdıran dərs: `cleanup_pkgs paket1 paket2` (yalnız dərsdən əvvəl olmayan paketləri silir; tələbənin öz paketlərinə toxunmur). Əl ilə `apt-get purge` cleanup-u YAZMA.
- `--cmd` tək dırnaqlıdır: heredoc üçün `<<"EOF"` işlət. `--explain "token|məna"` içində `|` simvolu işlətmə.
- Root konteynerdə icazə yoxlamaları keçir: `Permission denied` göstərmək üçün `sudo -u lab_x` / `runuser -u` işlət. Ubuntu 24.04-də ev qovluğu 750-dir: başqa hesabın oxuyacağı fayllar `/tmp/lab_*` altında olsun.
- `apt-get install -s` simulyasiyası `Conf` sətirləri ilə bitir: xülasə üçün `grep newly` istifadə et.
- `--verify` yalnız sandbox-əsaslı yoxlamalar üçün mənalıdır (cleanup hesabları/paketləri silir).
- Minimal imajda olmayan alətlər (ps, ip, ss, curl, file, tree, adduser...) `prep` ilə qurulur; bu internet tələb edir.
