# Sessiya 03 — Əsas Linux əmrləri (uptime, date, whoami, id, who, man)
lab_init 03 "Əsas Linux əmrləri: serveri ilk tanıyaq"

objective \
  "serverə qoşulanda ilk 60 saniyədə sistemin vəziyyətini oxumağı" \
  "uptime çıxışındakı 'load average'-i yorumlamağı" \
  "kimliyinizi (whoami, id) və qrup üzvlüyünüzü yoxlamağı" \
  "man ilə naməlum əmrin sənədini tapmağı"

concept "DevOps-da niyə 'əsas əmrlər'?" \
  "Production serverə SSH ilə girəndə ilk sual: 'Sistem sağlamdırmı, mən kiməm, nə qədər vaxtdır işləyir?'" \
  "Bu dərsin əmrləri incident zamanı ilk 60 saniyənin alətləridir."

step "Sistemin vaxtı və saat qurşağı" \
  --why "Cron job-lar, log-lar və sertifikat müddətləri vaxta bağlıdır. Cloud serverlər adətən UTC-dədir." \
  --cmd 'date; date "+%Y-%m-%d %H:%M:%S"; date +%Z' \
  --explain "date|cari tarix və vaxt" \
  --explain '"+%Y-%m-%d ..."|çıxışı formatlamaq (% ilə başlayan kodlar)' \
  --explain "+%Z|saat qurşağının adı (UTC, +04 və s.)" \
  --expect "Üç çıxış: tam tarix, formatlı tarix, saat qurşağı (məs. UTC)" \
  --predict "Sizcə log fayllarında vaxtı müqayisə edəndə niyə saat qurşağı vacibdir?" \
  --note "Server UTC-də, siz +04-də olsanız, log-dakı 10:00 sizin üçün 14:00-dır. Bu, incident araşdırmasında tez-tez səhvə səbəb olur." \
  --assert 'date +%Y | grep -Eq "^20[0-9]{2}$"'

step "Server nə qədərdir işləyir? (uptime)" \
  --why "Server gecə reboot olubmu? Deploy-dan sonra yenidən başlayıb? uptime bunu 1 saniyəyə deyir." \
  --cmd 'uptime' \
  --explain "up ...|sistem açılandan bəri keçən vaxt" \
  --explain "N user|hazırda neçə sessiya açıqdır" \
  --explain "load average|son 1, 5 və 15 dəqiqənin orta yükü" \
  --expect "Bir sətir: vaxt, up müddəti, user sayı, load average" \
  --predict "load average 4.00 olan 2 nüvəli server sağlamdır?" \
  --note "Qayda: load average nüvə sayından yüksəkdirsə, proseslər növbə gözləyir (2 nüvə + load 4 = sistem 2x yüklənib). Nüvə sayını növbəti addımda görəcəyik." \
  --assert 'uptime | grep -q "load average"'

step "Neçə CPU nüvəsi var? (load ilə müqayisə üçün)" \
  --why "Load average-i yalnız nüvə sayı ilə müqayisədə anlamaq olar." \
  --cmd 'nproc; echo "Load: $(cut -d" " -f1-3 /proc/loadavg)"' \
  --explain "nproc|mövcud CPU nüvələrinin sayı" \
  --explain "/proc/loadavg|nüvənin özünün yük göstəricisi (uptime də buradan oxuyur)" \
  --expect "Bir rəqəm (nüvə sayı) və 3 load dəyəri" \
  --note "Linux-da 'hər şey fayldır': /proc virtual qovluğu kernel məlumatını fayl kimi göstərir. Bunu Sessiya 21-də dərindən görəcəyik." \
  --assert '[ "$(nproc)" -ge 1 ]'

