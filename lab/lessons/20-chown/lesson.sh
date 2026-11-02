# Sessiya 20 — chown, chgrp, -R, file: root-un yaratdığı fayl servis hesabına
lab_init 20 "chown və chgrp: fayl sahibliyi"
# konteynerdəki sudo shim "-u" bilmir: runuser ilə əvəz edirik (real sudo-ya toxunmur)
if [ "$(type -t sudo)" = function ]; then
  sudo() { if [ "$1" = -u ]; then local _u=$2; shift 2; ( cd /tmp && runuser -u "$_u" -- "$@" ); else "$@"; fi; }
fi

# Təhlükəsizlik: yalnız lab_ hesabları və /tmp/lab_chown. Dərs bitəndə silinir.
cleanup 'sudo rm -rf /tmp/lab_chown'
cleanup 'sudo userdel lab_www 2>/dev/null; sudo userdel lab_deploy 2>/dev/null'
cleanup 'sudo groupdel lab_ops 2>/dev/null'

objective \
  "root ilə yaranan faylı niyə servis hesabının oxuya bilmədiyini izah etməyi" \
  "chown user:group, chown user, chown :group və chgrp ilə sahibliyi dəyişməyi" \
  "chown -R ilə bütün ağacı bir əmrlə düzəltməyi" \
  "chown-dan sonra sahibin niyə chmod edə bildiyini izah etməyi"

concept "chown: yalnız root, chmod: sahib və root" \
  "CI pipeline və ya admin root kimi fayl yükləyir, nginx (www-data) isə adi hesabdır: fayl root-a məxsus və 640-dırsa nginx onu oxuya bilməz. Klassik həll: chown www-data:www-data." \
  "Qayda: chown-u YALNIZ root edə bilər (sahib belə faylı başqasına verə bilməz). chmod-u isə sahib və root edə bilər. Ona görə sahiblik dəyişəndən sonra yeni sahib chmod edə bilir."

step "Hazırlıq: hesablar və root-un yaratdığı fayllar" \
  --why "Real vəziyyəti qururuq: deploy root ilə işləyib, fayllar root-a qalıb; nginx rolunda lab_www var." \
  --cmd 'sudo groupadd lab_ops && sudo useradd -M -s /usr/sbin/nologin lab_deploy && sudo useradd -M -s /usr/sbin/nologin lab_www && sudo install -d -m 755 /tmp/lab_chown/site/css /tmp/lab_chown/data/logs && printf "<h1>release-1</h1>\n" | sudo tee /tmp/lab_chown/index.html /tmp/lab_chown/site/index.html /tmp/lab_chown/site/css/main.css >/dev/null && printf "port: 8080\n" | sudo tee /tmp/lab_chown/app.conf >/dev/null && sudo chmod 640 /tmp/lab_chown/index.html /tmp/lab_chown/app.conf /tmp/lab_chown/site/index.html /tmp/lab_chown/site/css/main.css && stat -c "%U:%G %a %n" /tmp/lab_chown/index.html /tmp/lab_chown/app.conf' \
  --explain "install -d|qovluq ağacını yaradır" \
  --explain "tee|sudo ilə fayla yazmaq üçün (sudo echo > fayl işləməz, yönləndirməni sizin shell edir)" \
  --explain "chmod 640|sahib rw, qrup r, digərləri heç nə" \
  --expect "root:root 640 index.html və app.conf" \
  --assert '[ "$(stat -c %U:%G /tmp/lab_chown/index.html)" = root:root ]' \
  --root

step "Problem: servis root-un faylını oxuya bilmir" \
  --why "'Deploy etdim, amma sayt 403/500 verir': ən çox rast gəlinən səbəb." \
  --cmd 'sudo -u lab_www cat /tmp/lab_chown/index.html 2>&1' \
  --explain "lab_www|nginx kimi adi servis hesabı" \
  --explain "root:root 640|lab_www nə sahibdir, nə qrup üzvüdür → others bloku (---)" \
  --expect "cat: ... Permission denied" \
  --note "Burada chmod 644 də işi görərdi, amma o zaman fayl hamıya açılır. Doğru həll: sahibi servis hesabı etmək." \
  --assert 'sudo -u lab_www cat /tmp/lab_chown/index.html 2>&1 | grep -q "Permission denied"' \
  --allow-fail --root

