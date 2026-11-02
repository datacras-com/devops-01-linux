# Sessiya 18 — Fayl icazələri (rwx, ugo, oktal, umask, stat)
lab_init 18 "Fayl icazələri: rwx, owner/group/others, oktal, umask"
# konteynerdəki sudo shim "-u" bilmir: runuser ilə əvəz edirik (real sudo-ya toxunmur)
if [ "$(type -t sudo)" = function ]; then
  sudo() { if [ "$1" = -u ]; then local _u=$2; shift 2; ( cd /tmp && runuser -u "$_u" -- "$@" ); else "$@"; fi; }
fi

# Təhlükəsizlik: yalnız lab_ hesabları və /tmp/lab_perm. Dərs bitəndə hamısı silinir.
cleanup 'sudo rm -rf /tmp/lab_perm'
cleanup 'sudo userdel lab_guest 2>/dev/null; sudo userdel lab_dev 2>/dev/null; sudo userdel lab_deploy 2>/dev/null'
cleanup 'sudo groupdel lab_ops 2>/dev/null'

objective \
  "-rwxr-x--- kimi icazə sətrini owner/group/others bloklarına ayırıb oxumağı" \
  "fayl və qovluq üçün r, w, x-in fərqli mənasını izah etməyi" \
  "icazəni oktal rəqəmə (rwx=7, r-x=5, r--=4) çevirməyi" \
  "umask-ın yeni faylların icazəsini necə təyin etdiyini göstərməyi"

concept "Üç blok, üç hərf" \
  "Hər fayl üçün 3 blok: owner (u), group (g), others (o). Hər blokda r (oxu=4), w (yaz=2), x (icra=1). Sistem sizi yuxarıdan aşağı yoxlayır: sahibsinizsə owner bloku, qrupdasınızsa group bloku, yoxsa others." \
  "Qovluq üçün: r = ls ilə məzmunu görmək, w = içində yaratmaq/silmək, x = cd ilə girmək. root icazələri keçir, ona görə də Permission denied-i yalnız adi hesabla sınamaq olur."

step "Hesabları və nümunə faylları hazırla" \
  --why "İcazənin mənası yalnız fərqli kimliklərin eyni fayla müxtəlif cavab aldığını görəndə aydın olur." \
  --cmd 'sudo groupadd lab_ops && sudo useradd -M -s /usr/sbin/nologin lab_deploy && sudo useradd -M -s /usr/sbin/nologin -G lab_ops lab_dev && sudo useradd -M -s /usr/sbin/nologin lab_guest && sudo install -d -m 755 /tmp/lab_perm && sudo install -m 640 -o lab_deploy -g lab_ops /dev/null /tmp/lab_perm/app.conf && printf "#!/bin/bash\necho deployed\n" | sudo tee /tmp/lab_perm/run.sh >/dev/null && sudo chown lab_deploy:lab_ops /tmp/lab_perm/run.sh && sudo chmod 750 /tmp/lab_perm/run.sh && id lab_dev && id lab_guest' \
  --explain "lab_deploy|fayl sahibi" \
  --explain "lab_dev|lab_ops qrupunun üzvü" \
  --explain "lab_guest|nə sahib, nə qrup üzvü (others)" \
  --explain "install -m -o -g|fayl yaradır, sahibini, qrupunu və icazəsini bir addımda təyin edir" \
  --expect "lab_dev lab_ops qrupundadır, lab_guest isə yalnız öz qrupundadır" \
  --note "chown və chmod-u növbəti iki dərsdə öyrənəcəksiniz; burada yalnız sənədləri hazırlayırıq." \
  --assert 'id -nG lab_dev | grep -qw lab_ops && ! id -nG lab_guest | grep -qw lab_ops && test -f /tmp/lab_perm/run.sh' \
  --root

