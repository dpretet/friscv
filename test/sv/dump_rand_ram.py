#!/usr/bin/env python3
# coding: utf-8

# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

"""
Doc string to describe the module
"""

import secrets

NB_INST = 262144 # 1MB / 4 bytes (1 instruction = 4 bytes)


def gen_random_data():
    """ Generate random instruction """

    data = []
    i=0

    while i<NB_INST:
        i += 1
        data.append(secrets.token_hex(4))

    return data


def write_file(name, data, inst_per_line=4):
    """ Write a batch of instructions """

    i = 0
    temp = ""

    with open(name, "w") as file:
        for inst in data:
            i += 1
            temp = inst + temp
            if i==inst_per_line:
                file.write(temp + "\n")
                i = 0
                temp = ""
    file.close()

if __name__ == '__main__':

    inst = gen_random_data()
    write_file('ram_32b.txt', inst, 1)
    write_file('ram_128b.txt', inst, 4)
