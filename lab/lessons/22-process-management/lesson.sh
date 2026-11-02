# Sessiya 22 — Proses idarəsi (ps, top, kill, nohup, &, jobs)
lab_init 22 "Proses idarəsi: ps, top, kill"

objective \
  "ps aux və top -bn1 ilə prosesləri və resurs istifadəsini oxumağı" \
  "prosesi arxa planda (&, nohup) başlatmağı və jobs ilə izləməyi" \
  "kill (SIGTERM) və kill -9 (SIGKILL) fərqini bilməyi" \
  "CPU yeyən 'başıboş' prosesi tapıb dayandırmağı"

concept "Proses, PID və siqnallar" \
  "Hər işləyən proqram prosesdir və unikal PID-i var. PPID onu başladan prosesdir (PID 1 hamının atasıdır)." \
  "kill əslində 'siqnal göndər' deməkdir: SIGTERM (15, default) nəzakətlə 'təmizlənib çıx' deyir, SIGKILL (-9) isə dərhal öldürür." \
  "Təhlükəsizlik qaydası: PID-i həmişə dəqiq götürün; adla toplu öldürmək (pkill) başqa servisləri də vura bilər. Bu dərsdə yalnız öz yaratdığımız sleep proseslərini öldürürük." \
  "top interaktivdir (q ilə çıxılır, k ilə öldürülür); skript və dərslərdə top -bn1 (batch, 1 dəfə) istifadə edilir."

prep 'command -v ps >/dev/null && command -v top >/dev/null || { sudo apt-get update -qq && sudo apt-get install -y -qq procps; }'
cleanup "for f in $LAB_WORK/*.pid; do [ -f \"\$f\" ] && kill -9 \$(cat \"\$f\") 2>/dev/null; done; true"

step "Cari terminalın prosesləri və bütün proseslər" \
  --why "Servis 'işləyir' deyirlər, amma həqiqətən? ps ilk baxılan yerdir." \
  --cmd 'ps; echo "---"; ps aux | head -n 5; echo "---"; echo "Cəmi proses: $(ps aux | wc -l)"' \
  --explain "ps|yalnız bu terminalın prosesləri" \
  --explain "ps aux|a=bütün istifadəçilər, u=istifadəçi formatı, x=terminalsız proseslər də" \
  --explain "%CPU, %MEM, STAT|CPU/RAM faizi və vəziyyət (S=yatır, R=işləyir, Z=zombie)" \
  --expect "PID, TTY, CMD sütunları; ps aux-da USER PID %CPU %MEM ... COMMAND" \
  --note "Konteynerdə PID 1 adətən sizin başlatdığınız əmrdir (systemd yox). Real VM-də PID 1 systemd olur." \
  --assert 'ps aux | head -n1 | grep -q COMMAND'

step "Arxa planda proses başlat: & və jobs" \
  --why "Uzun işləyən əmr (build, backup) terminalı bloklamasın deyə arxa plana atılır." \
  --cmd 'sleep 300 >/dev/null 2>&1 & echo $! > a.pid
sleep 301 >/dev/null 2>&1 & echo $! > b.pid
echo "a PID=$(cat a.pid)  b PID=$(cat b.pid)"; jobs' \
  --explain "&|əmri arxa planda başladır, terminal azad olur" \
  --explain '$!|son arxa plan prosesinin PID-i; dəyişənə yazırıq ki, sonra dəqiq öldürək' \
  --explain "jobs|bu shell-in arxa plan işlərini göstərir" \
  --expect "İki PID və jobs-da iki Running sleep sətri" \
  --note "PID-ləri fayla yazdıq (a.pid, b.pid). Beləliklə sonra adla yox, dəqiq PID ilə kill edəcəyik." \
  --assert 'kill -0 $(cat a.pid) && kill -0 $(cat b.pid)'

