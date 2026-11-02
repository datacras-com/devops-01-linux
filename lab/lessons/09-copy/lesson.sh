# Sessiya 09 — Fayl və qovluq kopyalamaq (cp)
lab_init 09 "Kopyalama: cp ilə təhlükəsiz backup"

objective \
  "cp ilə faylı fayla və faylı qovluğa kopyalamağı" \
  "cp -r ilə qovluğu bütöv kopyalamağı" \
  "cp -i ilə təsadüfən üzərinə yazmanın qarşısını almağı" \
  "dəyişiklikdən əvvəl config backup-ı (config.yml.bak) hazırlamağı"

concept "Niyə cp? Dəyişməzdən əvvəl kopyala" \
  "DevOps qızıl qaydası: production konfiqini dəyişməzdən əvvəl həmişə backup götür." \
  "cp source destination — destination mövcuddursa SESSİZCƏ üzərinə yazılır. Qovluq üçün -r (recursive) lazımdır."

step "Hazırlıq: nginx.conf nümunəsi və faylı fayla kopyalamaq" \
  --why "Deploy-dan əvvəl konfiqin ehtiyat nüsxəsi lazımdır; cp bunun ən sadə yoludur." \
  --cmd 'printf "worker_processes 2;\nlisten 8080;\nserver_name dev.example.net;\n" > nginx.conf; cp nginx.conf nginx.conf.bak; ls -l nginx.conf nginx.conf.bak' \
  --explain "printf ... > nginx.conf|nümunə konfiq faylı yaradır" \
  --explain "cp nginx.conf nginx.conf.bak|fayl → fayl kopyası (source destination)" \
  --explain "ls -l|ölçünün eyni olduğunu yoxlayırıq" \
  --expect "İki fayl, eyni ölçüdə" \
  --note "Orijinal yerində qalır, kopya yaranır. Məzmun və ölçü eynidir." \
  --assert 'cmp -s nginx.conf nginx.conf.bak'

step "Faylı qovluğa kopyalamaq" \
  --why "Skripti və ya konfiqi backup/ və ya scripts/ qovluğuna atmaq gündəlik işdir." \
  --cmd 'mkdir -p backup; printf "#!/bin/bash\necho deploy\n" > deploy.sh; cp deploy.sh backup/; cp nginx.conf backup/; ls backup' \
  --explain "mkdir -p backup|backup qovluğunu yaradır (varsa xəta vermir)" \
  --explain "cp deploy.sh backup/|destination qovluqdursa fayl eyni adla içində yaranır" \
  --expect "backup qovluğunda deploy.sh və nginx.conf" \
  --predict "cp nginx.conf backup/ əmri hansı adla fayl yaradacaq?" \
  --note "Destination qovluqdursa ad saxlanılır: backup/nginx.conf. Sonundakı / niyyəti aydın göstərir." \
  --assert 'test -f backup/deploy.sh && test -f backup/nginx.conf'

step "Qovluğu kopyalamaq: -r olmadan və ilə" \
  --why "Bütün conf.d/ qovluğunu yedəkləmək üçün -r lazımdır; xətanı bir dəfə görmək yaxşıdır." \
  --cmd 'mkdir -p conf.d; echo "location / {}" > conf.d/site.conf; cp conf.d conf.d.bak; echo "--- indi -r ilə ---"; cp -r conf.d conf.d.bak; ls conf.d.bak' \
  --explain "cp conf.d conf.d.bak|qovluq üçün -r yoxdur → xəta (omitting directory)" \
  --explain "cp -r|recursive: qovluğu və içindəki hər şeyi kopyalayır" \
  --expect "Əvvəlcə 'omitting directory' xətası, sonra conf.d.bak içində site.conf" \
  --note "Xəta gözlənilən idi. -r ilə bütün ağac kopyalandı." \
  --assert 'test -f conf.d.bak/site.conf' \
  --allow-fail

