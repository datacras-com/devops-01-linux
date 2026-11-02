# Sessiya 21 — Sistem məlumatı (uname, lscpu, free, df, du, /proc, os-release)
lab_init 21 "Sistem məlumatı: serverin sağlamlıq yoxlaması"

objective \
  "serverin kernel, CPU, RAM və disk vəziyyətini bir neçə əmrlə oxumağı" \
  "free çıxışında 'available' ilə 'free' fərqini izah etməyi" \
  "du ilə diski dolduran qovluğu tapmağı" \
  "yuxarıdakıları birləşdirib sadə 'health check' hesabatı yazmağı"

concept "Niyə sistem məlumatı?" \
  "'Server yavaşdır' şikayətində ilk sual: RAM dolub? Disk 100%-dir? Neçə CPU var? Hansı kernel/OS?" \
  "/proc və /sys kernelin virtual fayllarıdır: free, lscpu, uptime kimi əmrlər məlumatı oradan oxuyub gözəl göstərir." \
  "Skript və monitoring (node_exporter kimi) birbaşa /proc/meminfo və /proc/cpuinfo oxuyur."

prep 'command -v free >/dev/null || { sudo apt-get update -qq && sudo apt-get install -y -qq procps; }'

step "Kernel və arxitektura (uname)" \
  --why "Alət və paket seçərkən kernel versiyası və arxitektura (x86_64 / aarch64) vacibdir. Docker imajı yanlış arxitekturada işləməz." \
  --cmd 'uname -a; uname -r; uname -m' \
  --explain "uname -a|bütün məlumat bir sətirdə (kernel adı, host, versiya, arxitektura)" \
  --explain "uname -r|yalnız kernel versiyası" \
  --explain "uname -m|maşın arxitekturası" \
  --expect "Linux ..., kernel versiyası, x86_64 və ya aarch64" \
  --note "Konteynerdə kernel host-un kernelidir (konteynerlər kernel paylaşır). Real VM-də öz kernelinizi görürsünüz." \
  --assert 'uname -s | grep -q Linux'

step "CPU: neçə nüvə, hansı model?" \
  --why "Instance tipini (t3.small, 2 vCPU) yoxlamaq və load average-i nüvə sayı ilə müqayisə etmək üçün." \
  --cmd 'nproc; lscpu | grep -E "^(Architecture|CPU\(s\)|Model name)"; grep -c "^processor" /proc/cpuinfo' \
  --explain "nproc|istifadə edilə bilən nüvə sayı" \
  --explain "lscpu|CPU haqqında oxunaqlı xülasə" \
  --explain "grep -E|bir neçə açarı eyni anda süzür (| = və ya)" \
  --explain "/proc/cpuinfo|kernelin CPU faylı; hər nüvə üçün 'processor' sətri var" \
  --expect "Arxitektura, CPU(s) sayı, model adı; sonda nüvə sayı (nproc ilə eyni)" \
  --note "nproc, lscpu CPU(s) və /proc/cpuinfo sayı eyni rəqəmi verməlidir. Fərq olarsa konteyner limiti (cgroup) ola bilər." \
  --assert '[ "$(nproc)" -ge 1 ] && lscpu | grep -q "CPU(s)"'

step "RAM: free və /proc/meminfo" \
  --why "'OOM killer prosesi öldürdü' xətasının əvvəlindəki ilk yoxlama: RAM doğrudan dolubdur, yoxsa cache-dir?" \
  --cmd 'free -m; echo "---"; free -h; echo "---"; grep -E "^(MemTotal|MemAvailable|SwapTotal)" /proc/meminfo' \
  --explain "free -m|megabayt ilə (sadə müqayisə üçün)" \
  --explain "free -h|human-readable (Gi, Mi) — gözlə oxumaq üçün" \
  --explain "available|yeni proqram üçün həqiqətən mövcud RAM (cache-in boşaldıla bilən hissəsi daxil)" \
  --explain "/proc/meminfo|eyni rəqəmlərin ham mənbəyi (kB ilə)" \
  --expect "Mem və Swap sətirləri; sonda MemTotal, MemAvailable, SwapTotal" \
  --predict "free sütunu az, available isə böyükdürsə, server RAM-dan əziyyət çəkirmi?" \
  --note "Xeyr. Linux boş RAM-ı disk cache üçün istifadə edir (buff/cache). Qərar üçün 'available'-a baxın, 'free'-yə yox." \
  --assert 'free -m | grep -q "^Mem:" && grep -q "^MemTotal" /proc/meminfo'

