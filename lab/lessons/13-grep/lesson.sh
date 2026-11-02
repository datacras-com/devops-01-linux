# Sessiya 13 — Faylda söz axtarmaq (grep)
lab_init 13 "grep: log və konfiqdə sətir tapmaq"

objective \
  "grep ilə log-da ERROR və konfiqdə parametr sətrini tapmağı" \
  "-i, -n, -c, -v, -r flag-larının nə etdiyini bilməyi" \
  "^ və $ ilə sətrin başı/sonuna görə axtarmağı (qovluqlar, günün logu, boş sətirlər)" \
  "pipe (|) ilə əmr çıxışını süzməyi" \
  "pozulmuş konfiqdən problemli sətri grep -v ilə təmizləməyi"

concept "grep — böyük faylda iynə axtarmaq" \
  "grep pattern fayl — pattern olan sətirləri göstərir; tapmasa çıxış boşdur (exit 1). Default olaraq hərf həssasdır." \
  "Incident-də ilk iş: grep ERROR app.log. Flag-lar: -i hərfə həssas deyil, -n sətir nömrəsi, -c say, -v tərsi, -r qovluqda rekursiv."

step "Sandbox-da nginx və app log-ları yaratmaq" \
  --why "Real log-a bənzər fayl olmadan axtarışı öyrənmək olmaz." \
  --cmd 'mkdir -p logs; printf "10:00:01 INFO app started\n10:00:05 INFO request /api/users 200\n10:01:12 ERROR db connection refused\n10:01:15 WARN retry 1\n10:01:20 error timeout on /api/orders\n10:02:00 INFO request /health 200\n10:02:30 ERROR db connection refused\n" > logs/app.log; printf "10.0.0.5 GET /index.html 200\n10.0.0.7 GET /missing 404\n10.0.0.5 POST /login 500\n10.0.0.9 GET /api 200\n" > logs/nginx-access.log; wc -l logs/*' \
  --explain "printf ... > fayl|çoxsətirli log yaradır" \
  --explain "wc -l|sətir sayı" \
  --expect "app.log 7, nginx-access.log 4 sətir" \
  --assert '[ "$(wc -l < logs/app.log)" = 7 ]'

step "Əsas axtarış" \
  --why "Yüzlərlə sətir arasında yalnız xətanı görmək lazımdır." \
  --cmd 'grep ERROR logs/app.log' \
  --explain "grep|pattern axtaran əmr" \
  --explain "ERROR|axtarılan söz (hərf həssas)" \
  --expect "İki ERROR sətri (db connection refused)" \
  --note "10:01:20 sətri 'error' (kiçik hərf) olduğu üçün tapılmadı. Növbəti addım." \
  --assert '[ "$(grep ERROR logs/app.log | wc -l)" = 2 ]'

step "-i: hərf fərqi, -n: sətir nömrəsi" \
  --why "Müxtəlif servislər ERROR, Error, error yazır; sətir nömrəsi isə problemi fayla çatdırmağı asanlaşdırır." \
  --cmd 'grep -in error logs/app.log' \
  --explain "-i|ignore case: ERROR, error, Error hamısı" \
  --explain "-n|hər sətrin əvvəlinə nömrə qoyur" \
  --predict "Neçə sətir çıxacaq: 2, 3, yoxsa 4?" \
  --expect "3 sətir, nömrələri 3, 5, 7" \
  --assert '[ "$(grep -i error logs/app.log | wc -l)" = 3 ]'

step "-c: saymaq və -v: tərsi" \
  --why "Neçə xəta var? Və xətasız sətirlər hansılardır?" \
  --cmd 'grep -ci error logs/app.log; echo "--- INFO olmayanlar ---"; grep -v INFO logs/app.log' \
  --explain "-c|uyğun sətirlərin sayı (sətirləri göstərmir)" \
  --explain "-v|invert: pattern OLMAYAN sətirlər" \
  --expect "3; sonra INFO olmayan 4 sətir" \
  --assert '[ "$(grep -vc INFO logs/app.log)" = 4 ]'

step "Pipe ilə: əmr çıxışında axtarış" \
  --why "Çoxlu əmrin çıxışı uzundur; grep ilə süzmək asan yoldur." \
  --cmd 'ls -l logs | grep nginx; echo "--- 5xx cavablar ---"; cat logs/nginx-access.log | grep " 500"' \
  --explain "cmd | grep X|soldakı əmrin çıxışı grep-ə girişdir" \
  --expect "nginx-access.log sətri, sonra POST /login 500" \
  --note "Pipe-ları Sessiya 5-6 və sonrakılarda dərinləşdirəcəyik; bura qədər: sol çıxış → sağ giriş." \
  --assert 'cat logs/nginx-access.log | grep -q " 500"'