step "Prosesi PID ilə tap: ps -p, ps aux | grep" \
  --why "Nginx/Jenkins/Prometheus donub: əvvəl hansı PID olduğunu, kimin övladı olduğunu və vəziyyətini görmək lazımdır." \
  --cmd 'ps -o pid,ppid,stat,etime,cmd -p $(cat a.pid),$(cat b.pid); echo "---"; ps aux | grep "[s]leep 30"' \
  --explain "-o pid,ppid,stat,..|çıxış sütunlarını özümüz seçirik" \
  --explain "-p PID,PID|yalnız həmin PID-lər" \
  --explain '"[s]leep"|grep-in özünü nəticədən çıxarmaq hiyləsi (grep -v grep əvəzi)' \
  --expect "İki sleep sətri, STAT=S (yatır), PPID eyni (bu shell)" \
  --note "Sleep CPU yemir, ona görə STAT=S. Alternativ: pgrep -a sleep. Amma onu öldürmək üçün adla yox, PID ilə işləyirik." \
  --assert 'ps -p $(cat a.pid) -o comm= | grep -q sleep'

step "Resursa görə sırala: top -bn1" \
  --why "'Server niyə yavaşdır?' sualında CPU/RAM-ı kim yeyir? top onu real vaxtda göstərir." \
  --cmd 'top -bn1 | head -n 12' \
  --explain "top|real vaxt monitor (interaktivdir, q ilə çıxılır)" \
  --explain "-b|batch rejim: terminalı idarə etmir, skriptə/log-a yazmaq olar" \
  --explain "-n1|bir dəfə çap edib çıx" \
  --explain "load average, %Cpu(s) id, MiB Mem|yük, CPU boş faizi, RAM xülasəsi" \
  --expect "Başlıq (load, Tasks, %Cpu, Mem) və PID/USER/%CPU/%MEM cədvəli" \
  --note "Yüksək 'id' (idle) = CPU boşdur. 'wa' yüksəkdirsə disk gözlənilir. Siyahı %CPU-ya görə sıralanır." \
  --assert 'top -bn1 | head -n 5 | grep -q "load average"'

step "Siqnal göndər: kill (SIGTERM)" \
  --why "Prosesi nəzakətlə dayandırmaq: o, açıq faylları bağlayıb təmiz çıxa bilər. Həmişə əvvəl bunu sınayın." \
  --cmd 'kill $(cat a.pid); sleep 1; ps -p $(cat a.pid) -o pid,stat,cmd || echo "a prosesi artıq yoxdur"; echo "---"; ps -p $(cat b.pid) -o pid,cmd' \
  --explain "kill PID|default SIGTERM (15) göndərir" \
  --explain '$(cat a.pid)|PID-i fayldan götürürük, əlimizlə yazmırıq' \
  --explain "ps -p ... || echo|proses yoxdursa ps xəta qaytarır, biz mesaj veririk" \
  --expect "a yoxdur, b hələ sağdır" \
  --predict "b prosesinə toxunmasaq nə olacaq?" \
  --note "Yalnız a öldü, b işləyir. Dəqiq PID ilə kill-in üstünlüyü budur: yan təsir yoxdur." \
  --assert '! kill -0 $(cat a.pid) 2>/dev/null && kill -0 $(cat b.pid)'

step "İnadkar proses: kill -9 (SIGKILL)" \
  --why "Bəzən proses SIGTERM-i ignor edir (donub və ya trap qoyub). Son çarə SIGKILL-dir, proses heç nə edə bilmir." \
  --cmd 'sh -c "trap \"\" TERM; while :; do sleep 1; done" >/dev/null 2>&1 & echo $! > stubborn.pid
sleep 1; kill $(cat stubborn.pid); sleep 1
echo "SIGTERM-dən sonra:"; ps -p $(cat stubborn.pid) -o pid,stat,cmd | tail -n1
kill -9 $(cat stubborn.pid); sleep 1
echo "SIGKILL-dən sonra:"; ps -p $(cat stubborn.pid) -o pid,cmd || echo "(proses getdi)"' \
  --explain 'trap "" TERM|proses SIGTERM-i ignor edir (inadkar proses simulyasiyası)' \
  --explain "kill -9|SIGKILL: kernel prosesi dərhal öldürür, təmizlənmə yoxdur" \
  --expect "SIGTERM-dən sonra proses hələ sağdır; kill -9-dan sonra getdi" \
  --note "kill -9 son çarədir: açıq fayllar/lock-lar təmizlənməyə bilər (məs. DB-də zədələnmə riski). Əvvəl həmişə SIGTERM." \
  --assert '! kill -0 $(cat stubborn.pid) 2>/dev/null'

