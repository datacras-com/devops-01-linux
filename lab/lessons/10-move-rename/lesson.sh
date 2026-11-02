# Sessiya 10 — Köçürmək və adını dəyişmək (mv)
lab_init 10 "mv: köçürmək və adını dəyişmək"

objective \
  "mv ilə faylı başqa qovluğa köçürməyi" \
  "mv ilə fayl və qovluğun adını dəyişməyi" \
  "cp və mv fərqini nəticəyə baxaraq izah etməyi" \
  "release-lər üçün ad dəyişmə (rollover) nümunəsini qurmağı"

concept "mv = cut & paste, rename də eyni əmr" \
  "Linux-da ayrıca rename əmri yoxdur: mv köhnə yeni. Eyni qovluqda mv = rename, başqa qovluğa mv = köçürmə." \
  "cp-dən fərqli olaraq orijinal yerində qalmır və qovluq üçün -r lazım deyil."

step "Hazırlıq və faylı qovluğa köçürmək" \
  --why "Köhnə log-u arxiv qovluğuna atmaq tipik əməliyyatdır." \
  --cmd 'mkdir -p archive; echo "log line" > app.log; mv app.log archive/; ls; echo "---"; ls archive' \
  --explain "mv app.log archive/|app.log-u archive qovluğuna köçür" \
  --expect "Cari qovluqda app.log yoxdur, archive içindədir" \
  --note "Orijinal yerdən yox oldu: cut & paste." \
  --assert '! test -e app.log && test -f archive/app.log'

step "cp ilə fərq" \
  --why "Hansını işlətdiyinizi bilməsəniz, ya fayl itirər, ya da dublikat yaradarsınız." \
  --cmd 'echo v1 > deploy.sh; cp deploy.sh archive/deploy.copy; ls; echo "--- mv ---"; mv deploy.sh archive/deploy.moved; ls' \
  --explain "cp|orijinal qalır (iki fayl)" \
  --explain "mv|orijinal yox olur (bir fayl)" \
  --predict "İkinci ls-də deploy.sh görünəcəkmi?" \
  --expect "Birinci ls-də deploy.sh var, ikincidə yoxdur" \
  --assert '! test -e deploy.sh && test -f archive/deploy.copy && test -f archive/deploy.moved'

step "Faylın adını dəyişmək" \
  --why "Config-i deaktiv etmək üçün adını dəyişmək (site.conf → site.conf.disabled) geniş yayılıb." \
  --cmd 'echo "server {}" > site.conf; mv site.conf site.conf.disabled; ls' \
  --explain "mv site.conf site.conf.disabled|eyni qovluqda destination fayl adıdır → rename" \
  --expect "Yalnız site.conf.disabled" \
  --note "Məzmun dəyişmir, yalnız ad." \
  --assert 'test -f site.conf.disabled && ! test -e site.conf'

step "Qovluğun adını dəyişmək" \
  --why "Release qovluqlarını (app → app.old) çevirmək deploy-un rollback hissəsidir." \
  --cmd 'mkdir app; echo v1 > app/version; mv app app.old; ls -d app*; cat app.old/version' \
  --explain "mv app app.old|qovluq da fayl kimi, -r lazım deyil" \
  --expect "app.old və içindəki version faylı (v1)" \
  --assert 'test -f app.old/version'

step "Köçür və eyni zamanda adını dəyiş" \
  --why "Bir əmrlə həm yer, həm ad dəyişir: köhnə release-i tarixli arxivə qoymaq." \
  --cmd 'mv app.old archive/app-release-1; ls archive' \
  --explain "mv src dir/yeniad|destination qovluq/yeniad olduqda hər ikisi baş verir" \
  --expect "archive içində app-release-1 görünür" \
  --assert 'test -f archive/app-release-1/version'

step "Üzərinə yazma təhlükəsi: -i və -n" \
  --why "mv də cp kimi mövcud faylın üzərinə səssiz yazır, köhnə məzmun geri qayıtmır." \
  --cmd 'echo important > keep.txt; echo other > new.txt; mv -n new.txt keep.txt; cat keep.txt; ls new.txt' \
  --explain "mv -n|no-clobber: mövcud faylın üzərinə yazma" \
  --explain "mv -i|üzərinə yazmazdan əvvəl soruşur" \
  --expect "keep.txt hələ 'important', new.txt də yerindədir" \
  --note "-n skriptlərdə -i-dən yaxşıdır: sual vermir, sadəcə keçir." \
  --assert 'grep -q important keep.txt && test -f new.txt'

task "Log-u arxivlə" \
  "error.log yaradın və onu logs-old qovluğuna köçürün (qovluğu özünüz yaradın). Cari qovluqda error.log qalmasın." \
  --check 'test -f logs-old/error.log && ! test -e error.log' \
  --hint "mkdir logs-old; mv error.log logs-old/" \
  --solution 'echo err > error.log; mkdir -p logs-old; mv error.log logs-old/'

task "Config adını dəyiş" \
  "app.conf yaradın və adını app.conf.v1 edin." \
  --check 'test -f app.conf.v1 && ! test -e app.conf' \
  --hint "mv köhnə yeni" \
  --solution 'echo x > app.conf; mv app.conf app.conf.v1'

task "Köçür və adlandır" \
  "build.sh yaradın və bir əmrlə releases/build-2.sh adı ilə köçürün (releases qovluğunu özünüz yaradın)." \
  --check 'test -f releases/build-2.sh && ! test -e build.sh' \
  --hint "Destination: qovluq/yeni_ad" \
  --solution 'echo x > build.sh; mkdir -p releases; mv build.sh releases/build-2.sh'

lab_summary "Sessiya 11 — Qovluq dəyişmək (cd, pwd)" \
  "mv src dir/ — köçürür; mv köhnə yeni — adı dəyişir" \
  "cp orijinalı saxlayır, mv saxlamır" \
  "mv səssiz üzərinə yazır: -n / -i işlət"
