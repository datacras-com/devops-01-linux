# Sessiya 19 — chmod (simvolik və oktal): deploy.sh +x, 755/644/600
lab_init 19 "chmod: icazələri dəyişmək (simvolik və oktal)"
# konteynerdəki sudo shim "-u" bilmir: runuser ilə əvəz edirik (real sudo-ya toxunmur)
if [ "$(type -t sudo)" = function ]; then
  sudo() { if [ "$1" = -u ]; then local _u=$2; shift 2; ( cd /tmp && runuser -u "$_u" -- "$@" ); else "$@"; fi; }
fi

# Təhlükəsizlik: yalnız lab_ hesabları və /tmp/lab_chmod. Dərs bitəndə silinir.
cleanup 'sudo rm -rf /tmp/lab_chmod'
cleanup 'sudo userdel lab_www 2>/dev/null; sudo userdel lab_deploy 2>/dev/null'

objective \
  "chmod u+x, g-w, o= kimi simvolik ifadələri yazıb nəticəni proqnozlaşdırmağı" \
  "755, 644, 600, 750 oktal rejimlərini nə vaxt seçməyi" \
  "deploy.sh icra olunmayanda, nginx.conf oxunmayanda səbəbi tapıb düzəltməyi" \
  "chmod -R ilə qovluq ağacının icazəsini dəyişməyi"

concept "chmod: iki yazılış, bir nəticə" \
  "Simvolik: chmod u+x,g-w,o= fayl ('kim' u/g/o/a + operator +/-/= + hərflər). + əlavə edir, - silir, = köhnəni silib yenisini yazır." \
  "Oktal: chmod 750 fayl: hər rəqəm bir blokdur (4=r, 2=w, 1=x cəmi). Praktik qayda: 755 skript/qovluq, 644 konfiq, 600 gizli (.env, private key). 777 demək olar həmişə səhvdir."

step "Hazırlıq: deploy hesabı, servis hesabı və fayllar" \
  --why "Root icazələri keçir; Permission denied-i yalnız adi hesabla görmək olar. lab_deploy fayl sahibi, lab_www isə 'nginx' rolundadır." \
  --cmd 'sudo useradd -M -s /usr/sbin/nologin lab_deploy && sudo useradd -M -s /usr/sbin/nologin lab_www && sudo install -d -m 755 -o lab_deploy /tmp/lab_chmod && sudo -u lab_deploy bash -c "cd /tmp/lab_chmod && printf \"#!/bin/bash\necho releasing\n\" > deploy.sh && printf \"server { listen 80; }\n\" > nginx.conf && printf \"DB_PASS=secret\n\" > .env" && stat -c "%a %A %U %n" /tmp/lab_chmod/deploy.sh /tmp/lab_chmod/nginx.conf /tmp/lab_chmod/.env' \
  --explain "install -d -m 755 -o|qovluğu icazə və sahib ilə yaradır" \
  --explain "sudo -u lab_deploy bash -c|faylları lab_deploy yaradır (sahibi odur)" \
  --expect "Üç fayl da 644 -rw-r--r-- lab_deploy" \
  --note "Yeni fayl default 644 olur (umask 022). Skript üçün x yoxdur, .env isə hamı üçün oxunandır: ikisi də düzəlməlidir." \
  --assert '[ "$(stat -c %a /tmp/lab_chmod/deploy.sh)" = 644 ] && [ "$(stat -c %U /tmp/lab_chmod/.env)" = lab_deploy ]' \
  --root

step "Problem: deploy.sh icra olunmur" \
  --why "CI pipeline-ın ən məşhur xətası: skript commit olunub, amma icra biti yoxdur." \
  --cmd 'sudo -u lab_deploy bash -c "/tmp/lab_chmod/deploy.sh" 2>&1' \
  --explain "Permission denied|fayl var, oxunur, amma x (icra) yoxdur" \
  --expect "bash: ... deploy.sh: Permission denied" \
  --note "Faylı ls -l ilə yoxlayın: -rw-r--r-- idi, x yoxdur. Həll chmod +x-dir." \
  --assert 'sudo -u lab_deploy bash -c "/tmp/lab_chmod/deploy.sh" 2>&1 | grep -q "Permission denied"' \
  --allow-fail --root