step "Terminal bağlansa da yaşasın: nohup" \
  --why "SSH sessiyası qopanda terminalın prosesləri öldürülür (SIGHUP). nohup bunu ignor etdirir; uzun işlər üçün lazımdır." \
  --cmd 'nohup sleep 303 > nohup.out 2>&1 & echo $! > n.pid
sleep 1; ps -o pid,stat,cmd -p $(cat n.pid); echo "--- nohup.out:"; cat nohup.out; echo "(boşdur = xəta yoxdur)"
kill $(cat n.pid); sleep 1; ps -p $(cat n.pid) >/dev/null || echo "n prosesi dayandırıldı"' \
  --explain "nohup|SIGHUP-ı ignor edir, çıxışı nohup.out-a yönləndirir" \
  --explain "> nohup.out 2>&1|stdout və stderr-i fayla yaz (nohup-un öz mesajı da ora düşür)" \
  --explain "&|arxa planda" \
  --expect "Proses sağdır; sonra öldürülür" \
  --note "Müasir praktikada uzun servislər üçün systemd (Sessiya 28) və ya tmux/screen daha yaxşıdır. nohup sürətli həll üçündür." \
  --assert '! kill -0 $(cat n.pid) 2>/dev/null' \
  --allow-fail

inject "CPU yeyən proses" \
  "Arxa planda bir 'başıboş build' prosesi CPU-nu 100% yeyir. top/ps ilə tapın və YALNIZ onu dayandırın (PID ilə)." \
  --cmd 'sh -c "while :; do :; done" >/dev/null 2>&1 & echo $! > hog.pid' \
  --symptom 'sleep 1; ps -eo pid,pcpu,stat,comm --sort=-pcpu | head -n 4' \
  --fix 'kill -9 $(cat hog.pid); sleep 1' \
  --check '[ -s hog.pid ] && ! ps -o stat= -p $(cat hog.pid) | grep -qv Z' \
  --hint "ps -eo pid,pcpu,comm --sort=-pcpu | head — ən çox %CPU olan PID-i tapın, kill PID."

task "Arxa plan prosesi" \
  "Arxa planda 'sleep 305' başladın və PID-ni mypid.txt faylına yazın (\$! istifadə edin)." \
  --check 'test -s mypid.txt && kill -0 $(cat mypid.txt) && ps -p $(cat mypid.txt) -o comm= | grep -q sleep' \
  --hint "sleep 305 & echo \$! > mypid.txt" \
  --solution 'sleep 305 >/dev/null 2>&1 & echo $! > mypid.txt; echo $! > t1.pid'

task "Prosesi dəqiq öldür" \
  "mypid.txt-dəki PID-i kill ilə dayandırın (adla pkill istifadə etməyin)." \
  --check 'test -s mypid.txt && ! ps -o stat= -p $(cat mypid.txt) | grep -qv Z' \
  --hint "kill \$(cat mypid.txt)" \
  --solution 'kill $(cat mypid.txt); sleep 1'

task "Ən çox RAM yeyən 3 proses" \
  "ps aux çıxışını %MEM-ə görə sıralayıb başlıq + ilk 3 prosesi top-mem.txt-ə yazın (cəmi 4 sətir)." \
  --check '[ "$(wc -l < top-mem.txt)" -eq 4 ] && head -n1 top-mem.txt | grep -q USER' \
  --hint "ps aux --sort=-%mem | head -n 4 > top-mem.txt" \
  --solution 'ps aux --sort=-%mem | head -n 4 > top-mem.txt'

lab_summary "Sessiya 23 — Paketlərin quraşdırılması (apt)" \
  "ps aux / ps -p — prosesi tap və vəziyyətini oxu" \
  "top -bn1 — CPU/RAM-ı kim yeyir" \
  "& / jobs / nohup — arxa plan və SSH qopmasına davamlılıq" \
  "kill (SIGTERM) əvvəl, kill -9 son çarə; həmişə dəqiq PID ilə"
