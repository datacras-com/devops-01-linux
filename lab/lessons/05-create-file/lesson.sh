# Sessiya 05 — Fayl yaratma (touch, cat >, echo, heredoc)
lab_init 05 "Fayl yaratma: skript, konfiq və .env"

objective \
  "touch ilə boş fayl və placeholder yaratmağı" \
  "echo, printf və heredoc (cat > fayl <<EOF) ilə məzmunlu fayl yaratmağı" \
  "ls -l və ls -ltr ilə fayl ölçüsünü və ən son dəyişəni tapmağı" \
  "nano/vi-nin nə üçün lazım olduğunu və harada işlədildiyini bilməyi"

concept "Linux-da fayl yaratmağın yolları" \
  "touch ad — 0 bayt boş fayl (mövcuddursa yalnız vaxtını yeniləyir). echo/printf '...' > ad — bir əmrlə məzmunlu fayl." \
  "cat > ad — klaviaturadan yazırsınız, Ctrl+C/Ctrl+D ilə bitirirsiniz (interaktivdir). Skriptdə bunun əvəzi heredoc-dur: cat > ad <<EOF ... EOF." \
  "nano ad / vi ad — redaktorlar İNTERAKTİVDİR (nano: Ctrl+O saxla, Ctrl+X çıx; vi: i yaz, Esc, :wq). Addımlarda işlətmirik, siz öz terminalınızda sınayın." \
  "Linux-da uzantı məcburi deyil: Dockerfile, Makefile, .env — uzantısız fayllardır."

step "Boş fayl yarat (touch)" \
  --why "CI/CD-də placeholder fayllar (.gitkeep), boş log faylı və ya timestamp yeniləmək üçün." \
  --cmd 'touch app.log; touch error.log access.log; ls -l' \
  --explain "touch ad|fayl yoxdursa 0 baytlıq yaradır, varsa vaxtını yeniləyir" \
  --explain "touch a b c|bir əmrlə bir neçə fayl" \
  --explain "ls -l|uzun format: icazə, sahib, ölçü, tarix, ad" \
  --expect "3 fayl, hamısının ölçüsü 0" \
  --note "Ölçü sütunu (5-ci) 0-dır: içi tamamilə boşdur." \
  --assert 'test -f app.log && test -f error.log && test -f access.log && [ ! -s app.log ]'

step "Bir sətirlik fayl (echo >)" \
  --why ".env və kiçik konfiqləri bir əmrlə yaratmaq olar." \
  --cmd 'echo "APP_ENV=production" > .env; cat .env; ls; echo "--- gizli fayllarla:"; ls -a' \
  --explain "echo \"...\"|mətni çap edir" \
  --explain ">|çıxışı ekran əvəzinə fayla yazır (fayl yoxdursa yaradır)" \
  --explain "ls -a|nöqtə ilə başlayan gizli faylları da göstərir" \
  --expect ".env adi ls-də görünmür, ls -a-da görünür" \
  --note "DİQQƏT: > fayl varsa onun ÜSTÜNƏ yazır. Bunun təhlükəsini Sessiya 06-da görəcəksiniz." \
  --assert 'grep -qx "APP_ENV=production" .env && ! ls | grep -q "^.env$"'

step "Çox sətirli fayl (printf)" \
  --why "\\n ilə bir neçə sətri skriptdə qısa yazmaq olar. printf formatı dəqiq idarə edir." \
  --cmd 'printf "DB_HOST=10.40.0.5\nDB_PORT=5432\nDB_NAME=appdb\n" > db.env; cat db.env; wc -l db.env' \
  --explain "printf|formatlı çıxış — \\n yeni sətir deməkdir" \
  --explain "wc -l db.env|yoxlama: 3 sətir" \
  --expect "3 sətir və 3 db.env" \
  --assert '[ "$(wc -l < db.env)" -eq 3 ]'

step "Heredoc ilə konfiq faylı (cat > fayl <<EOF)" \
  --why "nginx.conf kimi çox sətirli faylı skriptdə yaratmağın standart yolu. Klaviatura gözləmir." \
  --cmd 'cat > nginx.conf <<"EOF"
