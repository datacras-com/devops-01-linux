# Sessiya 12 — Fayl axtarmaq (find, diff, file)
lab_init 12 "find, diff, file: tap, müqayisə et, tanı"

objective \
  "find ilə faylı ada, tipə, yaşa və ölçüyə görə tapmağı" \
  "diff ilə iki konfiq faylının fərqini oxumağı" \
  "file ilə uzantısız faylın növünü təyin etməyi" \
  "bu üç əmri deploy öncəsi yoxlamada birləşdirməyi"

concept "Üç alət, üç sual" \
  "find — 'fayl haradadır?'  diff — 'iki fayl nə ilə fərqlənir?'  file — 'bu fayl nədir?'" \
  "find /yol şərtlər: -name ada, -type f/d tipə, -mtime N yaşa (gün), -size ölçüyə görə süzür. diff-də boş çıxış = fayllar eynidir."

step "Sandbox-da real layihə strukturu hazırlamaq" \
  --why "find-ı sınamaq üçün ağac lazımdır." \
  --cmd 'mkdir -p srv/app/logs srv/app/conf srv/backup; echo "port=8080" > srv/app/conf/app.conf; echo "port=8080" > srv/backup/app.conf; echo "INFO ok" > srv/app/logs/app.log; echo "ERROR x" > srv/app/logs/error.log; printf "#!/bin/bash\necho hi\n" > srv/app/deploy.sh; find srv | sort' \
  --explain "find srv|srv-dən başlayıb hər şeyi rekursiv göstərir" \
  --explain "sort|çıxışı sıralayır (deterministik olsun)" \
  --expect "srv ağacında cəmi 10 yol (5 fayl + 5 qovluq)" \
  --assert 'find srv | wc -l | grep -q "^10$"'

step "find -name: ada görə" \
  --why "Konfiq və ya log harada olduğunu bilmirsiniz — ada görə tapın." \
  --cmd 'find srv -name "app.conf"; find srv -name "*.log" | sort' \
  --explain "find yol|haradan axtaracağı" \
  --explain "-name \"*.log\"|şablon (dırnaq içində! shell-in genişləndirməsinin qarşısı)" \
  --expect "İki app.conf yolu və iki .log faylı" \
  --assert '[ "$(find srv -name "*.log" | wc -l)" = 2 ]'

step "find -type: fayl və ya qovluq" \
  --why "Yalnız qovluqları və ya yalnız faylları saymaq üçün." \
  --cmd 'echo "fayllar:"; find srv -type f | wc -l; echo "qovluqlar:"; find srv -type d | sort' \
  --explain "-type f|yalnız adi fayllar" \
  --explain "-type d|yalnız qovluqlar (directory)" \
  --expect "5 fayl; srv, srv/app, srv/app/conf, srv/app/logs, srv/backup qovluqları" \
  --assert '[ "$(find srv -type f | wc -l)" = 5 ]'

step "find -mtime və -size" \
  --why "Disk dolanda 'köhnə və böyük log-lar hansılardır?' sualı üçün." \
  --cmd 'dd if=/dev/zero of=srv/app/logs/big.log bs=1k count=20 2>/dev/null; touch -d "10 days ago" srv/app/logs/old.log; echo "-size +10k:"; find srv -type f -size +10k; echo "-mtime +7:"; find srv -type f -mtime +7' \
  --explain "-size +10k|10 kilobaytdan böyük (+ böyük, - kiçik)" \
  --explain "-mtime +7|7 gündən əvvəl dəyişdirilmiş" \
  --expect "big.log ölçüyə görə, old.log yaşa görə tapılır" \
  --note "Bu iki şərtin birləşməsi log rotation və disk təmizliyinin əsasıdır. Silmək üçün find-ı sonra -delete ilə birləşdirərsiniz, əvvəl həmişə yalnız siyahıya baxın." \
  --assert 'find srv -size +10k | grep -q big.log && find srv -mtime +7 | grep -q old.log'

step "diff: eyni fayllar" \
  --why "Backup orijinalla üst-üstə düşürmü?" \
  --cmd 'diff srv/app/conf/app.conf srv/backup/app.conf; echo "exit=$?"' \
  --explain "diff A B|A-nı B ilə sətir-sətir müqayisə edir" \
  --explain "exit=0|fərq yoxdur" \
  --expect "Çıxış yoxdur, exit=0" \
  --assert 'diff srv/app/conf/app.conf srv/backup/app.conf'

step "diff: fərqli fayllar" \
  --why "Deploy-dan sonra konfiqdə nə dəyişdi? diff dəqiq göstərir." \
  --cmd 'printf "port=9090\nworkers=4\n" > srv/app/conf/app.conf; diff srv/backup/app.conf srv/app/conf/app.conf; echo "exit=$?"' \
  --explain "<|birinci fayldakı sətir (backup)" \
  --explain ">|ikinci fayldakı sətir (yeni)" \
  --explain "1c1|1-ci sətir dəyişib; 1a2 — əlavə olunub" \
  --expect "< port=8080, > port=9090, > workers=4; exit=1" \
  --note "Exit 1 = fərq var. Skriptlərdə 'diff -q A B' ilə yalnız fərqin olub-olmamasını yoxlaya bilərsiniz." \
  --assert '! diff -q srv/backup/app.conf srv/app/conf/app.conf'

prep 'command -v file >/dev/null || { sudo apt-get update -qq; sudo apt-get install -y file; }'

step "file: faylın növü" \
  --why "Uzantısız fayl script-dirmi, mətn, yoxsa binary? Qurmadan əvvəl bilin." \
  --cmd 'cp srv/app/deploy.sh srv/app/deploy; file srv/app/deploy srv/app/conf/app.conf srv/app; file -b /bin/ls | cut -c1-9' \
  --explain "file ad|məzmuna baxıb növü deyir, uzantıya yox" \
  --explain "-b|brief: fayl adı olmadan yalnız növ" \
  --expect "Shell script, ASCII text, directory, ELF" \
  --assert 'file srv/app/deploy | grep -qi "script"'

task "Bütün .conf fayllarını tap" \
  "srv ağacındakı bütün .conf fayllarının yollarını conf-list.txt-ə yazın." \
  --check '[ "$(wc -l < conf-list.txt)" = 2 ] && grep -q app.conf conf-list.txt' \
  --hint "find srv -name \"*.conf\" > conf-list.txt" \
  --solution 'find srv -name "*.conf" > conf-list.txt'

task "Böyük fayl tap" \
  "10 KB-dan böyük faylın yolunu big-list.txt-ə yazın." \
  --check 'grep -q big.log big-list.txt && [ "$(wc -l < big-list.txt)" = 1 ]' \
  --hint "find ... -type f -size +10k" \
  --solution 'find srv -type f -size +10k > big-list.txt'

task "Konfiq fərqini saxla" \
  "backup və cari app.conf arasındakı diff nəticəsini config.diff-ə yazın." \
  --check 'grep -q 9090 config.diff && grep -q 8080 config.diff' \
  --hint "diff köhnə yeni > config.diff" \
  --solution 'diff srv/backup/app.conf srv/app/conf/app.conf > config.diff || true'

lab_summary "Sessiya 13 — Faylda söz axtarmaq (grep)" \
  "find yol -name/-type/-mtime/-size — fayl tapmaq" \
  "diff A B — boş çıxış eynidir; < köhnə, > yeni" \
  "file — məzmuna görə növ" \
  "silmədən əvvəl find ilə yalnız siyahıya bax"
