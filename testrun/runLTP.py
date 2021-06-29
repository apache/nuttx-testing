#!/usr/bin/python3

import os, sys, time, re, platform
import argparse, inspect
import pexpect
import subprocess
import csv
from itertools import groupby

PROMPT = "nsh>"
orgPath = os.path.abspath(os.path.dirname(__file__))

def parse_args():
    arg = argparse.ArgumentParser()
    arg.add_argument("-b", dest='board', default='sim',
                    help="specify board value, for example: sim or amebaZ, default is sim")
    arg.add_argument('-l', dest='log', default='.',
                    help="specify log path")
    arg.add_argument('-p', dest='path', default='.',
                    help="specify source code dir")
    args = arg.parse_args()
    return args

class connectNuttx(object):

    def setup(self, path, log):
        os.chdir(path)
        self.process = pexpect.spawn("./nuttx/nuttx")
        self.log = open(log, 'wb')
        self.process.logfile = self.log
        self.process.expect(PROMPT)

    def sendCommand(self, cmd):
        self.process.sendline(cmd)
        try:
            self.process.expect(PROMPT, timeout=300)
            #get return valule
            self.process.sendline('echo $?')
            self.process.readline()
            line = self.process.readline()
            if "0" in str(line):
                print("test case run pass, return 0")
                return 0
            else:
                print("test case run fail, return %s" % str(line))
                return str(line)

        except pexpect.TIMEOUT:
            print("Debug: TIMEOUT '%s' exist and run next test case" % cmd)
            return 2

        except pexpect.EOF:
            print("Debug: EOF raise exception")
            return 3

    def cleanup(self):
        self.process.sendline('poweroff')
        self.process.expect("$")
        os.chdir(orgPath)
        self.log.close()

def runCmd(cmd):
    p = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE)

    stdout, stderr = p.communicate()
    recode = p.returncode

    if recode != 0 :
        print("Debug: run command '%s' failed" % cmd)

    return stdout


def getResult(case, ret, dic):
    if ret == 0:
        dic[case] = 'PASS'
    else:
        dic[case] = 'FAIL'

    return dic

#read case from builtin_list.h file
def getCaseList(buildinfile, flag):
    f = open(buildinfile, 'r')
    lines = f.readlines()
    f.close()
    clist = []
    for line in lines:
        if flag in line:
            #line: { "ltp_interfaces_mq_setattr_1_1", SCHED_PRIORITY_DEFAULT, 8192, ltp_test_interfaces_mq_setattr_1_1_main },
            #get ltp_interfaces_mq_setattr_1_1
            obj = re.search(r'.*("%s.*")(.*)' % flag, line, re.M|re.I)
            #case not in blackList.txt
            if not findString(obj.group(1).strip('"'), 'blackList.txt'):
                clist.append(obj.group(1))
    return clist

#find string on dailyRunList.txt
def findString(string, filename):
    fPath = os.path.abspath(os.path.dirname(inspect.getfile(inspect.currentframe())))
    with open(os.path.join(fPath, filename), 'r') as f:
        lines = f.readlines()
        f.close()

        for line in lines:
            if string in line:
                return True
        return False

#update dic
def updateDic(dic):
    tmpDic={}
    for key in dic.keys():
        if findString(str(key), 'dailyRunList.txt'):
            tmpDic[key] = dic[key]
    return tmpDic

#write test result to csv file
def writeCsv(dic, log, name):
    today = time.strftime("%Y%m%d", time.localtime())
    resultName = os.path.join(log, name + '_result_' + today + '.csv')
    f = open(resultName, 'w')

    csv_write = csv.writer(f)
    #write summary to csv
    csv_summary = ["Total", "PASS", "FAIL", "PASS_Rate"]
    csv_write.writerow(csv_summary)
    (pNum, fNum, pRate) = genSummary(dic)
    csv_write.writerow([pNum+fNum, pNum, fNum, str(pRate) + '%'])
    csv_write.writerow(['\n'])

    #write cases status
    csv_head = ["Test Case", "Status"]
    csv_write.writerow(csv_head)

    for key in dic.keys():
        csv_write.writerow([key, dic[key]])

    f.close()

#find file
def findFile(path, flag):
    fList = []
    for root, dirs, files in os.walk(path):
        for name in files:
            if flag in name and not '.o' in name:
                fList.append(os.path.join(root, name))
    return fList

#get test suite name
def getTsName(tsFile):
    ts = '_'.join(os.path.basename(tsFile).split('_')[:-2])
    return ts

#get case list from buildin_list.h and write to testsuite_list.txt
def readBuildInList(path, log):
    flist = findFile(path, 'builtin_list.h')
    today = time.strftime("%Y%m%d", time.localtime())
    for bfile in flist:
        l1 = getCaseList(bfile, 'ltp_')
        #get open_posix list
        opList = [list(g) for k,g in groupby(l1,lambda x:'ltp_syscalls' in x) if not k]
        opFile = '%s_list_%s.txt' % ('open_posix', today)
        if opList:
            writeListToFile(os.path.join(log, opFile), opList[0])

        #get syscalls list
        sysList = [list(g) for k,g in groupby(l1,lambda x:'ltp_syscalls' in x) if k]
        sysFile = '%s_list_%s.txt' % ('syscalls', today)
        if sysList:
            writeListToFile(os.path.join(log, sysFile), sysList[0])
    return

#write runlist to file
def writeListToFile(filename, newlist):
    if newlist:
        f = open(filename, 'w')
        for ts in newlist:
            f.write(ts.strip('"'))
            f.write('\n')
        f.close()
        return f

#read test case status and generate summary
def genSummary(dic):
    passNum = 0
    failNum = 0

    for key in dic.keys():
        if dic[key] == 'PASS':
            passNum = passNum + 1
        else:
            failNum = failNum + 1
    passRate = round(passNum/(passNum+failNum)*100, 2)
    return (passNum, failNum, passRate)


def main():

    args = parse_args()
    board = args.board
    log = args.log
    path = args.path

    #check the argument
    if not os.path.exists(path):
        print("please set source code path!")
        sys.exit()

    if not os.path.exists(log):
        os.makedirs(log)

    #get case list from buildin_list.h and write to open_posix_list_20200921.txt
    readBuildInList(path, log)

    today = time.strftime("%Y%m%d", time.localtime())
    #get test suite list from log path
    tsList = findFile(log, '_list_%s.txt' % today)

    dic = {}
    for tsFile in tsList:
        #get Summary for test suite
        #get test suite name from test suite list file
        #for example: open_posix_list_20200921.txt, test suite: open_posix
        ts = getTsName(tsFile)

        #get case list from ts file
        f = open(tsFile, 'r')
        cList = f.readlines()
        f.close()

        #run test case
        for case in cList:
            case = case.strip("\n")
            p = connectNuttx()
            p.setup(path, os.path.join(log, case + ".txt"))
            ret = p.sendCommand(case)

            #get PASS FAIL result
            dic = getResult(case, ret, dic)

            p.cleanup()

        #follow the dailyRunList generate new dic
        tmpDic = updateDic(dic)

        #write result to csv
        writeCsv(tmpDic, log, ts)


if __name__ == '__main__':
    main()
