FASTA, = glob_wildcards('../results/pangenome/l_amylovorus/prokka/fna/{fasta}.fna')
rule all:
    input:
        expand("../results/pangenome/l_amylovorus/sourmash/sketches/{fasta}.zip", fasta=FASTA),
    #    expand("../results/TerL/own/{fasta}.faa", fasta=FASTA),
        
rule sketch:
    input:
        fasta = '../results/pangenome/l_amylovorus/prokka/fna/{fasta}.fna',
    output:
        sig= "../results/pangenome/l_amylovorus/sourmash/sketches/{fasta}.zip",
    conda: 
        "branchwater-skipmer"
    threads: 1
    shell:
        """
        sourmash sketch dna {input.fasta} \
        -p k=21,k=31,k=51,scaled=100,abund \
        --name {wildcards.fasta} -o {output.sig}
        """
