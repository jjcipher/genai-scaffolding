#!/usr/bin/env bash
# setup_sphinx.sh - Set up Sphinx documentation for GenAI projects

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/utils/logging.sh"

setup_sphinx() {
    local project_dir="$1"
    local project_name="$2"
    
    log "INFO" "Setting up Sphinx documentation..."
    
    # Create docs directory structure
    mkdir -p "$project_dir/docs/source/_static"
    mkdir -p "$project_dir/docs/source/_templates"
    
    # Create conf.py
    cat > "$project_dir/docs/source/conf.py" << ENDOFFILE
# Configuration file for the Sphinx documentation builder.

import os
import sys
sys.path.insert(0, os.path.abspath('../../src'))

# Project information
project = '${project_name}'
copyright = '$(date +%Y), Your Name'
author = 'Your Name'

# The full version, including alpha/beta/rc tags
release = '0.1.0'

# General configuration
extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.napoleon',
    'sphinx.ext.viewcode',
    'sphinx.ext.githubpages',
    'sphinx.ext.intersphinx',
    'sphinx.ext.todo',
    'sphinx.ext.coverage',
    'sphinx_rtd_theme',
    'myst_parser',
]

# Add any paths that contain templates here
templates_path = ['_templates']
exclude_patterns = []

# The suffix(es) of source filenames
source_suffix = {
    '.rst': 'restructuredtext',
    '.md': 'markdown',
}

# The master toctree document
master_doc = 'index'

# HTML theme settings
html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']
html_theme_options = {
    'navigation_depth': 4,
    'titles_only': False,
    'logo_only': False,
}

# Napoleon settings
napoleon_google_docstring = True
napoleon_numpy_docstring = True
napoleon_include_init_with_doc = True
napoleon_include_private_with_doc = True
napoleon_include_special_with_doc = True
napoleon_use_admonition_for_examples = True
napoleon_use_admonition_for_notes = True
napoleon_use_admonition_for_references = True
napoleon_use_ivar = True
napoleon_use_param = True
napoleon_use_rtype = True
napoleon_type_aliases = None

# Intersphinx configuration
intersphinx_mapping = {
    'python': ('https://docs.python.org/3', None),
    'numpy': ('https://numpy.org/doc/stable/', None),
    'pandas': ('https://pandas.pydata.org/docs/', None),
}

# ToDo settings
todo_include_todos = True
ENDOFFILE

    # Create index.rst
    cat > "$project_dir/docs/source/index.rst" << ENDOFFILE
Welcome to ${project_name}'s documentation!
=========================================

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   readme
   installation
   usage
   modules/index
   contributing
   authors
   history

Indices and tables
==================

* :ref:\`genindex\`
* :ref:\`modindex\`
* :ref:\`search\`
ENDOFFILE

    # Create installation.rst
    cat > "$project_dir/docs/source/installation.rst" << ENDOFFILE
.. highlight:: shell

============
Installation
============

Development Installation
-----------------------

1. Clone the repository:

   .. code-block:: console

      \$ git clone https://github.com/username/${project_name}.git

2. Install dependencies using Poetry:

   .. code-block:: console

      \$ cd ${project_name}
      \$ poetry install

3. Set up pre-commit hooks:

   .. code-block:: console

      \$ poetry run pre-commit install

Docker Installation
------------------

1. Build the Docker image:

   .. code-block:: console

      \$ docker-compose build

2. Run the container:

   .. code-block:: console

      \$ docker-compose up
ENDOFFILE

    # Create usage.rst
    cat > "$project_dir/docs/source/usage.rst" << ENDOFFILE
=====
Usage
=====

To use ${project_name} in a project:

.. code-block:: python

    import ${project_name}

Basic Usage
----------

Describe basic usage here.

Advanced Features
---------------

Describe advanced features here.

Configuration
------------

Explain configuration options here.

Best Practices
-------------

Document best practices here.
ENDOFFILE

    # Create modules/index.rst
    mkdir -p "$project_dir/docs/source/modules"
    cat > "$project_dir/docs/source/modules/index.rst" << ENDOFFILE
API Reference
============

.. toctree::
   :maxdepth: 4

   ${project_name}
ENDOFFILE

    # Create contributing.rst
    cat > "$project_dir/docs/source/contributing.rst" << ENDOFFILE
.. highlight:: shell

============
Contributing
============

We love your input! We want to make contributing to ${project_name} as easy and transparent as possible, whether it's:

* Reporting a bug
* Discussing the current state of the code
* Submitting a fix
* Proposing new features
* Becoming a maintainer

Development Process
-----------------

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

1. Fork the repo and create your branch from \`main\`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!

Pull Request Process
------------------

1. Update the README.md with details of changes to the interface, if applicable.
2. Update the docs with any new information.
3. The PR will be merged once you have the sign-off of the maintainers.

Any contributions you make will be under the MIT Software License
--------------------------------------------------------------

In short, when you submit code changes, your submissions are understood to be under the same [MIT License](http://choosealicense.com/licenses/mit/) that covers the project. Feel free to contact the maintainers if that's a concern.
ENDOFFILE

    # Create authors.rst
    cat > "$project_dir/docs/source/authors.rst" << ENDOFFILE
=======
Authors
=======

* Your Name <your.email@example.com>
ENDOFFILE

    # Create history.rst
    cat > "$project_dir/docs/source/history.rst" << ENDOFFILE
=======
History
=======

0.1.0 ($(date +%Y-%m-%d))
------------------

* First release on PyPI.
ENDOFFILE

    # Create Makefile for docs
    cat > "$project_dir/docs/Makefile" << ENDOFFILE
# Minimal makefile for Sphinx documentation

# You can set these variables from the command line, and also
# from the environment for the first two.
SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = source
BUILDDIR      = build

# Put it first so that "make" without argument is like "make help".
help:
	@\$(SPHINXBUILD) -M help "\$(SOURCEDIR)" "\$(BUILDDIR)" \$(SPHINXOPTS) \$(O)

.PHONY: help Makefile clean

# Remove everything in build directory
clean:
	rm -rf \$(BUILDDIR)/*

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  \$(O) is meant as a shortcut for \$(SPHINXOPTS).
%: Makefile
	@\$(SPHINXBUILD) -M \$@ "\$(SOURCEDIR)" "\$(BUILDDIR)" \$(SPHINXOPTS) \$(O)
ENDOFFILE

    # Add sphinx requirements to pyproject.toml
    cat >> "$project_dir/pyproject.toml" << ENDOFFILE

[tool.poetry.group.docs]
optional = true

[tool.poetry.group.docs.dependencies]
Sphinx = "^7.1.0"
sphinx-rtd-theme = "^1.3.0"
myst-parser = "^2.0.0"
ENDOFFILE

    # Add documentation commands to main Makefile
    cat >> "$project_dir/Makefile" << ENDOFFILE

# Documentation commands
docs-install:
	poetry install --with docs

docs-build:
	cd docs && poetry run make html

docs-clean:
	cd docs && poetry run make clean

docs-serve:
	cd docs/build/html && python -m http.server 8000
ENDOFFILE

    log "SUCCESS" "Sphinx documentation setup complete"
}

# Execute only if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ "$#" -lt 2 ]]; then
        echo "Usage: $0 PROJECT_DIR PROJECT_NAME"
        exit 1
    fi
    setup_sphinx "$@"
fi