step "Mən kiməm? (whoami, id)" \
  --why "Servis hesabı ilə işləyirsiniz, yoxsa root? Fayl icazəsi xətalarının yarısı burada həll olunur." \
  --cmd 'whoami; id' \
  --explain "whoami|aktiv istifadəçi adı" \
  --explain "uid|istifadəçinin rəqəm ID-si (root=0)" \
  --explain "gid|əsas qrup ID-si" \
  --explain "groups|mənsub olduğunuz bütün qruplar (sudo, docker və s.)" \
  --expect "İstifadəçi adı və uid=...(ad) gid=... groups=..." \
  --predict "Sizcə docker əmrini sudo-suz işlətmək üçün id çıxışında hansı qrup görünməlidir?" \
  --note "Cavab: docker qrupu. Bunu Session 15-də usermod -aG ilə edəcəksiniz." \
  --assert '[ "$(whoami)" = "$(id -un)" ]'

step "Sistemdə kim işləyir? (who, w)" \
  --why "Başqa kimsə eyni serverdə işləyirsə, restart etməzdən əvvəl bilmək lazımdır." \
  --cmd 'who || true; echo "---"; w || true' \
  --explain "who|aktiv sessiyalar (kim, hansı terminaldan, nə vaxt)" \
  --explain "w|who + hər sessiyanın indi nə işlətdiyi və idle vaxtı" \
  --expect "Konteynerdə/təmiz serverdə siyahı boş ola bilər. Real VM-də sizin SSH sessiyanız görünəcək." \
  --note "Boş çıxış xəta deyil: sadəcə heç kim daxil olmayıb. w-nin ilk sətri uptime ilə eynidir." \
  --allow-fail

step "Əmrin sənədi: man və --help" \
  --why "Hər flag-ı əzbərləmək mümkün deyil. Peşəkarlar sənəddən oxuyur." \
  --cmd 'date --help | head -n 5; echo "..."; (man date 2>/dev/null | col -bx | head -n 12) || echo "(man bu mühitdə quraşdırılmayıb — Ubuntu VM-də var)"' \
  --explain "--help|əmrin qısa istifadə qaydası (hər əmrdə yoxdur, çoxunda var)" \
  --explain "man ƏMR|tam sənəd; q ilə çıxılır, / ilə axtarılır" \
  --expect "date əmrinin istifadə sintaksisi" \
  --note "Əmrin hansı bölməyə aid olduğunu bilmək üçün man -k açarsöz (apropos) istifadə edin. Naməlum alətdə ilk addım həmişə --help və man olmalıdır."

task "Serverin 'ilk 60 saniyə' hesabatı" \
  "report.txt faylı yaradın. İçində 3 sətir olsun: istifadəçi adınız (whoami), nüvə sayı (nproc) və uptime çıxışı." \
  --check 'test -s report.txt && [ "$(wc -l < report.txt)" -ge 3 ] && grep -q "$(whoami)" report.txt && grep -q "load average" report.txt' \
  --hint "Üç əmri ardıcıl yazın və hər birinin çıxışını >> ilə report.txt-ə əlavə edin. (İlk əmrdə > işlədə bilərsiniz.)" \
  --solution 'whoami > report.txt; nproc >> report.txt; uptime >> report.txt'

task "Naməlum əmri öyrən" \
  "'wc' əmrini yeni görürsünüz. wc --help çıxışından istifadə edərək 'report.txt' faylındakı sətir sayını tapıb sayi.txt faylına yazın (yalnız rəqəm)." \
  --check 'test -s sayi.txt && test -s report.txt && [ "$(tr -d "[:space:]" < sayi.txt)" = "$(wc -l < report.txt | tr -d "[:space:]")" ]' \
  --hint "wc -l sətirləri sayır. Faylın adı çıxışda görünməsin deyə: wc -l < report.txt" \
  --solution 'wc -l < report.txt > sayi.txt'

lab_summary "Sessiya 04 — Fayl oxuma (cat, less, head, tail)" \
  "date/uptime/nproc — serverin vaxtı və yükü" \
  "whoami/id/who/w — kim və kim işləyir" \
  "man və --help — naməlum əmrin ilk mənbəyi" \
  "load average-i həmişə nüvə sayı ilə müqayisə et"
