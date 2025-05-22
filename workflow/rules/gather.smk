import os
import pandas as pd


# set list of samples
METAG = pd.read_csv("../config/sra.txt", usecols=[0], header=None).squeeze().tolist()

rule all:
    input:
        expand('../results/test_pipeline/gather/check/{metag}.m_elsdenii.check', metag=METAG,),


rule gather:
    input:
        query="/group/ctbrowngrp/irber/data/wort-data/wort-sra/sigs/{metag}.sig",
        against = "/group/ctbrowngrp2/amhorst/2025-pangenome/results/test_pipeline/m_elsdenii/sourmash/m_elsdenii.gtdb.zip"
    output:
        csv = "../results/test_pipeline/gather/{metag}.m_elsdenii.csv",
        check = "../results/test_pipeline/gather/check/{metag}.m_elsdenii.check"
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell: """
       sourmash gather {input.query} {input.against} --create-empty-results \
       -k 21 --scaled 1000 -o {output.csv} && touch {output.check}
    """
