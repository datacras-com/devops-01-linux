# Sessiya 14 — Faylda söz əvəzləmək (sed)
lab_init 14 "sed: konfiqdə dəyəri təhlükəsiz dəyişmək"

objective \
  "sed 's/köhnə/yeni/' ilə çıxışı dəyişdirib faylı toxunmadan yoxlamağı" \
  "g flag-ı və ünvanlarla (sətir nömrəsi) hədəfi dəqiqləşdirməyi" \
  "sed -i -dən əvvəl backup götürməyi (-i.bak)" \
  "səhv sed -i-dan sonra konfiqi backup-dan bərpa etməyi"

concept "sed -i: sürətli, amma geri qaytarmasız" \
  "sed default olaraq faylı dəyişmir, yalnız nəticəni çap edir. -i ilə fayl yerindəcə dəyişir və geri yol yoxdur." \
  "Qayda: 1) sed ilə nəticəyə bax, 2) cp ilə backup (və ya -i.bak), 3) yalnız sonra -i."

step "Hazırlıq: nginx.conf nümunəsi" \
  --why "Realistik konfiq lazımdır: port bir neçə yerdə var." \
  --cmd 'printf "server {\n  listen 8080;\n  server_name dev.example.net;\n  location / { proxy_pass http://127.0.0.1:8080; }\n}\n# port 8080 is default\n" > nginx.conf; cat -n nginx.conf' \
  --explain "cat -n|sətir nömrələri ilə göstərir" \
  --expect "6 sətir, 8080 üç yerdə" \
  --assert '[ "$(grep -c 8080 nginx.conf)" = 3 ]'

step "s/köhnə/yeni/ — fayla toxunmadan" \
  --why "Nəticəni əvvəl görmək təhlükəsizdir: fayl dəyişmir." \
  --cmd 'sed "s/8080/9090/" nginx.conf; echo "--- fayl hələ dəyişməyib ---"; grep -c 8080 nginx.conf' \
  --explain "s|substitute (əvəzlə)" \
  --explain "/8080/9090/|köhnə / yeni, / ayırıcıdır" \
  --expect "Çıxışda 9090, sonda grep -c hələ 3" \
  --note "Orijinal toxunulmazdır: sed yalnız çap etdi." \
  --assert '[ "$(grep -c 8080 nginx.conf)" = 3 ]'

step "g flag-ı: hər sətirdə hamısı" \
  --why "Bir sətirdə eyni dəyər iki dəfə ola bilər; g olmasa yalnız birincisi dəyişir." \
  --cmd 'echo "8080 and 8080" > t.txt; sed "s/8080/9090/" t.txt; sed "s/8080/9090/g" t.txt' \
  --explain "s/.../.../|hər sətirdə yalnız birinci" \
  --explain "s/.../.../g|global: sətirdəki bütün tapılanlar" \
  --expect "9090 and 8080, sonra 9090 and 9090" \
  --assert '[ "$(sed "s/8080/9090/g" t.txt)" = "9090 and 9090" ]'

step "Ünvanlar: yalnız seçilmiş sətir" \
  --why "Şərhdəki '8080'-ə toxunmadan yalnız listen sətrini dəyişmək lazımdır." \
  --cmd 'sed "2s/8080/9090/" nginx.conf; echo "--- pattern ünvanı ---"; sed "/listen/s/8080/9090/" nginx.conf | grep listen; echo "--- sətirləri göstər ---"; sed -n "2,3p" nginx.conf' \
  --explain "2s/.../|yalnız 2-ci sətirdə" \
  --explain "/listen/s/...|yalnız 'listen' olan sətirlərdə" \
  --explain "-n \"2,3p\"|yalnız 2-3-cü sətirləri çap et" \
  --expect "Yalnız hədəf sətir dəyişir; sed -n 2 sətir göstərir" \
  --assert '[ "$(sed -n "2,3p" nginx.conf | wc -l)" = 2 ]'

