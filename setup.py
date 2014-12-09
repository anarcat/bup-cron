#!/usr/bin/python
# -*- coding: utf-8 -*-

try:
    from setuptools import setup
except ImportError:
    from distutils.core import setup

import bup_cron
import sys

setup(name='bup_cron',
      description='bup jobs wrapper',
      long_description=bup_cron.__doc__,
      version=bup_cron.__version__,
      url='http://src.anarc.at/bup_cron.git',
      author=bup_cron.__author__,
      author_email=bup_cron.__email__,
      license='AGPL3',
      keywords='bup cron backups',
      # install_requires=['bup_cron'],
      classifiers=[
        'Development Status :: 4 - Beta',
        'Environment :: No Input/Output (Daemon)',
        'Environment :: Console',
        'Intended Audience :: System Administrators',
        'License :: OSI Approved :: GNU Affero General Public License v3',
        'Operating System :: POSIX',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 2 :: Only',
        'Topic :: System :: Archiving :: Backup',
        ],
      packages=['bup_cron'],
      scripts=['bup-cron'],
      )
