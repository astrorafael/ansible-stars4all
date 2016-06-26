#!/usr/bin/env python

# TESS MONITOR UTILITY

# ----------------------------------------------------------------------
# Copyright (c) 2014 Rafael Gonzalez.
#
# See the LICENSE file for details
# ----------------------------------------------------------------------

# OPCIONES : o reference file o un solo instrumento
# O estilo nagios o estilo M/Monit (con fichero de logfie)
#--------------------
# System wide imports
# -------------------

import json
import collections
import sys
import argparse
import logging
import os
import os.path

from logging.handlers import TimedRotatingFileHandler, RotatingFileHandler


# -------------------    
# NAGIOS return codes
# -------------------

OK       = 0
WARNING  = 1
CRITICAL = 2
UNKNOWN  = 3

# --------------------
# Logging File formats
# --------------------

CONSOLE_LOG_FORMAT = '%(message)s'
FILE_LOG_FORMAT    = '%(asctime)s [%(levelname)5s] - %(message)s'

ROOT = logging.getLogger()
ROOT.setLevel(logging.INFO)

# -----------------
# Logging Functions
# -----------------

def logToConsole():
    formatter = logging.Formatter(fmt=CONSOLE_LOG_FORMAT)
    consoleHandler = logging.StreamHandler()
    consoleHandler.setFormatter(formatter)
    ROOT.addHandler(consoleHandler)


def logToFile(filename, by_size, max_size):
    formatter   = logging.Formatter(fmt=FILE_LOG_FORMAT)
    if by_size:
        fileHandler = RotatingFileHandler(filename,
                                          maxBytes=max_size,
                                          backupCount=7)
    else:
        # daily rotation at midnight, keep 7 backups
        fileHandler = TimedRotatingFileHandler(filename,
                                           when='midnight',
                                           interval=1,
                                           backupCount=7)
    fileHandler.setFormatter(formatter)
    ROOT.addHandler(fileHandler)



# ======
# Parser
# ======

def createParser():
    # create the top-level parser
    parser = argparse.ArgumentParser(prog=sys.argv[0])
    parser.add_argument('input_file',  help='Input JSON file to parse')
    group1 = parser.add_mutually_exclusive_group()
    group1.add_argument('-r', '--reference-file', default=None, help='Instruments JSON reference file')
    group1.add_argument('-n', '--name',           default=None, help='Instrument name')
    parser.add_argument('-c', '--console',        action="store_true", help='Output to console')
    parser.add_argument('-o', '--output-file',    default=None, help='Output to log file')
    return parser


# ------------------
# Analysis functions
# ------------------

def getOnlineInstruments(input_file):
    '''
    Return a set of current instrument names detected from MQTT traffic
    Also returns how many times have been detected in the given time period.
    '''
    log = logging.getLogger()
    instruments=collections.Counter()
    if not os.path.isfile(input_file):
        log.critical("UNKNOWN: No input JSON file found %s", input_file)
        sys.exit(UNKNOWN)
    with open(input_file,'r') as f:
        for line in f:
            try:
                d = json.loads(line)
                instruments.update([d['name']])
            except Exception as e:
                log.critical(e)
                continue
                #sys.exit(UNKNOWN)
    # Remove all retained messages. This is a bias to be substracted
    bias = collections.Counter({ k: 1 for k in instruments.keys()})
    instruments = instruments - bias
    return set(instruments.keys()), instruments
    

def getReference(reference_file=None, tess_name=None):
    '''
    Return a set of intruments names that should be the reference to compare with
    '''
    log = logging.getLogger()
    if reference_file:
        if not os.path.isfile(reference_file):
            log.critical("UNKNOWN: No JSON reference file found %s", reference_file)
            sys.exit(UNKNOWN)
        with open(reference_file,'r') as ref:    
            reference = set(json.load(ref))
    elif tess_name:
        reference=set([tess_name])
    else:
        reference=set()
    return reference

# -------------------
# Reporting functions 
# -------------------

def singleReport(reference, online,perfdata):
    log = logging.getLogger()
    missing = reference - online
    if not len(reference - missing):
        log.critical("CRITICAL: Missing TESS instrument: %s | %s", str(list(missing)[0]), str(perfdata))
        return CRITICAL

    log.info("OK: instrument %s present | %s", str(list(reference)[0]), str(perfdata))
    return OK
    

def multipleReport(reference, online, perfdata):
    log = logging.getLogger()
    missing = reference - online
    if not len(reference - missing):
        log.critical("CRITICAL: All Missing TESS instruments: %s | %s", str(list(missing)), str(perfdata))
        return CRITICAL

    if len(missing):
        log.warning("WARNING: Missing TESS instruments: %s | %s", str(list(missing)), str(perfdata))
        return WARNING

    log.info("OK: All instruments present")
    return OK

# -------------
# Main function
# -------------

def main():
    parser = createParser()
    opts   = parser.parse_args()
    if opts.console:
        logToConsole()
    if opts.output_file:
        logToFile(filename=opts.output_file, by_size=False, max_size=0)
   
    online, perfdata = getOnlineInstruments(opts. input_file)
    reference = getReference(opts.reference_file, opts.name)

    if opts.name:
        rc = singleReport(reference, online, perfdata)
    else:
        rc = multipleReport(reference, online, perfdata)

    sys.exit(rc)

main()