step "Təhlükəsiz -i: əvvəl backup" \
  --why "-i geri qaytarılmaz; cp ilə backup bir saniyədir." \
  --cmd 'cp nginx.conf nginx.conf.bak; sed -i "/listen/s/8080/9090/" nginx.conf; diff nginx.conf.bak nginx.conf; grep -c 9090 nginx.conf' \
  --explain "cp ... .bak|dəyişməzdən əvvəl backup" \
  --explain "sed -i|faylı yerindəcə dəyişir" \
  --explain "diff bak yeni|dəyişikliyin dəqiq yoxlanışı" \
  --expect "diff yalnız listen sətrini göstərir, sonda 1" \
  --assert 'grep -q "listen 9090" nginx.conf && grep -q "listen 8080" nginx.conf.bak'

step "-i.bak: sed öz backup-ını yaradır" \
  --why "Ayrıca cp unutmaq mümkündür; -i.bak bunu avtomatik edir." \
  --cmd 'sed -i.bak "s#proxy_pass http://127.0.0.1:8080#proxy_pass http://127.0.0.1:9090#" nginx.conf; ls nginx.conf*; grep proxy_pass nginx.conf' \
  --explain "-i.bak|dəyişmədən əvvəl nginx.conf.bak yaradır" \
  --explain "s#...#...#|yolda / olanda başqa ayırıcı (#, |)" \
  --expect "nginx.conf və nginx.conf.bak, proxy_pass indi 9090" \
  --note "Diqqət: -i.bak əvvəlki nginx.conf.bak-ın üzərinə yazdı (artıq yeni backup köhnə dəyişikliyi daşıyır). Real işdə tarixli ad istifadə edin." \
  --assert 'grep -q "127.0.0.1:9090" nginx.conf'

inject "Səhv sed -i konfiqi korlayıb" \
  "Kimsə tələsib sed -i işlədib və konfiqdəki bütün dəyərləri silib. Hazırlıq: təmiz backup nginx.conf.good-dan bərpa edin." \
  --cmd 'cp nginx.conf nginx.conf.good; sed -i "s/9090.*//" nginx.conf' \
  --symptom 'cat nginx.conf' \
  --fix 'cp nginx.conf.good nginx.conf' \
  --check 'grep -q "listen 9090;" nginx.conf && grep -q server_name nginx.conf' \
  --hint "nginx.conf.good faylı backup-dır: cp ilə geri qoyun"

task "Port dəyişimi" \
  "app.env yaradın (PORT=8080 və HOST=localhost). Əvvəl app.env.bak backup-ı götürün, sonra sed -i ilə PORT-u 9090 edin." \
  --check 'grep -q "PORT=9090" app.env && grep -q "PORT=8080" app.env.bak && grep -q localhost app.env' \
  --hint "cp app.env app.env.bak; sed -i \"s/PORT=8080/PORT=9090/\" app.env" \
  --solution 'printf "PORT=8080\nHOST=localhost\n" > app.env; cp app.env app.env.bak; sed -i "s/PORT=8080/PORT=9090/" app.env'

task "Hamısını əvəzlə" \
  "hosts.txt-də 'dev' sözü hər sətirdə iki dəfə keçir. Bütün 'dev'-ləri 'prod' edin (fayl dəyişsin)." \
  --check '[ "$(grep -o prod hosts.txt | wc -l)" = 4 ] && ! grep -q dev hosts.txt' \
  --hint "g flag-ı və -i" \
  --solution 'printf "dev dev\ndev dev\n" > hosts.txt; sed -i "s/dev/prod/g" hosts.txt'

task "Sətir aralığını çıxar" \
  "big.txt-in 1..5 sətirlərindən (printf ile yaradın) 2-4-cü sətirləri göstərib mid.txt-ə yazın." \
  --check '[ "$(wc -l < mid.txt)" = 3 ] && grep -q "^2$" mid.txt && grep -q "^4$" mid.txt' \
  --hint "sed -n \"2,4p\" big.txt > mid.txt" \
  --solution 'printf "1\n2\n3\n4\n5\n" > big.txt; sed -n "2,4p" big.txt > mid.txt'

lab_summary "Sessiya 15 — İstifadəçi idarəetməsi" \
  "sed 's/köhnə/yeni/g' — çıxışı dəyişir, fayla toxunmur" \
  "ünvan (2s/, /pattern/s/) — dəqiq hədəf" \
  "sed -i yalnız backup-dan sonra; -i.bak avtomatikdir" \
  "korlanan konfiq backup-dan cp ilə bərpa olunur"
