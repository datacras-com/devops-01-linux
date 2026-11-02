# Sessiya 08 — Silmə (rm, rm -f, rmdir, rm -r, rm -rf)
lab_init 08 "Fayl və qovluq silmək: təhlükəsiz və təhlükəli"

prep 'mkdir -p demo/logs demo/tmp demo/empty1 demo/empty2 demo/old_release/bin demo/old_release/conf app/current app/config app/tmp backup
touch demo/logs/app-2024-01.log demo/logs/app-2024-02.log demo/logs/app-2024-03.log demo/logs/current.log demo/tmp/a.tmp demo/tmp/b.tmp demo/tmp/c.tmp demo/tmp/keep.txt demo/old_release/bin/run.sh demo/old_release/conf/app.env
echo "<h1>live</h1>" > app/current/index.html; echo "APP_ENV=prod" > app/config/app.env; touch app/tmp/cache1 app/tmp/cache2'

objective \
  "rm, rm -f, rmdir və rm -r fərqini bilməyi" \
  "silməzdən əvvəl ls/echo ilə nəyin silinəcəyini yoxlamağı" \
  "rm -rf * əmrinin niyə təhlükəli olduğunu anlamağı" \
  "yanlış silmədən sonra backup-dan bərpa etməyi"

concept "Linux-da Recycle Bin yoxdur" \
  "rm faylı birdəfəlik silir. Geri alma yoxdur. rmdir yalnız BOŞ qovluq silir (təhlükəsizdir). rm -r qovluğu içindəkilərlə silir, rm -rf isə heç nə soruşmadan." \
  "Bəzi sistemlərdə rm alias olaraq rm -i-dir (hər dəfə soruşur). Skriptlərdə və bu dərsdə sual yoxdur, ona görə hər şeyi əvvəlcədən yoxlayırıq." \
  "Qızıl qayda: pwd -> ls (nəyi siləcəyəm?) -> sonra rm. Kritik faylın əvvəlcə nüsxəsini çıxarın. Bu dərsdə hər şey yalnız sandbox daxilindədir."

step "Silmədən əvvəl strukturu gör" \
  --why "Nəyi sildiyinizi bilmirsinizsə, silməyin. Əvvəlcə baxın." \
  --cmd 'pwd; find demo | sort' \
  --explain "pwd|hansı qovluqdasınız" \
  --explain "find demo|demo altındakı hər şeyin siyahısı" \
  --expect "demo/empty1, demo/logs/..., demo/old_release/..., demo/tmp/..." \
  --assert 'test -d demo/old_release && test -f demo/logs/current.log'

step "Tək faylı sil (rm)" \
  --why "Köhnə və lazımsız faylı təmizləmək üçün." \
  --cmd 'rm -v demo/logs/current.log; ls demo/logs' \
  --explain "rm fayl|faylı silir" \
  --explain "-v|verbose: nəyi sildiyini çap edir" \
  --expect "removed demo/logs/current.log və qalan 3 log" \
  --assert '[ ! -e demo/logs/current.log ] && [ "$(ls demo/logs | wc -l)" -eq 3 ]'

step "Çoxlu fayl, əvvəlcə echo ilə yoxla" \
  --why "Wildcard (*) hansı faylları tutur? Silməzdən əvvəl echo ilə baxın — bu ən vacib təhlükəsizlik vərdişidir." \
  --cmd 'echo demo/logs/app-2024-0[12].log
rm -v demo/logs/app-2024-0[12].log
ls demo/logs' \
  --explain "echo ...[12].log|shell nəyi açacağını göstərir, heç nə silmir" \
  --explain "[12]|1 və ya 2 simvolu ilə uyğunlaşır" \
  --expect "əvvəlcə 2 fayl adı, sonra removed x2, qalan: app-2024-03.log" \
  --note "Qayda: rm yazmazdan əvvəl eyni sətri echo ilə yazın, çıxışa baxın, sonra echo-nu rm ilə əvəz edin." \
  --assert '[ "$(ls demo/logs)" = "app-2024-03.log" ]'

step "rm -f: zorla, səssiz" \
  --why "Skriptdə fayl yoxdursa xətasız keçmək lazımdır (təmizləmə skriptləri)." \
  --cmd 'rm demo/yoxdur.log; echo "rm exit: $?"; rm -f demo/yoxdur.log; echo "rm -f exit: $?"' \
  --explain "rm yoxdur|fayl yoxdursa xəta verir (exit 1)" \
  --explain "rm -f|force: sual vermir, olmayan faylı sükutla keçir (exit 0)" \
  --expect "birinci cannot remove ... No such file, exit 1; ikinci səssiz, exit 0" \
  --note "-f həm də real xətaları gizlədə bilər. Skriptdə yalnız bilərək işlədin." \
  --assert 'rm -f demo/yoxdur.log'

