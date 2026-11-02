# Sessiya 17 — ls əmri (ls -l, -a, -h, -R, -t, -d): çıxışı oxumaq
lab_init 17 "ls əmri: fayl siyahısı və icazələri oxumaq"

objective \
  "ls -l çıxışındakı 7 sütunu (tip, icazə, sahib, qrup, ölçü, tarix, ad) oxumağı" \
  "gizli faylları (.env) ls -a ilə tapmağı" \
  "ls -lh, -t, -S ilə böyük və ən yeni log faylını tapmağı" \
  "ls -ld ilə qovluğun özünün icazəsinə baxmağı və -R ilə ağacı görməyi"

concept "ls -l: ən çox işlənən diaqnostika əmri" \
  "'Deploy skripti icra olunmur', 'log-a yazmaq olmur', '.env oxunmur': hər dəfə ilk baxılan yer ls -l çıxışıdır." \
  "Sətir: -rwxr-xr-x 1 sahib qrup ölçü tarix ad. İlk simvol tip (- fayl, d qovluq, l symlink, c/b cihaz), sonra owner/group/others üçün 3x3 icazə."

step "Test layihəsini hazırla" \
  --why "ls-in nə göstərdiyini görmək üçün müxtəlif ölçü, tarix və icazəli fayllar lazımdır. Tarixlər sabitdir ki, çıxış hər dəfə eyni olsun." \
  --cmd 'mkdir -p app/logs && cd app && printf "#!/bin/bash\necho deploy\n" > deploy.sh && printf "server { listen 80; }\n" > nginx.conf && printf "DB_PASS=secret\n" > .env && head -c 2048 /dev/zero > logs/access.log && head -c 2097152 /dev/zero > logs/error.log && head -c 100 /dev/zero > logs/app.log && chmod 755 deploy.sh && chmod 644 nginx.conf && chmod 600 .env && touch -d "2025-03-01 10:00" logs/access.log && touch -d "2025-03-03 10:00" logs/error.log && touch -d "2025-03-02 10:00" logs/app.log && touch -d "2025-02-10 08:30" deploy.sh nginx.conf .env && cd .. && find app -type f | sort' \
  --explain "head -c N /dev/zero|N baytlıq fayl yaradır (ölçüləri müqayisə etmək üçün)" \
  --explain "touch -d|faylın dəyişmə tarixini təyin edir" \
  --explain "chmod|icazələri qurur (Sessiya 19-da öyrənəcəksiniz)" \
  --expect "6 fayl yolu: app/.env, app/deploy.sh, app/logs/..., app/nginx.conf" \
  --assert 'test -f app/.env && test -f app/logs/error.log'

step "Sadə ls və gizli fayllar: -a" \
  --why ".env kimi gizli fayllar adi ls-də görünmür; deploy-da onları unutmaq tez-tez edilən səhvdir." \
  --cmd 'ls app; echo "--- -a ---"; ls -a app; echo "--- -A (. və .. olmadan) ---"; ls -A app' \
  --explain "ls|gizli (nöqtə ilə başlayan) faylları göstərmir" \
  --explain "-a|hamısını, həm də . (cari) və .. (üst) qovluqları" \
  --explain "-A|-a kimi, amma . və .. olmadan" \
  --expect "Birinci siyahıda .env yoxdur; ikinci və üçüncüdə var" \
  --predict "Sizcə niyə .env-i gizli saxlamaq adətdir?" \
  --note "Nöqtə ilə başlayan fayl gizli sayılır. Bu təhlükəsizlik deyil, sadəcə səliqədir; real qoruma icazələrdədir (600)." \
  --assert 'ls -a app | grep -qx .env && ! ls app | grep -qx .env'

step "Uzun format: ls -l və 7 sütun" \
  --why "İcazə, sahib və ölçü yalnız uzun formatda görünür." \
  --cmd 'ls -l --time-style=long-iso app' \
  --explain "-l|uzun format: hər fayl bir sətir" \
  --explain "--time-style=long-iso|tarix sabit formatda (İL-AY-GÜN SAAT)" \
  --explain "total N|bloklarda ümumi ölçü (fayl sayı deyil)" \
  --expect "deploy.sh üçün -rwxr-xr-x, nginx.conf üçün -rw-r--r--, logs üçün drwx..." \
  --note "Sütunlar: 1) tip+icazə 2) hard link sayı 3) sahib 4) qrup 5) ölçü (bayt) 6) tarix 7) ad. deploy.sh-da x var, ona görə ./deploy.sh işləyir." \
  --assert 'ls -l app | grep -q "^-rwxr-xr-x.* deploy.sh$" && ls -l app | grep -q "^-rw-r--r--.* nginx.conf$"'

step "Fayl tipi: ilk simvol" \
  --why "/dev-də cihaz faylları, /bin-də symlink-lər görürsünüz; tipi bilmək onlarla düzgün davranmağa kömək edir." \
  --cmd 'ls -ld /dev/null /etc /bin app/deploy.sh | cut -c1-10' \
  --explain "-d|qovluğun içini deyil, özünü göstər (addım 6-da ətraflı)" \
  --explain "cut -c1-10|yalnız ilk 10 simvol: tip + icazə" \
  --expect "crw-rw-rw- (cihaz), drwxr-xr-x (qovluq), lrwxrwxrwx (symlink), -rwxr-xr-x (fayl)" \
  --note "c = character cihaz, d = directory, l = symlink (Ubuntu-da /bin → usr/bin), - = adi fayl. b = blok cihaz (disk)." \
  --assert '[ "$(ls -ld /dev/null | cut -c1)" = c ] && [ "$(ls -ld /etc | cut -c1)" = d ]'

