# Sessiya 16 — Başqa istifadəçi kimi işləmək (su, sudo -u, passwd, chpasswd)
lab_init 16 "Başqa istifadəçi kimi işləmək: su, sudo -u, passwd"
# konteynerdəki sudo shim "-u" bilmir: runuser ilə əvəz edirik (real sudo-ya toxunmur)
if [ "$(type -t sudo)" = function ]; then
  sudo() { if [ "$1" = -u ]; then local _u=$2; shift 2; ( cd /tmp && runuser -u "$_u" -- "$@" ); else "$@"; fi; }
fi

# Təhlükəsizlik: yalnız lab_deploy. Dərs bitəndə silinir.
cleanup 'sudo userdel -r lab_deploy 2>/dev/null; sudo groupdel lab_deploy 2>/dev/null'

objective \
  "parol təyin etməyi (passwd, skriptdə chpasswd) və parolun /etc/shadow-da hash olduğunu görməyi" \
  "sudo -u və su - ilə başqa istifadəçi kimi əmr icra etməyi" \
  "'Permission denied' xətasını 'kim kimdir' sualı ilə izah etməyi" \
  "passwd -l ilə hesabı müvəqqəti kilidləməyi"

concept "Parol, su, sudo -u: kim kimi işləyir?" \
  "passwd user interaktivdir (parolu iki dəfə yazırsınız). Skriptdə və bu labda eyni işi chpasswd görür: 'ad:parol' stdin-dən oxunur." \
  "sudo -u user ƏMR = yalnız bir əmri o istifadəçi kimi icra edir (CI-da ən çox işlənən). su - user = onun login shell-inə keçir (tire home və mühiti də yükləyir)." \
  "Production-da şifrə ilə SSH girişi adətən söndürülür (/etc/ssh/sshd_config: PasswordAuthentication no); açar ilə giriş daha təhlükəsizdir. Bu faylı labda dəyişmirik."

step "Test hesabını yarat" \
  --why "Başqa istifadəçi kimi işləməyi sınamaq üçün onsuz keçmək olmur." \
  --cmd 'sudo useradd -m -s /bin/bash lab_deploy && id -un lab_deploy && getent passwd lab_deploy | cut -d: -f6' \
  --explain "useradd -m -s|home və bash ilə yeni hesab (Sessiya 15)" \
  --expect "lab_deploy və /home/lab_deploy" \
  --assert 'getent passwd lab_deploy | grep -q ":/home/lab_deploy:"' \
  --root

step "Parol təyin et (qeyri-interaktiv) və shadow-da gör" \
  --why "Parol heç vaxt açıq saxlanmır. İnteraktiv 'passwd' skriptdə işləmir, ona görə chpasswd istifadə olunur." \
  --cmd 'echo "lab_deploy:Lab#Pass123" | sudo chpasswd && sudo passwd -S lab_deploy | cut -d" " -f1,2 && sudo awk -F: '"'"'$1=="lab_deploy"{print "hash baslayir: " substr($2,1,1)}'"'"' /etc/shadow' \
  --show 'echo "lab_deploy:PAROL" | sudo chpasswd; sudo passwd -S lab_deploy' \
  --explain "chpasswd|stdin-dən 'ad:parol' oxuyub parolu təyin edir (passwd-nin skript versiyası)" \
  --explain "passwd -S|hesabın parol statusu: P = parol var, L = kilidli, NP = parolsuz" \
  --explain "/etc/shadow|hash-lənmiş parollar; yalnız root oxuya bilir" \
  --expect "'lab_deploy P' və hash-in ilk simvolu \$ (məs. \$y\$ yescrypt)" \
  --note "Real parolu shell tarixçəsinə yazmayın (history-də qalır). Real mühitdə açar, vault və ya 'passwd' interaktiv istifadə edin." \
  --assert 'sudo passwd -S lab_deploy | grep -q "^lab_deploy P"' \
  --root

step "Başqa istifadəçi kimi bir əmr: sudo -u" \
  --why "CI job-u deploy hesabı ilə işləməlidir ki, fayllar düzgün sahibə aid olsun." \
  --cmd 'whoami; sudo -u lab_deploy whoami; sudo -u lab_deploy id -gn' \
  --explain "sudo -u lab_deploy|əmri lab_deploy kimi icra et (parol soruşmur, çünki sudo icazəniz var)" \
  --explain "whoami|hər dəfə fərqli nəticə: əmri kim icra edir" \
  --expect "Sizin adınız, sonra lab_deploy, sonra lab_deploy (əsas qrup)" \
  --note "Əmrdən sonra shell qalmır: yalnız bir əmr başqa kimlik ilə işləyir, sonra kimliyiniz əvvəlki olur." \
  --assert '[ "$(sudo -u lab_deploy whoami)" = lab_deploy ]' \
  --root

