# Sessiya 15 — İstifadəçi yaratmaq və idarə etmək (useradd, adduser, usermod, groupadd, /etc/passwd, /etc/group, userdel)
lab_init 15 "İstifadəçi və qrup idarəetməsi: servis hesabları"
# konteynerdəki sudo shim "-u" bilmir: runuser ilə əvəz edirik (real sudo-ya toxunmur)
if [ "$(type -t sudo)" = function ]; then
  sudo() { if [ "$1" = -u ]; then local _u=$2; shift 2; ( cd /tmp && runuser -u "$_u" -- "$@" ); else "$@"; fi; }
fi

# Təhlükəsizlik: yalnız lab_ prefiksli hesablar. Dərs bitəndə (və ya Ctrl+C-də) geri qaytarılır.
cleanup 'sudo groupdel lab_ops 2>/dev/null'
cleanup 'sudo userdel -r lab_ci 2>/dev/null; sudo groupdel lab_ci 2>/dev/null'
cleanup 'sudo userdel -r lab_dev 2>/dev/null; sudo groupdel lab_dev 2>/dev/null'
cleanup 'sudo userdel -r lab_svc 2>/dev/null; sudo groupdel lab_svc 2>/dev/null'
cleanup 'sudo userdel -r lab_deploy 2>/dev/null; sudo groupdel lab_deploy 2>/dev/null'

objective \
  "root, system və normal istifadəçi fərqini /etc/passwd üzərində göstərməyi" \
  "useradd və adduser ilə deploy və servis hesabları yaratmağı" \
  "groupadd və usermod -aG ilə istifadəçini qrupa əlavə etməyi" \
  "userdel -r ilə hesabı təmiz silməyi"

concept "Niyə hər servis üçün ayrı istifadəçi?" \
  "Production-da nginx www-data kimi, CI runner gitlab-runner kimi işləyir. Servis hack olunsa, zərər onun hesabının icazələri qədərdir." \
  "Üç növ: root (UID 0), system user (UID 1-999, nologin, servis üçün) və normal user (UID 1000+, insanlar üçün)." \
  "Bu dərsdə yalnız lab_ prefiksli hesablar yaradılır; dərs bitəndə hamısı avtomatik silinir. /etc faylları əl ilə redaktə OLUNMUR."

step "Mövcud istifadəçilər: /etc/passwd" \
  --why "Yeni hesab yaratmazdan əvvəl sistemdə kimlərin olduğunu və servis hesablarının necə göründüyünü bilmək lazımdır." \
  --cmd 'grep -E "^(root|www-data):" /etc/passwd' \
  --explain "/etc/passwd|bütün hesabların siyahısı (hər sətir bir hesab)" \
  --explain "root:x:0:0|ad : parol(x=shadow-da) : UID : GID" \
  --explain "www-data|nginx/apache-nin işlətdiyi system user: home /var/www, shell nologin" \
  --expect "İki sətir: root (UID 0, /bin/bash) və www-data (UID 33, nologin)" \
  --predict "Sizcə www-data-nın shell-i niyə nologin-dir?" \
  --note "Format: ad:x:UID:GID:şərh:home:shell. System user-in login shell-i yoxdur, ona görə də ona SSH ilə girmək olmur, yalnız proses kimi işləyir." \
  --assert 'grep -q "^root:x:0:0:" /etc/passwd && getent passwd www-data | grep -q nologin'

step "Normal istifadəçi yarat: useradd" \
  --why "Deploy işini edən insan/avtomatika üçün ayrı hesab lazımdır, root ilə deploy etmək təhlükəlidir." \
  --cmd 'sudo useradd -m -s /bin/bash -c "Deploy user" lab_deploy && id lab_deploy && ls -ld /home/lab_deploy | cut -d" " -f1,3,4,9' \
  --explain "-m|home qovluğunu yarat (/home/lab_deploy). Ubuntu-da useradd bunu özü etmir" \
  --explain "-s /bin/bash|login shell təyin et" \
  --explain "-c|şərh (GECOS) sahəsi" \
  --explain "id|UID, əsas qrup və bütün qruplar" \
  --expect "uid=1000+(lab_deploy) gid=...(lab_deploy) groups=...(lab_deploy) və home qovluğu" \
  --note "Hər istifadəçi ilə eyni adlı qrup avtomatik yaranır (lab_deploy). Əsas qrupu bu olur." \
  --assert 'id lab_deploy | grep -q "(lab_deploy)" && test -d /home/lab_deploy' \
  --root