step "İcazəni oxu: ls -l və stat" \
  --why "Hər Permission denied araşdırması 'fayl kimindir və nə icazəsi var' sualı ilə başlayır." \
  --cmd 'ls -l /tmp/lab_perm | tail -n +2 | tr -s " " | cut -d" " -f1,3,4,9; echo "---"; stat -c "%A  sahib=%U  qrup=%G  oktal=%a  %n" /tmp/lab_perm/app.conf /tmp/lab_perm/run.sh' \
  --explain "-rw-r-----|app.conf: owner=rw-, group=r--, others=---" \
  --explain "-rwxr-x---|run.sh: owner=rwx, group=r-x, others=---" \
  --explain "stat -c|çıxış formatı: %A simvolik icazə, %U sahib, %G qrup, %a oktal" \
  --expect "app.conf -rw-r----- lab_deploy lab_ops 640; run.sh -rwxr-x--- ... 750" \
  --predict "lab_dev (lab_ops üzvü) app.conf-u oxuya bilərmi? Yaza bilərmi?" \
  --note "stat həm simvolik, həm oktal formatı yanaşı verir. Skriptlərdə ls çıxışını parse etməkdənsə stat -c istifadə edin." \
  --assert '[ "$(stat -c %a /tmp/lab_perm/app.conf)" = 640 ] && [ "$(stat -c %a /tmp/lab_perm/run.sh)" = 750 ]'

step "Kim oxuya/yaza bilər? (owner, group, others)" \
  --why "Eyni fayl üç fərqli kimlik üçün üç fərqli cavab verir." \
  --cmd 'for u in lab_deploy lab_dev lab_guest; do r=no; w=no; sudo -u $u test -r /tmp/lab_perm/app.conf && r=yes; sudo -u $u test -w /tmp/lab_perm/app.conf && w=yes; echo "$u: oxu=$r yaz=$w"; done' \
  --explain "test -r / -w|cari kimlik üçün faylı oxuya/yaza bilirsə uğurlu (kod 0)" \
  --explain "sudo -u \$u|test-i həmin hesab kimi icra edir" \
  --expect "lab_deploy: oxu=yes yaz=yes; lab_dev: oxu=yes yaz=no; lab_guest: oxu=no yaz=no" \
  --note "lab_deploy owner (rw-), lab_dev group (r--), lab_guest others (---). Linux ən spesifik bloku seçir: sahib olan hesab group bloku nə deyirsə-desin owner blokuna baxılır." \
  --assert '[ "$(sudo -u lab_dev test -r /tmp/lab_perm/app.conf && echo y)" = y ] && ! sudo -u lab_guest test -r /tmp/lab_perm/app.conf' \
  --root

step "x icazəsi: skript icra etmək" \
  --why "'Permission denied' ilə deploy skripti çox vaxt x-in olmamasından yaranır." \
  --cmd 'sudo -u lab_dev /tmp/lab_perm/run.sh; echo "lab_dev kodu: $?"; sudo -u lab_guest bash -c "/tmp/lab_perm/run.sh" 2>&1; echo "lab_guest kodu: $?"' \
  --explain "lab_dev|group r-x: oxuya və icra edə bilər" \
  --explain "lab_guest|others ---: icra cəhdi rədd edilir" \
  --expect "lab_dev: deployed və kod 0; lab_guest: Permission denied və kod 126" \
  --note "Shell 126 kodu 'tapıldı, amma icra olunmur' deməkdir (127 isə 'tapılmadı'). CI log-unda 126 görsəniz birbaşa icazələrə baxın." \
  --assert 'sudo -u lab_dev /tmp/lab_perm/run.sh | grep -q deployed' \
  --allow-fail --root

