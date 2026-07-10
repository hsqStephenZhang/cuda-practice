# 01-copy

A minimal CUDA hello-world project.

## Build

```bash
just build
```

`just build` only configures on the first run, or when `build/CMakeCache.txt` is missing.

## Run

```bash
just run
```

Or do both at once with:

```bash
just
```

## Profile

```bash
just profile-nsys
just profile-ncu-memory
just profile-ncu-full
```

## Format

```bash
just fmt
```