step "Adi hesab chown edə bilməz" \
  --why "Sahiblik dəyişmək imtiyazlı əməliyyatdır. Bunu bilmək xətanı tez tanımağa kömək edir." \
  --cmd 'sudo -u lab_deploy chown lab_deploy /tmp/lab_chown/app.conf 2>&1; sudo -u lab_deploy chmod 666 /tmp/lab_chown/app.conf 2>&1' \
  --explain "chown ...|adi hesab üçün 'Operation not permitted'" \
  --explain "chmod ...|lab_deploy sahib deyil, ona görə o da rədd edilir" \
  --expect "İki 'Operation not permitted' xətası" \
  --note "Sahib olmayan chmod edə bilmir. Çıxış yolu: root sahibliyi dəyişir, sonra yeni sahib özü chmod edir." \
  --assert 'sudo -u lab_deploy chown lab_deploy /tmp/lab_chown/app.conf 2>&1 | grep -q "Operation not permitted"' \
  --allow-fail --root

step "root chown edir: user:group" \
  --why "nginx-in fayllarını nginx hesabına vermək deploy-dan sonrakı standart addımdır." \
  --cmd 'sudo chown lab_www:lab_www /tmp/lab_chown/index.html && stat -c "%U:%G %a %n" /tmp/lab_chown/index.html && sudo -u lab_www cat /tmp/lab_chown/index.html' \
  --explain "chown lab_www:lab_www|sahib və qrup eyni anda dəyişir" \
  --explain "format|user:group  (nöqtə də işləyir, amma iki nöqtə standartdır)" \
  --expect "lab_www:lab_www 640 və <h1>release-1</h1>" \
  --note "İndi lab_www sahibdir və 640-ın owner bloku (rw-) tətbiq olunur. Faylın icazə rəqəmi dəyişmədi, yalnız kimin sahibi olduğu dəyişdi." \
  --assert '[ "$(stat -c %U:%G /tmp/lab_chown/index.html)" = lab_www:lab_www ] && sudo -u lab_www cat /tmp/lab_chown/index.html | grep -q release-1' \
  --root

step "Yalnız user, yalnız group: chown user, chown :group, chgrp" \
  --why "Bəzən yalnız qrupu dəyişmək lazımdır (məs. ops komandası logları oxusun)." \
  --cmd 'sudo chown lab_deploy /tmp/lab_chown/app.conf; stat -c "chown user    -> %U:%G" /tmp/lab_chown/app.conf; sudo chown :lab_ops /tmp/lab_chown/app.conf; stat -c "chown :group -> %U:%G" /tmp/lab_chown/app.conf; sudo chgrp root /tmp/lab_chown/app.conf; stat -c "chgrp root   -> %U:%G" /tmp/lab_chown/app.conf; sudo chgrp lab_ops /tmp/lab_chown/app.conf' \
  --explain "chown lab_deploy f|yalnız sahib, qrup toxunulmaz (root qalır)" \
  --explain "chown :lab_ops f|yalnız qrup, sahib toxunulmaz" \
  --explain "chgrp lab_ops f|chown :lab_ops ilə eyni" \
  --expect "lab_deploy:root, lab_deploy:lab_ops, lab_deploy:root, sonda lab_deploy:lab_ops" \
  --predict "'chown lab_deploy file' qrupu da dəyişərmi?" \
  --note "Yalnız ad yazanda qrup qalır (lab_deploy:root). Mövcud olmayan qrup yazsanız 'invalid group' xətası alarsınız." \
  --assert '[ "$(stat -c %U:%G /tmp/lab_chown/app.conf)" = lab_deploy:lab_ops ]' \
  --root

step "chown -R: bütün ağac" \
  --why "Yüzlərlə fayl olan sayt qovluğunu fayl-fayl dəyişmək mümkün deyil." \
  --cmd 'sudo chown -R lab_www:lab_www /tmp/lab_chown/site && find /tmp/lab_chown/site -printf "%u:%g %p\n" | sort' \
  --explain "-R|rekursiv: qovluğun özü və bütün alt fayl/qovluqlar" \
  --explain "find -printf|hər yol üçün sahib:qrup və yol" \
  --expect "3 sətir, hamısı lab_www:lab_www" \
  --note "-R ilə ehtiyatlı olun: chown -R root /  və ya yanlış yol sistemi sındıra bilər. Əmri yazmazdan əvvəl yolu yoxlayın." \
  --assert '[ "$(find /tmp/lab_chown/site ! -user lab_www | wc -l)" = 0 ]' \
  --root

