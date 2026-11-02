# Sessiya 04 — Fayl oxuma (ls, pwd, cat, less, more, head, tail)
lab_init 04 "Fayl oxuma: log və konfiqurasiya faylları"

prep 'mkdir -p logs; for i in $(seq 1 30); do c=200; [ $((i%7)) -eq 0 ] && c=500; [ $((i%10)) -eq 0 ] && c=404; echo "10.0.0.$i - - \"GET /api/item/$i HTTP/1.1\" $c"; done > logs/access.log; printf "APP_ENV=staging\nDB_HOST=10.40.0.5\nDB_PORT=5432\n" > app.env'

objective \
  "kiçik konfiqurasiya faylını cat ilə, böyük log faylını head/tail ilə oxumağı" \
  "wc -l ilə faylın sətir sayını tapmağı" \
  "cat ... | grep ilə log-dan yalnız lazım olan sətirləri süzməyi" \
  "tail -f ilə canlı log izləməyin necə işlədiyini görməyi"

concept "Hansı əmr nə vaxt? (cat, less, more, head, tail)" \
  "cat — kiçik fayl (nginx.conf, .env): hamısını bir anda ekrana verir." \
  "less / more — böyük fayl: səhifə-səhifə. less-də Space=irəli, b=geri, /söz=axtarış, q=çıx. more-da geri yoxdur, faiz göstərir." \
  "less və more İNTERAKTİVDİR (q ilə çıxırsınız), buna görə addımlarda işlətmirik — siz öz terminalınızda /etc/passwd ilə sınayın." \
  "head/tail — faylın başı və sonu. tail -f — deploy zamanı logu canlı izləmək (Ctrl+C ilə çıx)."

step "Haradayıq və nə var? (pwd, ls)" \
  --why "Faylı oxumazdan əvvəl onun harada olduğunu bilməlisiniz. Səhv qovluq = səhv fayl." \
  --cmd 'pwd; ls; ls -la' \
  --explain "pwd|cari iş qovluğu (Present Working Directory)" \
  --explain "ls|qovluqdakı fayl və qovluqlar" \
  --explain "-la|uzun format (-l) və gizli fayllar (-a, nöqtə ilə başlayanlar)" \
  --expect "app.env faylı və logs qovluğu" \
  --note "Sizin iş qovluğunuz hər dərs başlayanda sıfırlanır — burada nə etsəniz də real sistemə toxunmur." \
  --assert 'test -f app.env && test -d logs'

step "Kiçik konfiqurasiya faylını oxu (cat)" \
  --why "Deploy-dan əvvəl .env və ya nginx.conf-u tez yoxlamaq lazımdır. Kiçik fayl üçün cat kifayətdir." \
  --cmd 'cat app.env; echo "---"; cat -n app.env' \
  --explain "cat fayl|bütün məzmunu ekrana verir" \
  --explain "-n|hər sətrin əvvəlinə nömrə yazır (xəta mesajında sətir nömrəsi olanda faydalıdır)" \
  --expect "3 sətir, sonra eyni 3 sətir nömrələrlə" \
  --predict "10 000 sətirlik fayla cat işlətsəniz nə olar?" \
  --note "Böyük fayla cat işlətsəniz ekran sona qədər 'axır' və başı itir. Orada less və ya head/tail lazımdır." \
  --assert '[ "$(cat app.env | wc -l)" -eq 3 ]'

step "Faylın əvvəli (head)" \
  --why "Böyük log-un formatını anlamaq üçün hamısını yükləməyə ehtiyac yoxdur — ilk bir neçə sətir bəs edir." \
  --cmd 'head -n 5 logs/access.log; echo "--- default:"; head logs/access.log | wc -l' \
  --explain "head|faylın əvvəlindən oxuyur" \
  --explain "-n 5|yalnız ilk 5 sətir (verilməsə, 10)" \
  --expect "5 access log sətri, sonra rəqəm 10" \
  --note "head -5 yazılışı da işləyir, amma -n 5 daha oxunaqlıdır." \
  --assert '[ "$(head -n 5 logs/access.log | wc -l)" -eq 5 ]'

step "Faylın sonu (tail)" \
  --why "Ən yeni hadisələr log-un sonundadır. İncident zamanı ilk baxdığınız yer." \
  --cmd 'tail -n 5 logs/access.log' \
  --explain "tail|faylın sonundan oxuyur" \
  --explain "-n 5|son 5 sətir" \
  --expect "Son 5 sətir (item/26 ... item/30)" \
  --assert 'tail -n 1 logs/access.log | grep -q "item/30"'

