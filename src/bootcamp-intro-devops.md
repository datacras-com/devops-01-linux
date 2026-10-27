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
  pre code .hljs-attr, pre code .hljs-section, pre code .hljs-keyword, pre code .hljs-name, pre code .hljs-selector-tag { color: #7DD3FC; }
  pre code .hljs-string, pre code .hljs-bullet, pre code .hljs-symbol { color: #FCD34D; }
  pre code .hljs-comment, pre code .hljs-quote { color: #94A3B8; }
  pre code .hljs-number, pre code .hljs-literal, pre code .hljs-regexp { color: #F9A8D4; }
  pre code .hljs-variable, pre code .hljs-template-variable, pre code .hljs-meta, pre code .hljs-built_in, pre code .hljs-params { color: #A7F3D0; }
  pre code .hljs-title, pre code .hljs-type, pre code .hljs-class, pre code .hljs-function { color: #C4B5FD; }
  pre code .hljs-operator, pre code .hljs-punctuation, pre code .hljs-subst { color: #E2E8F0; }
---

<!-- Slide 1: Title -->
# 🚀 DevOps & Platform Engineering
## Bootcamp-a Xoş Gəlmisiniz — İlk Dərs: Tanışlıq

```bash
$ whoami
future-devops-engineer
$ uptime
26 weeks of hands-on learning
```

> **DataCras DevOps & Platform Engineering — AI Assisted**
> Sıfırdan PROD-a hazır DevOps & Platform Engineer

---

<!-- Slide 2: Agenda -->
## 📋 Bu Gün Nə Danışacağıq?

1. **DevOps nədir?** — və nə deyil
2. **Niyə yaranıb?** — Dev və Ops arasındakı divar
3. **DevOps dövrü** — koddan istifadəçiyə qədər
4. **Platform Engineering** — növbəti addım
5. **Bootcamp xəritəsi** — 26 həftə, 9 blok
6. **Hər həftə necə keçir** — nəzəriyyə, lab, production ssenari
7. **Capstone və Bonus ay**
8. **Gözləntilər və ilk addımlar**

> Məqsəd bu gün alət öyrənmək yox, **bütöv mənzərəni görməkdir**.

---

<!-- Slide 3: DevOps nədir -->
## 🤔 DevOps Nədir?

**DevOps = Development + Operations**

> Proqram təminatını **tez**, **təhlükəsiz** və **təkrarlanan şəkildə** istifadəçiyə çatdırmaq üçün mədəniyyət, praktikalar və alətlər toplusu.

| Üç sütun | Mənası |
|---|---|
| **Mədəniyyət** | Komandalar arası əməkdaşlıq, ortaq məsuliyyət |
| **Praktikalar** | CI/CD, Infrastructure as Code, monitorinq |
| **Alətlər** | Git, Docker, Kubernetes, Terraform, Prometheus... |

> DevOps **vəzifə adı** da ola bilər, amma əsasən **iş üsuludur**.

---

<!-- Slide 4: Divar -->
## 🧱 Niyə Yaranıb? — Divar Problemi

![w:1100](img/devops-vs-silo.svg)

---

<!-- Slide 5: DevOps nə deyil -->
## ❌ DevOps Nə Deyil?

| Yanlış təsəvvür | Reallıq |
|---|---|
| "DevOps = Docker/Kubernetes öyrənmək" | Alətlər vasitədir, əsas **yanaşmadır** |
| "DevOps = sysadmin-in yeni adı" | Kod yazmaq, avtomatlaşdırmaq tələb olunur |
| "DevOps = ayrıca komanda, hər şeyi o edir" | Ortaq məsuliyyət, yeni divar yaratmaq deyil |
| "DevOps = sürət, keyfiyyət yox" | Sürət **və** etibarlılıq birlikdə |
| "Bir dəfə qurulur, bitir" | Davamlı təkmilləşmə dövrüdür |

---

<!-- Slide 6: Dövrü -->
## 🔄 DevOps Dövrü

![w:800](img/devops-loop.svg)

| Mərhələ | Nə baş verir | Bootcamp-da |
|---|---|---|
| Plan · Code | Tələblər, Git, branch strategiyası | Week 3 |
| Build · Test | CI pipeline, image build, scan | Week 4–5, 13 |
| Release · Deploy | CD, Helm, GitOps | Week 12–15 |
| Operate · Monitor | Kubernetes, observability, DR | Week 6–9, 21–24 |

---

<!-- Slide 7: CALMS və DORA -->
## 📏 DevOps-u Necə Ölçürük?

**CALMS çərçivəsi**

| C | A | L | M | S |
|---|---|---|---|---|
| Culture | Automation | Lean | Measurement | Sharing |

**DORA metrikləri** — komandanın çatdırılma performansı:

| Metrik | Sual |
|---|---|
| **Deployment frequency** | Nə qədər tez-tez deploy edirik? |
| **Lead time for changes** | Commit-dən production-a nə qədər vaxt keçir? |
| **Change failure rate** | Deploy-ların neçə faizi problem yaradır? |
| **MTTR** | Problem olanda nə qədər tez bərpa edirik? |

> Bu metriklərə Week 20-də (Platform Engineering) qayıdacağıq.

---

<!-- Slide 8: DevOps vs Platform -->
## 🏗️ DevOps → Platform Engineering

| | DevOps Engineer | Platform Engineer |
|---|---|---|
| **Fokus** | Pipeline, deploy, infrastruktur | Developer üçün **platforma** (məhsul kimi) |
| **Müştəri** | Komanda, tətbiq | Daxili developer-lər |
| **Nəticə** | Avtomatlaşdırılmış delivery | **Self-service**, "golden path" |
| **Alətlər** | CI/CD, IaC, K8s | + Backstage, Crossplane, CRD/Operator |

> Bu bootcamp **ikisini birləşdirir**: əvvəl DevOps təməli, sonra platforma qurmaq. Capstone: **Internal Developer Platform**.

---

<!-- Slide 9: Bootcamp haqqında -->
## 🎓 Bu Bootcamp Haqqında

| | |
|---|---|
| **Müddət** | 26 həftə + 1 bonus ay (pulsuz) |
| **Struktur** | 9 blok, hər həftə nəzəriyyə + praktika |
| **Hədəf** | Sıfırdan **production-grade** DevOps & Platform Engineer |
| **Final** | Capstone layihə + canlı GameDay müdafiəsi |

**Fərqləndirici cəhətlər:**
- **Production Failure Scenario** — hər həftə real incident
- **Failure Injection** — özün pozur, özün düzəldirsən
- **AI-Assisted Engineering** — debug, audit, config üçün prompt şablonları
- **Capstone** — işləyən Internal Developer Platform

---

<!-- Slide 10: Xəritə -->
## 🗺️ 26 Həftəlik Yol Xəritəsi

![w:1080](img/bootcamp-roadmap.svg)

---

<!-- Slide 11: Blok 1-3 -->
## 📚 Blok 1–3: Təməl, Konteynerlər, Kubernetes

| Blok | Həftələr | Nə öyrənəcəksən |
|---|---|---|
| **1 · Foundations** | 1–2 | Linux, proses, systemd, TCP/IP, DNS, `tcpdump`, firewall, SSH hardening |
| **2 · Containers** | 3–5 | Git internals, Docker, Podman/Buildah/Skopeo, Compose |
| **3 · Kubernetes Core** | 6–9 | Arxitektura, Deployment/StatefulSet, Service/Ingress, NetworkPolicy, PV/PVC |

> **Bu bloklar sonrakı hər şeyin təməlidir.** Linux zəif olsa, Kubernetes çətin olacaq.

---

<!-- Slide 12: Blok 4-6 -->
## 📚 Blok 4–6: IaC, CI/CD, Genişlənmə

| Blok | Həftələr | Nə öyrənəcəksən |
|---|---|---|
| **4 · IaC** | 10–12 | Terraform, Ansible, Kustomize, Helm |
| **5 · CI/CD & GitOps** | 13–15 | GitHub Actions / GitLab CI, Trivy, SBOM, cosign, ArgoCD, canary, Gateway API |
| **6 · Extensibility** | 16–18 | CRD, Operator, Admission Webhook, Vault, External Secrets, zero-trust |

---

<!-- Slide 13: Blok 7-9 -->
## 📚 Blok 7–9: Platforma, Etibarlılıq, Capstone

| Blok | Həftələr | Nə öyrənəcəksən |
|---|---|---|
| **7 · Platform Eng.** | 19–20 | Multi-tenancy, Backstage, Golden Path, Crossplane, DORA/SPACE |
| **8 · Observability, DR, Cost** | 21–24 | HPA/KEDA, Prometheus/Grafana/Loki/OTel, Velero, security hardening, Chaos Mesh |
| **9 · Capstone** | 25–26 | Internal Developer Platform + GameDay müdafiəsi |

---

<!-- Slide 14: Həftə necə keçir -->
## 📅 Hər Həftə Necə Keçir?

| Addım | Nə edirik |
|---|---|
| 1. **Nəzəriyyə** | Konsepti anlayırıq: niyə, necə işləyir |
| 2. **Canlı demo** | Təlimçi real mühitdə göstərir |
| 3. **Lab** | Sən özün quraşdırırsan, yazırsan, qırırsan |
| 4. **Production ssenari** | Real incident: timeline → araşdırma → root cause → fix |
| 5. **Failure injection** | Sistemi qəsdən pozub bərpa edirsən |
| 6. **AI prompt-lar** | AI ilə debug və audit, onu **yoxlamaq** bacarığı ilə |

> "Gecə saat 3-də problem olanda nə edəcəyini bilməyənə DevOps engineer demək olmaz."

---

<!-- Slide 15: Capstone -->
## 🏆 Capstone: Internal Developer Platform

Final layihə Kubernetes üzərində **işləyən platformadır**:

| Komponent | Məqsəd |
|---|---|
| **Tenant Controller** (operator) | Bir CR ilə namespace + RBAC + quota + NetworkPolicy |
| **Backstage portal** | Service catalog, golden path şablonları |
| **ArgoCD GitOps** | Git-ə push → klaster avtomatik sinxronlaşır |
| **CI/CD** | build → scan → SBOM → sign → push → deploy |
| **Vault + External Secrets** | Sirrlər Git-ə düşmür |
| **Observability + SLO** | Metrik, log, trace, error budget |
| **Velero + Chaos** | Backup/DR və dayanıqlıq sübutu |

> Üç səviyyə: **Core → Extended → Full IDP**. Müdafiə: arxitektura + canlı demo + GameDay.

---

<!-- Slide 16: Bonus ay -->
## 🎁 Bonus Ay — Karyera (Pulsuz)

| Həftə | Mövzu |
|---|---|
| **1** | Real layihə üzərində mentor ilə iş |
| **2** | Portfolio və GitHub profili |
| **3** | Müsahibəyə hazırlıq (texniki, sistem dizaynı, behavioral) |
| **4** | Mock müsahibələr, CV, karyera strategiyası |

---

<!-- Slide 17: Alətlər -->
## 🧰 Öyrənəcəyimiz Alətlər

| Kateqoriya | Alətlər |
|---|---|
| OS & Şəbəkə | Linux, systemd, iptables, SSH, DNS |
| Konteyner | Docker, Podman, containerd, Compose |
| Orkestrasiya | Kubernetes, Helm, Kustomize |
| IaC | Terraform, Ansible |
| CI/CD & GitOps | GitLab CI, GitHub Actions, ArgoCD, Trivy, cosign |
| Secrets & Security | Vault, External Secrets, RBAC, Falco |
| Platform | Backstage, Crossplane, CRD/Operator |
| Observability | Prometheus, Grafana, Loki, OpenTelemetry |
| Reliability | Velero, KEDA, Chaos Mesh |

---

<!-- Slide 18: Gözləntilər -->
## 🤝 Gözləntilər

**Bizdən sənə:**
- Real, production-a yaxın praktika
- Hər mövzuda "qırılanda nə edəcəyik" yanaşması
- Mentor dəstəyi və code review

**Səndən bizə:**
- **Hər həftə lab-ı özün et.** İzləmək öyrənmək deyil
- Xəta ilə qarşılaşanda **əvvəl log-a bax**, sonra sual ver
- AI-dən istifadə et, amma **nəticəni yoxla**
- Terminalla dost ol

> DevOps-da əsas bacarıq: **problemi sistemli araşdırmaq**.

---

<!-- Slide 19: İlk addımlar -->
## ✅ İlk Addımlar — Bu Həftə

| # | Tapşırıq |
|---|---|
| 1 | Linux mühitini hazırla (VM + SSH): **Chapter 1** materialları |
| 2 | Pre-work: əsas Linux əmrləri (**Session 00–14**) |
| 3 | GitHub və GitLab hesabı aç, SSH açarı yarat |
| 4 | Həftə 1-ə hazırlıq: `ping`, `curl`, `ss`, `systemctl` ilə tanış ol |
| 5 | Bir sualın var? Bütün gün qeyd et, növbəti dərsdə birlikdə baxarıq |

> **Növbəti dərs:** Week 1 — Linux & Networking Fundamentals

---

<!-- Slide 20: Q&A -->
## ❓ Suallar?

```
  ╔══════════════════════════════════════════════════════════╗
  ║  DevOps = mədəniyyət + praktika + alət                   ║
  ║  Məqsəd: dəyəri tez, təhlükəsiz çatdırmaq                ║
  ║  Dövr: Plan → Code → Build → Test → Release →            ║
  ║        Deploy → Operate → Monitor → (təkrar)             ║
  ║  26 həftə · 9 blok · capstone IDP · bonus karyera ayı    ║
  ║  Hər həftə: lab + production ssenari + failure injection ║
  ╚══════════════════════════════════════════════════════════╝
```

> **DataCras DevOps & Platform Engineering**
