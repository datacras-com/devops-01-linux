# Sessiya 06 — Redaktə və append (>, >>, sed -i)
lab_init 06 "Fayl redaktəsi: append, overwrite və sed -i"

prep 'printf "2024-01-01 Step 1: Build complete\n2024-01-01 Step 2: Test complete\n2024-01-02 Step 3: Deploy complete\n" > pipeline.log; printf "DB_HOST=localhost\nDB_PORT=5432\nLOG_LEVEL=DEBUG\n" > config.conf; printf "APP_ENV=prod\n" > .env'

objective \
  "> (üzərinə yaz) ilə >> (sona əlavə et) fərqini və təhlükəsini izah etməyi" \
  "echo, printf və heredoc ilə mövcud fayla sətir əlavə etməyi" \
  "sed -i ilə konfiq dəyərini qeyri-interaktiv dəyişməyi" \
  "təsadüfən əzilmiş log-u backup-dan bərpa etməyi"

concept "> vs >> — ən bahalı bir simvol" \
  ">  faylı SIFIRLAYIR və yenisini yazır (köhnə məzmun itir). >> isə sona əlavə edir, köhnə qalır." \
  "Log, tarixçə və .env-də həmişə >> işlədin. Təsadüfən bir > yazmaq bütün tarixçəni silə bilər, geri qaytarmaq demək olar ki, mümkün deyil." \
  "nano/vi mövcud faylı redaktə edir (interaktiv: nano — Ctrl+O, Ctrl+X; vi — i, Esc, :wq). Skriptdə və avtomatlaşdırmada onların əvəzi sed -i-dir."

step "Əvvəlcə faylın hazırkı halı" \
  --why "Dəyişməzdən əvvəl hazırkı vəziyyəti bilmək, sonra müqayisə etmək üçün." \
  --cmd 'cat pipeline.log; wc -l pipeline.log' \
  --explain "wc -l|sətir sayı (dəyişikliyi bununla yoxlayacağıq)" \
  --expect "3 sətirlik pipeline.log, sonra 3 pipeline.log" \
  --assert '[ "$(wc -l < pipeline.log)" -eq 3 ]'

step "Bir sətir əlavə et (echo >>)" \
  --why "Pipeline-ın hər addımı log-a bir sətir əlavə edir. Köhnə sətirlər qalmalıdır." \
  --cmd 'echo "2024-01-02 Step 4: Smoke test passed" >> pipeline.log; tail -n 2 pipeline.log; wc -l pipeline.log' \
  --explain ">>|faylın SONUNA əlavə edir (fayl yoxdursa yaradır)" \
  --explain "tail -n 2|yoxlama: son iki sətir" \
  --expect "4 sətir, köhnə 3 sətir yerindədir" \
  --predict "Eyni əmri > ilə yazsaydıq nə qalardı?" \
  --note "Cavab: yalnız bir sətir. Bunu dərsin sonunda failure injection ilə yaşayacaqsınız." \
  --assert '[ "$(wc -l < pipeline.log)" -eq 4 ] && head -n 1 pipeline.log | grep -q "Step 1"'

step "Vaxt damğası ilə əlavə et" \
  --why "Real log-da hər sətrin vaxtı olmalıdır ki, incident-də ardıcıllıq bilinsin." \
  --cmd 'echo "$(date "+%Y-%m-%d %H:%M") Deploy: prod-a göndərildi" >> pipeline.log; tail -n 1 pipeline.log' \
  --explain "\$(date ...)|əmrin çıxışını mətnin içinə yerləşdirir (command substitution)" \
  --explain "\"+%Y-%m-%d %H:%M\"|tarix formatı" \
  --expect "Bu günün tarixi ilə yeni sətir" \
  --assert '[ "$(wc -l < pipeline.log)" -eq 5 ] && tail -n 1 pipeline.log | grep -Eq "^20[0-9]{2}-[0-9]{2}-[0-9]{2} "'

step "Çox sətir əlavə et (printf >> və heredoc >>)" \
  --why ".env və config-ə bir neçə dəyişəni birlikdə əlavə etmək lazım olur." \
  --cmd 'printf "DB_HOST=10.40.0.10\nDB_PORT=5432\n" >> .env
cat >> config.conf <<"EOF"
MAX_RETRIES=3
TIMEOUT=30
EOF
echo "--- .env:"; cat .env; echo "--- config.conf:"; cat config.conf' \
  --explain "printf ... >> .env|iki sətri .env-in sonuna əlavə edir" \
  --explain "cat >> fayl <<\"EOF\"|heredoc-un məzmununu sona əlavə edir (klaviatura gözləmir)" \
  --expect ".env 3 sətir, config.conf 5 sətir" \
  --assert '[ "$(wc -l < .env)" -eq 3 ] && [ "$(wc -l < config.conf)" -eq 5 ]'

