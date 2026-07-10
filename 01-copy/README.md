# 01-copy

A minimal CUDA hello-world project.

## Build

```bash
just build
```

`just build` always regenerates the CMake build system before compiling, which avoids stale cache/layout issues on fresh clones or copied build directories.

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