server {
    listen 80;
    server_name dev.example.com;
    location / {
        proxy_pass http://127.0.0.1:8080;
    }
}
EOF
cat -n nginx.conf' \
  --explain "<<\"EOF\"|EOF sətrinə qədər olan hər şeyi fayla göndər (dırnaqlı EOF = dəyişənlər açılmır)" \
  --explain "cat > nginx.conf|stdin-i nginx.conf-a yazır" \
  --explain "cat -n|yoxlama üçün sətir nömrələri ilə göstərir" \
  --expect "7 sətirlik nginx server bloku" \
  --note "Dırnaqsız <<EOF yazsanız, \$(whoami) kimi hissələr yazılarkən icra olunar. Konfiqdə \$ varsa həmişə <<\"EOF\" işlədin." \
  --assert 'grep -q "proxy_pass" nginx.conf && [ "$(wc -l < nginx.conf)" -eq 7 ]'

step "Dəyişənli heredoc: deploy skripti" \
  --why "Dırnaqsız heredoc dəyişənləri yazılan anda doldurur — şablon üçün faydalıdır." \
  --cmd 'APP=myapp; cat > deploy.sh <<EOF
#!/bin/bash
echo "Deploying $APP"
cp -r build/ /srv/$APP/releases/
EOF
cat deploy.sh' \
  --explain "<<EOF|dırnaqsız: \$APP dərhal myapp ilə əvəz olunur" \
  --explain "#!/bin/bash|shebang — faylı hansı interpretator işlədir" \
  --expect "Faylda \$APP yox, artıq myapp yazılıb" \
  --assert 'grep -q "Deploying myapp" deploy.sh && head -n 1 deploy.sh | grep -q "^#!/bin/bash"'

step "Faylları ölçü və vaxta görə bax (ls -l, ls -ltr)" \
  --why "/var/log-da yüzlərlə fayl var — ən son yazılanı ls -ltr ilə ən aşağıda görürsünüz." \
  --cmd 'touch -d "2 days ago" old.log; touch fresh.log; ls -ltr' \
  --explain "touch -d \"2 days ago\"|faylın vaxtını əl ilə 2 gün əvvələ qoyur (demo üçün)" \
  --explain "-t|vaxta görə sırala" \
  --explain "-r|tərsinə çevir — ən yeni aşağıda olsun" \
  --expect "old.log yuxarıda, fresh.log ən aşağıda" \
  --note "Yadda saxlayın: ls -ltr = ən son dəyişən fayl sonda." \
  --assert '[ "$(ls -tr old.log fresh.log | head -n 1)" = old.log ]'

task "Release qeydi faylı" \
  "release.txt yaradın, 3 sətir olsun: VERSION=1.4.2, ENV=staging, OWNER=devops. (heredoc və ya printf işlədin)" \
  --check '[ "$(wc -l < release.txt)" -eq 3 ] && grep -qx "VERSION=1.4.2" release.txt && grep -qx "ENV=staging" release.txt && grep -qx "OWNER=devops" release.txt' \
  --hint "printf \"A\\nB\\nC\\n\" > fayl 3 sətir yazır." \
  --solution 'printf "VERSION=1.4.2\nENV=staging\nOWNER=devops\n" > release.txt'

task "Boş log faylları" \
  "Bir əmrlə worker-1.log, worker-2.log, worker-3.log boş faylları yaradın." \
  --check 'for i in 1 2 3; do test -f worker-$i.log && [ ! -s worker-$i.log ] || exit 1; done' \
  --hint "touch bir neçə ad qəbul edir; {1..3} brace expansion-dır." \
  --solution 'touch worker-{1..3}.log'

task "backup.sh skripti" \
  "backup.sh yaradın: birinci sətir #!/bin/bash, ikinci sətir tar -czf backup.tar.gz /srv/myapp/shared olsun." \
  --check '[ "$(wc -l < backup.sh)" -eq 2 ] && head -n 1 backup.sh | grep -qx "#!/bin/bash" && grep -q "tar -czf backup.tar.gz /srv/myapp/shared" backup.sh' \
  --hint "Heredoc: cat > backup.sh <<\"EOF\" ... EOF. Dırnaqlı EOF işlədin." \
  --solution 'cat > backup.sh <<"EOF"
#!/bin/bash
tar -czf backup.tar.gz /srv/myapp/shared
EOF'

lab_summary "Sessiya 06 — Fayl redaktəsi və append (>, >>, sed -i)" \
  "touch — boş fayl; echo/printf > fayl — məzmunlu fayl" \
  "cat > fayl <<\"EOF\" — çox sətirli fayl (skript və konfiq üçün standart)" \
  "ls -a gizli faylları, ls -ltr ən son dəyişəni göstərir" \
  "nano/vi interaktivdir — skriptdə heredoc və printf işlədin"
