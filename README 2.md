# Java Docker Multi-Stage Build Demo

A small Spring Boot app (one REST endpoint) packaged into Docker **4 different ways**,
so you can see how the image size drops step by step.

## The 4 versions

| # | Dockerfile | What it does | Rough size* |
|---|------------|--------------|-------------|
| 1 | `Dockerfile.1-single-stage` | Builds and runs in the same Maven + JDK image. Build tools and Maven cache stay inside. | ~550–650 MB |
| 2 | `Dockerfile.2-multistage-jre` | Builds in Maven image, then copies **only the jar** into a JRE (Ubuntu) image. | ~280–300 MB |
| 3 | `Dockerfile.3-multistage-alpine` | Same, but runs on a JRE built on **Alpine** Linux. Runs as non-root. | ~200–220 MB |
| 4 | `Dockerfile.4-multistage-jlink` | 3 stages: builds the jar, builds a **custom mini Java** with `jlink`, puts both on plain Alpine. | ~100–130 MB |

\* These are typical numbers, not measured here. Run the script to get your real ones.

## The simple idea behind multi-stage

```
Stage 1 (build)              Stage 2 (run)
┌─────────────────────┐      ┌──────────────────┐
│ Maven + full JDK    │      │ Small JRE only   │
│ ~/.m2 libraries     │      │                  │
│ source code         │      │                  │
│ app.jar  ───────────┼─COPY─▶ app.jar          │
└─────────────────────┘      └──────────────────┘
   thrown away                  this is shipped
```

Only the last `FROM` becomes your final image. Everything in earlier stages is
used during the build and then discarded.

## How to run

You need Docker installed. No Java or Maven needed on your laptop — the build happens inside Docker.

```bash
chmod +x compare-sizes.sh
./compare-sizes.sh            # build all 4 and print a size table
./compare-sizes.sh --test     # also start each one and check it responds
```

Run one version by hand:

```bash
docker build -f Dockerfile.3-multistage-alpine -t hello-app:alpine .
docker run -p 8080:8080 hello-app:alpine
curl http://localhost:8080/
```

## Extra things to try

- `docker history hello-app:1-single-stage` vs `docker history hello-app:2-multistage-jre`
  — shows which layer is taking the space.
- Change one line in `HelloApplication.java` and rebuild version 2. The
  `dependency:go-offline` layer is cached, so the rebuild is much faster.
- In version 4, remove a module like `java.desktop` from the `jlink` list and see
  the app fail at startup — this shows why the module list matters.