step "Neçə sətir var? (wc -l)" \
  --why "500 MB log faylını açmazdan əvvəl ölçüsünü bilmək lazımdır — less, yoxsa tail?" \
  --cmd 'wc -l logs/access.log; wc -l < logs/access.log' \
  --explain "wc -l|sətirləri sayır (word count, -l = lines)" \
  --explain "< fayl|faylı stdin kimi verir — fayl adı çıxışda görünmür" \
  --expect "30 logs/access.log, sonra təkcə 30" \
  --assert '[ "$(wc -l < logs/access.log)" -eq 30 ]'

step "Log-dan yalnız xətaları süz (cat | grep)" \
  --why "Deploy-dan sonra ilk sual: neçə 500 xətası var? Əl ilə oxumaq əvəzinə süzgəc işlədirik." \
  --cmd 'cat logs/access.log | grep " 500"; echo "---"; cat logs/access.log | grep " 500" | wc -l' \
  --explain "| (pipe)|soldakı əmrin çıxışını sağdakına ötürür" \
  --explain "grep \" 500\"|yalnız tərkibində 500 kodu olan sətirləri saxlayır" \
  --expect "4 sətir (item 7, 14, 21, 28) və sonda rəqəm 4" \
  --note "Pipe Linux-un ən güclü ideyasıdır: kiçik əmrləri zəncirləyib böyük iş görürsünüz." \
  --assert '[ "$(cat logs/access.log | grep " 500" | wc -l)" -eq 4 ]'

step "Canlı izləmə (tail -f) — 3 saniyəlik demo" \
  --why "Deploy gedərkən yeni sətirlərin necə düşdüyünü real vaxtda görmək üçün." \
  --cmd '( sleep 1; echo "10.0.0.99 - - \"GET /health HTTP/1.1\" 502" >> logs/access.log ) & timeout 3 tail -n 2 -f logs/access.log; wait; true' \
  --explain "tail -f|faylı izləyir, yeni sətir gələndə göstərir" \
  --explain "timeout 3|3 saniyədən sonra əmri dayandırır (real həyatda Ctrl+C edirsiniz)" \
  --explain "( sleep 1; echo ... >> )&|arxa planda 1 saniyə sonra log-a yeni sətir əlavə edir (simulyasiya)" \
  --expect "Son 2 sətir, bir saniyə sonra isə yeni 502 sətri özü görünür" \
  --note "Real serverdə: tail -f /var/log/nginx/error.log. Ctrl+C ilə çıxırsınız." \
  --assert 'tail -n 1 logs/access.log | grep -q " 502"'

task "Son 3 sətir" \
  "logs/access.log faylının son 3 sətrini last3.txt faylına yazın." \
  --check 'test -s last3.txt && [ "$(wc -l < last3.txt)" -eq 3 ] && diff -q last3.txt <(tail -n 3 logs/access.log)' \
  --hint "tail -n 3 faylın sonunu verir, nəticəni > ilə yönləndirin." \
  --solution 'tail -n 3 logs/access.log > last3.txt'

task "404 xətalarının sayı" \
  "Log-da neçə 404 sətri olduğunu tapıb yalnız rəqəmi count404.txt faylına yazın." \
  --check '[ "$(tr -d "[:space:]" < count404.txt)" = "$(grep -c " 404" logs/access.log)" ]' \
  --hint "grep-i wc -l ilə birləşdirin: cat ... | grep ... | wc -l" \
  --solution 'cat logs/access.log | grep " 404" | wc -l > count404.txt'

task "Nümunə (sample) faylı" \
  "sample.txt faylı yaradın: içində logs/access.log-un ilk 2 və son 2 sətri olsun (cəmi 4 sətir)." \
  --check 'test -s sample.txt && [ "$(wc -l < sample.txt)" -eq 4 ] && head -n 2 sample.txt | diff -q - <(head -n 2 logs/access.log) && tail -n 2 sample.txt | diff -q - <(tail -n 2 logs/access.log)' \
  --hint "head -n 2 > sample.txt, sonra tail -n 2 >> sample.txt (ikincidə >> işlədin, yoxsa birinci silinər!)" \
  --solution 'head -n 2 logs/access.log > sample.txt; tail -n 2 logs/access.log >> sample.txt'

lab_summary "Sessiya 05 — Fayl yaratma (touch, cat >, echo, heredoc)" \
  "cat — kiçik fayl, less/more — böyük fayl (interaktiv, q ilə çıx)" \
  "head -n N / tail -n N — faylın başı və sonu" \
  "wc -l — sətir sayı; cat | grep | wc -l — süz və say" \
  "tail -f — canlı log izləmə (Ctrl+C ilə çıx)"