step "Simvolik chmod: u+x, o=, g=rx" \
  --why "Simvolik forma 'yalnız bunu dəyiş, qalanına toxunma' deyəndə ideal formadır." \
  --cmd 'f=/tmp/lab_chmod/deploy.sh; sudo -u lab_deploy chmod u+x $f; stat -c "u+x     -> %a %A" $f; sudo -u lab_deploy chmod g-w $f; stat -c "g-w     -> %a %A (dəyişmədi, g-də w yox idi)" $f; sudo -u lab_deploy chmod o= $f; stat -c "o=      -> %a %A" $f; sudo -u lab_deploy chmod g=rx $f; stat -c "g=rx    -> %a %A" $f; sudo -u lab_deploy bash -c "$f"' \
  --explain "u+x|owner-ə icra əlavə et: 644 → 744" \
  --explain "o=|others üçün hər şeyi sil: 744 → 740" \
  --explain "g=rx|group-u dəqiq r-x et (köhnəni əvəz edir): 740 → 750" \
  --expect "744, 744, 740, 750 və sonda 'releasing' çıxışı" \
  --predict "chmod g-w, group-da w olmadığı halda xəta verərmi?" \
  --note "Xəta vermir: olmayan biti silmək heç nə etmir. '+' və '-' yalnız qeyd olunanlara, '=' isə bütün bloka toxunur." \
  --assert '[ "$(stat -c %a /tmp/lab_chmod/deploy.sh)" = 750 ]' \
  --root

step "Oktal chmod: 755 (skript), 644 (konfiq), 600 (sirr)" \
  --why "Production-da icazələri bir rəqəmlə təyin etmək həm sürətli, həm də dəqiqdir." \
  --cmd 'sudo -u lab_deploy chmod 755 /tmp/lab_chmod/deploy.sh; sudo -u lab_deploy chmod 644 /tmp/lab_chmod/nginx.conf; sudo -u lab_deploy chmod 600 /tmp/lab_chmod/.env; stat -c "%a %A %n" /tmp/lab_chmod/deploy.sh /tmp/lab_chmod/nginx.conf /tmp/lab_chmod/.env; echo "--- lab_www (nginx) nəyi oxuyur? ---"; for f in nginx.conf .env; do sudo -u lab_www test -r /tmp/lab_chmod/$f && echo "$f: oxuya bilir" || echo "$f: Permission denied"; done' \
  --explain "755|rwxr-xr-x: sahib tam, digərləri oxu+icra (skript, qovluq)" \
  --explain "644|rw-r--r--: konfiq, hamı oxuyur, yalnız sahib yazır" \
  --explain "600|rw-------: yalnız sahib; .env, SSH private key" \
  --expect "755, 644, 600; lab_www nginx.conf-u oxuyur, .env-i yox" \
  --note "SSH private key 600-dən açıq olsa ssh 'UNPROTECTED PRIVATE KEY FILE' deyib rədd edir. Konfiq 644 olsa servis hesabı onu oxuya bilir." \
  --assert '[ "$(stat -c %a /tmp/lab_chmod/.env)" = 600 ] && sudo -u lab_www test -r /tmp/lab_chmod/nginx.conf && ! sudo -u lab_www test -r /tmp/lab_chmod/.env' \
  --root