step "Hesab fayllarda: /etc/passwd və /etc/group" \
  --why "Hesabın həqiqətən yarandığını və hansı UID/GID aldığını fayldan oxumaq audit üçün vacibdir." \
  --cmd 'grep "^lab_deploy:" /etc/passwd; grep "^lab_deploy:" /etc/group' \
  --explain "passwd sətri|lab_deploy:x:UID:GID:Deploy user:/home/lab_deploy:/bin/bash" \
  --explain "group sətri|ad : x : GID : əlavə üzvlər (boş)" \
  --expect "Bir passwd sətri və bir group sətri" \
  --note "passwd-dəki 4-cü sahə (GID) və group-dakı 3-cü sahə eynidir: əsas qrup. 'x' o deməkdir ki, parol hash-i /etc/shadow-dadır." \
  --assert 'grep -q "^lab_deploy:x:[0-9]*:[0-9]*:Deploy user:/home/lab_deploy:/bin/bash$" /etc/passwd'

step "Qrup yarat və istifadəçini əlavə et: groupadd, usermod -aG" \
  --why "Bir neçə nəfərin eyni fayllara çıxışı qrup vasitəsilə verilir (məs. ops komandası, docker qrupu)." \
  --cmd 'sudo groupadd lab_ops && sudo usermod -aG lab_ops lab_deploy && id lab_deploy && grep "^lab_ops:" /etc/group' \
  --explain "groupadd lab_ops|yeni qrup" \
  --explain "usermod -aG|-a = əlavə et (köhnə qrupları saxla), -G = əlavə qrup siyahısı" \
  --explain "grep /etc/group|lab_ops sətrinin sonunda üzvlər görünür" \
  --expect "id çıxışında groups=...(lab_deploy),...(lab_ops); group sətri lab_ops:x:GID:lab_deploy" \
  --predict "-a olmadan (usermod -G lab_ops lab_deploy) yazsaq nə olardı?" \
  --note "-a unudulsa istifadəçi digər əlavə qruplardan çıxarılır (məsələn docker və ya sudo-dan). Production-da bu, giriş itkisinə səbəb olur. Qrup dəyişikliyi YENİ login sessiyasında aktiv olur." \
  --assert 'id -nG lab_deploy | grep -qw lab_ops' \
  --root

step "Servis hesabı: system user (login yoxdur)" \
  --why "Runner/servis hesabının interaktiv login-i olmamalıdır; yalnız prosesi işlətmək üçündür." \
  --cmd 'sudo useradd -r -s /usr/sbin/nologin -c "CI runner" lab_svc && getent passwd lab_svc && id -u lab_svc' \
  --explain "-r|system hesab: UID 1-999 aralığında, home yaradılmır" \
  --explain "-s /usr/sbin/nologin|login cəhdini rədd edən shell" \
  --explain "getent passwd|hesabı passwd bazasından oxuyur (fayl və ya LDAP)" \
  --expect "lab_svc sətri nologin ilə bitir; UID 1000-dən kiçikdir" \
  --note "gitlab-runner, prometheus, nginx hesabları belə yaranır. UID<1000 olması onların insan olmadığını göstərir." \
  --assert '[ "$(id -u lab_svc)" -lt 1000 ] && getent passwd lab_svc | grep -q nologin' \
  --root

prep 'command -v adduser >/dev/null || { sudo apt-get update -qq && sudo apt-get install -y -qq adduser; }'

