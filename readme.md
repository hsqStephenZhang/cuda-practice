## how to generate a new sub-project

1. install [`copier`](https://github.com/copier-org/copier) via `pip3 install copier`
2. install [`just`](https://github.com/casey/just/) by instructions.

run `./scripts/new_from_template.sh https://github.com/hsqStephenZhang/cuda-template.git name_of_your_proj`
for example, `./scripts/new_from_template.sh https://github.com/hsqStephenZhang/cuda-template.git 02-vec-add`

in each sub-dir, use `just build` `just run` to build/run the project. you may customize the just configuration.