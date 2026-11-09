---
marp: true
theme: default
paginate: true
backgroundColor: "#F7F9F8"
color: "#0F172A"
style: |
  section {
    font-family: 'Segoe UI', Arial, sans-serif;
    padding: 24px 44px;
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
    box-sizing: border-box;
    overflow: hidden;
    background-color: #F7F9F8;
    color: #0F172A;
  }
  h1 { color: #00A859; font-size: 1.65em; margin: 0 0 6px 0; }
  h2 { color: #00A859; font-size: 1.2em; border-bottom: 2px solid #00A859; padding-bottom: 5px; margin: 0 0 8px 0; }
  h3 { color: #0F172A; font-size: 0.95em; margin: 5px 0; }
  strong { color: #00A859; }
  em { color: #848688; font-style: normal; }
  code { background: #E8F5EE; color: #00703A; padding: 2px 5px; border-radius: 4px; font-size: 0.78em; border: 1px solid #C3E4D0; }
  pre { background: #0F172A; color: #E2E8F0; padding: 8px 12px; border-radius: 8px; border-left: 4px solid #00A859; font-size: 0.50em; line-height: 1.4; margin: 5px 0; overflow: hidden; }
  pre code { font-size: 1em; padding: 0; background: transparent; color: #A7F3D0; border: none; }
  table { width: 100%; border-collapse: collapse; font-size: 0.8em; }
  th { background: #00A859; color: #ffffff; padding: 6px 10px; text-align: left; }
  td { background: #ffffff; padding: 6px 10px; border-bottom: 1px solid #D1E8DC; color: #0F172A; }
  tr:nth-child(even) td { background: #F0FAF4; }
  .columns { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
  .columns pre { font-size: 0.48em; }
  blockquote { border-left: 4px solid #00A859; background: #E8F5EE; padding: 8px 14px; margin: 6px 0; border-radius: 0 8px 8px 0; color: #0F172A; font-style: normal; font-size: 0.84em; }
  ul { line-height: 1.55; margin: 5px 0; }
  li { margin-bottom: 2px; font-size: 0.86em; }
  br { display: block; margin: 4px 0; content: ''; }
  section::after { color: #848688; font-size: 0.75em; }
  .ai-box { background: #FFF8E1; border: 2px solid #F59E0B; border-radius: 10px; padding: 12px 16px; margin: 10px 0; font-size: 0.85em; }
  .ai-box h3 { color: #B45309; margin: 0 0 6px 0; font-size: 0.95em; }
  .ai-tip { background: #FFF8E1; border-left: 4px solid #F59E0B; padding: 8px 14px; margin: 8px 0; border-radius: 0 6px 6px 0; font-size: 0.82em; color: #78350F; }
  section img { display: block; margin: 6px auto; background: transparent; }
  section img.emoji, section img[data-marp-twemoji] { display: inline; margin: 0 2px; height: 1em; width: 1em; vertical-align: -0.12em; }
  pre code .hljs-attr, pre code .hljs-attribute, pre code .hljs-section, pre code .hljs-keyword, pre code .hljs-name, pre code .hljs-selector-tag { color: #7DD3FC; }
  pre code .hljs-string, pre code .hljs-bullet, pre code .hljs-symbol { color: #FCD34D; }
  pre code .hljs-comment, pre code .hljs-quote { color: #94A3B8; }
  pre code .hljs-number, pre code .hljs-literal, pre code .hljs-regexp { color: #F9A8D4; }
  pre code .hljs-variable, pre code .hljs-template-variable, pre code .hljs-meta, pre code .hljs-built_in, pre code .hljs-params { color: #A7F3D0; }
  pre code .hljs-title, pre code .hljs-type, pre code .hljs-class, pre code .hljs-function { color: #C4B5FD; }
  pre code .hljs-operator, pre code .hljs-punctuation, pre code .hljs-subst { color: #E2E8F0; }
---

# 🗺️ ip r — Routing Cədvəli

## Paket haraya gedir? — sadə izah, addım-addım

```bash
$ ip r
default via 192.168.0.1 dev ens33 proto static
192.168.0.0/24 dev ens33 proto kernel scope link src 192.168.0.31
```

DataCras DevOps & Platform Engineering · Linux Modulu · Sessiya 26B · Chapter 7 — Networking

---

## 📮 Əsas ideya — poçt analogiyası

| Həyatda | Şəbəkədə |
|---|---|
| Sən məktub göndərirsən | server **paket** göndərir |
| Məktubun ünvanı | **təyinat IP** (məs. `8.8.8.8`) |
| Öz küçən | **eyni şəbəkə** (birbaşa çatırsan) |
| Poçt şöbəsi | **gateway** (router) — başqa şəbəkələrə aparan qapı |
| "Hansı ünvan hansı yolla gedir" siyahısı | **routing cədvəli** → `ip r` |

> Server **hər paketdən əvvəl** bir sual verir: *"Bu ünvan mənim öz şəbəkəmdədir?"*
> **Hə** → paketi birbaşa ver. **Yox** → **gateway**-ə ver, o özü yolu tapsın.

`ip r` bu qərarın **qaydalar siyahısıdır**.

---

## 🔢 Əvvəl: "mənim şəbəkəm" nədir? — `ip a` yada sal

```bash
$ ip a show ens33 | grep "inet "
    inet 192.168.0.31/24 brd 192.168.0.255 scope global ens33     ← mənim IP-m / şəbəkə ölçüsü
```

`/24` = IP-nin **ilk 24 biti şəbəkəni göstərir** → `192.168.0.`**`x`** hamısı **bir şəbəkədir** (`192.168.0.0 – 192.168.0.255`).

| Təyinat IP | Mənim şəbəkəmdədir? | Nə edəcəyəm |
|---|---|---|
| `192.168.0.15` | ✅ hə (`192.168.0.x`) | birbaşa göndər |
| `192.168.1.15` | ❌ yox (`192.168.1.x`) | gateway-ə ver |
| `8.8.8.8` | ❌ yox | gateway-ə ver |

> Bu **bizim serverin real şəbəkəsidir**: interfeys `ens33`, IP `192.168.0.31/24`. `/24` = 256 ünvan, `/16` = 65 536 ünvan. Ətraflı: CIDR (Sessiya 40).

---

## ⌨️ `ip r` — bizim serverdə ilk baxış

```bash
$ ip r                        # tam forma: ip route
default via 192.168.0.1 dev ens33 proto static
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown
172.18.0.0/16 dev br-f737038b2048 proto kernel scope link src 172.18.0.1 linkdown
172.19.0.0/16 dev br-dc61628e4e9b proto kernel scope link src 172.19.0.1 linkdown
192.168.0.0/24 dev ens33 proto kernel scope link src 192.168.0.31
```

- **5 sətir = 5 qayda.** Hər sətir bir sualın cavabıdır: *"bu təyinat üçün paketi hara verim?"*
- **Əsas ikisi:** **1-ci sətir** (`default` → gateway `192.168.0.1`) və **son sətir** (öz şəbəkəm `192.168.0.0/24` → birbaşa `ens33`)
- **Ortadakı 3 sətir = Docker.** Docker öz virtual şəbəkələrini (`docker0`, `br-…`) yaradıb. `linkdown` = hazırda qoşulu konteyner yoxdur — bunlar bizi maraqlandırmır

> **Real serverdə `ip r`-də hər zaman əlavə sətirlər olur** (Docker, VPN, əlavə şəbəkələr). Əsas qayda: **`default` və öz şəbəkəni tap**, qalanını oxu.

---

## 🔍 Sətir 1: `default via 192.168.0.1 dev ens33`

```
default      via 192.168.0.1      dev ens33
   │              │                  │
 "hər yer"    "bu gateway-ə ver"   "bu interfeysdən çıx"
```

| Söz | Mənası |
|---|---|
| `default` | **başqa heç bir qaydaya uyğun gəlməyən hər şey** (= `0.0.0.0/0`). İnternet buradan gedir |
| `via 192.168.0.1` | paketi bu **gateway**-ə (router-ə) ver |
| `dev ens33` | bu **şəbəkə kartı** ilə göndər |
| `proto static` | qayda **konfiqdən/əl ilə** yazılıb (bizdə netplan), kernel özü yaratmayıb |

> **default gateway** = `ip r`-də `default via …` sətrindəki IP. "Default gateway nədir?" sualının cavabı budur.

---

## 🔍 Sətir 2: öz şəbəkəm üçün qayda

```
192.168.0.0/24 dev ens33 proto kernel scope link src 192.168.0.31
```

| Hissə | Mənası |
|---|---|
| `192.168.0.0/24` | **şəbəkə**: `192.168.0.0 – 192.168.0.255` |
| `dev ens33` | bu şəbəkəyə `ens33`-dan çıx |
| `via` **yoxdur** | gateway lazım deyil — **birbaşa çatırıq** |
| `proto kernel` | bu qaydanı **kernel özü yaratdı** (IP verəndə avtomatik) |
| `scope link` | yalnız **eyni şəbəkə seqmentində** (bir kabelin/switch-in üstündə) |
| `src 192.168.0.31` | paketdə **göndərən** kimi **mənim IP**-m yazılacaq |

> Əsas fərq: 1-ci sətirdə **`via` var** (gateway lazımdır), 2-ci sətirdə **yoxdur** (birbaşa).

---

## 🧭 Paket hara gedir? — qərar yolu

```
paketin təyinatı: 192.168.0.15           paketin təyinatı: 8.8.8.8
        │                                        │
 192.168.0.0/24-ə uyğundur? ✅ HƏ         192.168.0.0/24-ə uyğundur? ❌ YOX
        │                                        │
 → birbaşa ens33-dan göndər              → default qaydası: gateway 192.168.0.1-ə ver
   (gateway lazım deyil)                  (o, internetə ötürəcək)
```

| Təyinat | Qalib qayda | Yol |
|---|---|---|
| `192.168.0.15` | `192.168.0.0/24 dev ens33` | **birbaşa** |
| `8.8.8.8` | `default via 192.168.0.1` | **gateway** vasitəsilə |
| `10.0.0.5` | `default via 192.168.0.1` | **gateway** (başqa şəbəkədir) |

---

## 🎯 `ip route get <ip>` — kernel-dən birbaşa soruş

Cədvəli əllə oxumaq əvəzinə **"bu IP-yə hansı yolla gedərdin?"** deyə soruşa bilərsən:

```bash
$ ip route get 192.168.0.9          # eyni şəbəkə
192.168.0.9 dev ens33 src 192.168.0.31

$ ip route get 8.8.8.8             # internet
8.8.8.8 via 192.168.0.1 dev ens33 src 192.168.0.31
```

- `via` **yoxdur** → birbaşa. `via` **var** → gateway vasitəsilə
- `src` → paketdə yazılacaq **mənim** IP-m
- **Route yoxdursa:** `RTNETLINK answers: Network is unreachable`
- Real çıxışın sonunda `uid …` və `cache` də ola bilər — vacib olan ilk sətirdir

> Ən faydalı diaqnostika əmri: "bu IP-yə niyə çata bilmirəm?" sualına birbaşa cavab verir.

---

## 🥇 Bir neçə qayda uyğun gəlsə? — ən dəqiq olan qalib

Hipotetik cədvəl:

```
default       via 192.168.0.1  dev ens33      ← /0   (ən geniş)
10.0.0.0/16   via 192.168.0.50  dev ens33      ← /16
10.0.0.0/24   via 192.168.0.60 dev ens33      ← /24  (ən dəqiq)
```

`10.0.0.5` üçün **hər üç** qayda uyğundur. Kim qalib gəlir?

| Qayda | Uyğundur? | Prefiks |
|---|---|---|
| `default` (`/0`) | ✅ | ən qısa |
| `10.0.0.0/16` | ✅ | orta |
| `10.0.0.0/24` | ✅ | **ən uzun** ← **qalib** → gateway `192.168.0.60` |

> **Qayda:** *ən uzun prefiks* (ən dəqiq uyğunluq) qalib gəlir. `default` yalnız **heç bir başqa qayda uyğun gəlməyəndə** işləyir.

---

## 🆕 `ip` ilə IP ünvanı əlavə etmək və silmək

```bash
ip a show ens33 | grep "inet "                      # əvvəl: 1 IP
    inet 192.168.0.31/24 … scope global ens33

sudo ip addr add 192.168.0.200/24 dev ens33           # ikinci IP əlavə et  (qısa: ip a add)
ip a show ens33 | grep "inet "
    inet 192.168.0.31/24 … scope global ens33
    inet 192.168.0.200/24 scope global secondary ens33     ← əlavə (secondary) IP

sudo ip addr del 192.168.0.200/24 dev ens33           # sil
```

| Hissə | Mənası |
|---|---|
| `ip addr add <IP>/<prefiks>` | interfeysə **əlavə IP** ver |
| `dev ens33` | hansı **şəbəkə kartına** |
| `secondary` | **əlavə** IP — əsas IP (`192.168.0.31`) **dəyişmir**, yanına yenisi gəlir |

> **Bir şəbəkə kartında bir neçə IP ola bilər** — evə əlavə nömrə vermək kimi. ❗ Verdiyin IP **başqa cihazda işlənirsə** → *IP konflikti*: hər iki cihazın əlaqəsi pozulur. `ip addr add` da `ip route add` kimi **müvəqqətidir** (reboot-da itir). 🔒 Bu serverdə tələbələrdə `sudo` yoxdur — **müəllim göstərir**.

---

## 🤔 IP əlavə etmək nə vaxt lazım olur?

<style scoped>td, th { padding: 5px 10px; font-size: 0.8em; }</style>

| Vəziyyət | Nümunə |
|---|---|
| **Bir serverdə bir neçə servis, ayrı IP** | 1-ci sayt `192.168.0.31:443`, 2-ci sayt `192.168.0.200:443` — eyni port, fərqli IP |
| **Virtual / floating IP (HA)** | iki server var; əsas çöksə **ikincisi eyni IP-ni özünə əlavə edir** (keepalived) — istifadəçi fərq görmür |
| **Köç (migration)** | servisi yeni IP-yə keçirirsən, amma **köhnə IP də bir müddət işləsin** — ikisi paralel |
| **Test / lab** | serveri başqa şəbəkədən gələn trafiklə sınamaq üçün müvəqqəti IP |
| **Qurtarma (rescue)** | şəbəkə konfiqi pozulub; konsoldan müvəqqəti `ip addr add` + `ip route add default` edib içəri girirsən |
| **Docker / Kubernetes** | konteyner şəbəkəsini qurarkən interfeyslərə IP-ni **avtomatik əlavə edən** də eyni mexanizmdir |

> Qısa: **`ip addr add` = bu şəbəkə kartı artıq bu ünvanda da cavab versin.** Çox vaxt əlavə IP ilə birgə **route** da lazım olur (növbəti slaydlar).

---

## 🧪 Təhlükəsiz məşq: `dummy0` — saxta interfeys

`ens33`-a toxunmadan öyrənmək üçün **virtual** interfeys yaradırıq (SSH kəsilməz). 🔒 `sudo` lazımdır — serverdə **müəllim göstərir**:

```bash
sudo ip link add dummy0 type dummy             # saxta interfeys yarat
sudo ip link set dummy0 up                     # aktiv et
sudo ip addr add 10.77.0.1/24 dev dummy0       # ona IP ver
ip -br a show dummy0                           # dummy0  UNKNOWN  10.77.0.1/24 …
ip r                                           # yeni sətir:
10.77.0.0/24 dev dummy0 proto kernel scope link src 10.77.0.1
ip route get 10.77.0.9                         # 10.77.0.9 dev dummy0 src 10.77.0.1
sudo ip link del dummy0                        # təmizlə — IP və route özü silinir
```

- **Maraqlı:** IP əlavə edən kimi **kernel özü route yaratdı** (`proto kernel`) — 2-ci sətir belə yaranır!
- `UNKNOWN` — virtual interfeysdə normaldır. `ip link del dummy0` hər şeyi geri qaytarır

---

## ✏️ Route əlavə etmək və silmək — əmrlər

```bash
sudo ip route add 10.0.0.0/24 via 192.168.0.1 dev ens33     # əlavə et
ip r                                                       # yoxla
ip route get 10.0.0.5                                      # həqiqətən bu yolla gedirmi?
sudo ip route del 10.0.0.0/24                              # sil
```

| ⚠ Diqqət | Niyə |
|---|---|
| **Müvəqqətidir** | reboot-dan sonra **itir** (daimi üçün: `netplan` — növbəti slaydlarda) |
| **`default`-u silmə!** | SSH ilə qoşulubsansa, **əlaqə kəsilər** |
| **Gateway birbaşa çatılan olmalıdır** | `via` göstərilən IP **eyni şəbəkədə** olmalıdır |

| Xəta | Mənası |
|---|---|
| `RTNETLINK answers: File exists` | belə route **artıq var** (əvvəl `ip r` ilə bax, lazımsa `replace`) |
| `RTNETLINK answers: No such process` | silinəcək route **yoxdur** |
| `Error: Nexthop has invalid gateway.` | `via` IP-sinə **birbaşa çatmaq olmur** (şəbəkə uyğun deyil) |

> 🔒 Bu serverdə **müəllim göstərir** (tələbələrdə `sudo` yoxdur). Production-da yalnız test VM-də sına.

---

## 🤔 Route niyə əlavə edirik?

Problem: **`default` yalnız internetə aparır.** Server başqa şəbəkəyə də çatmalıdırsa, ona **ayrıca qayda** lazımdır:

```
        ┌─ ens33  192.168.0.31/24 ─> gateway 192.168.0.1  ─> İNTERNET          (default)
SERVER ─┤
        └─ ens34  10.20.0.1/24  ─> router  10.20.0.254 ─> DAXİLİ ŞƏBƏKƏ 10.0.0.0/24
```

| Ssenari | Əlavə edilən route |
|---|---|
| **İki şəbəkəli server** (internet + daxili/DB) | `10.0.0.0/24 via 10.20.0.254` |
| **VPN** (məs. WireGuard) | `10.8.0.0/24 dev wg0` — VPN şəbəkəsinə VPN interfeysindən |
| **Başqa ofis/subnet üçün xüsusi router** | `192.168.50.0/24 via 192.168.0.254` |
| **Trafiki bloklamaq** | `blackhole 203.0.113.0/24` — həmin şəbəkəyə paket getməsin |
| **Müvəqqəti test** | trafiki başqa yoldan keçirib nəticəni yoxlamaq |

> Route olmasa paket `default`-a düşür — **yanlış yerə** gedir.

---

## 🗑️ Route niyə silirik və ya dəyişirik?

| Vəziyyət | Nə baş verir | Həll |
|---|---|---|
| **Səhv yazılıb** (yanlış gateway/mask) | paketlər yanlış yerə gedir | `ip route del …` → düzgününü əlavə et |
| **Köhnə ("ölü") route qalıb** | VPN/şəbəkə söndü, route qaldı → həmin trafik **itir** | `ip route del …` |
| **İki qayda toqquşur** | daha dəqiq (uzun prefiks) **səhv qayda** qalib gəlir | səhv qaydanı sil |
| **Test bitdi** | müvəqqəti qayda lazım deyil | təmizlə |
| **Gateway dəyişdi** (yeni router) | köhnə gateway artıq cavab vermir | `ip route replace default via <yeni>` |

```bash
sudo ip route del 10.0.0.0/24                              # sil
sudo ip route replace default via 192.168.0.1 dev ens33      # varsa DƏYİŞİR, yoxdursa əlavə edir
```

> `replace` = "sil + əlavə et" **bir əmrlə**. ❗ `default`-u dəyişəndə **SSH kəsilə bilər**.

---

## 🎬 Canlı nümunə: daxili şəbəkəyə çatmaq

`dummy0` ilə **ikinci şəbəkə kartını** təqlid edirik və route-un qərarı necə dəyişdirdiyini görürük:

```bash
sudo ip link add dummy0 type dummy; sudo ip link set dummy0 up
sudo ip addr add 10.20.0.1/24 dev dummy0               # "daxili şəbəkə kartı"

ip route get 10.0.0.5                                  # ƏVVƏL
10.0.0.5 via 192.168.0.1 dev ens33 src 192.168.0.31        ← default (internet) gedir ❌

sudo ip route add 10.0.0.0/24 via 10.20.0.254 dev dummy0
ip route get 10.0.0.5                                  # SONRA
10.0.0.5 via 10.20.0.254 dev dummy0 src 10.20.0.1      ← daxili router-dən gedir ✅

sudo ip route del 10.0.0.0/24; sudo ip link del dummy0   # təmizlə
```

> 🔒 `sudo` tələb edir — **müəllim göstərir**. **`ip route get` real cihaz olmadan da qərarı göstərir** — ona görə route-ları əvvəl bununla yoxla, sonra real trafiklə.
> Yoxla: `ip r | grep 10.0.0` — yeni sətir əlavə oldu, silinəndən sonra yox oldu.

---

## 💾 Daimi etmək: `netplan` (Ubuntu)

`ip addr add` / `ip route add` **reboot-dan sonra itir**. Daimi üçün şəbəkə konfiqinə yazılır. Bizim serverdə **real fayl:** `/etc/netplan/99-netcfg-vmware.yaml`

```yaml
network:
  version: 2
  ethernets:
    ens33:
      dhcp4: no
      addresses:
        - 192.168.0.31/24               # əsas IP
        - 192.168.0.200/24              # ← əlavə IP nümunəsi
      routes:
        - to: default
          via: 192.168.0.1              # default gateway → ip r-də "proto static"
        - to: 10.0.0.0/24
          via: 192.168.0.254            # ← əlavə route nümunəsi
```

- **Tətbiq:** əvvəl `sudo netplan try` (120 san ərzində təsdiq etməsən köhnəyə **qayıdır** — SSH-ı qoruyur), sonra `sudo netplan apply`
- `ip r`-dəki `default via 192.168.0.1 … proto static` sətri məhz bu fayldan gəlir. RedHat/Amazon Linux-da: `nmcli`
- Əvvəl `ip` ilə **test et**, işləyirsə daimi yaz. 🔒 Real faylı yalnız müəllim dəyişir

---

## 🚑 Diaqnostika: `ping` işləmir — `ip r` nə deyir?

```bash
$ ping -c 1 8.8.8.8
ping: connect: Network is unreachable      ← route YOXDUR (ip r-də default yoxdur)

$ ping -c 1 10.99.99.99
1 packets transmitted, 0 received, 100% packet loss   ← route var, amma hədəf cavab vermir
```

| Simptom | Səbəb | `ip r` nə göstərir | Nə et |
|---|---|---|---|
| `Network is unreachable` | paket üçün **route yoxdur** | `default` sətri **yoxdur** | gateway əlavə et / şəbəkə konfiqini yoxla |
| `100% packet loss` | route var, hədəf/yol **cavab vermir** | `default via …` var | gateway-ə `ping` at, hədəf serveri, firewall-u yoxla |
| yalnız **internet** yoxdur | gateway səhvdir / çatılmır | `default via <səhv IP>` | `ping <gateway>` — çatırsa, yuxarıda problem var |
| yalnız **bir şəbəkəyə** çata bilmirsən | o şəbəkə üçün route yoxdur | həmin subnet **yoxdur** | `ip route add …` və ya router-dən xahiş et |

---

## 🧰 Faydalı variantlar və köhnə əmr

```bash
ip r                        # qısa forma (ip route)
ip route show default       # yalnız default gateway
ip r | grep default         # eyni şey, grep ilə
ip -4 r                     # yalnız IPv4
ip r show dev ens33          # yalnız ens33 üzrə qaydalar
route -n                    # KÖHNƏ (net-tools); eyni məlumat, başqa formatda
```

| `ip r` | `route -n` (köhnə) |
|---|---|
| `default via 192.168.0.1` | `0.0.0.0  192.168.0.1  0.0.0.0  UG` |
| `192.168.0.0/24 dev ens33` | `192.168.0.0  0.0.0.0  255.255.255.0  U` |

- `route -n`: `0.0.0.0` = default · **Flags** `U` = aktiv, `G` = gateway var. `Genmask 255.255.255.0` = `/24`
- Yeni kodda `ip r` işlət. `route`-u yalnız köhnə sistemlərdə **tanımaq** üçün bil

---

## 🧪 Praktik tapşırıqlar — A. hər kəs (`sudo`-suz)

```bash
# 1. Cədvələ bax — neçə sətir var? Hansılar Docker-dir?
ip r

# 2. Default gateway IP-sini tap
ip route show default

# 3. Kernel-dən soruş: eyni şəbəkədəki IP? internet? Docker şəbəkəsi?
ip route get 192.168.0.9
ip route get 8.8.8.8
ip route get 172.17.0.5

# 4. Gateway-ə ping at (çatırmı?)
ping -c 2 $(ip route show default | awk '{print $3}')

# 5. Öz IP-ni və interfeysini tap
ip -br a show ens33
```

> ❗ `ens33`-ün IP-sinə və **`default` route-a toxunma** — SSH əlaqə kəsilər. Bu serverdə hamı eyni maşındadır.

---

## 🧪 Praktik tapşırıqlar — B. müəllim göstərir (🔒 `sudo`)

`dummy0` üzərində (real `ens33`-ə toxunmur):

```bash
sudo ip link add dummy0 type dummy && sudo ip link set dummy0 up
sudo ip addr add 10.77.0.1/24 dev dummy0
ip r | grep dummy0                       # kernel route-u özü yaratdı

sudo ip route add 10.0.0.0/24 via 10.77.0.254 dev dummy0
ip route get 10.0.0.5                    # via 10.77.0.254 dev dummy0

sudo ip route add 10.0.0.0/24 via 10.77.0.254 dev dummy0    # File exists
sudo ip route del 10.55.0.0/24                              # No such process

sudo ip link del dummy0                  # hamısını təmizlə
```

> Tələbələr bunu **öz `sudo`-lu VM-lərində** təkrar edə bilərlər (Ubuntu VM, VirtualBox).

---

## 🤖 Bu mövzu üçün AI prompt-lar

```
💬 Çıxışı izah et:
"ip r çıxışım buradadır: <yapışdır>. Hər sətri sadə dillə izah et:
 default gateway hansıdır, mənim şəbəkəm hansıdır?"

💬 Diaqnostika:
"ping 10.0.0.5 işləmir. ip r və ip route get 10.0.0.5 çıxışları budur: <yapışdır>.
 Route yoxdur, yoxsa gateway problemidir? Necə ayırd edim?"

💬 Ssenari:
"Serverin ens33 (internet) və ens34 (10.20.0.0/24 daxili) kartları var. 10.0.0.0/24
 şəbəkəsinə çatmalıyam, router 10.20.0.254-dür. Hansı ip route əmrini yazım və
 daimi etmək üçün netplan-da necə göstərim?"

💬 Anlamaq:
"ən uzun prefiks qaydasını 3 route nümunəsi ilə izah et və hansının qalib gəldiyini göstər."
```

> ★ **AI Tip:** `ip r`, `ip a` və `ping` çıxışını **birlikdə** göndər. Amma **əmri icra etməzdən əvvəl** nə edəcəyini özün başa düş — xüsusilə `ip route del`, `ip addr del`, `default`-a toxunan hər şeyi.

---

## 📝 Xülasə — `ip r` və IP/route idarəsi bir baxışda

```
   ip r                         →  routing cədvəli: "hansı təyinat → hansı yolla"
   default via <GW> dev <IF>    →  başqa hər yerə: gateway-ə ver (internet)
   <şəbəkə>/<N> dev <IF> …      →  öz şəbəkəm: BİRBAŞA (via yoxdur)
   ip route get <ip>            →  kernel-dən soruş: bu IP-yə hansı yolla?
   ən uzun prefiks qalib        →  ən dəqiq qayda seçilir
   ip addr add/del              →  interfeysə əlavə IP ver / al  (HA, köç, test)
   ip route add/del/replace     →  yeni şəbəkə / yanlış route / gateway dəyişikliyi
   Network is unreachable       →  route yoxdur  |  100% loss → route var, cavab yoxdur
   hamısı müvəqqətidir          →  daimi: netplan (əvvəl netplan try!) · default-u silmə!
```

**Növbəti:** Sessiya 27 — Telnet və portlar · Sessiya 40 — CIDR və routing (dərin)