step "Oxunaqlı ölçü: -h və ölçüyə görə sıralama: -S" \
  --why "Disk dolanda ilk sual: ən böyük log hansıdır?" \
  --cmd 'ls -lh --time-style=long-iso app/logs; echo "--- -S (böyükdən kiçiyə) ---"; ls -S app/logs' \
  --explain "-h|human-readable: 2048 bayt → 2.0K, 2097152 → 2.0M" \
  --explain "-S|ölçüyə görə sırala (böyük əvvəl)" \
  --expect "error.log 2.0M, access.log 2.0K, app.log 100; -S sırası: error.log, access.log, app.log" \
  --note "-h tək işləmir, -l ilə birlikdə mənalıdır. /var/log-da 'ls -lhS | head' disk dolması ilə mübarizənin ilk addımıdır." \
  --assert '[ "$(ls -S app/logs | head -n 1)" = error.log ] && ls -lh app/logs | grep -q " 2.0M "'

step "Tarixə görə sıralama: -t və -r" \
  --why "Incident zamanı 'ən son dəyişən fayl hansıdır?' sualı gündəlik sualdır." \
  --cmd 'ls -t app/logs; echo "--- -r (tərsinə) ---"; ls -tr app/logs; echo "--- ən yeni ---"; ls -t app/logs | head -n 1' \
  --explain "-t|son dəyişmə vaxtına görə, ən yeni əvvəl" \
  --explain "-r|reverse: sıranı çevir (ən köhnə əvvəl)" \
  --expect "-t: error.log, app.log, access.log; -tr əksinə; ən yeni: error.log" \
  --note "ls -lt əmri uzun format ilə birlikdə də tez-tez işlənir: 'ls -lt /var/log | head' son yazılan log-ları göstərir." \
  --assert '[ "$(ls -t app/logs | head -n 1)" = error.log ] && [ "$(ls -tr app/logs | head -n 1)" = access.log ]'

step "Qovluğun özü: -d, və ağac: -R" \
  --why "'Qovluğa girə bilmirəm' halında qovluğun öz icazəsi lazımdır, içindəkilərin yox." \
  --cmd 'ls -l app/logs | head -n 2; echo "--- -d ---"; ls -ld app/logs; echo "--- -R ---"; ls -R app' \
  --explain "ls -l qovluq|qovluğun İÇİNDƏKİLƏRİ göstərir" \
  --explain "ls -ld qovluq|qovluğun ÖZ icazəsini göstərir" \
  --explain "-R|alt qovluqlara rekursiv enir (hər qovluq adı ilə başlıq alır)" \
  --expect "-d: drwxr-xr-x ... app/logs; -R: 'app:' və 'app/logs:' bölmələri" \
  --note "Qovluğa cd etmək üçün onun özündə x lazımdır, bunu ls -ld ilə yoxlayırsınız. -R böyük ağaclarda uzun çıxış verir; orada find və ya tree daha rahatdır." \
  --assert 'ls -R app | grep -q "^app/logs:$" && ls -ld app/logs | grep -q "^d"'

task "Ən böyük log" \
  "app/logs-dakı ən böyük faylın adını (yalnız ad) iş qovluğundakı biggest.txt-ə yazın." \
  --check '[ "$(cat biggest.txt)" = error.log ]' \
  --hint "ls -S ölçüyə görə sıralayır. İlk sətri head -n 1 ilə götürün." \
  --solution 'ls -S app/logs | head -n 1 > biggest.txt'

task "Gizli faylı tap" \
  "app qovluğundakı gizli faylların adlarını (nöqtə ilə başlayanları) hidden.txt-ə yazın. -a ilə . və .. də çıxacaq, onları -A ilə ayırın." \
  --check '[ "$(cat hidden.txt)" = .env ]' \
  --hint "ls -A app çıxışından yalnız nöqtə ilə başlayanları grep '^\\.' ilə seçin." \
  --solution "ls -A app | grep '^\\.' > hidden.txt"

task "deploy.sh icazə sətiri" \
  "deploy.sh faylının 10 simvolluq icazə sətrini (məs. -rwxr-xr-x) perm.txt-ə yazın." \
  --check '[ "$(cat perm.txt)" = "-rwxr-xr-x" ]' \
  --hint "ls -l çıxışının ilk 10 simvolunu cut -c1-10 ilə kəsin." \
  --solution 'ls -l app/deploy.sh | cut -c1-10 > perm.txt'

lab_summary "Sessiya 18 — Fayl icazələri (rwx, ugo, oktal, umask, stat)" \
  "ls -l: tip+icazə, link, sahib, qrup, ölçü, tarix, ad" \
  "-a/-A gizli faylları, -h oxunaqlı ölçü, -S ölçüyə, -t tarixə, -r tərsinə görə" \
  "ls -ld qovluğun özünün icazəsi, -R rekursiv ağac" \
  "İlk simvol tip: - fayl, d qovluq, l symlink, c/b cihaz"