step "-r: qovluqda rekursiv axtarış" \
  --why "'Bu IP/port hansı faylda yazılıb?' sualı: bütün qovluğu bir əmrlə skan et." \
  --cmd 'mkdir -p conf; printf "listen 8080;\nserver_name dev.example.net;\n" > conf/site.conf; printf "upstream 127.0.0.1:8080;\n" > conf/proxy.conf; grep -rn 8080 conf; echo "--- yalnız fayl adları ---"; grep -rl 8080 conf | sort' \
  --explain "-r|qovluq daxilində bütün fayllarda" \
  --explain "-l|yalnız uyğun gələn fayl adları" \
  --expect "İki faylda 8080 sətri; sonra iki fayl adı" \
  --assert '[ "$(grep -rl 8080 conf | wc -l)" = 2 ]'

step "^ — sətrin başı: ls -l-də yalnız qovluqlar" \
  --why "grep d adında d olan hər şeyi gətirir; ls -l-də qovluq sətri d ilə BAŞLAYIR, ona görə ^ lazımdır." \
  --cmd 'mkdir -p demo/dirA demo/dirB; touch demo/dfile demo/readme; ls -l demo | grep d; echo "--- yalnız qovluqlar ---"; ls -l demo | grep "^d"' \
  --explain "^|sətrin başlanğıcı (anchor)" \
  --explain "\"^d\"|sətir d hərfi ilə başlayır = qovluq" \
  --predict "grep d neçə sətir tapacaq, grep \"^d\" neçə?" \
  --expect "grep d: dirA, dirB, dfile (adında d var); grep \"^d\": yalnız dirA və dirB" \
  --assert '[ "$(ls -l demo | grep -c "^d")" = 2 ]'

step "Real use case: log-da yalnız bu günün sətirləri" \
  --why "Log həftələrlə yığılır; incident-də yalnız bir günün sətirləri lazımdır. Tarix sətrin başındadır — ^ ilə tutulur." \
  --cmd 'printf "2026-11-01T23:59:58+00:00 vm sshd[1]: Accepted publickey for aslan\n2026-11-02T05:21:07+00:00 vm sshd[2]: Failed password for root\n2026-11-02T05:22:10+00:00 vm app[3]: ERROR disk full\n2026-11-02T09:01:00+00:00 vm cron[4]: job ok since 2026-11-01\n" > logs/syslog.sample; grep -c "^2026-11-02" logs/syslog.sample; grep "^2026-11-02T05" logs/syslog.sample; echo "--- ^-sız ---"; grep -c "2026-11-01" logs/syslog.sample' \
  --explain "^2026-11-02|başlanğıc timestamp-ı həmin gün olan sətirlər" \
  --explain "^2026-11-02T05|həmin gün, saat 05:00–05:59" \
  --predict "2026-11-01 axtarışı ^-sız neçə sətir tapacaq?" \
  --expect "3; sonra saat 05 sətirləri (2 ədəd); ^-sız axtarış 2 verir, çünki cron sətrinin MESAJINDA da 2026-11-01 var" \
  --note "Real serverdə: sudo grep \"^\$(date +%F)\" /var/log/syslog. Köhnə sistemlərdə format 'Nov  2 05:21' (iki boşluq) ola bilər — əvvəl head -n 1 ilə formata bax." \
  --assert '[ "$(grep -c "^2026-11-02" logs/syslog.sample)" = 3 ] && [ "$(grep -c "2026-11-01" logs/syslog.sample)" = 2 ]'

