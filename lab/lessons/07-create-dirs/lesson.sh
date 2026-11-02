# Sessiya 07 — Qovluq yaratma (mkdir, mkdir -p, ls -R, find)
lab_init 07 "Qovluq yaratma: deploy strukturu qurmaq"

objective \
  "mkdir ilə bir və ya bir neçə qovluq yaratmağı" \
  "mkdir -p və brace expansion {a,b} ilə tam deploy strukturunu bir əmrlə qurmağı" \
  "ls -l, ls -R və find ilə strukturu yoxlamağı" \
  "releases / shared / backups kimi standart DevOps qovluq quruluşunu bilməyi"

concept "Niyə düzgün qovluq strukturu?" \
  "Ansible, Docker, nginx kimi alətlər müəyyən yolları gözləyir: /srv/APP/releases (versiyalar), shared (.env, upload), backups; /opt/APP/logs, config; /var/log/APP." \
  "Bu dərsdə eyni quruluşu sandbox daxilində nisbi yollarla (srv/..., opt/...) qururuq. tree əmri strukturu vizual göstərir, amma minimal serverdə yoxdur (apt install tree). Biz find və ls -R ilə eyni nəticəni alırıq."

step "Qovluq yarat (mkdir)" \
  --why "Hər layihənin öz qovluğu olmalıdır: log, skript və məlumat qarışmasın." \
  --cmd 'mkdir projects; mkdir logs data scripts; ls -l' \
  --explain "mkdir ad|bir qovluq yaradır" \
  --explain "mkdir a b c|bir neçə qovluq birlikdə" \
  --explain "ls -l|d hərfi ilə başlayan sətir qovluq deməkdir (fayllarda -)" \
  --expect "4 qovluq, hər sətir drwx... ilə başlayır" \
  --assert 'for d in projects logs data scripts; do test -d $d || exit 1; done'

step "İç-içə yol -p olmadan xəta verir" \
  --why "Çox adamın ilk qarşılaşdığı xəta: ara qovluqlar yoxdur." \
  --cmd 'mkdir srv/myapp/releases' \
  --explain "srv/myapp/releases|srv və myapp hələ yoxdur" \
  --expect "mkdir: cannot create directory ...: No such file or directory" \
  --note "Bu gözlənilən xətadır, qorxmayın. Növbəti addımda -p ilə həll edirik." \
  --assert '[ ! -d srv ]' \
  --allow-fail

step "mkdir -p: bütün yolu bir əmrlə" \
  --why "-p ara qovluqları avtomatik yaradır və qovluq artıq varsa xəta vermir — skriptlər üçün idealdır." \
  --cmd 'mkdir -p srv/myapp/releases; mkdir -p srv/myapp/releases; echo "ikinci dəfə də xətasız: $?"; ls srv/myapp' \
  --explain "-p|parents: lazım olan bütün ara qovluqları yarat" \
  --explain "\$?|son əmrin çıxış kodu (0 = uğurlu)" \
  --expect "ikinci dəfə də xətasız: 0 və releases" \
  --assert 'test -d srv/myapp/releases'

step "Brace expansion ilə bütün struktur" \
  --why "Real layihədə 10+ qovluq lazımdır. {a,b,c} yazılışı bir əmrlə hamısını yaradır." \
  --cmd 'mkdir -p srv/myapp/{releases,shared,backups,failed}
mkdir -p opt/myapp/{logs/2024,config,scripts,tmp}
mkdir -p var/log/myapp/{api,worker,web}
ls srv/myapp opt/myapp var/log/myapp' \
  --explain "{a,b,c}|shell əmri çalışmamış hər variant üçün ayrıca yola açır" \
  --explain "logs/2024|brace-in içində də alt yol ola bilər" \
  --expect "srv/myapp: backups failed releases shared; opt/myapp: config logs scripts tmp" \
  --note "Qovluq adlarında boşluq işlətməyin — _ və ya - işlədin. Boşluqlu ad hər əmrdə dırnaq tələb edir." \
  --assert 'test -d opt/myapp/logs/2024 && test -d var/log/myapp/worker && test -d srv/myapp/shared'

