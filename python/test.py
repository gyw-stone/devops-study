# -*- coding: UTF-8 -*-

import time

def decorator(func):
    def punch(*args, **kwargs):
        print(time.strftime('%Y-%m-%d', time.localtime(time.time())))
        func(*args, **kwargs)
    return punch

@decorator
def punch(name, department):
    print('name: {0} bus: {1} ding'.format(name, department))

@decorator
def print_args(reason, **kwargs):
    print(reason)
    print('kwargs :', kwargs)
punch('AA', 'BB')
print_args('AA', sex='man', age=90)