step "Login shell: su -" \
  --why "Hesabın mühitini (home, PATH, .profile) olduğu kimi görmək üçün tam login lazımdır." \
  --cmd 'sudo su - lab_deploy -c "whoami; pwd; echo shell=\$0"' \
  --explain "su - user|tire (-) = login shell: home qovluğuna keçir, mühiti yükləyir" \
  --explain "-c \"...\"|shell-ə keçmədən əmri icra et (interaktiv shell lazım olmasın)" \
  --expect "lab_deploy, /home/lab_deploy və shell adı" \
  --note "Adi istifadəçi olaraq su - yazsanız hədəf hesabın parolu soruşulur (indi təyin etdiyimiz). sudo su - isə öz parolunuzla işləyir. Tire olmadan su user: köhnə qovluq və mühit qalır." \
  --assert 'sudo su - lab_deploy -c pwd | grep -qx /home/lab_deploy' \
  --root

step "Onun adından fayl yarat: sahib kimdir?" \
  --why "Deploy hesabı ilə yaranan fayl ona məxsusdur. Root ilə yaratsaydıq, sonra icazə problemi çıxardı." \
  --cmd 'sudo -u lab_deploy bash -c "cd /home/lab_deploy && echo release-1 > release.txt && stat -c \"%U %G %a %n\" release.txt"' \
  --explain "bash -c \"...\"|iki əmri bir icra kontekstində (eyni istifadəçi ilə) işlət" \
  --explain "stat -c|çıxış formatı: %U sahib, %G qrup, %a oktal icazə" \
  --expect "lab_deploy lab_deploy 644 release.txt" \
  --note "644 = sahib oxu+yaz, digərləri yalnız oxu. İcazələri növbəti dərslərdə ətraflı görəcəksiniz." \
  --assert 'sudo test "$(stat -c %U /home/lab_deploy/release.txt)" = lab_deploy' \
  --root

step "Adi hesab nəyi edə bilmir? (Permission denied)" \
  --why "Servis hesabı məhdud olmalıdır: sistem fayllarını oxuya bilməməlidir. Bu, xəta yox, qoruma mexanizmidir." \
  --cmd 'sudo -u lab_deploy cat /etc/shadow 2>&1; sudo -u lab_deploy touch /etc/lab_test 2>&1' \
  --explain "cat /etc/shadow|parol hash-ləri: yalnız root oxuya bilir" \
  --explain "touch /etc/...|/etc qovluğuna yalnız root yaza bilər" \
  --expect "İki 'Permission denied' xətası" \
  --note "Servis hack olunsa belə, hücumçu /etc/shadow-u oxuya bilməyəcək. Xətanı oxuyanda ilk sual: bu əmri kim icra edir və fayl kimə məxsusdur?" \
  --assert 'sudo -u lab_deploy cat /etc/shadow 2>&1 | grep -q "Permission denied"' \
  --allow-fail --root

step "Hesabı müvəqqəti kilidlə və aç: passwd -l / -u" \
  --why "Müvəqqəti developer girişi bitəndə hesabı silmədən parolla girişi dayandırmaq olar." \
  --cmd 'sudo passwd -l lab_deploy >/dev/null; sudo passwd -S lab_deploy | cut -d" " -f1,2; sudo passwd -u lab_deploy >/dev/null; sudo passwd -S lab_deploy | cut -d" " -f1,2' \
  --explain "passwd -l|lock: hash-in əvvəlinə ! qoyur, parol artıq uyğun gəlmir" \
  --explain "passwd -u|unlock: geri qaytarır" \
  --expect "lab_deploy L, sonra lab_deploy P" \
  --note "Kilid yalnız parolla girişi bağlayır. SSH açarı ilə giriş üçün hesabı ayrıca vurmaq (usermod -s /usr/sbin/nologin və ya expire) lazımdır." \
  --assert 'sudo passwd -S lab_deploy | grep -q "^lab_deploy P"' \
  --root

task "Əmri onun adından icra et" \
  "lab_deploy kimi 'whoami' əmrini icra edin və çıxışı iş qovluğundakı who.txt faylına yazın." \
  --check '[ "$(cat who.txt)" = lab_deploy ]' \
  --hint "Yönləndirmə > sizin shell-də olur, sudo -u yalnız əmrə aiddir: sudo -u lab_deploy whoami > who.txt" \
  --solution 'sudo -u lab_deploy whoami > who.txt'

task "Hesabı kilidlə" \
  "lab_deploy hesabını passwd ilə kilidləyin (passwd -S 'L' göstərməlidir)." \
  --check 'sudo passwd -S lab_deploy | grep -q "^lab_deploy L"' \
  --hint "passwd əmrinin -l (lock) seçimi, root icazəsi ilə." \
  --solution 'sudo passwd -l lab_deploy'

lab_summary "Sessiya 17 — ls əmri (ls -l, -a, -h, -R, -t, -d)" \
  "sudo -u user ƏMR — bir əmri başqa kimlik ilə; su - user — tam login" \
  "chpasswd skriptdə parol üçün; passwd -S/-l/-u statusu idarə edir" \
  "Parol hash kimi /etc/shadow-dadır, yalnız root oxuyur" \
  "Permission denied — qoruma mexanizmidir: əvvəl 'kim icra edir?' sualını ver"