step "Qovluq icazəsi: r və x fərqli şeylərdir" \
  --why "Qovluqda r olmadan x ola bilər: adı bilsəniz faylı oxuyarsınız, amma siyahını görməzsiniz." \
  --cmd 'sudo install -d -m 711 /tmp/lab_perm/drop && echo ok | sudo tee /tmp/lab_perm/drop/known.txt >/dev/null && sudo chmod 644 /tmp/lab_perm/drop/known.txt && stat -c "%A %n" /tmp/lab_perm/drop; echo "--- ls ---"; sudo -u lab_guest ls /tmp/lab_perm/drop 2>&1; echo "--- cat ---"; sudo -u lab_guest cat /tmp/lab_perm/drop/known.txt' \
  --explain "drwx--x--x (711)|others üçün yalnız x: girmək olar, siyahı görmək olmaz" \
  --explain "ls|qovluq r tələb edir → rədd" \
  --explain "cat known.txt|yalnız x lazımdır (adı bilirik) → işləyir" \
  --expect "ls: Permission denied; cat: ok" \
  --note "Bu, 'drop-box' qovluqlarında istifadə olunur. Həm də /home/user qovluğunun başqalarına x icazəsi verməsinin təhlükəsi odur ki, fayl adlarını bilənlər oxuya bilər." \
  --assert 'sudo -u lab_guest cat /tmp/lab_perm/drop/known.txt | grep -q ok && ! sudo -u lab_guest ls /tmp/lab_perm/drop' \
  --root

step "Oktal rəqəmlər və umask" \
  --why "Yeni fayl icazəsini umask təyin edir; servis fayllarının gizli çıxmaması üçün bunu bilmək lazımdır." \
  --cmd '(umask 022; touch f_022; mkdir d_022; umask 077; touch f_077; mkdir d_077; stat -c "%a %A %n" f_022 d_022 f_077 d_077)' \
  --explain "umask 022|fayl 666-022=644, qovluq 777-022=755" \
  --explain "umask 077|fayl 600, qovluq 700: yalnız sahib" \
  --explain "( ... )|alt shell: umask yalnız bu əmrlər üçün dəyişir" \
  --expect "644 -rw-r--r-- f_022, 755 d_022, 600 f_077, 700 d_077" \
  --note "Fayl 666-dan, qovluq 777-dən başlayır; umask hissəsi çıxılır. Oktal: 6=4+2 (rw-), 5=4+1 (r-x), 7=4+2+1, 0=heç nə. Yoxlama üçün cari umask: 'umask' əmri." \
  --assert '[ "$(stat -c %a f_022)" = 644 ] && [ "$(stat -c %a d_077)" = 700 ]'

task "umask 077 ilə gizli fayl" \
  "umask 077 təyin olunmuş alt shell-də key.txt faylı yaradın ki, icazəsi 600 olsun (cari shell-in umask-ını dəyişməyin)." \
  --check '[ "$(stat -c %a key.txt)" = 600 ]' \
  --hint "( umask 077; touch key.txt ) şəklində alt shell istifadə edin." \
  --solution '(umask 077; touch key.txt)'

task "Simvoldan oktala" \
  "rwxr-x--- icazəsinin oktal qarşılığını (üç rəqəm) mode.txt-ə yazın." \
  --check '[ "$(tr -d "[:space:]" < mode.txt)" = 750 ]' \
  --hint "rwx=4+2+1, r-x=4+0+1, ---=0." \
  --solution 'echo 750 > mode.txt'

task "Kim oxuya bilər?" \
  "/tmp/lab_perm/app.conf faylını oxuya bilən, amma sahibi olmayan hesabın adını (lab_dev, lab_guest) who.txt-ə yazın." \
  --check '[ "$(tr -d "[:space:]" < who.txt)" = lab_dev ]' \
  --hint "Addım 4-ün çıxışına baxın: group bloku r-- olduğu üçün hansı hesab oxuyur?" \
  --solution 'echo lab_dev > who.txt'

lab_summary "Sessiya 19 — chmod ilə icazələri dəyişmək" \
  "İcazə sətiri: tip + owner + group + others (3x3)" \
  "r=4 w=2 x=1; fayl və qovluq üçün mənası fərqlidir" \
  "umask yeni faylların default icazəsini təyin edir (022 → 644/755)" \
  "stat -c '%A %a %U %G' — skript üçün etibarlı icazə sorğusu"