step "Mövcud dəyəri dəyiş (sed -i)" \
  --why "nano ilə LOG_LEVEL=DEBUG-u əl ilə dəyişmək olar, amma 50 serverdə skriptlə dəyişmək lazımdır — sed -i bunu edir." \
  --cmd 'sed -i "s/LOG_LEVEL=DEBUG/LOG_LEVEL=INFO/" config.conf; grep LOG_LEVEL config.conf' \
  --explain "sed -i|faylı yerindəcə (in-place) dəyişir" \
  --explain "s/köhnə/yeni/|əvəz et (substitute)" \
  --explain "grep LOG_LEVEL|dəyişikliyi yoxla" \
  --expect "LOG_LEVEL=INFO" \
  --note "Risk: sed -i faylı birbaşa dəyişir. Vacib faylda sed -i.bak ... işlədin — köhnə nüsxə .bak olaraq qalır." \
  --assert 'grep -qx "LOG_LEVEL=INFO" config.conf && ! grep -q DEBUG config.conf'

step "Təhlükəsizlik şəbəkəsi: backup və noclobber" \
  --why "Vacib faylı dəyişməzdən əvvəl nüsxə çıxarın. noclobber isə > ilə mövcud faylın üzərinə yazmağı bloklayır." \
  --cmd 'cp pipeline.log pipeline.log.bak
bash -c "set -o noclobber; echo oops > pipeline.log" || echo "(noclobber qorudu: fayl dəyişmədi)"
wc -l pipeline.log pipeline.log.bak' \
  --explain "cp pipeline.log pipeline.log.bak|dəyişməzdən əvvəl nüsxə" \
  --explain "set -o noclobber|shell-də > mövcud faylı əzməsin" \
  --expect "cannot overwrite existing file xətası, hər iki fayl 5 sətir" \
  --note "Noclobber yalnız sizin shell-də işləyir və >| ilə yenə keçmək olar. Əsas qoruyucu: backup və diqqət." \
  --assert '[ "$(wc -l < pipeline.log)" -eq 5 ] && cmp -s pipeline.log pipeline.log.bak' \
  --allow-fail

task ".env-ə əlavə et" \
  ".env faylını silmədən sonuna iki sətir əlavə edin: REDIS_HOST=10.40.0.20 və REDIS_PORT=6379. APP_ENV=prod sətri yerində qalmalıdır." \
  --check 'grep -qx "APP_ENV=prod" .env && grep -qx "REDIS_HOST=10.40.0.20" .env && grep -qx "REDIS_PORT=6379" .env' \
  --hint "İki dəfə echo \"...\" >> .env yazın. Bir dənə də > olmasın!" \
  --solution 'echo "REDIS_HOST=10.40.0.20" >> .env; echo "REDIS_PORT=6379" >> .env'

task "Timeout dəyərini artır" \
  "config.conf-da TIMEOUT=30 dəyərini sed -i ilə TIMEOUT=60 edin. Digər sətirlər dəyişməsin." \
  --check 'grep -qx "TIMEOUT=60" config.conf && ! grep -q "TIMEOUT=30" config.conf && grep -qx "LOG_LEVEL=INFO" config.conf' \
  --hint "sed -i \"s/TIMEOUT=30/TIMEOUT=60/\" config.conf" \
  --solution 'sed -i "s/TIMEOUT=30/TIMEOUT=60/" config.conf'

inject "Təsadüfi > ilə log məhv oldu" \
  "Həmkarınız >> əvəzinə > yazdı və pipeline.log-un bütün tarixçəsi silinəcək. Simptomu görün və bərpa edin." \
  --cmd 'echo "2024-01-03 New run" > pipeline.log' \
  --symptom 'cat pipeline.log; wc -l pipeline.log' \
  --fix 'cp pipeline.log.bak pipeline.log; echo "2024-01-03 New run" >> pipeline.log' \
  --check '[ "$(wc -l < pipeline.log)" -ge 6 ] && grep -q "Step 1: Build" pipeline.log && tail -n 1 pipeline.log | grep -q "New run"' \
  --hint "Backup faylı pipeline.log.bak var. Onu geri kopyalayın, sonra yeni sətri >> ilə əlavə edin."

lab_summary "Sessiya 07 — Qovluq yaratma (mkdir, mkdir -p, ls -R)" \
  ">> əlavə edir, > əzir: log və .env-də həmişə >>" \
  "echo/printf/heredoc >> ilə sətir və blok əlavə etmək" \
  "sed -i \"s/köhnə/yeni/\" fayl — qeyri-interaktiv redaktə (sed -i.bak ilə nüsxə qalır)" \
  "vacib faylı dəyişməzdən əvvəl cp ilə backup alın"
