#!make

# in some circumstances git_ref_name may be "" empty string
# such as during codespace prebuilds
git_ref_name ?= $(shell git rev-parse --abbrev-ref HEAD || echo latest)
# above git ref may not be valid docker tag
tag_from_git_ref_name := $(shell echo ${git_ref_name} | sed 's/[^a-zA-Z0-9._-]/-/g')
export TAG_FROM_GIT_REF_NAME=$(tag_from_git_ref_name)
tag_from_git_sha ?= latest
# this can be conveniently overwritten for --print and metadata file
export TAG_FROM_GIT_SHA=$(tag_from_git_sha)
# placeholder to be overwritten with --print for debugging etc
bake_args ?= --progress auto
can_push := false
export CAN_PUSH=$(can_push)
bake_targets := "builder" "developer"
smoke_test_jobs := $(addprefix smoke-test-,${bake_targets})
gh_token ?= $(shell gh auth token || echo ${GITHUB_PAT})

.PHONY: all
all: bake

.PHONY: bake
## Build all docker images
bake:
	GH_TOKEN=$(gh_token) \
	docker buildx bake \
		--file docker-bake.hcl \
		--file .env \
		$(bake_args)

bake-multiarch-cache:
	GH_TOKEN=$(gh_token) \
	CAN_CACHE=true \
		docker buildx bake \
			--file docker-bake.hcl \
			--file .env \
			--set=*.platform='$(ARCH)' \
			--set=*.output="type=image,push=false" \
			$(bake_args)

.DEFAULT_GOAL := show-help

.PHONY: rdeps
## Install R package dependencies
rdeps: rdeps-hard
	Rscript -e \
		"pak::local_install_deps()"

rdeps-hard: DESCRIPTION
	Rscript -e \
		"pak::local_install_deps(dependencies = TRUE)"

.PHONY: install
## Install R package
install: roxygenise
	Rscript \
		-e "pak::local_install()"

.PHONY: roxygenise
## Run roxygen
# hack is the easiest crossplatform way I could think of;
# sed -i won't play nice with macOS
# needs to run twice under some circumstances
roxygenise:
	Rscript -e "roxygen2::roxygenise()"
	Rscript -e "roxygen2::roxygenise()"
	grep -v '^RoxygenNote:' DESCRIPTION > DESCRIPTION_clean
	rm DESCRIPTION
	mv DESCRIPTION_clean DESCRIPTION

# from https://gist.github.com/klmr/575726c7e05d8780505a
.PHONY: show-help
show-help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) == Darwin && echo '--no-init --raw-control-chars')