step "Disk sahəsi: df" \
  --why "Disk 100% dolanda log yazılmır, DB çökür, deploy uğursuz olur. Bu, ən çox rast gəlinən production problemidir." \
  --cmd 'df -h /; echo "---"; df -h --output=source,size,used,pcent,target | head -n 6' \
  --explain "df|fayl sistemlərinin ümumi/istifadə olunan sahəsi" \
  --explain "-h|human-readable ölçü" \
  --explain "--output=...|yalnız seçilmiş sütunlar" \
  --explain "pcent|doluluq faizi — alert adətən 80-85%-də qurulur" \
  --expect "Kök (/) fayl sistemi və Use% sütunu" \
  --note "df fayl sisteminin ÜMUMİ vəziyyətini göstərir. 'Hansı qovluq tutub?' sualına növbəti addımdakı du cavab verir." \
  --assert 'df -h / | tail -n1 | grep -q "%"'

step "Disk kim tutur? du ilə axtarış" \
  --why "df 'disk doludur' deyir, du isə günahkar qovluğu göstərir (məs. /var/log böyüyüb)." \
  --cmd 'mkdir -p app/logs app/data app/cache; dd if=/dev/zero of=app/logs/app.log bs=1M count=6 status=none; dd if=/dev/zero of=app/data/db.bin bs=1M count=3 status=none; dd if=/dev/zero of=app/cache/c.tmp bs=1M count=1 status=none; du -sh app; du -h --max-depth=1 app | sort -rh' \
  --explain "dd ... count=6|6 MB-lıq saxta fayl yaradır (sandbox üçün)" \
  --explain "du -sh|qovluğun cəmi ölçüsü (-s summary, -h human)" \
  --explain "--max-depth=1|yalnız birinci səviyyə alt qovluqlar" \
  --explain "sort -rh|böyükdən kiçiyə (r=reverse, h=human ölçü)" \
  --expect "app cəmi ~10M; logs ən üstdə (6M), sonra data, cache" \
  --note "Real serverdə: du -h --max-depth=1 /var | sort -rh | head — və addım-addım içəri enin. Bu, 'disk dolub' incident-inin standart yoludur." \
  --assert 'du -h --max-depth=1 app | sort -rh | sed -n 2p | grep -q logs'

step "OS versiyası və host adı" \
  --why "Paket repoları, təhlükəsizlik yamaqları və dəstək müddəti OS buraxılışından asılıdır (Ubuntu 22.04 vs 24.04)." \
  --cmd 'head -n 4 /etc/os-release; echo "---"; (lsb_release -a 2>/dev/null || echo "lsb_release yoxdur (minimal imaj) — /etc/os-release kifayətdir"); echo "---"; (hostnamectl 2>/dev/null | head -n 6 || true) ; hostname' \
  --explain "/etc/os-release|hər müasir distroda var, skriptdə source edilə bilər" \
  --explain "lsb_release -a|distro məlumatı (hər imajda quraşdırılmır)" \
  --explain "hostnamectl|host adı, OS, kernel (systemd lazımdır)" \
  --expect "Ubuntu 24.04 məlumatı; konteynerdə hostnamectl işləməyə bilər" \
  --note "Skriptdə distronu aşkarlamaq üçün: . /etc/os-release; echo \$ID. Konteynerdə systemd olmadığı üçün hostnamectl xəta verə bilər, bu normaldır." \
  --assert 'grep -q "^NAME=" /etc/os-release' \
  --allow-fail

