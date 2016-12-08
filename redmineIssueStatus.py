# -*- coding: utf-8 -*-
import sys
print(sys.version)
import time
from operator import attrgetter
from redmine import Redmine

redmine = Redmine('http://222.184.92.208:3000/', key='6e1b9bcbdd23f24bc7ebac8591a90f678c1ef9c5')

def remind_note(issue,TDOA):
    "根据时间戳计算任务所剩时间，并返回任务提醒说明"
    str_note="系统提示：请尽快处理任务："+issue.subject+"，您的所剩时间还剩"
    if TDOA < 86400:#小于2天
        str_note += "2天"
    elif 86400 <= TDOA < 172800:#小于1天
        str_note += "1天"
    elif 172800 <= TDOA < 259200:#小于0天
        str_note += "0天"
    else:
        str_note = "系统提示：您已超时："+issue.subject
    issue.notes=str_note
    issue.save()
def tdoa_time(created_time):
    "计算当前时间和任务创建时间的时间差,'28800'为(数据库默认存储的时间+8小时=北京时间)"
    return time.time()-int(time.mktime(created_time.timetuple()))-28800


issues = redmine.issue.filter(tracker_id="5|6", status_id="1|3|7|9|14")
for issue in issues:
    if issue.status.id == 1:#当任务状态为新建(1)时
        if issue.journals:
            journalss=sorted(issue.journals, key=attrgetter('id'), reverse=True)
            for journal in journalss:
                if journal.notes.startswith("系统提示："):
                    if tdoa_time(journal.created_on) <86400:
                        break
                    else:
                        remind_note(issue,tdoa_time(issue.created_on))
                        break
        else:
            remind_note(issue,tdoa_time(issue.created_on))

    else:#当任务状态为已完成(3)，审阅通过(7)，审核未通过(9)，已反馈(14)
        journalss=sorted(issue.journals, key=attrgetter('id'), reverse=True)
        for journal in journalss:#循环遍历每个问题产生的日志
            if journal.notes.startswith("系统提示："):
                if tdoa_time(journal.created_on) <86400:
                    break
            for detail in journal.details:#遍历日志中的详细日志信息，查询状态变更的最新时间
                if detail["name"] == "status_id":
                    if detail["new_value"] == "3" or detail["new_value"] == "7" or detail["new_value"] == "9" or detail["new_value"] == "14":#3.已完成 7.审阅通过 9.审核未通过 14.已反馈
                        remind_note(issue,tdoa_time(journal.created_on))
                        break
            else: continue
            break