step "^$ — boş sətirlər və konfiq təmizləmə" \
  --why "Konfiq fayllarında şərh və boş sətirlər çoxdur; real parametrləri görmək üçün onları atmaq lazımdır." \
  --cmd 'printf "# app konfiqi\n\nworkers=4\n\n\n# log\nlevel=info\n" > conf/app.conf; grep -c "^$" conf/app.conf; grep -n "^$" conf/app.conf; echo "--- yalnız real sətirlər ---"; grep -Ev "^#|^$" conf/app.conf' \
  --explain "^$|sətrin başı ilə sonu arasında heç nə yoxdur = boş sətir" \
  --explain "-c|boş sətirlərin sayı" \
  --explain "-E|genişləndirilmiş regex: | işarəsi \"və ya\" deməkdir" \
  --explain "-v|tərsi: şərh VƏ boş olmayanlar" \
  --expect "3; nömrələr 2:, 4:, 5:; sonra workers=4 və level=info" \
  --note "Tələ: yalnız boşluq/tab olan sətir ^$-ə uyğun GƏLMİR. Onları ^[[:space:]]*$ tutur." \
  --assert '[ "$(grep -c "^$" conf/app.conf)" = 3 ] && [ "$(grep -Ev "^#|^$" conf/app.conf | wc -l)" = 2 ]'

inject "Deploy konfiqə DEBUG yazıb" \
  "Kimsə production konfiqinə debug rejimi əlavə edib. Tapın və həmin sətri silin (əsli saxlanılsın)." \
  --cmd 'printf "workers=4\nDEBUG=true\nport=8080\n" > conf/prod.conf' \
  --symptom 'grep -n DEBUG conf/prod.conf' \
  --fix 'grep -v DEBUG conf/prod.conf > conf/prod.tmp; mv conf/prod.tmp conf/prod.conf' \
  --check '! grep -q DEBUG conf/prod.conf && grep -q workers conf/prod.conf && grep -q port= conf/prod.conf' \
  --hint "grep -v DEBUG conf/prod.conf > conf/prod.tmp, sonra mv ilə əvəz edin (eyni fayla > yazmayın — boşalar!)"

task "Xəta sayını yaz" \
  "app.log-da ERROR sətirlərinin sayını (böyük hərflə, -c ilə) err-count.txt-ə yazın." \
  --check '[ "$(tr -d "[:space:]" < err-count.txt)" = 2 ]' \
  --hint "grep -c ERROR logs/app.log > err-count.txt" \
  --solution 'grep -c ERROR logs/app.log > err-count.txt'

task "404 və 500 sətirləri" \
  "nginx-access.log-dan xətalı cavabları (404 və ya 500 olan sətirləri) errors.txt-ə yazın." \
  --check '[ "$(wc -l < errors.txt)" = 2 ] && grep -q 404 errors.txt && grep -q 500 errors.txt' \
  --hint "grep -E \"404|500\" və ya iki dəfə grep. -E alternativ üçün" \
  --solution 'grep -E " (404|500)$" logs/nginx-access.log > errors.txt'

task "Rekursiv axtarış nəticəsi" \
  "conf qovluğunda 'server_name' olan fayl(lar)ın adını sn.txt-ə yazın." \
  --check 'grep -q site.conf sn.txt && ! grep -q proxy.conf sn.txt' \
  --hint "grep -rl server_name conf" \
  --solution 'grep -rl server_name conf > sn.txt'

task "Bu günün sətirlərinin sayı" \
  "logs/syslog.sample-da 2026-11-02 tarixi ilə BAŞLAYAN sətirlərin sayını (grep -c və ^ ilə) day-count.txt-ə yazın." \
  --check '[ "$(tr -d "[:space:]" < day-count.txt)" = 3 ]' \
  --hint "grep -c \"^2026-11-02\" logs/syslog.sample > day-count.txt" \
  --solution 'grep -c "^2026-11-02" logs/syslog.sample > day-count.txt'

task "Təmiz konfiq" \
  "conf/app.conf-dan şərh (#) və boş sətirləri atın, nəticəni clean.conf-a yazın (yalnız 2 real sətir qalmalıdır)." \
  --check '[ "$(wc -l < clean.conf)" = 2 ] && grep -q workers clean.conf && grep -q level clean.conf && ! grep -q "^#" clean.conf' \
  --hint "grep -Ev \"^#|^\$\" conf/app.conf > clean.conf" \
  --solution 'grep -Ev "^#|^$" conf/app.conf > clean.conf'

lab_summary "Sessiya 14 — Faylda söz əvəzləmək (sed)" \
  "grep pattern fayl — sətirləri tapır" \
  "-i -n -c -v -r -l — ən çox işlənən flag-lar" \
  "^ sətrin başı, $ sətrin sonu: grep \"^d\" (qovluqlar), grep \"^2026-11-02\" (günün logu), grep \"^$\" (boş sətirlər)" \
  "cmd | grep — istənilən çıxışı süzür" \
  "eyni fayla > ilə yazmaq onu boşaldır — tmp + mv işlət"