step "chown-dan sonra sahib chmod edə bilir" \
  --why "chown + chmod cütü: əvvəl kimin olduğunu, sonra nə edə biləcəyini təyin edirsiniz." \
  --cmd 'sudo -u lab_deploy chmod 660 /tmp/lab_chown/app.conf && stat -c "%U:%G %a %n" /tmp/lab_chown/app.conf' \
  --explain "lab_deploy|artıq sahibdir (əvvəlki addım) → chmod icazəlidir" \
  --expect "lab_deploy:lab_ops 660 app.conf" \
  --note "Addım 3-də eyni chmod rədd olunmuşdu, çünki lab_deploy sahib deyildi. Bu fərq bütün dərsin əsasıdır: chown root, chmod sahib." \
  --assert '[ "$(stat -c %a /tmp/lab_chown/app.conf)" = 660 ]' \
  --root

prep 'command -v file >/dev/null || { sudo apt-get update -qq && sudo apt-get install -y -qq file; }'

step "Fayl tipi: file əmri" \
  --why "ls -l ilk simvol göstərir, file isə məzmunu analiz edib nə olduğunu söyləyir." \
  --cmd 'for f in /tmp/lab_chown/index.html /tmp/lab_chown /dev/null; do echo "$f: $(file -b $f | cut -d, -f1)"; done' \
  --explain "file|fayl tipini məzmuna görə təyin edir (uzantıya yox)" \
  --expect "ASCII text, directory, character special" \
  --note "Uzantısı olmayan və ya yanlış adlı fayllarda file həqiqəti göstərir. Fayl yoxlanışları üçün də faydalıdır." \
  --assert 'file /tmp/lab_chown | grep -q directory && file /dev/null | grep -q "character special"' \
  --root

inject "Deploy skripti ağacı root-a çevirdi" \
  "Deploy skripti sudo ilə chown -R root:root /tmp/lab_chown/site işlətdi. lab_www saytı oxuya bilmir." \
  --cmd 'sudo chown -R root:root /tmp/lab_chown/site' \
  --symptom 'sudo -u lab_www cat /tmp/lab_chown/site/index.html 2>&1; find /tmp/lab_chown/site -printf "%u:%g %p\n" | sort' \
  --fix 'sudo chown -R lab_www:lab_www /tmp/lab_chown/site' \
  --check 'sudo -u lab_www cat /tmp/lab_chown/site/index.html | grep -q release && [ "$(find /tmp/lab_chown/site ! -user lab_www | wc -l)" = 0 ]' \
  --hint "find çıxışı hər fayl üçün sahibi göstərir. Hamısını yenidən lab_www:lab_www etmək üçün rekursiv chown lazımdır."

task "Sahibi və qrupu təyin et" \
  "İş qovluğunda config.yaml faylı yaradın və sahibini lab_deploy, qrupunu lab_ops edin." \
  --check '[ "$(stat -c %U:%G config.yaml)" = lab_deploy:lab_ops ]' \
  --hint "touch config.yaml, sonra sudo chown lab_deploy:lab_ops config.yaml" \
  --solution 'touch config.yaml; sudo chown lab_deploy:lab_ops config.yaml'

task "Yalnız qrupu dəyiş" \
  "İş qovluğunda release.tar faylı yaradın və YALNIZ qrupunu lab_ops edin (sahib dəyişməsin: hələ də sizsiniz)." \
  --check '[ "$(stat -c %G release.tar)" = lab_ops ] && [ "$(stat -c %U release.tar)" = "$(id -un)" ]' \
  --hint "chgrp lab_ops release.tar  və ya  chown :lab_ops release.tar (root icazəsi ilə)." \
  --solution 'touch release.tar; sudo chgrp lab_ops release.tar'

task "Qovluğu rekursiv ver" \
  "Hazır /tmp/lab_chown/data qovluğunu (içindəki logs ilə birlikdə) lab_www:lab_www edin." \
  --check '[ "$(find /tmp/lab_chown/data ! -user lab_www | wc -l)" = 0 ] && [ "$(find /tmp/lab_chown/data ! -group lab_www | wc -l)" = 0 ]' \
  --hint "-R seçimini unutmayın: sudo chown -R user:group yol" \
  --solution 'sudo chown -R lab_www:lab_www /tmp/lab_chown/data'

lab_summary "Sessiya 21 — Sistem məlumatı (Chapter 5: System Management)" \
  "chown user:group (hər ikisi), chown user, chown :group, chgrp group" \
  "chown yalnız root; chmod sahib və root. chown-dan sonra yeni sahib chmod edə bilir" \
  "chown -R ağac üçün: yolu iki dəfə yoxla" \
  "root-un yaratdığı fayl servis hesabına oxunmursa: stat → chown → yoxla"