step "Üzərinə yazmaq təhlükəsi və -i" \
  --why "cp səssizcə üzərinə yazır. Səhvən doğru faylı itirmək olar." \
  --cmd 'echo "ORIGINAL" > a.txt; echo "NEW" > b.txt; cp b.txt a.txt; cat a.txt; echo "--- -i ilə (n cavabı) ---"; echo n | cp -i b.txt nginx.conf; head -n 1 nginx.conf' \
  --explain "cp b.txt a.txt|a.txt-nin məzmunu itdi, soruşmadı" \
  --explain "cp -i|interactive: üzərinə yazmazdan əvvəl soruşur" \
  --expect "a.txt indi NEW; -i soruşur, n cavabı ilə nginx.conf toxunulmaz qalır" \
  --note "Skriptlərdə -i yaramaz (cavab gözləyir), amma əl ilə işləyəndə sığortadır." \
  --assert 'grep -q NEW a.txt && grep -q worker nginx.conf'

step "Metadatanı qorumaq: -p" \
  --why "Backup-da sahib, icazə və vaxt qalmalıdır (məs. icra hüququ olan deploy.sh)." \
  --cmd 'chmod 750 deploy.sh; cp deploy.sh plain.sh; cp -p deploy.sh kept.sh; ls -l deploy.sh plain.sh kept.sh | cut -c1-10' \
  --explain "cp|yeni fayl üçün default icazə (umask) tətbiq olunur" \
  --explain "cp -p|preserve: icazə, sahib və vaxt damğasını saxlayır" \
  --expect "kept.sh icazəsi deploy.sh ilə eynidir (-rwxr-x---)" \
  --note "Yeni faylın icazəsi mənbədən fərqli ola bilər; -p ilə eyni qalır. İcazələri Sessiya 18-19-da görəcəyik." \
  --assert '[ "$(stat -c %a kept.sh)" = 750 ]'

step "Praktik nümunə: tarixli backup və yoxlama" \
  --why "Hər dəyişiklikdən əvvəl adı ilə tarix qoyulmuş backup — rollback üçün əsasdır." \
  --cmd 'cp -p nginx.conf "nginx.conf.$(date +%Y%m%d)"; ls nginx.conf.*; diff nginx.conf backup/nginx.conf && echo "eynidir"' \
  --explain '$(date +%Y%m%d)|tarixi ada əlavə edir (məs. 20260101)' \
  --explain "diff|iki faylın fərqini göstərir; çıxış yoxdursa eynidir" \
  --expect "Tarixli backup faylı və 'eynidir'" \
  --note "diff haqqında Sessiya 12-də ətraflı." \
  --assert 'ls nginx.conf.2* >/dev/null'

task "Config backup" \
  "app.yml yaradın (məzmun: port: 8080) və onu app.yml.bak adı ilə kopyalayın." \
  --check 'test -f app.yml && cmp -s app.yml app.yml.bak && grep -q 8080 app.yml' \
  --hint "echo 'port: 8080' > app.yml, sonra cp app.yml app.yml.bak" \
  --solution 'echo "port: 8080" > app.yml; cp app.yml app.yml.bak'

task "Qovluğu yedəklə" \
  "scripts qovluğu yaradın, içinə run.sh qoyun və bütün qovluğu scripts.bak kimi kopyalayın." \
  --check 'test -f scripts.bak/run.sh' \
  --hint "Qovluq üçün cp -r" \
  --solution 'mkdir -p scripts; echo "echo hi" > scripts/run.sh; cp -r scripts scripts.bak'

task "İcazəni qorumaqla kopyala" \
  "tool.sh yaradın, chmod 700 verin və cp -p ilə tool.sh.bak kimi kopyalayın (icazə eyni qalmalıdır)." \
  --check '[ "$(stat -c %a tool.sh.bak)" = 700 ]' \
  --hint "chmod 700 tool.sh; cp -p tool.sh tool.sh.bak" \
  --solution 'echo x > tool.sh; chmod 700 tool.sh; cp -p tool.sh tool.sh.bak'

lab_summary "Sessiya 10 — Köçürmək və adını dəyişmək (mv)" \
  "cp src dst — fayl; qovluq üçün cp -r" \
  "cp səssizcə üzərinə yazır — -i sığortadır" \
  "cp -p icazə və vaxtı saxlayır" \
  "dəyişməzdən əvvəl həmişə .bak götür"