step "Strukturu yoxla: ls -R" \
  --why "Yaratdıqdan sonra yoxlamaq vərdişi: nə yaratdığınıza əmin olun." \
  --cmd 'ls -R opt' \
  --explain "-R|alt qovluqlara da gir (recursive)" \
  --expect "opt: myapp; opt/myapp: config logs scripts tmp; opt/myapp/logs: 2024 və s." \
  --assert 'ls -R opt | grep -q "^opt/myapp/logs:$"'

step "Ağac görünüşü: find (tree-nin alternativi)" \
  --why "tree hər serverdə yoxdur, find isə hər yerdə var. Yalnız qovluqları sıralı göstərmək üçün." \
  --cmd 'find srv opt var -type d | sort' \
  --explain "find yol|yolun altında hər şeyi gəzir" \
  --explain "-type d|yalnız qovluqlar (d=directory, f=fayl)" \
  --explain "| sort|əlifba sırası ilə (çıxış hər dəfə eyni olsun)" \
  --expect "srv, srv/myapp, srv/myapp/backups ... ardıcıl tam yollar" \
  --assert '[ "$(find srv opt var -type d | wc -l)" -eq 19 ]'

step "Qovluğa gir və yerini yoxla (cd, pwd)" \
  --why "Qovluğa girmək üçün cd, harada olduğunuzu bilmək üçün pwd. Silmə əmrlərindən əvvəl bu vərdiş həyat qurtarır." \
  --cmd 'cd srv/myapp/releases; pwd; mkdir v1.0.0 v1.0.1; ls; cd - > /dev/null; pwd' \
  --explain "cd yol|qovluğa keç" \
  --explain "cd -|əvvəlki qovluğa qayıt" \
  --expect "iş qovluğu/srv/myapp/releases, v1.0.0 v1.0.1, sonra yenə kök iş qovluğu" \
  --assert 'test -d srv/myapp/releases/v1.0.1 && pwd | grep -q "/s07$"'

task "Backup qovluqları" \
  "Bir əmrlə srv/myapp/backups/daily, srv/myapp/backups/weekly və srv/myapp/backups/monthly qovluqlarını yaradın." \
  --check 'for d in daily weekly monthly; do test -d srv/myapp/backups/$d || exit 1; done' \
  --hint "mkdir -p yol/{a,b,c}" \
  --solution 'mkdir -p srv/myapp/backups/{daily,weekly,monthly}'

task "Yeni servis qovluğu" \
  "var/log/payments altında api, worker alt qovluqlarını yaradın (var/log/payments hələ yoxdur)." \
  --check 'test -d var/log/payments/api && test -d var/log/payments/worker' \
  --hint "Ana qovluq yoxdur, ona görə mkdir -p lazımdır." \
  --solution 'mkdir -p var/log/payments/{api,worker}'

task "Hər mühit üçün konfiq" \
  "opt/myapp/config altında dev, staging, prod qovluqlarını yaradın. Sonra hər birinin içində boş app.env faylı olsun." \
  --check 'for e in dev staging prod; do test -d opt/myapp/config/$e && test -f opt/myapp/config/$e/app.env || exit 1; done' \
  --hint "Əvvəlcə mkdir -p ... {dev,staging,prod}, sonra touch ... /{dev,staging,prod}/app.env" \
  --solution 'mkdir -p opt/myapp/config/{dev,staging,prod}; touch opt/myapp/config/{dev,staging,prod}/app.env'

lab_summary "Sessiya 08 — Fayl və qovluq silmək (rm, rmdir, rm -r)" \
  "mkdir ad / mkdir a b c — qovluq yaratmaq" \
  "mkdir -p yol/{a,b} — iç-içə struktur, təkrar işlətsən də xətasız" \
  "ls -l (d), ls -R, find -type d — strukturu yoxlamaq" \
  "standart quruluş: srv/APP/{releases,shared,backups}, opt/APP/{logs,config}"
