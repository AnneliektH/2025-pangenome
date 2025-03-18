#! /usr/bin/env python
import sys
import pickle
import argparse

# allow import of hash_presence_lib
sys.path.insert(0, '/home/ctbrown/scratch3/2024-pangenome-hash-corr/')


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--dump-files-1', nargs='+')
    p.add_argument('--dump-files-2', nargs='+')
    args = p.parse_args()

    list1 = []
    for dmp in args.dump_files_1:
        with open(dmp, 'rb') as fp:
            x = pickle.load(fp)
        list1.append(x)

    list2 = []
    for dmp in args.dump_files_2:
        with open(dmp, 'rb') as fp:
            x = pickle.load(fp)
        list2.append(x)

    print(len(list1), len(list2))

    hashes = set()
    for x in list1:
        hashes.update(x.hash_to_sample)
    for x in list2:
        hashes.update(x.hash_to_sample)

    for hashval in hashes:
        num_1 = 0
        num_2 = 0
        for x in list1:
            num_1 += len(x.hash_to_sample[hashval])
        for x in list2:
            num_2 += len(x.hash_to_sample[hashval])

        print(hashval, num_1, num_2)


if __name__ == '__main__':
    sys.exit(main())
