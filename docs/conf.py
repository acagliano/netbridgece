#!/usr/bin/env python3
import sys

sys.path.append('/opt/homebrew/lib/python3.11/site-packages')
import subprocess, os

project = 'CryptX'
copyright = '2023'
author = 'Anthony Cagliano'

current_version = os.environ['current_version']
default_version = os.environ['default_version']
versions = os.environ['versions'].split()

extensions = [
    "breathe",
    "sphinx_proof"
]

html_theme_options = {
    'display_version': True,
    'titles_only': False
}


latex_engine = 'pdflatex'
latex_elements = {
  'papersize': 'letterpaper',
  'figure_align': 'H',
  'extraclassoptions': 'openany,oneside',
  'fncychap': r'\usepackage[Sonny]{fncychap}',
  'pointsize': '11pt',
  'preamble': r'''
    \usepackage{charter}
    \usepackage[defaultsans]{lato}
    \usepackage{inconsolata}
  ''',
}

templates_path = ['templates']
source_suffix = '.rst'
master_doc = 'index'
language = None
exclude_patterns = ['build', '_build', 'Thumbs.db', '.DS_Store', 'venv']
pygments_style = "sphinx"
html_theme = 'sphinx_rtd_theme'
html_show_sourcelink = False

try:
   html_context
except NameError:
   html_context = dict()
html_context['display_lower_left'] = True
html_context['current_version'] = current_version
html_context['default_version'] = default_version
html_context['version'] = current_version
html_context['versions'] = list()
for version in versions:
   html_context['versions'].append( (version, '/toolchain/' + version + '/index.html') )

breathe_projects = {}
breathe_default_project = 'CryptX'
breathe_show_define_initializer = True
breathe_show_enumvalue_initializer = True
subprocess.call('doxygen doxyfile', shell=True)
breathe_projects['CryptX'] = 'doxygen/xml'