step "Qovluq və -R: ağacın icazəsi" \
  --why "Qovluqda x olmasa içindəki fayllara cd/oxu mümkün deyil. Deploy zamanı bütün ağacı tək əmrlə qurmaq lazım gəlir." \
  --cmd 'sudo -u lab_deploy chmod o-x /tmp/lab_chmod; sudo -u lab_www cat /tmp/lab_chmod/nginx.conf 2>&1; sudo -u lab_deploy chmod o+x /tmp/lab_chmod; sudo -u lab_www cat /tmp/lab_chmod/nginx.conf; sudo -u lab_deploy mkdir -p /tmp/lab_chmod/static/img; sudo -u lab_deploy chmod -R 750 /tmp/lab_chmod/static; stat -c "%a %n" /tmp/lab_chmod/static /tmp/lab_chmod/static/img' \
  --explain "o-x|qovluqdan others-in girmə icazəsini al: içindəki fayllar da əlçatmaz olur" \
  --explain "o+x|geri ver" \
  --explain "-R|rekursiv: qovluq və bütün içindəkilər" \
  --expect "Birinci cat: Permission denied; ikincisi konfiqi göstərir; sonda 750 static və 750 static/img" \
  --note "-R fayllara da x qoyur, bu çox vaxt lazımsızdır. Alternativ: find ... -type f -exec chmod 644 {} +  və  find ... -type d -exec chmod 755 {} +  ayrı-ayrı." \
  --assert '[ "$(stat -c %a /tmp/lab_chmod/static/img)" = 750 ] && sudo -u lab_www cat /tmp/lab_chmod/nginx.conf | grep -q listen' \
  --root

inject "nginx.conf oxunmur" \
  "Kimsə səhvən 'chmod 000 nginx.conf' etdi. nginx (lab_www) konfiqi aça bilmir." \
  --cmd 'sudo chmod 000 /tmp/lab_chmod/nginx.conf' \
  --symptom 'sudo -u lab_www cat /tmp/lab_chmod/nginx.conf 2>&1; stat -c "%a %A %n" /tmp/lab_chmod/nginx.conf' \
  --fix 'sudo chmod 644 /tmp/lab_chmod/nginx.conf' \
  --check '[ "$(stat -c %a /tmp/lab_chmod/nginx.conf)" = 644 ] && sudo -u lab_www test -r /tmp/lab_chmod/nginx.conf' \
  --hint "stat icazəni göstərir. Konfiq faylı üçün düzgün oktal 644-dür (sahib yazır, hamı oxuyur)."

task "Release skripti: 750" \
  "İş qovluğunda içində 'echo ok' olan release.sh yaradın və icazəsini 750 edin." \
  --check '[ "$(stat -c %a release.sh)" = 750 ] && grep -q "echo ok" release.sh' \
  --hint "printf 'echo ok\\n' > release.sh; sonra chmod 750 release.sh." \
  --solution "printf 'echo ok\n' > release.sh; chmod 750 release.sh"

task "Simvolik ilə sirr faylı" \
  "app.env faylı yaradın və YALNIZ simvolik yazılışla (rəqəm yox) elə edin ki, sahib oxuya/yaza bilsin, qrup və others heç nə edə bilməsin (600)." \
  --check '[ "$(stat -c %a app.env)" = 600 ]' \
  --hint "chmod u=rw,go= app.env: '=' köhnə icazəni silir, boş siyahı isə hamısını götürür." \
  --solution 'touch app.env; chmod u=rw,go= app.env'

task "Qovluq ağacı" \
  "site/css qovluq ağacını yaradın və hər iki qovluğu rekursiv olaraq 750 edin." \
  --check '[ "$(stat -c %a site)" = 750 ] && [ "$(stat -c %a site/css)" = 750 ]' \
  --hint "mkdir -p site/css, sonra chmod -R 750 site." \
  --solution 'mkdir -p site/css; chmod -R 750 site'

lab_summary "Sessiya 20 — chown və chgrp: sahiblik" \
  "chmod u+x / g-w / o= (simvolik) və chmod 755 / 644 / 600 (oktal)" \
  "skript 755, konfiq 644, sirr (.env, key) 600; 777 istifadə etmə" \
  "Permission denied: stat ilə bax → kim icra edir, hansı blok tətbiq olur" \
  "chmod -R ağac üçün; fayl və qovluqları find ilə ayrı-ayrı qurmaq daha təmizdir"
