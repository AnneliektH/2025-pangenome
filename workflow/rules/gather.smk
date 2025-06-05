import os
import pandas as pd


# set list of samples
METAG = pd.read_csv("../config/sra.txt", usecols=[0], header=None).squeeze().tolist()

rule all:
    input:
        expand('../results/test_pipeline/gather/check/{metag}.gather.gtdb.check', metag=METAG,),
        expand('../results/test_pipeline/gather/check/{metag}.gather.mag.check', metag=METAG,),


rule gather:
    input:
        query="/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig",
        against = "/group/ctbrowngrp5/sourmash-db/gtdb-rs226/gtdb-rs226-reps.k21.rocksdb",
        own_mag = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.99.k21.rocksdb'
    output:
        csv = "../results/test_pipeline/gather/{metag}.gather.csv",
        check = "../results/test_pipeline/gather/check/{metag}.gather.check"
    conda: 
        "branchwater-skipmer"
    threads: 12
    shell: """
       sourmash gather {input.query} {input.against} {input.own_mag} --create-empty-results \
       -k 21 --scaled 1000 -o {output.csv} && touch {output.check}
    """

rule fastgather_gtdb:
    input:
        query="/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig",
        against = "/group/ctbrowngrp5/sourmash-db/gtdb-rs226/gtdb-rs226-reps.k21.rocksdb",
    output:
        csv = "../results/test_pipeline/gather/{metag}.gather.gtdb.csv",
        check = "../results/test_pipeline/gather/check/{metag}.gather.gtdb.check"
    conda: 
        "branchwater-skipmer"
    threads: 15
    shell: """
       sourmash scripts fastgather {input.query} {input.against} \
       -k 21 --scaled 1000 -o {output.csv} --cores {threads} && touch {output.check}
    """

rule fastgather_mag:
    input:
        query="/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig",
        own_mag = '/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAGs.99.k21.rocksdb'
    output:
        csv = "../results/test_pipeline/gather/{metag}.gather.mag.csv",
        check = "../results/test_pipeline/gather/check/{metag}.gather.mag.check"
    conda: 
        "branchwater-skipmer"
    threads: 15
    shell: """
       sourmash scripts fastgather {input.query} {input.own_mag} \
       -k 21 --scaled 1000 -o {output.csv} --cores {threads} && touch {output.check}
    """