step "rmdir: yalnız boş qovluq" \
  --why "Qovluq boş deyilsə rmdir silmir — səhvən data itirməkdən qoruyur." \
  --cmd 'rmdir -v demo/empty1; echo "--- dolu qovluğa cəhd:"; rmdir demo/old_release; ls demo' \
  --explain "rmdir|boş qovluğu silir" \
  --explain "dolu qovluq|Directory not empty xətası verir və heç nə silmir" \
  --expect "removing directory demo/empty1, sonra Directory not empty xətası" \
  --assert '[ ! -d demo/empty1 ] && test -d demo/old_release' \
  --allow-fail

step "Qovluq üçün rm -r" \
  --why "Dolu qovluğu silmək lazımdırsa -r lazımdır. Adi rm qovluğu silmir." \
  --cmd 'mkdir -p demo/scratch/a/b; touch demo/scratch/a/b/f.txt
rm demo/scratch || echo "(rm tək başına qovluq silmir)"
rm -r demo/scratch; ls demo' \
  --explain "rm qovluq|Is a directory xətası" \
  --explain "-r|recursive: içinə gir, hər şeyi sil, sonra qovluğu sil" \
  --expect "Is a directory xətası; sonra scratch ls-də yoxdur" \
  --assert '[ ! -d demo/scratch ]'

step "Təhlükəsiz təmizləmə: backup + yoxla + sil" \
  --why "app/ canlı tətbiqdir. İş görməzdən əvvəl backup, silməzdən əvvəl echo, sonra rm." \
  --cmd 'tar -czf backup/app-backup.tar.gz app
echo app/tmp/*
rm -rf app/tmp/*
ls app app/tmp; ls backup' \
  --explain "tar -czf ... app|app qovluğunu sıxılmış arxivə yığır (backup)" \
  --explain "echo app/tmp/*|wildcard nəyi tutur, əvvəlcə baxırıq" \
  --explain "rm -rf app/tmp/*|tam yol ilə: yalnız tmp-nin içi silinir, tmp özü qalır" \
  --expect "cache1 cache2 göstərilir; app-da config current tmp; tmp boş; backup-da arxiv" \
  --note "Yola diqqət: app/tmp/* (düzgün). Yalnız * yazıb yanlış qovluqda olsanız nə olar? Sonda görəcəksiniz." \
  --assert 'test -s backup/app-backup.tar.gz && [ -z "$(ls -A app/tmp)" ] && test -f app/current/index.html'

task "Müvəqqəti faylları təmizlə" \
  "demo/tmp-də yalnız .tmp ilə bitən faylları silin. keep.txt qalmalıdır." \
  --check '[ "$(ls demo/tmp)" = "keep.txt" ]' \
  --hint "Əvvəlcə echo demo/tmp/*.tmp yazın, sonra echo-nu rm ilə əvəz edin." \
  --solution 'rm demo/tmp/*.tmp'

task "Boş qovluğu sil" \
  "demo/empty2 qovluğunu (boşdur) ən təhlükəsiz əmrlə silin." \
  --check '[ ! -d demo/empty2 ] && test -d demo' \
  --hint "Boş qovluq üçün -r lazım deyil: rmdir." \
  --solution 'rmdir demo/empty2'

task "Köhnə release-i sil" \
  "demo/old_release qovluğunu içindəkilərlə birlikdə silin. demo/logs və demo/tmp toxunulmaz qalmalıdır." \
  --check '[ ! -e demo/old_release ] && test -f demo/logs/app-2024-03.log && test -f demo/tmp/keep.txt' \
  --hint "Dolu qovluq: rm -r (və ya -rf). Yol dəqiq olsun: demo/old_release." \
  --solution 'rm -rf demo/old_release'

inject "Yanlış qovluqda rm -rf *" \
  "Mühəndis app/tmp-i təmizləmək istəyirdi, amma app/ qovluğunda olub rm -rf ./* yazdı. Canlı tətbiq silinəcək. Backup-dan bərpa edin." \
  --cmd '(cd app && rm -rf ./*)' \
  --symptom 'ls -A app | wc -l; test -f app/current/index.html || echo "index.html yoxdur!"' \
  --fix 'tar -xzf backup/app-backup.tar.gz' \
  --check 'test -f app/current/index.html && test -f app/config/app.env' \
  --hint "backup/app-backup.tar.gz-də app/ var. tar -xzf ilə iş qovluğunda açın (tar -tzf ilə əvvəlcə içinə baxa bilərsiniz)."

lab_summary "Sessiya 09 — Kopyalama (cp)" \
  "rm fayl, rm -f səssiz, rmdir yalnız boş, rm -r qovluq, rm -rf sorğusuz" \
  "silmədən əvvəl: pwd, ls və ya echo ilə wildcard-ı yoxla" \
  "geri qaytarma yoxdur — kritik şeyi silmədən əvvəl backup (cp/tar)" \
  "rm -rf * yalnız dəqiq bildiyiniz qovluqda, tam yolla: rm -rf app/tmp/*"