step "Proqram haradadır? which, whereis, history" \
  --why "Eyni proqramın iki versiyası olanda hansının işlədiyini bilmək lazımdır. history isə 'dünən nə yazmışdım?' sualına cavabdır." \
  --cmd 'which bash; whereis bash; printf "ls\ncd /var/log\nchmod 600 key.pem\n" > h.txt; HISTFILE=$PWD/h.txt; history -r; history | grep chmod' \
  --explain "which|PATH-da ilk tapılan (əslində işləyən) icra faylı" \
  --explain "whereis|binary, man səhifəsi və mənbə yerləri" \
  --explain "history|əvvəlki əmrlər (~/.bash_history); grep ilə axtarılır" \
  --expect "bash-in yolu (/usr/bin/bash) və history-də chmod sətri" \
  --note "history üçün burada saxta fayl istifadə etdik ki, nəticə deterministik olsun. Real shell-də: history | grep ssh. Həssas parolu əmr sətrində yazmayın, history-də qalır." \
  --assert 'which bash >/dev/null && grep -q chmod h.txt'

step "Mini 'health check' hesabatı" \
  --why "Öyrəndiklərinizi birləşdirin: bir skript serverin vəziyyətini bir ekranda göstərsin. Monitoringin ən sadə forması." \
  --cmd 'cat > health.sh <<"EOS"
echo "kernel : $(uname -r)"
echo "cpu    : $(nproc) core"
echo "ram    : $(free -m | awk "/^Mem:/{print \$7}") MB available"
echo "disk / : $(df -h / | awk "NR==2{print \$5}") used"
EOS
bash health.sh' \
  --explain "<<\"EOS\"|here-document: sətirləri fayla yazır" \
  --explain "awk '/^Mem:/{print \$7}'|Mem sətrinin 7-ci sütunu (available)" \
  --explain "df -h / | awk 'NR==2'|ikinci sətir (başlıqdan sonrakı)" \
  --expect "4 sətir: kernel, cpu, ram, disk" \
  --note "Bu skripti cron ilə işlədib nəticəni log-a yaza bilərsiniz. Sonrakı dərslərdə (cron, systemd) bunu avtomatlaşdıracağıq." \
  --assert '[ "$(bash health.sh | wc -l)" -eq 4 ] && bash health.sh | grep -q "^ram"'

task "RAM hesabatı" \
  "/proc/meminfo-dan MemAvailable dəyərini (yalnız rəqəm, kB) mem.txt faylına yazın." \
  --check 'test -s mem.txt && grep -Eq "^[0-9]+$" mem.txt && [ "$(cat mem.txt)" -gt 0 ]' \
  --hint "awk '/MemAvailable/{print \$2}' /proc/meminfo > mem.txt" \
  --solution "awk '/MemAvailable/{print \$2}' /proc/meminfo > mem.txt"

task "Ən böyük qovluq" \
  "app qovluğunun ən böyük alt qovluğunun adını (yalnız ad, məs. logs) biggest.txt-yə yazın." \
  --check 'test -s biggest.txt && [ "$(tr -d "[:space:]" < biggest.txt)" = "logs" ]' \
  --hint "du -s app/* | sort -rn | head -n1 → sonra yalnız adı çıxarın (basename və ya awk)." \
  --solution 'du -s app/* | sort -rn | head -n1 | awk "{print \$2}" | xargs basename > biggest.txt'

task "Öz sağlamlıq hesabatınız" \
  "report.txt faylı yaradın: 3 sətir olsun, hər biri 'kernel', 'disk' və 'host' sözü ilə başlasın (nümunə: host: ad)." \
  --check '[ "$(wc -l < report.txt)" -ge 3 ] && grep -q "^kernel" report.txt && grep -q "^disk" report.txt && grep -q "^host" report.txt' \
  --hint "echo \"kernel: \$(uname -r)\" > report.txt ; sonra >> ilə əlavə edin." \
  --solution 'echo "kernel: $(uname -r)" > report.txt; echo "disk: $(df -h / | awk "NR==2{print \$5}")" >> report.txt; echo "host: $(hostname)" >> report.txt'

lab_summary "Sessiya 22 — Proses idarəsi (ps, top, kill)" \
  "uname/lscpu/nproc — kernel və CPU" \
  "free -h və 'available' — RAM-ın həqiqi vəziyyəti" \
  "df (ümumi) → du (günahkar qovluq) — disk incident axını" \
  "/etc/os-release və /proc — skript üçün stabil mənbələr"