step "adduser: istifadəçi dostu alternativ" \
  --why "Debian/Ubuntu-da adduser daha çox işi (home, qrup, skel faylları) avtomatik görür. Skriptdə sual verməsin deyə flag lazımdır." \
  --cmd 'sudo adduser --disabled-password --gecos "Developer" lab_dev >/dev/null 2>&1; id lab_dev; ls -a /home/lab_dev | head -n 5' \
  --explain "adduser|perl skripti, useradd üzərində; Ubuntu/Debian-a məxsus" \
  --explain "--disabled-password|parolsuz hesab (SSH açarı ilə girəcək)" \
  --explain "--gecos|tam ad sahəsi; verilməsə adduser soruşur (interaktiv)" \
  --expect "id çıxışı və home-da .bashrc, .profile kimi şablon fayllar" \
  --note "useradd = aşağı səviyyəli, hər distroda eyni. adduser = rahat, yalnız Debian/Ubuntu. Skriptlərdə və Ansible-da useradd, əl ilə işdə adduser daha çox işlənir." \
  --assert 'id lab_dev | grep -q "(lab_dev)" && test -f /home/lab_dev/.profile' \
  --root

step "Hesabı sil: userdel -r" \
  --why "Komanda üzvü ayrılanda və ya servis ləğv olunanda hesab silinməlidir, yoxsa köhnə hesablar təhlükəsizlik boşluğudur." \
  --cmd 'sudo userdel lab_svc; getent passwd lab_svc || echo "lab_svc silindi"; sudo userdel -r lab_dev 2>/dev/null; getent passwd lab_dev || echo "lab_dev silindi"; test -d /home/lab_dev && echo "home qaldı" || echo "home də silindi"' \
  --explain "userdel|hesabı /etc/passwd-dən silir" \
  --explain "-r|home qovluğunu və mail qutusunu da silir (olmasa home yetim qalır)" \
  --expect "lab_svc silindi, lab_dev silindi, home də silindi" \
  --note "-r olmadan home qovluğu diskdə qalır və sonra eyni UID-ni alan yeni hesab onun sahibi olur. Bu, klassik təhlükəsizlik səhvidir." \
  --assert '! getent passwd lab_svc && ! getent passwd lab_dev && ! test -d /home/lab_dev' \
  --root

task "CI hesabı yarat" \
  "lab_ci adlı normal istifadəçi yaradın: home qovluğu olsun, shell /bin/bash, və lab_ops qrupunun üzvü olsun." \
  --check 'getent passwd lab_ci | grep -q ":/bin/bash$" && test -d /home/lab_ci && id -nG lab_ci | grep -qw lab_ops' \
  --hint "useradd üçün -m, -s və -G (əlavə qrup) seçimlərinə baxın. Əvvəl lab_ops qrupu mövcud olmalıdır (addım 4)." \
  --solution 'sudo useradd -m -s /bin/bash -G lab_ops lab_ci'

task "UID-ni fayla yaz" \
  "lab_deploy hesabının UID rəqəmini (yalnız rəqəm) iş qovluğundakı uid.txt faylına yazın." \
  --check '[ "$(tr -d "[:space:]" < uid.txt)" = "$(id -u lab_deploy)" ]' \
  --hint "id əmrinin -u seçimi yalnız UID verir. Çıxışı > ilə yönləndirin." \
  --solution 'id -u lab_deploy > uid.txt'

task "Köhnə hesabı təmiz sil" \
  "lab_ci hesabını home qovluğu ilə birlikdə silin (silindikdən sonra getent passwd lab_ci boş olmalıdır)." \
  --check '! getent passwd lab_ci && ! test -d /home/lab_ci' \
  --hint "userdel-in home qovluğunu da silən seçimi hansıdır?" \
  --solution 'sudo userdel -r lab_ci'

lab_summary "Sessiya 16 — İstifadəçi kimi daxil olmaq (su, sudo -u, passwd)" \
  "useradd -m -s (normal), useradd -r (system), adduser (Debian rahatlığı)" \
  "usermod -aG qrup user — həmişə -a ilə, sonra id ilə yoxla" \
  "/etc/passwd (hesab), /etc/group (qrup), UID<1000 = system" \
  "userdel -r ilə təmiz sil; servislər üçün ayrı nologin hesab"
