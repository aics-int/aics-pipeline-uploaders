# See https://tech.davis-hansson.com/p/make/
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

ifeq ($(origin .RECIPEPREFIX), undefined)
  $(error This Make does not support .RECIPEPREFIX. Please use GNU Make 4.0 or later)
endif
.RECIPEPREFIX = >

##############################################

PYTHON_VERSION = python3
VENV_NAME := venv
VENV_BIN := $(VENV_NAME)/bin
ACTIVATE = $(VENV_BIN)/activate
PYTHON = $(VENV_BIN)/python3

$(PYTHON):
> test -d $(VENV_NAME) || $(PYTHON_VERSION) -m venv --upgrade-deps $(VENV_NAME)

venv: $(PYTHON)

install: venv
> $(PYTHON) -m pip install --index-url='https://artifactory.corp.alleninstitute.org/artifactory/api/pypi/pypi-virtual/simple' --extra-index-url='https://artifactory.corp.alleninstitute.org/artifactory/api/pypi/pypi-snapshot-local/simple' . 
.PHONY: install

install-dev: venv install
> $(PYTHON) -m pip install .[dev]
> $(VENV_BIN)/pre-commit install
.PHONY: install-dev

lint:
> $(PYTHON) -m flake8 --count --show-source --statistics aics_pipeline_uploaders
.PHONY: lint

type-check:
> $(PYTHON) -m mypy --ignore-missing-imports  aics_pipeline_uploaders
.PHONY: type-check

fmt:
> $(PYTHON) -m black aics_pipeline_uploaders
.PHONY: fmt

import-sort:
> $(PYTHON) -m isort aics_pipeline_uploaders
.PHONY: import-sort

test:
> $(PYTHON) -m pytest aics_pipeline_uploaders/tests/
.PHONY: test

test-exclude-slow:
> $(PYTHON) -m pytest -m "not slow"
.PHONY: test-exclude-slow

clean:  # Clear proj dir of all .gitignored files
> git clean -Xfd -e "!.vscode"
.PHONY: clean

docs:
> source $(ACTIVATE) && sphinx-apidoc -f -o docs aics_pipeline_uploaders aics_pipeline_uploaders/tests
> source $(ACTIVATE) && sphinx-build -b html docs docs/build
.PHONY: docs

docs-serve:
> $(PYTHON) -m http.server --directory docs/build 8080
.PHONY: docs-serve

build: install
> rm -rf build/
> rm -rf dist/
> $(PYTHON) -m build
.PHONY: build

publish: build
> $(PYTHON) -m twine upload --verbose -r release-local dist/*
.PHONY: publish

publish-snapshot: build
> $(PYTHON) -m twine upload --verbose -r snapshot-local dist/*
.PHONY: publish-snapshot

bumpversion-release:
> $(PYTHON) -m bumpversion --list release
.PHONY: bumpversion-release

bumpversion-major:
> $(PYTHON) -m bumpversion --list major
.PHONY: bumpversion-major

bumpversion-minor:
> $(PYTHON) -m bumpversion --list minor
.PHONY: bumpversion-minor

bumpversion-patch:
> $(PYTHON) -m bumpversion --list patch
.PHONY: bumpversion-patch

bumpversion-dev:
> $(PYTHON) -m bumpversion --list devbuild
.PHONY: bumpversion-dev
